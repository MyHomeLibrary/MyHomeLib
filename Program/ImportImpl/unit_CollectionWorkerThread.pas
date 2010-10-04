(* *****************************************************************************
  *
  * MyHomeLib
  *
  * Copyright (C) 2008-2010 Aleksey Penkov
  *
  * Author(s)           Nick Rymanov (nrymanov@gmail.com)
  * Created             20.08.2008
  * Description
  *
  * $Id$
  *
  * History
  *
  ****************************************************************************** *)

unit unit_CollectionWorkerThread;

interface

uses
  unit_WorkerThread,
  unit_Interfaces;

type
  TCollectionWorker = class(TWorker)
  protected
    FCollectionID: Integer;

  protected
    //
    // ��� ���� ����� ���������������� ������ � ������� ������
    //
    FSystemData: ISystemData;
    FCollection: IBookCollection;
    FCollectionRoot: string;

    procedure Initialize; override;
    procedure Uninitialize; override;

  public
    constructor Create(const CollectionID: Integer);
  end;

implementation

uses
  unit_Consts,
  unit_SystemDatabase;

{ TCollectionWorker }

constructor TCollectionWorker.Create(const CollectionID: Integer);
begin
  inherited Create;
  FCollectionID := CollectionID;
end;

procedure TCollectionWorker.Initialize;
begin
  inherited Initialize;
  FSystemData := CreateSystemData;
  Assert(Assigned(FSystemData));
  FCollection := FSystemData.GetCollection(FCollectionID);
  Assert(Assigned(FCollection));
  FCollectionRoot := FCollection.GetProperty(PROP_ROOTFOLDER);
end;

procedure TCollectionWorker.Uninitialize;
begin
  FSystemData.ClearCollectionCache;
  inherited Uninitialize;
end;

end.