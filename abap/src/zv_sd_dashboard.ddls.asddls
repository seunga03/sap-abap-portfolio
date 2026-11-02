@EndUserText.label: 'SD 프로세스 단계 대시보드'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@UI.headerInfo: {
  typeName: '판매오더',
  typeNamePlural: '판매현황',
  title: { type: #STANDARD, value: 'SoNumber' },
  description: { type: #STANDARD, value: 'CustomerName' }
}

define view entity ZV_SD_DASHBOARD as
  select from ztsda00010 as h
    left outer join ZV_SD_ITEM_SUM  as i on i.vbeln    = h.vbeln
    left outer join ZV_SD_CUST_NAME as c on c.Customer = h.kunnr
    left outer join ZV_SD_DELIV_SUM as d on d.SoNumber = h.vbeln
    left outer join ZV_SD_BILL_SUM  as b on b.SoNumber = h.vbeln
{
      @UI.facet: [
        { id: 'HProg', type: #DATAPOINT_REFERENCE, purpose: #HEADER, targetQualifier: 'ProgressDP', position: 10 },
        { id: 'HAmt',  type: #DATAPOINT_REFERENCE, purpose: #HEADER, targetQualifier: 'AmountDP',   position: 20 },
        { id: 'HDue',  type: #DATAPOINT_REFERENCE, purpose: #HEADER, targetQualifier: 'DueDP',      position: 30 },
        { id: 'Flow',     type: #FIELDGROUP_REFERENCE, label: '진행 현황', targetQualifier: 'Flow', position: 10 },
        { id: 'General',  type: #IDENTIFICATION_REFERENCE, label: '주문 정보', position: 20 },
        { id: 'Delivery', type: #FIELDGROUP_REFERENCE, label: '수량 / 납기', targetQualifier: 'Delivery', position: 30 },
        { id: 'Amount',   type: #FIELDGROUP_REFERENCE, label: '금액 정보', targetQualifier: 'Amount',   position: 40 }
      ]
      @UI.lineItem: [{ position: 40, label: '판매문서', importance: #HIGH }]
      @UI.selectionField: [{ position: 20 }]
      @UI.identification: [{ position: 10, label: '판매문서' }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZV_SD_VH_SO', element: 'SoNumber' } }]
      @EndUserText.label: '판매문서'
  key h.vbeln as SoNumber,

      @UI.lineItem: [{ position: 50, label: '주문일', importance: #HIGH }]
      @UI.selectionField: [{ position: 10 }]
      @UI.identification: [{ position: 20, label: '주문일' }]
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      @EndUserText.label: '주문일'
      h.audat as OrderDate,

      @UI.selectionField: [{ position: 30 }]
      @UI.identification: [{ position: 30, label: '고객' }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZV_SD_VH_CUSTOMER', element: 'Customer' } }]
      @EndUserText.label: '고객'
      h.kunnr as Customer,

      @UI.lineItem: [{ position: 60, label: '고객명', importance: #HIGH }]
      @UI.identification: [{ position: 35, label: '고객명' }]
      @EndUserText.label: '고객명'
      c.CustomerName as CustomerName,

      @UI.lineItem: [{ position: 10, label: 'SO상태', criticality: 'Criticality', importance: #HIGH }]
      @UI.identification: [{ position: 40, label: 'SO상태', criticality: 'Criticality' }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZV_SD_VH_STATUS', element: 'SoStatus' } }]
      @ObjectModel.text.element: [ 'StatusText' ]
      @UI.textArrangement: #TEXT_LAST
      @EndUserText.label: 'SO상태'
      cast( case when h.sosta = '' then 'SO' else h.sosta end as abap.char(4) ) as SoStatus,

      @UI.lineItem: [{ position: 20, type: #AS_DATAPOINT, label: '진행단계', importance: #HIGH }]
      @UI.dataPoint: {
        title: '진행단계',
        visualization: #PROGRESS,
        targetValue: 4,
        criticality: 'Criticality'
      }
      @EndUserText.label: '진행단계'
      case h.sosta
        when 'BI' then 4
        when 'GI' then 3
        when 'DO' then 2
        else 1
      end as ProgressStep,

      @UI.fieldGroup: [{ qualifier: 'Amount', position: 10, label: '공급금액' }]
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: '공급금액'
      h.netam as NetAmount,

      @UI.fieldGroup: [{ qualifier: 'Amount', position: 20, label: '세액' }]
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: '세액'
      h.taxam as TaxAmount,

      @UI.lineItem: [{ position: 70, label: '합계금액', importance: #HIGH }]
      @UI.fieldGroup: [{ qualifier: 'Amount', position: 30, label: '총 주문금액' }]
      @UI.dataPoint: { qualifier: 'AmountDP', title: '총 주문금액' }
      @Semantics.amount.currencyCode: 'Currency'
      @EndUserText.label: '합계금액'
      h.totam as TotalAmount,

      @EndUserText.label: '통화'
      h.waers as Currency,

      @UI.fieldGroup: [{ qualifier: 'Delivery', position: 10, label: '주문수량' }]
      @EndUserText.label: '주문수량'
      i.TotalQty as TotalQty,

      @UI.fieldGroup: [{ qualifier: 'Delivery', position: 20, label: '품목 수' }]
      @EndUserText.label: '품목 수'
      i.ItemCount as ItemCount,

      @UI.lineItem: [{ position: 80, label: '요청납기일', importance: #MEDIUM }]
      @UI.fieldGroup: [{ qualifier: 'Delivery', position: 30, label: '요청납기일' }]
      @EndUserText.label: '요청납기일'
      i.ReqDate as ReqDate,

      @UI.fieldGroup: [{ qualifier: 'Delivery', position: 40, label: '납기까지(일)' }]
      @EndUserText.label: '납기까지(일)'
      case
        when h.sosta = 'BI' or h.sosta = 'GI'
          then cast( 0 as abap.int4 )
        when i.ReqDate is null or i.ReqDate = '00000000'
          then cast( 0 as abap.int4 )
        else dats_days_between( $session.system_date, i.ReqDate )
      end as DaysLeft,

      @UI.fieldGroup: [{ qualifier: 'Flow', position: 10, label: '진행 흐름', criticality: 'Criticality' }]
      @EndUserText.label: '진행 흐름'
      cast( case h.sosta
              when 'BI' then '● 수주 ─ ● 출고문서 ─ ● 출고처리 ─ ● 청구'
              when 'GI' then '● 수주 ─ ● 출고문서 ─ ● 출고처리 ─ ○ 청구'
              when 'DO' then '● 수주 ─ ● 출고문서 ─ ○ 출고처리 ─ ○ 청구'
              else           '● 수주 ─ ○ 출고문서 ─ ○ 출고처리 ─ ○ 청구'
            end as abap.char(40) ) as FlowText,

      @UI.lineItem: [{ position: 91, label: '출고문서', importance: #LOW }]
      @UI.fieldGroup: [{ qualifier: 'Flow', position: 20, label: '출고문서' }]
      @EndUserText.label: '출고문서'
      d.DoNumber as DoNumber,

      @UI.fieldGroup: [{ qualifier: 'Flow', position: 30, label: '출하예정일' }]
      @EndUserText.label: '출하예정일'
      d.PlannedGI as PlannedGI,

      @UI.lineItem: [{ position: 92, label: '출고일', importance: #LOW }]
      @UI.selectionField: [{ position: 40 }]
      @UI.fieldGroup: [{ qualifier: 'Flow', position: 40, label: '실제출고일' }]
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      @EndUserText.label: '출고일'
      d.ActualGI as ActualGI,

      @UI.lineItem: [{ position: 93, label: '청구문서', importance: #LOW }]
      @UI.fieldGroup: [{ qualifier: 'Flow', position: 50, label: '청구문서' }]
      @EndUserText.label: '청구문서'
      b.BillNo as BillNo,

      @UI.lineItem: [{ position: 94, label: '청구일', importance: #LOW }]
      @UI.selectionField: [{ position: 50 }]
      @UI.fieldGroup: [{ qualifier: 'Flow', position: 60, label: '청구일' }]
      @Consumption.filter: { selectionType: #INTERVAL, multipleSelections: false }
      @EndUserText.label: '청구일'
      b.BillDate as BillDate,

      case h.sosta
        when 'BI' then 3
        when 'GI' then 2
        when 'DO' then 2
        else 0
      end as Criticality,

      @UI.dataPoint: {
        qualifier: 'ProgressDP',
        title: '진행률(%)',
        visualization: #PROGRESS,
        targetValue: 100,
        criticality: 'Criticality'
      }
      @EndUserText.label: '진행률'
      case h.sosta
        when 'BI' then 100
        when 'GI' then 75
        when 'DO' then 50
        else 25
      end as ProgressPct,

      @UI.lineItem: [{ position: 30, label: '납기상태', criticality: 'DueCrit', importance: #HIGH }]
      @UI.fieldGroup: [{ qualifier: 'Delivery', position: 50, label: '납기상태', criticality: 'DueCrit' }]
      @UI.dataPoint: { qualifier: 'DueDP', title: '납기상태', criticality: 'DueCrit' }
      @EndUserText.label: '납기상태'
      cast( case
              when h.sosta = 'BI' or h.sosta = 'GI' then '완료'
              when i.ReqDate is null or i.ReqDate = '00000000' then '미정'
              when dats_days_between( $session.system_date, i.ReqDate ) < 0 then '지연'
              when dats_days_between( $session.system_date, i.ReqDate ) <= 3 then '임박'
              else '정상'
            end as abap.char(10) ) as DueStatus,

      case
        when h.sosta = 'BI' or h.sosta = 'GI' then 3
        when i.ReqDate is null or i.ReqDate = '00000000' then 0
        when dats_days_between( $session.system_date, i.ReqDate ) < 0 then 1
        when dats_days_between( $session.system_date, i.ReqDate ) <= 3 then 2
        else 3
      end as DueCrit,

      @Semantics.text: true
      @EndUserText.label: '설명'
      cast( case h.sosta
              when 'BI' then '청구'
              when 'GI' then '출고처리'
              when 'DO' then '출고문서'
              else '수주'
            end as abap.char(10) ) as StatusText
}
