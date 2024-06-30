unit PJQ;

interface
uses SysUtils,Dialogs,Base64,Classes;

type charlist=Array of char;
type ByteArray=Array of Byte;
function EncryStrHex(Str, Key: AnsiString):String;
function DecryStrHex(Str, Key: AnsiString):String;
function DecryByteArray(source:Array of Byte;Key: AnsiString):ByteArray;
function DecryStream(stream:TStream;key:AnsiString):TStream;
function EncryStream(stream:TStream;key:AnsiString):TStream;
function StrToArray(Str:string):charlist;
//function ArrayToStr(ch:Array of Char):string;
function encryStrToStr(data,key:AnsiString):AnsiString;
function DecryStrToStr(data,key:AnsiString):AnsiString;
function CreateKey():string;
function CreateRandomStr(n:Cardinal):AnsiString;
function CreateRandomByte(n:Cardinal):ByteArray;

const DictionByte:Array[0..63] of Byte=(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,48,49,50,51,52,53,54,55,56,57,43,47);
const dictionary:array[0..63] of AnsiChar=('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/');
function indexOf(c:AnsiChar):Integer;overload;
function indexOf(b:Byte):Integer;overload;
implementation

//加密
function EncryStrHex(Str, Key: AnsiString):String;
var
en_str,ascii:AnsiString;
c,d,m,i,j,k,p:Integer;
arr:array of string;
source,temp:ByteArray;
KeyBytes:Array[0..7] of Byte;
//const dictionary:array[0..63] of char=('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/');
//buf:array[0..3] of Byte;
tem:Byte;
begin
  for i := 0 to 7 do
    KeyBytes[i]:=Byte(Key[i+1]);
  c:=Length(Str);
  SetLength(source,c+4);
  source[3]:=((c and $ff000000) shr 24);
source[2]:=((c and $00ff0000) shr 16);
source[1]:=((c and $0000ff00) shr 8);
source[0]:=c and $000000ff;
  for i:=1 to c do
    source[i+3]:=byte(Str[i]);
  //temp:=IntToHex(count,8);

  //en_str:=IntToHex(c,8)+Str;
  c:=Length(source);
  m:=c mod 64;//取余
  if m>0 then
  begin
    //SetLength(temp,64-m);
    temp:=CreateRandomByte(64-m);
    SetLength(source,c+64-m);
    for i := 0 to 64-m-1 do
      source[i+c]:=temp[i];
    //en_str:=en_str+ascii;
  end;
  c:=Length(source);
  d:=c div 64;//整取
  //SetLength(list,d);

  for i:=0 to d-1 do
  begin
    for j := 0 to 7 do
    begin
      for k := 0 to 7 do
      begin
        p:=indexOf(KeyBytes[k])+i*64+j*8+k;
        if p>63 then p:=p mod 64;
        tem:=source[i*64+j*8+k];
        source[i*64+j*8+k]:=source[p];
        source[p]:=tem;
      end;
    end;
  end;
  //showmessage(IntToStr(Length(ascii)));
  Result:=BytesToBase64(source);
end;
//解密
function DecryStrHex(Str,Key: AnsiString):String;
var
en_str,ascii:AnsiString;
c,d,m,i,j,k,p:Integer;
arr:array of string;
source,temp:Base64.ByteArray;
KeyBytes:Array[0..7] of Byte;
//const dictionary:array[0..63] of char=('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/');
//buf:array[0..3] of byte;
tem:Byte;
bf: record b1,b2,b3,b4: Byte end;
q: Integer absolute bf;
begin
  for i := 0 to 7 do
    KeyBytes[i]:=Byte(Key[i+1]);
  //en_str := StringReplace(Str,#$D#$A,'',[rfReplaceAll,rfIgnoreCase]);
  source:=Base64ToString(Str);
  //showmessage(IntToStr(Length(en_str)));
  c:=Length(source);
  m:=c mod 64;//取余
  if m<>0 then
  begin
    Result:='';
    exit;
  end;
  {en_str:=IntToHex(c,8)+Str;
  c:=Length(en_str);
  m:=c mod 64;//取余
  if m>0 then
  begin
    ascii:=CreateRandomStr(64-m);
    en_str:=en_str+ascii;
  end;}
  d:=c div 64;//整取
  ascii:='';
  for i:=d-1 downto 0 do
  begin
    for j := 7 downto 0 do
    begin
      for k := 7 downto 0 do
      begin
        p:=indexOf(KeyBytes[k])+i*64+j*8+k;
        if p>63 then p:=p mod 64;
        tem:=source[i*64+j*8+k];
        source[i*64+j*8+k]:=source[p];
        source[p]:=tem;
      end;
    end;
  end;
  bf.b1:=source[0];
  bf.b2:=source[1];
  bf.b3:=source[2];
  bf.b4:=source[3];
  //c:=TIntRec(buf).IntValue;
  //SetLength(source,q+4);
  if q>c then
  begin
    Result:='';
    exit;
  end;
  SetLength(en_str,q);
  for i := 0 to q - 1 do
  begin
    en_str[i+1]:=AnsiChar(source[i+4]);
  end;
  //Move(source[4],en_str[1],c);
