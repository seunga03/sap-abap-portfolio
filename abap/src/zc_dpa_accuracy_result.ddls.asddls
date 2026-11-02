@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AI 수요예측 정확도 최종 분석'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_DPA_ACCURACY_RESULT
  as select from ZC_DPA_ACCURACY_KPI as Base
{
      // Forecast 식별정보
  key Base.Fcsno               as Fcsno,
  key Base.Iteno               as Iteno,

      Base.Werks               as Werks,
      Base.Matnr               as Matnr,
      Base.Fcdat               as Fcdat,
      Base.Tcdat               as Tcdat,
      Base.Bsdat               as Bsdat,
      Base.Cstat               as Cstat,
      Base.Cdate               as Cdate,
      Base.Ctime               as Ctime,
      Base.Activ               as Activ,
      Base.EvalStatus          as EvalStatus,

      // 수량 정보
      @Semantics.quantity.unitOfMeasure: 'Meins'
      Base.Aiqty               as Aiqty,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Base.Fiqty               as Fiqty,

      Base.ActualQty           as ActualQty,
      Base.AiErrQty            as AiErrQty,
      Base.FiErrQty            as FiErrQty,

      // 절대오차
      abs( Base.AiErrQty )     as AiAbsErr,

      abs( Base.FiErrQty )     as FiAbsErr,

      // 담당자 보정 효과
      // 양수: 개선, 음수: 악화
      abs( Base.AiErrQty )
        - abs( Base.FiErrQty ) as AdjEffect,

      // AI 오차율 (%)
      // 완료된 기간 + 실제수요 > 0일 때만 계산
      case
        when Base.EvalStatus = 'DONE'
         and Base.ActualQty > 0
        then division(
               cast(
                 abs( Base.AiErrQty ) * 100
                 as abap.dec( 20, 3 )
               ),
               cast(
                 Base.ActualQty
                 as abap.dec( 18, 3 )
               ),
               2
             )
      end                      as AiApe,

      // 최종 예측 오차율 (%)
      case
        when Base.EvalStatus = 'DONE'
         and Base.ActualQty > 0
        then division(
               cast(
                 abs( Base.FiErrQty ) * 100
                 as abap.dec( 20, 3 )
               ),
               cast(
                 Base.ActualQty
                 as abap.dec( 18, 3 )
               ),
               2
             )
      end                      as FiApe,


      // 예측기간 종료 여부
      // X: 기간 종료 / 공백: 평가 대기 또는 진행 중
      case
        when Base.EvalStatus = 'DONE'
          then 'X'
        else ' '
      end                      as EvalEligible,

      // APE 계산 가능 여부
      // 기간 종료 + 실제 주문수량이 0보다 큰 경우
      case
        when Base.EvalStatus = 'DONE'
         and Base.ActualQty > 0
          then 'X'
        else ' '
      end                      as ApeAvailable,

      Base.Meins               as Meins

}
