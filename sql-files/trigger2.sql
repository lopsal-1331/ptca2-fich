-- DISPARADORES
-- DISPARADOR 2
-- Crear la vista deleted_posts
-- Actualizar la vista deleted_posts
-- Paso 1: Crear una tabla adicional para almacenar las filas eliminadas
create or replace able deleted_posts_queue (
    postdate date,
    barcode char(15),
    product varchar2(50),
    score number(1),
    title varchar2(50),
    text varchar2(2000),
    likes number(9),
    endorsed date
);

-- Paso 2: Crear un trigger BEFORE DELETE en la tabla original para insertar filas eliminadas en la tabla adicional
create or replace trigger after_delete_posts_trigger
before delete on posts
for each row
begin
    insert into deleted_posts_queue (postdate, barcode, product, score, title, text, likes, endorsed)
    values (:old.postdate, :old.barcode, :old.product, :old.score, :old.title, :old.text, :old.likes, :old.endorsed);
end;
/

-- PROCEDIMIENTO PARA HACER LA INSERCION DE LOS DATOS EN LA TABLA DE PUBLICACIONES ANÓNIMAS
create or replace procedure insert_into_anonyposts is
    row_count number;
begin
    for delpost in (select * from deleted_posts_queue) loop
        -- Verificamos si ya hay una fila en anonyposts con la misma fecha de publicacion
        select 
            count(*) into row_count
        from 
            anonyposts
        where postdate = delpost.postdate;

        if row_count > 0 then
          update deleted_posts_queue
          set postdate = current_date
          where postdate = delpost.postdate; 
          insert into anonyposts (postdate, barcode, product, score, title, text, likes, endorsed)
                values (delpost.postdate, delpost.barcode, delpost.product,
                        delpost.score, delpost.title, delpost.text,
                        delpost.likes, delpost.endorsed);
            dbms_output.put_line('Se Ha pasado una publicacion a formato anónimo con fecha modificada: '|| delpost.postdate);
        else 
            insert into anonyposts (postdate, barcode, product, score, title, text, likes, endorsed)
                values (delpost.postdate, delpost.barcode, delpost.product,
                        delpost.score, delpost.title, delpost.text,
                        delpost.likes, delpost.endorsed);
            dbms_output.put_line('Se Ha pasado una publicacion a formato anónimo con fecha: '|| delpost.postdate);
        end if;
    end loop;
    dbms_output.put_line('Todas las publicaciones recientemente eliminadas han sido pasadas a formato anonimo.');
    delete from deleted_posts_queue; -- Corrección aquí: quitamos el asterisco después de 'delete'
end insert_into_anonyposts;
/

-- activar el procedimiento
begin
    insert_into_anonyposts;
end;
/

