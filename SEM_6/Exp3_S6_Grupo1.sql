
-- PROCEDIMIENTO DE INSERCIÓN  (GASTO_COMUN_PAGO_CERO)
-- Este procedimiento almacenará la información del deudor.
CREATE OR REPLACE PROCEDURE PRC_INSERTAR_PAGO_CERO (
    p_periodo NUMBER,
    p_id_edif NUMBER,
    p_nom_edif VARCHAR2,
    p_run_adm VARCHAR2,
    p_nom_adm VARCHAR2,
    p_nro_depto NUMBER,
    p_run_resp VARCHAR2,
    p_nom_resp VARCHAR2,
    p_multa NUMBER,
    p_obs VARCHAR2
) AS
BEGIN
    INSERT INTO GASTO_COMUN_PAGO_CERO (
        anno_mes_pcgc, id_edif, nombre_edif, run_administrador, 
        nombre_admnistrador, nro_depto, run_responsable_pago_gc, 
        nombre_responsable_pago_gc, valor_multa_pago_cero, observacion
    ) VALUES (
        p_periodo, p_id_edif, p_nom_edif, p_run_adm, 
        p_nom_adm, p_nro_depto, p_run_resp, p_nom_resp, p_multa, p_obs
    );
END;

-- Procedimiento Principal
-- Recorre los departamentos, verifica deudas y actualiza la tabla GASTO_COMUN.

CREATE OR REPLACE PROCEDURE PRC_PROCESAR_MOROSIDAD (
    p_periodo_actual NUMBER, -- Ej: 202605. 
    p_valor_uf       NUMBER  -- Ej: 29509.
) AS
    -- Variables
    v_periodo_anterior NUMBER(6);
    v_conteo_pagos     NUMBER;
    v_meses_deuda      NUMBER;
    v_monto_multa      NUMBER;
    v_observacion      VARCHAR2(200);
