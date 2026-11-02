@EndUserText.label: 'SO별 청구 요약'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_SD_BILL_SUM
  as select from ztsda00060 as bi
    inner join   ztsda00050 as bh on bh.bilno = bi.bilno
    inner join   ztsda00040 as di on  di.vbeln = bi.vleln
                                  and di.posnr = bi.posnr
{
  key di.vgbel        as SoNumber,
      min( bh.bilno ) as BillNo,
      max( bh.bildt ) as BillDate
}
group by
  di.vgbel
