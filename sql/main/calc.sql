--удаление таблицы
DROP TABLE IF EXISTS results;

--создание таблицы
create table results (id int, response text);
---1.	Вывести максимальное количество человек в одном бронировании

insert into results
with count_passenger as (
select a.book_ref, count(distinct passenger_id) cnt_passenger
from bookings a 
join tickets b on a.book_ref =b.book_ref
group by a.book_ref
)
select 1 id , max(cnt_passenger) response
from count_passenger;
 
---2.	Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование
insert into results
with count_passenger as (
select a.book_ref, count(distinct passenger_id) cnt_passenger
from bookings a 
join tickets b on a.book_ref =b.book_ref
group by a.book_ref),
avg_count_passenger as(
select book_ref, cnt_passenger, round(avg(cnt_passenger) over()) avg_count_passenger
from count_passenger
)
select 2 id, count(distinct book_ref) response
from avg_count_passenger
where cnt_passenger>avg_count_passenger;

--3.	Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза, 
---среди бронирований с максимальным количеством людей (п.1)?
insert into results
select 3 id, coalesce  (
(
with count_passenger as (
select a.book_ref, passenger_id, count(passenger_id) over(partition by a.book_ref) cnt_passenger
from bookings a 
join tickets b on a.book_ref =b.book_ref),
max_count_passenger as(
select book_ref, passenger_id, cnt_passenger, max(cnt_passenger) over() max_count_passenger
from count_passenger),
passenger_list as (
select book_ref, string_agg(c.passenger_id,',') passenger_list
from max_count_passenger c
where max_count_passenger=cnt_passenger
GROUP BY book_ref
ORDER BY book_ref),
cnt_book_ref_table as (
select  passenger_list,count(distinct book_ref) cnt_book_ref
from passenger_list
group by passenger_list
)
select cnt_book_ref
from cnt_book_ref_table a 
where cnt_book_ref>1), 0) response;


--4.	Вывести номера брони и контактную информацию по пассажирам в брони (passenger_id, passenger_name, contact_data) 
--с количеством людей в брони = 3
insert into results
with count_passenger as (
select a.book_ref, passenger_id, passenger_name, contact_data, count(passenger_id) over(partition by a.book_ref) cnt_passenger
from bookings a 
join tickets b on a.book_ref =b.book_ref
order by a.book_ref, passenger_id, passenger_name, contact_data),
table_concat as (
select book_ref,concat(passenger_id,'|', passenger_name,'|', contact_data) passenger_info
from count_passenger
where cnt_passenger=3
order by book_ref, passenger_info),
union_passengers as (
select book_ref, string_agg(passenger_info,'|') passengers
from table_concat
group by book_ref
order by book_ref, passengers
)
select 4 id, concat(book_ref,'|', passengers) response
from union_passengers;


---5.	Вывести максимальное количество перелётов на бронь
insert into results
with count_flight_id as (
select b.book_ref, count(flight_id) cnt_flight_id
from ticket_flights a
join tickets b on a.ticket_no =b.ticket_no 
group by b.book_ref 
)
select 5 id, max(cnt_flight_id)response
from count_flight_id;


--6.	Вывести максимальное количество перелётов на пассажира в одной брони
insert into results
with count_flight_id as (
select b.book_ref, b.passenger_id, count( flight_id) cnt_flight_id
from ticket_flights a
join tickets b on a.ticket_no =b.ticket_no 
group by b.book_ref, b.passenger_id
)
select 6 id, max(cnt_flight_id)response
from count_flight_id;

--7.	Вывести максимальное количество перелётов на пассажира
insert into results
with count_flight_id as (
select b.passenger_id, count(flight_id) cnt_flight_id
from ticket_flights a
join tickets b on a.ticket_no =b.ticket_no 
group by b.book_ref, b.passenger_id
)
select 7 id, max(cnt_flight_id) response
from count_flight_id;


--8.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) 
--и общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты
insert into results
with table_sum_amount as (
select passenger_id, passenger_name, contact_data, sum(amount) sum_amount
from ticket_flights a
join tickets b on a.ticket_no =b.ticket_no 
group by passenger_id, passenger_name, contact_data
),
table_min_sum_amount as (
select passenger_id, passenger_name, contact_data, sum_amount, min(sum_amount) over() min_sum_amount
from table_sum_amount
order by passenger_id, passenger_name, contact_data, sum_amount
)
select 8 id, concat(passenger_id,'|', passenger_name,'|', contact_data,'|', sum_amount)response
from table_min_sum_amount
where sum_amount=min_sum_amount
order by id, response;

--9.	Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общее время в полётах,
--для пассажира, который провёл максимальное время в полётах
insert into results
with flight_duration as (
  select 
    t.passenger_id ,
    sum(fv.actual_duration) as flight_dur
  from flights_v fv  
  join ticket_flights tf 
    on fv.flight_id = tf.flight_id 
  join tickets t 
    on t.ticket_no = tf.ticket_no 
  group by t.passenger_id 
  )
