// Автор: Закасаренко Д.Н.
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
  // Тип размера файла
  TSizeIn = (siB, siKB, siMB, siGB);
  // Тип массива из символов в кодировке ANSI
  TArrayOfAnsiChar = array of AnsiChar;
  // Тип массива из строк в кодировке ANSI
  TArrayOfAnsiStrings = array of AnsiString;
  // Тип массива из массивов строк в кодировке ANSI
  TArrayOfArrayOfAnsiChar = array of TArrayOfAnsiChar;

  // Тип класса для генерации данных
  TGenData = class
  private
    // Для хранения данных буфера
    FData: TArrayOfAnsiChar;
    // Для хранения данных строки повторения
    FDataRepeatStr: TArrayOfAnsiChar;
    // Событие возобновления работы ПО требуется на случай приостановки работы
    // ПО пользователем на неопределённый период времени (например выделение
    // текста в консоли) и продолжения дальнейшей работы
    FEventResumeWorkApp: TEvent;
    // Событие возобновления работы потоков
    FEventResumeWorkThreads: TEvent;
    // Для хранения размера генерируемых данных
    FSize: Int64;
    // Массив слов для генерации строк
    FWL: TArrayOfAnsiStrings;
    // Для хранения флага тихого режима
    FQuiteMode: Boolean;
  public const
    // Максимальный размер буфера 512 кб
    MaxBufSize = 1024 * 512;
    // Максимальная длина генерируемого числа
    MaxLengthGenNumber = 5;
    // Максимальная длина генерируемой записи
    MaxRecSize = 256;
    // Минимальный размер записи
    MinRecSize = 6;
    // Минимальная длина числа
    MinLengthGenNumber = 1;
    // Минимальная длина гененрируемой строки
    MinLengthGenString = 1;
    // Внутренний разделитель записи
    InnerRecDelim = '. ';
    // Процент повторений
    PercentOfRepitions = 30;
    // Разделить строк
    StringDelimiter = #13#10;
    // Функция генерации числа, возвращает длину сгенерированного числа
    function GenNumber(AMaxLength: Integer): Integer;
    // Функции генерации строки, возвращает длину сгенерированной строки
    function GenString(ALength: Integer; AUseRepeatBuf: Boolean = False;
      AUseUpCase: Boolean = True): Integer;
    // Функция генерации записи типа Number. String
    function GenRec(ALength: Integer = TGenData.MinRecSize;
      AUseRepeatBuf: Boolean = False): Integer;
    // Процедура генерации данных
    procedure GenerateData(ASize: Int64);
    // Свойтсво для доступа к значению требуемого размера генерируемых данных
    property Size: Int64 read FSize write FSize;
    // Конструктор
    constructor Create(AEventResumeWorkApp: TEvent;
      AEventResumeWorkThreads: TEvent; AQuiteMode: Boolean);
    // Деструктор
    destructor Destroy; override;
  end;

  // Тип класса для генерации файла
  TGenFile = class
  private
    // Для хранения масивов с данными
    FArrayOfData: TArrayOfArrayOfAnsiChar;
    // Критическая секция для согласованной работы с масивоми данных
    FCS: TCriticalSection;
    // Для хранения количества записанных байт
    FCountBytesWritten: Int64;
    // Для хранения количества запущенных, остановленных потоков
    FCountRunningThreads, FCountEndingThreads: Integer;
    // Критическая секция для контроля количества работающих потоков
    FCSCountThread: TCriticalSection;
    // Событие завершения работы потоков
    FEventThreadsComplete: TEvent;
    // Событие возобновления работы ПО требуется на случай приостановки работы
    // ПО пользователем на неопределённый период времени (например выделение
    // текста в консоли) и продолжения дальнейшей работы
    FEventResumeWorkApp: TEvent;
    // Событие возобновления работы потоков
    FEventResumeWorkThreads: TEvent;
    // Для хранения потока данных файла
    FFileStream: TFileStream;
    // Для хранения требуемого размер файла в байтах
    FFileSize: Int64;
    // Количество потоков
    FThreadCount: Word;
    // Для хранения флага тихого режима
    FQuiteMode: Boolean;
    // Процедура добавления данных в массив с данными
    procedure AddDataToArrayOfData(var AData: TArrayOfAnsiChar);
    // Процедура записи данных в файл
    procedure WriteData;
  protected
    // Генератор данных
    GenData: TGenData;
  public const
    // Максимально допустимое количество потоков (1000 т.к. без изменений стека)
    MaxThreadCount = 1000;
    // Максимальный размер очереди (максимальное количество элементов в масиве)
    MaxQueueSize = 100;
    // Минимальный размер файла в байтах
    MinFileSize = 18;
    // Процедура генерации данных и записи их в файл
    procedure GenerateDataAndWriteToFile;
    // Процедура для увеличения значения количества работающих потоков
    procedure IncCountRunningThreads;
    // Процедура для уменьшения значения количества работающих потоков
    procedure IncCountEndingThreads;
    // Процедура обработки ошибки записи
    procedure RaiseError(AErrorMessage: string);
    // Процедура записи данных в файл
    procedure WriteDataToFile(var AData: TArrayOfAnsiChar);
    // Свойтсво для получения значения размера (в байтах) записанных данных
    property CountBytesWritten: Int64 read FCountBytesWritten;
    // Свойтсво для доступа к значению количества работающих потоков
    property CountRunningThreads: Integer read FCountRunningThreads;
    // Конструктор
    constructor Create(AFileName: string; AFileSize: Int64;
      AQuiteMode: Boolean = False; ASizeIn: TSizeIn = siB;
      AThreadCount: Word = 1);
    // Деструктор
    destructor Destroy; override;
  end;

  // Тип класса потока для генерации данных и записи в файл
  TThreadGenerateData = class(TThread)
  strict private
    // Флаг завершения необходимых работ потока
    FFinish: Boolean;
    // Сообщение об ошибке
    FErrorMessage: string;
  private
    // Генератор данных
    GenData: TGenData;
    // Ссылка на объект генерации файла
    GenFile: TGenFile;
    // Процедура изменения количества запущенных потоков
    procedure ChangeCountRunningThreads;
    // Процедура генерации ошибки
    procedure RaiseError;
  protected
    // Основная процедура потока
    procedure Execute; override;
  public
    // Конструктор
    constructor Create(AGenFile: TGenFile; APartSizeInBytes: Int64;
      AQuiteMode: Boolean);
    // Деструктор
    destructor Destroy; override;
  end;

