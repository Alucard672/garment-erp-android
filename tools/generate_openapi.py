# /// script
# requires-python = ">=3.12"
# dependencies = ["pyyaml==6.0.3"]
# ///
"""Generate the Dart bindings used by this app from the API contract snapshot."""
from pathlib import Path
import re

import yaml


ROOT = Path(__file__).resolve().parent.parent
SCHEMA = yaml.safe_load((ROOT / "openapi/schema.yaml").read_text())
COMPONENTS = SCHEMA["components"]["schemas"]
MODELS = (
    "ApiError", "LoginRequest", "PasswordChange", "LoginResult", "Customer", "CustomerReceivable", "Sku",
    "CustomerReceivableDetail", "ShipmentReceivable", "CustomerReceiptRead",
    "CustomerReceiptWrite", "ReceiptAllocation", "Style", "StyleDetail", "StyleSpecificationRead", "BomLineRead", "Measurement", "CareLabel",
    "ProfileRead", "AttributeRead", "PersonnelRead", "SizeRowRead", "SizeCellRead", "SizeWeight",
    "PaginatedCustomerList", "PaginatedStyleList", "StyleCatalogRead",
    "OrderRead", "OrderLineRead", "PaginatedOrderReadList", "OrderItemWrite", "OrderWrite",
    "DictionaryEntry", "WarehouseRead", "PaginatedWarehouseReadList", "AvailabilityLine", "ShipmentAvailability",
    "ShipmentWrite", "ShipmentItemWrite", "ShipmentPosted", "ShipmentRead", "DirectShipmentWrite", "PaginatedShipmentReadList",
    "PurchaseOrderRead", "PurchaseLineRead", "PaginatedPurchaseOrderReadList",
    "ReturnRequestRead", "PaginatedReturnRequestReadList", "StockRead", "PaginatedStockReadList",
    "ProgressNoteRead", "PaginatedProgressNoteReadList", "StaffRead", "PaginatedStaffReadList",
    "SalesSummary", "ShipmentLineRead", "StockMovementRead",
    "CustomerWrite", "PurchaseWrite", "PurchaseItemWrite", "SupplierRead",
    "SalesReturnRead", "SalesReturnWrite", "SalesReturnLineRead", "ReturnWrite", "ProgressWrite", "ReceiptRead", "ReceiptLineRead",
    "ReceiptWrite", "ReceiptLineWrite",
)
ENUMS = ("PaymentMethodEnum",)
COMPATIBLE_OPTIONAL_FIELDS = {
    "Customer": {"active"},
    "SupplierRead": {"active"},
    "WarehouseRead": {"active"},
    "CustomerReceivableDetail": {"return_amount"},
    "BomLineRead": {"gross_quantity", "id", "material_type", "material_base_unit", "supplier_name"},
    "Style": {"has_style_image"},
    "StyleDetail": {"has_style_image", "active"},
    "StyleSpecificationRead": {"profile", "size_table", "has_style_image", "has_care_image", "style_image_ids"},
    "OrderRead": {"clerk_name", "clerk_id", "customer_id", "status"},
    "OrderLineRead": {"style_id", "special_name"},
    "ShipmentRead": {"is_direct", "customer_id", "clerk_id", "clerk_name", "payment_method", "receivable_amount",
                     "paid_amount", "gross_amount", "settled_amount", "outstanding_amount"},
    "ShipmentLineRead": {"style_id", "special_name"},
    "ReturnRequestRead": {"special_name"},
}


def string_enum_ref(schema):
    name = schema.get("$ref", "").split("/")[-1]
    return COMPONENTS.get(name, {}).get("type") == "string" and "enum" in COMPONENTS[name]


def enum_name(schema):
    for option in schema.get("oneOf", [schema]):
        name = option.get("$ref", "").split("/")[-1]
        if name in ENUMS:
            return name
    return None


def dart_type(schema):
    if name := enum_name(schema):
        return name.removesuffix("Enum")
    if string_enum_ref(schema):
        return "String"
    if "$ref" in schema:
        return schema["$ref"].split("/")[-1]
    if schema.get("type") == "array":
        return f"List<{dart_type(schema['items'])}>"
    return {"integer": "int", "string": "String", "boolean": "bool"}[schema["type"]]


