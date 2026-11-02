@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CM03 발생출처 Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_EXC_SRTYP_VH
  as select distinct from ztexa00010
{
      @ObjectModel.text.element: [ 'Name' ]
      @EndUserText.label: '발생출처'
  key srtyp as Srtyp,

      @Semantics.text: true
      @EndUserText.label: '발생출처명'
      cast( case srtyp
              when 'RISK' then '납기 리스크'
              when 'SUBC' then '외주 정합성'
              when 'QM'   then '품질 검사'
              when 'INVC' then '송장 정산'
              else srtyp
            end as abap.char(12) ) as Name
}
