// �����: ����������� �.�.
unit unitGen;

interface

uses
  System.Classes,
  System.Math,
  System.SyncObjs,
  System.SysUtils,
  System.Types,
  Winapi.Windows;

type
  // ��� ������� �����
  TSizeIn = (siB, siKB, siMB, siGB);
  // ��� ������� �� �������� � ��������� ANSI
  TArrayOfAnsiChar = array of AnsiChar;
  // ��� ������� �� ����� � ��������� ANSI
  TArrayOfAnsiStrings = array of AnsiString;
  // ��� ������� �� �������� ����� � ��������� ANSI
  TArrayOfArrayOfAnsiChar = array of TArrayOfAnsiChar;

  // ��� ������ ��� ��������� ������
  TGenData = class
  private
    // ��� �������� ������ ������
    FData: TArrayOfAnsiChar;
    // ��� �������� ������ ������ ����������
    FDataRepeatStr: TArrayOfAnsiChar;
    // ������� ������������� ������ �� ��������� �� ������ ������������ ������
    // �� ������������� �� ������������� ������ ������� (�������� ���������
    // ������ � �������) � ����������� ���������� ������
    FEventResumeWorkApp: TEvent;
    // ������� ������������� ������ �������
    FEventResumeWorkThreads: TEvent;
    // ��� �������� ������� ������������ ������
    FSize: Int64;
    // ������ ���� ��� ��������� �����
    FWL: TArrayOfAnsiStrings;
    // ��� �������� ����� ������ ������
    FQuiteMode: Boolean;
  public const
    // ������������ ������ ������ 512 ��
    MaxBufSize = 1024 * 512;
    // ������������ ����� ������������� �����
    MaxLengthGenNumber = 5;
    // ������������ ����� ������������ ������
    MaxRecSize = 256;
    // ����������� ������ ������
    MinRecSize = 6;
    // ����������� ����� �����
    MinLengthGenNumber = 1;
    // ����������� ����� ������������� ������
    MinLengthGenString = 1;
    // ���������� ����������� ������
    InnerRecDelim = '. ';
    // ������� ����������
    PercentOfRepitions = 30;
    // ��������� �����
    StringDelimiter = #13#10;
    // ������� ��������� �����, ���������� ����� ���������������� �����
    function GenNumber(AMaxLength: Integer): Integer;
    // ������� ��������� ������, ���������� ����� ��������������� ������
    function GenString(ALength: Integer; AUseRepeatBuf: Boolean = False;
      AUseUpCase: Boolean = True): Integer;
    // ������� ��������� ������ ���� Number. String
    function GenRec(ALength: Integer = TGenData.MinRecSize;
      AUseRepeatBuf: Boolean = False): Integer;
    // ��������� ��������� ������
    procedure GenerateData(ASize: Int64);
    // �������� ��� ������� � �������� ���������� ������� ������������ ������
    property Size: Int64 read FSize write FSize;
    // �����������
    constructor Create(AEventResumeWorkApp: TEvent;
      AEventResumeWorkThreads: TEvent; AQuiteMode: Boolean);
    // ����������
    destructor Destroy; override;
  end;

  // ��� ������ ��� ��������� �����
  TGenFile = class
  private
    // ��� �������� ������� � �������
    FArrayOfData: TArrayOfArrayOfAnsiChar;
    // ����������� ������ ��� ������������� ������ � �������� ������
    FCS: TCriticalSection;
    // ��� �������� ���������� ���������� ����
    FCountBytesWritten: Int64;
    // ��� �������� ���������� ����������, ������������� �������
    FCountRunningThreads, FCountEndingThreads: Integer;
    // ����������� ������ ��� �������� ���������� ���������� �������
    FCSCountThread: TCriticalSection;
    // ������� ���������� ������ �������
    FEventThreadsComplete: TEvent;
    // ������� ������������� ������ �� ��������� �� ������ ������������ ������
    // �� ������������� �� ������������� ������ ������� (�������� ���������
    // ������ � �������) � ����������� ���������� ������
    FEventResumeWorkApp: TEvent;
    // ������� ������������� ������ �������
    FEventResumeWorkThreads: TEvent;
    // ��� �������� ������ ������ �����
    FFileStream: TFileStream;
    // ��� �������� ���������� ������ ����� � ������
    FFileSize: Int64;
    // ���������� �������
    FThreadCount: Word;
    // ��� �������� ����� ������ ������
    FQuiteMode: Boolean;
    // ��������� ���������� ������ � ������ � �������
    procedure AddDataToArrayOfData(var AData: TArrayOfAnsiChar);
    // ��������� ������ ������ � ����
    procedure WriteData;
  protected
    // ��������� ������
    GenData: TGenData;
  public const
    // ����������� ���������� ���������� ������� (1000 �.�. ��� ��������� �����)
    MaxThreadCount = 1000;
    // ������������ ������ ������� (������������ ���������� ��������� � ������)
    MaxQueueSize = 100;
    // ����������� ������ ����� � ������
    MinFileSize = 18;
    // ��������� ��������� ������ � ������ �� � ����
    procedure GenerateDataAndWriteToFile;
    // ��������� ��� ���������� �������� ���������� ���������� �������
    procedure IncCountRunningThreads;
    // ��������� ��� ���������� �������� ���������� ���������� �������
    procedure IncCountEndingThreads;
    // ��������� ��������� ������ ������
    procedure RaiseError(AErrorMessage: string);
    // ��������� ������ ������ � ����
    procedure WriteDataToFile(var AData: TArrayOfAnsiChar);
    // �������� ��� ��������� �������� ������� (� ������) ���������� ������
    property CountBytesWritten: Int64 read FCountBytesWritten;
    // �������� ��� ������� � �������� ���������� ���������� �������
    property CountRunningThreads: Integer read FCountRunningThreads;
    // �����������
    constructor Create(AFileName: string; AFileSize: Int64;
      AQuiteMode: Boolean = False; ASizeIn: TSizeIn = siB;
      AThreadCount: Word = 1);
    // ����������
    destructor Destroy; override;
  end;

  // ��� ������ ������ ��� ��������� ������ � ������ � ����
  TThreadGenerateData = class(TThread)
  strict private
    // ���� ���������� ����������� ����� ������
    FFinish: Boolean;
    // ��������� �� ������
    FErrorMessage: string;
  private
    // ��������� ������
    GenData: TGenData;
    // ������ �� ������ ��������� �����
    GenFile: TGenFile;
    // ��������� ��������� ���������� ���������� �������
    procedure ChangeCountRunningThreads;
    // ��������� ��������� ������
    procedure RaiseError;
  protected
    // �������� ��������� ������
    procedure Execute; override;
  public
    // �����������
    constructor Create(AGenFile: TGenFile; APartSizeInBytes: Int64;
      AQuiteMode: Boolean);
    // ����������
    destructor Destroy; override;
  end;

