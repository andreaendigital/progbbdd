
# Gestión de Gastos Comunes y Morosidad (PL/SQL) - AINTEGRAEDI

## Descripción del Proyecto

Este proyecto contiene la solución de Base de Datos para el caso de negocio de la empresa AINTEGRAEDI. El objetivo es automatizar, mediante procedimientos almacenados en Oracle PL/SQL, la detección de departamentos morosos, el cálculo de multas y la generación de reportes de corte de suministros.

## 📋 Descripción del Caso
La empresa administra múltiples edificios y requiere un proceso mensual que:

Identifique los departamentos que no han pagado los gastos comunes del mes anterior.

Calcule multas según la reincidencia de la deuda (Reglas de Negocio).

Genere alertas de corte de agua y combustible.

Actualice los montos de multas en el sistema principal.

## Reglas de Negocio Implementadas

Periodo de Análisis: Se procesa el mes actual, validando los pagos del mes inmediatamente anterior.

Morosidad: Se considera moroso si no existe registro en la tabla PAGO_GASTO_COMUN.

Multas y Sanciones:

1 mes de deuda: Multa de 2 UF + "Aviso de corte".

>1 mes de deuda: Multa de 4 UF + "Corte programado" (fecha de pago actual).

## 🛠️ Requisitos Técnicos
Base de Datos Oracle (XE, Cloud o Enterprise).

Oracle SQL Developer o cliente similar.

Scripts de creación y población de tablas (crea_pobla_tabla_bd_AINTEGRAED.sql).

## 🚀 Instalación y Configuración
Sigue estos pasos para levantar el entorno de pruebas:

Crear Usuario:
- Ejecuta el script de creación de usuario con permisos de RESOURCE y CONNECT.

Poblar Base de Datos:
- Conéctate con el usuario creado y ejecuta el script principal:
- crea_pobla_tabla_bd_AINTEGRAED.sql
- Nota: Este script genera datos simulados para el año en curso (ej. 2026).


Compilar Procedimiento:
 - Ejecuta el script solucion_procedimiento.sql (el código PL/SQL PRC_PROCESAR_MOROSIDAD) para compilar la lógica en la base de datos.


## Ejecución y Pruebas
Dado que el script de población inserta datos "perfectos" (todos pagan), es necesario realizar una simulación manual para ver los resultados del reporte de morosidad.

- Paso 1: Identificar el Periodo
Verifica en qué año/mes quedaron guardados los datos:

SELECT MAX(anno_mes_pcgc) FROM GASTO_COMUN;
-- Resultado típico: 202605 (Mayo 2026)

- Paso 2: Simular Morosos (Borrar Pagos)
Para que el reporte genere datos idénticos al requerimiento (Figura 1 y 2), elimina los pagos de los departamentos objetivo en el mes anterior (ej. Abril 202604):

DELETE FROM PAGO_GASTO_COMUN 
WHERE anno_mes_pcgc = 202604 -- Ajustar año si es necesario
AND (
    (id_edif = 40 AND nro_depto IN (20, 30)) OR
    (id_edif = 20 AND nro_depto IN (503, 509, 510, 602, 603)) OR
    (id_edif = 30 AND nro_depto IN (503)) OR
    (id_edif = 50 AND nro_depto IN (503, 1005, 1101)) OR
    (id_edif = 60 AND nro_depto IN (503, 1101, 1104))
);
COMMIT;

- Paso 3: Ejecutar el Procedimiento
Ejecuta el procedimiento indicando el periodo actual (Mayo) y el valor de la UF.

-- Parámetros: (Periodo_Actual, Valor_UF)
EXEC PRC_PROCESAR_MOROSIDAD(202605, 29509);


📊 Verificación de Resultados
Una vez ejecutado el proceso, consulta las tablas para validar la información:

Reporte de Morosos (Simula Figura 1):

SELECT * FROM GASTO_COMUN_PAGO_CERO ORDER BY id_edif, nro_depto;

Multas Aplicadas (Simula Figura 2):

SELECT * FROM GASTO_COMUN 
WHERE anno_mes_pcgc = 202605 AND multa_gc > 0
ORDER BY id_edif, nro_depto;


## Visuales:

Comprobando informes luego de ejecución de procedimientos:

<img width="1246" height="746" alt="Captura de pantalla 2026-02-16 131955" src="https://github.com/user-attachments/assets/84bef6c8-d38d-4747-8a22-abe8d10cd8ec" />

<img width="698" height="629" alt="Captura de pantalla 2026-02-16 131931" src="https://github.com/user-attachments/assets/def3cf54-c15f-4734-8a07-4ba902dd15d8" />







