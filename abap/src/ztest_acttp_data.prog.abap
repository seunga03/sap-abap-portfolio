*&---------------------------------------------------------------------*
*& Report ztest_acttp_data
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_acttp_data.
" CM03 조치유형 임시 코드 (CDGRP=ACTTP) — 팀이 ZCM_ACTION_RULE/공통코드 확정 시 교체
DATA lt_code TYPE STANDARD TABLE OF ztcma00080.

lt_code = VALUE #( cdgrp = 'ACTTP' actyn = 'Y' valfr = '20260101' valto = '99991231'
                   ernam = sy-uname erdat = sy-datum erzet = sy-uzeit
  ( cdval = 'REMD' cdnam = '재촉'                     cddsc = 'RISK' )
  ( cdval = 'URGP' cdnam = '긴급구매전환'             cddsc = 'RISK' )
  ( cdval = 'MONI' cdnam = '모니터링유지'             cddsc = 'RISK' )
  ( cdval = 'RCHK' cdnam = '재검증요청'               cddsc = 'SUBC' )
  ( cdval = 'STLR' cdnam = '차이정산요청'             cddsc = 'SUBC' )
  ( cdval = 'LOSS' cdnam = '손실확정'                 cddsc = 'SUBC' )
  ( cdval = 'RTRN' cdnam = '반품'                     cddsc = 'QM'   )
  ( cdval = 'RWRK' cdnam = '재작업'                   cddsc = 'QM'   )
  ( cdval = 'SCRP' cdnam = '폐기'                     cddsc = 'QM'   )
  ( cdval = 'APRC' cdnam = 'AP 금액 재산정'           cddsc = 'INVC' )
  ( cdval = 'POFX' cdnam = 'PO 단가 정정'             cddsc = 'INVC' )
  ( cdval = 'REIS' cdnam = 'Invoice 재발행 요청'      cddsc = 'INVC' )
  ( cdval = 'GRFX' cdnam = 'GR 수량 수정'             cddsc = 'INVC' ) ).

MODIFY ztcma00080 FROM TABLE @lt_code.
COMMIT WORK.
WRITE: / |조치유형 { lines( lt_code ) }건 적재 완료 (CDGRP=ACTTP)|.
