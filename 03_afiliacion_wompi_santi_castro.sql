-- ============================================================
-- 1. Comercios base (última partición de wompi_merchants)
-- ============================================================

DROP TABLE IF EXISTS {zona_p1}.wompi_comercios_base;

CREATE TABLE {zona_p1}.wompi_comercios_base
STORED AS PARQUET TBLPROPERTIES ("transactional" = "false") AS

SELECT
    substr(cast(mer.creado as string), 1, 6) as periodo,
    mer.id_comercio,
    mer.nombre_comercio,
    mer.nombre_legal,
    mer.documento_identidad,
    mer.tipo_documento,
    mer.telefono,
    mer.correo_electronico,
    mer.tipo_cuenta,
    mer.plan_dispersion,
    mer.modelo,
    -- mer.codigo_asesor,
    mer.activo,
    mer.cod_ciudad,
    mer.cod_departamento,
    mer.ciudad,
    mer.departamento,
    mer.ciiu,
    mer.descripcion_act_econ,
    mer.monto_limite_diario,
    mer.monto_limite_transaccional,
    mer.desembolsos_permitidos,
    mer.fuentes_pago_habilitadas,
    -- CAST(from_unixtime(mer.creado)           AS DATE) AS fecha_creacion_comercio,
    -- CAST(from_unixtime(mer.prim_ingreso_app) AS DATE) AS fecha_prim_ingreso_app,
    -- CAST(from_unixtime(mer.ult_ingreso_app)  AS DATE) AS fecha_ult_ingreso_app
    CASE WHEN mer.creado           = 0 THEN NULL ELSE CAST(to_timestamp(CAST(mer.creado           AS STRING), 'yyyyMMdd') AS DATE) END AS fecha_creacion_comercio,
    CASE WHEN mer.prim_ingreso_app = 0 THEN NULL ELSE CAST(to_timestamp(CAST(mer.prim_ingreso_app AS STRING), 'yyyyMMdd') AS DATE) END AS fecha_prim_ingreso_app,
    CASE WHEN mer.ult_ingreso_app  = 0 THEN NULL ELSE CAST(to_timestamp(CAST(mer.ult_ingreso_app  AS STRING), 'yyyyMMdd') AS DATE) END AS fecha_ult_ingreso_app

FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY id_comercio ORDER BY creado DESC) AS rn
    FROM resultados_wompi.wompi_merchants
    WHERE ingestion_year  = {wompim_year}
      AND ingestion_month = {wompim_month}
      AND ingestion_day   = {wompim_day}
) mer
WHERE mer.rn = 1
    AND UPPER(mer.desembolsos_permitidos) = 'SI'
    AND UPPER(mer.activo) = 'A'
    AND mer.modelo LIKE 'Agregador'
;

COMPUTE STATS {zona_p1}.wompi_comercios_base;

-- ============================================================
-- 2. Procedimientos base (última partición de wompi_businesses_procedures)
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_procedimientos_base;

CREATE TABLE {zona_p1}.wompi_procedimientos_base
STORED AS PARQUET TBLPROPERTIES ("transactional" = "false") AS

SELECT
    -- proc.id_comercio,
    -- MAX(proc.estado_comercio)                   AS estado_comercio,
    -- MAX(proc.codigo_asesor)                     AS codigo_asesor,
    -- MAX(proc.nombre_procedimiento)              AS ultimo_proc,
    -- MAX(proc.estado_procedimiento)              AS estado_ultimo_proc,
    -- MAX(proc.fecha_actualizacion_procedimiento) AS fecha_ult_actualizacion_proc,
    -- MAX(proc.fecha_creacion_procedimiento)      AS fecha_inicio_procedimiento
    id_comercio,
    codigo_asesor,
    estado_comercio,
    cast (fecha_actualizacion_procedimiento/100 as bigint) as fecha_actualizacion_procedimiento,
    nombre_procedimiento
FROM resultados_wompi.wompi_businesses_procedures proc
WHERE proc.ingestion_year  = {wompibp_year}
  AND proc.ingestion_month = {wompibp_month}
  AND proc.ingestion_day   = {wompibp_day}
    AND proc.nombre_procedimiento IN (
        "Validación identidad - Persona VTP",
        "Validación identidad - Empresa VTP",
        "Validación identidad - Persona",
        "Validación identidad - Empresa"
    )
    AND proc.estado_comercio = 'Activo con desembolsos'
-- GROUP BY proc.id_comercio
;

COMPUTE STATS {zona_p1}.wompi_procedimientos_base;

DROP TABLE IF EXISTS {zona_p1}.ult_wompi_procedimientos_base;

CREATE TABLE {zona_p1}.ult_wompi_procedimientos_base
STORED AS PARQUET TBLPROPERTIES ("transactional" = "false") AS

