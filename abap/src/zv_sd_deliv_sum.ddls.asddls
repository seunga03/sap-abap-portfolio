@EndUserText.label: 'SO별 납품 요약'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_SD_DELIV_SUM
  as select from ztsda00040 as di
    inner join   ztsda00030 as dh on dh.vbeln = di.vbeln
{
  key di.vgbel        as SoNumber,
      min( dh.vbeln ) as DoNumber,
      min( dh.tddat ) as PlannedGI,
      max( dh.acgdt ) as ActualGI
}
group by
  di.vgbel
