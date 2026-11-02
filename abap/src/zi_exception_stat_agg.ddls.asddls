@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception 통계 - 집계'
define view entity ZI_EXCEPTION_STAT_AGG
  as select from ZI_EXCEPTION_MONTH
{
  key crmon,
  key owgrp,
  key extyp,
  key srtyp,
      count( * )                                        as TotalCnt,
      sum( case prsta when 'OPEN' then 1 else 0 end )   as OpenCnt,
      sum( case prsta when 'PROG' then 1 else 0 end )   as ProgCnt,
      sum( case prsta when 'ACTN' then 1 else 0 end )   as ActnCnt,
      sum( case prsta when 'CLSD' then 1 else 0 end )   as ClosedCnt,
      sum( case prsta when 'RJCT' then 1 else 0 end )   as RjctCnt,
      sum( DoneFlag )                                   as DoneCnt,
      sum( DoneDays )                                   as DoneDays
}
group by
  crmon,
  owgrp,
  extyp,
  srtyp
