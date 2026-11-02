@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AI 수요예측 정확도 KPI 분석'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_DPA_ACCURACY_KPI
  as select from ZC_DPA_ACCURACY as Base
{
      // Forecast 식별정보
  key Base.Fcsno as Fcsno,
  key Base.Iteno as Iteno,

      Base.Werks as Werks,
      Base.Matnr as Matnr,
      Base.Fcdat as Fcdat,
      Base.Tcdat as Tcdat,
      Base.Bsdat as Bsdat,
      Base.Cstat as Cstat,
      Base.Cdate as Cdate,
      Base.Ctime as Ctime,
      Base.Activ as Activ,

      // 수량 정보
      @Semantics.quantity.unitOfMeasure: 'Meins'
      Base.Aiqty as Aiqty,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Base.Fiqty as Fiqty,

      // 실제 주문이 없으면 0으로 처리
      coalesce(
        get_numeric_value( Base.ActualQty ),
        cast( 0 as abap.dec( 13, 3 ) )
      )          as ActualQty,

      // 오차수량 (양수: 과대예측 / 음수: 과소예측)
      get_numeric_value( Base.Aiqty )
        - coalesce(
            get_numeric_value( Base.ActualQty ),
            cast( 0 as abap.dec( 13, 3 ) )
          )      as AiErrQty,

      get_numeric_value( Base.Fiqty )
        - coalesce(
            get_numeric_value( Base.ActualQty ),
            cast( 0 as abap.dec( 13, 3 ) )
          )      as FiErrQty,

      // 예측 평가 상태
      case
        when Base.Fcdat > $session.system_date
          then 'WAIT'

        when Base.Tcdat >= $session.system_date
          then 'PROG'

        else 'DONE'
      end        as EvalStatus,

      Base.Meins as Meins
}
