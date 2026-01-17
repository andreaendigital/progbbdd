

-----  SENTENCIAS PARA VER TABLAS

SELECT * FROM ARRIENDO_CAMION ;
SELECT * FROM CAMION;
SELECT * FROM CLIENTE;
SELECT * FROM COMUNA;
SELECT * FROM MARCA;
SELECT * FROM TIPO_CLIENTE;
SELECT * FROM TIPO_CAMION;
SELECT * FROM TIPO_SALUD;
SELECT * FROM AFP;
SELECT * FROM EMPLEADO;
SELECT * FROM ESTADO_CIVIL;
SELECT * FROM PROY_MOVILIZACION;
SELECT * FROM ARRIENDO_CAMION;
SELECT * FROM USUARIO_CLAVE;
SELECT * FROM HIST_ARRIENDO_ANUAL_CAMION;
SELECT * FROM INFO_SII;
SELECT * FROM BONIF_POR_UTILIDAD;
SELECT * FROM TRAMO_ANTIGUEDAD;

-- EN LA PRIMERA PARTE TRABAJARE EL DESARROLLO DE LAS SENTENCIAS Y EN LA SEGUNDA PARTE COPIARÉ Y MODIFICARÉ AGREGANDO LOS LOOP Y TRANSACCIONES

---------------------------------------------------
-- BLOQUE PL/SQL PARA UN SOLO REGISTRO (ID_EMP = 100)
---------------------------------------------------

SET SERVEROUTPUT ON; -- HABILITAR SALIDA POR CONSOLA           

VARIABLE b_fecha_hoy VARCHAR2(10); -- VARIABLE BIND PARA FECHA PROCESO
EXEC :b_fecha_hoy := TO_CHAR(SYSDATE, 'DD/MM/YYYY'); -- ASIGNAR FECHA ACTUAL A VARIABLE BIND


DECLARE
-- DECLARAR EL CURSOR EN LA PARTE 2

-- DECLARAR VARIABLES
v_id_emp                EMPLEADO.ID_EMP%TYPE;
v_dv_emp                EMPLEADO.DVRUN_EMP%TYPE;
v_pnombre               EMPLEADO.PNOMBRE_EMP%TYPE;
v_snombre               EMPLEADO.SNOMBRE_EMP%TYPE;
v_appaterno             EMPLEADO.APPATERNO_EMP%TYPE;
v_apmaterno             EMPLEADO.APMATERNO_EMP%TYPE;
v_fecha_contratacion    EMPLEADO.FECHA_CONTRATO%TYPE;
v_sueldo                EMPLEADO.SUELDO_BASE%TYPE;
v_estado_civil          ESTADO_CIVIL.NOMBRE_ESTADO_CIVIL%TYPE;
v_run_emp               EMPLEADO.NUMRUN_EMP%TYPE;
v_fecha_nac             EMPLEADO.FECHA_NAC%TYPE;

-- Variables locales
v_nombre_completo VARCHAR2(60); -- Ajustado a largo en tabla USUARIO_CLAVE
v_annos_trabajados NUMBER;
v_fecha_hoy   DATE;
v_letras_apellido  VARCHAR2(2);


