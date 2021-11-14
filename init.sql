-- Установим расширение, нужное для UUID
create extension "uuid-ossp";

-- Создадим enum валют
create type t_currency as enum ('RUR','EUR','USD');

-- Создадим партиционированную таблицу
create table bills(
    id bigserial, -- автоинкрементный id
    uid uuid default uuid_generate_v4(), -- автогенерируемый uuid вида de5d09be-acfe-42f1-940c-f90db3c43a31
    create_dtime timestamptz default now(), -- дата счета, по ней партиционируем
    amount float8 not null, -- сумма счета
    currency t_currency not null, -- валюта счета, тип enum
    merchant_payload jsonb -- неструктурированный json от продавца
);

-- Ограничения уникальности должны включать ключ партиционирования, чтобы обеспечить сквозную уникальность для всех партиций
-- Добавим первичный ключ
alter table bills add primary key (id, create_dtime);
-- Добавим ограничение уникальности uid
create unique index on bills(uid, create_dtime);

create index on bills(currency);

-- Заполним таблицу данными для RUR
insert into bills(create_dtime, amount, currency, merchant_payload)
select generate_series as timestamp, 100, 'RUR', ('{"orderId": "123"}')::jsonb
from generate_series('2021-01-01', '2021-12-31', interval '1 hour');

-- Заполним таблицу данными для USD
insert into bills(create_dtime, amount, currency, merchant_payload)
select generate_series as timestamp, 100, 'USD', ('{"orderId": "123"}')::jsonb
from generate_series('2021-01-01', '2021-12-31', interval '1 hour');

-- Заполним таблицу данными для EUR
insert into bills(create_dtime, amount, currency, merchant_payload)
select generate_series as timestamp, 100, 'EUR', ('{"orderId": "123"}')::jsonb
from generate_series('2021-01-01', '2021-12-31', interval '1 hour');

-- Соберем статистику после заполнения таблицы, чтобы планировщик строил корректные планы. Обычно вам это не нужно.
analyze bills;
