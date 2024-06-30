unit Base64;

interface
uses Math;
type ByteArray=Array of Byte;
function BytesToBase64(const Value: array of Byte): AnsiString;
function Base64ToString(const Value: string): ByteArray;
function GetBase64Index(c:AnsiChar):Integer;
implementation
{============================
*函数名：BytesToBase64*
*作者：*
*时间：2005.11.29 15.25 *
*说明：实现字符转换*
============================}
function BytesToBase64(const Value: array of Byte): AnsiString;
var
  c: Byte;
  n, l: Integer;
  Count: Integer;
  DOut: array[0..3] of Byte;
  Table : AnsiString;
begin
  Table :='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  setlength(Result, ceil(Length(Value)/3)*4);
  //setlength(Result, ((Length(Value)+1) div 3) * 4);
  l := 1;
  Count := 0;
  while Count < Length(Value) do
  begin
    c := Ord(Value[Count]);
    Inc(Count);
    DOut[0] := (c and $FC) shr 2;
    DOut[1] := (c and $03) shl 4;
    if Count < Length(Value) then
    begin
      c := Ord(Value[Count]);
      Inc(Count);
      DOut[1] := DOut[1] + (c and $F0) shr 4;
      DOut[2] := (c and $0F) shl 2;
      if Count < Length(Value) then
      begin
        c := Ord(Value[Count]);
        Inc(Count);
        DOut[2] := DOut[2] + (c and $C0) shr 6;
        DOut[3] := (c and $3F);
      end
      else
      begin
        DOut[3] := $40;
      end;
    end
    else
    begin
      DOut[2] := $40;
      DOut[3] := $40;
    end;
    for n := 0 to 3 do
    begin
      Result[l] := Table[DOut[n] + 1];
      Inc(l);
    end;
  end

end;
{============================
*函数名：Base64ToString*
*作者：*
*时间：2005.11.29 15.25 *
*说明：实现字符转换*
============================}
function Base64ToString(const Value: string): ByteArray;
var
  x, y, n, l: Integer;
  d: array[0..3] of Byte;
  Table : string;
begin
  Table :=
    #$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$3E +#$40
    +#$40 +#$40 +#$3F +#$34 +#$35 +#$36 +#$37 +#$38 +#$39 +#$3A +#$3B +#$3C
    +#$3D +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40 +#$00 +#$01 +#$02 +#$03
    +#$04 +#$05 +#$06 +#$07 +#$08 +#$09 +#$0A +#$0B +#$0C +#$0D +#$0E +#$0F
    +#$10 +#$11 +#$12 +#$13 +#$14 +#$15 +#$16 +#$17 +#$18 +#$19 +#$40 +#$40
    +#$40 +#$40 +#$40 +#$40 +#$1A +#$1B +#$1C +#$1D +#$1E +#$1F +#$20 +#$21
    +#$22 +#$23 +#$24 +#$25 +#$26 +#$27 +#$28 +#$29 +#$2A +#$2B +#$2C +#$2D
    +#$2E +#$2F +#$30 +#$31 +#$32 +#$33 +#$40 +#$40 +#$40 +#$40 +#$40 +#$40;

  SetLength(Result, Length(Value));
  x := 1;
  l := 0;
  while x < Length(Value) do
  begin
    for n := 0 to 3 do
    begin
      if x > Length(Value) then
        d[n] := 64
      else
      begin
        y := Ord(Value[x]);
        if (y < 33) or (y > 127) then
          d[n] := 64
        else
          d[n] := Ord(Table[y - 32]);
      end;
      Inc(x);
    end;
    Result[l] := Byte((D[0] and $3F) shl 2 + (D[1] and $30) shr 4);
    Inc(l);
    if d[2] <> 64 then
    begin
      Result[l] := Byte((D[1] and $0F) shl 4 + (D[2] and $3C) shr 2);
      Inc(l);
      if d[3] <> 64 then
      begin
        Result[l] := Byte((D[2] and $03) shl 6 + (D[3] and $3F));
        Inc(l);
      end;
    end;
  end;
  //Dec(l);
  SetLength(Result, l);

end;
{============================
*函数名：GetBase64Index*
*作者：*
*时间：2005.11.29 15.25 *
*说明：获取Base64编码的索引*
============================}
function GetBase64Index(c:AnsiChar):Integer;
var
Table:AnsiString;
i:Integer;
begin
  Table:='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
  for i := 0 to 64 do
  begin
    if Table[i+1]=c then
      break;
  end;
  Result:=i;
end;
end.
