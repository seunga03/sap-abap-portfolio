*&---------------------------------------------------------------------*
*& Include          ZLFIA00090_SEL
*&---------------------------------------------------------------------*
SELECT-OPTIONS: s_ivnum FOR ztfia00010-ivnum,     " 송장번호
                s_lifnr FOR ztfia00010-lifnr,     " 공급업체
                s_ebeln FOR ztfia00010-ebeln,     " PO번호
                s_budat FOR ztfia00010-budat.     " 등록일

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(10) TEXT-c00.          " 대상
  SELECTION-SCREEN POSITION 35.
  PARAMETERS: p_hold AS CHECKBOX DEFAULT 'X'.       " 보류 (HOLD)
  SELECTION-SCREEN COMMENT 40(5) TEXT-c01 FOR FIELD p_hold.
  SELECTION-SCREEN POSITION 50.
  PARAMETERS: p_rej  AS CHECKBOX DEFAULT 'X'.       " 반려 (QREJ)
  SELECTION-SCREEN COMMENT 55(5) TEXT-c02 FOR FIELD p_rej.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN FUNCTION KEY 2.
