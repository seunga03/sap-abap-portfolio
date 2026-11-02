@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '채권채무 만기 현황(건별)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_FI_OPEN_ITEM
  with parameters
    @Environment.systemField: #SYSTEM_DATE
    p_keydt : abap.dats                              // 기준일 (안 넣으면 오늘)

  // ---------- AP : 줄 돈 ----------
  as select from    ztcma00110 as ap
    left outer join ztcma00010 as lf on lf.lifnr = ap.lifnr
{
  key 'AP'                                           as dtype,    // 구분
  key ap.apnum                                       as docno,    // 채무번호
      ap.ivnum                                       as refno,    // 송장번호
      ap.lifnr                                       as partner,  // 공급업체
      lf.name1                                       as name1,
      ap.bldat,
      ap.duedt,
      ap.clsta,
      ap.waers,
      @Semantics.amount.currencyCode: 'waers'
      ap.dmbtr,                                                   // 금액
      @Semantics.amount.currencyCode: 'waers'
      ap.paybt                                       as clrbt,    // 반제누계(지급)
      @Semantics.amount.currencyCode: 'waers'
      ap.adjbt,                                                   // 조정누계
      @Semantics.amount.currencyCode: 'waers'
      ap.dmbtr - ap.paybt - ap.adjbt                 as openbal,  // 잔액
      dats_days_between( ap.duedt, $parameters.p_keydt ) as ovdays // +연체일수 / -남은일수
}

union all

  // ---------- AR : 받을 돈 ----------
  select from       ztcma00100      as ar
    left outer join ZV_SD_CUST_NAME as cu on cu.Customer = ar.kunnr   // 현민 고객명 CDS 재사용
{
  key 'AR'                                           as dtype,
  key ar.arnum                                       as docno,    // 채권번호
      ar.bilno                                       as refno,    // 청구번호
      ar.kunnr                                       as partner,  // 고객
      cu.CustomerName                                as name1,
      ar.bldat,
      ar.duedt,
      ar.clsta,
      ar.waers,
      ar.dmbtr,
      ar.rcpbt                                       as clrbt,    // 반제누계(수금)
      ar.adjbt,
      ar.dmbtr - ar.rcpbt - ar.adjbt                 as openbal,
      dats_days_between( ar.duedt, $parameters.p_keydt ) as ovdays
}
