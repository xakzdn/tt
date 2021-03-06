--Триггеры
/*DROP TRIGGER trigger_bi_routes ON public.routes;*/
DROP TRIGGER trigger_check_gps ON public.gps_point;
--Процедуры и функции
/*DROP FUNCTION public.trigger_bi_routes_f();*/
DROP FUNCTION public.trigger_check_gps_f();
DROP FUNCTION public.drivers_add(surename varchar, name varchar, patronymic varchar, date_of_birth date, employment_date date, gender varchar, status smallint, category varchar, address varchar, telephone varchar);
--Права
REVOKE SELECT, INSERT, UPDATE ON public.cars FROM dispatcher_role, operator_role;
REVOKE SELECT, INSERT, UPDATE ON public.drivers FROM dispatcher_role, operator_role;
REVOKE SELECT, INSERT, UPDATE ON public.routes FROM dispatcher_role, operator_role;
REVOKE SELECT, INSERT, UPDATE ON public.route_points FROM dispatcher_role, operator_role;
REVOKE SELECT ON public.gps_point FROM dispatcher_role;
REVOKE INSERT, UPDATE, DELETE ON public.gps_point FROM operator_role;
--Таблицы
DROP TABLE public.cars;
DROP TABLE public.drivers;
DROP TABLE public.routes;
DROP TABLE public.route_points;
DROP TABLE public.gps_point;
---Роли
DROP ROLE dispatcher_role;
DROP ROLE operator_role;
DROP ROLE "IvanovIV";
DROP ROLE "KozlovVA";
DROP ROLE "PetrovPE";
DROP ROLE "SokolovAA";