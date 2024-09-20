-- PAQUETE para el manejo del usuario actual
create or replace package user_settings as
  procedure set_current_user(p_username in varchar2);
  function get_current_user return varchar2;
end user_settings;
/

create or replace package body user_settings as
  current_user_var varchar2(100);
  -- Establece usuario del sistema
  procedure set_current_user(p_username in varchar2) is
  begin
    current_user_var := p_username;
  end set_current_user;
  -- Funcion que nos devuelve el usuario actual
  function get_current_user return varchar2 is
  begin
    return current_user_var;
  end get_current_user;
end user_settings;
/

-- Establezco usuario
begin
  user_settings.set_current_user('luis2'); 
end; 
/

-- VISTA 1 : MIS_COMPRAS
create or replace view mis_compras as
select * 
from orders_clients
-- Imponemos que el usuario debe ser el que se haya establecido como actual en el sistema
where username = user_settings.get_current_user; 

-- VISTA 2 : MI_PERFIL
create or replace view mi_perfil as 
select 
    clients.username as usuario, 
    clients.reg_datetime as fecha_registor, 
    clients.user_passw as contraseña, 
    clients.name as nombre, 
    clients.surn1 as apellido1, 
    clients.surn2 as apellido2,
    clients.email as email, 
    clients.mobile as telefono, 
    clients.preference as preferencia, 
    clients.voucher as voucher, 
    clients.voucher_exp as voucher_exp,
    client_addresses.waytype, 
    client_addresses.wayname, 
    client_addresses.gate, 
    client_addresses.block, 
    client_addresses.stairw, 
    client_addresses.floor, 
    client_addresses.door, 
    client_addresses.zip,
    client_addresses.town, 
    client_addresses.country, 
    client_cards.cardnum as tarjeta_credito, 
    client_cards.card_comp, 
    client_cards.card_holder, 
    client_cards.card_expir 
from 
    clients
join 
    client_addresses ON clients.username = client_addresses.username
join 
    client_cards ON clients.username = client_cards.username
where 
    clients.username = user_settings.get_current_user;


-- VISTA 3 : MIS COMENTARIOS
create or replace view mis_comentarios as
select 
  *
from posts
where username = user_settings.get_current_user; 


-- Para la vista anterior se va a crear un paquete que permite insertar, eliminar y actualizar comentarios
create or replace package mis_comentarios_ops as 
  -- insertar un nuevo comentario
  procedure insertar_comentario(ref varchar2, punt number, text varchar2, bar char, title varchar2); 
  -- eliminar comentario is likes = 0
  procedure eliminar_comentario(fecha date); 
  -- actualizar texto de un comentario
  procedure actualizar_comentario(fecha date, texto varchar2, punt number); 
end mis_comentarios_ops; 
/

create or replace package body mis_comentarios_ops as
  -- Procedimiento para insertar el nuevo comentairio
  procedure insertar_comentario(ref varchar2, punt number, text varchar2, bar char, title varchar2) is 
    usr varchar2(30); 
  begin 
    usr := user_settings.get_current_user; 
    insert into posts (username, postdate, barcode, product, score, title, text, likes, endorsed)
    values (usr, current_date, bar, ref, punt, title, text, 0, null);
  end insertar_comentario; 

  procedure eliminar_comentario(fecha date) is 
    usr varchar2(30); 
  begin 
    usr := user_settings.get_current_user; 
    delete from posts 
    where username = usr and trunc(postdate) = trunc(fecha)
    and likes=0; 
  end eliminar_comentario; 

  procedure actualizar_comentario(fecha date, texto varchar2, punt number) is 
    usr varchar2(30); 
  begin 
    usr := user_settings.get_current_user; 
    update posts
      set text = texto, score = punt 
      where username = usr and trunc(postdate) = trunc(fecha) and likes = 0; 
  end actualizar_comentario; 
end mis_comentarios_ops; 
/

-- PRUEBAS
begin 
  mis_comentarios_ops.insertar_comentario('Paisajes y cantar', 4, 'Me ha gustado mucho. Volveria a comprar', null, null); 
end; 
/

begin 
  mis_comentarios_ops.actualizar_comentario(current_date, 'Despues de una semana se ha puesto rancio.', 1); 
end; 
/

begin 
  mis_comentarios_ops.eliminar_comentario(current_date);
end; 
/