/* Bloque Anónimo PL/SQL - Caso 1 */

DECLARE

    -- Variables para recibir datos externos (Paramétricas)
    v_run_cliente       VARCHAR(15) := '&RUN_CLIENTE';  
    v_tramo1_extra      NUMBER := &VALOR_EXTRA_TRAMO1; -- Ej: 100
    v_tramo2_extra      NUMBER := &VALOR_EXTRA_TRAMO2; -- Ej: 300
    v_tramo3_extra      NUMBER := &VALOR_EXTRA_TRAMO3; -- Ej: 550
    v_valor_normal      NUMBER := &VALOR_PESO_NORMAL;  -- Ej: 1200

    -- Variables para guardar datos traídos de la BD
    v_nro_cliente       NUMBER;
    v_nombre_completo   VARCHAR2(100);
    v_nombre_tipo_cli   VARCHAR2(50);
    v_monto_total_cred  NUMBER := 0; -- Inicializa en 0 por seguridad
    
    -- Variables para cálculos
    v_pesos_base        NUMBER := 0;
    v_pesos_extra       NUMBER := 0;
    v_pesos_total       NUMBER := 0;
    
    -- Variable auxiliar para el cálculo de año anterior
    v_anho_anterior     NUMBER;

BEGIN
    --lógica ejecutable 

    -- Se calcula cuál fue el año anterior dinámicamente. Extrae el año actual del sistema y le resta 1
    v_anho_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

    -- A. Se obtiene datos personales del cliente
    -- Se usa SELECT ... INTO ... para guardar el resultado de la consulta en nuestras variables
    SELECT nro_cliente, 
           pnombre || ' ' || snombre || ' ' || appaterno || ' ' || apmaterno,
           tc.nombre_tipo_cliente
      INTO v_nro_cliente, 
           v_nombre_completo,
           v_nombre_tipo_cli
      FROM CLIENTE c
      JOIN TIPO_CLIENTE tc ON c.cod_tipo_cliente = tc.cod_tipo_cliente
     WHERE c.numrun || '-' || c.dvrun = v_run_cliente;

    -- B. Se calcula el monto total solicitado el año anterior
    -- NVL sirve por que si no hay créditos, devuelva 0 en lugar de NULL, evitando problemas de cálculos matematicos
    SELECT NVL(SUM(monto_solicitado), 0)
      INTO v_monto_total_cred
      FROM CREDITO_CLIENTE
     WHERE nro_cliente = v_nro_cliente
       AND EXTRACT(YEAR FROM fecha_solic_cred) = v_anho_anterior;

    -- C. Cálculo de Pesos BASE (Regla: $1.200 por cada $100.000)
    -- TRUNC se usa para tomar la parte entera de la división (ej: 150.000 / 100.000 = 1.5 -> 1)
    v_pesos_base := TRUNC(v_monto_total_cred / 100000) * v_valor_normal;

    -- D. Cálculo de Pesos EXTRA (Solo Independientes)
    IF v_nombre_tipo_cli LIKE '%independiente%' THEN
        -- Evaluamos los tramos según el monto total
        IF v_monto_total_cred < 1000000 THEN
            v_pesos_extra := TRUNC(v_monto_total_cred / 100000) * v_tramo1_extra;
        ELSIF v_monto_total_cred >= 1000001 AND v_monto_total_cred <= 3000000 THEN
            v_pesos_extra := TRUNC(v_monto_total_cred / 100000) * v_tramo2_extra;
        ELSIF v_monto_total_cred > 3000000 THEN
             v_pesos_extra := TRUNC(v_monto_total_cred / 100000) * v_tramo3_extra;
        END IF;
    ELSE
        -- Si no es independiente, extra es 0
        v_pesos_extra := 0;
    END IF;

    -- Suma final
    v_pesos_total := v_pesos_base + v_pesos_extra;

    -- E. Insertar en la tabla de resultados
    -- Primero borramos si ya existe para evitar error de clave duplicada (útil al probar varias veces)
    DELETE FROM CLIENTE_TODOSUMA WHERE nro_cliente = v_nro_cliente;
    
    INSERT INTO CLIENTE_TODOSUMA (
        NRO_CLIENTE, RUN_CLIENTE, NOMBRE_CLIENTE, TIPO_CLIENTE, 
        MONTO_SOLIC_CREDITOS, MONTO_PESOS_TODOSUMA
    ) VALUES (
        v_nro_cliente, v_run_cliente, v_nombre_completo, v_nombre_tipo_cli,
        v_monto_total_cred, v_pesos_total
    );

    -- Confirmar cambios
    COMMIT;
    
    -- Mensaje de éxito en consola
    DBMS_OUTPUT.PUT_LINE('Proceso exitoso para cliente: ' || v_nombre_completo);
    DBMS_OUTPUT.PUT_LINE('Total Pesos Calculados: ' || v_pesos_total);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró el cliente con RUN ' || v_run_cliente);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
