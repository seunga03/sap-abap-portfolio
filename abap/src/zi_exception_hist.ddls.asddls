@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception 처리이력'
define view entity ZI_EXCEPTION_HIST
  as select from ztexa00020
  association to parent ZI_EXCEPTION as _Exception          // ★ 부모 연결
    on $projection.exnum = _Exception.exnum
{
  key logno,
      exnum,
      prtms,
      prres,
      cast( case prres
              when 'ASGN' then '담당자 배정'
              when 'REAS' then '담당자 재배정'
              when 'PROG' then '처리중 전환'
              when 'ACTN' then '조치 결정'
              when 'CLSD' then '종료'
              when 'RJCT' then '반려'
              when 'AIRC' then 'AI 추천'
              when 'HRLS' then 'Hold 해제'
              when 'RQDN' then '요청 완료'
              when 'RCFL' then '재검증 실패'
              else prres
            end as abap.char(14) )                       as prres_text,
      uname,
      prtxt,
      _Exception                                             // ★
}
