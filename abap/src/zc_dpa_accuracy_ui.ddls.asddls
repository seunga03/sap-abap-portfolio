@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AI 수요예측 정확도 UI 데이터'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity ZC_DPA_ACCURACY_UI
  as select from ZC_DPA_ACCURACY_RESULT as Result
{
      // Forecast 식별정보
  key Result.Fcsno        as Fcsno,
  key Result.Iteno        as Iteno,

      Result.Werks        as Werks,
      Result.Matnr        as Matnr,
      Result.Fcdat        as Fcdat,
      Result.Tcdat        as Tcdat,
      Result.Cdate        as Cdate,
      Result.Ctime        as Ctime,
      Result.Activ        as Activ,
      Result.EvalStatus   as EvalStatus,

      // 예측수량
      @Semantics.quantity.unitOfMeasure: 'Meins'
      Result.Aiqty        as Aiqty,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Result.Fiqty        as Fiqty,

      // 실제 주문수량
      cast(
        Result.ActualQty as abap.dec( 20, 3 )
      )                   as ActualQty,

      // AI / 최종 예측 오차수량
      cast(
        Result.AiErrQty as abap.dec( 20, 3 )
      )                   as AiErrQty,

      cast(
        Result.FiErrQty as abap.dec( 20, 3 )
      )                   as FiErrQty,

      // 절대오차
      cast(
        Result.AiAbsErr as abap.dec( 20, 3 )
      )                   as AiAbsErr,

      cast(
        Result.FiAbsErr as abap.dec( 20, 3 )
      )                   as FiAbsErr,

      // 담당자 조정 효과
      cast(
        Result.AdjEffect as abap.dec( 20, 3 )
      )                   as AdjEffect,

      // 오차율(%)
      cast(
        Result.AiApe as abap.dec( 15, 2 )
      )                   as AiApe,

      cast(
        Result.FiApe as abap.dec( 15, 2 )
      )                   as FiApe,

      // 평가 가능 여부
      Result.EvalEligible as EvalEligible,
      Result.ApeAvailable as ApeAvailable,

      // 수량 단위
      Result.Meins        as Meins
}