SELECT
    proc.id_comercio,
    MAX(proc.estado_comercio)                   AS estado_comercio,
    MAX(proc.codigo_asesor)                     AS codigo_asesor,
    MAX(proc.nombre_procedimiento)              AS ultimo_proc,
    MAX(proc.estado_procedimiento)              AS estado_ultimo_proc,
    MAX(proc.fecha_actualizacion_procedimiento) AS fecha_ult_actualizacion_proc,
    MAX(proc.fecha_creacion_procedimiento)      AS fecha_inicio_procedimiento
FROM resultados_wompi.wompi_businesses_procedures proc
WHERE proc.ingestion_year  = {wompibp_year}
  AND proc.ingestion_month = {wompibp_month}
  AND proc.ingestion_day   = {wompibp_day}
GROUP BY proc.id_comercio
;

COMPUTE STATS {zona_p1}.ult_wompi_procedimientos_base;

-- ============================================================
-- 3. Payment identities resumen (última partición de wompi_payment_identities)
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_payment_identities_resumen;

CREATE TABLE {zona_p1}.wompi_payment_identities_resumen
STORED AS PARQUET TBLPROPERTIES ("transactional" = "false") AS

SELECT
    pi.id_comercio,
    MAX(pi.codigo_unico) AS codigo_unico,
    SUM(CASE WHEN UPPER(TRIM(pi.identidad_activa)) = 'TRUE'  THEN 1 ELSE 0 END) AS identidades_activas,

    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'DAVIPLATA'                THEN 1 ELSE 0 END) AS flag_daviplata,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'TARJETA DE CREDITO'                  THEN 1 ELSE 0 END) AS flag_tarjeta,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'SU+ PAY'                  THEN 1 ELSE 0 END) AS flag_su_pay,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'TARJETAS VENTA PRESENTE'  THEN 1 ELSE 0 END) AS flag_tarjeta_venta_presente,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'PUNTOS COLOMBIA'          THEN 1 ELSE 0 END) AS flag_puntos_colombia,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'NEQUI'                    THEN 1 ELSE 0 END) AS flag_nequi,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'BANCOLOMBIA BUY NOW PAY L' THEN 1 ELSE 0 END) AS flag_bcol_bnpl,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'BOTON BANCOLOMBIA'        THEN 1 ELSE 0 END) AS flag_boton_bancolombia,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'FISERV'                   THEN 1 ELSE 0 END) AS flag_fiserv,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'DATAFONO VENTA PRESENTE'  THEN 1 ELSE 0 END) AS flag_datafono_venta_presente,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'CORRESPONSAL BANCARIO'    THEN 1 ELSE 0 END) AS flag_corresponsal_bancario,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'QR BANCOLOMBIA'           THEN 1 ELSE 0 END) AS flag_qr_bancolombia,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'TOKENBOX'                 THEN 1 ELSE 0 END) AS flag_tokenbox,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'CREDIBANCO'               THEN 1 ELSE 0 END) AS flag_credibanco,
    MAX(CASE WHEN UPPER(TRIM(medio_pago)) = 'PSE'                      THEN 1 ELSE 0 END) AS flag_pse,

    --MAX(CAST(from_unixtime(pi.identidad_creada) AS DATE)) AS fecha_primera_identidad
      MAX(CASE WHEN pi.identidad_creada = 0 THEN NULL ELSE CAST(to_timestamp(CAST(pi.identidad_creada AS STRING), 'yyyyMMdd') AS DATE) END) AS fecha_primera_identidad

FROM resultados_wompi.wompi_payment_identities pi
WHERE pi.ingestion_year  = {wompipi_year}
  AND pi.ingestion_month = {wompipi_month}
  AND pi.ingestion_day   = {wompipi_day}
GROUP BY pi.id_comercio
;

COMPUTE STATS {zona_p1}.wompi_payment_identities_resumen;

-- ============================================================
-- 4. Transacciones filtradas (aprobadas desde 2025)
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_transacciones_filtradas;

CREATE TABLE {zona_p1}.wompi_transacciones_filtradas
STORED AS PARQUET TBLPROPERTIES ("transactional" = "false") AS

SELECT
    trx.id_comercio,
    UPPER(TRIM(trx.medio_pago)) AS medio_pago,
    UPPER(TRIM(trx.franquicia)) AS franquicia,
    -- CAST(trx.fecha_creacion_transaccion AS BIGINT) AS f_trx
    CASE WHEN trx.fecha_creacion_transaccion = 0 THEN NULL ELSE CAST(to_timestamp(CAST(trx.fecha_creacion_transaccion AS STRING), 'yyyyMMdd') AS DATE) END AS f_trx

FROM resultados_wompi.wompi_transactions trx
WHERE UPPER(TRIM(trx.estado_transaccion)) = 'APROBADA'
;

