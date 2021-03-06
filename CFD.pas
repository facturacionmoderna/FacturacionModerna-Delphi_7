{
  Requisitos:
  1.- Instalar openssl en el sistema
  2.- import Microsoft xml 6
}
unit CFD;

interface

uses
  SysUtils,Messages, Classes, Windows, Forms, MSXMLDOM, MSXML2_TLB,Dialogs, Utilidades;

type
  Comprobante = class(TObject)

private
  { Private declarations }
  function ejecutarComando (comando : String; outpath: String) : String;
  function IsWinNT: boolean;

protected
  { Protected declarations }
                                                    
public
  { Public declarations }
  function createOriginalChain(xml: String; xslt : String): TStringList;
  function getInfoCertificate(certfile: String): TStringList;
  function addCertificateToXml(xml: String; cert: WideString; certNo: String): TStringList;
  function createDigitalStamp(keyfile: String; chain: String; password: String): TStringList;
  function addDigitalStampToXml(xml: String; digitalStamp: String): TStringList;

published
  { Published declarations }

end;

var
   Util: Utilities;
   
implementation

{ Leer certificado para extraer el No de certificado y el contenido del cer en base 64 }
function Comprobante.getInfoCertificate( certfile: String ): TStringList;
var
  file_name, certificateNumber : String;
  content_file, certificate : WideString;
  res : TStringList;
  path : String;
  pid : String;
  i : Integer;
  command : String;
  file_path: TFileName;

begin
  path := ExtractFilePath( Application.ExeName );
  certificateNumber := '';
  certificate := '';
  res := TStringList.Create;

  if (certfile = '') then
  begin;
    res.Add('msg=No se especifico la ruta del certificado');
    res.Add('status=false');
    res.Add('certificate=' + certificate);
    res.Add('certificateNumber=' + certificateNumber);
    Result := res;
    Exit;
  end;

  if not FileExists(certfile) then
  begin
    res.Add('msg=La ruta especificada del certificado no existe');
    res.Add('status=false');
    res.Add('certificate=' + certificate);
    res.Add('certificateNumber=' + certificateNumber);
    Result := res;
    Exit;
  end;

  { Obtener el n�mero de certificado }
  command := 'openssl x509 -inform DER -in "' + String(certfile) + '" -noout -serial';
  file_name := Util.RandomNameFile('.txt');
  file_path := path + file_name;
  pid := ejecutarComando(command, file_path);
  content_file := Util.ReadFileTmp(file_path, 1);
  i := 9;
  while i <= Length(content_file) do
  begin
    certificateNumber := certificateNumber + content_file[i];
    Inc(i, 2);
  end;
  if (certificateNumber = '') then
  begin
    res.Add('msg=Error al obtener el numero del certificado');
    res.Add('status=false');
    res.Add('certificate=');
    res.Add('certificateNumber=');
    Result := res;
    Exit;
  end;

  {Obtener el contenido del certificado}
  command := 'openssl enc -base64 -A -in "' + String(certfile) + '"';
  file_name := Util.RandomNameFile('.txt');
  file_path := path + file_name;
  pid := ejecutarComando(command, file_path);
  certificate := Util.ReadFileTmp(file_path, 1);
  If certificate = '' Then
    begin
    res.Add('msg=Error al obtener el contenido del certificado');
    res.Add('status=false');
    res.Add('certificate=');
    res.Add('certificateNumber=');
    Result := res;
    Exit;
  end;

  res.Add('msg=Informacion extraida con exito');
  res.Add('status=true');
  res.Add('certificate=' + certificate);
  res.Add('certificateNumber=' + certificateNumber);
  Result := res;

end;

{ Agregar al xml, el numero de certificado y el contenido del certificado }
function Comprobante.addCertificateToXml(xml: String; cert: WideString; certNo: String): TStringList;
var
  XMLDoc : IXMLDOMDocument2;
  objNodelist, objNodelist2: IXMLDOMNodeList;
  objNode, objNode2: IXMLDOMNode;
  res : TStringList;
  i: integer;
  newXml : WideString;

