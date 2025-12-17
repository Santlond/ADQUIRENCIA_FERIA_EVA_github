DROP TABLE IF exists {zona_p}.wompi_vbpo_autogestion_cincox PURGE; 
CREATE TABLE {zona_p}.wompi_vbpo_autogestion_cincox
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
WITH a as(
SELECT 
    id_comercio		
    , num_doc		
    , modelo		
    , nombre_comercio		
    , plan_dispersion		
    , segm		
    , subsegm		
    , marca_gerenciado		
    , cod_ventas		
    , cast(codigo_asesor as BIGINT) as codigo_asesor
    , usuario	
    , nombre_usuario	
    , cod_cargo
    , cargo_usuario
    , descri_zona
    , descri_region
    -- , trx_ultimos_6m		
    -- , monto_mastercard		
    -- , trx_mastercard		
    , periodo
FROM {zona_p}.plink_wmv
WHERE fuente is null
),planta as (
--select distinct
--nom_asesor,
--cast (codase as bigint) as codase,
--nivel,
--'BPO' as fuente
--from resultados_vspc_canales.tiplantaac
--where nivel in ('NY','SE')
--AND ingestion_year = {PCO[year]}
--and ingestion_month = {PCO[month]}
--and ingestion_day = {PCO[day]}
select distinct
    nombre as nom_asesor  
    ,cod_asesor as codase
    ,descri_cargo as cargo_usuario
    ,descri_zona
    ,descri_region
    ,cod_cargo
    ,'BPO' as fuente
FROM resultados_vspc_canales.fco_planta_comercial
where ingestion_year= {PLTN[year]}
and ingestion_month= {PLTN[month]}
and ingestion_day= {PLTN[day]}
and cod_cargo in ('SE','NY')
), final as(
select
    a.id_comercio		
    , a.num_doc		
    , a.modelo		
    , a.nombre_comercio		
    , a.plan_dispersion		
    , a.segm		
    , a.subsegm		
    , a.marca_gerenciado		
    , a.cod_ventas		
    , a.codigo_asesor		
    , a.usuario	
    , b.nom_asesor
    , b.cod_cargo
    , b.cargo_usuario
    , b.descri_zona
    , b.descri_region	
    -- , a.trx_ultimos_6m		
    -- , a.monto_mastercard		
    -- , a.trx_mastercard		
    , b.fuente 
    , a.periodo
from a 
left join planta b  
on cast(a.codigo_asesor as bigint) = cast(b.codase as bigint)
)
SELECT
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
    , nom_asesor as nombre_usuario
    , cod_cargo
    , cargo_usuario
    , descri_zona
    , descri_region	
    -- , trx_ultimos_6m		
    -- , monto_mastercard		
    -- , trx_mastercard		
    , if(fuente is NOT NULL, fuente, 'Autogestion') as fuente		
    , periodo
FROM final
;

compute stats  {zona_p}.wompi_vbpo_autogestion_cincox;