select 
  9 as id, 
    concat_ws('|',fd.passenger_id, t.passenger_name, t.contact_data, fd.flight_dur) as response 
from flight_duration fd
join tickets t 
  on fd.passenger_id = t.passenger_id
where fd.flight_dur = (select max(flight_dur) from flight_duration)
order by fd.passenger_id, t.passenger_name, t.contact_data, fd.flight_dur;


--10.	Вывести город(а) с количеством аэропортов больше одного
insert into results
select 10 id ,city response
from (
select city, count(distinct airport_code) cnt_airport_code
from airports a 
group by city
having count(distinct airport_code)>1) a
order by city;
 
--11.	Вывести город(а), у которого самое меньшее количество городов прямого сообщения
insert into results
with all_flights as  
  (
  select distinct 
    departure_airport as airp1,
    arrival_airport as airp2
  from flights f 
  union 
  select distinct 
    arrival_airport as airp1,
    departure_airport as airp2
  from flights f 
  order by 1,2
  ) , 
t2 as (
  select 
    a.city, 
    count(a.city) as city_cnt
  from all_flights af
  left join airports a 
    on a.airport_code = af.airp1
  group by a.city
  ) 
select 
  11 as id, 
  city as response
from t2
where city_cnt = (select min(city_cnt) from t2);


--12.	Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты
insert into results
with table_city as (
  select distinct departure_city, arrival_city
  from routes)
select 12 id, concat(dc, '|', ac) response
from(
  select t1.departure_city dc, t2.arrival_city ac
  from table_city t1, table_city t2
  where t1.departure_city < t2.arrival_city
  except
  select * from table_city) t
order by dc, ac;

--13.	Вывести города, до которых нельзя добраться без пересадок из Москвы?
insert into results
select 13 id, departure_city response
from routes
where departure_city != 'Москва' 
and departure_city not in (
    select arrival_city from routes 
    where departure_city = 'Москва');

---14.	Вывести модель самолета, который выполнил больше всего рейсов
insert into results
with table_count_flight_id as (
select model, count(flight_id) count_flight_id
from aircrafts a 
join flights b on a.aircraft_code=b.aircraft_code
group by model
), 
table_max_count_flight_id as(
select model, count_flight_id, max(count_flight_id) over() max_count_flight_id
from table_count_flight_id)
select 14 id, model response
from table_max_count_flight_id
where max_count_flight_id=count_flight_id;


--15.	Вывести модель самолета, который перевез больше всего пассажиров
insert into results
with table_passenger_id as (
select model, count(passenger_id) count_passenger_id
from aircrafts a 
join flights b on a.aircraft_code=b.aircraft_code
join ticket_flights c on c.flight_id=b.flight_id
join tickets d on d.ticket_no=c.ticket_no
group by model
), 
table_max_count_passenger_id as(
select model, count_passenger_id, max(count_passenger_id) over() max_count_passenger_id
from table_passenger_id)
select 15 id, model response
from table_max_count_passenger_id
where max_count_passenger_id=count_passenger_id;

--16.	Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам
insert into results
SELECT 16 id, abs(extract(epoch from sum(scheduled_duration) - sum(actual_duration)) / 60)::int response
FROM bookings.flights_v
WHERE status = 'Arrived';


--17.	Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13
insert into results
select 17 id, arrival_city response 
from flights_v f 
where departure_city = 'Санкт-Петербург'
and date_trunc('day',actual_departure_local) = '2016-09-13'
order by 1,2;


--18.	Вывести перелёт(ы) с максимальной стоимостью всех билетов
insert into results
select 18 id,  flight_id response
from
  (select flight_id, 
  		sum(amount) sum_amount,
  		max(sum(amount)) over() max_sum_amount
  from ticket_flights tf
  group by flight_id) t
where sum_amount = max_sum_amount
order by flight_id;


---19.	Выбрать дни в которых было осуществлено минимальное количество перелётов
insert into results
select 19 id, date_departure response
from
  (select actual_departure::date date_departure, 
  			count(flight_id) count_flight, 
  			min(count(flight_id)) over() min_count_flight 
  from flights f 
  where actual_departure is not null
  group by actual_departure::date) t
where count_flight = min_count_flight
order by date_departure; 

---20.	Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года
insert into results
select 20 id, avg(count_flights) response
from 
  (select count(flight_id) count_flights
  from flights 
  where actual_departure is not null and date_trunc('month', actual_departure) = '2016-09-01' 
  group by actual_departure::date) t;
 
---21.	Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов
insert into results
with table_avg_duration as (
  select distinct departure_city,avg(actual_duration) over(partition by departure_city) avg_duration 
  from flights_v
  where status='Arrived'
  order by avg_duration desc 
  limit 5
  )
---insert into results
select 21 id,departure_city response
from table_avg_duration 
where extract(epoch from avg_duration)/3600>3
order by departure_city   
limit 5;

select distinct id
from results;
