(* *****************************************************************************
  *
  * MyHomeLib
  *
  * Copyright (C) 2008-2010 Aleksey Penkov
  *
  * Created             22.02.2010
  * Description
  * Author(s)           Aleksey Penkov  alex.penkov@gmail.com
  *
  * $Id$
  *
  * History
  * NickR 02.03.2010    ��� ����������������
  *
  ****************************************************************************** *)

unit frm_add_nonfb2;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ExtCtrls,
  VirtualTrees,
  StdCtrls,
  ShellApi,
  Mask,
  ComCtrls,
  Menus,
  files_list,
  unit_database,
  unit_globals,
  FBDDocument,
  FBDAuthorTable,
  Buttons;

type
  TfrmAddnonfb2 = class(TForm)
    pmEdit: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    flFiles: TFilesList;
    N5: TMenuItem;
    miClearAll: TMenuItem;
    pmMain: TPopupMenu;
    N6: TMenuItem;
    miOpenExplorer: TMenuItem;
    miOpenFile: TMenuItem;
    pcPages: TPageControl;
    tsFiles: TTabSheet;
    Tree: TVirtualStringTree;
    tsBookInfo: TTabSheet;
    gbFile: TGroupBox;
    edFileName: TEdit;
    btnCopyToFamily: TButton;
    btnCopyToName: TButton;
    btnCopyToTitle: TButton;
    btnCopyToSeries: TButton;
    btnRenameFile: TBitBtn;
    gbGenres: TGroupBox;
    lblGenre: TLabel;
    btnShowGenres: TButton;
    gbLang: TGroupBox;
    cbLang: TComboBox;
    gbKeywords: TGroupBox;
    edKeyWords: TEdit;
    gbSerie: TGroupBox;
    edSN: TEdit;
    cbSeries: TComboBox;
    gbTitle: TGroupBox;
    edT: TEdit;
    gbOptions: TGroupBox;
    cbAutoSeries: TCheckBox;
    cbSelectFileName: TCheckBox;
    cbNoAuthorAllowed: TCheckBox;
    RzGroupBox6: TGroupBox;
    cbClearOptions: TComboBox;
    btnNext: TBitBtn;
    tsFBD: TTabSheet;
    gbFDBCover: TGroupBox;
    FCover: TImage;
    btnPasteCover: TButton;
    btnLoad: TButton;
    gbPublisher: TGroupBox;
    RzLabel4: TLabel;
    RzLabel6: TLabel;
    RzLabel7: TLabel;
    RzLabel5: TLabel;
    edISBN: TEdit;
    edPublisher: TEdit;
    edYear: TEdit;
    edCity: TEdit;
    mmAnnotation: TMemo;
    dtnConvert: TBitBtn;
    btnClose: TBitBtn;
    cbForceConvertToFBD: TCheckBox;
    btnOpenBook: TBitBtn;
    FBD: TFBDDocument;
    alBookAuthors: TFBDAuthorTable;
    alFBDAuthors: TFBDAuthorTable;
    procedure RzButton3Click(Sender: TObject);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
    procedure TreeDblClick(Sender: TObject);
    procedure TreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure btnAddClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
    procedure btnShowGenresClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCopyToTitleClick(Sender: TObject);
    procedure btnCopyToSeriesClick(Sender: TObject);
    procedure btnCopyToFamilyClick(Sender: TObject);
    procedure btnCopyToNameClick(Sender: TObject);
    procedure flFilesFile(Sender: TObject; const F: TSearchRec);
    procedure miClearAllClick(Sender: TObject);
    procedure miOpenExplorerClick(Sender: TObject);
    procedure miRenameFileClick(Sender: TObject);
    procedure flFilesDirectory(Sender: TObject; const Dir: string);
    procedure TreeCompareNodes(Sender: TBaseVirtualTree; Node1, Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
    procedure TreeClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnPasteCoverClick(Sender: TObject);
    procedure dtnConvertClick(Sender: TObject);
    procedure btnFileOpenClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure AddAuthorFromList(Sender: TObject);

  private
    FBookRecord: TBookRecord;
    FOnSetControlsState: TChangeStateEvent;

    procedure PrepareBookRecord;
    procedure CommitData;

    procedure ScanFolder;
    procedure FillLists;
    procedure SortTree;
    function FillFBDData: Boolean;
  public
    property OnSetControlsState: TChangeStateEvent read FOnSetControlsState write FOnSetControlsState;

  private
    FLibrary: TMHLLibrary;
    FRootPath: string;
    function CheckEmptyFields(Data: PFileData): Boolean;
  end;

var
  frmAddnonfb2: TfrmAddnonfb2;

implementation

uses
  IOUtils,
  dm_user,
  frm_genre_tree,
  unit_TreeUtils,
  unit_Consts,
  unit_Settings,
  unit_MHLHelpers,
  unit_Helpers,
  frm_author_list,
  dm_collection;

resourcestring
  rstrFileNotSelected = '���� �� ������!';
  rstrProvideAtLeastOneAuthor = '������� ������� ������ ������!';
  rstrProvideBookTitle = '������� �������� �����!';
  rstrFailedToRename = '�������������� �� �������!' + CRLF + '��������, ���� ������������ ������ ����������.';

{$R *.dfm}

procedure TfrmAddnonfb2.FillLists;
begin
  cbSeries.Items.Clear;
  FLibrary.GetSeries(cbSeries.Items);
end;

procedure TfrmAddnonfb2.btnShowGenresClick(Sender: TObject);
var
  Data: PGenreData;
  Node: PVirtualNode;
begin

  if frmGenreTree.ShowModal = mrOk then
  begin
    lblGenre.Caption := '';
    Node := frmGenreTree.tvGenresTree.GetFirstSelected;
    while Node <> nil do
    begin
      Data := frmGenreTree.tvGenresTree.GetNodeData(Node);
      lblGenre.Caption := lblGenre.Caption + Data.GenreAlias + ' ; ';
      Node := frmGenreTree.tvGenresTree.GetNextSelected(Node);
    end;
  end;
end;

procedure TfrmAddnonfb2.btnCopyToFamilyClick(Sender: TObject);
var
  Author: TAuthorRecord;
begin
  Author.Last := Trim(edFileName.SelText);
  alBookAuthors.AddAuthor(Author);
end;

procedure TfrmAddnonfb2.btnCopyToNameClick(Sender: TObject);
var
  Author: TAuthorRecord;
begin
  if alBookAuthors.Count > 0 then
  begin
    Author := alBookAuthors.ActiveRecord;
    Author.First := (trim(edFileName.SelText));
    alBookAuthors.ActiveRecord := Author;
  end;
end;

procedure TfrmAddnonfb2.btnCopyToSeriesClick(Sender: TObject);
begin
  cbSeries.Text := Trim(edFileName.SelText);
end;

procedure TfrmAddnonfb2.btnCopyToTitleClick(Sender: TObject);
begin
  edT.Text := Trim(edFileName.SelText);
end;

procedure TfrmAddnonfb2.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FLibrary.Active := False;
  FreeAndNil(FLibrary);

  Assert(Assigned(FOnSetControlsState));
  FOnSetControlsState(True);

  Settings.ForceConvertToFBD := cbForceConvertToFBD.Checked;
  CanClose := True;
end;

procedure TfrmAddnonfb2.FormShow(Sender: TObject);
begin
  cbForceConvertToFBD.Checked := Settings.ForceConvertToFBD;

  miClearAllClick(Sender);
  lblGenre.Caption := '';

  FLibrary := TMHLLibrary.Create(Self);
  FLibrary.DatabaseFileName := DMUser.ActiveCollection.DBFileName;
  FLibrary.Active := True;

  ScanFolder;

  FillLists;
  FillGenresTree(frmGenreTree.tvGenresTree, True);
  pcPages.ActivePageIndex := 0;

  FBD.CoverSizeCode := 4;

  alBookAuthors.AddAuthorFromListButton.OnClick := AddAuthorFromList;
  alBookAuthors.AddAuthorFromListButton.Visible := True;
end;

function TfrmAddnonfb2.FillFBDData: Boolean;
var
  I: Integer;
begin
  Result := False;

  FBD.SetAuthors(alBookAuthors.Items, atlBook);
  with FBD.Title do
  begin
    Booktitle.Text := edT.Text;
    Keywords.Text := edKeyWords.Text;
    Lang := cbLang.Text;
    FBD.AddSeries(sltBook, cbSeries.Text, StrToIntDef(edSN.Text, 0));
    Genre.Clear;
    for I := 0 to High(FBookRecord.Genres) do
      Genre.Add(FBookRecord.Genres[I].FB2GenreCode);
  end;

  FBD.SetAuthors(alFBDAuthors.Items, atlFBD);

  with FBD.Publisher do
  begin
    Publisher.Text := edPublisher.Text;
    City.Text := edCity.Text;
    ISBN.Text := edISBN.Text;
    Year := edYear.Text;
  end;
  FBD.Custom.Clear;
  FBD.AutoLoadCover;
  Result := True;
end;

procedure TfrmAddnonfb2.miClearAllClick(Sender: TObject);
begin
  edT.Text := '';
  edFileName.Text := '';
  alBookAuthors.Clear;
  alFBDAuthors.Clear;
  cbSeries.Text := '';
  edSN.Text := '0';
  edKeyWords.Text := '';

  edPublisher.Clear;
  edCity.Clear;
  edISBN.Clear;
  edYear.Clear;

  mmAnnotation.Lines.Clear;
  FCover.Picture := nil;
end;

procedure TfrmAddnonfb2.miOpenExplorerClick(Sender: TObject);
var
  Data: PFileData;
begin
  Data := Tree.GetNodeData(Tree.GetFirstSelected);
  if (Data = nil) or (Data.DataType = dtFolder) then
    Exit;
  SimpleShellExecute(Handle, ExtractFilePath(Data^.FullPath), '', 'explore');
end;

function TfrmAddnonfb2.CheckEmptyFields(Data: PFileData): Boolean;
begin
  Result := False;
  try
    if Data = nil then
      raise EInvalidOp.Create(rstrFileNotSelected);
    if (not cbNoAuthorAllowed.Checked) and (alBookAuthors.Count = 0) then
      raise EInvalidOp.Create(rstrProvideAtLeastOneAuthor);
    if edT.Text = '' then
      raise EInvalidOp.Create(rstrProvideBookTitle);
    if Data.DataType = dtFolder then
      Result := False
    else
      Result := True;
  finally
  end;
end;

procedure TfrmAddnonfb2.CommitData;
var
  Next: PVirtualNode;
  Data: PFileData;
begin
  FLibrary.InsertBook(FBookRecord, True, True);

  FBookRecord.Clear;

  Next := Tree.GetNext(Tree.GetFirstSelected);
  Tree.DeleteNode(Tree.GetFirstSelected, True);
  if Next <> nil then
    Tree.Selected[Next] := True;
  case cbClearOptions.ItemIndex of
    0:
      miClearAllClick(nil);
    1:
      alBookAuthors.Clear;
    2:
      begin
        edT.Text := '';
      end;
  end;
  FillLists;
  if cbAutoSeries.Checked then
    edSN.Text := IntToStr(StrToIntDef(edSN.Text, 0) + 1);
  TreeChange(Tree, Next);

  Data := Tree.GetNodeData(Next);
  if (Data <> nil) and (Data.DataType = dtFile) then
    pcPages.ActivePage := tsBookInfo
  else
    pcPages.ActivePage := tsFiles;
end;

procedure TfrmAddnonfb2.dtnConvertClick(Sender: TObject);
var
  SavedCursor: TCursor;
begin
  // TODO: fix to save the cover

  frmAddnonfb2.Enabled := False;
  SavedCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    PrepareBookRecord;
    if cbForceConvertToFBD.Checked then
    begin
      FBD.ProgramUsed := GetProgramUsed(Application.ExeName);
      FBD.New(FRootPath + FBookRecord.Folder, FBookRecord.FileName, FBookRecord.FileExt);
      if FillFBDData then
      begin
        FBD.Save(False);
        FBookRecord.FileName := FBookRecord.FileName + ZIP_EXTENSION;
        CommitData;
      end;
    end
    else
      CommitData;
  finally
    Screen.Cursor := SavedCursor;
    frmAddnonfb2.Enabled := True;
  end;
end;

procedure TfrmAddnonfb2.miRenameFileClick(Sender: TObject);
var
  NewName: string;
  Data: PFileData;
begin
  btnRenameFile.Enabled := False;
  try
    Data := Tree.GetNodeData(Tree.GetFirstSelected);
    if CheckEmptyFields(Data) then
    begin
      NewName := CheckSymbols(alBookAuthors.ActiveRecord.Last + ' ' + alBookAuthors.ActiveRecord.First + ' ' + edT.Text);
      if RenameFile(Data.FullPath + Data.FileName + Data.Ext, Data.FullPath + NewName + Data.Ext) then
      begin
        Data.FileName := NewName;
        edFileName.Text := NewName;
        Tree.RepaintNode(Tree.GetFirstSelected);
      end
      else
        MessageDlg(rstrFailedToRename, mtError, [mbOk], 0);
    end;
  finally
    btnRenameFile.Enabled := True;
  end;
end;

procedure TfrmAddnonfb2.PrepareBookRecord;
var
  Data: PFileData;
  Author: TAuthorRecord;
begin
  Data := Tree.GetNodeData(Tree.GetFirstSelected);
  if not CheckEmptyFields(Data) then
    Exit;

  if alBookAuthors.Count > 0 then
  begin
    for Author in alBookAuthors.Items do
      TAuthorsHelper.Add(FBookRecord.Authors, Author.Last, Author.First, Author.Middle);
  end
  else
    TAuthorsHelper.Add(FBookRecord.Authors, rstrUnknownAuthor, '', '');

  frmGenreTree.GetSelectedGenres(FBookRecord);
  FBookRecord.Title := edT.Text;
  FBookRecord.Serie := cbSeries.Text;
  if Data.Folder <> '\' then
    FBookRecord.Folder := Data.Folder
  else
    FBookRecord.Folder := '';
  FBookRecord.FileName := Data.FileName;
  FBookRecord.FileExt := Data.Ext;
  FBookRecord.Code := 0;
  FBookRecord.InsideNo := 0;
  FBookRecord.SeqNumber := StrToIntDef(edSN.Text, 0);
  FBookRecord.LibID := 0;
  FBookRecord.Deleted := False;
  FBookRecord.Size := Data.Size;
  FBookRecord.Date := Now;
  FBookRecord.KeyWords := edKeyWords.Text;
  FBookRecord.Lang := cbLang.Text;
end;

procedure TfrmAddnonfb2.AddAuthorFromList(Sender: TObject);
var
  FFiltered: Boolean;
  Row: TAuthorRecord;
  Data: PAuthorData;
  Node: PVirtualNode;
begin
  FFiltered := DMCollection.Authors.Filtered;
  DMCollection.Authors.Filtered := False;
  try
    FillAuthorTree(frmAuthorList.tvAuthorList);
  finally
    DMCollection.Authors.Filtered := FFiltered;
  end;

  if frmAuthorList.ShowModal = mrOk then
  begin
    Node := frmAuthorList.tvAuthorList.GetFirstSelected;
    while Assigned(Node) do
    begin
      Data := frmAuthorList.tvAuthorList.GetNodeData(Node);

      Row.Last := Data^.LastName;
      Row.First := Data^.FirstName;
      Row.Middle := Data^.MiddleName;

      alBookAuthors.AddAuthor(Row);

      Node := frmAuthorList.tvAuthorList.GetNextSelected(Node);
    end;
  end;
end;

procedure TfrmAddnonfb2.btnAddClick(Sender: TObject);
begin
  PrepareBookRecord;
  CommitData;
end;

procedure TfrmAddnonfb2.btnLoadClick(Sender: TObject);
var
  FileName: string;
begin
  // TODO: uncomment when TfrmAddnonfb2.dtnConvertClick is fixed to actually save the cover
  Assert(False, 'Not implemented yet!');
  if GetFileName(fnOpenCoverImage, FileName) then
    FBD.LoadCoverFromFile(FileName);
end;

procedure TfrmAddnonfb2.btnNextClick(Sender: TObject);
begin
  pcPages.ActivePage := tsFBD;
end;

procedure TfrmAddnonfb2.btnPasteCoverClick(Sender: TObject);
begin
  // TODO: uncomment when TfrmAddnonfb2.dtnConvertClick is fixed to actually save the cover
  Assert(False, 'Not implemented yet!');
  FBD.LoadCoverFromClpbrd;
end;

procedure TfrmAddnonfb2.flFilesDirectory(Sender: TObject; const Dir: string);
var
  Data: PFileData;
  ParentNode: PVirtualNode;
  CurrentNode: PVirtualNode;
  ParentName: string;
  Path: string;

  procedure InsertNodeData(Node: PVirtualNode);
  begin
    Data := Tree.GetNodeData(Node);

    Initialize(Data^);
    Data.Title := ExtractFileName(ExcludeTrailingPathdelimiter(Path));
    Data.Folder := Path;
    Data.DataType := dtFolder;
    Include(Node.States, vsInitialUserData);
  end;

begin
  Path := ExtractRelativePath(FRootPath, Dir);
  if Path = '' then
    Exit;

  ParentName := ExtractFilePath(ExcludeTrailingPathdelimiter(Path));
  ParentNode := FindParentInTree(Tree, ParentName);
  if ParentNode <> nil then
  begin
    CurrentNode := Tree.AddChild(ParentNode);
    InsertNodeData(CurrentNode);
  end
  else if (FindParentInTree(Tree, Path) = nil) then
  begin
    CurrentNode := Tree.AddChild(Nil);
    InsertNodeData(CurrentNode);
  end;
end;

procedure TfrmAddnonfb2.flFilesFile(Sender: TObject; const F: TSearchRec);
var
  FullName: string;
  FileName: string;
  Data: PFileData;
  Path: String;
  ParentNode: PVirtualNode;
  CurrentNode: PVirtualNode;
  Ext: string;
begin
  if (F.Name = '.') or (F.Name = '..') then
    Exit;

  Ext := ExtractFileExt(F.Name);
  if Ext = '' then
    Exit;

  //
  // ��������� fb2-��������� � ����
  //
  if (CompareText(Ext, FB2_EXTENSION) = 0) or (CompareText(Ext, ZIP_EXTENSION) = 0) then
    Exit;

  //
  // ��������, ���� �� � ��� ����� ��� ����� ���������
  //

  if Settings.Readers.Find(Ext) = nil then
    Exit;

  if FLibrary.CheckFileInCollection(F.Name, False, True) then
    Exit;

  FullName := ExtractRelativePath(FRootPath, flFiles.LastDir + F.Name);
  FileName := TPath.GetFileNameWithoutExtension(F.Name);
  Path := ExtractRelativePath(FRootPath, flFiles.LastDir);

  ParentNode := FindParentInTree(Tree, Path);

  CurrentNode := Tree.AddChild(ParentNode);
  Data := Tree.GetNodeData(CurrentNode);

  Initialize(Data^);
  Data.DataType := dtFile;
  Data.FileName := FileName;
  Data.Size := F.Size;
  Data.FullPath := flFiles.LastDir;
  Data.Folder := Path;
  Data.Ext := Ext;
  Data.Date := F.Time;
  Include(CurrentNode.States, vsInitialUserData);
end;

procedure TfrmAddnonfb2.ScanFolder;
begin
  Tree.Clear;
  Tree.NodeDataSize := SizeOf(TFileData);

  FRootPath := DMUser.ActiveCollection.RootPath;

  flFiles.TargetPath := DMUser.ActiveCollection.RootFolder;
  flFiles.Process;
  SortTree;
end;

procedure TfrmAddnonfb2.SortTree;
var
  A, B: PVirtualNode;
  Data, DataA, DataB: PFileData;
  Parent: PVirtualNode;
begin
  Parent := Tree.GetFirst;
  Data := Tree.GetNodeData(Parent);
  while Parent <> nil do
  begin
    if (Data.DataType = dtFolder) and (Tree.HasChildren[Parent]) then
    begin
      A := Tree.GetFirstChild(Parent);
      while (A <> Parent.LastChild) do
      begin
        DataA := Tree.GetNodeData(A);
        B := Tree.GetNext(A);
        DataB := Tree.GetNodeData(B);
        if (A.Parent = B.Parent) and (DataA.DataType = dtFile) and (DataB.DataType = dtFolder) then
        begin
          Tree.MoveTo(B, A, amInsertBefore, False);
          A := Parent.FirstChild;
        end
        else
          A := B;
        B := Tree.GetNext(B);
      end;
    end;

    if (Data.DataType = dtFolder) and (Parent.ChildCount = 0) then
      Tree.DeleteNode(Parent, True);

    Parent := Tree.GetNext(Parent);
    Data := Tree.GetNodeData(Parent);
  end;
end;

procedure TfrmAddnonfb2.btnFileOpenClick(Sender: TObject);
var
  Data: PFileData;
  S: string;
begin
  Data := Tree.GetNodeData(Tree.GetFirstSelected);
  if Data <> nil then
  begin
    S := AnsiLowercase(Data.FullPath + Data.FileName + Data.Ext);
    SimpleShellExecute(Handle, S);
  end;
end;

procedure TfrmAddnonfb2.RzButton3Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmAddnonfb2.TreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);

