; ──────────────────────────────────────────────────────────────────────────────
;  Lumora — Windows Installer (Inno Setup 6)
;  Built by CI from: build\windows\x64\runner\Release\
; ──────────────────────────────────────────────────────────────────────────────

#define MyAppName      "Lumora"
#ifndef MyAppVersion
#define MyAppVersion   "1.0.1"
#endif
#define MyAppPublisher "JTing904"
#define MyAppExeName   "Lumora.exe"
#define MyAppURL       "https://github.com/JTing904/Lumora"
; Must match SetCurrentProcessExplicitAppUserModelID in windows/runner/main.cpp,
; or a pinned shortcut and the running window get separate taskbar buttons.
#define MyAppUserModelID "io.github.jting904.lumora"
; The sign-in link scheme lib/services/platform/url_scheme.dart registers.
#define MyAppUrlScheme "io.github.jting904.lumora"

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
; The program was zplay.exe up to 1.0.0
Type: files; Name: "{app}\zplay.exe"

[Icons]
Name: "{group}\{#MyAppName}";    Filename: "{app}\{#MyAppExeName}"; AppUserModelID: "{#MyAppUserModelID}"
Name: "{userdesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; AppUserModelID: "{#MyAppUserModelID}"; Tasks: desktopicon

[Registry]
; The app registers this per-user scheme itself on every start (it also has to
; work from the portable ZIP). Writing it here too makes a sign-in link work
; before the first launch, and uninsdeletekey removes it on uninstall so no
; dead handler is left pointing at a deleted exe. An old ZPlay install is a
; separate product with its own uninstaller and is not touched.
Root: HKCU; Subkey: "Software\Classes\{#MyAppUrlScheme}"; ValueType: string; ValueName: ""; ValueData: "URL:{#MyAppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\{#MyAppUrlScheme}"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\{#MyAppUrlScheme}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
