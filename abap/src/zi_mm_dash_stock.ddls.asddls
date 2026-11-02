@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 자재 재고'
define view entity ZI_MM_DASH_STOCK
  as select from ztmma00070 as stock

    left outer join ztcma00020 as material
      on material.matnr = stock.matnr

    left outer join ZI_MM_DASH_PLANT as plant
      on plant.werks = stock.werks

    left outer join ZI_MM_DASH_STORAGE as storage
      on  storage.werks = stock.werks
      and storage.lgort = stock.lgort
{
      @EndUserText.label: '플랜트'
  key stock.werks,

      @EndUserText.label: '창고'
  key stock.lgort,

      @EndUserText.label: '자재'
  key stock.matnr,

      @EndUserText.label: '플랜트명'
      plant.name1 as wname,

      @EndUserText.label: '창고명'
      storage.lgobe,

      @EndUserText.label: '자재명'
      material.maktx,

      @EndUserText.label: '자재유형'
      material.mtart,

      @EndUserText.label: '가용재고'
      @Semantics.quantity.unitOfMeasure: 'meins'
      stock.stqty,

      @EndUserText.label: '예약재고'
      @Semantics.quantity.unitOfMeasure: 'meins'
      stock.rsqty,

      @EndUserText.label: '검사대기재고'
      @Semantics.quantity.unitOfMeasure: 'meins'
      stock.qisty,

      @EndUserText.label: '단위'
      stock.meins
}
