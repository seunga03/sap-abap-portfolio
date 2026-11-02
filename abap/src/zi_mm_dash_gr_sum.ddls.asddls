@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 구매입고 집계'
define view entity ZI_MM_DASH_GR_SUM
  as select from ZI_MM_DASH_MOVEMENT
{
      @EndUserText.label: '구매오더'
  key ebeln,

      @EndUserText.label: '구매오더 품목'
  key ebelp,

      @EndUserText.label: '단위'
  key meins,

      @EndUserText.label: '101 누적입고량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( menge ) as grqty
}
where
      bwart = '101'
  and ebeln <> ' '
group by
  ebeln,
  ebelp,
  meins
