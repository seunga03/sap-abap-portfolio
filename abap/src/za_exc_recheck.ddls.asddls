@EndUserText.label: 'Exception 재검증 입력'
define abstract entity ZA_EXC_RECHECK
{
  @EndUserText.label: '재검증 통과'
  passed : abap_boolean;

  @EndUserText.label: '재검증 메모'
  memo   : abap.char(200);
}
