*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_E01
*&---------------------------------------------------------------------*

LOAD-OF-PROGRAM.

INITIALIZATION.
  sscrfields-functxt_01 = '지급 조회로'.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      SUBMIT zlfia00010
      VIA SELECTION-SCREEN.
  ENDCASE.

AT SELECTION-SCREEN OUTPUT.

START-OF-SELECTION.
  PERFORM get_data_dummy.
  CALL SCREEN 100.
