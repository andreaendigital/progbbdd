# 🏨 Sistema de Gestión y Cobranza PL/SQL - Hotel "La Última Oportunidad"

![Oracle](https://img.shields.io/badge/Oracle-F80000?style=for-the-badge&logo=oracle&logoColor=white)
![PL/SQL](https://img.shields.io/badge/PL%2FSQL-Advanced-blue)

Solución integral de base de datos desarrollada en **PL/SQL** para optimizar la gestión de cobranza, registro de consumos y emisión de informes del hotel "La Última Oportunidad", ubicado en San Pedro de Atacama. 

Este proyecto implementa lógica de negocio compleja mediante el uso de **Triggers, Packages, Funciones y Procedimientos Almacenados**, garantizando la integridad referencial y el manejo silencioso de errores.

## 📋 Tabla de Contenidos
- [Descripción del Proyecto](#-descripción-del-proyecto)
- [Reglas de Negocio Aplicadas](#-reglas-de-negocio-aplicadas)
- [Arquitectura de la Solución](#-arquitectura-de-la-solución)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Instrucciones de Ejecución](#-instrucciones-de-ejecución)
- [Pruebas y Validación](#-pruebas-y-validación)
- [Autora](#-autora)

## 📖 Descripción del Proyecto
El sistema original del hotel presentaba fallas en el registro y cálculo de los servicios consumidos por los huéspedes. Este proyecto rediseña la capa de base de datos para automatizar las siguientes áreas críticas:
1. **Sincronización en tiempo real:** Mantenimiento automático del total de consumos cada vez que se registra, actualiza o elimina un consumo individual.
2. **Cálculo de Cobranza:** Generación del estado de cuenta final de los huéspedes en el momento del *Check-out*, calculando alojamiento, minibares, tours y descuentos específicos por convenios con agencias.

## 💼 Reglas de Negocio Aplicadas
El motor de base de datos se encarga de procesar las siguientes reglas:
* Todos los valores base se manejan en **Dólares (USD)** y el resultado final se convierte a **Pesos Chilenos (CLP)** utilizando un tipo de cambio paramétrico.
* **Cobro por pasajeros:** Se aplica un cargo fijo de $35.000 CLP por persona alojada.
* **Descuentos Dinámicos:** * Descuento variable por rango de consumos según la tabla `TRAMOS_CONSUMOS`.
  * Descuento corporativo del 12% sobre el subtotal exclusivo para reservas provenientes de la agencia *"Viajes Alberti"*.
* **Manejo de Errores:** Errores de datos (ej. huéspedes sin agencia o sin registros de consumo) son capturados mediante `PRAGMA AUTONOMOUS_TRANSACTION` y guardados en una bitácora (`REG_ERRORES`) sin interrumpir la ejecución del proceso masivo.

## 🏗️ Arquitectura de la Solución
El proyecto está compuesto por los siguientes objetos PL/SQL:

* **Trigger DML (`trg_sincroniza_consumos`):** Trigger a nivel de fila (`FOR EACH ROW`) que detecta eventos `INSERT`, `UPDATE` y `DELETE` en la tabla `CONSUMO` para actualizar dinámicamente la tabla `TOTAL_CONSUMOS`.
* **Package (`pkg_hotel`):** Agrupa la lógica de cálculo de los tours consumidos por un huésped.
* **Funciones (`fn_get_agencia` y `fn_get_consumos`):** Subprogramas independientes con transacciones autónomas que recuperan información del huésped y capturan excepciones de forma silenciosa para auditoría.
* **Procedimiento Principal (`sp_generar_cobros`):** Orquesta todo el flujo, realiza iteraciones mediante cursores agrupados (para evitar errores ORA-00001), aplica la matemática del negocio, redondea valores y puebla la tabla final `DETALLE_DIARIO_HUESPEDES`.

## 🛠️ Tecnologías Utilizadas
* **Base de Datos:** Oracle Database (Compatible con Oracle 11g / 12c / 19c / 21c / XE y Oracle Cloud).
* **Lenguaje:** SQL y PL/SQL.
* **Herramienta de Desarrollo:** Oracle SQL Developer.

## 🚀 Instrucciones de Ejecución
Para desplegar esta solución en un entorno local o de desarrollo, sigue estos pasos en orden estricto para evitar errores de dependencia:

1. **Preparación del Entorno (DDL y DML Base):**
   Ejecuta el script de creación de tablas y poblado de datos provisto en el proyecto (`Script_prueba3_FC.sql`) entregado por docente.

2. **Compilación de la Solución:**
   Abre el script principal de la solución y compila los objetos en el siguiente orden:
   * **Paso 1:** Crear el Trigger `trg_sincroniza_consumos`.
   * **Paso 2:** Crear la especificación y el cuerpo del paquete `pkg_hotel`.
   * **Paso 3:** Crear las funciones `fn_get_agencia` y `fn_get_consumos`.
   * **Paso 4:** Crear el procedimiento principal `sp_generar_cobros`.

## 🧪 Pruebas y Validación
Puedes validar el funcionamiento del sistema ejecutando el siguiente bloque anónimo en la consola de SQL Developer (Asegúrate de activar la salida DBMS con `SET SERVEROUTPUT ON;`):

```sql
BEGIN
    -- Generar cobros para la fecha 18/08/2021 con un dólar a $915 CLP
    sp_generar_cobros(TO_DATE('18/08/2021', 'DD/MM/YYYY'), 915);
END;
/

## 🧪 CONSULTA DE VALIDACIÓN

-- Revisar los cálculos finales y aplicación de descuentos:
SELECT * FROM detalle_diario_huespedes ORDER BY id_huesped;

-- Verificar la captura silenciosa de excepciones:
SELECT * FROM reg_errores;


## Visuales:

Comprobando informes luego de ejecución de procedimientos:

