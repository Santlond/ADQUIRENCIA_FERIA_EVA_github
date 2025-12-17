
DROP TABLE IF exists {zona_p}.vinculaciones_comercios_adq_cincox PURGE; 
CREATE TABLE {zona_p}.vinculaciones_comercios_adq_cincox
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS

WITH a as (
  SELECT 
    cast(enit as BIGINT) as nit
    , eccomercio as codigo_unico
    , ersocial as nombre
    , etnegocio as mcc
    , ROW_NUMBER () OVER (PARTITION BY eccomercio ORDER BY efecafili DESC) AS rn
  FROM s_productos.adq_adqlibramd_adqffestab
  WHERE year = {ADQESTAB[year]}
  and ingestion_month = {ADQESTAB[month]}
  and ingestion_day = {ADQESTAB[day]}
),

comercio_unico AS (
  SELECT
    nit
    , codigo_unico
    , nombre
    , mcc
  FROM
    a
  WHERE
    rn = 1
),

afiliacion as (
  SELECT
    periodo
    , cod_unico
    , tipo_afiliacion
  from {zona_p}.tipo_afiliacion_comercios_adq_cincox
  --WHERE tipo_afiliacion not lIKE  'NULL'
)

select
  a.nit
  , a.codigo_unico
  --, a.nombre
  --, a.mcc
  --, b.tipo_afiliacion
  , b.periodo
from
  comercio_unico as a
inner JOIN
  afiliacion b
  on a.codigo_unico = b.cod_unico
;

compute stats {zona_p}.vinculaciones_comercios_adq_cincox;