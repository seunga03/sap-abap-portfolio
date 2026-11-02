@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception 통계'
@UI: {
  headerInfo: { typeName: '예외 통계',
                typeNamePlural: 'CM05 예외 운영 성과 · 월별 처리 현황' },
  presentationVariant: [ { sortOrder: [ { by: 'crmon', direction: #DESC },
                                        { by: 'OpenCnt', direction: #DESC } ],
                           visualizations: [ { type: #AS_LINEITEM } ] } ]
}
define view entity ZC_EXCEPTION_STAT
  as select from ZI_EXCEPTION_STAT_AGG
{
      @UI: { lineItem: [ { position: 5 } ], selectionField: [ { position: 5 } ] }
      @EndUserText.label: '발생월'
  key crmon,

      @UI: { lineItem: [ { position: 10 } ], selectionField: [ { position: 10 } ] }
      @EndUserText.label: '담당그룹'
      @ObjectModel.text.element: [ 'OwgrpText' ]
      @UI.textArrangement: #TEXT_ONLY
  key owgrp,

      @UI: { lineItem: [ { position: 20 } ], selectionField: [ { position: 20 } ] }
      @EndUserText.label: '예외유형'
      @ObjectModel.text.element: [ 'ExtypText' ]
      @UI.textArrangement: #TEXT_ONLY
  key extyp,

      @UI: { lineItem: [ { position: 30 } ], selectionField: [ { position: 30 } ] }
      @EndUserText.label: '발생출처'
      @ObjectModel.text.element: [ 'SrtypText' ]
      @UI.textArrangement: #TEXT_ONLY
  key srtyp,

      @UI.lineItem: [ { position: 40 } ]
      @EndUserText.label: '전체'
      TotalCnt,
      
      
      @UI.lineItem: [ { position: 50, criticality: 'OpenCrit' } ]
      @EndUserText.label: '접수대기'
      OpenCnt,

      @UI.lineItem: [ { position: 60 } ]
      @EndUserText.label: '처리중'
      ProgCnt,

      @UI.lineItem: [ { position: 65 } ]
      @EndUserText.label: '조치실행중'
      ActnCnt,

      @UI.lineItem: [ { position: 70 } ]
      @EndUserText.label: '종료'
      ClosedCnt,

      @UI.lineItem: [ { position: 75 } ]
      @EndUserText.label: '반려'
      RjctCnt,

      // 처리율(%) = (종료 + 반려) / 전체
      @UI.dataPoint: { title: '처리율', targetValue: 100, visualization: #PROGRESS }
      @UI.lineItem: [ { position: 80, type: #AS_DATAPOINT } ]
      @EndUserText.label: '처리율(%)'
      division( ( ClosedCnt + RjctCnt ) * 100, TotalCnt, 1 )  as CloseRate,

      @UI.lineItem: [ { position: 90 } ]
      @EndUserText.label: '평균 처리일'
      division( DoneDays,
                case when DoneCnt = 0 then 1 else DoneCnt end,
                1 )                                  as AvgDays,      
      @UI.hidden: true
      DoneCnt,
      @UI.hidden: true
      DoneDays,          

      @UI.hidden: true
      case when OpenCnt > 0 then 1 else 3 end                  as OpenCrit,
            @UI.hidden: true
      cast( case owgrp
              when 'MM'   then '자재(MM)'
              when 'FI'   then '재무(FI)'
              when 'BOTH' then '공동(MM+FI)'
              when 'QM'   then 'QM'
              else owgrp end as abap.char(20) )    as OwgrpText,

      @UI.hidden: true
      cast( case extyp
              when 'PROC' then '조달'
              when 'QUAL' then '품질'
              when 'SETL' then '정산'
              else extyp end as abap.char(20) )    as ExtypText,

      @UI.hidden: true
      cast( case srtyp
              when 'PO'   then 'PO'
              when 'SUBC' then '외주 정합성'
              when 'QM'   then '품질 검사'
              when 'RISK' then '납기 리스크'
              when 'INVC' then '송장 정산'
              else srtyp end as abap.char(20) )    as SrtypText

}
