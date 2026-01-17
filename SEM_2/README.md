# Proyecto PL/SQL: Generación de Credenciales - Truck Rental

Este repositorio contiene la solución técnica para el caso de negocio "Truck Rental", enfocado en la construcción de un bloque PL/SQL para la generación masiva y segura de credenciales de usuarios (Nombre de Usuario y Contraseña) para los empleados de la empresa.

## 📋 Contexto del Proyecto

La empresa TRUCK RENTAL requiere mejorar sus estándares de seguridad. Actualmente, los accesos son genéricos por área. El objetivo es migrar a un sistema donde cada empleado tenga credenciales únicas generadas paramétricamente, permitiendo auditoría y control de acceso individual.

Objetivo Principal: Implementar un Bloque PL/SQL Anónimo que procese la nómina de empleados, calcule sus credenciales basándose en reglas de negocio complejas y almacene los resultados en una tabla de auditoría (USUARIO_CLAVE).

## ⚙️ Requerimientos de Negocio

La generación de datos debe cumplir con las siguientes reglas estrictas de transformación de datos:

1. Generación de Nombre de Usuario
El formato debe ser la concatenación de:

Primera letra del estado civil (minúscula).

Tres primeras letras del primer nombre.

Largo del primer nombre.

Un asterisco (*).

Último dígito del sueldo base.

Dígito verificador del RUN.

Años trabajados en la empresa.

Condición especial: Si lleva menos de 10 años, agregar una 'X' al final.

2. Generación de Clave (Contraseña)
El formato debe ser la concatenación de:

Tercer dígito del RUN.

Año de nacimiento + 2.

Últimos 3 dígitos del sueldo base - 1.

Letras del Apellido (Lógica condicional):

Casado / AUC: Dos primeras letras.

Soltero / Divorciado: Primera y última letra.

Viudo: Antepenúltima y penúltima letra.

Separado: Dos últimas letras.

ID del empleado.

Mes y Año de la fecha de proceso (paramétrica).

Todo el bloque de letras debe ir en minúsculas.

---

## 🛠️ Implementación Técnica
La solución fue desarrollada en Oracle PL/SQL utilizando las siguientes estrategias:

Estrategia de Iteración: Uso de Cursor Explícito (CURSOR c_empleados IS...) con ciclo FOR automatizado. Esto optimiza la memoria y evita errores de "No Data Found" en secuencias discontinuas.

Manejo de Fechas: Uso de Variables Bind (:b_fecha_proceso) para evitar fechas "hardcodeadas" y permitir la ejecución simulada en cualquier fecha.

Cálculo de Antigüedad: Función TRUNC(MONTHS_BETWEEN(...)/12) para precisión exacta en años.

Lógica Condicional: Estructura IF - ELSIF - ELSE para manejar las variaciones complejas del Estado Civil, normalizando los datos con UPPER para comparaciones robustas.

Transaccionalidad: Control de transacciones con COMMIT solo si el total de registros procesados coincide con el total esperado; de lo contrario, ROLLBACK.

Manejo de Errores: Bloques BEGIN-EXCEPTION-END anidados para asegurar que un error en un empleado no detenga el procesamiento de los demás.

---

## Estructura de Datos (Insumos)
El script trabaja sobre el modelo de datos provisto en Script_prueba1_C.sql.

Tablas Fuente: EMPLEADO, ESTADO_CIVIL.

Tabla Destino: USUARIO_CLAVE.

Nota: Se detectó que la columna de descripción en la tabla ESTADO_CIVIL se denomina NOMBRE_ESTADO_CIVIL (no DESC_ESTADO_CIVIL), ajuste que fue incorporado en la solución final.

---

## 🚀 Instrucciones de Ejecución
Para ejecutar este proyecto en Oracle SQL Developer:

Preparar el Entorno: Ejecutar el script de creación de tablas (Script_prueba1_C.sql) para poblar la base de datos.

Limpiar y Configurar: Ejecutar las líneas de limpieza y definición de variable Bind (seleccionar y presionar F5 o "Ejecutar Script"):

TRUNCATE TABLE USUARIO_CLAVE;
VARIABLE b_fecha_proceso VARCHAR2(10);
EXEC :b_fecha_proceso := TO_CHAR(SYSDATE, 'DD/MM/YYYY');

Ejecutar el Bloque: Copiar el bloque PL/SQL completo, seleccionarlo todo y ejecutar como Script (F5).

Verificar Resultados: Consultar la tabla de salida:

SELECT * FROM USUARIO_CLAVE ORDER BY ID_EMP ASC;

## 🚀 Resultados Logrados
Al finalizar la ejecución, el sistema entrega:

Una tabla USUARIO_CLAVE poblada con todos los empleados del rango (100 a 320).

Nombres de usuario y claves generados dinámicamente según las reglas del negocio.

Mensaje en consola (DBMS_OUTPUT) confirmando el éxito de la transacción y la cantidad de filas procesadas.

Ejemplo de salida de consola:

--------------------------------------------------
PROCESO FINALIZADO EXITOSAMENTE
Total empleados procesados e insertados: 23
--------------------------------------------------



## Visuales:

















