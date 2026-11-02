@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '채권채무 만기 구간별 합계'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_FI_OPEN_SUM
  with parameters
    @Environment.systemField: #SYSTEM_DATE
    p_keydt : abap.dats                              // 기준일 (안 넣으면 오늘)
  as select from ZV_FI_OPEN_AGING( p_keydt : $parameters.p_keydt )
{
  key dtype,                                         // AP / AR
  key bucket,                                        // 만기 구간
  key waers,
      @Semantics.amount.currencyCode: 'waers'
      sum( openbal ) as openbal,                     // 구간 잔액 합계
      count( * )     as doccnt                       // 건수
}
group by dtype, bucket, waers
