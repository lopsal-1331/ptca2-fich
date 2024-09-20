-- DISPARADORES 
-- DISPARADOR 4

-- DISPARADOR PARA COMPRAS DE CLIENTES
create or replace trigger stock_update
before insert or update on client_lines
for each row 
declare 
    sold client_lines.quantity%type; 
    bar client_lines.barcode%type; 
    cur number; 
    s_min number;
    s_max number; 
    prov char(10); 
    need number; 
begin 
    -- Guardo la cantidad de producto vendido y genero mensaje
    sold := :new.quantity; 
    bar := :new.barcode;
    dbms_output.put_line('Se ha vendido: '|| sold || ' ud(s) del producto: '|| bar);

    -- Selecciono el stock actual, min y max para el barcode del pedido y lo actualizo
    select 
        cur_stock, min_stock, max_stock
    into 
        cur, s_min, s_max
    from 
        References 
    where 
        barcode = bar;
    dbms_output.put_line('Stock actual producto: '|| cur ||'. Max-Stock: '|| s_max|| '. Min-Stock: '|| s_min);

    -- Actualizo
    update references 
       set cur_stock=cur - to_number(sold)
     where barcode = bar;
    
    dbms_output.put_line('Se ha actualizado el stock del pedido.');

    -- Actualizo el nuevo valor del stock y 
    cur := cur - to_number(sold);
    dbms_output.put_line('Nuevo valor del stock: '|| cur);

    -- Buscar proveedor posible
    select 
        taxid into prov
    from 
        supply_lines 
    where 
        supply_lines.barcode = bar 
        and rownum =1
    order by cost asc;
    dbms_output.put_line('El proveedor: '|| prov || ' ofrece nuestro producto.');

    -- Cantidad que necesitariamos
    need := s_max - cur; 
    dbms_output.put_line('Se necesitan: '|| need || ' unidad/es');
    -- 
    if cur<s_min and prov is not null then
        -- En este caso podemos generar el pedido de reposicion sin problema
      dbms_output.put_line('Se ha generado un pedido de reposicion para el producto: '|| bar);
      insert into replacements (taxid, barcode, orderdate, status, units, deldate, payment)
      values (prov, bar, sysdate, 'D', need, null, 0);
    end if;
    if cur<s_min and prov is null then 
        -- Se deberia hacer pedido de reposicion pero no es posible hacerlo sin un proveedor (taxid forma parte de la pk)
        dbms_output.put_line('No se ha podido realizar pedido de reposicion. Proveedor no encontrado.');
    end if; 
end; 
/



-- Pruebas
select * from client_lines where rownum=1; 

insert into client_lines(orderdate, username, town, country, barcode, price, quantity, pay_type, pay_datetime, cardnum)
values ('01/05/23', 'luis2', 'Val de la Alameda', 'Belize', 'OIO25319I806865', 0.5, 5, 'COD', '02/05/2023', null);


update client_lines
set 
    quantity = 10, 
    barcode = 'OIO25319I806865'
where 
    trunc(orderdate) = '01/05/23' and username = 'naki' and town = 'Val de la Alameda' and country='Belize';



-- DISPARADOR PARA COMPRAS DE CLIENTES ANONIMOS
create or replace trigger stock_update_anonym
before insert or update on lines_anonym
for each row 
declare 
    sold lines_anonym.quantity%type; 
    bar lines_anonym.barcode%type; 
    cur number; 
    s_min number;
    s_max number; 
    prov char; 
    need number; 
begin 
    -- Guardo la cantidad de producto vendido y genero mensaje
    sold := :new.quantity; 
    bar := :new.barcode;
    dbms_output.put_line('Se ha vendido: '|| sold || ' ud(s) del producto: '|| bar);

    -- Selecciono el stock actual, min y max para el barcode del pedido y lo actualizo
    select 
        cur_stock, min_stock, max_stock
    into 
        cur, s_min, s_max
    from 
        References 
    where 
        barcode = bar;
    dbms_output.put_line('Stock actual producto: '|| cur ||'. Max-Stock: '|| s_max|| '. Min-Stock: '|| s_min);

    -- Actualizo
    update references
       set cur_stock=cur - sold
     where barcode = bar;

    -- Actualizo el nuevo valor del stock y 
    cur := cur - sold;

    -- Buscar proveedor posible
    select 
        taxid into prov
    from 
        supply_lines 
    where 
        supply_lines.barcode = bar 
        and rownum =1
    order by cost asc;
    
    -- Cantidad que necesitariamos
    need := s_max - cur; 
    -- 
    if cur<s_min and prov is not null then
        -- En este caso podemos generar el pedido de reposicion sin problema
      dbms_output.put_line('Se ha generado un pedido de reposicion para el producto: '|| bar);
      insert into replacements (taxid, barcode, orderdate, status, units, deldate, payment)
      values (prov, bar, sysdate, 'D', need, null, 0);
    end if;
    if cur<s_min and prov is null then 
        -- Se deberia hacer pedido de reposicion pero no es posible hacerlo sin un proveedor (taxid forma parte de la pk)
        dbms_output.put_line('No se ha podido realizar pedido de reposicion. Proveedor no encontrado.');
    end if; 
end; 
/

-- Pruebas 
