unit EncryDecryTool;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,PJQ;
procedure EncryFile(inputfile:String; outfile:String);
procedure DecryFile(inputfile:String; outfile:String);
implementation

{$region '获取文件名'}
function GetFileName(path: string): string;
begin
  Result :=StringReplace(path,ExtractFilePath(path),'',[rfReplaceAll]);
end;
{$endregion}

{$region '加密文件'}
procedure EncryFile(inputfile:String; outfile:String);
var
FileStream,outFileStream: TFileStream;
key:String;
stream:TStream;
KeyBytes:Array[0..7] of Byte;
i:integer;
begin
  if FileExists(inputfile) then
  begin
    FileStream := TFileStream.Create(inputfile, fmOpenread);
    key:= CreateKey();
    stream:=EncryStream(FileStream,key);
    FileStream.Free;
    for i := 0 to 7 do
      KeyBytes[i]:=Byte(key[i+1]);
    outFileStream:=TFileStream.Create(outfile,fmCreate);
    outFileStream.Position:=0;
    stream.Position:=0;
    outFileStream.write(KeyBytes, Length(KeyBytes));
    i:=outFileStream.CopyFrom(stream,stream.Size);
    //ShowMessage(inttostr(i));
    stream.Free;
    outFileStream.Free;
  end;
end;
{$endregion}

{$region '解密文件'}
procedure DecryFile(inputfile:String; outfile:String);
var
  FileStream,outFileStream: TFileStream;
  key:AnsiString;
  stream,tempStream:TStream;
  buff:Array[0..7] of Byte;
  i:integer;
begin
  if FileExists(inputfile) then
  begin
    FileStream := TFileStream.Create(inputfile, fmOpenread or fmShareDenyRead);
    FileStream.Position:=0;
    FileStream.Read(buff[0],8);
    SetLength(key, 8);
    Move(buff[0], key[1], 8);
    stream:=TMemoryStream.Create;
    stream.CopyFrom(FileStream,FileStream.Size-8);
    stream:=DecryStream(Stream,key);
    FileStream.Free;

    outFileStream:=TFileStream.Create(outfile,fmCreate);
    outFileStream.Position:=0;
    stream.Position:=0;
    //outFileStream.write(KeyBytes, Length(KeyBytes));
    outFileStream.CopyFrom(stream,stream.Size);
    //ShowMessage(inttostr(i));
    stream.Free;
    outFileStream.Free;
  end;
end;
{$endregion}

function CreateDecryFileName(path: string):String;
var
  FilePath,FileName,name,tem_name:String;
  i:integer;
begin
  FilePath:=ExtractFilePath(path);
  FileName:=GetFileName(path);
  i:=LastDelimiter('.',FileName);
  name:=LeftStr(FileName,i-1);
  tem_name:=LeftStr(FileName,i-5);
  //FileName:=StringReplace(FileName,name,tem_name+'_dec',[rfReplaceAll]);
  Result:= FilePath+FileName;
end;

end.