begin
  res := TStringList.Create;

  if (xml = '') or (cert = '') or (certNo = '') then
  begin;
    res.Add('msg=Verificar los parametros enviados, se encuentran vacios');
    res.Add('status=false');
    Result := res;
    Exit;
  end;

  { Validar existencia del xml }
  if FileExists(xml) then
  begin
    xml := Util.ReadFileTmp(xml, 0);
  end;

  try
    XMLDoc := CoDOMDocument60.Create;
    XMLDoc.async := False;
    XMLDoc.setProperty('SelectionLanguage', 'XPath');
    XMLDoc.loadXML(xml);
  except
    on E : Exception do
    begin
      res.Add('msg=' + E.Message);
      res.Add('status=false');
      res.Add('newXml=');
      Result := res;
      Exit;
    end;
  end;

  { Aplica para facturas }
  XMLDoc.setProperty('SelectionNamespaces', 'xmlns:cfdi="http://www.sat.gob.mx/cfd/3"');
  objNodelist := XMLDoc.selectNodes('cfdi:Comprobante');
  for i := 0 to objNodelist.length - 1 do
  begin
    objNode := objNodelist.item[i];
    objNode.selectSingleNode('@Certificado').Text := cert;
    objNode.selectSingleNode('@NoCertificado').Text := certNo;
  end;
  //
  XMLDoc.setProperty('SelectionNamespaces', 'xmlns:retenciones="http://www.sat.gob.mx/esquemas/retencionpago/1"');
  objNodelist2 := XMLDoc.selectNodes('retenciones:Retenciones');
  for i := 0 to objNodelist2.length - 1 do
  begin
    objNode2 := objNodelist2.item[i];
    objNode2.selectSingleNode('@Cert').Text := cert;
    objNode2.selectSingleNode('@NumCert').Text := certNo;
  end;

  newXml := XMLDoc.xml;
  if (newXml = '') then
  begin
     res.Add('msg=No se logro recuperar el XMl modificado');
     res.Add('status=false');
     res.Add('newXml=');
     Result := res;
     Exit;
  end;

  objNodelist := nil;
  objNode := nil;
  objNodelist2 := nil;
  objNode2 := nil;
  XMLDoc := nil;

  res.Add('msg=XML modificado con �xito');
  res.Add('status=true');
  res.Add('newXml=' + newXml);
  Result := res;

end;

{ Generar la cadena original del comprobante }
function Comprobante.createOriginalChain( xml: String; xslt : String ): TStringList;
var
  chain : String;
  res : TStringList;
  XMLDoc : IXMLDOMDocument;
  XSLDoc : IXMLDOMDocument;
  Template : IXSLTemplate;
  Processor : IXSLProcessor;

begin;
  res := TStringList.Create;

  if (xml = '') Or (xslt = '') then
  begin;
    res.Add('msg=Verificar los parametros enviados, se encuentran vacios');
    res.Add('status=false');
    Result := res;
    Exit;
  end;

  { Validar existencia del xml }
  if FileExists(xml) then
  begin
    xml := Util.ReadFileTmp(xml, 0);
  end;

  try
    XMLDoc := CoFreeThreadedDOMDocument60.Create;
    XSLDoc := CoFreeThreadedDOMDocument60.Create;
    XMLDoc.loadXML(xml);
    XSLDoc.load(xslt);
    Template := CoXSLTemplate60.Create;
    XSLDoc.async := False;
    XSLDoc.resolveExternals := True;
    XSLDoc.validateOnParse := True;
    Template.stylesheet := XSLDoc;
    Processor := Template.createProcessor;
    Processor.input := XMLDoc;
    Processor.transform;
    chain :=  Processor.output;
    if (chain = '|||') then
    begin
      res.Add('msg=Error al generar la cadena original, la cadena esta vacia: ' + chain);
      res.Add('status=false');
      Result := res;
      Exit;
    end;
    res.Add('msg=' + chain);
    res.Add('status=true');
  except
    on E : Exception do
    begin
      res.Add('msg=' + E.Message);
      res.Add('status=false');
    end;
  end;
  XMLDoc := nil;
  XSLDoc := nil;
  Result := res;