v_nombre_usuario     VARCHAR2(20); -- Ajustado a largo en tabla USUARIO_CLAVE
v_clave_usuario     VARCHAR2(20); -- Ajustado a largo en tabla USUARIO_CLAVE

    
BEGIN
    -- RECUPERAMOS DATOS
        SELECT E.ID_EMP, E.NUMRUN_EMP, E.DVRUN_EMP, E.PNOMBRE_EMP, SNOMBRE_EMP, APPATERNO_EMP, APMATERNO_EMP, E.FECHA_NAC, E.FECHA_CONTRATO, E.SUELDO_BASE, EC.NOMBRE_ESTADO_CIVIL 
        INTO v_id_emp, v_run_emp, v_dv_emp, v_pnombre, v_snombre, v_appaterno, v_apmaterno, v_fecha_nac, v_fecha_contratacion, v_sueldo, v_estado_civil 
        FROM EMPLEADO E 
        JOIN ESTADO_CIVIL EC ON E.ID_ESTADO_CIVIL = EC.ID_ESTADO_CIVIL 
        WHERE E.ID_EMP = 100;
        
    --CONCATENAR NOMBRE COMPLETO
    v_nombre_completo := v_pnombre || ' ' || v_snombre || ' ' ||  v_appaterno || ' ' || v_apmaterno ;
    
    -- Convertir variable Bind a Date , 
    v_fecha_hoy := TO_DATE(:b_fecha_hoy, 'DD/MM/YYYY');
    
    -- [PL/SQL DOCUMENTADA 1]: Cálculo de antigüedad truncada saca los decimales en caso de existir
    v_annos_trabajados := TRUNC(MONTHS_BETWEEN(v_fecha_hoy, v_fecha_contratacion ) / 12);
    
    
    -- GENERACIÓN DE NOMBRE DE USUARIO
            v_nombre_usuario := 
                LOWER(SUBSTR(v_estado_civil, 1, 1)) ||       -- 1ra letra estado civil
                SUBSTR(v_pnombre, 1, 3) ||                   -- 3 letras nombre
                LENGTH(v_pnombre) ||                         -- Largo nombre
                '*' ||                                       -- Asterisco
                SUBSTR(TO_CHAR(v_sueldo), -1) ||             -- Último dígito sueldo
                v_dv_emp ||                                  -- Dígito verificador
                v_annos_trabajados;                          -- Años trabajados
    
     -- AGREGAR X SI ANNOS_TRABAJADOS ES < 10    
     
     IF v_annos_trabajados < 10 THEN
                v_nombre_usuario := v_nombre_usuario || 'X';
    END IF;


    -- GENERAR LETRAS DEL APELLIDO
                  
                -- 1. Determinamos las letras del apellido según estado civil
            IF (v_estado_civil) = 'CASADO' OR (v_estado_civil) = 'ACUERDO DE UNION CIVIL' THEN
                -- Dos primeras letras
                v_letras_apellido := SUBSTR(v_appaterno, 1, 2);
                
            ELSIF (v_estado_civil) = 'DIVORCIADO' OR (v_estado_civil) = 'SOLTERO' THEN
                -- Primera y última letra
                v_letras_apellido := SUBSTR(v_appaterno, 1, 1) || SUBSTR(v_appaterno, -1);
                
            ELSIF (v_estado_civil) = 'VIUDO' THEN
                -- Antepenúltima (-3) y penúltima (-2) letra
                v_letras_apellido := SUBSTR(v_appaterno, -3, 1) || SUBSTR(v_appaterno, -2, 1);
                
            ELSIF (v_estado_civil) = 'SEPARADO' THEN
                -- Dos últimas letras
                v_letras_apellido := SUBSTR(v_appaterno, -2);
                
            ELSE
                -- Opción por defecto (por seguridad)
                v_letras_apellido := SUBSTR(v_appaterno, 1, 2);
            END IF;

    -- GENERACIÓN DE CLAVE DE USUARIO
            v_clave_usuario :=           
                SUBSTR(TO_CHAR(v_run_emp), 3, 1) ||                      -- 3er dígito RUN
                (TO_NUMBER(TO_CHAR(v_fecha_nac, 'YYYY')) + 2) ||         -- Año Nac + 2
                (TO_NUMBER(SUBSTR(TO_CHAR(v_sueldo), -3)) - 1) ||        -- Últimos 3 sueldo - 1
                LOWER(v_letras_apellido) ||                              -- Letras apellido
                v_id_emp  ||                                                     -- ID Empleado
                TO_CHAR(v_fecha_hoy, 'MMYYYY');                      -- MesAño actual
            
-- VERIFICACIÓN 
    -- VER los datos en la consola
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('DATOS CAPTURADOS PARA EL EMPLEADO 100:');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Nombre Completo Generado: ' || v_nombre_completo);
    DBMS_OUTPUT.PUT_LINE('Sueldo Base: ' || v_sueldo);
    DBMS_OUTPUT.PUT_LINE('Estado Civil: ' || v_estado_civil);
    DBMS_OUTPUT.PUT_LINE('Fecha Contrato: ' || v_fecha_contratacion);
    DBMS_OUTPUT.PUT_LINE('Años trabajados: ' || v_annos_trabajados);
    DBMS_OUTPUT.PUT_LINE('Nombre Usuario: ' ||  v_nombre_usuario);
    DBMS_OUTPUT.PUT_LINE('Clave Usuario: ' ||  v_clave_usuario);
END;
/



-- SENTENCIA PARA VERIFICAR SELECCION DE UNA LINEA
SELECT E.ID_EMP, E.NUMRUN_EMP, E.DVRUN_EMP, E.PNOMBRE_EMP, E.APPATERNO_EMP, 
                   E.SUELDO_BASE, E.FECHA_NAC, E.FECHA_CONTRATO, EC.NOMBRE_ESTADO_CIVIL
           -- INTO v_run_emp, v_dv_emp, v_pnombre, v_appaterno, 
           --      v_sueldo, v_fecha_nac, v_fecha_cont, v_estado_civil
            FROM EMPLEADO E
            JOIN ESTADO_CIVIL EC ON E.ID_ESTADO_CIVIL = EC.ID_ESTADO_CIVIL
            WHERE E.ID_EMP = 100;