Result:=en_str;
end;
{$region '解密字节流'}
function DecryByteArray(source:Array of Byte;Key: AnsiString):ByteArray;
var
ascii:AnsiString;
KeyBytes,temp:Array[0..7] of Byte;
c,d,m,i,j,k,p:Integer;
tem:Byte;
bf: record b1,b2,b3,b4: Byte end;
q: Integer absolute bf;
begin
  for i := 0 to 7 do
    KeyBytes[i]:=Byte(Key[i+1]);
  c:=Length(source);
  m:=c mod 64;//取余
  if m<>0 then
  begin
    Result:=nil;
    exit;
  end;
  {en_str:=IntToHex(c,8)+Str;
  c:=Length(en_str);
  m:=c mod 64;//取余
  if m>0 then
  begin
    ascii:=CreateRandomStr(64-m);
    en_str:=en_str+ascii;
  end;}
  d:=c div 64;//整取
  ascii:='';
  for i:=d-1 downto 0 do
  begin
    for j := 7 downto 0 do
    begin
      for k := 7 downto 0 do
      begin
        p:=indexOf(KeyBytes[k])+i*64+j*8+k;
        if p>63 then p:=p mod 64;
        tem:=source[i*64+j*8+k];
        source[i*64+j*8+k]:=source[p];
        source[p]:=tem;
      end;
    end;
  end;
  bf.b1:=source[0];
  bf.b2:=source[1];
  bf.b3:=source[2];
  bf.b4:=source[3];
  if q>c then
  begin
    Result:=nil;
    exit;
  end;
  SetLength(Result,q);
  for i := 0 to q - 1 do
  begin
    Result[i]:=source[i+4];
  end;
  //Result:=temp;
end;
{$endregion}
{$region '加密字节流'}
function EncryByteArray(source:Array of Byte;Key: AnsiString):ByteArray;
var
ascii:AnsiString;
KeyBytes,temp:Array[0..7] of Byte;
c,d,m,i,j,k,p:Integer;
tem:Byte;
{bf: record b1,b2,b3,b4: Byte end;
q: Integer absolute bf;}
begin
  for i := 0 to 7 do
    KeyBytes[i]:=Byte(Key[i+1]);
  c:=Length(source);
  {m:=c mod 64;//取余
  if m<>0 then
  begin
    Result:=nil;
    exit;
  end;}
  {en_str:=IntToHex(c,8)+Str;
  c:=Length(en_str);
  m:=c mod 64;//取余
  if m>0 then
  begin
    ascii:=CreateRandomStr(64-m);
    en_str:=en_str+ascii;
  end;}
  d:=c div 64;//整取
  ascii:='';
  for i:=0 to d-1 do
  begin
    for j := 0 to 7 do
    begin
      for k := 0 to 7 do
      begin
        p:=indexOf(KeyBytes[k])+i*64+j*8+k;
        if p>63 then p:=p mod 64;
        tem:=source[i*64+j*8+k];
        source[i*64+j*8+k]:=source[p];
        source[p]:=tem;
      end;
    end;
  end;
  {bf.b1:=source[0];
  bf.b2:=source[1];
  bf.b3:=source[2];
  bf.b4:=source[3];
  if q>c then
  begin
    Result:=nil;
    exit;
  end;}
  SetLength(Result,c);
  for i := 0 to c - 1 do
  begin
    Result[i]:=source[i];
  end;
  //Result:=temp;
