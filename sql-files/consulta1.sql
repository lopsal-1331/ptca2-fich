-- CONSULTA 1 : Bestsellers Geographic Report
-- Creo una vista donde agrupo y selecciono todas las ordenes tanto anonimas como de clientes
-- Solo incluyo los datos necesatios para realizar el reporte

create or replace view orders AS
select 
    orderdate, 
    country, 
    barcode, 
    price, 
    quantity, 
    varietal, 
    reference
from (
    select 
        lines_anonym.orderdate as orderdate, 
        lines_anonym.dliv_country as country, 
        lines_anonym.barcode as barcode, 
        lines_anonym.price as price, 
        lines_anonym.quantity as quantity, 
        products.varietal as varietal, 
        references.product as reference 
    from 
        lines_anonym
        join references on lines_anonym.barcode = references.barcode
        join products on references.product = products.product
    where 
        lines_anonym.orderdate >= add_months(current_date, -12)
    union
    select 
        client_lines.orderdate as orderdate, 
        client_lines.country as country, 
        client_lines.barcode as barcode, 
        client_lines.price as price, 
        to_number(client_lines.quantity) as quantity, 
        products.varietal as varietal, 
        references.product as reference 
    from 
        client_lines
        join references on client_lines.barcode = references.barcode 
        join products on references.product = products.product 
    where
        client_lines.orderdate >= add_months(current_date, -12)
); 

-- Realizarmos la consulta principal
select 
    country, 
    varietal, 
    total_ventas, 
    total_ingreso, 
    avg_unidades_referencia, 
    num_paises_consumidores_potenciales
from (
    select 
        country, 
        varietal, 
        count(*) as total_ventas, 
        sum(quantity * price ) as total_ingreso, 
        avg(quantity) as avg_unidades_referencia, 
        row_number() over (partition by country order by count(*) desc) as ranking_variedad, 
        count(distinct country) over (partition by varietal) as num_paises_consumidores_potenciales
    from orders
    group by country, varietal
) ventas_por_variedad
where ranking_variedad = 1
and num_paises_consumidores_potenciales > 0.01 * (
    select sum(total_ventas)
    from (
        select 
            varietal, 
            sum(quantity) as total_ventas
        from orders
        group by varietal
    ) ventas_por_variedad_total
    where ventas_por_variedad_total.varietal = ventas_por_variedad.varietal
);