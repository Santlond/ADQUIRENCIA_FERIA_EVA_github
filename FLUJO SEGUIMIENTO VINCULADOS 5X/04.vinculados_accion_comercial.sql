DROP TABLE IF exists {zona_p}.wompi_vac_cincox PURGE; 
CREATE TABLE {zona_p}.wompi_vac_cincox
PARTITIONED  BY (periodo) STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
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
    , fuente		
    , periodo
FROM {zona_p}.plink_wmv
WHERE fuente is not null
;

compute stats {zona_p}.wompi_vac_cincox;