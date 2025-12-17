-- DROP TABLE IF exists {zona_p}.plink_comercios_wompi_cincox_trx PURGE;
-- CREATE TABLE  {zona_p}.plink_comercios_wompi_cincox_trx
-- STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
-- with wompi_trx_all as(
-- SELECT 
--     id_comercio
--     , sum(monto_transaccion/100) as monto_total
-- FROM resultados_wompi.wompi_transactions
-- where estado_transaccion = 'Aprobada' 
-- and to_timestamp(cast(fecha_creacion_transaccion as STRING), 'yyyyMMdd') BETWEEN date_sub(trunc(current_date(),'MM'), interval 6 month) and last_day(date_sub(trunc(current_date(),'MM'), interval 1 day))
-- and ingestion_year = {WTRX[year]}
-- GROUP BY 1
-- ORDER BY 2 asc
-- ), actividad as(
-- select
-- id_comercio
-- , if(monto_total = 0, 'No', 'Si') as trx_ultimos_6m
-- from wompi_trx_all
-- --where monto_total = 0
-- ), wompi_trx_mc as(
-- SELECT
-- (year*100+month) as periodo
-- , id_comercio
-- , count(*) as trx_mastercard
-- , sum(monto_transaccion/100) as monto_mastercard
-- from resultados_wompi.wompi_transactions
-- WHERE  to_timestamp(cast(fecha_creacion_transaccion as STRING), 'yyyyMMdd') BETWEEN date_sub(trunc(current_date(),'MM'), interval 6 month) and last_day(date_sub(trunc(current_date(),'MM'), interval 1 day))
-- and lower(franquicia) like 'mastercard'
-- and estado_transaccion = 'Aprobada' 
-- and medio_pago in ('Tarjetas venta presente','Tarjeta de credito','Datafono venta presente')
-- and ingestion_year = {WTRX[year]}
-- GROUP BY 1,2
-- )
-- select
--     t0.id_comercio
--     , t0.trx_ultimos_6m
--     , sum(t1.trx_mastercard) as trx_mastercard
--     , sum(t1.monto_mastercard) as monto_mastercard
-- from actividad t0
-- left join wompi_trx_mc t1 ON t0.id_comercio = t1.id_comercio
-- GROUP BY 1,2
-- ; 

-- compute stats {zona_p}.plink_comercios_wompi_cincox_trx;





DROP TABLE IF EXISTS {zona_p}.plink_comercios_wompi_cincox_trx PURGE;
 
CREATE TABLE {zona_p}.plink_comercios_wompi_cincox_trx
STORED AS PARQUET TBLPROPERTIES ("transactional" = "false") AS
 
with wompi_trx_all as(
    SELECT
        id_comercio
        , fecha_creacion_transaccion
        , franquicia
        , medio_pago
        , sum(monto_transaccion/100) as monto_total
        , count(*) as num_trx
    FROM
        resultados_wompi.wompi_transactions
    where
        UPPER(TRIM(estado_transaccion)) = 'APROBADA'
        and year = {WTRX[year]}
        --- la primera semana de enero year = {WTRX[year]} - 1
    GROUP BY 1, 2, 3, 4
),
 
wompi_trx_mes_a_mes AS (
    SELECT
        id_comercio
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 1, monto_total, 0)) AS monto_enero
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 2, monto_total, 0)) AS monto_febrero
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 3, monto_total, 0)) AS monto_marzo
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 4, monto_total, 0)) AS monto_abril
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 5, monto_total, 0)) AS monto_mayo
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 6, monto_total, 0)) AS monto_junio
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 7, monto_total, 0)) AS monto_julio
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 8, monto_total, 0)) AS monto_agosto
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 9, monto_total, 0)) AS monto_septiembre
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 10, monto_total, 0)) AS monto_octubre
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 11, monto_total, 0)) AS monto_noviembre
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 12, monto_total, 0)) AS monto_diciembre
 
        -- para franquicia mastercard monto trx
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 1
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_enero_mc
        , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 2
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_febrero_mc
        ,SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 3
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_marzo_mc
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 4
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_abril_mc
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 5
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_mayo_mc
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 6
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_junio_mc
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 7
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_julio_mc
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 8
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_agosto_mc
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 9
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_septiembre_mc
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 10
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_octubre_mc
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 11
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_noviembre_mc
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 12
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), monto_total, 0)) AS monto_diciembre_mc
 
            -- para franquicia mastercard num trx
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 1
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_enero
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 2
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_febrero
            ,SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 3
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_marzo
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 4
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_abril
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 5
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_mayo
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 6
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_junio
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 7
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_julio
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 8
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_agosto
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 9
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_septiembre
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 10
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_octubre
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 11
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_noviembre
            , SUM(IF(CAST(SUBSTR(cast(fecha_creacion_transaccion AS STRING), 5, 2) AS INT) = 12
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD'
            AND UPPER(TRIM(medio_pago)) IN ('TARJETAS VENTA PRESENTE','TARJETA DE CREDITO','DATAFONO VENTA PRESENTE'), num_trx, 0)) AS num_trx_mc_diciembre
    FROM
        wompi_trx_all
    GROUP BY 1
)
 
