DROP TABLE IF exists {zona_i}.base_adquirencia_vinculados_seguimiento_cincox PURGE; 
CREATE TABLE {zona_i}.base_adquirencia_vinculados_seguimiento_cincox
STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
select
  t0.codigo_unico
  , t0.nit
 
  --, t0.tipo_afiliacion
  --, t0.mcc
  --, t0.nombre as nombre_comercio
  --, t0.segm
  --, t0.subsegm
  --, t0.gerenciamiento as marca_genrenciado
  --, t0.cod_asesor
  --, t0.descri_cargo
  --, t0.descri_region
  --, t0.descri_zona
  --, t1.trx_ultimos_6m
  --, t1.monto_mastercard
  --, t1.trx_mastercard

    , t1.adquirencia_activo_enero
    , t1.adquirencia_activo_febrero
    , t1.adquirencia_activo_marzo
    , t1.adquirencia_activo_abril
    , t1.adquirencia_activo_mayo
    , t1.adquirencia_activo_junio
    , t1.adquirencia_activo_julio
    , t1.adquirencia_activo_agosto
    , t1.adquirencia_activo_septiembre
    , t1.adquirencia_activo_octubre
    , t1.adquirencia_activo_noviembre
    , t1.adquirencia_activo_diciembre
    , t1.monto_enero_mc
    , t1.monto_febrero_mc
    , t1.monto_marzo_mc
    , t1.monto_abril_mc
    , t1.monto_mayo_mc
    , t1.monto_junio_mc
    , t1.monto_julio_mc
    , t1.monto_agosto_mc
    , t1.monto_septiembre_mc
    , t1.monto_octubre_mc
    , t1.monto_noviembre_mc
    , t1.monto_diciembre_mc
    , t1.num_trx_mc_enero
    , t1.num_trx_mc_febrero
    , t1.num_trx_mc_marzo
    , t1.num_trx_mc_abril
    , t1.num_trx_mc_mayo
    , t1.num_trx_mc_junio
    , t1.num_trx_mc_julio
    , t1.num_trx_mc_agosto
    , t1.num_trx_mc_septiembre
    , t1.num_trx_mc_octubre
    , t1.num_trx_mc_noviembre
    , t1.num_trx_mc_diciembre
    --, t0.periodo
--from  {zona_p}.comercios_adq_final_cincox t0
from {zona_p}.vinculaciones_comercios_adq_cincox AS t0
left join {zona_p}.trx_comercios_adq_vinculados_cincox AS t1
on t0.codigo_unico = cast(t1.cod_unico as bigint)
;

compute stats {zona_i}.base_adquirencia_vinculados_seguimiento_cincox;


DROP TABLE IF exists {zona_f}.base_adquirencia_vinculados_seguimiento_cincox PURGE; 
CREATE TABLE {zona_f}.base_adquirencia_vinculados_seguimiento_cincox
STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
select
  (CAST(codigo_unico AS BIGINT) * 2024) + 1998 AS codigo_unico_mask_adq --id_comercio    
  , (CAST(nit AS BIGINT) * 2024) + 1999 AS num_doc_mask  --num_doc 
  --, periodo
  --, tipo_afiliacion
  --, mcc
  --, segm
  --, subsegm
  --, marca_genrenciado
  --, cod_asesor
  --, descri_cargo
  --, descri_region
  --, descri_zona
  --, trx_ultimos_6m
  --, monto_mastercard
  --, trx_mastercard
    , adquirencia_activo_enero
    , adquirencia_activo_febrero
    , adquirencia_activo_marzo
    , adquirencia_activo_abril
    , adquirencia_activo_mayo
    , adquirencia_activo_junio
    , adquirencia_activo_julio
    , adquirencia_activo_agosto
    , adquirencia_activo_septiembre
    , adquirencia_activo_octubre
    , adquirencia_activo_noviembre
    , adquirencia_activo_diciembre
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
from {zona_i}.base_adquirencia_vinculados_seguimiento_cincox
;

compute stats {zona_f}.base_adquirencia_vinculados_seguimiento_cincox;