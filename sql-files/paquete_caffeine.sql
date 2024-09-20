create or replace package caffeine as 
    procedure set_replacement_orders;
    procedure prov_report(
      prov in varchar2
    );
end caffeine; 
/

create or replace package body caffeine as
    -- PROCEDIMIENTO 1
    procedure set_replacement_orders is
        v_cost number(12,2);
    begin
        -- Paso 1: Obtengo todas las filas en estado 'D' (borrador)
        for draft in (
            select * from replacements where status = 'D'
        ) loop
          -- Paso 2: verificamos si hay coincidencias en supply_lines para el tax_id y barcode
            select 
                cost into v_cost 
            from 
                supply_lines
            where  
                supply_lines.taxid = draft.taxid 
                and 
                supply_lines.barcode = draft.barcode; 
            -- Si existe un coste (el proveedor tiene una oferta para ese barcode)
            if v_cost is not null then 
                update replacements 
                set status='P',
                payment = v_cost * draft.units; 
                dbms_output.put_line('Replacement order confirmed for: '|| draft.taxid ||' in the date: ' || draft.orderdate || ' of the product: ' || draft.barcode);
            end if;
        end loop;
    exception
        when no_data_found then
            dbms_output.put_line('No offer found.');
    end set_replacement_orders;

    -- PROCEDIMIENTO 2
    procedure prov_report(
      prov in varchar2
    ) is
        num_orders number(10);
        avg_days number(10);
        avg_cost number(15,2);
        min_cost number(15,2);
        max_cost number(15,2);
        best_offer number(15,2);
        cur_ref varchar2(50);
    begin
        select count(*) into num_orders from replacements 
        where status = 'P' or status = 'F' and orderdate >= add_months(sysdate, -12)
        and taxid = prov;

        select avg(deldate-orderdate) into avg_days from replacements where taxid = prov and 
        orderdate >=add_months(current_date, -12) and status = 'F'; 
        
        dbms_output.put_line('Informe para: '|| prov);
        dbms_output.put_line('Total orders this year: '|| num_orders);
        dbms_output.put_line('Tiempo medio de entrega en días: '|| avg_days);

       for ref in (
            select 
                avg(cost) as avg_cost, 
                min(cost) as min_cost,
                max(cost) as max_cost, 
                references.product as curref
            from supply_lines join references on supply_lines.barcode = references.barcode 
            where supply_lines.taxid = prov 
            group by references.product 
        ) loop
            avg_cost := ref.avg_cost; 
            min_cost := ref.min_cost; 
            max_cost := ref.max_cost; 
            cur_ref := ref.curref; 

            select cost into best_offer
            from (
                select cost 
                from supply_lines 
                join references on supply_lines.barcode = references.barcode 
                where references.product = ref.curref
                order by cost asc
            )
            where rownum = 1; 

            dbms_output.put_line('Reference: '|| cur_ref); 
            dbms_output.put_line('Average cost: '|| avg_cost); 
            dbms_output.put_line('Min cost: '|| min_cost); 
            dbms_output.put_line('Max cost: '|| min_cost);
            dbms_output.put_line('Best offer: '|| best_offer);

        end loop;

    end prov_report;
end caffeine; 
/


-- INSERT INTO Replacements (taxID, barCode, orderdate, status, units, deldate, payment)
-- no data
-- Inserts para la comprobación de datos
insert into Replacements (taxID, barCode, orderdate, status, units, deldate, payment)
values ('K10665016P', 'QQO10649Q369834', TO_DATE('2024-04-03', 'YYYY-MM-DD'), 'D', 4, NULL, 0);

-- Inicializo mi paquete 
BEGIN
    caffeine.set_replacement_orders;
END;
/

select * from supply_lines where taxid = 'K10665016P'; 

-- INSERT INTO REPLACEMENTS AND SUPPLY ORDERS 
insert into replacements (taxID, barCode, orderdate, status, units, deldate, payment)
values ('K10665016P', 'QQO10649Q369834', TO_DATE('2024-05-03', 'YYYY-MM-DD'), 'F', 4, TO_DATE('2024-05-15', 'YYYY-MM-DD'), 0);

insert into replacements (taxID, barCode, orderdate, status, units, deldate, payment)
values ('K10665016P', 'OQQ87941O509260', TO_DATE('2024-05-03', 'YYYY-MM-DD'), 'F', 4, TO_DATE('2024-05-23', 'YYYY-MM-DD'), 0);

insert into replacements (taxID, barCode, orderdate, status, units, deldate, payment)
values ('K10665016P', 'OQO15967O320195', TO_DATE('2024-05-03', 'YYYY-MM-DD'), 'F', 4, TO_DATE('2024-05-205', 'YYYY-MM-DD'), 0);

begin 
    caffeine.prov_report('K10665016P')
end; 
/