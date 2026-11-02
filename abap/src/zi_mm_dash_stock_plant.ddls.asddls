@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 플랜트별 재고 집계'
define view entity ZI_MM_DASH_STOCK_PLANT
  as select from ZI_MM_DASH_STOCK
{
  key werks,
  key matnr,
  key meins,

      wname,
      maktx,

      @EndUserText.label: '플랜트 가용재고'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( stqty ) as stqty,

      @EndUserText.label: '플랜트 예약재고'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( rsqty ) as rsqty,

      @EndUserText.label: '플랜트 검사재고'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( qisty ) as qisty
}
group by
  werks,
  matnr,
  meins,
  wname,
  maktx
