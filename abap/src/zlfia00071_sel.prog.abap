*&---------------------------------------------------------------------*
*& Include          ZLFIA00070_SEL
*&---------------------------------------------------------------------*
SELECT-OPTIONS: s_ivnum FOR ztfia00010-ivnum,     " 송장번호
                s_xblnr FOR ztfia00010-xblnr,     " 거래처송장번호
                s_lifnr FOR ztfia00010-lifnr,     " 공급업체
                s_ebeln FOR ztfia00010-ebeln,     " PO번호
                s_bldat FOR ztfia00010-bldat,     " 인보이스일자
                s_budat FOR ztfia00010-budat.     " 등록일

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(10) TEXT-c00.          " 대사상태

  SELECTION-SCREEN POSITION 33.
  PARAMETERS: p_ok   AS CHECKBOX DEFAULT 'X'.       " 통과 (PASS)
  SELECTION-SCREEN COMMENT 35(8) TEXT-c01 FOR FIELD p_ok.

  SELECTION-SCREEN POSITION 45.
  PARAMETERS: p_hold AS CHECKBOX DEFAULT 'X'.       " 보류 (HOLD)
  SELECTION-SCREEN COMMENT 47(8) TEXT-c02 FOR FIELD p_hold.

  SELECTION-SCREEN POSITION 57.
  PARAMETERS: p_rej  AS CHECKBOX DEFAULT 'X'.       " 반려 (QREJ)
  SELECTION-SCREEN COMMENT 59(8) TEXT-c03 FOR FIELD p_rej.

  SELECTION-SCREEN POSITION 69.
  PARAMETERS: p_canc AS CHECKBOX.                   " 취소 (CANC) - 기본 해제
  SELECTION-SCREEN COMMENT 71(8) TEXT-c04 FOR FIELD p_canc.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.
