--1. Создайте роли:
CREATE ROLE operator_role NOINHERIT NOREPLICATION;
CREATE ROLE dispatcher_role NOINHERIT NOREPLICATION;
--2. Создайте пользователей:
CREATE ROLE "IvanovIV" SUPERUSER NOINHERIT NOREPLICATION LOGIN;
COMMENT ON ROLE "IvanovIV" IS 'Иванов И.В. (администратор)';
CREATE ROLE "PetrovPE" NOINHERIT NOREPLICATION LOGIN IN ROLE dispatcher_role, operator_role;
COMMENT ON ROLE "PetrovPE" IS 'Петров П.Е. (оператор и диспетчер)';
CREATE ROLE "SokolovAA" NOINHERIT NOREPLICATION LOGIN IN ROLE dispatcher_role;
COMMENT ON ROLE "SokolovAA" IS 'Соколов А.А. (диспетчер)';
CREATE ROLE "KozlovVA" NOINHERIT NOREPLICATION LOGIN IN ROLE operator_role;
COMMENT ON ROLE "KozlovVA" IS 'Козлов В.А. (оператор)';
--3. Создайте справочники:
--3.1. Автомобили.
CREATE TABLE public.cars (
  state_number VARCHAR(15) UNIQUE,
  vin VARCHAR(17) UNIQUE,
  brand VARCHAR(100)
)
WITH (oids = false);
COMMENT ON TABLE public.cars IS 'Автомобили';
COMMENT ON COLUMN public.cars.state_number IS 'Госномер';
COMMENT ON COLUMN public.cars.vin IS 'VIN код';
COMMENT ON COLUMN public.cars.brand IS 'Марка';
--3.2. Водители.
CREATE TABLE public.drivers (
  surename VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL UNIQUE,
  patronymic VARCHAR(100) NOT NULL UNIQUE,
  date_of_birth DATE,
  employment_date DATE,
  gender VARCHAR(50),
  status SMALLINT,
  category VARCHAR(100),
  address VARCHAR(200),
  telephone VARCHAR(15)
)
WITH (oids = false);
COMMENT ON TABLE public.drivers IS 'Водители';
COMMENT ON COLUMN public.drivers.surename IS 'Фамилия';
COMMENT ON COLUMN public.drivers.name IS 'Имя';
COMMENT ON COLUMN public.drivers.patronymic IS 'Отчество';
COMMENT ON COLUMN public.drivers.date_of_birth IS 'Дата рождения';
COMMENT ON COLUMN public.drivers.gender IS 'Пол';
COMMENT ON COLUMN public.drivers.employment_date IS 'Дата приема на работу';
COMMENT ON COLUMN public.drivers.status IS 'Статус (работает/уволен) (0/1)';
COMMENT ON COLUMN public.drivers.category IS 'Категория';
COMMENT ON COLUMN public.drivers.address IS 'Адрес';
COMMENT ON COLUMN public.drivers.telephone IS 'Телефон';
--3.3. Маршруты.
CREATE TABLE public.routes (
/*  guid uuid,*/
  tractor VARCHAR(100),
  route_type VARCHAR(100),
  opening_status VARCHAR(100),
  opening_date DATE,
  user_open_route VARCHAR(100),
  drivers VARCHAR(100)
)
WITH (oids = false);
COMMENT ON TABLE public.routes IS 'Маршруты';
COMMENT ON COLUMN public.routes.tractor IS 'Тягач';
COMMENT ON COLUMN public.routes.route_type IS 'Тип маршрута';
COMMENT ON COLUMN public.routes.opening_status IS 'Статус открытия';
COMMENT ON COLUMN public.routes.opening_date IS 'Дата открытия';
COMMENT ON COLUMN public.routes.user_open_route IS 'Пользователь, открывший маршрут';
COMMENT ON COLUMN public.routes.drivers IS 'Водители';
--3.3.1 -- Триггер для генерации GUID
/*CREATE FUNCTION trigger_bi_routes_f(
)
RETURNS trigger AS
$body$
BEGIN
  if new.guid is null then new.guid =
  --Можно подгрузить модуль pgcrypto и использовать gen_random_uuid() [CREATE EXTENSION pgcrypto;]
  --Можно подгрузить модуль uuid-ossp и использовать uuid_generate_v4() [CREATE EXTENSION "uuid-ossp";]
  --Что бы не подгружать модули воспользуюсь приведением типов и MD5 ХЭШэм это ведь тестовое задание
  uuid_in(md5(random()::text || now()::text)::cstring);
  end if;
  RETURN NEW;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER;
CREATE TRIGGER trigger_bi_routes
  BEFORE INSERT
  ON public.routes FOR EACH ROW
  EXECUTE PROCEDURE trigger_bi_routes_f();*/
