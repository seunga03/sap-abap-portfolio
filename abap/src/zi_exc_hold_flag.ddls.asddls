@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception Hold 집계'
define view entity ZI_EXC_HOLD_FLAG
  as select from ztexa00030
{
  key exnum,
      count(*) as hold_cnt,
      sum( case when hdsta = 'ACTV' then 1 else 0 end ) as act_cnt
}
group by exnum
