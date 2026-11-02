@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '채권채무 만기 구간(건별)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_FI_OPEN_AGING
  with parameters
    @Environment.systemField: #SYSTEM_DATE
    p_keydt : abap.dats                              // 기준일 (안 넣으면 오늘)
  as select from ZV_FI_OPEN_ITEM( p_keydt : $parameters.p_keydt )
{
  key dtype,                                         // AP / AR
  key docno,                                         // 채무·채권번호
      refno,
      partner,
      name1,
      duedt,
      waers,
      @Semantics.amount.currencyCode: 'waers'
      dmbtr,
      @Semantics.amount.currencyCode: 'waers'
      clrbt,
      @Semantics.amount.currencyCode: 'waers'
      adjbt,
      @Semantics.amount.currencyCode: 'waers'
      openbal,
      ovdays,
      case
        when openbal <= 0   then '0'                 // 완결
        when ovdays  >  0   then '1'                 // 기한 지남(연체)
        when ovdays  >= -7  then '2'                 // 7일 이내
        when ovdays  >= -30 then '3'                 // 30일 이내
        else                     '4'                 // 30일 초과
      end as bucket                                  // 만기 구간
}