COMPUTE STATS {zona_p1}.wompi_transacciones_filtradas;

-- ============================================================
-- 5. Transacciones resumen por comercio
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_transacciones_resumen;

CREATE TABLE {zona_p1}.wompi_transacciones_resumen
STORED AS PARQUET TBLPROPERTIES ("transactional" = "false") AS

SELECT
    b.id_comercio,
    -- Por franquicia (tarjetas)
    MIN(CASE WHEN UPPER(TRIM(t.franquicia)) = 'MASTERCARD' THEN t.f_trx END) AS fecha_primera_trx_mc,
    MAX(CASE WHEN UPPER(TRIM(t.franquicia)) = 'MASTERCARD' THEN t.f_trx END) AS fecha_ultima_trx_mc,
    MIN(CASE WHEN UPPER(TRIM(t.franquicia)) = 'VISA'       THEN t.f_trx END) AS fecha_primera_trx_visa,
    MAX(CASE WHEN UPPER(TRIM(t.franquicia)) = 'VISA'       THEN t.f_trx END) AS fecha_ultima_trx_visa,
    MIN(CASE WHEN UPPER(TRIM(t.franquicia)) = 'AMEX'       THEN t.f_trx END) AS fecha_primera_trx_amex,
    MAX(CASE WHEN UPPER(TRIM(t.franquicia)) = 'AMEX'       THEN t.f_trx END) AS fecha_ultima_trx_amex,
    -- Por medio de pago
    MIN(CASE WHEN t.medio_pago = 'DAVIPLATA'                 THEN t.f_trx END) AS fecha_primera_trx_daviplata,
    MAX(CASE WHEN t.medio_pago = 'DAVIPLATA'                 THEN t.f_trx END) AS fecha_ultima_trx_daviplata,
    MIN(CASE WHEN t.medio_pago = 'TARJETA DE CREDITO'                   THEN t.f_trx END) AS fecha_primera_trx_tarjeta,
    MAX(CASE WHEN t.medio_pago = 'TARJETA DE CREDITO'                   THEN t.f_trx END) AS fecha_ultima_trx_tarjeta,
    MIN(CASE WHEN t.medio_pago = 'SU+ PAY'                   THEN t.f_trx END) AS fecha_primera_trx_su_pay,
    MAX(CASE WHEN t.medio_pago = 'SU+ PAY'                   THEN t.f_trx END) AS fecha_ultima_trx_su_pay,
    MIN(CASE WHEN t.medio_pago = 'TARJETAS VENTA PRESENTE'   THEN t.f_trx END) AS fecha_primera_trx_tarjeta_vp,
    MAX(CASE WHEN t.medio_pago = 'TARJETAS VENTA PRESENTE'   THEN t.f_trx END) AS fecha_ultima_trx_tarjeta_vp,
    MIN(CASE WHEN t.medio_pago = 'PUNTOS COLOMBIA'           THEN t.f_trx END) AS fecha_primera_trx_puntos_col,
    MAX(CASE WHEN t.medio_pago = 'PUNTOS COLOMBIA'           THEN t.f_trx END) AS fecha_ultima_trx_puntos_col,
    MIN(CASE WHEN t.medio_pago = 'NEQUI'                     THEN t.f_trx END) AS fecha_primera_trx_nequi,
    MAX(CASE WHEN t.medio_pago = 'NEQUI'                     THEN t.f_trx END) AS fecha_ultima_trx_nequi,
    MIN(CASE WHEN t.medio_pago = 'BANCOLOMBIA BUY NOW PAY L' THEN t.f_trx END) AS fecha_primera_trx_bcol_bnpl,
    MAX(CASE WHEN t.medio_pago = 'BANCOLOMBIA BUY NOW PAY L' THEN t.f_trx END) AS fecha_ultima_trx_bcol_bnpl,
    MIN(CASE WHEN t.medio_pago = 'BOTON BANCOLOMBIA'         THEN t.f_trx END) AS fecha_primera_trx_boton_bcol,
    MAX(CASE WHEN t.medio_pago = 'BOTON BANCOLOMBIA'         THEN t.f_trx END) AS fecha_ultima_trx_boton_bcol,
    MIN(CASE WHEN t.medio_pago = 'FISERV'                    THEN t.f_trx END) AS fecha_primera_trx_fiserv,
    MAX(CASE WHEN t.medio_pago = 'FISERV'                    THEN t.f_trx END) AS fecha_ultima_trx_fiserv,
    MIN(CASE WHEN t.medio_pago = 'DATAFONO VENTA PRESENTE'   THEN t.f_trx END) AS fecha_primera_trx_datafono_vp,
    MAX(CASE WHEN t.medio_pago = 'DATAFONO VENTA PRESENTE'   THEN t.f_trx END) AS fecha_ultima_trx_datafono_vp,
    MIN(CASE WHEN t.medio_pago = 'CORRESPONSAL BANCARIO'     THEN t.f_trx END) AS fecha_primera_trx_corr_ban,
    MAX(CASE WHEN t.medio_pago = 'CORRESPONSAL BANCARIO'     THEN t.f_trx END) AS fecha_ultima_trx_corr_ban,
    MIN(CASE WHEN t.medio_pago = 'QR BANCOLOMBIA'            THEN t.f_trx END) AS fecha_primera_trx_qr_bcol,
    MAX(CASE WHEN t.medio_pago = 'QR BANCOLOMBIA'            THEN t.f_trx END) AS fecha_ultima_trx_qr_bcol,
    MIN(CASE WHEN t.medio_pago = 'TOKENBOX'                  THEN t.f_trx END) AS fecha_primera_trx_tokenbox,
    MAX(CASE WHEN t.medio_pago = 'TOKENBOX'                  THEN t.f_trx END) AS fecha_ultima_trx_tokenbox,
    MIN(CASE WHEN t.medio_pago = 'CREDIBANCO'                THEN t.f_trx END) AS fecha_primera_trx_credibanco,
    MAX(CASE WHEN t.medio_pago = 'CREDIBANCO'                THEN t.f_trx END) AS fecha_ultima_trx_credibanco,
    MIN(CASE WHEN t.medio_pago = 'PSE'                       THEN t.f_trx END) AS fecha_primera_trx_pse,
    MAX(CASE WHEN t.medio_pago = 'PSE'                       THEN t.f_trx END) AS fecha_ultima_trx_pse,
    -- General
    MIN(t.f_trx)                 AS fecha_primera_trx_general,
    MAX(t.f_trx)                 AS fecha_ultima_trx_general,
    COUNT(*)                     AS trx_total,
    COUNT(DISTINCT t.medio_pago) AS medios_pago_utilizados,
    COUNT(DISTINCT t.franquicia) AS franquicias_utilizadas