end;

{ Crear el sello del comprobante }
function Comprobante.createDigitalStamp(keyfile: String; chain: String; password: String): TStringList;
var
  res : TStringList;
  pid2, deleted: boolean;
  command, sello, file_name, file_path, path, pemfile, pid: String;

begin
  path := ExtractFilePath( Application.ExeName );
  res := TStringList.Create;
  deleted := False;

  if (keyfile = '') Or (chain = '') Or (password = '') then
  begin;
    res.Add('msg=Verificar los parametros enviados, se encuentran vacios');
    res.Add('status=false');
    Result := res;
    Exit;
  end;

  { Validar existencia del string de cadena original }
  if not FileExists(chain) then
  begin
    file_name := Util.RandomNameFile('.txt');
    file_path := path + file_name;
    pid2 := Util.WriteFileWithoutBom(file_path, chain);
    chain := file_path;
    deleted := True;
  end;

  { Generar PEM del archivo .key para poder sellar }
  command := 'openssl pkcs8 -inform DER -in "' + keyfile + '" -passin pass:"' + password + '"';
  file_name := Util.RandomNameFile('.pem');
  pemfile := path + file_name;
  pid := ejecutarComando(command, pemfile);

  { Crear el sello del xml }
  command := 'openssl dgst -sha256 -sign "' + pemfile + '" "' + chain + '" | openssl enc -base64 -A';
  file_name := Util.RandomNameFile('.txt');
  file_path := path + file_name;
  pid := ejecutarComando(command, file_path);
  sello := Util.ReadFileTmp(file_path, 1);

  if (sello = '') then
  begin
    res.Add('msg=Sello vacio');
    res.Add('status=false');
    Result := res;
    Exit;
  end;

  { Eliminar archivos temporales }
  DeleteFile(PChar(pemfile));
  If deleted Then
  begin
    DeleteFile(PChar(chain));
  end;

  res.Add('msg=Sello creado con exito');
  res.Add('status=true');
  res.Add('sello=' + sello);
  Result := res;

end;

{ Agregar sello al xml }
function Comprobante.addDigitalStampToXml(xml: String; digitalStamp: String): TStringList;
var
  XMLDoc : IXMLDOMDocument2;
  objNodelist, objNodelist2: IXMLDOMNodeList;
  objNode, objNode2: IXMLDOMNode;
  res : TStringList;
  i: integer;
  newXml : WideString;

begin
  res := TStringList.Create;

  if (xml = '') or (digitalStamp = '') then
  begin;
    res.Add('msg=Verificar los parametros enviados, se encuentran vacios');
    res.Add('status=false');
    Result := res;
    Exit;
  end;

  { Validar existencia del xml }
  if FileExists(xml) then
  begin
    xml := Util.ReadFileTmp(xml, 0);
  end;

  try
    XMLDoc := CoDOMDocument60.Create;
    XMLDoc.async := False;
    XMLDoc.setProperty('SelectionLanguage', 'XPath');
    XMLDoc.loadXML(xml);
  except
    on E : Exception do
    begin
      res.Add('msg=' + E.Message);
      res.Add('status=false');
      res.Add('newXml=');
      Result := res;
      Exit;
    end;
  end;

  { Aplica para facturas }
  XMLDoc.setProperty('SelectionNamespaces', 'xmlns:cfdi="http://www.sat.gob.mx/cfd/3"');
  objNodelist := XMLDoc.selectNodes('cfdi:Comprobante');
  for i := 0 to objNodelist.length - 1 do
  begin
    objNode := objNodelist.item[i];
    objNode.selectSingleNode('@Sello').Text := digitalStamp;
  end;
  //
  XMLDoc.setProperty('SelectionNamespaces', 'xmlns:retenciones="http://www.sat.gob.mx/esquemas/retencionpago/1"');
  objNodelist2 := XMLDoc.selectNodes('retenciones:Retenciones');
  for i := 0 to objNodelist2.length - 1 do
  begin
    objNode2 := objNodelist2.item[i];
    objNode2.selectSingleNode('@Sello').Text := digitalStamp;
  end;

  newXml := XMLDoc.xml;
  if (newXml = '') then
  begin
     res.Add('msg=No se logro recuperar el XML modificado, al agregar el sello');
     res.Add('status=false');
     res.Add('newXml=');
     Result := res;
     Exit;
  end;

  objNodelist := nil;
  objNode := nil;
  objNodelist2 := nil;
  objNode2 := nil;
  XMLDoc := nil;

  res.Add('msg=XML modificado con �xito');
  res.Add('status=true');
  res.Add('newXml=' + newXml);
  Result := res;

