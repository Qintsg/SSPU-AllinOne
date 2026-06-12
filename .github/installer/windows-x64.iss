#define AppTechnicalName "SSPU-AllinOne"
#define AppPublisher "Qintsg"
#define AppExeName "sspu_allinone.exe"
#define AppVersion GetEnv("APP_VERSION")
#define WorkspaceDir GetEnv("GITHUB_WORKSPACE")

[Setup]
AppId={{3657CB2B-B935-4DE9-A7F2-FFA5E5FB1C8E}
AppName={code:GetAppDisplayName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
LicenseFile={#WorkspaceDir}\assets\legal\legal_zh.txt
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
UsePreviousAppDir=yes
UsePreviousPrivileges=yes
DefaultDirName={autopf}\{#AppTechnicalName}
DefaultGroupName={code:GetAppDisplayName}
DisableProgramGroupPage=yes
OutputDir={#WorkspaceDir}\dist
OutputBaseFilename=SSPU-AllinOne-v{#AppVersion}-windows-x64-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile={#WorkspaceDir}\windows\runner\resources\app_icon.ico
UninstallDisplayName={code:GetAppDisplayName}
UninstallDisplayIcon={app}\{#AppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
PrivilegesRequiredOverrideTitle=Select install scope / 选择安装范围
PrivilegesRequiredOverrideInstruction=Select install scope / 选择安装范围
PrivilegesRequiredOverrideText1=%1 can be installed for all Windows users (requires administrator privileges), or for the current user only.%n%n%1 可安装到所有 Windows 用户（需要管理员权限），也可仅安装到当前用户。
PrivilegesRequiredOverrideText2=%1 can be installed for the current user only, or for all Windows users (requires administrator privileges).%n%n%1 可仅安装到当前用户，也可安装到所有 Windows 用户（需要管理员权限）。
PrivilegesRequiredOverrideAllUsers=Install for &all users / 为所有用户安装
PrivilegesRequiredOverrideAllUsersRecommended=Install for &all users (recommended) / 为所有用户安装（推荐）
PrivilegesRequiredOverrideCurrentUser=Install for &me only / 仅为当前用户安装
PrivilegesRequiredOverrideCurrentUserRecommended=Install for &me only (recommended) / 仅为当前用户安装（推荐）

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#WorkspaceDir}\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{code:GetAppDisplayName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{code:GetAppDisplayName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{code:GetAppDisplayName}}"; Flags: nowait postinstall skipifsilent

[Code]
const
  UninstallRegKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{3657CB2B-B935-4DE9-A7F2-FFA5E5FB1C8E}_is1';

var
  ExistingInstallFound: Boolean;
  ExistingInstallIsSameVersion: Boolean;
  ExistingInstallLocation: String;
  ExistingInstallVersion: String;
  ExistingUninstallString: String;
  KeepAppDataAfterUninstall: Boolean;

function GetUserDefaultUILanguage: Integer;
  external 'GetUserDefaultUILanguage@kernel32.dll stdcall';

function IsChineseUserInterface(): Boolean;
begin
  Result := (GetUserDefaultUILanguage() and $03FF) = $0004;
end;

function GetAppDisplayName(Param: String): String;
begin
  if IsChineseUserInterface() then
    Result := '工大聚合'
  else
    Result := '{#AppTechnicalName}';
end;

function ExtractExecutablePath(CommandLine: String): String;
var
  EndQuotePosition: Integer;
begin
  Result := Trim(CommandLine);
  if Result = '' then
    Exit;

  if Copy(Result, 1, 1) = '"' then begin
    Delete(Result, 1, 1);
    EndQuotePosition := Pos('"', Result);
    if EndQuotePosition > 0 then
      Result := Copy(Result, 1, EndQuotePosition - 1);
  end;
end;

function SameVersionReinstallPrompt(): String;
begin
  if IsChineseUserInterface() then
    Result := '已安装相同版本的 ' + GetAppDisplayName('') + '。是否先卸载当前版本，然后重新进入安装流程？'
  else
    Result := 'The same version of ' + GetAppDisplayName('') + ' is already installed. Uninstall it first, then restart setup?';
end;

function KeepAppDataPrompt(): String;
begin
  if IsChineseUserInterface() then
    Result := '是否保留应用数据？选择“是”会保留用户目录下的 .sspu-aio；选择“否”会在卸载完成后删除该目录。'
  else
    Result := 'Keep application data? Choose Yes to keep .sspu-aio under your user profile; choose No to delete it after uninstall finishes.';
end;

function ReinstallUninstallFailedMessage(): String;
begin
  if IsChineseUserInterface() then
    Result := '卸载当前版本失败，无法继续重新安装。'
  else
    Result := 'Failed to uninstall the current version. Setup cannot continue reinstalling.';
end;

function RelaunchSetupFailedMessage(): String;
begin
  if IsChineseUserInterface() then
    Result := '重新启动安装流程失败。请手动再次运行安装器。'
  else
    Result := 'Failed to restart setup. Please run the installer again manually.';
end;

function DetectExistingInstallInRoot(RootKey: Integer; ScopeLabel: String): Boolean;
begin
  Result := False;
  if not RegKeyExists(RootKey, UninstallRegKey) then
    Exit;

  RegQueryStringValue(RootKey, UninstallRegKey, 'DisplayVersion', ExistingInstallVersion);
  RegQueryStringValue(RootKey, UninstallRegKey, 'InstallLocation', ExistingInstallLocation);
  RegQueryStringValue(RootKey, UninstallRegKey, 'UninstallString', ExistingUninstallString);

  ExistingInstallFound := True;
  ExistingInstallIsSameVersion := ExistingInstallVersion = '{#AppVersion}';
  Result := True;

  Log('Detected existing SSPU-AllinOne ' + ScopeLabel + ' install: version=' + ExistingInstallVersion + ', location=' + ExistingInstallLocation);
end;

procedure DetectExistingInstall();
begin
  ExistingInstallFound := False;
  ExistingInstallIsSameVersion := False;
  ExistingInstallLocation := '';
  ExistingInstallVersion := '';
  ExistingUninstallString := '';

  if not DetectExistingInstallInRoot(HKCU, 'current-user') then
    DetectExistingInstallInRoot(HKLM, 'all-users');
end;

function ShouldForceReinstall(): Boolean;
begin
  Result := ExpandConstant('{param:SSPUREINSTALL|0}') = '1';
end;

function IsReinstallContinuation(): Boolean;
begin
  Result := ExpandConstant('{param:SSPU_REINSTALL_CONTINUE|0}') = '1';
end;

function ConfirmSameVersionReinstall(): Boolean;
begin
  if ShouldForceReinstall() then begin
    Result := True;
    Exit;
  end;

  Result := SuppressibleMsgBox(
    SameVersionReinstallPrompt(),
    mbConfirmation,
    MB_YESNO or MB_DEFBUTTON2,
    IDNO
  ) = IDYES;
end;

function RunExistingUninstaller(): Boolean;
var
  ResultCode: Integer;
  UninstallerPath: String;
  UninstallerParams: String;
begin
  UninstallerPath := ExtractExecutablePath(ExistingUninstallString);
  if (UninstallerPath = '') or (not FileExists(UninstallerPath)) then begin
    Log('Existing uninstaller was not found: ' + ExistingUninstallString);
    Result := False;
    Exit;
  end;

  UninstallerParams := '/SILENT /NORESTART';
  if WizardSilent then
    UninstallerParams := '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SSPUKEEPAPPDATA=1';

  Log('Running existing uninstaller before reinstall: ' + UninstallerPath + ' ' + UninstallerParams);
  Result := Exec(UninstallerPath, UninstallerParams, '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
  if not Result then
    Log('Existing uninstaller failed with exit code ' + IntToStr(ResultCode));
end;

function RelaunchSetupAfterReinstall(): Boolean;
var
  ResultCode: Integer;
  RelaunchParams: String;
begin
  RelaunchParams := '/SP- /SSPU_REINSTALL_CONTINUE=1 /LANG=' + ExpandConstant('{language}');
  Result := Exec(ExpandConstant('{srcexe}'), RelaunchParams, '', SW_SHOWNORMAL, ewNoWait, ResultCode);
  if not Result then
    Log('Failed to relaunch setup after reinstall handoff.');
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if IsReinstallContinuation() then
    Exit;

  DetectExistingInstall();
  if not ExistingInstallFound then
    Exit;

  if not ExistingInstallIsSameVersion then begin
    Log('Preparing upgrade install; previous install scope and directory are preserved by UsePreviousPrivileges/UsePreviousAppDir.');
    Exit;
  end;

  if not ConfirmSameVersionReinstall() then begin
    Log('User cancelled same-version reinstall.');
    Result := False;
    Exit;
  end;

  if not RunExistingUninstaller() then begin
    SuppressibleMsgBox(ReinstallUninstallFailedMessage(), mbError, MB_OK, IDOK);
    Result := False;
    Exit;
  end;

  if WizardSilent then
    Exit;

  if not RelaunchSetupAfterReinstall() then
    SuppressibleMsgBox(RelaunchSetupFailedMessage(), mbError, MB_OK, IDOK);

  Result := False;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := ExistingInstallFound and (not ExistingInstallIsSameVersion) and (PageID = wpSelectDir);
end;

function InitializeUninstall(): Boolean;
var
  KeepAppDataParam: String;
begin
  KeepAppDataParam := ExpandConstant('{param:SSPUKEEPAPPDATA|ask}');
  if KeepAppDataParam = '1' then
    KeepAppDataAfterUninstall := True
  else if KeepAppDataParam = '0' then
    KeepAppDataAfterUninstall := False
  else
    KeepAppDataAfterUninstall := SuppressibleMsgBox(
      KeepAppDataPrompt(),
      mbConfirmation,
      MB_YESNO or MB_DEFBUTTON1,
      IDYES
    ) = IDYES;

  Result := True;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  AppDataPath: String;
begin
  if CurUninstallStep <> usPostUninstall then
    Exit;

  if KeepAppDataAfterUninstall then begin
    Log('Keeping SSPU-AllinOne application data after uninstall.');
    Exit;
  end;

  AppDataPath := ExpandConstant('{userprofile}\.sspu-aio');
  Log('Removing SSPU-AllinOne application data: ' + AppDataPath);
  DelTree(AppDataPath, True, True, True);
end;
