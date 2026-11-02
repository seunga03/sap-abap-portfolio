@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 구매입고 진행'
define view entity ZI_MM_DASH_PO_PROGRESS
  as select from ZI_MM_DASH_PO as po

    left outer join ZI_MM_DASH_GR_SUM as gr
      on  gr.ebeln = po.ebeln
      and gr.ebelp = po.ebelp
      and gr.meins = po.meins

    left outer join ZI_MM_DASH_QM_SUM as qm
      on  qm.ebeln = po.ebeln
      and qm.ebelp = po.ebelp
      and qm.meins = po.meins

    left outer join ZI_MM_DASH_QM_MOVE_SUM as qm_move
      on  qm_move.ebeln = po.ebeln
      and qm_move.ebelp = po.ebelp
      and qm_move.meins = po.meins
{
  key po.ebeln,
  key po.ebelp,

      po.bedat,
      po.lifnr,
      po.bukrs,
      po.ekorg,
      po.ekgrp,
      po.pstat,

      po.werks,
      po.wname,
      po.lgort,
      po.lgobe,
      po.matnr,
      po.maktx,

      @EndUserText.label: '주문수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      po.menge,

      @EndUserText.label: '101 누적입고량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( gr.grqty as abap.dec(13,3) ),
          0
        )
        as abap.quan(13,3)
      ) as grqty,

      @EndUserText.label: '미입고량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        cast( po.menge as abap.dec(13,3) )
        -
        coalesce(
          cast( gr.grqty as abap.dec(13,3) ),
          0
        )
        as abap.quan(13,3)
      ) as openqty,

      @EndUserText.label: '검사수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( qm.insqty as abap.dec(13,3) ),
          0
        )
        as abap.quan(13,3)
      ) as insqty,

      @EndUserText.label: '합격수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( qm.passqty as abap.dec(13,3) ),
          0
        )
        as abap.quan(13,3)
      ) as passqty,

      @EndUserText.label: '불량수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( qm.failqty as abap.dec(13,3) ),
          0
        )
        as abap.quan(13,3)
      ) as failqty,

      @EndUserText.label: '검사 후 재고전환량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( qm_move.releasedqty as abap.dec(13,3) ),
          0
        )
        as abap.quan(13,3)
      ) as releasedqty,

      po.meins,

      @Semantics.amount.currencyCode: 'waers'
      po.netpr,

      @EndUserText.label: '발주금액'
      @Semantics.amount.currencyCode: 'waers'
      cast(
        cast( po.menge as abap.dec(13,3) )
        *
        cast( po.netpr as abap.dec(11,2) )
        as abap.curr(23,2)
      ) as poamount,

      po.waers,
      po.eindt,
      po.banfn,
      po.bnfpo,
      po.ptype
}
