
DROP TABLE IF exists {zona_p}.tipo_afiliacion_comercios_adq_cincox PURGE; 
CREATE TABLE {zona_p}.tipo_afiliacion_comercios_adq_cincox
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS

WITH primera_franq as(
  SELECT 
      eccomercio as cod_unico
      , min(efecafili) as f_p_franq
  FROM s_productos.adq_adqlibramd_adqffestab
  WHERE ingestion_year = {ADQESTAB[year]}
  and ingestion_month = {ADQESTAB[month]}
  and ingestion_day = {ADQESTAB[day]}
  --and eccomercio = 2270136
  GROUP BY 1
), 

afi_banco as(
  SELECT
    ndcoduni as cod_unico
    , min(concat('20',substr(ndfechag,7,2), substr(ndfechag,1,2), substr(ndfechag,4,2))) as  minima_vb 
  FROM s_productos.adq_adqlibramd_adqffcodes
  WHERE
    year >= 2021 -- la tabla tiene información desde está partición
    AND ndindica like 'H'
  GROUP BY 1
), 

pre as (
  SELECT
    t0.cod_unico
    , cast(t0.minima_vb as BIGINT) minima_vb
    , cast(t1.f_p_franq as BIGINT) f_p_franq
  from afi_banco t0 
  LEFT JOIN primera_franq t1
  on t0.cod_unico = t1.cod_unico
), 

final as (
  SELECT
    *
    , CASE
      when f_p_franq>=minima_vb then 'AFILIACION'
      WHEN f_p_franq<minima_vb then 'CAMBIO'
    end tipo_afiliacion
  FROM pre
)

SELECT 
  *
  , substr(cast(minima_vb as STRING), 1,6) as periodo
FROM final
WHERE minima_vb >= 20250101
;

COMPUTE stats {zona_p}.tipo_afiliacion_comercios_adq_cincox;