implementation

{ TGenFile }

procedure TGenFile.AddDataToArrayOfData(var AData: TArrayOfAnsiChar);
begin
  // Входим в критическую секцию
  FCS.Enter;
  try
    // Увеличиваем массив из массивов с данными на еденицу
    SetLength(FArrayOfData, Length(FArrayOfData) + 1);
    // Записываем указатель на данные новому элементу массива
    FArrayOfData[Length(FArrayOfData) - 1] := AData;
  finally
    // Выходим из критической секции
    FCS.Leave;
  end;
end;

constructor TGenFile.Create(AFileName: string; AFileSize: Int64;
  AQuiteMode: Boolean = False; ASizeIn: TSizeIn = siB; AThreadCount: Word = 1);
begin
  // Если имя файла отсутсвует
  if AFileName = '' then
    // Поднимаем ошибку
    raise Exception.Create('Не указано имя файла!');
  // Создаём объект для работы с файлом, следовательно и файл
  FFileStream := TFileStream.Create(AFileName, fmCreate);
  // Вычисляем необходимый размер файла
  case ASizeIn of
    siB: // Байты
      FFileSize := AFileSize;
    siKB: // Килобайты
      FFileSize := AFileSize * 1024;
    siMB: // Мегабайты
      FFileSize := AFileSize * 1024 * 1024;
    siGB: // Гигабайты
      FFileSize := AFileSize * 1024 * 1024 * 1024
  else
    FFileSize := AFileSize; // По умолчанию считаем, что размер указан в байтах
  end;
  // Если указанный размер файла меньше минимально возможного
  if FFileSize < MinFileSize then
    // Поднимаем ошибку
    raise Exception.Create('Указанная длина файла является меньше допустимой! '
      + '(' + IntToStr(FFileSize) + ' < ' + IntToStr(MinFileSize) + ')');
  // Если указано не верное количество потоков
  if (AThreadCount < 1) or (AThreadCount > MaxThreadCount) then
    // Поднимаем ошибку
    raise Exception.Create('Значение количества потоков указано не верно!');
  // Инициализируем переменную для хранения количества записанных байт
  FCountBytesWritten := 0;
  // Инициализируем переменную для хранения количества запущенных потоков
  FCountRunningThreads := 0;
  // Инициализируем переменную для хранения количества зевершённых потоков
  FCountEndingThreads := 0;
  // Создаём критическую секцию контроля количества записанных байт
  FCS := TCriticalSection.Create;
  // Создаём критическую секцию для контроля количества работающих потоков
  FCSCountThread := TCriticalSection.Create;
  // Создаём событие завершения работы
  FEventThreadsComplete := TEvent.Create(nil, True, False, '');
  // Создаём событие возобновления работы ПО
  FEventResumeWorkApp := TEvent.Create(nil, True, True, '');
  // Создаём событие возобновления работы потоков
  FEventResumeWorkThreads := TEvent.Create(nil, True, True, '');
  // Инициализируем количество потоков
  FThreadCount := AThreadCount;
  // Инициализируем тихий режим
  FQuiteMode := AQuiteMode;
  // Создаём генератор данных
  GenData := TGenData.Create(FEventResumeWorkApp, FEventResumeWorkThreads,
    FQuiteMode);
