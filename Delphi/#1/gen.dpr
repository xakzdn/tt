// Автор: Закасаренко Д.Н.
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
  // Инициализируем результат
  Result := 0;
  // В цикле перебираем параметры
  for i := 1 to ParamCount do
    // Если найден искомый параметр
    if LowerCase(Trim(ParamStr(i))) = LowerCase(AParamName) then
      // Вернём его индекс (порядковый номер)
      Result := i;
end;

procedure Help;
begin
  Writeln('Пример вызова: gen.exe [опции]');
  Writeln('Возможные опции:');
  Writeln(' -f [Имя файла или полный путь к файлу] - Указание файла вывода');
  Writeln(' -h - Вывод на экран помощи по программе');
  Writeln(' -m [Кол-во потоков] - Указание максимального количества потоков');
  Writeln(' -s [Размер файла] - Указание требуемого размера файла вывода');
  Writeln(' -t [Тип указанного размера файла] - Указание типа размера');
  Writeln(' -q - Указание использования тихого(быстрого) режима');
  Writeln('Возможные типы размера файла:');
  Writeln(' B - Байты');
  Writeln(' K - Килобайты');
  Writeln(' M - Мегабайты');
  Writeln(' G - Гигабайты');
  Writeln('Ограничения:');
  Writeln(' Минимальный размер файла = ' + IntToStr(TGenFile.MinFileSize) +
    ' байт.');
  Writeln(' Минимальное количество потоков = 1.');
  Writeln(' Максимальное количество потоков = ' +
    IntToStr(TGenFile.MaxThreadCount) + '.');
  Writeln('Примечания:');
  Writeln(' Если имя или путь к файлу содежрит пробелы, используйте кавычки.');
  Writeln(' Если путь к файлу не указан будет использован рабочий каталог.');
  Writeln(' Если тип размера файла не указан будет использован тип B - Байты.');
  Writeln(' Если количество потоков не указано будет использован 1 поток.');
  Writeln(' При использовании тихого режима, не будет:'#13#10 +
    '  - Вывода в консоль информации о процессе выполнения записи.'#13#10 +
    '  - Приостановок работы (например при выделение текста в консоли) '#13#10 +
    '    за счёт этого производительность будет выше.');
  Writeln('Пример вызова для генерации файла размером 10 GB в 1000 потоков:' +
    #13#10 + ' gen.exe -f f.txt -t G -s 10 -m 1000 -q');
end;

var
  // Для хранения данных о дате и времени
  DT: TDateTime;
  // Для хранения имени файла (полного пути)
  F: string;
  // Для хранения данных о максимально возможном количестве потоков генерации
  M: Integer;
  // Для хранения данных о размере файла
  S: Int64;
  // Для хранения данных о типе размера файла
  T: TSizeIn;
  // Для хранения данных флага тихого режима
  Q: Boolean = False;

begin
  try
    // Если существует параметр -h
    if GetIndexParam('-h') > 0 then
    begin
      // Выведем на экран помощь по программе
      Help;
      // Завершим работу
      Exit;
    end;
    // Если существует параметр -f
    if GetIndexParam('-f') > 0 then
      // Устанавливаем значение имени файла
      F := ParamStr(GetIndexParam('-f') + 1);
    // Инициализируем значение максимально возможного количества потоков
    M := 1;
    // Если существует параметр -m
    if GetIndexParam('-m') > 0 then
      // Если значение количества потоков указано не верно
      if not TryStrToInt(ParamStr(GetIndexParam('-m') + 1), M) or (M < 1) or
        (M > TGenFile.MaxThreadCount) then
        // Поднимаем ошибку
        raise Exception.Create('Значение количества потоков указано не верно!');
    // Если существует параметр -s
    if GetIndexParam('-s') > 0 then
      // Если значение размера файла указано не верно
      if not TryStrToInt64(ParamStr(GetIndexParam('-s') + 1), S) then
        // Поднимаем ошибку
        raise Exception.Create('Размер файла указан не верно!');
    // Инициализируем тип размера файла по умолчанию
    T := siB;
    // Если существует параметр -t
    if GetIndexParam('-t') > 0 then
      // Если значение типа размера файла указано
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
    // Устанавливаем значение тихого режима
    Q := GetIndexParam('-q') > 0;
    // Вычисляем дату и время на момент запуска
    DT := Now;
    // Выводим информацию о времени начала выполнения
    Writeln('Время начала выполнения: ' + FormatDateTime('hh:mm:ss.zzz', DT));
    try
      // Создание экземпляра класса для генерации файла
      with TGenFile.Create(F, S, Q, T, M) do
        try
          // Генерация данных и запись их в файл
          GenerateDataAndWriteToFile;
        finally
          // Освобождение памяти занемаемой экземпляром класса
          Free;
        end;
      // Вычисляем дату и время на момент завершения генерации файла
      DT := Now - DT;
      // Выводим информацию о времени выполнения
      Writeln('Время выполнения генерации данных и записи их в файл: ',
        FormatDateTime('hh:mm:ss.zzz', DT));
    except
      on E: Exception do
        Writeln('Ошибка: [' + E.ClassName, '] ', E.Message);
    end;
    // Выводим информацию о времени конца выполнения
    Writeln('Время конца выполнения: ' + FormatDateTime('hh:mm:ss.zzz', Now));
  except
    // В случае ошибки осуществляем её обработку путём вывода на экран сообщения
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
