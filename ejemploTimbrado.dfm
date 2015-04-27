object Form1: TForm1
  Left = 415
  Top = 243
  Width = 538
  Height = 379
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object txtLayout: TEdit
    Left = 24
    Top = 136
    Width = 369
    Height = 21
    TabOrder = 0
    Text = '--- Selecciona archivo layout ---'
  end
  object cmdTimbrarLayout: TButton
    Left = 24
    Top = 174
    Width = 473
    Height = 43
    Caption = 'Timbrar Layout'
    TabOrder = 1
    OnClick = cmdTimbrarLayoutClick
  end
  object Edit2: TEdit
    Left = 24
    Top = 238
    Width = 473
    Height = 21
    TabOrder = 2
    Text = '5729175F-47BE-4881-8AE8-5892F624F99F'
  end
  object Button2: TButton
    Left = 24
    Top = 269
    Width = 473
    Height = 43
    Caption = 'Cancelar UUID'
    TabOrder = 3
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 392
    Top = 31
    Width = 105
    Height = 25
    Caption = 'Examinar'
    TabOrder = 4
    OnClick = Button3Click
  end
  object txtXml: TEdit
    Left = 24
    Top = 33
    Width = 369
    Height = 21
    TabOrder = 5
    Text = '--- Selecciona archivo xml ---'
  end
  object Button4: TButton
    Left = 392
    Top = 134
    Width = 105
    Height = 25
    Caption = 'Examinar'
    TabOrder = 6
    OnClick = Button4Click
  end
  object cmdTimbrarXml: TButton
    Left = 24
    Top = 72
    Width = 473
    Height = 41
    Caption = 'Timbrar XML'
    TabOrder = 7
    OnClick = cmdTimbrarXmlClick
  end
  object CheckBox1: TCheckBox
    Left = 24
    Top = 16
    Width = 161
    Height = 17
    Caption = 'Timbrar Xml de Retenciones'
    TabOrder = 8
  end
end
