# CenWallet

基于用户提供的 Pixso UI 实现的 Flutter 钱包 App。包含 48 个页面路由、64 张模拟器页面与状态截图，以及完整的项目结构和架构说明。

![主要界面](docs/main-screens.jpg)

## 文档

- [项目结构、架构与功能说明](docs/项目架构说明.md)
- [全部界面截图](docs/界面截图.md)
- [Pixso 画板与实现对应表](docs/设计对应表.md)
- [验证记录](docs/验证记录.md)

## 启动

开发环境：Flutter 3.41.6 / Dart 3.11.4。

```bash
flutter pub get
flutter run
```

进入引导页，依次点击 **Let’s begin → Skip → Explore demo**，即可体验全部页面。也可以填写有效格式的手机号和至少 8 位密码完成演示登录；验证码统一为 `F2368`。

App 默认提供 USD、JPY、BTC 钱包，可以创建 EUR 钱包。充值、转账、换汇、账单支付会更新本地演示余额与交易记录。重启后保留钱包、联系人、设置和交易；认证会话不持久化。

本项目是可运行的 UI 与本地业务演示。支付、银行连接、短信、身份审核、指纹认证、机票出票均未接入真实服务；二维码支持生成与手动输入收款码。界面沿用设计稿的英文。

## 检查与截图

```bash
./tools/verify.sh
flutter devices
./tools/capture_screenshots.sh DEVICE_ID
```

截图脚本会在指定设备上遍历页面、验证完整转账流程，并把 PNG 保存到 `docs/screenshots/`。Android 设备也可运行此脚本，但本次实际构建与设备验证使用 iOS 模拟器。

```bash
flutter build ios --simulator --debug
```

iOS 模拟器构建输出：`build/ios/iphonesimulator/Runner.app`。