END;
/


/* Sentencias para verificar. Consultas de prueba (SQL Puro) Para Caso 1*/
SELECT c.nro_cliente, 
       c.pnombre || ' ' || c.snombre || ' ' || c.appaterno || ' ' || c.apmaterno AS nombre_completo,
       tc.nombre_tipo_cliente
  FROM CLIENTE c
  JOIN TIPO_CLIENTE tc ON c.cod_tipo_cliente = tc.cod_tipo_cliente
 WHERE c.numrun || '-' || c.dvrun = '21242003-4'; -- RUT de KAREN SOFIA PRADENAS MANDIOLA


/* Consulta de Contenido de Tabla */
SELECT * FROM CLIENTE_TODOSUMA;

/* Ruts para probar solución con 5 clientes específicos */
-- 21242003-4   RUT de KAREN SOFIA PRADENAS MANDIOLA 67
-- 22176845-2  RUT de SILVANA MARTINA VALENZUELA DUARTE 85
-- 18858542-6  RUT de DENISSE ALICIA DIAZ MIRANDA  62
-- 22558061-8  RUT de AMANDA ROMINA LIZANA MARAMBIO  34
-- 21300628-2  RUT de LUIS CLAUDIO LUNA JORQUERA  41

------------------------------------------------------------------------------
/* Bloque Anónimo PL/SQL - Caso 2 */


DECLARE
    -- Parámetros de entrada
    v_nro_cliente       NUMBER := &NRO_CLIENTE;       
    v_nro_solic         NUMBER := &NRO_SOLICITUD;     -- Ej: 2001, 3004, 2004
    v_cant_postergar    NUMBER := &CANT_CUOTAS_POST;  -- 1 o 2
    
    -- Variables para datos del crédito actual
    v_ultima_cuota      NUMBER;
    v_fecha_venc        DATE;
    v_valor_cuota_orig  NUMBER;
    v_tipo_credito      VARCHAR2(50);
    
    -- Variables para cálculos
    v_tasa_interes      NUMBER := 0;
    v_nuevo_valor_cuota NUMBER;
    v_cant_creditos_anho_ant NUMBER;
    v_anho_anterior     NUMBER;

BEGIN
    v_anho_anterior := EXTRACT(YEAR FROM SYSDATE) - 1;

    -- 1. se Obtiene datos de la ÚLTIMA cuota vigente de ese crédito
    SELECT MAX(nro_cuota)
      INTO v_ultima_cuota
      FROM CUOTA_CREDITO_CLIENTE
     WHERE nro_solic_credito = v_nro_solic;

    -- Se Trae la fecha vencimiento y valor de esa última cuota
    SELECT fecha_venc_cuota, valor_cuota
      INTO v_fecha_venc, v_valor_cuota_orig
      FROM CUOTA_CREDITO_CLIENTE
     WHERE nro_solic_credito = v_nro_solic
       AND nro_cuota = v_ultima_cuota;

    -- 2. Se identifica Tipo de Crédito para definir la tasa
    SELECT c.nombre_credito
      INTO v_tipo_credito
      FROM CREDITO_CLIENTE cc
      JOIN CREDITO c ON cc.cod_credito = c.cod_credito
     WHERE cc.nro_solic_credito = v_nro_solic;

    -- Lógica de tasas según reglas del negocio
    IF v_tipo_credito LIKE '%Hipotecario%' THEN
        IF v_cant_postergar = 1 THEN
            v_tasa_interes := 0; -- Sin interés
        ELSE
            v_tasa_interes := 0.005; -- 0.5%
        END IF;
    ELSIF v_tipo_credito LIKE '%Consumo%' THEN
        v_tasa_interes := 0.01; -- 1%
    ELSIF v_tipo_credito LIKE '%Automotriz%' THEN
        v_tasa_interes := 0.02; -- 2%
    END IF;

    -- Se calcula el valor de las nuevas cuotas
    v_nuevo_valor_cuota := ROUND(v_valor_cuota_orig + (v_valor_cuota_orig * v_tasa_interes));

    -- 3. INSERTAR NUEVAS CUOTAS (Sin Loops, usando IF secuencial)
    
    -- Insertar la primera cuota postergada (siempre se hace si cant >= 1)
    IF v_cant_postergar >= 1 THEN
        INSERT INTO CUOTA_CREDITO_CLIENTE (
            nro_solic_credito, nro_cuota, fecha_venc_cuota, valor_cuota, 
            fecha_pago_cuota, monto_pagado, saldo_por_pagar, cod_forma_pago
        ) VALUES (
            v_nro_solic, 
            v_ultima_cuota + 1,                -- Siguiente número
            ADD_MONTHS(v_fecha_venc, 1),       -- Un mes después del último vencimiento
            v_nuevo_valor_cuota,
            NULL, NULL, NULL, NULL             -- Campos nulos como pide las instrucciones
        );
    END IF;

    -- Insertar la segunda cuota postergada (solo si cant = 2)
    IF v_cant_postergar = 2 THEN
        INSERT INTO CUOTA_CREDITO_CLIENTE (
            nro_solic_credito, nro_cuota, fecha_venc_cuota, valor_cuota, 
            fecha_pago_cuota, monto_pagado, saldo_por_pagar, cod_forma_pago
        ) VALUES (
            v_nro_solic, 
            v_ultima_cuota + 2,                -- Dos números más
            ADD_MONTHS(v_fecha_venc, 2),       -- Dos meses después
            v_nuevo_valor_cuota,
            NULL, NULL, NULL, NULL
        );
    END IF;

    -- 4. CONDONACIÓN (Verificar si pidió más créditos el año pasado)
    SELECT COUNT(*)
      INTO v_cant_creditos_anho_ant
      FROM CREDITO_CLIENTE
     WHERE nro_cliente = v_nro_cliente
       AND EXTRACT(YEAR FROM fecha_solic_cred) = v_anho_anterior;

    -- Si tiene más de 1 crédito (el actual + otros), se condona la última cuota ORIGINAL
    IF v_cant_creditos_anho_ant > 1 THEN
        UPDATE CUOTA_CREDITO_CLIENTE
           SET fecha_pago_cuota = fecha_venc_cuota, -- Fecha pago = Fecha vencimiento
               monto_pagado = valor_cuota,          -- Monto pagado = Valor total
               saldo_por_pagar = 0                  -- Deuda saldada
         WHERE nro_solic_credito = v_nro_solic
           AND nro_cuota = v_ultima_cuota;          -- Actualizamos la que era la última antes de insertar
           
        DBMS_OUTPUT.PUT_LINE('Se aplicó condonación a la cuota ' || v_ultima_cuota);
    END IF;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Postergación realizada para solicitud: ' || v_nro_solic);

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- Deshacer si hay error
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/