BEGIN
    -- 1. Calcular el mes anterior basado en el parámetro ingresado.
    -- Convertimos el numero 202605 a fecha, restamos 1 mes, y volvemos a numero.
    v_periodo_anterior := TO_NUMBER(TO_CHAR(ADD_MONTHS(TO_DATE(TO_CHAR(p_periodo_actual, '999999'), 'YYYYMM'), -1), 'YYYYMM'));

    -- 2. Limpiar la tabla de destino para el periodo actual (para evitar duplicados si se  re-ejecuta)
    DELETE FROM GASTO_COMUN_PAGO_CERO WHERE anno_mes_pcgc = p_periodo_actual;

    -- 3. Recorrer los departamentos que tenían gasto común el mes ANTERIOR
    FOR reg IN (
        SELECT 
            gc.id_edif, 
            e.nombre_edif, 
            a.numrun_adm || '-' || a.dvrun_adm AS run_adm,
            a.pnombre_adm || ' ' || a.appaterno_adm AS nom_adm,
            gc.nro_depto, 
            r.numrun_rpgc || '-' || r.dvrun_rpgc AS run_resp,
            r.pnombre_rpgc || ' ' || r.appaterno_rpgc AS nom_resp,
            gc.fecha_pago_gc -- Fecha tope de pago
        FROM GASTO_COMUN gc
        JOIN EDIFICIO e ON gc.id_edif = e.id_edif
        JOIN ADMINISTRADOR a ON e.numrun_adm = a.numrun_adm
        JOIN RESPONSABLE_PAGO_GASTO_COMUN r ON gc.numrun_rpgc = r.numrun_rpgc
        WHERE gc.anno_mes_pcgc = v_periodo_anterior
    ) LOOP
        
        -- 4. Verificar si pagaron el mes anterior (Regla A)
        SELECT COUNT(*) INTO v_conteo_pagos
        FROM PAGO_GASTO_COMUN
        WHERE id_edif = reg.id_edif 
          AND nro_depto = reg.nro_depto 
          AND anno_mes_pcgc = v_periodo_anterior;

        -- SI NO PAGÓ (conteo es 0), PROCESAMOS LA MULTA
        IF v_conteo_pagos = 0 THEN
            
            -- 5. Verificar historial de deudas (Reglas C y D)
            -- Contamos cuántas boletas tienen estado 3 (Pendiente)
            SELECT COUNT(*) INTO v_meses_deuda
            FROM GASTO_COMUN
            WHERE id_edif = reg.id_edif 
              AND nro_depto = reg.nro_depto 
              AND id_epago = 3; 

            -- 6. Aplicar lógica de multas
            IF v_meses_deuda > 1 THEN
                -- Más de un mes debiendo: Multa 4 UF
                v_monto_multa := p_valor_uf * 4;
                v_observacion := 'Se realizará el corte del combustible y agua a contar del ' || TO_CHAR(reg.fecha_pago_gc, 'DD/MM/YYYY');
            ELSE
                -- Solo debe el mes anterior: Multa 2 UF
                v_monto_multa := p_valor_uf * 2;
                v_observacion := 'Se dará aviso de corte de combustible y agua';
            END IF;

            -- 7. Insertar en la tabla de reporte (GASTO_COMUN_PAGO_CERO)
            INSERT INTO GASTO_COMUN_PAGO_CERO (
                anno_mes_pcgc, id_edif, nombre_edif, run_administrador, 
                nombre_admnistrador, nro_depto, run_responsable_pago_gc, 
                nombre_responsable_pago_gc, valor_multa_pago_cero, observacion
            ) VALUES (
                p_periodo_actual, -- Usamos el periodo actual para el reporte
                reg.id_edif, reg.nombre_edif, reg.run_adm,
                reg.nom_adm, reg.nro_depto, reg.run_resp, reg.nom_resp,
                v_monto_multa, v_observacion
            );

            -- 8. Actualizar la multa en la tabla GASTO_COMUN del periodo ACTUAL
            UPDATE GASTO_COMUN
            SET multa_gc = v_monto_multa
            WHERE id_edif = reg.id_edif 
              AND nro_depto = reg.nro_depto 
              AND anno_mes_pcgc = p_periodo_actual;
              
        END IF; -- Fin validación no pago
    END LOOP;
    
    COMMIT; -- Guardar cambios
END;
/



-- Eliminamos pagos del periodo ABRIL (mes anterior al proceso de Mayo)
-- para que coincidan con la imagen de ejemplo
DELETE FROM PAGO_GASTO_COMUN 
WHERE anno_mes_pcgc = 202604 
AND (
    (id_edif = 40 AND nro_depto IN (20, 30)) OR
    (id_edif = 20 AND nro_depto IN (503, 509, 510, 602, 603)) OR
    (id_edif = 30 AND nro_depto IN (503)) OR
    (id_edif = 50 AND nro_depto IN (503, 1005, 1101)) OR
    (id_edif = 60 AND nro_depto IN (503, 1101, 1104))
);

COMMIT;

-- Procesamos Mayo. El sistema detectará la falta de pago en Abril.
EXEC PRC_PROCESAR_MOROSIDAD(202605, 29509);

-- Comprobamos informes:
SELECT 
    ANNO_MES_PCGC,
    ID_EDIF,
    NOMBRE_EDIF,
    RUN_ADMINISTRADOR,
    NOMBRE_ADMNISTRADOR,
    NRO_DEPTO,
    RUN_RESPONSABLE_PAGO_GC,
    NOMBRE_RESPONSABLE_PAGO_GC,
    OBSERVACION
FROM GASTO_COMUN_PAGO_CERO
ORDER BY ID_EDIF, NRO_DEPTO;


SELECT 
    ANNO_MES_PCGC,
    ID_EDIF,
    NRO_DEPTO,
    FECHA_DESDE_GC,
    FECHA_HASTA_GC,
    MULTA_GC
FROM GASTO_COMUN 
WHERE anno_mes_pcgc = 202605 
  AND multa_gc > 0
ORDER BY ID_EDIF, NRO_DEPTO;
