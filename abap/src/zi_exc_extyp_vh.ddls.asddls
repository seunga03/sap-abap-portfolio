@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CM03 예외유형 Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_EXC_EXTYP_VH
  as select distinct from ztexa00010
{
      @ObjectModel.text.element: [ 'Name' ]
      @EndUserText.label: '예외유형'
  key extyp as Extyp,

      @Semantics.text: true
      @EndUserText.label: '예외유형명'
      cast( case extyp
              when 'PROC' then '조달'
              when 'QUAL' then '품질'
              when 'SETL' then '정산'
              else extyp
            end as abap.char(8) ) as Name
}
