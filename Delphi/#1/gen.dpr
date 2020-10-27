// �����: ����������� �.�.
program gen;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  unitGen in 'unitGen.pas';

function GetIndexParam(AParamName: string): Integer;
var
  i: Integer;
begin
  // �������������� ���������
  Result := 0;
  // � ����� ���������� ���������
  for i := 1 to ParamCount do
    // ���� ������ ������� ��������
    if LowerCase(Trim(ParamStr(i))) = LowerCase(AParamName) then
      // ����� ��� ������ (���������� �����)
      Result := i;
end;

procedure Help;
begin
  Writeln('������ ������: gen.exe [�����]');
  Writeln('��������� �����:');
  Writeln(' -f [��� ����� ��� ������ ���� � �����] - �������� ����� ������');
  Writeln(' -h - ����� �� ����� ������ �� ���������');
  Writeln(' -m [���-�� �������] - �������� ������������� ���������� �������');
  Writeln(' -s [������ �����] - �������� ���������� ������� ����� ������');
  Writeln(' -t [��� ���������� ������� �����] - �������� ���� �������');
  Writeln(' -q - �������� ������������� ������(��������) ������');
  Writeln('��������� ���� ������� �����:');
  Writeln(' B - �����');
  Writeln(' K - ���������');
  Writeln(' M - ���������');
  Writeln(' G - ���������');
  Writeln('�����������:');
  Writeln(' ����������� ������ ����� = ' + IntToStr(TGenFile.MinFileSize) +
    ' ����.');
  Writeln(' ����������� ���������� ������� = 1.');
  Writeln(' ������������ ���������� ������� = ' +
    IntToStr(TGenFile.MaxThreadCount) + '.');
  Writeln('����������:');
  Writeln(' ���� ��� ��� ���� � ����� �������� �������, ����������� �������.');
  Writeln(' ���� ���� � ����� �� ������ ����� ����������� ������� �������.');
  Writeln(' ���� ��� ������� ����� �� ������ ����� ����������� ��� B - �����.');
  Writeln(' ���� ���������� ������� �� ������� ����� ����������� 1 �����.');
  Writeln(' ��� ������������� ������ ������, �� �����:'#13#10 +
    '  - ������ � ������� ���������� � �������� ���������� ������.'#13#10 +
    '  - ������������ ������ (�������� ��� ��������� ������ � �������) '#13#10 +
    '    �� ���� ����� ������������������ ����� ����.');
  Writeln('������ ������ ��� ��������� ����� �������� 10 GB � 1000 �������:' +
    #13#10 + ' gen.exe -f f.txt -t G -s 10 -m 1000 -q');
end;

var
  // ��� �������� ������ � ���� � �������
  DT: TDateTime;
  // ��� �������� ����� ����� (������� ����)
  F: string;
  // ��� �������� ������ � ����������� ��������� ���������� ������� ���������
  M: Integer;
  // ��� �������� ������ � ������� �����
  S: Int64;
  // ��� �������� ������ � ���� ������� �����
  T: TSizeIn;
  // ��� �������� ������ ����� ������ ������
  Q: Boolean = False;

begin
  try
    // ���� ���������� �������� -h
    if GetIndexParam('-h') > 0 then
    begin
      // ������� �� ����� ������ �� ���������
      Help;
      // �������� ������
      Exit;
    end;
    // ���� ���������� �������� -f
    if GetIndexParam('-f') > 0 then
      // ������������� �������� ����� �����
      F := ParamStr(GetIndexParam('-f') + 1);
    // �������������� �������� ����������� ���������� ���������� �������
    M := 1;
    // ���� ���������� �������� -m
    if GetIndexParam('-m') > 0 then
      // ���� �������� ���������� ������� ������� �� �����
      if not TryStrToInt(ParamStr(GetIndexParam('-m') + 1), M) or (M < 1) or
        (M > TGenFile.MaxThreadCount) then
        // ��������� ������
        raise Exception.Create('�������� ���������� ������� ������� �� �����!');
    // ���� ���������� �������� -s
    if GetIndexParam('-s') > 0 then
      // ���� �������� ������� ����� ������� �� �����
      if not TryStrToInt64(ParamStr(GetIndexParam('-s') + 1), S) then
        // ��������� ������
        raise Exception.Create('������ ����� ������ �� �����!');
    // �������������� ��� ������� ����� �� ���������
    T := siB;
    // ���� ���������� �������� -t
    if GetIndexParam('-t') > 0 then
      // ���� �������� ���� ������� ����� �������
      if ParamStr(GetIndexParam('-t') + 1) <> '' then
        case UpperCase(ParamStr(GetIndexParam('-t') + 1))[1] of
          'B':
            T := siB;
          'K':
            T := siKB;
          'M':
            T := siMB;
          'G':
            T := siGB;
        else
          T := siB;
        end;
    // ������������� �������� ������ ������
    Q := GetIndexParam('-q') > 0;
    // ��������� ���� � ����� �� ������ �������
    DT := Now;
    // ������� ���������� � ������� ������ ����������
    Writeln('����� ������ ����������: ' + FormatDateTime('hh:mm:ss.zzz', DT));
    try
      // �������� ���������� ������ ��� ��������� �����
      with TGenFile.Create(F, S, Q, T, M) do
        try
          // ��������� ������ � ������ �� � ����
          GenerateDataAndWriteToFile;
        finally
          // ������������ ������ ���������� ����������� ������
          Free;
        end;
      // ��������� ���� � ����� �� ������ ���������� ��������� �����
      DT := Now - DT;
      // ������� ���������� � ������� ����������
      Writeln('����� ���������� ��������� ������ � ������ �� � ����: ',
        FormatDateTime('hh:mm:ss.zzz', DT));
    except
      on E: Exception do
        Writeln('������: [' + E.ClassName, '] ', E.Message);
    end;
    // ������� ���������� � ������� ����� ����������
    Writeln('����� ����� ����������: ' + FormatDateTime('hh:mm:ss.zzz', Now));
  except
    // � ������ ������ ������������ � ��������� ���� ������ �� ����� ���������
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