end;
{$endregion}
{$region '解密流'}
function DecryStream(stream:TStream;key:AnsiString):TStream;
var
bytes:Array of Byte;
temp:ByteArray;
i,l,m:Integer;
begin
  l:=stream.Size;
  {m:=stream.Size mod 64;//取余
  if m<>0 then
    l:=stream.Size+64-m;}
  SetLength(bytes,l);
  stream.Position:=0;
  stream.Read(bytes[0],stream.Size);
  {for i := 0 to Length(bytes) - 1 do
  begin

  end;}
  temp:=DecryByteArray(bytes,key);
  Result:=TMemoryStream.create;
  Result.Write(temp[0],Length(temp));
  //Result:=stream;
end;
{$endregion}
{$region '加密流'}
function EncryStream(stream:TStream;key:AnsiString):TStream;
var
  bytes:Array of Byte;
  temp:ByteArray;
  i,l,m:Integer;
  bf: record b1,b2,b3,b4: Byte end;
  q: Integer absolute bf;
begin
  q:=stream.Size;
  l:=q+4;
  m:=l mod 64;//取余
  if m<>0 then
    l:=l+64-m;
  SetLength(bytes,l);
  bytes[0]:=bf.b1;
  bytes[1]:=bf.b2;
  bytes[2]:=bf.b3;
  bytes[3]:=bf.b4;
  stream.Position:=0;
  stream.Read(bytes[4],stream.Size);
  temp:=EncryByteArray(bytes,key);
  Result:=TMemoryStream.create;
  Result.Write(temp[0],Length(temp));
end;
{$endregion}

//分组加密-字符串>字符串
function encryStrToStr(data,key:AnsiString):AnsiString;
var
p:Integer;
tem:AnsiChar;
i:Integer;
j:Integer;
//const diction:string='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
begin
  for j := 0 to 7 do
  begin
    for i := 1 to 8 do
    begin
      p:=indexOf(key[i])+i+j*8;
      if p>64 then p:=p mod 64;
      tem:=data[i+j*8];
      data[i+j*8]:=data[p];
      data[p]:=tem;
    end;
  end;
  //showmessage(IntToStr(Length(data)));
  Result:=data;
end;
//分组解密-字符串>字符串
function DecryStrToStr(data,key:AnsiString):AnsiString;
var
p:Integer;
tem:AnsiChar;
i:Integer;
j:Integer;
//const diction:string='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
begin
  showmessage(IntToStr(Length(data)));
  for j := 7 downto 0 do
  begin
    for i := 8 downto 1 do
    begin
      p:=indexOf(key[i])+i+j*8;
      if p>64 then p:=p mod 64;
      tem:=data[i+j*8];
      data[i+j*8]:=data[p];
      data[p]:=tem;
    end;
  end;
  Result:=data;
end;
//字符串转数组
function StrToArray(Str:string):charlist;
var
i:Integer;
ch:charlist;
begin
  for i := 0 to 63 do
    ch[i] := Str[i];
  Result:=ch;
end;
{$region '随机产生8位秘钥'}
function CreateKey():string;
var
i:Integer;
str:string;
const diction:string[64]='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
begin
  str:='';
  for i := 1 to 8 do
  begin
    str:=str+diction[Random(64)+1];

  end;
  Result:=str;
end;
{$endregion}
//随机产生一串字符
function CreateRandomStr(n:Cardinal):AnsiString;
var
i:Integer;
str:AnsiString;

begin
  for i := 0 to n - 1 do
  begin
    str:=str+dictionary[random(64)];
  end;
  Result:=str;
end;
//随机产生一串字节数组
function CreateRandomByte(n:Cardinal):ByteArray;
var
i:Integer;
ba:ByteArray;
begin
  SetLength(ba,n);
  for i := 0 to n - 1 do
  begin
    ba[i]:=DictionByte[random(64)];
  end;
  Result:=ba;
end;
//查找字符的索引位置
function indexOf(c:AnsiChar):Integer;overload;
var
i:Integer;
r:Integer;
begin
  r:=-1;
  for i := 0 to 63 do
  begin
    if c=dictionary[i] then
    begin
      r:=i;
      break;
    end;
  end;
  Result:=r;
end;
//查找字节的索引位置
function indexOf(b:Byte):Integer;overload;
var
i:Integer;
r:Integer;
begin
  r:=-1;
  for i := 0 to 63 do
  begin
    if b=DictionByte[i] then
    begin
      r:=i;
      break;
    end;
  end;
  Result:=r;
end;
end.