--3.4. Точки маршрутов.
CREATE TABLE public.route_points (
  route VARCHAR(100),
  object_id UUID,
  object_type VARCHAR(100),
  object_name VARCHAR(100),
  date_plan_arrival DATE,
  date_fact_arrival DATE
)
WITH (oids = false);
COMMENT ON TABLE public.route_points IS 'Точки маршрутов';
COMMENT ON COLUMN public.route_points.route IS 'Маршрут';
COMMENT ON COLUMN public.route_points.object_id IS 'ИД объекта';
COMMENT ON COLUMN public.route_points.object_type IS 'Тип объекта';
COMMENT ON COLUMN public.route_points.object_name IS 'Название объекта';
COMMENT ON COLUMN public.route_points.date_plan_arrival IS 'Дата планового прибытия/убытия';
COMMENT ON COLUMN public.route_points.date_fact_arrival IS 'Дата фактического прибытия/убытия';
--4. Раздаём ролям оператор и диспетчер права на чтение и запись.
GRANT SELECT, INSERT, UPDATE ON public.cars TO dispatcher_role, operator_role;
GRANT SELECT, INSERT, UPDATE ON public.drivers TO dispatcher_role, operator_role;
GRANT SELECT, INSERT, UPDATE ON public.route_points TO dispatcher_role, operator_role;
GRANT SELECT, INSERT, UPDATE ON public.routes TO dispatcher_role, operator_role;
--5. Заполнение созданных таблиц некими данными.
--5.1 INSERT (напишите запросы добавления)
INSERT INTO public.cars ("state_number", "vin", "brand")
 VALUES (E'А777АА123RU', E'KL1UF756E6B195928', E'Chevrolet Rezzo 2005');
INSERT INTO public.drivers ("surename", "name", "patronymic", "date_of_birth", "employment_date", "gender", "status", "category", "address", "telephone")
 VALUES (E'Иванов', E'Пётр', E'Сергеевич', E'1991-01-01', E'2016-07-24', E'Мужской', 0, E'B', E'г.Краснодар', E'7-918-111-22-23');
INSERT INTO public.route_points ("route", "object_id", "object_type", "object_name", "date_plan_arrival", "date_fact_arrival")
 VALUES (E'Маршрут 1', E'123456789012345678901234567890AB', E'Тип объкта 1', E'Объект 1', E'2016-07-24', E'2016-07-23');
INSERT INTO public.routes (/*"guid",*/ "tractor", "route_type", "opening_status", "opening_date", "user_open_route", "drivers")
 VALUES (/*null,*/ E'Тягач 1', E'Тип маршрута 1', E'Открыт', E'2016-07-24', E'Пользователь 1', E'Иванов И.И.\r\nПетров П.П.');
--5.1 UPDATE (изменения)
UPDATE public.cars
SET state_number = E'Б777ББ123RU'
WHERE state_number = E'А777АА123RU' and
      vin = E'KL1UF756E6B195928' and
      brand = E'Chevrolet Rezzo 2005';
UPDATE public.drivers
SET category = E'C'
WHERE surename = E'Иванов' and
      name = E'Пётр' and
      patronymic = E'Сергеевич' and
      date_of_birth = E'1991-01-01' and
      employment_date = E'2016-07-24' and
      gender = E'Мужской' and
      status = 0 and
      category = E'B' and
      address = E'г.Краснодар' and
      telephone = E'7-918-111-22-23';
