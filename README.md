# 📚 Caso BANK SOLUTION: bloque PL/SQL anónimo simple.

Este repositorio contiene la solución a la actividad práctica de PL/SQL para el caso de negocio "Bank Solutions". El objetivo es desarrollar bloques anónimos simples para la automatización de procesos bancarios utilizando Oracle Database.

## 📋 Descripción del Proyecto

Se desarrollan soluciones lógicas para dos requerimientos del banco:
1.  **Cálculo de beneficios:** Programa de puntos "Pesos TODOSUMA".
2.  **Gestión de créditos:** Proceso de postergación de cuotas.

Ambos casos implementan el uso de variables Bind (paramétricas), manejo de fechas dinámicas (`EXTRACT`, `ADD_MONTHS`) y estructuras de control (`IF/ELSE`).

## ⚙️ Pre-requisitos e Instalación

Para ejecutar los scripts de solución, se debe preparar el entorno de base de datos en el siguiente orden:

1.  **Crear Usuario:** Ejecutar el script `crea_usuario_ PRACT1_PRY2206.sql` con un usuario administrador (SYSTEM/SYS).
2.  **Poblar Tablas:** Conectarse con el usuario creado (`PRY2206_P1`) y ejecutar `crea_pobla_tablas_bd_BANK_SOLUTIONS.sql`.

---

## 🚀 Caso 1: Programa de Pesos TODOSUMA

**Objetivo:**
Calcular y almacenar los puntos ("pesos") ganados por un cliente basándose en los créditos solicitados durante el **año anterior** a la ejecución del proceso.

**Lógica Implementada:**
* Se solicita el RUT del cliente y los valores de los pesos (normales y extras por tramo) como parámetros.
* Calcula dinámicamente el año anterior (`SYSDATE - 1`).
* **Regla de Negocio:**
    * Base: Asigna un monto por cada $100.000 solicitados.
    * Extra: Si el cliente es "Trabajador Independiente", se asignan pesos adicionales según el tramo del monto total.
* **Salida:** Inserta el cálculo final en la tabla `CLIENTE_TODOSUMA`.

---

## 🚀 Caso 2: Postergación de Cuotas

**Objetivo:**
Automatizar la reprogramación de deudas, permitiendo a un cliente postergar 1 o 2 cuotas de un crédito vigente.

**Lógica Implementada:**
* Se solicitan como parámetros el Cliente, la Solicitud de Crédito y la cantidad de cuotas a postergar (1 o 2).
* Identifica la última cuota vigente para generar las siguientes correlativas (N+1, N+2).
* Calcula las nuevas fechas de vencimiento usando `ADD_MONTHS`.
* **Tasas de Interés:** Aplica tasas fijas según el tipo de crédito (Hipotecario, Consumo o Automotriz).
* **Beneficio de Condonación:** Si el cliente solicitó más de un crédito el año anterior, se marca la última cuota original como "Pagada" (Condonada).
* **Salida:** Inserta registros y actualiza la tabla `CUOTA_CREDITO_CLIENTE`.

---

## 🛠️ Tecnologías

* Oracle PL/SQL
* SQL Developer (para ejecución y variables de sustitución `&`)

---
**Nota:** Los scripts están diseñados para ser ejecutados de forma individual por cliente, utilizando variables de sustitución para la entrada de datos.


## Visuales:

Caso 1:

Ingreso de Variables de Sustitución: 

<img width="712" height="300" alt="Captura de pantalla 2026-01-11 123008" src="https://github.com/user-attachments/assets/0ca6b4cc-c90d-4562-a2ae-b7b6670eba9d" />

<img width="707" height="301" alt="Captura de pantalla 2026-01-11 123017" src="https://github.com/user-attachments/assets/9e951423-e388-414c-9984-56e53417af5b" />

Ingreso de tabla CLIENTE_TODOSUMA 

<img width="1001" height="367" alt="Captura de pantalla 2026-01-11 123212" src="https://github.com/user-attachments/assets/7506c09d-d645-4612-bf37-fc7ce367797b" />

Salida DBMS
<img width="446" height="188" alt="Captura de pantalla 2026-01-11 123107" src="https://github.com/user-attachments/assets/0d1c092f-63f3-4984-b3bb-5a3f7c237a3c" />



CASO 2:

Ingreso de Variables de Sustitución:


<img width="769" height="212" alt="Captura de pantalla 2026-01-11 151038" src="https://github.com/user-attachments/assets/ffd55e7b-98a3-4891-9749-83085143a658" />

<img width="504" height="174" alt="Captura de pantalla 2026-01-11 151054" src="https://github.com/user-attachments/assets/28250904-2f7e-40a9-9565-906eda1b239d" />

<img width="464" height="170" alt="Captura de pantalla 2026-01-11 151103" src="https://github.com/user-attachments/assets/32226d12-308b-43fa-bf00-e59a66e2e809" />

Salidas de DBMS

<img width="383" height="180" alt="Captura de pantalla 2026-01-11 151112" src="https://github.com/user-attachments/assets/45aa19f7-3814-4ebf-84f1-5785109426f7" />


Resultado Crédito 2004

<img width="863" height="79" alt="Captura de pantalla 2026-01-11 151804" src="https://github.com/user-attachments/assets/b8873912-1dc9-4458-bb77-c0093f3c74c4" />

Resultado Crédito 3004

<img width="866" height="81" alt="Captura de pantalla 2026-01-11 151824" src="https://github.com/user-attachments/assets/fe2082f6-fdf5-4e86-806d-6bebd5968b6a" />

Resultado Credito 2001

<img width="865" height="101" alt="Captura de pantalla 2026-01-11 151844" src="https://github.com/user-attachments/assets/49236e33-b1d8-4181-be8d-8e1c03a6847c" />


















