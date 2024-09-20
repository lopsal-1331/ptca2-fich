-- DISPARADORES
-- DISPARADOR 3
create or replace trigger block_anonym_post
before insert on lines_anonym
for each row
declare 
    card lines_anonym.card_num%type; 
    usr client_cards.username%type; 
begin 
    card := :new.card_num; 
    -- Verificar si la tarjeta está registrada para algún usuario
    select username into usr
    from client_cards
    where cardnum = card;

    if usr is not null then
        raise_application_error(-20001, 'esta tarjeta ya esta registrada por un usuario.');
    end if;
end;
/


-- Pruebas
select cardnum from client_cards where rownum<2; 
-- 1396414232
insert into lines_anonym (orderdate, contact, dliv_town, dliv_country, barcode, price, quantity, pay_type, pay_datetime, card_comp, card_num, card_holder, card_expir) 
values ('07/04/2024', 'manuela@gmail.com', 'Madrid', 'España', '946010000000', 12, 3, 'credit card', '25/09/16', 'Andorran Stress', 1396414232, 'Wilburga Plaza', '01/10/24');