------------------------------------------------------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------               
-- PARTE DOS REPLANTEAR SENTENCIAS AGREAGNDO: ALMACENAR EN TABLA, AGREGAR ESTRUCUTRA DE CONTROL DE ITERACION, 
 ------------------------------------------------------------------------------------------------------------------------               
------------------------------------------------------------------------------------------------------------------------

SET SERVEROUTPUT ON;

--------------------------------------------------------
-- 1. LIMPIEZA DE TABLA (Requerimiento g)
--------------------------------------------------------
TRUNCATE TABLE USUARIO_CLAVE;

--------------------------------------------------------
-- 2. VARIABLE BIND PARA FECHA PROCESO (Requerimiento b)
--------------------------------------------------------

VARIABLE b_fecha_hoy VARCHAR2(10);
EXEC :b_fecha_hoy := TO_CHAR(SYSDATE, 'DD/MM/YYYY');

--------------------------------------------------------
-- 3. BLOQUE PL/SQL ANÓNIMO CON CURSOR
--------------------------------------------------------

DECLARE
    -------------------------------------------------------------------------
    -- A. DECLARACIÓN DEL CURSOR
    -- Recupera todos los datos necesarios haciendo el JOIN
    -------------------------------------------------------------------------
    CURSOR c_empleados IS
        SELECT E.ID_EMP, 
               E.NUMRUN_EMP, 
               E.DVRUN_EMP, 
               E.PNOMBRE_EMP, 
               E.SNOMBRE_EMP,      
               E.APPATERNO_EMP, 
               E.APMATERNO_EMP,    
               E.FECHA_NAC, 
               E.FECHA_CONTRATO, 
               E.SUELDO_BASE, 
               EC.NOMBRE_ESTADO_CIVIL
        FROM EMPLEADO E
        JOIN ESTADO_CIVIL EC ON E.ID_ESTADO_CIVIL = EC.ID_ESTADO_CIVIL
        WHERE E.ID_EMP BETWEEN 100 AND 320
        ORDER BY E.ID_EMP;

    -------------------------------------------------------------------------
    -- B. DECLARACIÓN DE VARIABLES
    -------------------------------------------------------------------------
    -- Variables para cálculos
    v_fecha_hoy     DATE;
    v_annos_trabajados  NUMBER;
    v_nombre_completo   VARCHAR2(100);
    
    -- Variables para lógica de negocio (Usuario y Clave)
    v_nombre_usuario        VARCHAR2(20);
    v_clave_usuario          VARCHAR2(20);
    v_letras_apellido   VARCHAR2(2); -- Auxiliar para el IF/ELSE
    
    -- Variables de control de transacciones
    v_contador_exitos   NUMBER := 0;
    v_total_esperado    NUMBER := 0;
    
    
    
BEGIN

