-------------------------------
-- RESOLUCIÓN CASO SUMATIVA 2
-------------------------------

SET SERVEROUTPUT ON;

-------------------------------


--variable bind para el años en proceso
VARIABLE b_periodo NUMBER;
EXEC :b_periodo := 2026;

DECLARE
    -- VARRAY para nombres de transacciones (requerimiento)
    TYPE t_tipo_nom IS VARRAY(2) OF VARCHAR2(40);
    v_nombres_tipo t_tipo_nom := t_tipo_nom('Avance en Efectivo', 'Super Avance en Efectivo');
    
    -- Registro para el detalle
    TYPE r_detalle_transac IS RECORD (
        v_run      cliente.numrun%TYPE,
        v_dv       cliente.dvrun%TYPE,
        v_tarjeta  tarjeta_cliente.nro_tarjeta%TYPE,
        v_nro_tran transaccion_tarjeta_cliente.nro_transaccion%TYPE,
        v_fecha    DATE,
        v_monto    NUMBER,
        v_cod_tipo NUMBER
    );
    
    v_reg r_detalle_transac;
    
    -- Cursor Explícito Principal (Requerimiento)
    CURSOR c_transacciones IS
        SELECT cl.numrun, cl.dvrun, t.nro_tarjeta, t.nro_transaccion, 
               t.fecha_transaccion, t.monto_total_transaccion, t.cod_tptran_tarjeta
        FROM cliente cl
        JOIN tarjeta_cliente tc ON cl.numrun = tc.numrun
        JOIN transaccion_tarjeta_cliente t ON tc.nro_tarjeta = t.nro_tarjeta
        WHERE EXTRACT(YEAR FROM t.fecha_transaccion) = :b_periodo
          AND t.cod_tptran_tarjeta IN (102, 103)
        ORDER BY t.fecha_transaccion ASC, cl.numrun ASC;
    
    CURSOR c_resumen (p_anio NUMBER) IS
        SELECT TO_CHAR(fecha_transaccion, 'MMYYYY') as mes_anno, tipo_transaccion, 
               SUM(monto_transaccion) as total_monto, SUM(aporte_sbif) as total_aporte
        FROM DETALLE_APORTE_SBIF
        GROUP BY TO_CHAR(fecha_transaccion, 'MMYYYY'), tipo_transaccion
        ORDER BY 1 ASC, 2 ASC;
    
    -- Variables de cálculo
    v_porc_sbif    NUMBER;
    v_aporte_calc  NUMBER;
    v_nom_tipo     VARCHAR2(40);
    v_cont_iter    NUMBER := 0;
    v_total_reg    NUMBER;
    
    -- Excepciones (Requerimiento)
    ex_monto_fuera_rango EXCEPTION; -- Definida por usuario
    
    ex_error_dml EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_error_dml, -2291); -- No predefinida (Error de FK)
    
    
BEGIN
    -- limpieza de tablas:
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DETALLE_APORTE_SBIF';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE RESUMEN_APORTE_SBIF';

    -- Obtener total para validación de COMMIT (Requerimiento)
    SELECT COUNT(*) INTO v_total_reg 
    FROM transaccion_tarjeta_cliente 
    WHERE EXTRACT(YEAR FROM fecha_transaccion) = :b_periodo
      AND cod_tptran_tarjeta IN (102, 103);
      
-- Apertura de Cursor
    FOR rec IN c_transacciones LOOP
        -- Asigna nombre desde el VARRAY basado en el código
        IF rec.cod_tptran_tarjeta = 102 THEN v_nom_tipo := v_nombres_tipo(1);
        ELSE v_nom_tipo := v_nombres_tipo(2);
        END IF;
      
      -- Cálculo del Aporte (Requerimiento)
        BEGIN
            SELECT porc_aporte_sbif INTO v_porc_sbif
            FROM TRAMO_APORTE_SBIF
            WHERE rec.monto_total_transaccion BETWEEN tramo_inf_av_sav AND tramo_sup_av_sav;
            
        -- Excepción Predefinida: Se activa si el monto de la transacción no cae en ningún rango de la tabla TRAMO_APORTE_SBIF
        EXCEPTION
            WHEN NO_DATA_FOUND THEN -- v_porc_sbif := 0; el aporte es cero, un opción pero se eleva la excepción:
            RAISE ex_monto_fuera_rango;  -- dispara excepción de usuario
            
        END;

        v_aporte_calc := ROUND(rec.monto_total_transaccion * (v_porc_sbif / 100));

        -- Inserción Detalle (Requerimiento)
        INSERT INTO DETALLE_APORTE_SBIF 
        VALUES (rec.numrun, rec.dvrun, rec.nro_tarjeta, rec.nro_transaccion, 
                rec.fecha_transaccion, v_nom_tipo, rec.monto_total_transaccion, v_aporte_calc);

        v_cont_iter := v_cont_iter + 1;
    END LOOP;

    -- Lógica para RESUMEN_APORTE_SBIF (Requerimiento)
    -- Procesamiento de Resumen usando el segundo cursor (parametrizado)
    FOR res IN c_resumen(:b_periodo) LOOP
        INSERT INTO RESUMEN_APORTE_SBIF VALUES (res.mes_anno, res.tipo_transaccion, res.total_monto, res.total_aporte);
    END LOOP;

    -- Confirmación de Transacción (Requerimiento)
    IF v_cont_iter = v_total_reg THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Proceso exitoso. Registros procesados: ' || v_cont_iter);
    ELSE
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: No se procesaron todos los registros.');
    END IF;

EXCEPTION
    --Captura de la excepción definida por el usuario
    WHEN ex_monto_fuera_rango THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE ('Error de Negocio: Se encontró un monto que no coincide con los tramos SBIF.');
    
    -- Captura de la NO PREDEFINIDA (asociada a -2291)
    WHEN ex_error_dml THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error de Integridad: Intento de insertar una tarjeta o cliente inexistente.');

    -- Captura de PREDEFINIDA (General para el resto del bloque)
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLCODE || ' - ' || SQLERRM);
        

END;
/


---- PARA VERIFICAR: 

DELETE FROM TRANSACCION_TARJETA_CLIENTE WHERE nro_transaccion = 7777;
COMMIT;

INSERT INTO TRANSACCION_TARJETA_CLIENTE (nro_tarjeta, nro_transaccion, fecha_transaccion, monto_transaccion, total_cuotas_transaccion, monto_total_transaccion, cod_tptran_tarjeta, id_sucursal)
VALUES (31021713767, 7777, TO_DATE('01/01/2026','DD/MM/YYYY'), 10, 1, 10, 102, 1311);
COMMIT;

SELECT * FROM TRANSACCION_TARJETA_CLIENTE WHERE nro_transaccion = 7777;

SELECT * FROM RESUMEN_APORTE_SBIF;
SELECT * FROM DETALLE_APORTE_SBIF;






