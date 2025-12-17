DROP TABLE IF exists {zona_i}.base_wompi_vinculados_seguimiento_cincox PURGE; 
CREATE TABLE {zona_i}.base_wompi_vinculados_seguimiento_cincox
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS

with union_wompi AS (
    select
        id_comercio		
        , num_doc		
        , modelo		
        , nombre_comercio		
        , plan_dispersion		
        , segm		
        , subsegm		
        , marca_gerenciado		
        , cod_ventas		
        , codigo_asesor		
        , usuario	
        , nombre_usuario
        , cod_cargo
        , cargo_usuario
        , descri_zona
        , descri_region	
        -- , trx_ultimos_6m		
        -- , monto_mastercard		
        -- , trx_mastercard		
        , fuente 
        , periodo
    from {zona_p}.wompi_vac_cincox
    union ALL
    select
        id_comercio		
        , num_doc		
        , modelo		
        , nombre_comercio		
        , plan_dispersion		
        , segm		
        , subsegm		
        , marca_gerenciado		
        , cod_ventas		
        , codigo_asesor		
        , usuario	
        , nombre_usuario
        , cod_cargo
        , cargo_usuario
        , descri_zona
        , descri_region	
        -- , trx_ultimos_6m		
        -- , monto_mastercard		
        -- , trx_mastercard		
        , fuente 
        , periodo
    from {zona_p}.wompi_vbpo_autogestion_cincox
)

-- adjuntamos la transaccionalidad de cada comercio
select
    t1.id_comercio		
    , t1.num_doc		
    , t1.modelo		
    , t1.nombre_comercio		
    , t1.plan_dispersion		
    , t1.segm		
    , t1.subsegm		
    , t1.marca_gerenciado		
    , t1.cod_ventas		
    , t1.codigo_asesor		
    , t1.usuario	
    , t1.nombre_usuario
    , t1.cod_cargo
    , t1.cargo_usuario
    , t1.descri_zona
    , t1.descri_region	
    , IFNULL(t2.wompi_activo_enero, 'No') AS wompi_activo_enero
    , IFNULL(t2.wompi_activo_febrero, 'No') AS wompi_activo_febrero
    , IFNULL(t2.wompi_activo_marzo, 'No') AS wompi_activo_marzo
    , IFNULL(t2.wompi_activo_abril, 'No') AS wompi_activo_abril
    , IFNULL(t2.wompi_activo_mayo, 'No') AS wompi_activo_mayo
    , IFNULL(t2.wompi_activo_junio, 'No') AS wompi_activo_junio
    , IFNULL(t2.wompi_activo_julio, 'No') AS wompi_activo_julio
    , IFNULL(t2.wompi_activo_agosto, 'No') AS wompi_activo_agosto
    , IFNULL(t2.wompi_activo_septiembre, 'No') AS wompi_activo_septiembre
    , IFNULL(t2.wompi_activo_octubre, 'No') AS wompi_activo_octubre
    , IFNULL(t2.wompi_activo_noviembre, 'No') AS wompi_activo_noviembre
    , IFNULL(t2.wompi_activo_diciembre, 'No') AS wompi_activo_diciembre
    , IFNULL(t2.monto_enero_mc, 0) AS monto_enero_mc
    , IFNULL(t2.monto_febrero_mc, 0) AS monto_febrero_mc
    , IFNULL(t2.monto_marzo_mc, 0) AS monto_marzo_mc
    , IFNULL(t2.monto_abril_mc, 0) AS monto_abril_mc
    , IFNULL(t2.monto_mayo_mc, 0) AS monto_mayo_mc
    , IFNULL(t2.monto_junio_mc, 0) AS monto_junio_mc
    , IFNULL(t2.monto_julio_mc, 0) AS monto_julio_mc
    , IFNULL(t2.monto_agosto_mc, 0) AS monto_agosto_mc
    , IFNULL(t2.monto_septiembre_mc, 0) AS monto_septiembre_mc
    , IFNULL(t2.monto_octubre_mc, 0) AS monto_octubre_mc
    , IFNULL(t2.monto_noviembre_mc, 0) AS monto_noviembre_mc
    , IFNULL(t2.monto_diciembre_mc, 0) AS monto_diciembre_mc
    , IFNULL(t2.num_trx_mc_enero, 0) AS num_trx_mc_enero
    , IFNULL(t2.num_trx_mc_febrero, 0) AS num_trx_mc_febrero
    , IFNULL(t2.num_trx_mc_marzo, 0) AS num_trx_mc_marzo
    , IFNULL(t2.num_trx_mc_abril, 0) AS num_trx_mc_abril
    , IFNULL(t2.num_trx_mc_mayo, 0) AS num_trx_mc_mayo
    , IFNULL(t2.num_trx_mc_junio, 0) AS num_trx_mc_junio
    , IFNULL(t2.num_trx_mc_julio, 0) AS num_trx_mc_julio
    , IFNULL(t2.num_trx_mc_agosto, 0) AS num_trx_mc_agosto
    , IFNULL(t2.num_trx_mc_septiembre, 0) AS num_trx_mc_septiembre
    , IFNULL(t2.num_trx_mc_octubre, 0) AS num_trx_mc_octubre
    , IFNULL(t2.num_trx_mc_noviembre, 0) AS num_trx_mc_noviembre
    , IFNULL(t2.num_trx_mc_diciembre, 0) AS num_trx_mc_diciembre
    , t1.fuente
    , t1.periodo
