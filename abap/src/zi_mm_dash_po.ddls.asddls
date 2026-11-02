@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 구매오더'
define view entity ZI_MM_DASH_PO
  as select from ztmma00060 as item

    inner join ztmma00050 as head
      on head.ebeln = item.ebeln

    left outer join ztcma00020 as material
      on material.matnr = item.matnr

    left outer join ZI_MM_DASH_PLANT as plant
      on plant.werks = item.werks

    left outer join ZI_MM_DASH_STORAGE as storage
      on  storage.werks = item.werks
      and storage.lgort = item.lgort
{
      @EndUserText.label: '구매오더'
  key item.ebeln,

      @EndUserText.label: '구매오더 품목'
  key item.ebelp,

      @EndUserText.label: '구매오더일'
      head.bedat,

      @EndUserText.label: '공급업체'
      head.lifnr,

      @EndUserText.label: '회사코드'
      head.bukrs,

      @EndUserText.label: '구매조직'
      head.ekorg,

      @EndUserText.label: '구매그룹'
      head.ekgrp,

      @EndUserText.label: '진행상태'
      head.pstat,

      @EndUserText.label: '플랜트'
      item.werks,

      @EndUserText.label: '플랜트명'
      plant.name1 as wname,

      @EndUserText.label: '창고'
      item.lgort,

      @EndUserText.label: '창고명'
      storage.lgobe,

      @EndUserText.label: '자재'
      item.matnr,

      @EndUserText.label: '자재명'
      material.maktx,

      @EndUserText.label: '주문수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      item.menge,

      @EndUserText.label: '단위'
      item.meins,

      @EndUserText.label: '구매단가'
      @Semantics.amount.currencyCode: 'waers'
      item.netpr,

      @EndUserText.label: '통화'
      item.waers,

      @EndUserText.label: '납품예정일'
      item.eindt,

      @EndUserText.label: '구매요청'
      item.banfn,

      @EndUserText.label: '구매요청 품목'
      item.bnfpo,

      @EndUserText.label: '조달유형'
      item.ptype
}
