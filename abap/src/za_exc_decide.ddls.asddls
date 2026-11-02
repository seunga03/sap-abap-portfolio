@EndUserText.label: 'Exception 조치 결정 입력'
define abstract entity ZA_EXC_DECIDE
{
  @EndUserText.label: '조치유형'
  @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_EXC_ACTION_VH', element: 'ActionType' } } ]
  acttp : abap.char(4);
  
  @UI.hidden: true
  ai_acttp : abap.char(4);

  @EndUserText.label: '조치 메모'
  memo  : abap.char(200);
}
