unit ejemploTimbrado;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Utilidades,
  Dialogs, StdCtrls, WS, CFD;

type
  TForm1 = class(TForm)
    txtLayout: TEdit;
    cmdTimbrarLayout: TButton;
    Edit2: TEdit;
    Button2: TButton;
    Button3: TButton;
    txtXml: TEdit;
    Button4: TButton;
    cmdTimbrarXml: TButton;
    CheckBox1: TCheckBox;
    procedure cmdTimbrarLayoutClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure cmdTimbrarXmlClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  WS_FM: WSConecFM;
  Util: Utilities;

implementation

{$R *.dfm}

{Timbrar Layout}
procedure TForm1.cmdTimbrarLayoutClick(Sender: TObject);
  var
    layout, rfc, pass, id, url, path : string;
    parametros : TStringList;
    resultados :TStringList;
    xmlb64, pdfb64, txtb64, cbbb64, uuid : wideString;
    f: TextFile;
    SL: TStringList;

  begin
    Screen.Cursor:= crHourGlass;
    layout := txtLayout.Text;
    path := ExtractFilePath( Application.ExeName );
    {
    A continuación se definen las credenciales de acceso al Web Service, en cuanto se
    active su servicio deberá cambiar esta información por
    sus claves de acceso en modo productivo.
    }
    rfc := 'ESI920427886';
    pass := 'b9ec2afa3361a59af4b4d102d3f704eabdf097d4';
    id := 'UsuarioPruebasWS';
    url := 'https://t1demo.facturacionmoderna.com/timbrado/soap';
    parametros := TStringList.Create;
    parametros.Add('emisorRFC='+ rfc);
    parametros.Add('userPass='+ pass);
    parametros.Add('userId='+ id);
    parametros.Add('urlTimbrado='+ url);
    parametros.Add('generarPDF=true');
    parametros.Add('generarTXT=true');
    parametros.Add('generarCBB=true');

    resultados := WS_FM.timbrado(layout, parametros);

    if (resultados.IndexOfName('code') > -1) then
    begin
      ShowMessage(resultados.Values['message']);
      Screen.Cursor:= crDefault;
      Exit;
    end;

    xmlb64 := resultados.Values['xmlb64'];
    uuid := resultados.Values['uuid'];

    xmlb64 := Util.base64decode(xmlb64);
    AssignFile(f, path + 'resultados\' + uuid + '.xml');
    Rewrite(f);
    WriteLn(f,xmlb64);
    CloseFile(f);

    if (resultados.IndexOfName('pdfb64') > -1) then
    begin
      pdfb64 := resultados.Values['pdfb64'];
      pdfb64 := Util.base64decode(pdfb64);
      AssignFile(f, path + 'resultados\' + uuid + '.pdf');
      Rewrite(f);
      WriteLn(f,pdfb64);
      CloseFile(f);
    end;
    if (resultados.IndexOfName('txtb64') > -1) then
    begin
      txtb64 := resultados.Values['txtb64'];
      txtb64 := Util.base64decode(txtb64);
      AssignFile(f, path + 'resultados\' + uuid + '.txt');
      Rewrite(f);
      WriteLn(f,txtb64);
      CloseFile(f);
    end;
    if (resultados.IndexOfName('cbbb64') > -1) then
    begin
      cbbb64 := resultados.Values['cbbb64'];
      cbbb64 := Util.base64decode(cbbb64);
      AssignFile(f, path + 'resultados\' + uuid + '.png');
      Rewrite(f);
      WriteLn(f,cbbb64);
      CloseFile(f);
    end;
    Screen.Cursor:= crDefault;
    showMessage('Timbrado Exitoso');
  end;

{Cancelar UUID}
procedure TForm1.Button2Click(Sender: TObject);
var
  uuid, rfc, pass, id, url : string;
  parametros : TStringList;
  resultados : TStringList;
  msg: wideString;

begin
  Screen.Cursor:= crHourGlass;
  uuid := Edit2.Text;
  rfc := 'ESI920427886';
  pass := 'b9ec2afa3361a59af4b4d102d3f704eabdf097d4';
  id := 'UsuarioPruebasWS';
  url := 'https://t1demo.facturacionmoderna.com/timbrado/soap';
  parametros := TStringList.Create;
  parametros.Add('emisorRFC='+ rfc);
  parametros.Add('userPass='+ pass);
  parametros.Add('userId='+ id);
  parametros.Add('urlCancelado='+ url);

  resultados := WS_FM.cancelado(uuid, parametros);
  msg := resultados.Values['message'];
  showMessage(msg);
  Screen.Cursor:= crDefault;

end;

procedure TForm1.Button3Click(Sender: TObject);
var
  openDialog : TOpenDialog;

begin
  openDialog := TOpenDialog.Create(self);
  openDialog.InitialDir := GetCurrentDir;
  openDialog.Options := [ofFileMustExist];
  openDialog.Filter := 'Archivos Xml|*.xml';
  // Abrir archivos xml por default
  openDialog.FilterIndex := 1;
  if openDialog.Execute then
  begin
    txtXml.Text := openDialog.FileName;
  end
  else
  begin
    txtXml.Text := '--- Buscar archivo xml ---';
  end;
  openDialog.Free;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  openDialog : TOpenDialog;

begin
  openDialog := TOpenDialog.Create(self);
  openDialog.InitialDir := GetCurrentDir;
  openDialog.Options := [ofFileMustExist];
  openDialog.Filter := 'Archivos ini|*.ini|Archivos txt|*.txt';
  // Abrir archivos txt por default
  openDialog.FilterIndex := 2;
  if openDialog.Execute then
  begin
    txtLayout.Text := openDialog.FileName;
  end
  else
  begin
    txtLayout.Text := '--- Buscar archivo layout ---';
  end;
  openDialog.Free;
end;

{ Timbrar xml }
procedure TForm1.cmdTimbrarXmlClick(Sender: TObject);
var
    path, xsltfile, certfile,keyfile, password, file_name : String;
    status, msg, cadenaO, xmlfile, certi, certiNumber,dgSign : wideString;
    cfd : Comprobante;
    resp : TStringList;
    layout, rfc, pass, id, url : string;
    parametros : TStringList;
    resultados : TStringList;
    xmlb64, pdfb64, txtb64, cbbb64, uuid : wideString;
    f: TextFile;
    pdfbytes, cbbbytes, xmlbytes: wideString;
    stream: TFileStream;

  begin
    Screen.Cursor:= crHourGlass;
    path := ExtractFilePath( Application.ExeName );
    xmlfile := txtXml.Text;
    xsltfile := path + 'utilerias\xslt3_2\cadenaoriginal_3_2.xslt';
    certfile := path + 'utilerias\certificados\20001000000200000278.cer';
    keyfile := path + 'utilerias\certificados\20001000000200000278.key';
    password := '12345678a';

    if CheckBox1.Checked then
    begin
        xsltfile := path + 'utilerias\xslt_retenciones\retenciones.xslt';
    end;


    { Obtener informacion del certificado }
    resp := cfd.getInfoCertificate(certfile);
    status := resp.Values['status'];
    if ( status = 'false' ) then
    begin
      msg := resp.Values['msg'];
      showMessage(msg);
      Screen.Cursor:= crDefault;
      Exit;
    end;
    certi := resp.Values['certificate'];
    certiNumber := resp.Values['certificateNumber'];

    { Agregar informacion del certificado al xml }
    resp :=  cfd.addCertificateToXml(xmlfile, certi, certiNumber);
    status := resp.Values['status'];
    if ( status = 'false' ) then
    begin
      msg := resp.Values['msg'];
      showMessage(msg);
      Screen.Cursor:= crDefault;
      Exit;
    end;
    xmlfile := resp.Values['newXml'];

    { Generar la cadena original del xml }
    resp := cfd.createOriginalChain(xmlfile, xsltfile);
    status := resp.Values['status'];
    if ( status = 'false' ) then
    begin
      msg := resp.Values['msg'];
      showMessage(msg);
      Screen.Cursor:= crDefault;
      Exit;
    end;
    cadenaO := resp.Values['msg'];

    resp := cfd.createDigitalStamp(keyfile,cadenaO, password);
    status := resp.Values['status'];
    if ( status = 'false' ) then
    begin
      msg := resp.Values['msg'];
      showMessage(msg);
      Screen.Cursor:= crDefault;
      Exit;
    end;
    dgSign := resp.Values['sello'];

    { Agregar el sello al xml }
    resp := cfd.addDigitalStampToXml(xmlfile, dgSign);
    status := resp.Values['status'];
    if ( status = 'false' ) then
    begin
      msg := resp.Values['msg'];
      showMessage(msg);
      Screen.Cursor:= crDefault;
      Exit;
    end;
    xmlfile := resp.Values['newXml'];

    {Realizar timbrado de XML }
    rfc := 'ESI920427886';
    pass := 'b9ec2afa3361a59af4b4d102d3f704eabdf097d4';
    id := 'UsuarioPruebasWS';
    url := 'https://t1demo.facturacionmoderna.com/timbrado/soap';
    parametros := TStringList.Create;
    parametros.Add('emisorRFC='+ rfc);
    parametros.Add('userPass='+ pass);
    parametros.Add('userId='+ id);
    parametros.Add('urlTimbrado='+ url);
    parametros.Add('generarPDF='+ 'true');
    parametros.Add('generarTXT='+ 'true');
    parametros.Add('generarCBB='+ 'true');

    resp := WS_FM.timbrado(xmlfile, parametros);

    if (resp.IndexOfName('code') > -1) then
    begin
      msg := resp.Values['message'];
      showMessage(msg);
      Screen.Cursor:= crDefault;
      Exit;
    end;

    uuid := resp.Values['uuid'];
    { Guardar XML }
    file_name :=  path + 'resultados\' + uuid + '.xml';
    xmlb64 := resp.Values['xmlb64'];
    xmlb64 := Util.base64decode(xmlb64);
    Util.WriteFileTmp(file_name, xmlb64);

    { Guardar PDF }
    if (resp.IndexOfName('pdfb64') > -1) then
    begin
      pdfb64 := resp.Values['pdfb64'];
      pdfb64 := Util.base64decode(pdfb64);
      AssignFile(f, path + 'resultados\' + uuid + '.pdf');
      Rewrite(f);
      WriteLn(f,pdfb64);
      CloseFile(f);
    end;

    { Guardar TXT }
    if (resp.IndexOfName('txtb64') > -1) then
    begin
      file_name :=  path + 'resultados\' + uuid + '.txt';
      txtb64 := resp.Values['txtb64'];
      txtb64 := Util.base64decode(txtb64);
      Util.WriteFileTmp(file_name, txtb64);
    end;
    if (resp.IndexOfName('cbbb64') > -1) then
    begin
      cbbb64 := resp.Values['cbbb64'];
      cbbb64 := Util.base64decode(cbbb64);
      AssignFile(f, path + 'resultados\' + uuid + '.png');
      Rewrite(f);
      WriteLn(f,cbbb64);
      CloseFile(f);
    end;

    Screen.Cursor:= crDefault;
    showMessage('Timbrado Exitoso');
  end;

end.

