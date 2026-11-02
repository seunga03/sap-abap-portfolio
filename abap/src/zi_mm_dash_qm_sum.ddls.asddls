@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 구매품목별 검사 집계'
define view entity ZI_MM_DASH_QM_SUM
  as select from ZI_MM_DASH_INSPECTION
{
  key ebeln,
  key ebelp,
  key meins,

      @EndUserText.label: '검사수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( insqt ) as insqty,

      @EndUserText.label: '합격수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( pasqt ) as passqty,

      @EndUserText.label: '불량수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( faiqt ) as failqty
}
where ebeln <> ' '
group by
  ebeln,
  ebelp,
  meins
