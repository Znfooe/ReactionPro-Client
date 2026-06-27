# Windows 安装包

## 前置条件

- Windows 10/11 x64
- Flutter 3.44.3
- Visual Studio 2022“使用 C++ 的桌面开发”
- Inno Setup 6 或 7

安装 Inno Setup：

```powershell
winget install --id JRSoftware.InnoSetup --exact --silent --accept-source-agreements --accept-package-agreements
```

## 构建

从仓库根目录执行：

```powershell
.\scripts\build-windows-installer.ps1 `
  -ApiBaseUrl "https://api.example.com/api/v1"
```

脚本会构建 Flutter Windows Release、下载并验证 Microsoft Visual C++ x64 运行库，然后调用 Inno Setup 生成：

```text
dist/ReactionPro-Setup-x64-1.0.0.exe
```

不要为其他电脑构建使用 `localhost` API 的安装包，否则登录、成绩同步和排行榜无法连接服务器。

## 发布

公开发布时应同时提供安装包 SHA-256：

```powershell
Get-FileHash .\dist\ReactionPro-Setup-x64-1.0.0.exe -Algorithm SHA256
```

当前安装包没有项目代码签名，Windows SmartScreen 可能显示“未知发布者”。发布者应在正式大规模分发前加入代码签名。
