



---------- TRX ADQUIRENCIA

DROP TABLE IF exists proceso_consumidores.trx_comercios_adq_vinculados_cincox PURGE; 
CREATE TABLE proceso_consumidores.trx_comercios_adq_vinculados_cincox
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
WITH adq_trx_all as(
SELECT 
  cod_unico
  , sum(mnt_total_trx) as monto_total
FROM resultados_vspc_medios_de_pago.gsap_m_transaccional
WHERE year = 2025
and f_trx BETWEEN date_sub(trunc(current_date(),'MM'), interval 6 month) and last_day(date_sub(trunc(current_date(),'MM'), interval 1 day))
GROUP BY 1
), actividad as (
select
cod_unico
, if(monto_total <= 0, 'No', 'Si') as trx_ultimos_6m
from adq_trx_all
), adq_trx_mc as (
select 
  cod_unico
  , count(*) as trx_mastercard
  , sum(mnt_total_trx) as monto_mastercard
FROM resultados_vspc_medios_de_pago.gsap_m_transaccional
WHERE year = 2025
and f_trx BETWEEN date_sub(trunc(current_date(),'MM'), interval 6 month) and last_day(date_sub(trunc(current_date(),'MM'), interval 1 day))
and descri_franq like 'Mastercard'
and estado_trx like 'Cleared'
group by 1
)
select
    t0.cod_unico
    , t0.trx_ultimos_6m
    , sum(t1.trx_mastercard) as trx_mastercard
    , sum(t1.monto_mastercard) as monto_mastercard
from actividad t0
left join adq_trx_mc t1 ON t0.cod_unico = t1.cod_unico
GROUP BY 1,2

; 

compute stats proceso_consumidores.trx_comercios_adq_vinculados_cincox;



---final


DROP TABLE IF exists {zona_i}.base_adquirencia_vinculados_seguimiento_cincox PURGE; 
CREATE TABLE {zona_i}.base_adquirencia_vinculados_seguimiento_cincox
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
select
  t0.codigo_unico
  , t0.nit
  , t0.tipo_afiliacion
  , t0.nombrnombre_comercio
  , t0.segm
  , t0.subsegm
  , t0.gerenciamiento as marca_genrenciado
  , t0.cod_asesor
  , t0.descri_cargo 
  , t0.descri_region
  , t0.descri_zona
  , t1.trx_ultimos_6m
  , t1.monto_mastercard
  , t1.trx_mastercard
  , t0.periodo
from proceso_consumidores.comercios_adq_final_cincox t0
left join proceso_consumidores.trx_comercios_adq_vinculados_cincox t1
on t0.codigo_unico = cast(t1.cod_unico as bigint)
;

compute stats {zona_i}.base_adquirencia_vinculados_seguimiento_cincox;

