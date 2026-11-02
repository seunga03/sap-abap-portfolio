@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '납기 리스크 최근 스냅샷'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_EXC_RISK_LATEST as select from ztexa00040
{
  key ebeln,
  key ebelp,
      max( crdat ) as crdat
}
group by ebeln, ebelp
