
-- DROP TABLE IF exists {zona_p}.trx_comercios_adq_vinculados_cincox PURGE; 
-- CREATE TABLE {zona_p}.trx_comercios_adq_vinculados_cincox
-- STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS

-- WITH adq_trx_all as(
--   SELECT 
--     cod_unico
--     , sum(mnt_total_trx) as monto_total
--   FROM resultados_vspc_medios_de_pago.gsap_m_transaccional
--   WHERE year = {ATRX[year]}
--   AND year()
--   --and f_trx BETWEEN date_sub(trunc(current_date(),'MM'), interval 6 month) and last_day(date_sub(trunc(current_date(),'MM'), interval 1 day))
--   GROUP BY 1
-- ),

-- actividad as (
-- select
-- cod_unico
-- , if(monto_total > 0, 'Si', 'No') as trx_ultimos_6m
-- from adq_trx_all
-- ),

-- adq_trx_mc as (
-- select 
--   cod_unico
--   , count(*) as trx_mastercard
--   , sum(mnt_total_trx) as monto_mastercard
-- FROM resultados_vspc_medios_de_pago.gsap_m_transaccional
-- WHERE year = {ATRX[year]}
-- and f_trx BETWEEN date_sub(trunc(current_date(),'MM'), interval 6 month) and last_day(date_sub(trunc(current_date(),'MM'), interval 1 day))
-- and descri_franq like 'Mastercard'
-- and estado_trx like 'Cleared'
-- group by 1
-- )

-- select
--     t0.cod_unico
--     , t0.trx_ultimos_6m
--     , sum(t1.trx_mastercard) as trx_mastercard
--     , sum(t1.monto_mastercard) as monto_mastercard
-- from actividad t0
-- left join adq_trx_mc t1 ON t0.cod_unico = t1.cod_unico
-- GROUP BY 1,2
-- ; 

-- compute stats {zona_p}.trx_comercios_adq_vinculados_cincox;



DROP TABLE IF exists {zona_p}.trx_comercios_adq_vinculados_cincox PURGE;
CREATE TABLE {zona_p}.trx_comercios_adq_vinculados_cincox
STORED AS PARQUET TBLPROPERTIES('transactional' = 'false') AS
 
WITH adq_trx_all as(
    SELECT
        cod_unico
        , f_trx
        , descri_franq AS franquicia
        , estado_trx
        , sum(mnt_total_trx) as monto_total
        , count(*) as num_trx
    FROM
        resultados_vspc_medios_de_pago.gsap_m_transaccional
    WHERE
        year = {ATRX[year]} --- la primera semana de enero year = {WTRX[year]} - 1
        AND year(f_trx) = YEAR(NOW()) --- la primera semana de enero year(f_trx) = YEAR(NOW()) - 1
        AND UPPER(TRIM(estado_trx)) = 'CLEARED'
    GROUP BY 1, 2, 3, 4
),

adquirencia_trx_mes_a_mes AS ( 
    SELECT
        cod_unico
        , SUM(IF(MONTH(f_trx) = 1, monto_total, 0)) AS monto_enero
        , SUM(IF(MONTH(f_trx) = 2, monto_total, 0)) AS monto_febrero
        , SUM(IF(MONTH(f_trx) = 3, monto_total, 0)) AS monto_marzo
        , SUM(IF(MONTH(f_trx) = 4, monto_total, 0)) AS monto_abril
        , SUM(IF(MONTH(f_trx) = 5, monto_total, 0)) AS monto_mayo
        , SUM(IF(MONTH(f_trx) = 6, monto_total, 0)) AS monto_junio
        , SUM(IF(MONTH(f_trx) = 7, monto_total, 0)) AS monto_julio
        , SUM(IF(MONTH(f_trx) = 8, monto_total, 0)) AS monto_agosto
        , SUM(IF(MONTH(f_trx) = 9, monto_total, 0)) AS monto_septiembre
        , SUM(IF(MONTH(f_trx) = 10, monto_total, 0)) AS monto_octubre
        , SUM(IF(MONTH(f_trx) = 11, monto_total, 0)) AS monto_noviembre
        , SUM(IF(MONTH(f_trx) = 12, monto_total, 0)) AS monto_diciembre

        -- para franquicia mastercard monto trx
        , SUM(IF(MONTH(f_trx) = 1
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_enero_mc
        , SUM(IF(MONTH(f_trx) = 2
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_febrero_mc
        ,SUM(IF(MONTH(f_trx) = 3
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_marzo_mc
        , SUM(IF(MONTH(f_trx) = 4
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_abril_mc
        , SUM(IF(MONTH(f_trx) = 5
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_mayo_mc
        , SUM(IF(MONTH(f_trx) = 6
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_junio_mc
        , SUM(IF(MONTH(f_trx) = 7
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_julio_mc
        , SUM(IF(MONTH(f_trx) = 8
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_agosto_mc
        , SUM(IF(MONTH(f_trx) = 9
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_septiembre_mc
        , SUM(IF(MONTH(f_trx) = 10
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_octubre_mc
        , SUM(IF(MONTH(f_trx) = 11
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_noviembre_mc
        , SUM(IF(MONTH(f_trx) = 12
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', monto_total, 0)) AS monto_diciembre_mc

        -- para franquicia mastercard num trx
        , SUM(IF(MONTH(f_trx) = 1
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_enero
        , SUM(IF(MONTH(f_trx) = 2
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_febrero
        ,SUM(IF(MONTH(f_trx) = 3
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_marzo
        , SUM(IF(MONTH(f_trx) = 4
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_abril
        , SUM(IF(MONTH(f_trx) = 5
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_mayo
        , SUM(IF(MONTH(f_trx) = 6
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_junio
        , SUM(IF(MONTH(f_trx) = 7
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_julio
        , SUM(IF(MONTH(f_trx) = 8
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_agosto
        , SUM(IF(MONTH(f_trx) = 9
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_septiembre
        , SUM(IF(MONTH(f_trx) = 10
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_octubre
        , SUM(IF(MONTH(f_trx) = 11
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_noviembre
        , SUM(IF(MONTH(f_trx) = 12
            AND UPPER(TRIM(franquicia)) = 'MASTERCARD', num_trx, 0)) AS num_trx_mc_diciembre
    FROM
        adq_trx_all
    GROUP BY 1
)

SELECT
    cod_unico
    , IF(monto_enero > 0, 'Si', 'No') AS adquirencia_activo_enero
    , IF(monto_febrero > 0, 'Si', 'No') AS adquirencia_activo_febrero
    , IF(monto_marzo > 0, 'Si', 'No') AS adquirencia_activo_marzo
    , IF(monto_abril > 0, 'Si', 'No') AS adquirencia_activo_abril
    , IF(monto_mayo > 0, 'Si', 'No') AS adquirencia_activo_mayo
    , IF(monto_junio > 0, 'Si', 'No') AS adquirencia_activo_junio
    , IF(monto_julio > 0, 'Si', 'No') AS adquirencia_activo_julio
    , IF(monto_agosto > 0, 'Si', 'No') AS adquirencia_activo_agosto
    , IF(monto_septiembre > 0, 'Si', 'No') AS adquirencia_activo_septiembre
    , IF(monto_octubre > 0, 'Si', 'No') AS adquirencia_activo_octubre
    , IF(monto_noviembre > 0, 'Si', 'No') AS adquirencia_activo_noviembre
    , IF(monto_diciembre > 0, 'Si', 'No') AS adquirencia_activo_diciembre
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
    adquirencia_trx_mes_a_mes
;

compute stats {zona_p}.trx_comercios_adq_vinculados_cincox;