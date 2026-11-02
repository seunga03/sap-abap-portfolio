@EndUserText.label: '판매오더 품목 합계'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_SD_ITEM_SUM
  as select from ztsda00020
{
  key vbeln                                   as vbeln,
      count(*)                                as ItemCount,
      sum( cast( kwmeng as abap.dec(15,3) ) ) as TotalQty,
      min( reqdt )                            as ReqDate
}
group by
  vbeln
