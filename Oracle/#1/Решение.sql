--Oracle Database 18c Express Edition Release 18.0.0.0.0 – Production
--select banner as "oracle version" from v$version

/*
    1.1. Напишите запрос, который выведет сумму комиссии по каждому сотруднику/агенту (премия * (процент комиссии / 100)), 
    а также вычисляемое поле «Comment». Если для сотрудника/агента процент комиссии больше 50,
    то в поле “Comment” должно выводиться «Повышенное вознаграждение», иначе «Стандартное вознаграждение».

------------------
select
    (a.PREMIUM * (a.SHAREPRC /100)) as sum,
    (case when (a.SHAREPRC > 50) then 'Повышенное вознаграждени' else 'Стандартное вознаграждение' end) as "Comment"
  from ABS_SUBJECT a
------------------
*/

/*
    2. Создайте функцию, которая возвращает сумму премии по полисам сотрудника по его идентификатору.
    Напишите запрос, который выведет всех сотрудников и сумму премии по их полисам, используя созданную функцию.
------------------
CREATE OR REPLACE function GetPremByEmpl(A_EMPLISN number)
  return number
  as
    V_EMPLSIN ABS_SUBJECT.PREMIUM % type;
  begin
    select a.premium
      into V_EMPLSIN
      from TEST.ABS_SUBJECT a
      where a.EMPLISN = A_EMPLISN;
    return V_EMPLSIN;
  end;
/
select a.*, GetPremByEmpl(a.emplisn) from abs_subject a --ORA-06575: Package or function GETPREMBYEMPL is in an invalid state (мне не понятна причина)
------------------
*/

/*
    3. Создайте процедуру, в которой в цикле (LOOP) всем сотрудникам устанавливается размер комиссии равный 0,5 (50%).
------------------
CREATE OR REPLACE procedure SetCommission 
  as
  begin
    for r in (select *
        from ABS_SUBJECT)
    loop
      update ABS_SUBJECT
        set SHAREPRC = 50;
    end loop;
  exception
    when NO_DATA_FOUND then null;
  end;
/
------------------
*/

/*
    4. Создайте триггер для таблицы ABS_SUBJECT, который срабатывает при добавлении или изменении записи в 
    таблице и выводит сообщение об ошибке «Комиссия не может быть меньше нуля!» в случае,
    если значение поля SHAREPRC в добавляемой/изменяемой строке меньше 0.
------------------
create trigger "trASBIU"
  before insert or update of EMPLISN, EMPLNAME, PREMIUM, SHAREPRC, DEPTISN
  on ABS_SUBJECT
  for each row
declare
  e exception;
begin
  if (:NEW.SHAREPRC < 0)
  then
    raise e;
  end if;
exception
  when e then raise_application_error(-20001, 'Комиссия не может быть меньше нуля!');
end;
/
------------------
*/

/* 
    5. В базу добавлена еще одна таблица по филиалам (ABS_DEPTS). Таблица связана с таблицей ABS_SUBJECT по графе DEPTISN.
    Напишите запрос, который выведет набольший размер комиссии для каждого филиала.
select d.deptname, max(s.SHAREPRC)
from
ABS_SUBJECT s left join ABS_DEPTS d on s.DEPTISN = d.DEPTISN
group by  d.deptname
------------------
*/

/* 
    6. Напишите запрос, который выведет два столбца. В первом столбце выводится название филиала,
    во второй столбец – все сотрудники филиала через запятую.
------------------
select d.deptname,
       listagg (s.EMPLNAME, ',') within group (order by s.EMPLNAME)
  from ABS_SUBJECT s
    left join ABS_DEPTS d
      on s.DEPTISN = d.DEPTISN
  group by d.deptname
------------------
*/

/* 
    7.	В базу добавлена еще одна таблица по филиалам (ABS_PRODUCTS).
    В таблице хранится древовидная структура продуктов компании.
    (не совсем понял задание)
------------------
select 
XMLAGG(xmlelement("row", xmlforest(prodisn, prodname, parentprod)))
 from ABS_PRODUCTS
 where parentprod = 21 -- Все продукты, входящие в узел «ЖИЛЬЕ».
------------------
*/
