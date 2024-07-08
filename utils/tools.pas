unit tools;

{$mode Delphi}

interface

uses
  Windows,Classes, SysUtils,Nb30,regexpr,ComObj,Forms;
var
  app:TApplication;
function GetMACAdress: string;
function RunDosCommand(Command: string): string;
function GetGUID:string;

implementation

{$region '执行命令'}
function RunDosCommand(Command: string): string;
var
  hReadPipe: THandle;
  hWritePipe: THandle;
  SI: TStartUpInfo;
  PI: TProcessInformation;
  SA: TSecurityAttributes;
  //     SD   :   TSecurityDescriptor;
  BytesRead: DWORD;
  Dest: AnsiString;
  TmpList: TStringList;
  Avail, ExitCode, wrResult: DWORD;
  osVer: TOSVERSIONINFO;
  tmpstr: AnsiString;
begin
  SetLength(Dest, 1024);
  osVer.dwOSVersionInfoSize := Sizeof(TOSVERSIONINFO);
  GetVersionEX(osVer);

  if osVer.dwPlatformId = VER_PLATFORM_WIN32_NT then
  begin
  //         InitializeSecurityDescriptor(@SD,   SECURITY_DESCRIPTOR_REVISION);
  //         SetSecurityDescriptorDacl(@SD,   True,   nil,   False);
    SA.nLength := SizeOf(SA);
    SA.lpSecurityDescriptor := nil; //@SD;
    SA.bInheritHandle := True;
    CreatePipe(hReadPipe, hWritePipe, @SA, 0);
  end
  else
    CreatePipe(hReadPipe, hWritePipe, nil, 1024);
  try
    FillChar(SI, SizeOf(SI), 0);
    SI.cb := SizeOf(TStartUpInfo);
    SI.wShowWindow := SW_HIDE;
    SI.dwFlags := STARTF_USESHOWWINDOW;
    SI.dwFlags := SI.dwFlags or STARTF_USESTDHANDLES;
    SI.hStdOutput := hWritePipe;
    SI.hStdError := hWritePipe;
    if CreateProcess(nil, PChar(@Command[1]), nil, nil, True, NORMAL_PRIORITY_CLASS, nil, nil, SI, PI) then
    begin
      ExitCode := 0;
      while ExitCode = 0 do
      begin
        wrResult := WaitForSingleObject(PI.hProcess, 500);
  //                 if   PeekNamedPipe(hReadPipe,   nil,   0,   nil,   @Avail,   nil)   then
        if PeekNamedPipe(hReadPipe, @Dest[1], 1024, @Avail, nil, nil) then
        begin
          if Avail > 0 then
          begin
            TmpList := TStringList.Create;
            try
              FillChar(Dest[1], Length(Dest) * SizeOf(Char), 0);
              ReadFile(hReadPipe, Dest[1], Avail, BytesRead, nil);
              TmpStr := Copy(Dest, 0, BytesRead - 1);
              TmpList.Text := TmpStr;
              Result := tmpstr;
            finally
              TmpList.Free;
            end;
          end;
        end;
        if wrResult <> WAIT_TIMEOUT then ExitCode := 1;
      end;
      GetExitCodeProcess(PI.hProcess, ExitCode);
      CloseHandle(PI.hProcess);
      CloseHandle(PI.hThread);
    end;
  finally
    CloseHandle(hReadPipe);
    CloseHandle(hWritePipe);
  end;
end;
{$endregion}

{$region '获取网卡地址'}
function GetMACAdress: string;
var
Rgr_str:string;
Rgr_str1:string;
Rgr: TRegExpr;
text:string;
begin
Result := '';
Rgr_str:='[\d\w]{2}-[\d\w]{2}-[\d\w]{2}-[\d\w]{2}-[\d\w]{2}-[\d\w]{2}';
//Rgr_str1:='[\d\w-]{17}';
Rgr:=TRegExpr.Create;
Rgr.Expression:=Rgr_str;
text:=RunDosCommand('getmac -v');
//OutputDebugString(PChar(text));
if Rgr.Exec(text) then
  begin
    text :=Rgr.Match[0];
    Result := Rgr.Match[0];
    {Rgr.Expression:=Rgr_str1;
    if Rgr.Exec(text) then
      Result := Rgr.Match[0];}
  end;
end;
{$endregion}

{$region 'GUID'}
function GetGUID:string;
var
  //AGuid: TGUID;
  sGUID: string;
begin
  sGUID := CreateClassID;
  //ShowMessage(sGUID); // Á½±ß´ø´óÀ¨ºÅµÄGuid
  Delete(sGUID, 1, 1);
  Delete(sGUID, Length(sGUID), 1);
  //ShowMessage(sGUID); // È¥µô´óÀ¨ºÅµÄGuid£¬Õ¼36Î»ÖÐ¼äÓÐ¼õºÅ
  sGUID:= StringReplace(sGUID, '-', '', [rfReplaceAll]);
  //ShowMessage(sGUID); // È¥µô¼õºÅµÄGuid£¬Õ¼32Î»
  Result:=sGUID;
end;
{$endregion}


end.

