#define MyAppName "ReactionPro"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "ZNFOOE"
#define MyAppExeName "ReactionPro.exe"

[Setup]
AppId={{2C79B30C-1B0C-4E3B-9C61-6FA0D618A7FE}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\..\dist
OutputBaseFilename=ReactionPro-Setup-x64-{#MyAppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupLogging=yes
CloseApplications=yes
RestartApplications=no

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "ReactionPro.exe,reaction_time_test.exe"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\build\windows\x64\runner\Release\ReactionPro.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "prerequisites\VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "正在安装 Microsoft Visual C++ 运行库..."; Flags: waituntilterminated; Check: VCRuntimeNeedsInstall
Filename: "{app}\{#MyAppExeName}"; Description: "运行 {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
function VCRuntimeNeedsInstall: Boolean;
var
  Installed: Cardinal;
begin
  Installed := 0;
  Result := not RegQueryDWordValue(
    HKLM64,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'Installed',
    Installed
  ) or (Installed <> 1);
end;
