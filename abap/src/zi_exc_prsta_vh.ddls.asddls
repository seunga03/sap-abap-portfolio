@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CM03 처리상태 Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_EXC_PRSTA_VH
  as select distinct from ztexa00010
{
      @ObjectModel.text.element: [ 'Name' ]
      @EndUserText.label: '처리상태'
  key prsta as Prsta,

      @Semantics.text: true
      @EndUserText.label: '처리상태명'
      cast( case prsta
              when 'OPEN' then '접수대기'
              when 'PROG' then '처리중'
              when 'ACTN' then '조치실행중'
              when 'CLSD' then '종료'
              when 'RJCT' then '반려'
              else prsta
            end as abap.char(12) ) as Name
}
