@EndUserText.label: '담당자 재배정 파라미터'
define abstract entity ZA_EXC_ASSIGN
{
  @EndUserText.label: '담당자'
  uname : abap.char(12);
  @EndUserText.label: '사유'
  memo : abap.char(200);
}
