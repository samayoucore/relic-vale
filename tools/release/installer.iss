#ifndef GameVersion
  #error GameVersion must be supplied by the build script
#endif
[Setup]
AppId={{0FBCACD7-1CE1-4B3E-AC16-786B08E6D924}
AppName=Relic Vale
AppVersion={#GameVersion}
AppPublisher=Relic Vale
DefaultDirName={localappdata}\Programs\Relic Vale
DefaultGroupName=Relic Vale
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
DisableProgramGroupPage=yes
OutputDir={#OutputPath}
OutputBaseFilename=RelicVale-{#GameVersion}-Setup
SetupIconFile={#IconPath}
UninstallDisplayIcon={app}\RelicVale.exe
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
UninstallLogMode=append
VersionInfoVersion={#GameVersion}.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourcePath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Relic Vale"; Filename: "{app}\RelicVale.exe"; WorkingDir: "{app}"
Name: "{group}\Relic Vale - Safe Mode"; Filename: "{app}\RelicVale.exe"; Parameters: "-- --safe-mode"; WorkingDir: "{app}"
Name: "{group}\Read Me"; Filename: "{app}\README.txt"
Name: "{group}\Uninstall Relic Vale"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Relic Vale"; Filename: "{app}\RelicVale.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\RelicVale.exe"; Description: "{cm:LaunchProgram,Relic Vale}"; Flags: nowait postinstall skipifsilent

; No UninstallDelete entry: user:// saves, settings and logs are preserved.
