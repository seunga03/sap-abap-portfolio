@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 검사 후 재고전환 집계'
define view entity ZI_MM_DASH_QM_MOVE_SUM
  as select from ZI_MM_DASH_MOVEMENT
{
  key ebeln,
  key ebelp,
  key meins,

      @EndUserText.label: '검사 후 재고전환량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( menge ) as releasedqty
}
where
      ( bwart = '321' or bwart = '654' )
  and ebeln <> ' '
group by
  ebeln,
  ebelp,
  meins
