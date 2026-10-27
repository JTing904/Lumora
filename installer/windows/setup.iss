; ──────────────────────────────────────────────────────────────────────────────
;  Lumora — Windows Installer (Inno Setup 6)
;  Built by CI from: build\windows\x64\runner\Release\
; ──────────────────────────────────────────────────────────────────────────────

#define MyAppName      "Lumora"
#ifndef MyAppVersion
#define MyAppVersion   "1.0.0"
#endif
#define MyAppPublisher "JTing904"
#define MyAppExeName   "zplay.exe"
#define MyAppURL       "https://github.com/JTing904/Lumora"

[Setup]
AppId={{4E2A7C51-8B3D-4F6E-9A1C-2D5B7E8F0A36}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
OutputDir=Output
OutputBaseFilename=Lumora-Windows-Setup
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
PrivilegesRequired=lowest
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
; Clean up old files that might conflict with new version
Type: filesandordirs; Name: "{app}\data\flutter_assets\*"
Type: files; Name: "{app}\*.dll.old"

[Icons]
Name: "{group}\{#MyAppName}";    Filename: "{app}\{#MyAppExeName}"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