UPDATE public.route_points
SET date_plan_arrival = E'2016-07-25'
WHERE route = E'Маршрут 1';
UPDATE public.routes
SET opening_date = E'2016-07-23'
WHERE tractor = E'Тягач 1';
--5.2 DELETE (удаления записей)
/*
DELETE FROM public.cars;
DELETE FROM public.drivers;
DELETE FROM public.route_points;
DELETE FROM public.routes;
*/
--5.3 TRUNCATE (а также очистки таблицы).
/*
TRUNCATE public.cars, public.drivers, public.route_points, public.routes;
*/
--6. Создаём хранимую процедуру для добавления водителей.
CREATE OR REPLACE FUNCTION public.drivers_add (
  surename varchar,
  name varchar,
  patronymic varchar,
  date_of_birth date,
  employment_date date,
  gender varchar,
  status smallint,
  category varchar,
  address varchar,
  telephone varchar
)
RETURNS void AS
$body$
DECLARE ftelephone varchar(15);
BEGIN
  --Проверки
  if (surename is null) or (surename = '') then
    RAISE EXCEPTION USING MESSAGE = 'Не заполнено поле "Фамилия"!';
  end if;
  if (name is null) or (name = '') then
    RAISE EXCEPTION USING MESSAGE = 'Не заполнено поле "Имя"!';
  end if;
  if (patronymic is null) or (patronymic = '') then
    RAISE EXCEPTION USING MESSAGE = 'Не заполнено поле "Отчество"!';
  end if;
  --Выбираем только цыфры из строки
  SELECT regexp_replace(telephone, '[^0-9]', '', 'g')
  INTO ftelephone;
  --Форматируем строку например так
  ftelephone=substr(ftelephone,1,1)||'-'||substr(ftelephone,2,3)||'-'||substr(
    ftelephone,5,3)||'-'||substr(ftelephone,8,2)||'-'||substr(ftelephone,10,2);
  --Вставляем данные в таблицу
  INSERT INTO public.drivers("surename", "name", "patronymic", "date_of_birth",
    "employment_date", "gender", "status", "category", "address", "telephone")
  VALUES (surename, name, patronymic, date_of_birth, employment_date, gender,
    status, category, address, ftelephone);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
--6.1. Выдаём права
GRANT EXECUTE ON FUNCTION public.drivers_add(surename varchar, name varchar,
patronymic varchar, date_of_birth date, employment_date date, gender varchar,
status smallint, category varchar, address varchar, telephone varchar) TO
dispatcher_role;
--7. Создаём представление, которое будет выводить точки маршрутов с информацией о маршруте, автомобиле и водителях.
/*CREATE VIEW public.route_points_view(
    route,
    object_id,
    object_type,
    object_name,
    date_plan_arrival,
    date_fact_arrival,
    drivers,
    opening_date,
    opening_status,
    route_type,
    tractor,
    user_open_route)
AS
  SELECT rp.route,
         rp.object_id,
         rp.object_type,
         rp.object_name,
         rp.date_plan_arrival,
         rp.date_fact_arrival,
         r.drivers,
         r.opening_date,
         r.opening_status,
         r.route_type,
         r.tractor,
         r.user_open_route
  FROM public.route_points rp,
       public.routes r
  where rp.route = r.guid and ???;*/
--8. Создаём структуру для хранения GPS-точек
CREATE TABLE public.gps_point (
  car VARCHAR(15) NOT NULL,
  date date NOT NULL,
  latitude NUMERIC(18,10) NOT NULL,
  longitude NUMERIC(18,10) NOT NULL,
  height NUMERIC(18,10) NOT NULL,
  speed NUMERIC(18,10) NOT NULL
)
WITH (oids = false);
--8.1 Права (права на изменение — у оператора, на просмотр — у диспетчера)
GRANT SELECT ON public.gps_point TO dispatcher_role;
GRANT INSERT, UPDATE, DELETE ON public.gps_point TO operator_role;
--9. Создаём на языке pl/python триггер для проверки корректности атрибутов
/*create extension plpython3u;*/
CREATE OR REPLACE FUNCTION public.trigger_check_gps_f (
)
RETURNS trigger AS
$body$
import datetime
if TD["new"] == TD["old"]:
 return "SKIP"
elif datetime.datetime.strptime(TD["new"]["date"], "%Y-%m-%d") > datetime.datetime.today():
 return "SKIP"
elif datetime.datetime.strptime(TD["new"]["date"], "%Y-%m-%d") < datetime.datetime.today()-datetime.timedelta(days=2):
 return "SKIP"
elif TD["new"]["latitude"] < -180 or TD["new"]["latitude"] > 180:
 return "SKIP"
elif TD["new"]["height"] < 0 or TD["new"]["height"] > 5000:
 return "SKIP"
elif TD["new"]["speed"] < 0 or TD["new"]["speed"] > 150:
 return "SKIP"
else:
 return "MODIFY";
$body$
LANGUAGE 'plpython3u'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
CREATE TRIGGER trigger_check_gps
  BEFORE INSERT OR UPDATE
  ON public.gps_point FOR EACH ROW
  EXECUTE PROCEDURE public.trigger_check_gps_f();