def decode(schema, expression):
    if enum_name(schema):
        return f"{dart_type(schema)}.fromCode({expression} as String?)"
    if "$ref" in schema and not string_enum_ref(schema):
        return f"{dart_type(schema)}.fromJson({expression} as Map<String, dynamic>)"
    if schema.get("type") == "array":
        item = decode(schema["items"], "item")
        return f"({expression} as List<dynamic>).map((item) => {item}).toList(growable: false)"
    return f"{expression} as {dart_type(schema)}"


def camel_case(name):
    return re.sub(r"_(\w)", lambda match: match[1].upper(), name)


def generate_enum(name):
    component = COMPONENTS[name]
    labels = dict(re.findall(r"^\* `([^`]+)` - (.+)$", component["description"], re.M))
    dart_name = name.removesuffix("Enum")
    entries = [f"  {camel_case(code)}('{code}', '{labels[code]}')" for code in component["enum"]]
    return [
        f"enum {dart_name} {{", ",\n".join(entries) + ";", "",
        f"  const {dart_name}(this.code, this.label);",
        "  final String code;", "  final String label;", "",
        f"  static {dart_name}? fromCode(String? code) {{",
        "    for (final method in values) {",
        "      if (method.code == code) return method;",
        "    }", "    return null;", "  }", "}", "",
    ]


def generate_model(name):
    component = COMPONENTS[name]
    fields = {
        key: {**schema["allOf"][0], **schema} if len(schema.get("allOf", [])) == 1 else schema
        for key, schema in component["properties"].items()
    }
    required = set(component.get("required", [])) - COMPATIBLE_OPTIONAL_FIELDS.get(name, set())
    lines = [f"class {name} {{", f"  const {name}({{"]
    for key, schema in fields.items():
        optional = key not in required or schema.get("nullable")
        lines.append(f"    {'' if optional else 'required '}this.{camel_case(key)},")
    lines += ["  });", ""]
    for key, schema in fields.items():
        optional = key not in required or schema.get("nullable")
        lines.append(f"  final {dart_type(schema)}{'?' if optional else ''} {camel_case(key)};")
    lines += ["", f"  factory {name}.fromJson(Map<String, dynamic> json) => {name}("]
    for key, schema in fields.items():
        expression = f"json['{key}']"
        value = decode(schema, expression)
        if key not in required or schema.get("nullable"):
            value = f"{expression} == null ? null : {value}"
        lines.append(f"    {camel_case(key)}: {value},")
    lines += ["  );", "", "  Map<String, dynamic> toJson() => {"]
    for key, schema in fields.items():
        field = camel_case(key)
        optional = key not in required or schema.get("nullable")
        if enum_name(schema):
            field += ("?" if optional else "") + ".code"
        elif "$ref" in schema and not string_enum_ref(schema):
            field += ("?" if optional else "") + ".toJson()"
        elif schema.get("type") == "array" and "$ref" in schema["items"]:
            field += ("?" if optional else "") + ".map((item) => item.toJson()).toList()"
        guard = f"if ({field} != null) " if name == "OrderItemWrite" and key in {"sku_id", "special_name", "unit_price"} else ""
        lines.append(f"    {guard}'{key}': {field},")
    lines += ["  };", "}", ""]
    return lines


lines = ["// Generated from openapi/schema.yaml. Do not edit.", "", "abstract final class ApiPath {"]
for path, methods in SCHEMA["paths"].items():
    for operation in methods.values():
        name = camel_case(operation["operationId"])
        if path_fields := re.findall(r"\{(\w+)\}", path):
            parameters = {p["name"]: p["schema"] for p in operation.get("parameters", []) if p["in"] == "path"}
            arguments = ", ".join(f"{dart_type(parameters[field])} {camel_case(field)}" for field in path_fields)
            template = re.sub(r"\{(\w+)\}", lambda match: "$" + camel_case(match[1]), path)
            lines.append(f"  static String {name}({arguments}) => '{template}';")
        else:
            lines.append(f"  static const {name} = '{path}';")
lines += ["}", ""]
for name in ENUMS:
    lines += generate_enum(name)
for model in MODELS:
    lines += generate_model(model)
(ROOT / "lib/generated/api_schema.dart").write_text("\n".join(lines))
