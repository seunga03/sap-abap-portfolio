@EndUserText.label: 'SD 프로세스 대시보드 분석'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@UI.headerInfo: {
  typeName: '판매오더',
  typeNamePlural: '판매현황 분석'
}

@UI.chart: [
  { title: '일자별 진행 단계 현황',
    chartType: #COLUMN_STACKED,
    dimensions: [ 'OrderDate', 'SoStatus' ],
    measures: [ 'OrderCount' ],
    dimensionAttributes: [ { dimension: 'OrderDate', role: #CATEGORY },
                           { dimension: 'SoStatus',   role: #SERIES } ],
    measureAttributes: [ { measure: 'OrderCount', role: #AXIS_1 } ] },
  { qualifier: 'FilterStatus',
    title: '진행 단계별 건수',
    chartType: #BAR,
    dimensions: [ 'SoStatus' ],
    measures: [ 'OrderCount' ],
    dimensionAttributes: [ { dimension: 'SoStatus', role: #CATEGORY } ],
    measureAttributes: [ { measure: 'OrderCount', role: #AXIS_1 } ] },
  { qualifier: 'FilterDue',
    title: '납기상태별 건수',
    chartType: #DONUT,
    dimensions: [ 'DueStatus' ],
    measures: [ 'OrderCount' ],
    dimensionAttributes: [ { dimension: 'DueStatus', role: #CATEGORY } ],
    measureAttributes: [ { measure: 'OrderCount', role: #AXIS_1 } ] },
  { qualifier: 'FilterCustomer',
    title: '고객별 주문금액',
    chartType: #BAR,
    dimensions: [ 'Customer' ],
    measures: [ 'TotalAmount' ],
    dimensionAttributes: [ { dimension: 'Customer', role: #CATEGORY } ],
    measureAttributes: [ { measure: 'TotalAmount', role: #AXIS_1 } ] }
]

@UI.presentationVariant: [
  { sortOrder: [{ by: 'OrderDate', direction: #ASC }],
    visualizations: [ { type: #AS_CHART }, { type: #AS_LINEITEM } ] },
  { qualifier: 'FilterStatus',
    visualizations: [ { type: #AS_CHART, qualifier: 'FilterStatus' } ] },
  { qualifier: 'FilterDue',
    visualizations: [ { type: #AS_CHART, qualifier: 'FilterDue' } ] },
  { qualifier: 'FilterCustomer',
    sortOrder: [{ by: 'TotalAmount', direction: #DESC }],
    visualizations: [ { type: #AS_CHART, qualifier: 'FilterCustomer' } ] }
]

define view entity ZV_SD_DASH_ANA
  as select from ZV_SD_DASHBOARD as d
    left outer join ZV_SD_PROC_SUM as p on p.SoNumber = d.SoNumber
{
      @UI.lineItem: [{ position: 30, label: '판매문서' }]
      @UI.selectionField: [{ position: 20 }]
      @EndUserText.label: '판매문서'
  key d.SoNumber as SoNumber,

      @UI.lineItem: [{ position: 40, label: '주문일' }]
      @UI.selectionField: [{ position: 10 }]
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      @EndUserText.label: '주문일'
      d.OrderDate as OrderDate,

      @EndUserText.label: '주문월'
      cast( substring( d.OrderDate, 1, 6 ) as abap.char(6) ) as OrderMonth,

      @UI.selectionField: [{ position: 30 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZV_SD_DASH_ANA', element: 'Customer' },
                                           presentationVariantQualifier: 'FilterCustomer' }]
      @ObjectModel.text.element: [ 'CustomerName' ]
      @EndUserText.label: '고객'
      d.Customer as Customer,

      @UI.lineItem: [{ position: 50, label: '고객명' }]
      @Semantics.text: true
      @EndUserText.label: '고객명'
      d.CustomerName as CustomerName,

      @UI.lineItem: [{ position: 10, label: 'SO상태', criticality: 'Criticality' }]
      @UI.selectionField: [{ position: 40 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZV_SD_DASH_ANA', element: 'SoStatus' },
                                           presentationVariantQualifier: 'FilterStatus' }]
      @ObjectModel.text.element: [ 'StatusText' ]
      @UI.textArrangement: #TEXT_LAST
      @EndUserText.label: 'SO상태'
      d.SoStatus as SoStatus,

      @Semantics.text: true
      @EndUserText.label: '상태명'
      d.StatusText as StatusText,

      d.Criticality as Criticality,

      @UI.lineItem: [{ position: 20, label: '납기상태', criticality: 'DueCrit' }]
      @UI.selectionField: [{ position: 50 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZV_SD_DASH_ANA', element: 'DueStatus' },
                                           presentationVariantQualifier: 'FilterDue' }]
      @EndUserText.label: '납기상태'
      d.DueStatus as DueStatus,

      d.DueCrit as DueCrit,

      @UI.lineItem: [{ position: 60, label: '합계금액' }]
      @Aggregation.default: #SUM
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: '합계금액'
      d.TotalAmount as TotalAmount,

      @EndUserText.label: '통화'
      d.Currency as Currency,

      @UI.lineItem: [{ position: 70, label: '출고일' }]
      @EndUserText.label: '출고일'
      d.ActualGI as ActualGI,

      @UI.lineItem: [{ position: 80, label: '청구일' }]
      @EndUserText.label: '청구일'
      d.BillDate as BillDate,

      @EndUserText.label: '요청납기일'
      cast( d.ReqDate as abap.char(8) ) as ReqDate,      -- 문자로 보냄 (잘못된 날짜 값이 있어도 500 안 나게)

      @EndUserText.label: '납기까지(일)'
      d.DaysLeft as DaysLeft,

      @EndUserText.label: '출고문서'
      d.DoNumber as DoNumber,

      @EndUserText.label: '출하예정일'
      cast( d.PlannedGI as abap.char(8) ) as PlannedGI,

      @EndUserText.label: '청구문서'
      d.BillNo as BillNo,

      @EndUserText.label: '조달중 품목수'
      cast( coalesce( p.ShortItems, 0 ) as abap.int4 ) as ShortItems,

      @EndUserText.label: '조달 Lead Time(일)'
      cast( coalesce( p.LeadDays, 0 ) as abap.int4 ) as LeadDays,

      @Aggregation.default: #SUM
      @EndUserText.label: '건수'
      cast( 1 as abap.int4 ) as OrderCount
}
