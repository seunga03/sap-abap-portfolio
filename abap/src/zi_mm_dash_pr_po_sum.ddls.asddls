@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 구매요청별 구매입고 집계'
define view entity ZI_MM_DASH_PR_PO_SUM
  as select from ZI_MM_DASH_PO_PROGRESS
{
  key banfn,
  key bnfpo,
  key matnr,
  key meins,

      @EndUserText.label: '구매오더 품목 수'
      count(*) as poitemcount,

      @EndUserText.label: '발주수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( menge ) as poqty,

      @EndUserText.label: '101 누적입고량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( grqty ) as grqty,

      @EndUserText.label: '미입고량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( openqty ) as openqty,

      @EndUserText.label: '검사수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( insqty ) as insqty,

      @EndUserText.label: '합격수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( passqty ) as passqty,

      @EndUserText.label: '불량수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( failqty ) as failqty,

      @EndUserText.label: '검사 후 재고전환량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      sum( releasedqty ) as releasedqty
}
where banfn <> ' '
group by
  banfn,
  bnfpo,
  matnr,
  meins
