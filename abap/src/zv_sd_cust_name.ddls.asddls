@EndUserText.label: '고객명'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define view entity ZV_SD_CUST_NAME
  as select from ztcma00050
{
  key kunnr        as Customer,
      max( name1 ) as CustomerName
}
group by
  kunnr
