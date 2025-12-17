--- wompi maestri vinculaciones (tiene los de accion comercial)


DROP TABLE IF EXISTS {zona_p}.plink_wmv PURGE; 
CREATE TABLE {zona_p}.plink_wmv
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS


select distinct
t0.id_comercio
, t0.num_doc
, t0.modelo
, t0.nombre_comercio
, t0.plan_dispersion
, t0.segm
, t0.subsegm
, t0.marca_gerenciado
, t0.codigo_asesor
, t0.cod_ventas
, t0.usuario
, t0.nombre_usuario
, t0.cod_cargo
, t0.cargo_usuario
, t0.descri_zona
, t0.descri_region
-- , isnull(t1.trx_ultimos_6m,'No') as trx_ultimos_6m
-- , isnull(t1.monto_mastercard, 0) as monto_mastercard
-- , isnull(t1.trx_mastercard, 0) as trx_mastercard
, t0.fuente
, t0.periodo
from {zona_p}.plink_comercios_wompi_cincox t0
--    left join {zona_p}.plink_comercios_wompi_cincox_trx t1
--   on t0.id_comercio = t1.id_comercio
--   )
--  select
--  *
--  from a
;

compute stats {zona_p}.plink_wmv;