SELECT
    id_comercio
    , IF(monto_enero > 0, 'Si', 'No') AS wompi_activo_enero
    , IF(monto_febrero > 0, 'Si', 'No') AS wompi_activo_febrero
    , IF(monto_marzo > 0, 'Si', 'No') AS wompi_activo_marzo
    , IF(monto_abril > 0, 'Si', 'No') AS wompi_activo_abril
    , IF(monto_mayo > 0, 'Si', 'No') AS wompi_activo_mayo
    , IF(monto_junio > 0, 'Si', 'No') AS wompi_activo_junio
    , IF(monto_julio > 0, 'Si', 'No') AS wompi_activo_julio
    , IF(monto_agosto > 0, 'Si', 'No') AS wompi_activo_agosto
    , IF(monto_septiembre > 0, 'Si', 'No') AS wompi_activo_septiembre
    , IF(monto_octubre > 0, 'Si', 'No') AS wompi_activo_octubre
    , IF(monto_noviembre > 0, 'Si', 'No') AS wompi_activo_noviembre
    , IF(monto_diciembre > 0, 'Si', 'No') AS wompi_activo_diciembre
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
FROM
    wompi_trx_mes_a_mes
;
 
COMPUTE STATS {zona_p}.plink_comercios_wompi_cincox_trx;
 
 
-- SELECT
--     SUM(monto_enero_mc) AS total_monto_enero_mc,
--     SUM(monto_febrero_mc) AS total_monto_febrero_mc,
--     SUM(monto_marzo_mc) AS total_monto_marzo_mc,
--     SUM(monto_abril_mc) AS total_monto_abril_mc,
--     SUM(monto_mayo_mc) AS total_monto_mayo_mc,
--     SUM(monto_junio_mc) AS total_monto_junio_mc,
--     SUM(monto_julio_mc) AS total_monto_julio_mc,
--     SUM(monto_agosto_mc) AS total_monto_agosto_mc,
--     SUM(monto_septiembre_mc) AS total_monto_septiembre_mc,
--     SUM(monto_octubre_mc) AS total_monto_octubre_mc,
--     SUM(monto_noviembre_mc) AS total_monto_noviembre_mc,
--     SUM(monto_diciembre_mc) AS total_monto_diciembre_mc,
 
--     SUM(num_trx_mc_enero) AS total_num_trx_mc_enero,
--     SUM(num_trx_mc_febrero) AS total_num_trx_mc_febrero,
--     SUM(num_trx_mc_marzo) AS total_num_trx_mc_marzo,
--     SUM(num_trx_mc_abril) AS total_num_trx_mc_abril,
--     SUM(num_trx_mc_mayo) AS total_num_trx_mc_mayo,
--     SUM(num_trx_mc_junio) AS total_num_trx_mc_junio,
--     SUM(num_trx_mc_julio) AS total_num_trx_mc_julio,
--     SUM(num_trx_mc_agosto) AS total_num_trx_mc_agosto,
--     SUM(num_trx_mc_septiembre) AS total_num_trx_mc_septiembre,
--     SUM(num_trx_mc_octubre) AS total_num_trx_mc_octubre,
--     SUM(num_trx_mc_noviembre) AS total_num_trx_mc_noviembre,
--     SUM(num_trx_mc_diciembre) AS total_num_trx_mc_diciembre
-- FROM
--     proceso.trx_wompi_jj AS t1
-- INNER JOIN
--     proceso_consumidores.plink_comercios_wompi_cincox AS t2
-- ON
--     t1.id_comercio = t2.id_comercio
-- ;