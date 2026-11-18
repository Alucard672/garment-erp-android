# Garment ERP Android

原生横屏 Flutter 平板工作台。使用本地管理后台创建的员工账号登录。所有正式单据和业务资料由 Django API 读写 PostgreSQL。

```sh
flutter pub get
flutter run --dart-define=ERP_API_URL=http://10.0.2.2:8001
flutter analyze
flutter test
```

模拟器用 `10.0.2.2:8001` 连接宿主机 API。真机 USB 调试可执行 `adb reverse tcp:8001 tcp:8001`，再使用 `http://127.0.0.1:8001`。

登录页连续点 Logo 11 下打开环境选择。「测试环境」默认直连阿里云 `https://121.43.167.158`。构建时可用 `--dart-define=ERP_LOCAL_API_URL=...`、`ERP_TEST_API_URL`、`ERP_PRODUCTION_API_URL` 指定各环境地址。使用 `--dart-define=ERP_DEFAULT_ENV=test` 可指定首次打开的环境，可选值为 `local`、`test` 和 `production`。既有构建仍可使用 `ERP_API_URL` 指定默认服务。正式环境需要 HTTPS，正式 APK 的三个环境都只接受 HTTPS。环境选择保存在当前设备，阿里云测试服直连和旧 SSH 转发入口共用订单录入内容和待重试记录。

安卓销售区包括产品档案、客户档案、客户订单、按订货开单、已过账发货单、采购、退货申请、库存总览和流水、生产跟单、数据分析、员工档案、款号与订单号查询和系统设置。平板支持新增客户、采购单、成衣入库单、选择客户和入库仓库、按款号色码直接开退单，以及按原订货明细新增跟单。商品、仓库和供应商在管理后台维护。扫码查询支持手输和键盘式扫码枪输入。

「保存订单」直接提交到服务器，保存成功后返回订单列表并显示订单号。失败原因显示在录入页面，提交结果不明确时保留原请求供重试。已保存订单进入待发列表。按原订单选仓发货时，可以在待发数量范围内输入分批发货数量，仓库结存可以为负。

一张订货单可选择多个款号，各款显示已登记的销售价、缩略图和颜色尺码。订货单详情按款号分表，可点击缩略图查看大图。「销售开单 → 销售单 → 开单」可选择按订货单发货或现货直接发货，现货直发需选出库仓，支持负库存销售。订货单和发货单可选填店员，默认使用当前操作员。选「未付」后，实际发出的金额可在「客户账款」中查询。

「销售开单」的单据列表可切换订货单和销售单。支持输入关键词、搜索并下拉选择客户或店员，以及单独填写起止日期。

登录后进入经营首页，扫码入口显示在首页顶栏。左侧选择业务模块后，在工作区顶部横向切换客户账款等二级菜单。单据详情展开在右侧工作区。有明细的录入页返回时可选保留或清空。

订货和现货直发支持「特殊货品」，选择后填写品名、销售价和数量。特殊货品发货不扣库存。按订货发货和现货直发均可填写部分实收，剩余发货金额计入客户账款。选择客户后可打开「核销客户账款」，登记实收并指定发货单及核销金额。

升级前按 API 仓库说明和顺序部署兼容后端。新功能需要 `sales.0005_special_order_lines`、`fulfillment.0005_special_items_and_shipment_payment` 和 `customer.0003_customer_receipts`。核销操作员需要加授 `customer.add_customerreceipt`。

同步 `openapi/schema.yaml` 后运行 `uv run tools/generate_openapi.py` 和 `dart format lib/generated`。正式构建需要 HTTPS 服务地址和发布签名。

## 平板在线更新

平板打开「系统设置 → 检查更新」获取最新版本，选择「下载并安装」后进入 Android 安装页面。首次可能需要打开「允许此来源安装应用」，返回 App 再点「安装更新」。关闭安装页面后可以重试。

登录、回到前台时，平板会自动检查更新。持续打开工作台时每 15 分钟检查一次。发现新版会在工作台顶部提示，点「查看更新」进入系统设置。仍可随时手动检查。

首个带有更新功能的正式包需先安装到平板。后续版本使用同一个应用 ID 和签名，且每次提高 `--build-number`，例如从 1 提高到 2。已安装的调试包通常使用不同签名，切换为正式包应先处理平板上未提交的订单。

发版机需从密钥管理设施注入 `ERP_KEYSTORE`（密钥库绝对路径）、`ERP_KEYSTORE_PASSWORD`、`ERP_KEY_ALIAS`、`ERP_KEY_PASSWORD`。在 Android 仓库运行：

```sh
flutter build apk --release --build-name=0.1.1 --build-number=2 \
  --dart-define=ERP_API_URL=https://erp.example.com
python3 tools/stage_update.py build/app/outputs/flutter-apk/app-release.apk build/android-updates \
  --build-tools "$ANDROID_HOME/build-tools/36.0.0"
```

默认清单地址为 API 域名下的 `/android-updates/latest.json`。也可在构建时用 `--dart-define=ERP_UPDATE_URL=https://updates.example.com/erp/latest.json` 指定独立 HTTPS 目录。将工具生成的版本 APK 上传到该目录，检查下载正常后再替换 `latest.json`。APK 与清单必须同目录，直接返回 HTTP 200。建议对 `latest.json` 禁用缓存。发布涉及 API 变更时先发布兼容后端，再切换清单。

如果用现有 ECS 的 Nginx，在 HTTPS 站点的 `server` 中配置静态目录，并将生成的文件发布到该目录：

```nginx
location ^~ /android-updates/ {
    alias /opt/garment-erp-test/android-updates/;
    autoindex off;
    add_header Cache-Control "no-cache";
}
```

配置好 SSH 发布账号和目录后，也可以从工作区根目录运行 `bash release-scripts/publish-android.sh` 一次完成签名打包、上传和切换版本清单。具体参数见工作区发布说明。

「商品中心 → 货品查询」可按款号或名称、上架日期、颜色、类别、季节、品牌、状态、经办人和有无图片组合查询。列表和图片视图共用筛选条件和页码，点缩略图可放大，点图片卡片的商品名称可打开档案。首次进入只看启用款，点「清除」可查全部状态。总库存按全仓汇总，未获库存查看权限时显示「—」。

「商品中心 → 库存管理」与「入库与发货 → 库存总览」共用当前库存筛选。填写条件后点「查询」，点「清除」恢复全部状态。日期框可点开年、月、日滚轮，点「关闭」采用所选日期，也可选择键盘输入。

安卓页面的设计与验收遵循 [Android 横屏 ERP 界面规范](docs/tablet-ui.md)。可在「商品中心 → 库存管理」查看 TDesign 风格的筛选区。

退货管理中「销售退货单」按客户选款号、色码和件数，特殊货品可填写品名、单价。确认后按仓库入账，退货金额抵减客户欠款，可形成客户结余。「历史退货申请」可查原有申请。
