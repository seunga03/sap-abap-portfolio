@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception 후속 요청'
@UI.presentationVariant: [ { sortOrder: [ { by: 'rqnum', direction: #DESC } ],
                             visualizations: [ { type: #AS_LINEITEM } ] } ]
define view entity ZI_EXCEPTION_REQ
  as select from ztexa00060
  association [0..1] to ZI_EXC_ACTION_VH as _Action
    on $projection.acttp = _Action.ActionType  
{
      @UI.lineItem: [ { position: 10, label: '요청번호' } ]
  key rqnum,

      @UI.hidden: true
      exnum,

      @UI.lineItem: [ { position: 20, label: '조치' } ]
      @ObjectModel.text.element: [ 'acttp_text' ]
      @UI.textArrangement: #TEXT_ONLY
      acttp,

      @UI.hidden: true
      _Action.ActionName as acttp_text,

      @UI.lineItem: [ { position: 30, label: '처리 프로그램' } ]
      tgpgm,

      @UI.lineItem: [ { position: 40, label: '상태' } ]
      @ObjectModel.text.element: [ 'rqsta_text' ]
      @UI.textArrangement: #TEXT_ONLY
      rqsta,

      @UI.hidden: true
      cast( case rqsta
              when 'WAIT' then '대기'
              when 'DONE' then '완료'
              when 'CNCL' then '취소'
              else rqsta
            end as abap.char(8) )                        as rqsta_text,

      @UI.lineItem: [ { position: 50, label: '요청 메모' } ]
      rqtxt,

      @UI.lineItem: [ { position: 60, label: '처리 메모' } ]
      rstxt,

      @UI.lineItem: [ { position: 70, label: '요청자' } ]
      ernam,

      @UI.lineItem: [ { position: 80, label: '요청일' } ]
      erdat,

      @UI.hidden: true
      erzet,

      @UI.lineItem: [ { position: 90, label: '완료일' } ]
      cmdat,

      @UI.lineItem: [ { position: 100, label: '완료자' } ]
      cmusr
}
