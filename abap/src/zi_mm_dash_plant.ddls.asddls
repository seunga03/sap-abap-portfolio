@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 플랜트'
define view entity ZI_MM_DASH_PLANT
  as select from ztcma00140
{
      @EndUserText.label: '플랜트'
  key werks,

      @EndUserText.label: '플랜트명'
      name1,

      @EndUserText.label: '주소번호'
      adrnr,

      @EndUserText.label: '지역'
      regio,

      @EndUserText.label: '회사코드'
      bukrs,

      @EndUserText.label: '활성여부'
      actyn
}