/* Sentencias para verificar. Consultas de prueba (SQL Puro) Para Caso 2*/

-- Verificar la última cuota (MAX) , dirá cuál es el número más alto de cuota que existe hoy para ese crédito.

SELECT MAX(nro_cuota)
  FROM CUOTA_CREDITO_CLIENTE
 WHERE nro_solic_credito = 2001; 
 -- LA DEUDA 2001 DE SEBASTIAN TIENE 48 CUOTAS
 
 -- Verificar fecha y valor de esa última cuota 
 SELECT fecha_venc_cuota, valor_cuota
  FROM CUOTA_CREDITO_CLIENTE
 WHERE nro_solic_credito = 2001
   AND nro_cuota = 48; 
   -- FECHA 22/12/29 Y VALOR CUOTA 57292 
   
   -- Verificar el Tipo de Crédito, hace el cruce (JOIN) para saber si es Hipotecario, Consumo, etc.
  SELECT c.nombre_credito
  FROM CREDITO_CLIENTE cc
  JOIN CREDITO c ON cc.cod_credito = c.cod_credito
 WHERE cc.nro_solic_credito = 2001;
 -- EL TIPO DE CREDITO ES Crédito Hipotecario
 
 
 -- probar si el cliente Sebastián Quintana (tiene el nro_cliente 5) pidió créditos el año pasado.
--  hoy es 2026 (por lo que el año anterior sería 2025)
SELECT COUNT(*)
  FROM CREDITO_CLIENTE
 WHERE nro_cliente = 5   
   AND EXTRACT(YEAR FROM fecha_solic_cred) = 2025; -- Se reemplaza v_anho_anterior por el año fijo
 
 -- verificar visualmente qué créditos está encontrando (o si no encuentra ninguno)
 SELECT *
  FROM CREDITO_CLIENTE
 WHERE nro_cliente = 5
   AND EXTRACT(YEAR FROM fecha_solic_cred) = 2025;
 -- Para Sebastian, cliente n 5, un solo credito. 
 -- Para Karen , cliente n 67, tiene 2 créditos el año pasado.
 -- Para Julian, cliente n 13, tiene 2 créditos el año pasado.

 -- PARA VERIFICAR TABLA CUOTA_CREDITO_CLIENTE
   SELECT * FROM CUOTA_CREDITO_CLIENTE WHERE NRO_SOLIC_CREDITO = 2001 ORDER BY NRO_CUOTA;
   SELECT * FROM CUOTA_CREDITO_CLIENTE WHERE NRO_SOLIC_CREDITO = 2004 ORDER BY NRO_CUOTA;
   SELECT * FROM CUOTA_CREDITO_CLIENTE WHERE NRO_SOLIC_CREDITO = 3004 ORDER BY NRO_CUOTA;