FROM {zona_p1}.wompi_comercios_base b
LEFT JOIN {zona_p1}.wompi_transacciones_filtradas t
    ON b.id_comercio = t.id_comercio
GROUP BY b.id_comercio
;

COMPUTE STATS {zona_p1}.wompi_transacciones_resumen;

DROP TABLE IF EXISTS {zona_p1}.wompi_comercios_procedimientos;

CREATE TABLE {zona_p1}.wompi_comercios_procedimientos
STORED AS PARQUET TBLPROPERTIES ("transactional" = "false") AS
select
    a.periodo
    , a.id_comercio
    , a.documento_identidad
    , a.modelo
    , a.nombre_comercio
    , a.plan_dispersion
    , b.codigo_asesor
from {zona_p1}.wompi_comercios_base a
left join {zona_p1}.wompi_procedimientos_base b
on a.id_comercio = b.id_comercio
;

COMPUTE STATS {zona_p1}.wompi_comercios_procedimientos;

-- ============================================================
-- Intenciones
-- ============================================================
-- ============================================================
-- Base 1: intenciones
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_intenciones_5x;

CREATE TABLE {zona_p1}.wompi_intenciones_5x
STORED AS PARQUET
TBLPROPERTIES ("transactional" = "false") AS
SELECT
    num_doc,
    CAST(cod_ventas_gestion_val_planta AS STRING) AS cod_ventas,
    usuario_creacion AS usuario,
    nombre_usuario_creacion AS nombre_usuario,
    cargo_usuario_creacion AS cargo_usuario,
    CAST(fecha_gestion AS TIMESTAMP) AS f_gest,
    'intenciones' AS origen
FROM resultados_clientes_personas_y_pymes.fco_intenciones_y_gestiones_pymes_empresas_corporativo
WHERE cod_producto IN (1134, 723)
  AND cod_estado IN (2, 3);

COMPUTE STATS {zona_p1}.wompi_intenciones_5x;


-- ============================================================
-- Base 2: stoc
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_stoc_5x;

CREATE TABLE {zona_p1}.wompi_stoc_5x
STORED AS PARQUET
TBLPROPERTIES ("transactional" = "false") AS
SELECT
    num_doc,
    CAST(cod_ventas_val_planta AS STRING) AS cod_ventas,
    usuario_red AS usuario,
    nombre_user_gestion AS nombre_usuario,
    cargo_user_gestion AS cargo_usuario,
    CAST(f_gestion AS TIMESTAMP) AS f_gest,
    'stoc' AS origen
FROM resultados_clientes_personas_y_pymes.fco_gestion_oc_stoc_personas
WHERE cod_accion IN (114, 467, 6073)
  AND cod_estado IN (3, 4);

COMPUTE STATS {zona_p1}.wompi_stoc_5x;

-- ============================================================
-- Base 3: gestion
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_gestion_5x;

