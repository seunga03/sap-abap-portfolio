@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 창고'
define view entity ZI_MM_DASH_STORAGE
  as select from ztcma00150
{
      @EndUserText.label: '플랜트'
  key werks,

      @EndUserText.label: '창고'
  key lgort,

      @EndUserText.label: '창고명'
      lgobe,

      @EndUserText.label: '출하·입고 지점'
      vstel,

      @EndUserText.label: '국가'
      land1,

      @EndUserText.label: '활성여부'
      actyn
}
