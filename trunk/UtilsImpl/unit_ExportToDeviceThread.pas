{ ****************************************************************************** }
{ }
{ MyHomeLib }
{ }
{ Version 0.9 }
{ 20.08.2008 }
{ Copyright (c) Aleksey Penkov    alex.penkov@gmail.com }
{ Matvienko Sergei  matv84@mail.ru }
{ }
{ }
{ ****************************************************************************** }

unit unit_ExportToDeviceThread;

interface

uses
  Classes,
  SysUtils,
  unit_WorkerThread,
  unit_globals,
  Dialogs,
  ABSMain,
  IdHTTP,
  ZipForge;

type

  TExportToDeviceThread = class(TWorker)
  private
    FZipper: TZipForge;

    FFileOprecord: record SArch, FileName, Folder: String;
    SNo: integer;
  end;

FFileOpMode :(fmFb2Zip, fmFb2, fmFBD);
FBookIdList : TBookIdList;
FTable : TAbsTable;
FCollectionRoot : string;
FExportMode : TExportMode;
FIsTmp : boolean;
FProcessedFiles : string;
procedure ShowZipErrorMessage(Sender: TObject; ErrCode: integer;
  Message: string);

function fb2Lrf(InpFile, OutFile: string): boolean;
function fb2EPUB(InpFile, OutFile: string): boolean;
function fb2PDF(InpFile, OutFile: string): boolean;

procedure SetTable(ATable: TAbsTable);
protected
  procedure WorkFunction; override;
  function PrepareFile(ID: integer): boolean;
  function SendFileToDevice: boolean;

public
  property BookIdList: TBookIdList write FBookIdList;
  property Table: TAbsTable write SetTable;
  property ProcessedFiles: string read FProcessedFiles;
  property ExportMode: TExportMode read FExportMode write FExportMode;
  end;

implementation

uses
  Windows,
  dm_collection,
  dm_user,
  unit_database,
  unit_Consts,
  unit_Settings,
  frm_main,
  StrUtils,
  ShellAPI,
  unit_MHLHelpers, unit_WriteFb2Info,
  unit_Templater;

{ TExportToDeviceThread }

procedure TExportToDeviceThread.ShowZipErrorMessage
  (Sender: TObject; ErrCode: integer; Message: string);
begin
  if ErrCode <> 0 then
    Teletype(Format('������ ���������� ������ %s, ���: %d',
        [FZipper.FileName, 0]), tsError);
end;

//
// ���������� ��� �����, ���� ����� - �������������� �������������
// ��������� �������� ����� � �����
//

function TExportToDeviceThread.PrepareFile(ID: integer): boolean;
var
  z: integer;
  CR: string;
  FS: TMemoryStream;
  p1, p2: integer;
  FullName: String;
  InsideFileName: string;

  Templater: TTemplater;
  R: TBookRecord;

begin

  { TODO -oalex :
    �����������: ��������� �� ��������� ������
    ����������� � ������� }

  FIsTmp := False;
  FTable.Locate('ID', ID, []);
  Result := False;

  CR := GetFullBookPath(FTable, FCollectionRoot);

  with FFileOprecord do
  begin
    //
    // ���������� ��� ����� � ������������ � �������� ����������
    { TODO -oNickR -cPerformance : ���������� ��������� ������������ ������ ���� ��� ��� ������������� ������ }
    { TODO -oNickR -cBug : ��� ������� �� ���������� ������ }
    { TODO -oNickR -cBug : DMCollection.GetCurrentBook(R) ���������� ������ }
    Templater := TTemplater.Create;
    try
      if Templater.SetTemplate(Settings.FileNameTemplate, TpFile) = ErFine then
      begin
        DMCollection.GetCurrentBook(R);
        FileName := Templater.ParseString(R, TpFile);
      end;

      if (ExtractFileExt(FTable['FileName']) = ZIP_EXTENSION) and
        (FTable['Ext'] <> ZIP_EXTENSION) then
        FFileOpMode := fmFBD
      else if ExtractFileExt(CR) <> ZIP_EXTENSION then
        FFileOpMode := fmFb2;

      // ���������� ��� �������� � ������������ � �������� ����������
      if Templater.SetTemplate(Settings.FolderTemplate, TpPath) = ErFine then
      begin
        DMCollection.GetCurrentBook(R);
        Folder := Templater.ParseString(R, TpPath);
      end;
    finally
      Templater.Free;
    end;

    case FFileOpMode of
      fmFb2Zip:
        SArch := CR;
      fmFb2:
        SArch := CR + FTable['FileName'] + FTable['Ext'];
      fmFBD:
        begin
          CR := CR + FTable['FileName'];
          SArch := CR;
        end;
    end;
    SNo := FTable['InsideNo'];

    Folder := IncludeTrailingPathDelimiter(Trim(CheckSymbols(Folder)));
    FileName := Trim(CheckSymbols(FileName));

    InsideFileName := FullName + ' - ' + FTable.FieldByName('Title').AsString;

    if Settings.TransliterateFileName then
    begin
      InsideFileName := Transliterate(InsideFileName);
      Folder := Transliterate(Folder);
      FileName := Transliterate(FileName);
    end;

    FileName := FileName + DMCollection.tblBooks['Ext'];
  end;

  //
  // ���� ���� � ������ - ������������� � $tmp
  //
  if (FFileOpMode = fmFb2Zip) OR (FFileOpMode = fmFBD) then
  begin
    if not FileExists(CR) then
    begin
      ShowMessage('����� ' + CR + ' �� ������!', MB_ICONERROR or MB_OK);
      Exit;
    end;

    InsideFileName := Trim(CheckSymbols(InsideFileName)) + DMCollection.tblBooks
      ['Ext'];

    FS := TMemoryStream.Create;
    try
      FZipper.FileName := FFileOprecord.SArch;
      FZipper.OpenArchive;
      FZipper.ExtractToStream(GetFileNameZip(FZipper, FFileOprecord.SNo), FS);
      FFileOprecord.SArch := Settings.TempPath + InsideFileName;
      FS.SaveToFile(FFileOprecord.SArch);
      FIsTmp := True;
    finally
      FS.Free;
    end;
  end;
  if (DMCollection.tblBooks['Ext'] = FB2_EXTENSION)
    and Settings.OverwriteFB2Info then
    WriteFb2InfoToFile(FFileOprecord.SArch);

  Result := True;
