*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_E01
*&---------------------------------------------------------------------*
LOAD-OF-PROGRAM.

INITIALIZATION.
  sscrfields-functxt_01 = '지급 등록으로'.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      SUBMIT zlfia00020
      VIA SELECTION-SCREEN.
  ENDCASE.


AT SELECTION-SCREEN OUTPUT.

START-OF-SELECTION.

  PERFORM get_data_dummy.
  CALL SCREEN 0100.