implementation

{ TGenFile }

procedure TGenFile.AddDataToArrayOfData(var AData: TArrayOfAnsiChar);
begin
  // ������ � ����������� ������
  FCS.Enter;
  try
    // ����������� ������ �� �������� � ������� �� �������
    SetLength(FArrayOfData, Length(FArrayOfData) + 1);
    // ���������� ��������� �� ������ ������ �������� �������
    FArrayOfData[Length(FArrayOfData) - 1] := AData;
  finally
    // ������� �� ����������� ������
    FCS.Leave;
  end;
end;

constructor TGenFile.Create(AFileName: string; AFileSize: Int64;
  AQuiteMode: Boolean = False; ASizeIn: TSizeIn = siB; AThreadCount: Word = 1);
begin
  // ���� ��� ����� ����������
  if AFileName = '' then
    // ��������� ������
    raise Exception.Create('�� ������� ��� �����!');
  // ������ ������ ��� ������ � ������, ������������� � ����
  FFileStream := TFileStream.Create(AFileName, fmCreate);
  // ��������� ����������� ������ �����
  case ASizeIn of
    siB: // �����
      FFileSize := AFileSize;
    siKB: // ���������
      FFileSize := AFileSize * 1024;
    siMB: // ���������
      FFileSize := AFileSize * 1024 * 1024;
    siGB: // ���������
      FFileSize := AFileSize * 1024 * 1024 * 1024
  else
    FFileSize := AFileSize; // �� ��������� �������, ��� ������ ������ � ������
  end;
  // ���� ��������� ������ ����� ������ ���������� ����������
  if FFileSize < MinFileSize then
    // ��������� ������
    raise Exception.Create('��������� ����� ����� �������� ������ ����������! '
      + '(' + IntToStr(FFileSize) + ' < ' + IntToStr(MinFileSize) + ')');
  // ���� ������� �� ������ ���������� �������
  if (AThreadCount < 1) or (AThreadCount > MaxThreadCount) then
    // ��������� ������
    raise Exception.Create('�������� ���������� ������� ������� �� �����!');
  // �������������� ���������� ��� �������� ���������� ���������� ����
  FCountBytesWritten := 0;
  // �������������� ���������� ��� �������� ���������� ���������� �������
  FCountRunningThreads := 0;
  // �������������� ���������� ��� �������� ���������� ����������� �������
  FCountEndingThreads := 0;
  // ������ ����������� ������ �������� ���������� ���������� ����
  FCS := TCriticalSection.Create;
  // ������ ����������� ������ ��� �������� ���������� ���������� �������
  FCSCountThread := TCriticalSection.Create;
  // ������ ������� ���������� ������
  FEventThreadsComplete := TEvent.Create(nil, True, False, '');
  // ������ ������� ������������� ������ ��
  FEventResumeWorkApp := TEvent.Create(nil, True, True, '');
  // ������ ������� ������������� ������ �������
  FEventResumeWorkThreads := TEvent.Create(nil, True, True, '');
  // �������������� ���������� �������
  FThreadCount := AThreadCount;
  // �������������� ����� �����
  FQuiteMode := AQuiteMode;
  // ������ ��������� ������
  GenData := TGenData.Create(FEventResumeWorkApp, FEventResumeWorkThreads,
    FQuiteMode);