end;

function TExportToDeviceThread.SendFileToDevice: boolean;
var
  DestFileName: string;
begin
  if not FileExists(FFileOprecord.SArch) then
  begin
    ShowMessage(Format('File "%s" not found', [FFileOprecord.SArch]),
      MB_ICONERROR or MB_OK);
    Result := False;
    Exit;
  end;

  CreateFolders(Settings.DeviceDir, FFileOprecord.Folder);
  DestFileName := Settings.DevicePath + FFileOprecord.Folder +
    FFileOprecord.FileName;

  Result := True;

  case FExportMode of
    emFB2:
      unit_globals.CopyFile(FFileOprecord.SArch, DestFileName);
    emFb2Zip:
      ZipFile(FFileOprecord.SArch, DestFileName + ZIP_EXTENSION);
    emTxt:
      unit_globals.ConvertToTxt(FFileOprecord.SArch, DestFileName,
        Settings.TXTEncoding);
    emLrf:
      Result := fb2Lrf(FFileOprecord.SArch, DestFileName);
    emEpub:
      Result := fb2EPUB(FFileOprecord.SArch, DestFileName);
    emPDF:
      Result := fb2PDF(FFileOprecord.SArch, DestFileName);
  end;

  // if FIsTmp then
  // SysUtils.DeleteFile(FFileOpRecord.SArch);
end;

function TExportToDeviceThread.fb2Lrf(InpFile, OutFile: string): boolean;
var
  params: string;
begin
  params := Format('-i "%s" -o "%s"', [InpFile, ChangeFileExt(OutFile, '.lrf')]
    );
  Result := ExecAndWait(Settings.AppPath + 'converters\fb2lrf\fb2lrf_c.exe',
    params, SW_HIDE)
end;

function TExportToDeviceThread.fb2EPUB(InpFile, OutFile: string): boolean;
var
  params: string;
begin
  params := Format('"%s" "%s"', [InpFile, ChangeFileExt(OutFile, '.epub')]);
  Result := ExecAndWait(Settings.AppPath + 'converters\fb2epub\fb2epub.exe',
    params, SW_HIDE)
end;

function TExportToDeviceThread.fb2PDF(InpFile, OutFile: string): boolean;
var
  params: string;
begin
  params := Format('"%s" "%s"', [InpFile, ChangeFileExt(OutFile, '.pdf')]);
  Result := ExecAndWait(Settings.AppPath + 'converters\fb2pdf\fb2pdf.cmd',
    params, SW_HIDE)
end;

procedure TExportToDeviceThread.SetTable(ATable: TAbsTable);
begin
  if Assigned(ATable) then
    FTable := ATable;
end;

procedure TExportToDeviceThread.WorkFunction;
var
  i: integer;
  totalBooks: integer;
  Res: boolean;
begin

  if FTable <> DMUser.tblGrouppedBooks then // ������� ���-�� ���������� ...
    FCollectionRoot := IncludeTrailingPathDelimiter
      (DMUser.ActiveCollection.RootFolder)
  else
    FCollectionRoot := '';

  FZipper := TZipForge.Create(nil);
  try
    // FZipper.OnMessage := ShowZipErrorMessage;

    totalBooks := High(FBookIdList) + 1;

    for i := 0 to totalBooks - 1 do
    begin
      Res := PrepareFile(FBookIdList[i].ID);
      if Res then
      begin
        if i = 0 then
          FProcessedFiles := FFileOprecord.SArch;

        Res := SendFileToDevice;
      end;

      if not Res and (i < totalBooks - 1) then
        Canceled := (ShowMessage('������������ ���������� ����� ?',
            MB_ICONQUESTION or MB_YESNO) = IDNO);

      SetComment(Format('�������� ������: %u �� %u', [i + 1, totalBooks]));
      SetProgress(i * 100 div totalBooks);

      if Canceled then
      begin
        SetComment('���������� �������� ...');
        Break;
      end;
    end;

    SetComment(Format('�������� ������: %u �� %u', [i + 1, totalBooks]));
  finally
    FreeAndNil(FZipper);
  end;
end;

end.
