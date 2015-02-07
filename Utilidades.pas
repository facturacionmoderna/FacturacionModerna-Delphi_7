unit Utilidades;

interface

uses
  SysUtils, Classes, IdCoder, IdCoder3to4, IdCoderMIME, IdBaseComponent, EncdDecd;

type
  Utilities = class(TObject)

private
  { Private declarations }

public
  { Public declarations }
  function WriteFileTmp(file_path: String; myText:WideString): boolean;
  function WriteFileWithoutBom(file_path: String; myText:WideString): boolean;
  function ReadFileTmp(file_path: String; delete: integer): WideString;
  function Base64EncodeFile(file_path: string): WideString;
  function RandomNameFile(extension: String): String;
  function base64decode(strLinea: AnsiString): ansiString;
  function delete_file(file_path: String): boolean;

published
{ Published declarations }

end;

implementation

function Utilities.WriteFileTmp(file_path: String; myText:WideString): boolean;
const
  UTF8BOM: array[0..2] of Byte = ($EF, $BB, $BF);
var
  UTF8Str: UTF8String;
  FS: TFileStream;
begin
  UTF8Str := UTF8Encode(myText);

  FS := TFileStream.Create(file_path, fmCreate);
  try
    FS.WriteBuffer(UTF8BOM[0], SizeOf(UTF8BOM));
    FS.WriteBuffer(PAnsiChar(UTF8Str)^, Length(UTF8Str));
  finally
    FS.Free;
  end;
end;


function Utilities.WriteFileWithoutBom(file_path: String; myText:WideString): boolean;
var
  UTF8Str: UTF8String;
  FS: TFileStream;
begin
  UTF8Str := UTF8Encode(myText);

  FS := TFileStream.Create(file_path, fmCreate);
  try
    FS.WriteBuffer(PAnsiChar(UTF8Str)^, Length(UTF8Str));
  finally
    FS.Free;
  end;
end;


function Utilities.ReadFileTmp(file_path: String; delete: integer): WideString;
var
  f:TFileStream;
  src:AnsiString;
  wx:word;
  i,j:integer;
begin
  if FileExists(file_path) then
   begin
    f:=TFileStream.Create(file_path,fmOpenRead or fmShareDenyNone);
    try
      f.Read(wx,2);
      if wx=$FEFF then
       begin
        //UTF16
        i:=(f.Size div 2)-1;
        SetLength(Result,i);
        f.Read(Result[1],i*2);
        //detect NULL's
        for j:=1 to i do if Result[j]=#0 then Result[j]:=' ';//?
       end
      else
       begin
        i:=0;
        if wx=$BBEF then f.Read(i,1);
        if (wx=$BBEF) and (i=$BF) then
         begin
          //UTF-8
          i:=f.Size-3;
          SetLength(src,i);
          f.Read(src[1],i);
          //detect NULL's
          for j:=1 to i do if src[j]=#0 then src[j]:=' ';//?
          Result:=Trim(UTF8Decode(src));
         end
        else
         begin
          //assume current encoding
          f.Position:=0;
          i:=f.Size;
          SetLength(src,i);
          f.Read(src[1],i);
          //detect NULL's
          for j:=1 to i do if src[j]=#0 then src[j]:=' ';//?
          Result:=Trim(src);
         end;
       end;
    finally
      f.Free;
    end;
    if (delete = 1) then
    begin
      delete_file(file_path);
    end;
   end
  else
    Result:='';
end;


function Utilities.Base64EncodeFile(file_path: string): WideString;
var
  SourceStr: TFileStream;
  Encoder: TIdEncoderMIME;
  str : WideString;
begin
    str := '';
    SourceStr := TFileStream.Create(file_path, fmOpenRead);
    try
      Encoder := TIdEncoderMIME.Create(nil);
      try
        str := Encoder.Encode(SourceStr);
      finally
        Encoder.Free;
      end;
    finally
      SourceStr.Free;
    end;
    Result := str;
end;


function Utilities.RandomNameFile(extension: String): String;
var
  wAnyo, wMes, wDia: Word;
  wHora, wMinutos, wSegundos, wMilisegundos: Word;
  filename : String;
begin
  LongTimeFormat := 'hh:mm:ss.zzz';
  filename := 'tmp' + TimeToStr(Now());
  filename := StringReplace(filename, ':', '', [rfReplaceAll, rfIgnoreCase]);
  filename := StringReplace(filename, '.', '', [rfReplaceAll, rfIgnoreCase]);
  Result := filename + extension;
end;


function Utilities.base64decode(strLinea: AnsiString): ansiString;
  var Decoder : TIdDecoderMime;
  begin
    Decoder := TIdDecoderMime.Create(nil);
    try
      Result := Decoder.DecodeString(strLinea);
    finally
      FreeAndNil(Decoder)
  end
end;


function Utilities.delete_file(file_path: String): boolean;
var
  file_name: PAnsiChar;

begin
  if FileExists(file_path) then
  begin
    file_name := PAnsiChar(AnsiString(file_path));
    if DeleteFile(file_name) then
    begin
      Result:= True;
    end
    else
    begin
      Result:= False;
    end;
  end;
end;

end.{ end implementation }
