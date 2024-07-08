unit uMyV8Handler;

{$MODE Delphi}

{$I cef.inc}

interface

uses
  Windows,uCEFTypes, uCEFInterfaces, uCEFv8Value, uCEFv8Handler,Classes,tools;
var
  CommandList:TStringList;
type
  TMyV8Handler = class(TCefv8HandlerOwn)
    protected
      function Execute(const name: ustring; const obj: ICefv8Value; const arguments: TCefv8ValueArray; var retval: ICefv8Value; var exception: ustring): Boolean; override;
  end;

implementation

function TMyV8Handler.Execute(const name      : ustring;
                              const obj       : ICefv8Value;
                              const arguments : TCefv8ValueArray;
                              var   retval    : ICefv8Value;
                              var   exception : ustring): Boolean;
begin
  {if (name = 'myfunc') then
    begin
      retval := TCefv8ValueRef.NewString('My Function Value!');
      Result := True;
    end
   else
    Result := False;}
  case CommandList.IndexOf(name) of
    //exit
    0:
      begin
        app.Terminate;
        //retval := TCefv8ValueRef.NewString('Application.exit');
        Result := False;
      end;
    1:begin
      //getMACAdress
      //OutputDebugString(PChar(name));
      retval := TCefv8ValueRef.NewString(GetMACAdress);
      Result := True;
    end
    else
      begin
        retval := TCefv8ValueRef.NewString('My Function Value!');
        Result := True;
      end;
  end;
end;

initialization
CommandList := TStringList.Create;
CommandList.Add('exit');
CommandList.Add('getMACAdress');

end.