CREATE TABLE {zona_p1}.wompi_gestion_5x
STORED AS PARQUET
TBLPROPERTIES ("transactional" = "false") AS
SELECT
    num_doc,
    CAST(cod_ventas_user_creacion_planta AS STRING) AS cod_ventas,
    user_creacion AS usuario,
    nombre_user_creacion AS nombre_usuario,
    cargo_user_creacion AS cargo_usuario,
    CAST(f_gestion AS TIMESTAMP) AS f_gest,
    'gestion' AS origen
FROM resultados_clientes_personas_y_pymes.fco_gestion_intenciones_personas
WHERE cod_producto_detallado IN (135, 143)
  AND cod_estado IN (1, 3, 4);

COMPUTE STATS {zona_p1}.wompi_gestion_5x;

-- ============================================================
-- Union de fuentes
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_combinacion_intenciones_5x;

CREATE TABLE {zona_p1}.wompi_combinacion_intenciones_5x
STORED AS PARQUET
TBLPROPERTIES ("transactional" = "false") AS
SELECT
    num_doc,
    cod_ventas,
    usuario,
    nombre_usuario,
    cargo_usuario,
    f_gest,
    origen
FROM {zona_p1}.wompi_intenciones_5x
UNION ALL
SELECT
    num_doc,
    cod_ventas,
    usuario,
    nombre_usuario,
    cargo_usuario,
    f_gest,
    origen
FROM {zona_p1}.wompi_stoc_5x
UNION ALL
SELECT
    num_doc,
    cod_ventas,
    usuario,
    nombre_usuario,
    cargo_usuario,
    f_gest,
    origen
FROM {zona_p1}.wompi_gestion_5x;

COMPUTE STATS {zona_p1}.wompi_combinacion_intenciones_5x;


-- ============================================================
-- Orden y priorizacion
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_ordenado_5x;

CREATE TABLE {zona_p1}.wompi_ordenado_5x
STORED AS PARQUET
TBLPROPERTIES ("transactional" = "false") AS
SELECT
    num_doc,
    cod_ventas,
    usuario,
    nombre_usuario,
    cargo_usuario,
    f_gest,
    origen,
    ROW_NUMBER() OVER (
        PARTITION BY num_doc
        ORDER BY f_gest DESC, cod_ventas DESC
    ) AS rn
FROM {zona_p1}.wompi_combinacion_intenciones_5x;

COMPUTE STATS {zona_p1}.wompi_ordenado_5x;


-- ============================================================
-- Depuracion (1 registro por documento)
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_depuracion_5x;

CREATE TABLE {zona_p1}.wompi_depuracion_5x
STORED AS PARQUET
TBLPROPERTIES ("transactional" = "false") AS
SELECT
    num_doc,
    cod_ventas,
    usuario,
    nombre_usuario,
    cargo_usuario,
    f_gest,
    origen,
    'Accion comercial' AS fuente
FROM {zona_p1}.wompi_ordenado_5x
WHERE rn = 1;

COMPUTE STATS {zona_p1}.wompi_depuracion_5x;


-- ============================================================
-- Tabla final
-- ============================================================
DROP TABLE IF EXISTS {zona_p1}.wompi_intenciones_5x_final;

CREATE TABLE {zona_p1}.wompi_intenciones_5x_final
STORED AS PARQUET
TBLPROPERTIES ("transactional" = "false") AS
SELECT
    t0.id_comercio,
    t0.documento_identidad,
    t0.modelo,
    t0.nombre_comercio,
    t0.plan_dispersion,
    t0.codigo_asesor,
    t1.desc_segmento AS segmento,
    t1.desc_subsegmento AS subsegmento,
    t1.gerenciamiento AS marca_gerenciado,
    t2.cod_ventas,
    t2.usuario,
    t2.nombre_usuario,
    t2.cargo_usuario,
    t2.fuente,
    t2.origen,
    t0.periodo
FROM {zona_p1}.wompi_comercios_procedimientos t0
LEFT JOIN {zona_p1}.adq_5x_datos_clientes_mdm t1
    ON CAST(t0.documento_identidad AS BIGINT) = CAST(t1.num_doc AS BIGINT)
LEFT JOIN {zona_p1}.wompi_depuracion_5x t2
    ON CAST(t0.documento_identidad AS BIGINT) = CAST(t2.num_doc AS BIGINT);

COMPUTE STATS {zona_p1}.wompi_intenciones_5x_final;


-- ============================================================
-- 6. Tabla final
-- ============================================================
DROP TABLE IF EXISTS {zona_p3}.afiliaciones_wompi_final;

CREATE TABLE {zona_p3}.afiliaciones_wompi_final
STORED AS PARQUET TBLPROPERTIES ("transactional" = "false") AS

