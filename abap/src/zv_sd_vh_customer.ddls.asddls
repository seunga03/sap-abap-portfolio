@EndUserText.label: '고객 값 목록'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZV_SD_VH_CUSTOMER
  as select from ztsda00010
{
      @EndUserText.label: '고객'
  key kunnr as Customer
}
group by
  kunnr
