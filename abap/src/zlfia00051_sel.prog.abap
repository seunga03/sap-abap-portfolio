*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.

SELECT-OPTIONS: s_kunnr FOR ztcma00100-kunnr,     " 고객
                s_duedt FOR ztcma00100-duedt.     " 회수기한
SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(10) TEXT-c00.          " 회수상태
  SELECTION-SCREEN POSITION 12.

  PARAMETERS: p_open AS CHECKBOX DEFAULT 'X'.       " 미결
  SELECTION-SCREEN COMMENT 13(8) TEXT-c01 FOR FIELD p_open.

  PARAMETERS: p_part AS CHECKBOX DEFAULT 'X'.       " 부분수금
  SELECTION-SCREEN COMMENT 25(10) TEXT-c02 FOR FIELD p_part.

  PARAMETERS: p_done AS CHECKBOX.                   " 완결
  SELECTION-SCREEN COMMENT 55(10) TEXT-c03 FOR FIELD p_done.
SELECTION-SCREEN END OF LINE.

PARAMETERS: p_rcpac TYPE ztfia00060-rcpac,              " 입금계좌
            p_rcpdt TYPE ztfia00060-rcpdt DEFAULT sy-datum OBLIGATORY. " 수금일

SELECTION-SCREEN FUNCTION KEY 1.

SELECTION-SCREEN END OF BLOCK b1.
