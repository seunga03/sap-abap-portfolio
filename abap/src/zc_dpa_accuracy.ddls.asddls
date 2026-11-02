@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AI 수요예측 정확도 분석'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_DPA_ACCURACY
  as select from    ZI_DPA_FORECAST  as Forecast

    left outer join ZI_DPA_SO_ACTUAL as Actual on  Actual.Werks =  Forecast.Werks
                                               and Actual.Matnr =  Forecast.Matnr
                                               and Actual.Meins =  Forecast.Meins
                                               and Actual.Audat >= Forecast.Fcdat
                                               and Actual.Audat <= Forecast.Tcdat
{
      // 예측 식별자
  key Forecast.Fcsno          as Fcsno,
  key Forecast.Iteno          as Iteno,

      // 분석 기준정보
      Forecast.Werks          as Werks,
      Forecast.Matnr          as Matnr,
      Forecast.Fcdat          as Fcdat,
      Forecast.Tcdat          as Tcdat,
      Forecast.Bsdat          as Bsdat,
      Forecast.Cstat          as Cstat,
      Forecast.Cdate          as Cdate,
      Forecast.Ctime          as Ctime,
      Forecast.Activ          as Activ,

      // AI 원본 예측수량
      @Semantics.quantity.unitOfMeasure: 'Meins'
      Forecast.Aiqty          as Aiqty,

      // 담당자 보정 후 최종수량
      @Semantics.quantity.unitOfMeasure: 'Meins'
      Forecast.Fiqty          as Fiqty,

      // 실제 고객 주문수량
      @Semantics.quantity.unitOfMeasure: 'Meins'
      sum( Actual.ActualQty ) as ActualQty,

      Forecast.Meins          as Meins

}

group by
    Forecast.Fcsno,
    Forecast.Iteno,
    Forecast.Werks,
    Forecast.Matnr,
    Forecast.Fcdat,
    Forecast.Tcdat,
    Forecast.Bsdat,
    Forecast.Cstat,
    Forecast.Cdate,
    Forecast.Ctime,
    Forecast.Activ,
    Forecast.Aiqty,
    Forecast.Fiqty,
    Forecast.Meins
