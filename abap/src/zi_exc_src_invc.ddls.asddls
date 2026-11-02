@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '송장 정산 상세 (CM03 소스 섹션)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_EXC_SRC_INVC
  as select from ztfia00020 as it
    inner join   ztfia00010 as hd
      on  hd.ivnum = it.ivnum
    left outer join ztcma00010 as vn
      on  vn.lifnr = hd.lifnr
    left outer join ztmma00060 as po
      on  po.ebeln = hd.ebeln
      and po.ebelp = it.ebelp
{
  key it.ivnum                          as ivnum,
  key it.invit                          as invit,
      cast( 'INVC' as abap.char(4) )    as srtyp,
      hd.ebeln                          as ebeln,
      it.ebelp                          as ebelp,
      hd.lifnr                          as lifnr,
      vn.name1                          as name1,
      it.matnr                          as matnr,
      @Semantics.quantity.unitOfMeasure: 'meins'
      it.menge                          as menge,
      it.meins                          as meins,
      hd.waers                          as waers,
      @Semantics.amount.currencyCode: 'waers'
      it.netpr                          as netpr,
      @Semantics.amount.currencyCode: 'waers'
      it.wrbtr                          as wrbtr,

      // ★ PO 단가 (PO 아이템이 없으면 0)
      @Semantics.amount.currencyCode: 'waers'
      cast( coalesce( cast( po.netpr as abap.dec(11,2) ),
                      cast( 0 as abap.dec(11,2) ) ) as abap.curr(11,2) )
                                        as po_netpr,

      // ★ 차이금액 = 청구금액 - 청구수량 × PO단가 (PO 단가가 없으면 0)
      @Semantics.amount.currencyCode: 'waers'
      cast( case when po.netpr is null
                  then cast( 0 as abap.dec(23,2) )
                  else cast( it.wrbtr as abap.dec(23,2) )
                       - cast( it.menge as abap.dec(13,3) )
                         * cast( po.netpr as abap.dec(11,2) )
             end as abap.curr(23,2) )   as diff_amt,

      it.mstat                          as mstat,
      cast( case it.mstat
              when 'WAIT' then '대사대기'
              when 'PASS' then '대사통과'
              when 'HOLD' then '대사보류'
              when 'QREJ' then '수량초과반려'
              when 'FREJ' then '최종반려'
              else it.mstat
            end as abap.char(12) )      as mstat_text,
      hd.vdudt                          as vdudt
}
