# ReactionPro Client

ReactionPro 是一个使用 Flutter 构建的反应力与击杀时间测试客户端，支持 Web、Windows、Android、iOS、macOS 和 Linux。

本仓库只包含公开客户端。API 服务器和管理后台不在本仓库中。

## 功能

- 反应力测试与逐回合详细数据
- 击杀时间测试、2D/3D 兼容模式与 Raw Input
- 准星、目标、网格和开屏外观设置
- 登录、成绩历史与排行榜客户端
- Flutter Web 与 Windows 桌面构建

## 环境

- Flutter 3.44.3
- Dart 3.12.2
- Windows 桌面构建需要 Visual Studio 2022 的“使用 C++ 的桌面开发”

## 快速开始

```powershell
Set-Location .\frontend
flutter pub get
flutter run -d chrome
```

Windows 桌面端：

```powershell
Set-Location .\frontend
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

反应力和击杀时间测试可以在本地运行。登录、成绩同步和排行榜需要兼容 ReactionPro `/api/v1` 契约的 API。

## 配置

客户端配置会被编译进应用，用户可以读取，因此只能包含公开值：

```text
API_BASE_URL
OAUTH_GITHUB_CLIENT_ID
OAUTH_GOOGLE_CLIENT_ID
SENTRY_DSN
```

禁止在客户端放入 OAuth Client Secret、数据库连接串、JWT 私钥、Resend Key 或其他 Secret。

构建 Web：

```powershell
Set-Location .\frontend
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

构建 Windows 安装包见 [Windows 安装包说明](docs/windows-installer.md)。

## 仓库关系

本仓库是 ReactionPro 私有完整仓库中 Flutter 客户端的公开镜像。公开 Issue 和 Pull Request 会在审查后回填到私有事实源，再随下一次同步发布。

## 安全

请不要在公开 Issue 中披露尚未修复的漏洞。报告方式见 [SECURITY.md](SECURITY.md)。

## 第三方资源

字体等第三方资源不自动适用 Apache-2.0，详情见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 许可证

除第三方声明另有说明外，ReactionPro Client 使用 [Apache License 2.0](LICENSE)。
