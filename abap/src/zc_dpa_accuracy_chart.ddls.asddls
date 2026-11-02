@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '수요예측 3중 비교 차트'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_DPA_ACCURACY_CHART
  as select from ZC_DPA_ACCURACY_UI as Base
{
      // 분석 차원
  key Base.Fcsno                                  as Fcsno,
  key Base.Iteno                                  as Iteno,

      Base.Werks                                  as Werks,
      Base.Matnr                                  as Matnr,
      Base.Fcdat                                  as Fcdat,
      Base.Tcdat                                  as Tcdat,
      Base.EvalStatus                             as EvalStatus,
      Base.Meins                                  as Meins,

      // 차트 측정값 ① AI 원본 예측
      @Aggregation.default: #SUM
      @EndUserText.label: 'AI 원본 예측수량'
      cast( Base.Aiqty as abap.dec( 20, 3 ) )     as AiForecastQty,

      // 차트 측정값 ② 최종 확정 예측
      @Aggregation.default: #SUM
      @EndUserText.label: '최종 확정수량'
      cast( Base.Fiqty as abap.dec( 20, 3 ) )     as FinalForecastQty,

      // 차트 측정값 ③ 실제 SO 수요
      @Aggregation.default: #SUM
      @EndUserText.label: '실제 고객 주문수량'
      cast( Base.ActualQty as abap.dec( 20, 3 ) ) as ActualDemandQty
}
where
  Base.Activ = 'X'