WITH planta AS (
SELECT *
FROM (
    SELECT
        cod_asesor,
        cod_cargo,
        descri_cargo,
        descri_zona,
        descri_region,
        ROW_NUMBER() OVER (
            PARTITION BY CAST(cod_asesor AS BIGINT)
            ORDER BY periodo DESC
        ) AS rn
    FROM resultados_vspc_canales.fco_planta_comercial
    WHERE ingestion_year = {pln_year}
      AND ingestion_month = {pln_month}
      AND ingestion_day = {pln_day}
) t
WHERE rn = 1
)

SELECT
    DISTINCT
    -- Datos del comercio
    b.id_comercio,
    b.periodo,
    b.nombre_comercio,
    b.nombre_legal,
    b.documento_identidad AS num_doc,
    b.tipo_documento,
    b.tipo_cuenta,
    b.plan_dispersion,
    CASE
        WHEN UPPER(b.plan_dispersion) = 'PLAN FREMIUM NEQUI NEGOCIOS'
          OR UPPER(b.plan_dispersion) = 'PLAN NEQUI NEGOCIOS EMPRENDEDORES' THEN 'Nequi negocios'
        ELSE 'Wompi'
    END AS plan_dispersion_2,
    b.modelo,
    b.activo,
    b.cod_ciudad,
    b.cod_departamento,
    b.ciudad,
    t0.segmento AS segm,
    t0.subsegmento AS subsegm,
    t0.marca_gerenciado,
    t0.cod_ventas,
    t0.periodo AS periodo_colocacion,
    t1.cod_cargo,
    t1.descri_cargo,
    t1.descri_zona,
    t1.descri_region,
    b.departamento,
    b.ciiu,
    b.descripcion_act_econ,
    b.monto_limite_diario,
    b.monto_limite_transaccional,
    b.desembolsos_permitidos,
    b.fuentes_pago_habilitadas,
    b.fecha_creacion_comercio,
    b.fecha_prim_ingreso_app,
    b.fecha_ult_ingreso_app,

    -- Procedimientos de vinculación
    p.estado_comercio,
    p.codigo_asesor,
    p.ultimo_proc,
    p.estado_ultimo_proc,
    p.fecha_inicio_procedimiento,
    p.fecha_ult_actualizacion_proc,

    -- Identidades de pago (afiliación por canal)
    -- pi.codigo_unico,
    -- pi.id_comercio,
    pi.identidades_activas,
    COALESCE(pi.flag_daviplata,               0) AS flag_daviplata,
    COALESCE(pi.flag_tarjeta,                 0) AS flag_tarjeta,
    COALESCE(pi.flag_su_pay,                  0) AS flag_su_pay,
    COALESCE(pi.flag_tarjeta_venta_presente,  0) AS flag_tarjeta_venta_presente,
    COALESCE(pi.flag_puntos_colombia,         0) AS flag_puntos_colombia,
    COALESCE(pi.flag_nequi,                   0) AS flag_nequi,
    COALESCE(pi.flag_bcol_bnpl,               0) AS flag_bcol_bnpl,
    COALESCE(pi.flag_boton_bancolombia,       0) AS flag_boton_bancolombia,
    COALESCE(pi.flag_fiserv,                  0) AS flag_fiserv,
    COALESCE(pi.flag_datafono_venta_presente, 0) AS flag_datafono_venta_presente,
    COALESCE(pi.flag_corresponsal_bancario,   0) AS flag_corresponsal_bancario,
    COALESCE(pi.flag_qr_bancolombia,          0) AS flag_qr_bancolombia,
    COALESCE(pi.flag_tokenbox,                0) AS flag_tokenbox,
    COALESCE(pi.flag_credibanco,              0) AS flag_credibanco,
    COALESCE(pi.flag_pse,                     0) AS flag_pse,
    pi.fecha_primera_identidad,

    -- Fechas primera / última transacción por franquicia
    r.fecha_primera_trx_mc,
    r.fecha_ultima_trx_mc,
    r.fecha_primera_trx_visa,
    r.fecha_ultima_trx_visa,
    r.fecha_primera_trx_amex,
    r.fecha_ultima_trx_amex,
    -- Fechas primera / última transacción por medio de pago
    r.fecha_primera_trx_daviplata,
    r.fecha_ultima_trx_daviplata,
    r.fecha_primera_trx_tarjeta,
    r.fecha_ultima_trx_tarjeta,
    r.fecha_primera_trx_su_pay,
    r.fecha_ultima_trx_su_pay,
    r.fecha_primera_trx_tarjeta_vp,
    r.fecha_ultima_trx_tarjeta_vp,
    r.fecha_primera_trx_puntos_col,
    r.fecha_ultima_trx_puntos_col,
    r.fecha_primera_trx_nequi,
    r.fecha_ultima_trx_nequi,
    r.fecha_primera_trx_bcol_bnpl,
    r.fecha_ultima_trx_bcol_bnpl,
    r.fecha_primera_trx_boton_bcol,
    r.fecha_ultima_trx_boton_bcol,
    r.fecha_primera_trx_fiserv,
    r.fecha_ultima_trx_fiserv,
    r.fecha_primera_trx_datafono_vp,
    r.fecha_ultima_trx_datafono_vp,
    r.fecha_primera_trx_corr_ban,
    r.fecha_ultima_trx_corr_ban,
    r.fecha_primera_trx_qr_bcol,
    r.fecha_ultima_trx_qr_bcol,
    r.fecha_primera_trx_tokenbox,
    r.fecha_ultima_trx_tokenbox,
    r.fecha_primera_trx_credibanco,
    r.fecha_ultima_trx_credibanco,
    r.fecha_primera_trx_pse,
    r.fecha_ultima_trx_pse,
    -- General
    r.fecha_primera_trx_general,
    r.fecha_ultima_trx_general,
    COALESCE(r.trx_total,              0) AS trx_total,
    COALESCE(r.medios_pago_utilizados, 0) AS medios_pago_utilizados,
    COALESCE(r.franquicias_utilizadas, 0) AS franquicias_utilizadas,

    -- Flags de activación (tuvo al menos una transacción aprobada)
    CASE WHEN r.fecha_primera_trx_mc          IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_mc,
    CASE WHEN r.fecha_primera_trx_visa         IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_visa,
    CASE WHEN r.fecha_primera_trx_amex         IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_amex,
    CASE WHEN r.fecha_primera_trx_daviplata    IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_daviplata,
    CASE WHEN r.fecha_primera_trx_tarjeta      IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_tarjeta,
    CASE WHEN r.fecha_primera_trx_su_pay       IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_su_pay,
    CASE WHEN r.fecha_primera_trx_tarjeta_vp   IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_tarjeta_vp,
    CASE WHEN r.fecha_primera_trx_puntos_col   IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_puntos_col,
    CASE WHEN r.fecha_primera_trx_nequi        IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_nequi,
    CASE WHEN r.fecha_primera_trx_bcol_bnpl    IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_bcol_bnpl,
    CASE WHEN r.fecha_primera_trx_boton_bcol   IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_boton_bcol,
    CASE WHEN r.fecha_primera_trx_fiserv       IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_fiserv,
    CASE WHEN r.fecha_primera_trx_datafono_vp  IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_datafono_vp,
    CASE WHEN r.fecha_primera_trx_corr_ban     IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_corr_ban,
    CASE WHEN r.fecha_primera_trx_qr_bcol      IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_qr_bcol,
    CASE WHEN r.fecha_primera_trx_tokenbox     IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_tokenbox,
    CASE WHEN r.fecha_primera_trx_credibanco   IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_credibanco,
    CASE WHEN r.fecha_primera_trx_pse          IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_pse,
    CASE WHEN r.fecha_primera_trx_general      IS NOT NULL THEN 1 ELSE 0 END AS flag_activado_general,

    -- Días desde creación del comercio hasta primera transacción
    DATEDIFF(r.fecha_primera_trx_mc,         b.fecha_creacion_comercio) AS dias_a_primera_trx_mc,
    DATEDIFF(r.fecha_primera_trx_visa,        b.fecha_creacion_comercio) AS dias_a_primera_trx_visa,
    DATEDIFF(r.fecha_primera_trx_amex,        b.fecha_creacion_comercio) AS dias_a_primera_trx_amex,
    DATEDIFF(r.fecha_primera_trx_daviplata,   b.fecha_creacion_comercio) AS dias_a_primera_trx_daviplata,
    DATEDIFF(r.fecha_primera_trx_nequi,       b.fecha_creacion_comercio) AS dias_a_primera_trx_nequi,
    DATEDIFF(r.fecha_primera_trx_boton_bcol,  b.fecha_creacion_comercio) AS dias_a_primera_trx_boton_bcol,
    DATEDIFF(r.fecha_primera_trx_pse,         b.fecha_creacion_comercio) AS dias_a_primera_trx_pse,
    DATEDIFF(r.fecha_primera_trx_general,     b.fecha_creacion_comercio) AS dias_a_primera_trx_general,

    -- Flags de activación dentro de los primeros 30 días
    CASE WHEN r.fecha_primera_trx_mc         <= DATE_ADD(b.fecha_creacion_comercio, 30) THEN 1 ELSE 0 END AS flag_activado_mc_30d,
    CASE WHEN r.fecha_primera_trx_visa        <= DATE_ADD(b.fecha_creacion_comercio, 30) THEN 1 ELSE 0 END AS flag_activado_visa_30d,
    CASE WHEN r.fecha_primera_trx_amex        <= DATE_ADD(b.fecha_creacion_comercio, 30) THEN 1 ELSE 0 END AS flag_activado_amex_30d,
    CASE WHEN r.fecha_primera_trx_daviplata   <= DATE_ADD(b.fecha_creacion_comercio, 30) THEN 1 ELSE 0 END AS flag_activado_daviplata_30d,
    CASE WHEN r.fecha_primera_trx_nequi       <= DATE_ADD(b.fecha_creacion_comercio, 30) THEN 1 ELSE 0 END AS flag_activado_nequi_30d,
    CASE WHEN r.fecha_primera_trx_boton_bcol  <= DATE_ADD(b.fecha_creacion_comercio, 30) THEN 1 ELSE 0 END AS flag_activado_boton_bcol_30d,
    CASE WHEN r.fecha_primera_trx_pse         <= DATE_ADD(b.fecha_creacion_comercio, 30) THEN 1 ELSE 0 END AS flag_activado_pse_30d,
    CASE WHEN r.fecha_primera_trx_general     <= DATE_ADD(b.fecha_creacion_comercio, 30) THEN 1 ELSE 0 END AS flag_activado_general_30d,

    -- Total de medios afiliados (suma de flags PI)
    COALESCE(pi.flag_daviplata,               0)
        + COALESCE(pi.flag_tarjeta,                 0)
        + COALESCE(pi.flag_su_pay,                  0)
        + COALESCE(pi.flag_tarjeta_venta_presente,  0)
        + COALESCE(pi.flag_puntos_colombia,         0)
        + COALESCE(pi.flag_nequi,                   0)
        + COALESCE(pi.flag_bcol_bnpl,               0)
        + COALESCE(pi.flag_boton_bancolombia,       0)
        + COALESCE(pi.flag_fiserv,                  0)
        + COALESCE(pi.flag_datafono_venta_presente, 0)
        + COALESCE(pi.flag_corresponsal_bancario,   0)
        + COALESCE(pi.flag_qr_bancolombia,          0)
        + COALESCE(pi.flag_tokenbox,                0)
        + COALESCE(pi.flag_credibanco,              0)
        + COALESCE(pi.flag_pse,                     0) AS medios_pago_afiliados,

    -- Total de canales activados (con al menos una trx aprobada)
        (CASE WHEN r.fecha_primera_trx_daviplata    IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_tarjeta      IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_su_pay       IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_tarjeta_vp   IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_puntos_col   IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_nequi        IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_bcol_bnpl    IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_boton_bcol   IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_fiserv       IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_datafono_vp  IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_corr_ban     IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_qr_bcol      IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_tokenbox     IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_credibanco   IS NOT NULL THEN 1 ELSE 0 END)
        + (CASE WHEN r.fecha_primera_trx_pse          IS NOT NULL THEN 1 ELSE 0 END) AS medios_pago_activados,

    -- Clasificación de activación
    CASE
        WHEN COALESCE(r.trx_total, 0) = 0                                             THEN 'Sin transacciones'
        WHEN DATEDIFF(r.fecha_primera_trx_general, b.fecha_creacion_comercio) <= 7    THEN 'Activacion rapida'
        WHEN DATEDIFF(r.fecha_primera_trx_general, b.fecha_creacion_comercio) <= 30   THEN 'Activacion media'
        ELSE 'Activacion tardia'
    END AS clasificacion_activacion