-- 1. Preparación de datos iniciales
    v_fecha_hoy := TO_DATE(:b_fecha_hoy, 'DD/MM/YYYY');

    -- Obtenemos el total para validar al final (Requerimiento i)
    SELECT COUNT(*) INTO v_total_esperado FROM EMPLEADO WHERE ID_EMP BETWEEN 100 AND 320;

    -------------------------------------------------------------------------
    -- C. APERTURA E ITERACIÓN DEL CURSOR (LOOP)
    -------------------------------------------------------------------------
    -- Usamos un CURSOR FOR LOOP que facilita la lectura y manejo (r_emp es el registro)
    FOR r_emp IN c_empleados LOOP

        BEGIN
            -- Concatenar nombre completo para insertar
            v_nombre_completo := r_emp.PNOMBRE_EMP || ' ' || r_emp.SNOMBRE_EMP || ' ' || r_emp.APPATERNO_EMP || ' ' || r_emp.APMATERNO_EMP;

            --------------------------------------------------------
            -- LÓGICA 1: AÑOS TRABAJADOS
            --------------------------------------------------------
            -- [PL/SQL DOCUMENTADA]: Se usa TRUNC y MONTHS_BETWEEN para obtener el entero de años
            v_annos_trabajados := TRUNC(MONTHS_BETWEEN(v_fecha_hoy, r_emp.FECHA_CONTRATO) / 12);

            --------------------------------------------------------
            -- LÓGICA 2: NOMBRE DE USUARIO
            --------------------------------------------------------
            v_nombre_usuario := 
                LOWER(SUBSTR(r_emp.NOMBRE_ESTADO_CIVIL, 1, 1)) ||  -- 1ra letra estado civil
                SUBSTR(r_emp.PNOMBRE_EMP, 1, 3) ||                 -- 3 primeras letras nombre
                LENGTH(r_emp.PNOMBRE_EMP) ||                       -- Largo nombre
                '*' ||                                             -- Asterisco
                SUBSTR(TO_CHAR(r_emp.SUELDO_BASE), -1) ||          -- Último dígito sueldo
                r_emp.DVRUN_EMP ||                                 -- Dígito verificador
                v_annos_trabajados;                                -- Años trabajados

            -- Si lleva menos de 10 años, agregar X
            IF v_annos_trabajados < 10 THEN
                v_nombre_usuario := v_nombre_usuario || 'X';
            END IF;

            --------------------------------------------------------
            -- LÓGICA 3: CLAVE DE USUARIO (USANDO IF / ELSIF / ELSE)
            --------------------------------------------------------
            -- Determinamos letras del apellido según estado civil. Se agrega UPPER para seguridad y comparar correctamente las variables.
            IF UPPER(r_emp.NOMBRE_ESTADO_CIVIL) = 'CASADO' OR UPPER(r_emp.NOMBRE_ESTADO_CIVIL) = 'ACUERDO DE UNION CIVIL' THEN
                -- Dos primeras letras
                v_letras_apellido := SUBSTR(r_emp.APPATERNO_EMP, 1, 2);
                
            ELSIF UPPER(r_emp.NOMBRE_ESTADO_CIVIL) = 'DIVORCIADO' OR UPPER(r_emp.NOMBRE_ESTADO_CIVIL) = 'SOLTERO' THEN
                -- Primera y última letra
                v_letras_apellido := SUBSTR(r_emp.APPATERNO_EMP, 1, 1) || SUBSTR(r_emp.APPATERNO_EMP, -1);
                
            ELSIF UPPER(r_emp.NOMBRE_ESTADO_CIVIL) = 'VIUDO' THEN
                -- Antepenúltima (-3) y penúltima (-2) letra
                v_letras_apellido := SUBSTR(r_emp.APPATERNO_EMP, -3, 1) || SUBSTR(r_emp.APPATERNO_EMP, -2, 1);
                
            ELSIF UPPER(r_emp.NOMBRE_ESTADO_CIVIL) = 'SEPARADO' THEN
                -- Dos últimas letras
                v_letras_apellido := SUBSTR(r_emp.APPATERNO_EMP, -2);
                
            ELSE
                -- Por defecto
                v_letras_apellido := SUBSTR(r_emp.APPATERNO_EMP, 1, 2);
            END IF;

            -- Construcción final de la clave
            -- [PL/SQL DOCUMENTADA]: Concatenación de partes numéricas y texto formateado a minúsculas
            v_clave_usuario  := 
                SUBSTR(TO_CHAR(r_emp.NUMRUN_EMP), 3, 1) ||                   -- a) 3er dígito RUN
                (TO_NUMBER(TO_CHAR(r_emp.FECHA_NAC, 'YYYY')) + 2) ||         -- b) Año Nac + 2
                (TO_NUMBER(SUBSTR(TO_CHAR(r_emp.SUELDO_BASE), -3)) - 1) ||   -- c) Fin Sueldo - 1
                LOWER(v_letras_apellido) ||                                  -- d) Letras apellido (del IF)
                r_emp.ID_EMP ||                                              -- e) ID Empleado
                TO_CHAR(v_fecha_hoy, 'MMYYYY');                          -- f) MesAño Proceso

            --------------------------------------------------------
            -- LÓGICA 4: INSERTAR DATOS
            --------------------------------------------------------
            -- [SQL DOCUMENTADA]: Inserción en tabla final usando los valores calculados
            INSERT INTO USUARIO_CLAVE 
            (ID_EMP, NUMRUN_EMP, DVRUN_EMP, NOMBRE_EMPLEADO, NOMBRE_USUARIO, CLAVE_USUARIO)
            VALUES 
            (r_emp.ID_EMP, r_emp.NUMRUN_EMP, r_emp.DVRUN_EMP, v_nombre_completo, v_nombre_usuario , v_clave_usuario );

            -- Aumentar contador
            v_contador_exitos := v_contador_exitos + 1;

        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error procesando empleado ' || r_emp.ID_EMP || ': ' || SQLERRM);
        END;

    END LOOP; -- Fin del Cursor



-------------------------------------------------------------------------
    -- D. CIERRE DE TRANSACCIÓN
    -------------------------------------------------------------------------
    IF v_contador_exitos = v_total_esperado THEN
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('PROCESO FINALIZADO EXITOSAMENTE');
        DBMS_OUTPUT.PUT_LINE('Total empleados procesados e insertados: ' || v_contador_exitos);
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    ELSE
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: No se procesaron todos los registros. Se realizó Rollback.');
    END IF;

END;
/

-- CONSULTA FINAL PARA VERIFICAR RESULTADOS
SELECT * FROM USUARIO_CLAVE ORDER BY ID_EMP ASC;





