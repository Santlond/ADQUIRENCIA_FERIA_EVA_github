DROP TABLE IF exists {zona_p}.plink_comercios_wompi_cincox PURGE; 
CREATE TABLE {zona_p}.plink_comercios_wompi_cincox
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
WITH wompi as (
SELECT  DISTINCT
    substr(cast(creado as string), 1, 6) as periodo
    , id_comercio
    , cast(documento_identidad as BIGINT) as num_doc  
    , modelo
    , nombre_comercio
    , plan_dispersion
FROM resultados_wompi.wompi_merchants 
WHERE activo = "A"
AND desembolsos_permitidos = "Si"
and modelo like 'Agregador'
and creado>20250000
and ingestion_year = {WCOM[year]}
and ingestion_month = {WCOM[month]}
and ingestion_day = {WCOM[day]}
),procedures as (
select distinct
    id_comercio,
    codigo_asesor,
    estado_comercio,
    cast (fecha_actualizacion_procedimiento/100 as bigint) as fecha_actualizacion_procedimiento,
    nombre_procedimiento
from resultados_wompi.wompi_businesses_procedures
where nombre_procedimiento in ("Validación identidad - Persona VTP", "Validación identidad - Empresa VTP","Validación identidad - Persona","Validación identidad - Empresa")
and estado_comercio ='Activo con desembolsos'
and ingestion_year = {WBP[year]}
and ingestion_month = {WBP[month]}
and ingestion_day = {WBP[day]}
), wompi_a as (
select
    a.periodo
    , a.id_comercio
    , a.num_doc
    , a.modelo
    , a.nombre_comercio
    , a.plan_dispersion
    , b.codigo_asesor
from wompi a
left join procedures b
on a.id_comercio = b.id_comercio
), mdm as(
SELECT 
    cast(numero_id as BIGINT) as num_doc
    , desc_segmento as segm
    , desc_subsegmento as subsegm
    , gerenciamiento as marca_gerenciado
FROM resultados_fcr.fcr_mdm_datos_generales_clientes
where year = {MDM[year]}
and month =  {MDM[month]}
and day =    {MDM[day]}
), intenciones AS (
    SELECT
        num_doc,
        cod_ventas_gestion_val_planta,
        usuario_creacion,
        nombre_usuario_creacion,
        cargo_usuario_creacion,
        CAST(fecha_gestion AS TIMESTAMP) AS f_gest
    FROM resultados_clientes_personas_y_pymes.fco_intenciones_y_gestiones_pymes_empresas_corporativo
    WHERE cod_producto IN (1134, 723) 
    AND cod_estado IN (2, 3)
    AND year = 2025
), stoc AS (
    SELECT
        num_doc,
        cod_ventas_val_planta,
        usuario_red,
        nombre_user_gestion,
        cargo_user_gestion,
        CAST(f_gestion AS TIMESTAMP) AS f_gest
    FROM resultados_clientes_personas_y_pymes.fco_gestion_oc_stoc_personas
    WHERE cod_accion IN (114, 467, 6073) 
    AND cod_estado IN (3, 4)
    AND year = 2025
), gestion AS (
    SELECT
        num_doc,
        cod_ventas_user_creacion_planta,
        user_creacion,
        nombre_user_creacion,
        cargo_user_creacion,
        CAST(f_gestion AS TIMESTAMP) AS f_gest
    FROM resultados_clientes_personas_y_pymes.fco_gestion_intenciones_personas
    WHERE cod_producto_detallado IN (135, 143) 
    AND cod_estado IN (1, 3, 4)
    AND year = 2025
), combinacion AS (
    SELECT distinct
        num_doc,
        CAST(cod_ventas_gestion_val_planta AS VARCHAR) AS cod_ventas,
        usuario_creacion AS usuario,
        nombre_usuario_creacion AS nombre_usuario,
        cargo_usuario_creacion AS cargo_usuario,
        f_gest
    FROM intenciones
    UNION ALL
    SELECT distinct
        num_doc,
        CAST(cod_ventas_val_planta AS VARCHAR) AS cod_ventas, 
        usuario_red AS usuario,
        nombre_user_gestion AS nombre_usuario,
        cargo_user_gestion AS cargo_usuario,
        f_gest
    FROM stoc
    UNION ALL
    SELECT distinct
        num_doc,
        CAST(cod_ventas_user_creacion_planta AS VARCHAR) AS cod_ventas, 
        user_creacion AS usuario,
        nombre_user_creacion AS nombre_usuario,
        cargo_user_creacion AS cargo_usuario,
        f_gest
    FROM gestion
), ordenado AS (
    SELECT
        num_doc,
        cod_ventas,
        usuario,
        nombre_usuario,
        cargo_usuario,
        f_gest,
        ROW_NUMBER() OVER (PARTITION BY num_doc ORDER BY num_doc desc, f_gest ASC, cod_ventas desc ) AS rn
    FROM combinacion
), depuracion as(
select distinct
    *
    , 'Accion comercial' as Fuente
from ordenado
where rn=1
), final as (
SELECT distinct 
    t0.id_comercio
    , t0.num_doc  
    , t0.modelo
    , t0.nombre_comercio
    , t0.plan_dispersion
    , t0.codigo_asesor
    , t1.segm
    , t1.subsegm
    , t1.marca_gerenciado
    , t2.cod_ventas
    , t2.usuario
    , t2.nombre_usuario
    , t2.cargo_usuario
    , t2.fuente
    , t0.periodo
FROM wompi_a  t0 
LEFT JOIN mdm t1 ON CAST(t0.num_doc AS BIGINT) = CAST(t1.num_doc AS BIGINT)
LEFT JOIN depuracion t2 ON CAST(t0.num_doc as BIGINT) = CAST(t2.num_doc as BIGINT)
),planta AS (
select
    cod_asesor
    ,cod_cargo
    ,descri_cargo
    ,descri_zona
    ,descri_region
FROM resultados_vspc_canales.fco_planta_comercial
where ingestion_year= {PLTN[year]}
and ingestion_month= {PLTN[month]}
and ingestion_day= {PLTN[day]}
)
select
    t1.*
    ,t0.*
from final t0
left join planta t1 ON CAST(t0.cod_ventas AS BIGINT) = CAST(t1.cod_asesor AS BIGINT)
;

compute stats {zona_p}.plink_comercios_wompi_cincox;