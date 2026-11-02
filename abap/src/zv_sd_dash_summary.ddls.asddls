@EndUserText.label: 'SO상태별 건수'
@AccessControl.authorizationCheck: #NOT_REQUIRED

@UI.headerInfo: {
  typeName: 'SO상태',
  typeNamePlural: '상태별 건수'
}

define view entity ZV_SD_DASH_SUMMARY
  as select from ZV_SD_DASHBOARD
{
      @UI.lineItem: [{ position: 10, label: 'SO상태', criticality: 'Criticality' }]
      @EndUserText.label: 'SO상태'
  key SoStatus,

      @UI.lineItem: [{ position: 20, label: '건수' }]
      @EndUserText.label: '건수'
      count(*) as OrderCount,

      max(Criticality) as Criticality
}
group by SoStatus