begin
  TreeClick(Sender);
end;

procedure TfrmAddnonfb2.TreeClick(Sender: TObject);
var
  Data: PFileData;
begin
  Data := Tree.GetNodeData(Tree.GetFirstSelected);
  if (Data = nil) or (Data.DataType = dtFolder) then
    Exit;
  edFileName.Text := Data.FileName;
  if cbSelectFileName.Checked then
    edFileName.SelectAll;

end;

procedure TfrmAddnonfb2.TreeCompareNodes(Sender: TBaseVirtualTree; Node1, Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
var
  Data1, Data2: PFileData;
begin
  Data1 := Sender.GetNodeData(Node1);
  Data2 := Sender.GetNodeData(Node2);
  // Result := CompareInt(Data1.DataType, Data1.DataType);
end;

procedure TfrmAddnonfb2.TreeDblClick(Sender: TObject);
// var
// Data: PFileData;
// S: string;
begin
  // Data := Tree.GetNodedata(Tree.GetFirstSelected);
  // if Data <> nil then
  // begin
  // S := AnsiLowercase(Data.FullPath + Data.FileName + Data.Ext);
  // SimpleShellExecute(Handle, s);
  // end;
  pcPages.ActivePageIndex := 1;
end;

procedure TfrmAddnonfb2.TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  Data: PFileData;
begin
  Data := Tree.GetNodeData(Node);
  if Assigned(Data) then
    Finalize(Data^);
end;

procedure TfrmAddnonfb2.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: String);
var
  Data: PFileData;
begin
  Data := Sender.GetNodeData(Node);
  case Data.DataType of
    dtFolder:
      if Column = 0 then
        CellText := Data.Title
      else
        CellText := '';
    dtFile:
      case Column of
        0: CellText := Data.FileName;
        1: CellText := CleanExtension(Data.Ext);
        2: CellText := GetFormattedSize(Data.Size);
        3: CellText := '';
      end;
  end;
end;

procedure TfrmAddnonfb2.TreePaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
var
  Data: PFileData;
begin
  Data := Tree.GetNodeData(Node);
  if Data.DataType = dtFolder then
    TargetCanvas.Font.Style := [fsBold]
end;

end.