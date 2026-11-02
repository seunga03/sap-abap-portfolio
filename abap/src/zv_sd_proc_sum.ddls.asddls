@EndUserText.label: '판매오더별 조달 요약'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZV_SD_PROC_SUM
  as select from ZV_SD_PROC_ROW
{
  key SoNumber,
      sum( IsShort )   as ShortItems,
      max( ShortLead ) as LeadDays
}
group by SoNumber