end;

procedure TGenFile.IncCountEndingThreads;
begin
  // ���� � ����������� ������
  FCSCountThread.Enter;
  try
    // ����������� ����� ������� ����������� ������
    Inc(FCountEndingThreads, 1);
    // ���� ����� ���������� ������� ����� ����� ������ ����������� ������
    if (FCountRunningThreads = FCountEndingThreads) then
      // ������������� �� ����
      FEventThreadsComplete.SetEvent;
  finally
    // ����� �� ����������� ������
    FCSCountThread.Leave;
  end;
end;

destructor TGenFile.Destroy;
begin
  // ����������� ������ ���������� ����������� ������
  if Assigned(GenData) then
    GenData.Free;
  // ����������� ������ ���������� ����������� �������
  if Assigned(FCS) then
    FCS.Free;
  // ����������� ������ ���������� ����������� �������
  if Assigned(FCSCountThread) then
    FCSCountThread.Free;
  // ����������� ������ ���������� �������� ���������� ������ �������
  if Assigned(FEventThreadsComplete) then
    FEventThreadsComplete.Free;
  // ����������� ������ ���������� �������� ������������� ������ ��
  if Assigned(FEventResumeWorkApp) then
    FEventResumeWorkApp.Free;
  // ����������� ������ ���������� �������� ������������� ������ �������
  if Assigned(FEventResumeWorkThreads) then
    FEventResumeWorkThreads.Free;
  // ����������� ������ ���������� �������� ��� ������ � ������� ������ �����
  if Assigned(FFileStream) then
    FFileStream.Free;
end;

procedure TGenFile.GenerateDataAndWriteToFile;
var
  // ��� �������� ������� ������������ �����, �����
  Size, PartSize: Int64;
