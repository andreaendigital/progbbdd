
# Resolución Caso Sumativa 2: Sistema de Aportes SBIF - ALL THE BEST
## Descripción del Proyecto

Este proyecto implementa un motor de procesamiento masivo de datos desarrollado en PL/SQL para la empresa de retail ALL THE BEST. El objetivo es automatizar el cálculo de aportes obligatorios a la Superintendencia de Bancos e Instituciones Financieras (SBIF) derivados de las transacciones de "Avances" y "Súper Avances" en efectivo.

El sistema extrae transacciones anuales de forma paramétrica, calcula porcentajes de aporte basados en tramos legales y genera dos reportes mandatorios: un detalle transaccional y un resumen mensual totalizado.

## 🛠️ Tecnologías Utilizadas
Base de Datos: Oracle Database

Lenguaje: PL/SQL (Bloques Anónimos)

Herramienta: Oracle SQL Developer

## 🚀 Requerimientos Técnicos Implementados

La solución cumple estrictamente con los siguientes estándares de desarrollo:

1. Estructuras de Memoria:

- VARRAY: Utilizado para gestionar de forma dinámica los nombres de los tipos de transacciones de tarjeta.
- Registro (RECORD): Definición de una estructura personalizada para manipular filas de transacciones de manera eficiente.

2. Manejo de Cursores:
- Cursor Explícito: Para la recuperación de registros detallados.
- Cursor Parametrizado: Implementado para la generación del resumen mensual, permitiendo la reutilización lógica.

3. Lógica Procedimental:
- Cálculo de aportes realizado íntegramente en PL/SQL mediante sentencias aritméticas y de control.
- Uso de SQL Dinámico (EXECUTE IMMEDIATE) para el truncado de tablas en tiempo de ejecución.
- Validación de consistencia mediante contadores de iteraciones vs. registros totales antes de ejecutar el COMMIT.

## ⚠️ Estrategia de Manejo de Excepciones
Se implementó un esquema de captura de errores jerárquico para asegurar la integridad de los datos:

- Predefinida (NO_DATA_FOUND): Gestiona la búsqueda de tramos impositivos.
- No Predefinida (ORA-02291): Captura violaciones de integridad referencial vinculadas a claves foráneas inexistentes mediante PRAGMA EXCEPTION_INIT.
- Definida por el Usuario (ex_monto_fuera_rango): Se dispara mediante RAISE cuando una transacción no cumple con los criterios de negocio (montos fuera de tramos legales), forzando un ROLLBACK de la transacción.


## Configuración y Ejecución

1. Ejecutar el script de base de datos Script_Sumativa2.sql para poblar el modelo.

2. Configurar la variable BIND de periodo:
  VARIABLE b_periodo NUMBER;
  EXEC :b_periodo := 2026;

3. Ejecutar el bloque PL/SQL anónimo.




## Visuales:

Evidencia de Excepción: 

<img width="598" height="66" alt="Captura de pantalla 2026-02-09 122144" src="https://github.com/user-attachments/assets/fbbd4dcf-a3ea-43ee-8e4a-0d7251f961bb" />

Resultado de Tablas:

<img width="937" height="652" alt="Captura de pantalla 2026-02-09 122952" src="https://github.com/user-attachments/assets/ca07b977-bb02-4dd6-93e8-9537455b0b70" />


<img width="643" height="172" alt="Captura de pantalla 2026-02-09 122850" src="https://github.com/user-attachments/assets/b726b193-9f6c-40d3-9b07-656ed353c07e" />










