#define AppName "SSPU-AllinOne"
#define AppPublisher "Qintsg"
#define AppExeName "sspu_allinone.exe"
#define AppVersion GetEnv("APP_VERSION")
#define WorkspaceDir GetEnv("GITHUB_WORKSPACE")

[Setup]
AppId={{3657CB2B-B935-4DE9-A7F2-FFA5E5FB1C8E}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
OutputDir={#WorkspaceDir}\dist
OutputBaseFilename=SSPU-AllinOne-v{#AppVersion}-windows-x64-installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile={#WorkspaceDir}\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#WorkspaceDir}\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
