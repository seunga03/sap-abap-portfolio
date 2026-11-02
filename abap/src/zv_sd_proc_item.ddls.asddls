@EndUserText.label: '판매오더 품목별 조달 현황'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZV_SD_PROC_ITEM
  as select from ztmma00150 as r
    left outer join ZV_SD_LEADTIME as l on l.Material = r.matnr
{
  key r.vbeln as SoNumber,
  key r.posnr as ItemNo,
      r.matnr as Material,
      r.meins as Unit,
      cast( r.ordqt as abap.dec(15,3) ) as OrderQty,
      cast( r.sumqt as abap.dec(15,3) ) as IssuedQty,
      cast( r.avlqt as abap.dec(15,3) ) as ReservedQty,
      case when cast( r.ordqt as abap.dec(15,3) ) - cast( r.sumqt as abap.dec(15,3) ) - cast( r.avlqt as abap.dec(15,3) ) > 0
           then cast( cast( r.ordqt as abap.dec(15,3) ) - cast( r.sumqt as abap.dec(15,3) ) - cast( r.avlqt as abap.dec(15,3) ) as abap.dec(15,3) )
           else cast( 0 as abap.dec(15,3) ) end as ShortQty,
      cast( coalesce( l.LeadDays, 0 ) as abap.int4 ) as LeadDays
}
