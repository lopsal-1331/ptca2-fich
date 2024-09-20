-- DISPARADORES
-- DISPARADOR 1
create or replace trigger endorsed_check
before insert or update on posts
for each row 
declare 
    bar posts.barcode%type; 
    ref posts.product%type;
    usr posts.username%type; 
    num_products number; 
begin 
    -- obtenemos los valores de las columnas de la fila insertada o actualizada
    bar := :new.barcode; 
    ref := :new.product; 
    usr := :new.username; 

    -- verificamos si ha realizado algún pedido con el barcode o el producto
    if bar is null then
        -- buscamos en client_lines si ha relaizado pedidos para la referencia
        select
            count(*) into num_products
        from 
            client_lines
            join references on client_lines.barcode = references.barcode
        where
            client_lines.username = usr
            and 
            references.product = ref; 
    else 
        -- buscamos si se han realizado pedidos con el barcode o el producto
        select
            count(*) into num_products 
        from
            client_lines 
            join references on client_lines.barcode = references.barcode 
        where
            client_lines.username = usr
            and 
            (client_lines.barcode = bar or references.product = ref);
    end if; 

    -- actualizamos el atributo 'endorsed' segun corresponda
    if num_products > 0 then
        :new.endorsed := sysdate; 
    else 
        :new.endorsed := null; 
    end if; 
end; 
/

-- PRUEBAS
-- Insertamos en post
insert into posts (username, postdate, barcode, product, score, title, text, likes, endorsed)
values ('naki', '05/04/2024', 'OIO25319I806865', 'Pena de venus', 3, 'Mediocre', 'Sin comentarios', 300, null);