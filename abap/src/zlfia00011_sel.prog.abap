*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  SELECT-OPTIONS: s_lifnr FOR ztfia00050-lifnr,   " 공급업체
                  s_paynr FOR ztfia00050-paynr,   " 지급번호
                  s_paydt FOR ztfia00050-paydt.   " 지급일
  PARAMETERS:     p_payac TYPE ztfia00050-payac.  " 출금계좌 (F4)

SELECTION-SCREEN FUNCTION KEY 1.

SELECTION-SCREEN END OF BLOCK b1.
