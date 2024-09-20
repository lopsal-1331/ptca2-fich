-- BUSINESS WAY OF LIFE
-- Como en la anterior consulta, creamos una vista agrupando todos los datos que 
-- necesitamos para realizar la consulta.

create or replace view bwol as 
select 
    fecha, 
    referencia, 
    quantity, 
    total_ing, 
    cost
from (
    select 
        lines_anonym.orderdate as fecha, 
        references.product as referencia, 
        sum(lines_anonym.quantity) as quantity, 
        sum(lines_anonym.price * lines_anonym.quantity) as total_ing, 
        avg(supply_lines.cost) as cost 
    from 
        lines_anonym
        join supply_lines on lines_anonym.barcode = supply_lines.barcode
        join references on lines_anonym.barcode = references.barcode
    group by 
        lines_anonym.orderdate, references.product
    union
    select 
        client_lines.orderdate as fecha, 
        references.product as referencia, 
        sum(to_number(client_lines.quantity)) as quantity, 
        sum(to_number(client_lines.quantity) * client_lines.price) as total_ing, 
        avg(supply_lines.cost) as cost 
    from 
        client_lines
        join supply_lines on client_lines.barcode = supply_lines.barcode
        join references on client_lines.barcode = references.barcode
    group by
        client_lines.orderdate, references.product
)
where fecha >= add_months(current_date, -12);

-- Realizo la consulta principal

with MonthlyReport as (
    select 
        to_char(fecha, 'YYYY-MM') as month, 
        referencia, 
        sum(quantity) as total_uds, 
        count(*) as total_orders, 
        sum(total_ing) as tot_ing, 
        sum(total_ing - cost * quantity) as beneficio 
    from bwol 
    group by 
        fecha, referencia
)
select 
    month, 
    referencia as mejor_referencia, 
    total_orders, 
    total_uds, 
    tot_ing, 
    beneficio 
from (
    select 
        month, 
        referencia, 
        total_orders, 
        total_uds, 
        tot_ing, 
        beneficio, 
        row_number() over (partition by month order by total_uds) as rn 
    from monthlyReport
)
where rn = 1; 