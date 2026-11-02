*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_E01
*&---------------------------------------------------------------------*
LOAD-OF-PROGRAM.
  sscrfields-functxt_01 = '수금 등록으로'.

INITIALIZATION.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      SUBMIT zlfia00050
        VIA SELECTION-SCREEN.
  ENDCASE.

AT SELECTION-SCREEN OUTPUT.

START-OF-SELECTION.

  PERFORM get_data_dummy.
  CALL SCREEN 0100.
