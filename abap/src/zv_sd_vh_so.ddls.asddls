@EndUserText.label: '판매문서 값 목록'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZV_SD_VH_SO
  as select from ZV_SD_DASHBOARD
{
      @EndUserText.label: '판매문서'
  key SoNumber,

      @EndUserText.label: '고객'
      Customer
}