end;

procedure TGenFile.IncCountEndingThreads;
begin
  // Вход в критическую секцию
  FCSCountThread.Enter;
  try
    // Увеличиваем число потоков завершивших работу
    Inc(FCountEndingThreads, 1);
    // Если число запущенных потоков равно числу потокв завершивших работу
    if (FCountRunningThreads = FCountEndingThreads) then
      // Сигнализируем об этом
      FEventThreadsComplete.SetEvent;
  finally
    // Выход из критической секции
    FCSCountThread.Leave;
  end;
end;

destructor TGenFile.Destroy;
begin
  // Освобождаем память занимаемую генератором данных
  if Assigned(GenData) then
    GenData.Free;
  // Освобождаем память занимаемую критической секцией
  if Assigned(FCS) then
    FCS.Free;
  // Освобождаем память занимаемую критической секцией
  if Assigned(FCSCountThread) then
    FCSCountThread.Free;
  // Освобождаем память занимаемую событием завершения работы потоков
  if Assigned(FEventThreadsComplete) then
    FEventThreadsComplete.Free;
  // Освобождаем память занимаемую событием возобновления работы ПО
  if Assigned(FEventResumeWorkApp) then
    FEventResumeWorkApp.Free;
  // Освобождаем память занимаемую событием возобновления работы потоков
  if Assigned(FEventResumeWorkThreads) then
    FEventResumeWorkThreads.Free;
  // Освобождаем память занимаемую объектом для работы с потоком данных файла
  if Assigned(FFileStream) then
    FFileStream.Free;
end;

procedure TGenFile.GenerateDataAndWriteToFile;
var
  // Для хранения размера генерируемых даных, части
  Size, PartSize: Int64;
