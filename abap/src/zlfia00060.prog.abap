*&---------------------------------------------------------------------*
*& Report ZLFIA00060
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZLFIA00060.

TABLES sscrfields.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.

SELECTION-SCREEN SKIP.

  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN PUSHBUTTON 10(20) TEXT-r01 USER-COMMAND reg.   " 수금등록

    SELECTION-SCREEN PUSHBUTTON 45(20) TEXT-r02 USER-COMMAND inq.   " 조회

  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b1.

AT SELECTION-SCREEN OUTPUT.
  DATA lt_excl TYPE TABLE OF sy-ucomm.

  CLEAR lt_excl.
  APPEND 'ONLI' TO lt_excl.   " 실행 (F8)
  APPEND 'PRIN' TO lt_excl.   " 실행 후 인쇄
  APPEND 'SJOB' TO lt_excl.   " 백그라운드 실행

  CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
    EXPORTING
      p_status  = '%_00'
      p_program = 'RSSYSTDB'
    TABLES
      p_exclude = lt_excl.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'REG'.
      SUBMIT zlfia00050 VIA SELECTION-SCREEN AND RETURN.
    WHEN 'INQ'.
      SUBMIT zlfia00040 VIA SELECTION-SCREEN AND RETURN.
  ENDCASE.