FROM {zona_p1}.wompi_comercios_base b
LEFT JOIN {zona_p1}.ult_wompi_procedimientos_base p
    ON b.id_comercio = p.id_comercio
LEFT JOIN {zona_p1}.wompi_payment_identities_resumen pi
    ON b.id_comercio = pi.id_comercio
LEFT JOIN {zona_p1}.wompi_transacciones_resumen r
    ON b.id_comercio = r.id_comercio
LEFT JOIN {zona_p1}.wompi_intenciones_5x_final t0
    ON CAST(b.id_comercio AS BIGINT) = CAST(t0.id_comercio AS BIGINT)
LEFT JOIN planta t1
    ON COALESCE(CAST(t0.cod_ventas AS BIGINT),CAST(p.codigo_asesor AS BIGINT)) = CAST(t1.cod_asesor AS BIGINT)
;

COMPUTE STATS {zona_p3}.afiliaciones_wompi_final;

-- ===== Campos faltantes
-- periodo: Se saca del creado
-- FROM final t0
-- LEFT JOIN planta t1   ========== cod_ventas ===========
-- ON COALESCE(CAST(t0.cod_ventas AS BIGINT),CAST(T0.codigo_asesor AS BIGINT)) = CAST(t1.cod_asesor AS BIGINT)
-- ORDER BY periodo ASC
-- Del cruce de arriba salen cod_cargo, descri_cargo, descri_zona, descri_region