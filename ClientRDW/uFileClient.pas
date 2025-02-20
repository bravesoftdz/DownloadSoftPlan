unit uFileClient;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, uRESTDWBase, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage, uDWJSONObject, uDWConsts, uDWConstsData, Vcl.ComCtrls, idComponent,
  uRESTDWServerEvents, uDWAbout, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, Data.DB, Vcl.Grids, Vcl.DBGrids, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, uRESTDWPoolerDB, Vcl.Samples.Gauges;

type
  TForm4 = class(TForm)
    Label4: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    eHost: TEdit;
    ePort: TEdit;
    edPasswordDW: TEdit;
    edUserNameDW: TEdit;
    RESTClientPooler1: TRESTClientPooler;
    Label1: TLabel;
    Button1: TButton;
    lbLocalFiles: TListBox;
    Button2: TButton;
    Button3: TButton;
    OpenDialog1: TOpenDialog;
    cmb_tmp: TComboBox;
    Label2: TLabel;
    ProgressBar1: TProgressBar;
    DWClientEvents1: TDWClientEvents;
    pnl1: TPanel;
    DTBase1: TRESTDWDataBase;
    DWSQL_Downloads: TRESTDWClientSQL;
    dbgrd1: TDBGrid;
    ds1: TDataSource;
    pnl_Top: TPanel;
    pnl2: TPanel;
    edt1: TEdit;
    Gauge1: TGauge;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure RESTClientPooler1Work(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Int64);
    procedure RESTClientPooler1WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure RESTClientPooler1WorkEnd(ASender: TObject; AWorkMode: TWorkMode);
    procedure dbgrd1DblClick(Sender: TObject);
  private
    { Private declarations }
   FBytesToTransfer : Int64;
  public
    { Public declarations }
   DirName : String;
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.Button1Click(Sender: TObject);
Var
 dwParams      : TDWParams;
 vErrorMessage : String;
 vFileList     : TStringStream;
Begin
 lbLocalFiles.Clear;
 RESTClientPooler1.Host     := eHost.Text;
 RESTClientPooler1.Port     := StrToInt(ePort.Text);

 Try
  Try
   DWClientEvents1.CreateDWParams('FileList', dwParams);
   DWClientEvents1.SendEvent('FileList', dwParams, vErrorMessage);
   If vErrorMessage = '' Then
    Begin
     If dwParams.ItemsString['result'].AsString <> '' Then
      Begin
       vFileList := TStringStream.Create('');
       Try
        dwParams.ItemsString['result'].SaveToStream(vFileList);
        lbLocalFiles.Items.Text := vFileList.DataString;
       Finally
        vFileList.Free;
       End;
      End;
    End
   Else
    Showmessage(vErrorMessage);
  Except
  End;
 Finally
  FreeAndNil(dwParams);
 End;
End;

procedure TForm4.Button2Click(Sender: TObject);
Var
 DWParams     : TDWParams;
 vErrorMessage : String;
 StringStream : TStringStream;
Begin
 If lbLocalFiles.ItemIndex > -1 Then
  Begin
   RESTClientPooler1.Host     := eHost.Text;
   RESTClientPooler1.Port     := StrToInt(ePort.Text);
   DWClientEvents1.CreateDWParams('DownloadFile', dwParams);
   dwParams.ItemsString['Arquivo'].AsString := lbLocalFiles.Items[lbLocalFiles.ItemIndex];
   Try
    Try
     RESTClientPooler1.Host := eHost.Text;
     RESTClientPooler1.Port := StrToInt(ePort.Text);
     DWClientEvents1.SendEvent('DownloadFile', dwParams, vErrorMessage);
     If vErrorMessage = '' Then
      Begin
       StringStream          := TStringStream.Create('');
       dwParams.ItemsString['result'].SaveToStream(StringStream);
       Try
        ForceDirectories(ExtractFilePath(DirName + lbLocalFiles.Items[lbLocalFiles.ItemIndex]));
        If FileExists(DirName + lbLocalFiles.Items[lbLocalFiles.ItemIndex]) Then
         DeleteFile(DirName + lbLocalFiles.Items[lbLocalFiles.ItemIndex]);
        StringStream.SaveToFile(DirName + lbLocalFiles.Items[lbLocalFiles.ItemIndex]);
        StringStream.SetSize(0);
        Showmessage('Download conclu�do...');
       Finally
        FreeAndNil(StringStream);
       End;
      End;
    Except
    End;
   Finally
    FreeAndNil(DWParams);
   End;
  End
 Else
  Showmessage('Escolha um arquivo para Download...');
End;

procedure TForm4.Button3Click(Sender: TObject);
Var
 DWParams      : TDWParams;
 vErrorMessage : String;
 MemoryStream  : TMemoryStream;
Begin
  RESTClientPooler1.RequestTimeOut:= StrToInt(Copy(cmb_tmp.Text, 1,1)) * 60000;
  If OpenDialog1.Execute Then
  Begin
   DWClientEvents1.CreateDWParams('SendReplicationFile', dwParams);
   dwParams.ItemsString['Arquivo'].AsString := OpenDialog1.FileName;
   MemoryStream                 := TMemoryStream.Create;
   MemoryStream.LoadFromFile(OpenDialog1.FileName);
   dwParams.ItemsString['FileSend'].LoadFromStream(MemoryStream);
   MemoryStream.SetSize(0);
   MemoryStream.Free;
   DWClientEvents1.SendEvent('SendReplicationFile', DWParams, vErrorMessage);
   If vErrorMessage = '' Then
    Begin
      Try
       If DWParams.ItemsString['Result'].AsBoolean Then
        Showmessage('Upload conclu�do...');
      Finally
      End;
    End;
   DWParams.Free;
  End;
end;

procedure TForm4.dbgrd1DblClick(Sender: TObject);

begin

   //edt1.text := lbLocalFiles.Items.Add(vFileList); // pega pelo nome do campo

end;

procedure TForm4.FormCreate(Sender: TObject);
begin
 DTBase1.Connected:=True;

 DWSQL_Downloads.Active:=True;

 DirName  := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) +
             IncludeTrailingPathDelimiter('filelist');
 If Not DirectoryExists(DirName) Then
  ForceDirectories(DirName);


end;

procedure TForm4.RESTClientPooler1Work(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
  If FBytesToTransfer = 0 Then // No Update File
   Exit;
  ProgressBar1.Position := AWorkCount;
  Gauge1.Progress:=AWorkCount;
end;

procedure TForm4.RESTClientPooler1WorkBegin(ASender: TObject;
  AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
 FBytesToTransfer := AWorkCountMax;
 ProgressBar1.Max := FBytesToTransfer;
 Gauge1.Progress:=FBytesToTransfer;
 ProgressBar1.Position := 0;
 Gauge1.Progress:=0;
end;

procedure TForm4.RESTClientPooler1WorkEnd(ASender: TObject;
  AWorkMode: TWorkMode);
begin
 ProgressBar1.Position := FBytesToTransfer;
 Gauge1.Progress:=FBytesToTransfer;
 FBytesToTransfer      := 0;
end;

end.
