@EndUserText.label: '자재별 조달 Lead Time'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZV_SD_LEADTIME
  as select from ztcma00040
{
  key matnr                              as Material,
      max( cast( plifz as abap.int4 ) )  as LeadDays
}
where priok = '0'
  and actyn = 'Y'
  and valfr <= $session.system_date
  and valto >= $session.system_date
group by matnr
