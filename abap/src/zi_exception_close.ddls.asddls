@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception - 종료/반려 시점'
define view entity ZI_EXCEPTION_CLOSE
  as select from ztexa00020
{
  key exnum,
      max( prtms ) as clts,
      max( erdat ) as cldat      // 종료·반려일 (DATS) — 평균 처리일 계산용
}
where prres = 'CLSD'
   or prres = 'RJCT'
group by
  exnum
