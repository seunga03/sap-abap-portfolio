@EndUserText.label: '바코드 일괄 입고 요청'
define root abstract entity ZAE_MM_GR_REQUEST
{
  key RequestId : abap.char( 32 );
  
  _Item : composition [1..*] of ZAE_MM_GR_ITEM;
}
