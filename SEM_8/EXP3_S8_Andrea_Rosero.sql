-- 1. Creación del Trigger
CREATE OR REPLACE TRIGGER trg_sincroniza_consumos
AFTER INSERT OR UPDATE OR DELETE ON consumo
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Si se inserta, sumamos el monto al total del huésped. 
        -- Usamos UPDATE y si no existe el registro, lo creamos con un INSERT.
        UPDATE total_consumos 
        SET monto_consumos = monto_consumos + :NEW.monto 
        WHERE id_huesped = :NEW.id_huesped;
        
        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO total_consumos (id_huesped, monto_consumos) 
            VALUES (:NEW.id_huesped, :NEW.monto);
        END IF;
        
    ELSIF UPDATING THEN
        -- Si se actualiza, restamos el monto antiguo y sumamos el nuevo
        UPDATE total_consumos 
        SET monto_consumos = monto_consumos - :OLD.monto + :NEW.monto 
        WHERE id_huesped = :NEW.id_huesped;
        
    ELSIF DELETING THEN
        -- Si se elimina, restamos el monto del registro borrado
        UPDATE total_consumos 
        SET monto_consumos = monto_consumos - :OLD.monto 
        WHERE id_huesped = :OLD.id_huesped;
    END IF;
END;
/

-- 2. Bloque Anónimo para validar el Trigger (Pruebas solicitadas)
BEGIN
    -- Prueba a: Inserta un nuevo consumo (monto 150)
    -- Nota: Uso una ID ficticia alta (99999) asumiendo que es la "siguiente" libre
    INSERT INTO consumo (id_consumo, id_reserva, id_huesped, monto) 
    VALUES (99999, 1587, 340006, 150);
    
    -- Prueba b: Elimina el consumo con ID 11473
    DELETE FROM consumo WHERE id_consumo = 11473;
    
    -- Prueba c: Actualiza a US$ 95 el monto del consumo con ID 10688
    UPDATE consumo SET monto = 95 WHERE id_consumo = 10688;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Pruebas del trigger ejecutadas correctamente.');
END;
/




-------------------------------------------------------------------------------------

-- Especificación del Package
CREATE OR REPLACE PACKAGE pkg_hotel IS
    FUNCTION fn_calc_tours(p_id_huesped NUMBER) RETURN NUMBER;
END pkg_hotel;
/

-- Cuerpo del Package
CREATE OR REPLACE PACKAGE BODY pkg_hotel IS
    FUNCTION fn_calc_tours(p_id_huesped NUMBER) RETURN NUMBER IS
        v_total_tours_usd NUMBER := 0;
    BEGIN
        -- Multiplicamos el valor del tour por el número de personas que asistieron
        SELECT NVL(SUM(t.valor_tour * ht.num_personas), 0)
        INTO v_total_tours_usd
        FROM huesped_tour ht
        JOIN tour t ON ht.id_tour = t.id_tour
        WHERE ht.id_huesped = p_id_huesped;

        RETURN v_total_tours_usd;
    EXCEPTION
        WHEN OTHERS THEN 
            RETURN 0; -- Retorna 0 si hay cualquier error o no tomó tours
    END fn_calc_tours;
END pkg_hotel;
/


------------------------------------------------------------------------------------


-- Función para obtener la Agencia
CREATE OR REPLACE FUNCTION fn_get_agencia(p_id_huesped NUMBER) RETURN VARCHAR2 IS
    PRAGMA AUTONOMOUS_TRANSACTION; 
    v_nom_agencia VARCHAR2(100);
    v_mensaje_error VARCHAR2(300); -- Variable extra para capturar el error
BEGIN
    SELECT a.nom_agencia
    INTO v_nom_agencia
    FROM huesped h
    JOIN agencia a ON h.id_agencia = a.id_agencia
    WHERE h.id_huesped = p_id_huesped;

    RETURN v_nom_agencia;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Guardamos el error en la variable limitando a 300 caracteres
        v_mensaje_error := SUBSTR(SQLERRM, 1, 300); 
        
        INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
        VALUES (sq_error.NEXTVAL, 'Error en la función FN_AGENCIA al recuperar la agencia del huesped con id ' || p_id_huesped, v_mensaje_error);
        COMMIT;
        RETURN 'NO REGISTRA AGENCIA';
        
    WHEN OTHERS THEN
        -- Guardamos el error en la variable limitando a 300 caracteres
        v_mensaje_error := SUBSTR(SQLERRM, 1, 300); 
        
        INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
        VALUES (sq_error.NEXTVAL, 'Error inesperado en FN_AGENCIA', v_mensaje_error);
        COMMIT;
        RETURN 'NO REGISTRA AGENCIA';
END fn_get_agencia;
/



-- Función para obtener los Consumos
CREATE OR REPLACE FUNCTION fn_get_consumos(p_id_huesped NUMBER) RETURN NUMBER IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_total_consumos NUMBER := 0;
    v_mensaje_error VARCHAR2(300); -- Variable extra para capturar el error
BEGIN
    SELECT monto_consumos
    INTO v_total_consumos
    FROM total_consumos
    WHERE id_huesped = p_id_huesped;

    RETURN v_total_consumos;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Guardamos el error en la variable limitando a 300 caracteres
        v_mensaje_error := SUBSTR(SQLERRM, 1, 300);
        
        INSERT INTO reg_errores (id_error, nomsubprograma, msg_error)
        VALUES (sq_error.NEXTVAL, 'Error en la función FN_CONSUMOS al recuperar los consumos del cliente con Id ' || p_id_huesped, v_mensaje_error);
        COMMIT;
        RETURN 0;
        
    WHEN OTHERS THEN
        RETURN 0;