from union_wompi AS t1
LEFT JOIN
    {zona_p}.plink_comercios_wompi_cincox_trx AS t2
    ON t1.id_comercio = t2.id_comercio
;

compute stats {zona_i}.base_wompi_vinculados_seguimiento_cincox;





DROP TABLE IF exists {zona_f}.base_wompi_vinculados_seguimiento_cincox PURGE; 
CREATE TABLE {zona_f}.base_wompi_vinculados_seguimiento_cincox
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
select
    (CAST(id_comercio AS BIGINT) * 2024) + 1998 AS codigo_unico_mask_wompi --id_comercio		
    , (CAST(num_doc AS BIGINT) * 2024) + 1999 AS num_doc_mask  --num_doc		
    , modelo			
    , plan_dispersion		
    , segm		
    , subsegm		
    , marca_gerenciado			
    , codigo_asesor		
    , cod_cargo
    , cargo_usuario
    , descri_zona
    , descri_region	
    , wompi_activo_enero
    , wompi_activo_febrero
    , wompi_activo_marzo
    , wompi_activo_abril
    , wompi_activo_mayo
    , wompi_activo_junio
    , wompi_activo_julio
    , wompi_activo_agosto
    , wompi_activo_septiembre
    , wompi_activo_octubre
    , wompi_activo_noviembre
    , wompi_activo_diciembre
    , monto_enero_mc
    , monto_febrero_mc
    , monto_marzo_mc
    , monto_abril_mc
    , monto_mayo_mc
    , monto_junio_mc
    , monto_julio_mc
    , monto_agosto_mc
    , monto_septiembre_mc
    , monto_octubre_mc
    , monto_noviembre_mc
    , monto_diciembre_mc
    , num_trx_mc_enero
    , num_trx_mc_febrero
    , num_trx_mc_marzo
    , num_trx_mc_abril
    , num_trx_mc_mayo
    , num_trx_mc_junio
    , num_trx_mc_julio
    , num_trx_mc_agosto
    , num_trx_mc_septiembre
    , num_trx_mc_octubre
    , num_trx_mc_noviembre
    , num_trx_mc_diciembre	
    , fuente 
    , periodo
from {zona_i}.base_wompi_vinculados_seguimiento_cincox
;

compute stats {zona_f}.base_wompi_vinculados_seguimiento_cincox;