begin
  // Выполняем обязательства, на случай указания минимального размера файла,
  // согласно задаче, а именно:
  // "Должно быть какое-то количество строк с одинаковой частью String."
  // ---------------------------------------------------------------------------
  // Генерируем минимально возможную запись
  GenData.GenRec(TGenData.MinRecSize);
  // Генерируем минимально возможную запись с повторением строки
  GenData.GenRec(TGenData.MinRecSize, True);
  // Запишем в файл сгенерированные данные
  WriteDataToFile(GenData.FData);
  // Если тихий режим не включен
  if not FQuiteMode then
    // Выводим фактическое\ожидаемое количество (%) записанных данных в файл
    Writeln('Записано: ', FCountBytesWritten, '\', FFileSize, ' (',
      IntToStr(FCountBytesWritten * 100 div FFileSize), '%)');
  // ---------------------------------------------------------------------------
  // Требуемый размер данных (размер файла минус количество записаных байт)
  Size := FFileSize - FCountBytesWritten;
  // Размер генерируемой части
  PartSize := Max(Size div FThreadCount, TGenData.MinRecSize);
  // Если размер данных меньше или равен минимальному размеру записи
  if Size <= TGenData.MaxBufSize then
  begin
    // Генерируем данные в основном потоке
    GenData.GenerateData(Size);
    // Записываем данные
    WriteDataToFile(GenData.FData);
    // Выводим фактическое\ожидаемое количество (%) записанных данных в файл
    Writeln('Записано: ', FCountBytesWritten, '\', FFileSize, ' (',
      IntToStr(FCountBytesWritten * 100 div FFileSize), '%)');
  end
  else
  begin
    // Пока размер требуемых для генерации данных больше нуля
    while Size > 0 do
    begin
      if Size - PartSize < PartSize then
        PartSize := Size;
      // Создаём поток для работы
      TThreadGenerateData.Create(Self, PartSize, FQuiteMode);
      // Уменьшаем необходимый размер файла
      Dec(Size, PartSize);
    end;
    // Пока потоки не завершили работу
    while FEventThreadsComplete.WaitFor(0) = wrTimeout do
      // Пишем данные в файл
      WriteData;
    // Ждём события завершения работы всех потоков
    FEventThreadsComplete.WaitFor(INFINITE);
    // Если ещё остались данные запишем их
    WriteData;
  end;
  // Вывод результата
  Writeln('Результат:');
  // Если доплнительных рабочих потоков не было
  if FCountRunningThreads = 0 then
    Writeln('Работа велась в основном потоке.')
  else
    Writeln('Количество использованных потоков: ', FCountRunningThreads, '/',
      FThreadCount, '.');
  Writeln('Требовалось записать:  ', FFileSize, ' байт.');
  Writeln('Было записано в файл:  ', FCountBytesWritten, ' байт.');
end;

procedure TGenFile.RaiseError(AErrorMessage: string);
begin
  // Просто выведем текст ошибки
  Writeln('Error: ' + AErrorMessage);
end;

procedure TGenFile.WriteData;
begin
  // Пока есть данные
  while Length(FArrayOfData) > 0 do
  begin
    // Входим в критическую секцию
    FCS.Enter;
    try
      // Если тихий режим не включен
      if not FQuiteMode then
        // Если размер данных больше ~512 мб
        if Length(FArrayOfData) > MaxQueueSize then
          // Выполняем сброс события
          FEventResumeWorkThreads.ResetEvent
        else
          // Выполняем установку события
          FEventResumeWorkThreads.SetEvent;
      // Записываем данные в файл
      WriteDataToFile(FArrayOfData[0]);
      // Очищаем буфер
      SetLength(FArrayOfData[0], 0);
      // Удаляем масив из массива с данными
      Delete(FArrayOfData, 0, 1);
    finally
      // Выходим из критической секции
      FCS.Leave;
    end;
    // Если тихий режим выключен
    if not FQuiteMode then
    begin
      // Сбросим событие возобновления работы ПО
      FEventResumeWorkApp.ResetEvent;
      // Выводим фактическое\ожидаемое количество (%) записанных данных в файл
      Writeln('Записано: ', FCountBytesWritten, '\', FFileSize, ' (',
        IntToStr(FCountBytesWritten * 100 div FFileSize), '%)');
      // Установим событие возобновления работы ПО
      FEventResumeWorkApp.SetEvent;
    end;
  end;
end;

procedure TGenFile.WriteDataToFile(var AData: TArrayOfAnsiChar);
begin
  // Пытаемся записать в файл данные буфера
  if FFileStream.Write(TBytes(AData), Length(AData)) = -1 then
    // Если не удалось записать данные поднимаем ошибку
    raise Exception.Create('Ошибка записи данных!');
  // Увеличиваем размер записанных данных в файл
  Inc(FCountBytesWritten, Length(AData));
  // Очистка буфера данных
  SetLength(GenData.FData, 0);
end;

procedure TGenFile.IncCountRunningThreads;
begin
  // Вход в критическую секцию
  FCSCountThread.Enter;
  try
    // Увеличиваем число запущенных потоков
    Inc(FCountRunningThreads, 1);
  finally
    // Выход из критической секции
    FCSCountThread.Leave;
  end;
end;

{ TThreadGenerateAndWrite }

procedure TThreadGenerateData.ChangeCountRunningThreads;
begin
  // Если работа завершена
  if FFinish then
    // Увеличиваем число завершивших работу потоков
    GenFile.IncCountEndingThreads
  else // Иначе
    // Увеличиваем число запущенных потоков
    GenFile.IncCountRunningThreads;
end;

constructor TThreadGenerateData.Create(AGenFile: TGenFile;
  APartSizeInBytes: Int64; AQuiteMode: Boolean);
begin
  // Инициализируем файл генерации
  GenFile := AGenFile;
  // Создаём генератор данных
  GenData := TGenData.Create(GenFile.FEventResumeWorkApp,
    GenFile.FEventResumeWorkThreads, AQuiteMode);
  // Установим необходимый размер генерируемых данных
  GenData.FSize := APartSizeInBytes;
  // Создаём работающий поток
  inherited Create(False);
end;

destructor TThreadGenerateData.Destroy;
begin
  // Освобождаем память занимаемую генератором данных
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
      // Пока необходимый размер больше нуля и работа потока не завершена
      while (GenData.FSize > 0) and not Terminated do
      begin
        // Генерируем данные
        GenData.GenerateData(Min(GenData.MaxBufSize, GenData.FSize));
        // Обработка концовки
        if GenData.FSize - Length(GenData.FData) < GenData.MinRecSize then
        begin
          // Уберём разделитель строк
          SetLength(GenData.FData, Length(GenData.FData) -
            Length(GenData.StringDelimiter));
          // Уменьшим необходимую длину на длину сгенерированной строки
          GenData.GenString(GenData.FSize - Length(GenData.FData) -
            Length(GenData.StringDelimiter), False, False);
          for I := 1 to Length(GenData.StringDelimiter) do
          begin
            // Увеличиваем размер буфера на еденицу
            SetLength(GenData.FData, Length(GenData.FData) + 1);
            // Записываем в буфер значение из разделителя строк
            GenData.FData[Length(GenData.FData) - 1] :=
              AnsiChar(GenData.StringDelimiter[I]);
          end;
        end;
        // Поместим массив сгенерированных данных в массив с данными
        GenFile.AddDataToArrayOfData(GenData.FData);
        // Уменьшаем размер необходимых сгенерированных данных
        Dec(GenData.FSize, Length(GenData.FData));
        // Забудем ссылку на массив
        GenData.FData := nil;
      end;
    finally
      FFinish := True;
      ChangeCountRunningThreads;
    end;
  except
    on E: Exception do
    begin
      // Запишем сообщение об ошибке
      FErrorMessage := E.Message;
      // Сообщим об ошибке
      RaiseError;
    end;
  end;
end;

procedure TThreadGenerateData.RaiseError;
begin
  // Обработаем ошибку
  GenFile.RaiseError(FErrorMessage);
end;

{ TGenData }

constructor TGenData.Create(AEventResumeWorkApp: TEvent;
  AEventResumeWorkThreads: TEvent; AQuiteMode: Boolean);
begin
  // Инициализируем размер генерируемых данных
  FSize := 0;
  // Инициализируем массив слов
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
  // Получим ссылку на событие возобновления работы ПО
  FEventResumeWorkApp := AEventResumeWorkApp;
  // Получим ссылку на событие возобновления работы потоков
  FEventResumeWorkThreads := AEventResumeWorkThreads;
  // Инициализируем тихий режим
  FQuiteMode := AQuiteMode;
end;

destructor TGenData.Destroy;
begin
  // Освобождаем память занимаемую массивом слов для генерации строк
  SetLength(FWL, 0);
  inherited;
end;

procedure TGenData.GenerateData(ASize: Int64);
var
  // Для хранения флага необходимости использовать данные буфера повторения
  NURB: Boolean;
  // Для хранения необходимой длины генерируемой записи
  L: Integer;
  // Итератор
  I: Integer;
begin
  // Пока длина больше нуля
  while ASize > 0 do
  begin
    // Ждём наступления события возобновления работы ПО
    FEventResumeWorkApp.WaitFor(INFINITE);
    // Если тихий режим не включен
    if not FQuiteMode then
    begin
      // Ждём наступления события возобновления работы потоков
      FEventResumeWorkThreads.WaitFor(INFINITE);
    end;
    // Если требуемая длина меньше минимально возможной длине записи
    if (ASize < MinRecSize) then
    begin
      // Уберём разделитель строк
      SetLength(FData, Length(FData) - Length(StringDelimiter));
      // Уменьшим необходимую длину на длину сгенерированной строки
      ASize := ASize - Int64(GenString(ASize, False, False));
      // Если необходимо записать данные разделителя строк в буфер данных
      // Запись в буфер данных разделителя строк
      for I := 1 to Length(StringDelimiter) do
      begin
        // Увеличиваем размер буфера на еденицу
        SetLength(FData, Length(FData) + 1);
        // Записываем в буфер значение из разделителя строк
        FData[Length(FData) - 1] := AnsiChar(StringDelimiter[I]);
      end;
    end
    else
    begin
      // Инициализируем генератор псевдо-случайных чисел
      Randomize;
      // Определяем значение флага необходимости использовать буфер повторения
      NURB :=
      // Определяем возможность использования буфера повторения (можем?)
        (Length(FDataRepeatStr) <= ASize - Length(StringDelimiter)) and
        (ASize >= MinRecSize) and (Length(FDataRepeatStr) > 0) and
        (ASize > MaxRecSize + MinRecSize)
      // Вычисляем необходимость использования буфера повторения (хотим?)
        and (RandomRange(0, 100) < PercentOfRepitions);
      // Если используем буфер повторения
      if NURB then
        L := MaxRecSize + MinRecSize
      else
        // Генерируем необходимую длину записи
        L := RandomRange(MinRecSize,
          Min(ASize, (MaxRecSize + MinRecSize) - Length(StringDelimiter)) + 1);
      // Если длина необходимых данных больше или равна минимальной длине
      // записи плюс длина разделителя строк
      if L >= MinRecSize + Length(StringDelimiter) then
        Dec(L, Length(StringDelimiter));
      // Генерируем запись
      L := GenRec(L, NURB);
      // Уменьшим необходимую длину на длину сгенерированной записи
      ASize := ASize - Int64(L);
    end;
  end;
end;

function TGenData.GenNumber(AMaxLength: Integer): Integer;
var
  LenGenNumber: Integer; // Для хранения длины генерируемого числа
begin
  // Инициализируем результирующее количество сгенерированных символов
  Result := 0;
  if AMaxLength < 1 then
    Exit;
  // Инициализируем генератор псевдо-случайных чисел
  Randomize;
  // Генерируем длину генерируемого числа ограничив её AMaxLength
  LenGenNumber := RandomRange(MinLengthGenNumber,
    Min(AMaxLength, MaxLengthGenNumber + 1) + 1);
  // Увеличиваем размер буфера на еденицу
  SetLength(FData, Length(FData) + 1);
  // Генерируем символ от 1 до 9 в буфер данных
  FData[Length(FData) - 1] := AnsiChar(RandomRange(49, 58));
  // Уменьшаем необходимую длину генерируемого числа на единицу
  Dec(LenGenNumber);
  // Увеличиваем на единицу результирующее количество сгенерированных символов
  Inc(Result);
  // Пока необходимая длина генерируемого числа больше единицы
  while LenGenNumber > 1 do
  begin
    // Увеличиваем размер буфера на еденицу
    SetLength(FData, Length(FData) + 1);
    // Генерируем символ от 0 до 9 в буфер данных
    FData[Length(FData) - 1] := AnsiChar(RandomRange(48, 58));
    // Уменьшаем необходимую длину генерируемого числа на единицу
    Dec(LenGenNumber);
    // Увеличиваем на единицу результирующее количество сгенерированных символов
    Inc(Result);
  end;
end;

function TGenData.GenRec(ALength: Integer = TGenData.MinRecSize;
  AUseRepeatBuf: Boolean = False): Integer;
var
  // Итератор, переменная для хранения длины сгенерированной строки
  I: Integer;
  // Для хранения длины записи
  L: Integer;
begin
  // Если требуемая длина записи меньше минимальной
  if ALength < MinRecSize then
    // Требуемая длина записи равна минимальной
    ALength := MinRecSize;
  // Если используется буфер повторения
  if AUseRepeatBuf then
  begin
    // Возможная длина числа
    L := // Вычисляем значение возможной максимальной длины числа
      ALength - // Требуемый размер записи минус
      Length(InnerRecDelim) - // Длина внутреннего разделителя минус
      Length(FDataRepeatStr) - // Длина буфера повторения минус
      Length(StringDelimiter); // Длина разделителя строк
  end
  else
  begin
    // Возможная длина числа
    L := // Вычисляем значение возможной максимальной длины числа
      ALength - // Требуемый размер записи
      Length(InnerRecDelim) - // Длина внутреннего разделителя минус
      MinLengthGenString - // Минимальная длина гененрируемой строки минус
      Length(StringDelimiter) // Длина разделителя строк
      ;
  end;
  // Генерируем число и инициализируем Result
  Result := GenNumber(L);
  if Result > L then
    Result := Result;
  // Записываем в буфер данных внутренний разделитель
  for I := 1 to Length(InnerRecDelim) do
  begin
    // Увеличиваем длину буфера данных на единицу
    SetLength(FData, Length(FData) + 1);
    // Записываем в буфер данные внутреннего разделителя
    FData[Length(FData) - 1] := AnsiString(InnerRecDelim)[I];
    // Увеличиваем на единицу результирующее число сгенерированных символов
    Inc(Result);
  end;
  // Если используется буфер повторения
  if AUseRepeatBuf then
  begin
    // Требуемая длина строки равна длине буфера повторения
    L := Length(FDataRepeatStr);
  end
  else
  begin
    // Требуемая длина строки
    L := // Вычисляем значение возможной максимальной длины строки
      ALength - // Требуемый размер записи минус
      Result - // Длина сгенерированного числа минус
      Length(StringDelimiter);
  end;
  // Генерируем строку
  I := GenString(L, AUseRepeatBuf);
  // Увеличиваем результирующее количество сгенерированных символов
  // на длину сгенерированной строки
  Inc(Result, I);
  // Запись в буфер данных разделителя строк
  for I := 1 to Length(StringDelimiter) do
  begin
    // Увеличиваем размер буфера на еденицу
    SetLength(FData, Length(FData) + 1);
    // Записываем в буфер значение из разделителя строк
    FData[Length(FData) - 1] := AnsiChar(StringDelimiter[I]);
    // Увеличиваем на единицу результирующее число сгенерированных символов
    Inc(Result);
  end;
end;

function TGenData.GenString(ALength: Integer;
  AUseRepeatBuf, AUseUpCase: Boolean): Integer;
var
  // Итератор
  I: Integer;
  // Для хранения данных выбранного слова
  ASW: AnsiString;
begin
  // Инициализируем результирующее количество сгенерированных символов
  Result := 0;
  if not AUseRepeatBuf then
    // Инициализируем размер буфера строки повторения на еденицу
    SetLength(FDataRepeatStr, 0);
  if ALength < 1 then
    ALength := ALength;
  // Если необходимая длина меньше единицы
  if ALength < 1 then
    // Выходим из процедуры
    Exit;
  // Если используется буфер повтора
  if AUseRepeatBuf then
    for I := 0 to Length(FDataRepeatStr) - 1 do
    begin
      if ALength < 1 then
        Break;
      // Увеличиваем размер буфера на еденицу
      SetLength(FData, Length(FData) + 1);
      // Записываем данные из буфера строки повторения в буфер данных
      FData[Length(FData) - 1] := FDataRepeatStr[I];
      // Увеличиваем на единицу результирующее число сгенерированных символов
      Inc(Result);
    end
  else // Если не используется буфер повтора
  begin
    // Инициализируем генератор псевдо-случайных чисел
    Randomize;
    // Выбираем случайное слово
    ASW := FWL[RandomRange(0, Length(FWL))];
    // Увеличиваем размер буфера на еденицу
    SetLength(FData, Length(FData) + 1);
    // Записываем первую букву выбранного слова
    if AUseUpCase then
      FData[Length(FData) - 1] := UpCase(ASW[1])
    else
      FData[Length(FData) - 1] := ASW[1];
    // Увеличиваем размер буфера для повторения на еденицу
    SetLength(FDataRepeatStr, Length(FDataRepeatStr) + 1);
    // Копируем сгенерированный символ из буфера в буфера повторения
    FDataRepeatStr[Length(FDataRepeatStr) - 1] := FData[Length(FData) - 1];
    // Уменьшаем необходимую длину
    Dec(ALength);
    // Увеличиваем на единицу результирующее число сгенерированных символов
    Inc(Result);
    for I := 2 to Length(ASW) do
    begin
      if ALength < 1 then
        Break;
      // Увеличиваем размер буфера на еденицу
      SetLength(FData, Length(FData) + 1);
      // Записываем первую букву выбранного слова
      FData[Length(FData) - 1] := ASW[I];
      // Увеличиваем размер буфера для повторения на еденицу
      SetLength(FDataRepeatStr, Length(FDataRepeatStr) + 1);
      // Копируем сгенерированный символ из буфера в буфера повторения
      FDataRepeatStr[Length(FDataRepeatStr) - 1] := FData[Length(FData) - 1];
      // Уменьшаем необходимую длину
      Dec(ALength);
      // Увеличиваем на единицу результирующее число сгенерированных символов
      Inc(Result);
    end;
    while ALength > 0 do
    begin
      // Увеличиваем размер буфера на еденицу
      SetLength(FData, Length(FData) + 1);
      // Записываем пробел в буфер
      FData[Length(FData) - 1] := Space;
      // Увеличиваем размер буфера для повторения на еденицу
      SetLength(FDataRepeatStr, Length(FDataRepeatStr) + 1);
      // Копируем сгенерированный символ из буфера в буфера повторения
      FDataRepeatStr[Length(FDataRepeatStr) - 1] := FData[Length(FData) - 1];
      // Уменьшаем необходимую длину
      Dec(ALength);
      // Увеличиваем на единицу результирующее число сгенерированных символов
      Inc(Result);
      if ALength < 1 then
        Break;
      // Выбираем случайное слово
      ASW := FWL[RandomRange(0, Length(FWL))];
      for I := 1 to Length(ASW) do
      begin
        if ALength < 1 then
          Break;
        // Увеличиваем размер буфера на еденицу
        SetLength(FData, Length(FData) + 1);
        // Записываем первую букву выбранного слова
        FData[Length(FData) - 1] := ASW[I];
        // Увеличиваем размер буфера для повторения на еденицу
        SetLength(FDataRepeatStr, Length(FDataRepeatStr) + 1);
        // Копируем сгенерированный символ из буфера в буфера повторения
        FDataRepeatStr[Length(FDataRepeatStr) - 1] := FData[Length(FData) - 1];
        // Уменьшаем необходимую длину
        Dec(ALength);
        // Увеличиваем на единицу результирующее число сгенерированных символов
        Inc(Result);
      end;
    end;
  end;
end;

end.
