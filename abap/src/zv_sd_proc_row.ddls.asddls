@EndUserText.label: '판매오더 예약재고 행별 조달 판단'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZV_SD_PROC_ROW
  as select from ztmma00150 as r
    left outer join ZV_SD_LEADTIME as l on l.Material = r.matnr
{
  r.vbeln as SoNumber,
  r.matnr as Material,
  case when cast( r.ordqt as abap.dec(15,3) )
          - cast( r.sumqt as abap.dec(15,3) )
          - cast( r.avlqt as abap.dec(15,3) ) > 0
       then 1 else 0 end as IsShort,
  case when cast( r.ordqt as abap.dec(15,3) )
          - cast( r.sumqt as abap.dec(15,3) )
          - cast( r.avlqt as abap.dec(15,3) ) > 0
       then coalesce( l.LeadDays, 0 ) else 0 end as ShortLead
}