END fn_get_consumos;
/


--------------------------------------------------------------------------------------


-- PROCEDIMINETO PRINCIPAL

CREATE OR REPLACE PROCEDURE sp_generar_cobros (
    p_fecha_actual IN DATE,
    p_tipo_cambio IN NUMBER
) IS
    -- Variables para cálculos en USD
    v_consumos_usd NUMBER;
    v_tours_usd NUMBER;
    v_pct_desc_consumos NUMBER;
    
    -- Variables para cálculos en CLP (Pesos Chilenos)
    v_alojamiento_clp NUMBER;
    v_consumos_clp NUMBER;
    v_tours_clp NUMBER;
    v_cobro_personas_clp NUMBER;
    v_subtotal_clp NUMBER;
    v_desc_consumos_clp NUMBER;
    v_desc_agencia_clp NUMBER;
    v_total_clp NUMBER;
    
    -- Variables auxiliares
    v_agencia VARCHAR2(100);
    v_num_personas NUMBER;
BEGIN
    -- 1. Limpieza de tablas
    EXECUTE IMMEDIATE 'TRUNCATE TABLE detalle_diario_huespedes';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE reg_errores';

    -- 2. Cursor agrupado (GROUP BY) para evitar error ORA-00001
    FOR reg IN (
        SELECT r.id_huesped,
               -- Se concatena un espacio para asegurar que el INSTR no falle si el nombre es una sola palabra
               SUBSTR(h.nom_huesped, 1, INSTR(h.nom_huesped || ' ', ' ')-1) || ' ' || h.appat_huesped AS nombre,
               -- Sumamos todas las habitaciones asociadas a esa reserva
               SUM((hab.valor_habitacion + hab.valor_minibar) * r.estadia) AS alojamiento_usd
        FROM reserva r
        JOIN huesped h ON r.id_huesped = h.id_huesped
        JOIN detalle_reserva dr ON r.id_reserva = dr.id_reserva
        JOIN habitacion hab ON dr.id_habitacion = hab.id_habitacion
        WHERE r.ingreso + r.estadia = p_fecha_actual
        GROUP BY r.id_huesped, h.nom_huesped, h.appat_huesped
    ) LOOP
        
        -- Obtener datos usando nuestras funciones
        v_agencia := fn_get_agencia(reg.id_huesped);
        v_consumos_usd := fn_get_consumos(reg.id_huesped);
        v_tours_usd := pkg_hotel.fn_calc_tours(reg.id_huesped);
        
        -- Determinar cantidad de personas (asumimos mínimo 1 si no registra tour)
        BEGIN
            SELECT NVL(MAX(num_personas), 1) INTO v_num_personas
            FROM huesped_tour WHERE id_huesped = reg.id_huesped;
        EXCEPTION 
            WHEN OTHERS THEN v_num_personas := 1;
        END;

        -- Conversión a CLP y redondeo a enteros
        v_alojamiento_clp := ROUND(reg.alojamiento_usd * p_tipo_cambio);
        v_consumos_clp := ROUND(v_consumos_usd * p_tipo_cambio);
        v_tours_clp := ROUND(v_tours_usd * p_tipo_cambio);
        v_cobro_personas_clp := 35000 * v_num_personas;
        
        -- Subtotal
        v_subtotal_clp := v_alojamiento_clp + v_consumos_clp + v_tours_clp + v_cobro_personas_clp;

        -- Descuento Consumos: Buscar porcentaje en tabla
        BEGIN
            SELECT pct INTO v_pct_desc_consumos
            FROM tramos_consumos
            WHERE v_consumos_usd BETWEEN vmin_tramo AND vmax_tramo;
        EXCEPTION 
            WHEN NO_DATA_FOUND THEN v_pct_desc_consumos := 0;
        END;
        v_desc_consumos_clp := ROUND(v_consumos_clp * v_pct_desc_consumos);

        -- Descuento Agencia: 12% sobre (Alojamiento + Consumos + Personas)
        IF UPPER(v_agencia) = 'VIAJES ALBERTI' THEN
            v_desc_agencia_clp := ROUND((v_alojamiento_clp + v_consumos_clp + v_cobro_personas_clp) * 0.12);
        ELSE
            v_desc_agencia_clp := 0;
        END IF;

        -- Total a pagar
        v_total_clp := v_subtotal_clp - v_desc_consumos_clp - v_desc_agencia_clp;

        -- Insertar resultado final
        INSERT INTO detalle_diario_huespedes (
            id_huesped, nombre, agencia, alojamiento, consumos, tours, 
            subtotal_pago, descuento_consumos, descuentos_agencia, total
        ) VALUES (
            reg.id_huesped, reg.nombre, v_agencia, v_alojamiento_clp, v_consumos_clp, v_tours_clp, 
            v_subtotal_clp, v_desc_consumos_clp, v_desc_agencia_clp, v_total_clp
        );
        
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Proceso de facturación finalizado correctamente.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error crítico en el proceso: ' || SQLERRM);
END;
/

---------------------------------------------

--VALIDACION

SET SERVEROUTPUT ON;

BEGIN
    -- Invocamos el procedimiento pasando la fecha del requerimiento y el valor de cambio
    sp_generar_cobros(TO_DATE('18/08/2021', 'DD/MM/YYYY'), 915);
END;
/

-- Finalmente, para revisar los resultados de la tabla:
SELECT * FROM detalle_diario_huespedes ORDER BY id_huesped;

-- Y para ver si las funciones atraparon errores correctamente:
SELECT * FROM reg_errores;

-------------------------------------------------------------------------

