#define AppTechnicalName "SSPU-AllinOne"
#define AppPublisher "Qintsg"
#define AppExeName "sspu_allinone.exe"
#define AppVersion GetEnv("APP_VERSION")
#define WorkspaceDir GetEnv("GITHUB_WORKSPACE")
#define BundleDir GetEnv("WINDOWS_ARM64_BUNDLE_DIR")

[Setup]
AppId={{F35768C5-7743-48E7-A7D0-F9923B7D1795}
AppName={code:GetAppDisplayName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
LicenseFile={#WorkspaceDir}\assets\legal\legal_zh.txt
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
DefaultDirName={autopf}\{code:GetAppDisplayName}
DefaultGroupName={code:GetAppDisplayName}
DisableProgramGroupPage=yes
OutputDir={#WorkspaceDir}\dist
OutputBaseFilename=SSPU-AllinOne-v{#AppVersion}-windows-arm64-installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
SetupIconFile={#WorkspaceDir}\windows\runner\resources\app_icon.ico
UninstallDisplayName={code:GetAppDisplayName}
UninstallDisplayIcon={app}\{#AppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{code:GetAppDisplayName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{code:GetAppDisplayName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{code:GetAppDisplayName}}"; Flags: nowait postinstall skipifsilent

[Code]
function GetUserDefaultUILanguage: Integer;
  external 'GetUserDefaultUILanguage@kernel32.dll stdcall';

function GetAppDisplayName(Param: String): String;
begin
  if (GetUserDefaultUILanguage() and $03FF) = $0004 then
    Result := '工大聚合'
  else
    Result := '{#AppTechnicalName}';
end;
