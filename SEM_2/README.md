
# 🚛 Proyecto PL/SQL: Generación de Credenciales - Truck Rental

Este proyecto consiste en el desarrollo de una solución PL/SQL para la empresa **TRUCK RENTAL**. El objetivo es automatizar la creación de credenciales de acceso (usuario y contraseña) para los empleados, mejorando los estándares de seguridad y auditoría de la compañía.

## 📋 Contexto del Negocio

Actualmente, los empleados utilizan usuarios genéricos por área. Para mejorar la seguridad, se requiere un proceso paramétrico que genere accesos únicos basados en la información personal y contractual de cada trabajador.

**Objetivo:** Construir un bloque PL/SQL anónimo que procese la información desde las tablas maestras y pueble la tabla de auditoría `USUARIO_CLAVE`.

## ⚙️ Requerimientos y Reglas de Negocio

El sistema aplica reglas estrictas de transformación de datos para generar las credenciales:

### 1. Formato de Nombre de Usuario
Se construye concatenando:
* Primera letra del estado civil (minúscula).
* Tres primeras letras del primer nombre.
* Largo del primer nombre.
* Un asterisco (`*`).
* Último dígito del sueldo base.
* Dígito verificador del RUN.
* Años trabajados (calculados con precisión).
* **Condición:** Si la antigüedad es menor a 10 años, se agrega una `'X'` al final.

### 2. Formato de Clave (Contraseña)
Se construye concatenando:
* Tercer dígito del RUN.
* Año de nacimiento sumado en 2.
* Los tres últimos dígitos del sueldo base disminuidos en 1.
* **Letras del Apellido Paterno (Lógica Condicional):**
  * *Casado / AUC:* Dos primeras letras.
  * *Soltero / Divorciado:* Primera y última letra.
  * *Viudo:* Antepenúltima y penúltima letra.
  * *Separado:* Dos últimas letras.
* ID del empleado.
* Mes y Año de la fecha de proceso (formato MMYYYY).

---

## 🛠️ Implementación Técnica

La solución fue desarrollada en **Oracle PL/SQL** implementando las siguientes características:

* **Cursor Explícito (`FOR LOOP`):** Se utiliza un cursor para iterar de manera eficiente sobre el rango de empleados (IDs 100 a 320), manejando automáticamente los saltos en la secuencia de IDs.
* **Variables Bind:** Uso de `:b_fecha_proceso` para inyectar la fecha de ejecución externamente, evitando fechas fijas en el código.
* **Manejo de Fechas:** Cálculo de antigüedad utilizando `TRUNC(MONTHS_BETWEEN(...)/12)`.
* **Control de Flujo:** Reemplazo de `CASE` por estructura `IF-ELSIF-ELSE` para manejar lógica compleja de estados civiles (normalizados con `UPPER`).
* **Transaccionalidad:** Validación final mediante `COUNT`. Se ejecuta `COMMIT` solo si el total de registros insertados coincide con el total de empleados leídos; de lo contrario, se ejecuta `ROLLBACK`.

## 📂 Archivos del Proyecto

* **`Script_prueba1_C.sql`**: Script base proporcionado que crea y puebla las tablas (`EMPLEADO`, `ESTADO_CIVIL`, etc.).
* **`Solucion_Bloque_PLSQL.sql`**: El bloque anónimo desarrollado que contiene la lógica del negocio.

## 🚀 Instrucciones de Ejecución (Oracle SQL Developer)

Sigue estos pasos para probar la solución:

### 1. Preparación de la Base de Datos
Ejecuta el script `Script_prueba1_C.sql` para crear las tablas y secuencias necesarias.

### 2. Configuración Inicial
Antes de correr el bloque principal, limpia la tabla de destino y define la variable de fecha:

```sql
TRUNCATE TABLE USUARIO_CLAVE;
VARIABLE b_fecha_proceso VARCHAR2(10);
EXEC :b_fecha_proceso := TO_CHAR(SYSDATE, 'DD/MM/YYYY');

```

### 3. Ejecución del Proceso

Ejecuta el bloque PL/SQL completo. Asegúrate de tener activada la salida de script (`SET SERVEROUTPUT ON`) para ver los mensajes de depuración.

### 4. Verificación

Consulta la tabla de resultados para validar la generación de credenciales:

```sql
SELECT * FROM USUARIO_CLAVE ORDER BY ID_EMP ASC;

```

## ✅ Resultado Esperado

Al finalizar, el sistema mostrará en la consola DBMS un mensaje de éxito indicando la cantidad de registros procesados. La tabla `USUARIO_CLAVE` contendrá una fila por cada empleado procesado con su usuario y clave generados dinámicamente según las reglas descritas.





## Visuales:

















