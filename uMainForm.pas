unit uMainForm;

{$I cef.inc}

interface

uses
  {$IFDEF DELPHI16_UP}
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  {$ELSE}
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls,
  {$ENDIF}
  uCEFChromium, uCEFChromiumWindow, uCEFInterfaces, uCustomResourceHandler,
  uCEFConstants, uCEFTypes,EncryDecryTool,PjQ,tools;
const
  MINIBROWSER_SHOWDEVTOOLS     = WM_APP + $101;
  MINIBROWSER_HIDEDEVTOOLS     = WM_APP + $102;
  APPLICATION_TERMINATE        = WM_APP + $103;
type

  { TMainForm }

  TMainForm = class(TForm)
    ChromiumWindow1: TChromiumWindow;
    AddressBarPnl: TPanel;
    Edit1: TEdit;
    Button1: TButton;
    Timer1: TTimer;
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ChromiumWindow1Close(Sender: TObject);
    procedure ChromiumWindow1BeforeClose(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

  private
    procedure WMMove(var aMessage : TWMMove); message WM_MOVE;
    procedure WMMoving(var aMessage : TMessage); message WM_MOVING;
    procedure WMEnterMenuLoop(var aMessage: TMessage); message WM_ENTERMENULOOP;
    procedure WMExitMenuLoop(var aMessage: TMessage); message WM_EXITMENULOOP;

  protected
    // Variables to control when can we destroy the form safely
    FCanClose : boolean;  // Set to True in TChromium.OnBeforeClose
    FClosing  : boolean;  // Set to True in the CloseQuery event.

    procedure Chromium_OnAfterCreated(Sender: TObject);
    procedure Chromium_OnGetResourceHandler(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const request: ICefRequest; var Result: ICefResourceHandler);
    procedure Chromium_OnBeforePopup(Sender: TObject; const browser: ICefBrowser; const frame: ICefFrame; const targetUrl, targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean; const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient; var settings: TCefBrowserSettings; var extra_info: ICefDictionaryValue; var noJavascriptAccess: Boolean; var Result: Boolean);
    {function Chromium_OnKeyEvent(browser: ICefBrowser; event: PCefKeyEvent;
                        eventType: TCefKeyEventType; modifiers: TCefEventFlags;
                        isSystemKey: Boolean; out result: Boolean): HRESULT; stdcall;}
    procedure ShowDevToolsMsg(var aMessage : TMessage); message MINIBROWSER_SHOWDEVTOOLS;
    procedure HideDevToolsMsg(var aMessage : TMessage); message MINIBROWSER_HIDEDEVTOOLS;
    procedure ApplicationExit(var aMessage : TMessage); message APPLICATION_TERMINATE;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
                      
procedure CreateGlobalCEFApp;

implementation

{$R *.lfm}

uses
  uCEFv8Value, uMyV8Accessor,uMyV8Handler,uCEFMiscFunctions, uCEFApplication;

{$region '解密'}
function DecryFile(FileStream:TFileStream):TStream;
var
  //FileStream: TFileStream;
  key:AnsiString;
  stream:TStream;
  buff:Array[0..7] of Byte;
  i:integer;
begin
    //FileStream := TFileStream.Create(inputfile, fmOpenread or fmShareDenyRead);
    FileStream.Position:=0;
    FileStream.Read(buff[0],8);
    SetLength(key, 8);
    Move(buff[0], key[1], 8);
    stream:=TMemoryStream.Create;
    stream.CopyFrom(FileStream,FileStream.Size-8);
    stream:=DecryStream(Stream,key);
    FileStream.Free;
    Result := stream;
    {outFileStream:=TFileStream.Create(outfile,fmCreate);
    outFileStream.Position:=0;
    stream.Position:=0;
    //outFileStream.write(KeyBytes, Length(KeyBytes));
    outFileStream.CopyFrom(stream,stream.Size);
    //ShowMessage(inttostr(i));
    stream.Free;
    outFileStream.Free;}
end;
{$endregion}
// Destruction steps
// =================
// 1. The FormCloseQuery event sets CanClose to False and calls TChromiumWindow.CloseBrowser, which triggers the TChromiumWindow.OnClose event.
// 2. The TChromiumWindow.OnClose event calls TChromiumWindow.DestroyChildWindow which triggers the TChromiumWindow.OnBeforeClose event.
// 3. TChromiumWindow.OnBeforeClose sets FCanClose := True and sends WM_CLOSE to the form.

procedure GlobalCEFApp_OnContextCreated(const browser: ICefBrowser; const frame: ICefFrame; const context: ICefv8Context);
var
  TempAccessor : ICefV8Accessor;
  TempObject   : ICefv8Value;

  TempHandler  : ICefv8Handler;
  TempFunction : ICefv8Value;
begin

  TempAccessor := TMyV8Accessor.Create;
  TempObject   := TCefv8ValueRef.NewObject(TempAccessor, nil);
  TempObject.SetValueByKey('MACAdress', TCefv8ValueRef.NewString(getMACAdress), V8_PROPERTY_ATTRIBUTE_NONE);
  TempObject.SetValueByKey('version', TCefv8ValueRef.NewString('1'), V8_PROPERTY_ATTRIBUTE_NONE);

  TempHandler  := TMyV8Handler.Create;
  TempFunction := TCefv8ValueRef.NewFunction('exit', TempHandler);
  TempObject.SetValueByKey('exit', TempFunction, V8_PROPERTY_ATTRIBUTE_NONE);

  context.Global.SetValueByKey('CEFObject', TempObject, V8_PROPERTY_ATTRIBUTE_NONE);
end;

procedure CreateGlobalCEFApp;
begin
  GlobalCEFApp                  := TCefApplication.Create;
  GlobalCEFApp.OnContextCreated := GlobalCEFApp_OnContextCreated;
  GlobalCEFApp.SetCurrentDir    := True;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := FCanClose;

  if not(FClosing) then
    begin
      FClosing := True;
      Visible  := False;
      ChromiumWindow1.CloseBrowser(True);
    end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCanClose := False;
  FClosing  := False;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  ChromiumWindow1.OnAfterCreated                       := Chromium_OnAfterCreated;
  ChromiumWindow1.ChromiumBrowser.OnGetResourceHandler := Chromium_OnGetResourceHandler;
  ChromiumWindow1.ChromiumBrowser.OnBeforePopup        := Chromium_OnBeforePopup;
  //ChromiumWindow1.ChromiumBrowser.OnKeyEvent           := Chromium_OnKeyEvent;
  //ChromiumWindow1.ChromiumBrowser.
  //ChromiumWindow1.CreateBrowser
  // GlobalCEFApp.GlobalContextInitialized has to be TRUE before creating any browser
  // If it's not initialized yet, we use a simple timer to create the browser later.
  if not(ChromiumWindow1.CreateBrowser) then Timer1.Enabled := True;
end;

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  OutputDebugString(PChar(IntToStr(Key)));
  case Key of
    //F12
    123: PostMessage(Handle, MINIBROWSER_SHOWDEVTOOLS, 0, 0);
    //F5
    116: ChromiumWindow1.ChromiumBrowser.Reload;
  end;
end;

procedure TMainForm.ChromiumWindow1BeforeClose(Sender: TObject);
begin
  FCanClose := True;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  if not(ChromiumWindow1.CreateBrowser) and not(ChromiumWindow1.Initialized) then
    Timer1.Enabled := True;
end;

procedure TMainForm.ChromiumWindow1Close(Sender: TObject);
begin
  // DestroyChildWindow will destroy the child window created by CEF at the top of the Z order.
  if not(ChromiumWindow1.DestroyChildWindow) then
    begin
      FCanClose := True;
      PostMessage(Handle, WM_CLOSE, 0, 0);
    end;
end;

procedure TMainForm.Chromium_OnAfterCreated(Sender: TObject);
begin
  OutputDebugString(PChar('Chromium_OnAfterCreated'));
  //ChromiumWindow1.UpdateSize;
  ChromiumWindow1.LoadURL('http://localhost/');
  //tempPoint:=TPoint.Create(0,0);
  PostMessage(Handle, MINIBROWSER_SHOWDEVTOOLS, 0, 0);
end;

procedure TMainForm.Chromium_OnGetResourceHandler(Sender : TObject;
                                                  const browser : ICefBrowser;
                                                  const frame   : ICefFrame;
                                                  const request : ICefRequest;
                                                  var   Result  : ICefResourceHandler);
var
  TempStream : TStringStream;
  url:string;
  FileStream:TFileStream;
  stream:TStream;
  p: Integer;
begin
  // This event is called from the IO thread. Use mutexes if necessary.
  TempStream := nil;
  Result     := nil;
  //MessageDlg(request.Url, mtConfirmation, mbYesNo, 0);
  url:= StringReplace(request.Url,'http://localhost/','',[]);
  //OutputDebugString(PChar(url));
  p:=Pos('devtools://',url);
  if p>0 then
    begin
      Result:=nil;
      exit;
    end;

  if url='' then
    begin
      url:='\dist\index.html';
    end
  else
    begin
      url:='\dist\'+url;
    end;
  try
    try
      //WriteLn(GetCurrentDir +url);
      p:=Pos('?',url);
      if p>0 then Delete(url,p,1000);
      //ShowMessage(url);
      OutputDebugString(PChar(url));
      FileStream:=TFileStream.Create(GetCurrentDir +url, fmOpenread);
      //stream:=DecryFile(FileStream);
      stream:=TMemoryStream.Create;
      stream.CopyFrom(FileStream,FileStream.Size);
      Result     := TCustomResourceHandler.Create(browser, frame, '', request, TStream(stream), CefGetMimeType('html'));
    except
      on e : exception do
        if CustomExceptionHandler('TMainForm.Chromium_OnGetResourceHandler', e) then raise;
    end;
    (*try
      TempStream := TStringStream.Create('<!DOCTYPE html><html><body><p>test</p></body></html>'{, TEncoding.UTF8, false});
      Result     := TCustomResourceHandler.Create(browser, frame, '', request, TStream(TempStream), CefGetMimeType('html'));
    except
      on e : exception do
        if CustomExceptionHandler('TMainForm.Chromium_OnGetResourceHandler', e) then raise;
    end;*)
  finally
    if (TempStream <> nil) then FreeAndNil(TempStream);
  end;
end;

procedure TMainForm.Chromium_OnBeforePopup(Sender: TObject;
  const browser: ICefBrowser; const frame: ICefFrame; const targetUrl,
  targetFrameName: ustring; targetDisposition: TCefWindowOpenDisposition;
  userGesture: Boolean; const popupFeatures: TCefPopupFeatures;
  var windowInfo: TCefWindowInfo; var client: ICefClient;
  var settings: TCefBrowserSettings;
  var extra_info: ICefDictionaryValue;
  var noJavascriptAccess: Boolean;
  var Result: Boolean);
begin
  // For simplicity, this demo blocks all popup windows and new tabs
  Result := (targetDisposition in [CEF_WOD_NEW_FOREGROUND_TAB, CEF_WOD_NEW_BACKGROUND_TAB, CEF_WOD_NEW_POPUP, CEF_WOD_NEW_WINDOW]);
end;

procedure TMainForm.WMMove(var aMessage : TWMMove);
begin
  inherited;

  if (ChromiumWindow1 <> nil) then ChromiumWindow1.NotifyMoveOrResizeStarted;
end;

procedure TMainForm.WMMoving(var aMessage : TMessage);
begin
  inherited;

  if (ChromiumWindow1 <> nil) then ChromiumWindow1.NotifyMoveOrResizeStarted;
end;

procedure TMainForm.WMEnterMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then GlobalCEFApp.OsmodalLoop := True;
end;

procedure TMainForm.WMExitMenuLoop(var aMessage: TMessage);
begin
  inherited;

  if (aMessage.wParam = 0) and (GlobalCEFApp <> nil) then GlobalCEFApp.OsmodalLoop := False;
end;

{$region '显示DevTools，消息执行'}
procedure TMainForm.ShowDevToolsMsg(var aMessage : TMessage);
var
  TempPoint : TPoint;
begin
  TempPoint.x := (aMessage.wParam shr 16) and $FFFF;
  TempPoint.y := aMessage.wParam and $FFFF;
  ChromiumWindow1.ChromiumBrowser.ShowDevTools(tempPoint);
end;
{$endregion}

{$region '隐藏DevTools，消息执行'}
procedure TMainForm.HideDevToolsMsg(var aMessage : TMessage);
begin
  //HideDevTools;
  ChromiumWindow1.SetFocus;
end;
{$endregion}

procedure TMainForm.ApplicationExit(var aMessage : TMessage);
begin
  OutputDebugString(PChar('TMainForm.ApplicationExit'));
  Application.Terminate;
end;

end.