begin
  // ��������� �������������, �� ������ �������� ������������ ������� �����,
  // �������� ������, � ������:
  // "������ ���� �����-�� ���������� ����� � ���������� ������ String."
  // ---------------------------------------------------------------------------
  // ���������� ���������� ��������� ������
  GenData.GenRec(TGenData.MinRecSize);
  // ���������� ���������� ��������� ������ � ����������� ������
  GenData.GenRec(TGenData.MinRecSize, True);
  // ������� � ���� ��������������� ������
  WriteDataToFile(GenData.FData);
  // ���� ����� ����� �� �������
  if not FQuiteMode then
    // ������� �����������\��������� ���������� (%) ���������� ������ � ����
    Writeln('��������: ', FCountBytesWritten, '\', FFileSize, ' (',
      IntToStr(FCountBytesWritten * 100 div FFileSize), '%)');
  // ---------------------------------------------------------------------------
  // ��������� ������ ������ (������ ����� ����� ���������� ��������� ����)
  Size := FFileSize - FCountBytesWritten;
  // ������ ������������ �����
  PartSize := Max(Size div FThreadCount, TGenData.MinRecSize);
  // ���� ������ ������ ������ ��� ����� ������������ ������� ������
  if Size <= TGenData.MaxBufSize then
  begin
    // ���������� ������ � �������� ������
    GenData.GenerateData(Size);
    // ���������� ������
    WriteDataToFile(GenData.FData);
    // ������� �����������\��������� ���������� (%) ���������� ������ � ����
    Writeln('��������: ', FCountBytesWritten, '\', FFileSize, ' (',
      IntToStr(FCountBytesWritten * 100 div FFileSize), '%)');
  end
  else
  begin
    // ���� ������ ��������� ��� ��������� ������ ������ ����
    while Size > 0 do
    begin
      if Size - PartSize < PartSize then
        PartSize := Size;
      // ������ ����� ��� ������
      TThreadGenerateData.Create(Self, PartSize, FQuiteMode);
      // ��������� ����������� ������ �����
      Dec(Size, PartSize);
    end;
    // ���� ������ �� ��������� ������
    while FEventThreadsComplete.WaitFor(0) = wrTimeout do
      // ����� ������ � ����
      WriteData;
    // ��� ������� ���������� ������ ���� �������
    FEventThreadsComplete.WaitFor(INFINITE);
    // ���� ��� �������� ������ ������� ��
    WriteData;
  end;
  // ����� ����������
  Writeln('���������:');
  // ���� ������������� ������� ������� �� ����
  if FCountRunningThreads = 0 then
    Writeln('������ ������ � �������� ������.')
  else
    Writeln('���������� �������������� �������: ', FCountRunningThreads, '/',
      FThreadCount, '.');
  Writeln('����������� ��������:  ', FFileSize, ' ����.');
  Writeln('���� �������� � ����:  ', FCountBytesWritten, ' ����.');
end;

procedure TGenFile.RaiseError(AErrorMessage: string);
begin
  // ������ ������� ����� ������
  Writeln('Error: ' + AErrorMessage);
end;

procedure TGenFile.WriteData;
begin
  // ���� ���� ������
  while Length(FArrayOfData) > 0 do
  begin
    // ������ � ����������� ������
    FCS.Enter;
    try
      // ���� ����� ����� �� �������
      if not FQuiteMode then
        // ���� ������ ������ ������ ~512 ��
        if Length(FArrayOfData) > MaxQueueSize then
          // ��������� ����� �������
          FEventResumeWorkThreads.ResetEvent
        else
          // ��������� ��������� �������
          FEventResumeWorkThreads.SetEvent;
      // ���������� ������ � ����
      WriteDataToFile(FArrayOfData[0]);
      // ������� �����
      SetLength(FArrayOfData[0], 0);
      // ������� ����� �� ������� � �������
      Delete(FArrayOfData, 0, 1);
    finally
      // ������� �� ����������� ������
      FCS.Leave;
    end;
    // ���� ����� ����� ��������
    if not FQuiteMode then
    begin
      // ������� ������� ������������� ������ ��
      FEventResumeWorkApp.ResetEvent;
      // ������� �����������\��������� ���������� (%) ���������� ������ � ����
      Writeln('��������: ', FCountBytesWritten, '\', FFileSize, ' (',
        IntToStr(FCountBytesWritten * 100 div FFileSize), '%)');
      // ��������� ������� ������������� ������ ��
      FEventResumeWorkApp.SetEvent;
    end;
  end;
end;

procedure TGenFile.WriteDataToFile(var AData: TArrayOfAnsiChar);
begin
  // �������� �������� � ���� ������ ������
  if FFileStream.Write(TBytes(AData), Length(AData)) = -1 then
    // ���� �� ������� �������� ������ ��������� ������
    raise Exception.Create('������ ������ ������!');
  // ����������� ������ ���������� ������ � ����
  Inc(FCountBytesWritten, Length(AData));
  // ������� ������ ������
  SetLength(GenData.FData, 0);
end;

procedure TGenFile.IncCountRunningThreads;
begin
  // ���� � ����������� ������
  FCSCountThread.Enter;
  try
    // ����������� ����� ���������� �������
    Inc(FCountRunningThreads, 1);
  finally
    // ����� �� ����������� ������
    FCSCountThread.Leave;
  end;
end;

{ TThreadGenerateAndWrite }

procedure TThreadGenerateData.ChangeCountRunningThreads;
begin
  // ���� ������ ���������
  if FFinish then
    // ����������� ����� ����������� ������ �������
    GenFile.IncCountEndingThreads
  else // �����
    // ����������� ����� ���������� �������
    GenFile.IncCountRunningThreads;
end;

constructor TThreadGenerateData.Create(AGenFile: TGenFile;
  APartSizeInBytes: Int64; AQuiteMode: Boolean);
begin
  // �������������� ���� ���������
  GenFile := AGenFile;
  // ������ ��������� ������
  GenData := TGenData.Create(GenFile.FEventResumeWorkApp,
    GenFile.FEventResumeWorkThreads, AQuiteMode);
  // ��������� ����������� ������ ������������ ������
  GenData.FSize := APartSizeInBytes;
  // ������ ���������� �����
  inherited Create(False);
end;

destructor TThreadGenerateData.Destroy;
begin
  // ����������� ������ ���������� ����������� ������
  if Assigned(GenData) then
    GenData.Free;
  inherited;
end;

procedure TThreadGenerateData.Execute;
var
  I: Integer;
begin
  inherited;
  try
    FFinish := False;
    ChangeCountRunningThreads;
    try
      // ���� ����������� ������ ������ ���� � ������ ������ �� ���������
      while (GenData.FSize > 0) and not Terminated do
      begin
        // ���������� ������
        GenData.GenerateData(Min(GenData.MaxBufSize, GenData.FSize));
        // ��������� ��������
        if GenData.FSize - Length(GenData.FData) < GenData.MinRecSize then
        begin
          // ����� ����������� �����
          SetLength(GenData.FData, Length(GenData.FData) -
            Length(GenData.StringDelimiter));
          // �������� ����������� ����� �� ����� ��������������� ������
          GenData.GenString(GenData.FSize - Length(GenData.FData) -
            Length(GenData.StringDelimiter), False, False);
          for I := 1 to Length(GenData.StringDelimiter) do
          begin
            // ����������� ������ ������ �� �������
            SetLength(GenData.FData, Length(GenData.FData) + 1);
            // ���������� � ����� �������� �� ����������� �����
            GenData.FData[Length(GenData.FData) - 1] :=
              AnsiChar(GenData.StringDelimiter[I]);
          end;
        end;
        // �������� ������ ��������������� ������ � ������ � �������
        GenFile.AddDataToArrayOfData(GenData.FData);
        // ��������� ������ ����������� ��������������� ������
        Dec(GenData.FSize, Length(GenData.FData));
        // ������� ������ �� ������
        GenData.FData := nil;
      end;
    finally
      FFinish := True;
      ChangeCountRunningThreads;
    end;
  except
    on E: Exception do
    begin
      // ������� ��������� �� ������
      FErrorMessage := E.Message;
      // ������� �� ������
      RaiseError;
    end;
  end;
end;

procedure TThreadGenerateData.RaiseError;
begin
  // ���������� ������
  GenFile.RaiseError(FErrorMessage);
end;

{ TGenData }

constructor TGenData.Create(AEventResumeWorkApp: TEvent;
  AEventResumeWorkThreads: TEvent; AQuiteMode: Boolean);
begin
  // �������������� ������ ������������ ������
  FSize := 0;
  // �������������� ������ ����
  SetLength(FWL, 10);
  FWL[0] := 'a';
  FWL[1] := 'is';
  FWL[2] := 'the';
  FWL[3] := 'best';
  FWL[4] := 'apple';
  FWL[5] := 'cherry';
  FWL[6] := 'banana';
  FWL[7] := 'something';
  FWL[8] := 'like';
  FWL[9] := 'that';
  // ������� ������ �� ������� ������������� ������ ��
  FEventResumeWorkApp := AEventResumeWorkApp;
  // ������� ������ �� ������� ������������� ������ �������
  FEventResumeWorkThreads := AEventResumeWorkThreads;
  // �������������� ����� �����
  FQuiteMode := AQuiteMode;
end;

destructor TGenData.Destroy;
begin
  // ����������� ������ ���������� �������� ���� ��� ��������� �����
  SetLength(FWL, 0);
  inherited;
end;

procedure TGenData.GenerateData(ASize: Int64);
var
  // ��� �������� ����� ������������� ������������ ������ ������ ����������
  NURB: Boolean;
  // ��� �������� ����������� ����� ������������ ������
  L: Integer;
  // ��������
  I: Integer;
begin
  // ���� ����� ������ ����
  while ASize > 0 do
  begin
    // ��� ����������� ������� ������������� ������ ��
    FEventResumeWorkApp.WaitFor(INFINITE);
    // ���� ����� ����� �� �������
    if not FQuiteMode then
    begin
      // ��� ����������� ������� ������������� ������ �������
      FEventResumeWorkThreads.WaitFor(INFINITE);
    end;
    // ���� ��������� ����� ������ ���������� ��������� ����� ������
    if (ASize < MinRecSize) then
    begin
      // ����� ����������� �����
      SetLength(FData, Length(FData) - Length(StringDelimiter));
      // �������� ����������� ����� �� ����� ��������������� ������
      ASize := ASize - Int64(GenString(ASize, False, False));
      // ���� ���������� �������� ������ ����������� ����� � ����� ������
      // ������ � ����� ������ ����������� �����
      for I := 1 to Length(StringDelimiter) do
      begin
        // ����������� ������ ������ �� �������
        SetLength(FData, Length(FData) + 1);
        // ���������� � ����� �������� �� ����������� �����
        FData[Length(FData) - 1] := AnsiChar(StringDelimiter[I]);
      end;
    end
    else
    begin
      // �������������� ��������� ������-��������� �����
      Randomize;
      // ���������� �������� ����� ������������� ������������ ����� ����������
      NURB :=
      // ���������� ����������� ������������� ������ ���������� (�����?)
        (Length(FDataRepeatStr) <= ASize - Length(StringDelimiter)) and
        (ASize >= MinRecSize) and (Length(FDataRepeatStr) > 0) and
        (ASize > MaxRecSize + MinRecSize)
      // ��������� ������������� ������������� ������ ���������� (�����?)
        and (RandomRange(0, 100) < PercentOfRepitions);
      // ���� ���������� ����� ����������
      if NURB then
        L := MaxRecSize + MinRecSize
      else
        // ���������� ����������� ����� ������
        L := RandomRange(MinRecSize,
          Min(ASize, (MaxRecSize + MinRecSize) - Length(StringDelimiter)) + 1);
      // ���� ����� ����������� ������ ������ ��� ����� ����������� �����
      // ������ ���� ����� ����������� �����
      if L >= MinRecSize + Length(StringDelimiter) then
        Dec(L, Length(StringDelimiter));
      // ���������� ������
      L := GenRec(L, NURB);
      // �������� ����������� ����� �� ����� ��������������� ������
      ASize := ASize - Int64(L);
    end;
  end;
end;

function TGenData.GenNumber(AMaxLength: Integer): Integer;
var
  LenGenNumber: Integer; // ��� �������� ����� ������������� �����
begin
  // �������������� �������������� ���������� ��������������� ��������
  Result := 0;
  if AMaxLength < 1 then
    Exit;
  // �������������� ��������� ������-��������� �����
  Randomize;
  // ���������� ����� ������������� ����� ��������� � AMaxLength
  LenGenNumber := RandomRange(MinLengthGenNumber,
    Min(AMaxLength, MaxLengthGenNumber + 1) + 1);
  // ����������� ������ ������ �� �������
  SetLength(FData, Length(FData) + 1);
  // ���������� ������ �� 1 �� 9 � ����� ������
  FData[Length(FData) - 1] := AnsiChar(RandomRange(49, 58));
  // ��������� ����������� ����� ������������� ����� �� �������
  Dec(LenGenNumber);
  // ����������� �� ������� �������������� ���������� ��������������� ��������
  Inc(Result);
  // ���� ����������� ����� ������������� ����� ������ �������
  while LenGenNumber > 1 do
  begin
    // ����������� ������ ������ �� �������
    SetLength(FData, Length(FData) + 1);
    // ���������� ������ �� 0 �� 9 � ����� ������
    FData[Length(FData) - 1] := AnsiChar(RandomRange(48, 58));
    // ��������� ����������� ����� ������������� ����� �� �������
    Dec(LenGenNumber);
    // ����������� �� ������� �������������� ���������� ��������������� ��������
    Inc(Result);
  end;
end;

function TGenData.GenRec(ALength: Integer = TGenData.MinRecSize;
  AUseRepeatBuf: Boolean = False): Integer;
var
  // ��������, ���������� ��� �������� ����� ��������������� ������
  I: Integer;
  // ��� �������� ����� ������
  L: Integer;
begin
  // ���� ��������� ����� ������ ������ �����������
  if ALength < MinRecSize then
    // ��������� ����� ������ ����� �����������
    ALength := MinRecSize;
  // ���� ������������ ����� ����������
  if AUseRepeatBuf then
  begin
    // ��������� ����� �����
    L := // ��������� �������� ��������� ������������ ����� �����
      ALength - // ��������� ������ ������ �����
      Length(InnerRecDelim) - // ����� ����������� ����������� �����
      Length(FDataRepeatStr) - // ����� ������ ���������� �����
      Length(StringDelimiter); // ����� ����������� �����
  end
  else
  begin
    // ��������� ����� �����
    L := // ��������� �������� ��������� ������������ ����� �����
      ALength - // ��������� ������ ������
      Length(InnerRecDelim) - // ����� ����������� ����������� �����
      MinLengthGenString - // ����������� ����� ������������� ������ �����
      Length(StringDelimiter) // ����� ����������� �����
      ;
  end;
  // ���������� ����� � �������������� Result
  Result := GenNumber(L);
  if Result > L then
    Result := Result;
  // ���������� � ����� ������ ���������� �����������
  for I := 1 to Length(InnerRecDelim) do
  begin
    // ����������� ����� ������ ������ �� �������
    SetLength(FData, Length(FData) + 1);
    // ���������� � ����� ������ ����������� �����������
    FData[Length(FData) - 1] := AnsiString(InnerRecDelim)[I];
    // ����������� �� ������� �������������� ����� ��������������� ��������
    Inc(Result);
  end;
  // ���� ������������ ����� ����������
  if AUseRepeatBuf then
  begin
    // ��������� ����� ������ ����� ����� ������ ����������
    L := Length(FDataRepeatStr);
  end
  else
  begin
    // ��������� ����� ������
    L := // ��������� �������� ��������� ������������ ����� ������
      ALength - // ��������� ������ ������ �����
      Result - // ����� ���������������� ����� �����
      Length(StringDelimiter);
  end;
  // ���������� ������
  I := GenString(L, AUseRepeatBuf);
  // ����������� �������������� ���������� ��������������� ��������
  // �� ����� ��������������� ������
  Inc(Result, I);
  // ������ � ����� ������ ����������� �����
  for I := 1 to Length(StringDelimiter) do
  begin
    // ����������� ������ ������ �� �������
    SetLength(FData, Length(FData) + 1);
    // ���������� � ����� �������� �� ����������� �����
    FData[Length(FData) - 1] := AnsiChar(StringDelimiter[I]);
    // ����������� �� ������� �������������� ����� ��������������� ��������
    Inc(Result);
  end;
end;

function TGenData.GenString(ALength: Integer;
  AUseRepeatBuf, AUseUpCase: Boolean): Integer;
var
  // ��������
  I: Integer;
  // ��� �������� ������ ���������� �����
  ASW: AnsiString;
begin
  // �������������� �������������� ���������� ��������������� ��������
  Result := 0;
  if not AUseRepeatBuf then
    // �������������� ������ ������ ������ ���������� �� �������
    SetLength(FDataRepeatStr, 0);
  if ALength < 1 then
    ALength := ALength;
  // ���� ����������� ����� ������ �������
  if ALength < 1 then
    // ������� �� ���������
    Exit;
  // ���� ������������ ����� �������
  if AUseRepeatBuf then
    for I := 0 to Length(FDataRepeatStr) - 1 do
    begin
      if ALength < 1 then
        Break;
      // ����������� ������ ������ �� �������
      SetLength(FData, Length(FData) + 1);
      // ���������� ������ �� ������ ������ ���������� � ����� ������
      FData[Length(FData) - 1] := FDataRepeatStr[I];
      // ����������� �� ������� �������������� ����� ��������������� ��������
      Inc(Result);
    end
  else // ���� �� ������������ ����� �������
  begin
    // �������������� ��������� ������-��������� �����
    Randomize;
    // �������� ��������� �����
    ASW := FWL[RandomRange(0, Length(FWL))];
    // ����������� ������ ������ �� �������
    SetLength(FData, Length(FData) + 1);
    // ���������� ������ ����� ���������� �����
    if AUseUpCase then
      FData[Length(FData) - 1] := UpCase(ASW[1])
    else
      FData[Length(FData) - 1] := ASW[1];
    // ����������� ������ ������ ��� ���������� �� �������
    SetLength(FDataRepeatStr, Length(FDataRepeatStr) + 1);
    // �������� ��������������� ������ �� ������ � ������ ����������
    FDataRepeatStr[Length(FDataRepeatStr) - 1] := FData[Length(FData) - 1];
    // ��������� ����������� �����
    Dec(ALength);
    // ����������� �� ������� �������������� ����� ��������������� ��������
    Inc(Result);
    for I := 2 to Length(ASW) do
    begin
      if ALength < 1 then
        Break;
      // ����������� ������ ������ �� �������
      SetLength(FData, Length(FData) + 1);
      // ���������� ������ ����� ���������� �����
      FData[Length(FData) - 1] := ASW[I];
      // ����������� ������ ������ ��� ���������� �� �������
      SetLength(FDataRepeatStr, Length(FDataRepeatStr) + 1);
      // �������� ��������������� ������ �� ������ � ������ ����������
      FDataRepeatStr[Length(FDataRepeatStr) - 1] := FData[Length(FData) - 1];
      // ��������� ����������� �����
      Dec(ALength);
      // ����������� �� ������� �������������� ����� ��������������� ��������
      Inc(Result);
    end;
    while ALength > 0 do
    begin
      // ����������� ������ ������ �� �������
      SetLength(FData, Length(FData) + 1);
      // ���������� ������ � �����
      FData[Length(FData) - 1] := Space;
      // ����������� ������ ������ ��� ���������� �� �������
      SetLength(FDataRepeatStr, Length(FDataRepeatStr) + 1);
      // �������� ��������������� ������ �� ������ � ������ ����������
      FDataRepeatStr[Length(FDataRepeatStr) - 1] := FData[Length(FData) - 1];
      // ��������� ����������� �����
      Dec(ALength);
      // ����������� �� ������� �������������� ����� ��������������� ��������
      Inc(Result);
      if ALength < 1 then
        Break;
      // �������� ��������� �����
      ASW := FWL[RandomRange(0, Length(FWL))];
      for I := 1 to Length(ASW) do
      begin
        if ALength < 1 then
          Break;
        // ����������� ������ ������ �� �������
        SetLength(FData, Length(FData) + 1);
        // ���������� ������ ����� ���������� �����
        FData[Length(FData) - 1] := ASW[I];
        // ����������� ������ ������ ��� ���������� �� �������
        SetLength(FDataRepeatStr, Length(FDataRepeatStr) + 1);
        // �������� ��������������� ������ �� ������ � ������ ����������
        FDataRepeatStr[Length(FDataRepeatStr) - 1] := FData[Length(FData) - 1];
        // ��������� ����������� �����
        Dec(ALength);
        // ����������� �� ������� �������������� ����� ��������������� ��������
        Inc(Result);
      end;
    end;
  end;
end;

end.
