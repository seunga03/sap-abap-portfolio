@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception 처리이력 - 화면용'
@UI.presentationVariant: [ { sortOrder: [ { by: 'prtms', direction: #DESC } ],
                             visualizations: [ { type: #AS_LINEITEM } ] } ]
define view entity ZC_EXCEPTION_HIST
  as projection on ZI_EXCEPTION_HIST
{
      @UI.hidden: true
  key logno,

      @UI.hidden: true
      exnum,

      @UI.lineItem: [ { position: 10, label: '처리일시' } ]
      prtms,

      @UI.lineItem: [ { position: 20, label: '처리결과' } ]
      @ObjectModel.text.element: [ 'prres_text' ]
      @UI.textArrangement: #TEXT_ONLY
      prres,

      @UI.hidden: true
      prres_text,

      @UI.lineItem: [ { position: 30, label: '처리자' } ]
      uname,

      @UI.lineItem: [ { position: 40, label: '사유·메모' } ]
      prtxt,

      _Exception : redirected to parent ZC_EXCEPTION
}
