@EndUserText.label: 'AI 추천 결과'
define abstract entity ZA_EXC_AI_RESULT
{
  success : abap.char(1);
  acttp   : abap.char(4);
  actnm   : abap.char(60);
  reason  : abap.char(255);
  cnt     : abap.int4;
  message : abap.char(255);
}
