*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.

SELECT-OPTIONS: s_lifnr FOR ztcma00110-lifnr,     " 공급업체
                s_duedt FOR ztcma00110-duedt.     " 지급기한
SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(10) TEXT-c00.          " 지급상태
  SELECTION-SCREEN POSITION 12.

  PARAMETERS: p_open AS CHECKBOX DEFAULT 'X'.       " 미결
  SELECTION-SCREEN COMMENT 13(8) TEXT-c01 FOR FIELD p_open.

  PARAMETERS: p_part AS CHECKBOX DEFAULT 'X'.       " 부분반제
  SELECTION-SCREEN COMMENT 25(10) TEXT-c02 FOR FIELD p_part.

  PARAMETERS: p_done AS CHECKBOX.                   " 완결
  SELECTION-SCREEN COMMENT 55(10) TEXT-c03 FOR FIELD p_done.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(9) TEXT-c04.          " 지급상태
  SELECTION-SCREEN POSITION 12.

  PARAMETERS: p_hold AS CHECKBOX DEFAULT 'X'.       " 홀드건 제외
  SELECTION-SCREEN COMMENT 13(8) TEXT-c05 FOR FIELD p_hold.
SELECTION-SCREEN END OF LINE.

PARAMETERS: p_payac TYPE ztfia00050-payac,              " 출금계좌
            p_paydt TYPE ztfia00050-paydt DEFAULT sy-datum OBLIGATORY. " 지급일

SELECTION-SCREEN FUNCTION KEY 1.
SELECTION-SCREEN END OF BLOCK b1.
