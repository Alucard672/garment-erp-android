# 领域文档

平板交互遵循 [横屏界面规范](../tablet-ui.md)。接口以同步自服务端的 [OpenAPI 契约](../../openapi/schema.yaml) 为依据。

本仓库采用单一术语表。开始相关任务时，读取仓库根目录已有的 `GLOSSARY.md`，并查阅 `docs/adr/` 中与本次工作有关的架构决策记录。术语表或决策目录尚未建立时，继续使用本仓库现有规范。

工单、测试和代码使用已约定的领域术语。通过 `grill-with-docs` 或 `domain-modeling` 澄清新术语后，将定义写入 `GLOSSARY.md`。确定需要长期保留的设计取舍时，在 `docs/adr/` 下新增按序编号的 Markdown 文件。若提案与既有决策冲突，指出对应记录与重新评估的原因。
