@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CM03 조치유형 Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_EXC_ACTION_VH
  as select from ztcma00080
{
      @ObjectModel.text.element: [ 'ActionName' ]
      @EndUserText.label: '조치유형'
  key cdval as ActionType,

      @Semantics.text: true
      @EndUserText.label: '조치명'
      cdnam as ActionName,

      @EndUserText.label: '대상 발생출처'
      cddsc as AllowedSrtyp
}
where cdgrp = 'ACTTP'