end;


{##############################}
{##### Private functions ######}
{##############################}
function Comprobante.ejecutarComando (comando : String; outpath: String) : String;
var
  Buffer: array[0..4096] of Char;
  si: STARTUPINFO;
  sa: SECURITY_ATTRIBUTES;
  sd: SECURITY_DESCRIPTOR;
  pi: PROCESS_INFORMATION;
  newstdin, newstdout, read_stdout, write_stdin: THandle;
  exitcod, bread, avail: Cardinal;

begin
  Result:= '';
  comando := comando + ' > ' + '"' + outpath + '"';
  if IsWinNT then
  begin
    InitializeSecurityDescriptor(@sd, SECURITY_DESCRIPTOR_REVISION);
    SetSecurityDescriptorDacl(@sd, true, nil, false);
    sa.lpSecurityDescriptor := @sd;
  end
  else sa.lpSecurityDescriptor := nil;
  sa.nLength := sizeof(SECURITY_ATTRIBUTES);
  sa.bInheritHandle := TRUE;
  if CreatePipe(newstdin, write_stdin, @sa, 0) then
  begin
    if CreatePipe(read_stdout, newstdout, @sa, 0) then
    begin
      GetStartupInfo(si);
      with si do
      begin
        dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
        wShowWindow := SW_HIDE;
        hStdOutput := newstdout;
        hStdError := newstdout;
        hStdInput := newstdin;
      end;
      Fillchar(Buffer, SizeOf(Buffer), 0);
      GetEnvironmentVariable('COMSPEC', @Buffer, SizeOf(Buffer) - 1);
      StrCat(@Buffer,PChar(' /c ' + comando));
      if CreateProcess(nil, @Buffer, nil, nil, TRUE, CREATE_NEW_CONSOLE, nil, nil, si, pi) then
      begin
        repeat
          PeekNamedPipe(read_stdout, @Buffer, SizeOf(Buffer) - 1, @bread, @avail, nil);
          if bread > 0 then
          begin
            Fillchar(Buffer, SizeOf(Buffer), 0);
            ReadFile(read_stdout, Buffer, bread, bread, nil);
            Result:= Result + String(PChar(@Buffer));
          end;
          Application.ProcessMessages;
          GetExitCodeProcess(pi.hProcess, exitcod);
        until (exitcod <> STILL_ACTIVE) and (bread = 0);
      end;
      CloseHandle(read_stdout);
      CloseHandle(newstdout);
    end;
    CloseHandle(newstdin);
    CloseHandle(write_stdin);
  end;
end;

function Comprobante.IsWinNT: boolean;
var
  OSV: OSVERSIONINFO;
begin
  OSV.dwOSVersionInfoSize := sizeof(osv);
  GetVersionEx(OSV);
  result := OSV.dwPlatformId = VER_PLATFORM_WIN32_NT;
end;

end.
