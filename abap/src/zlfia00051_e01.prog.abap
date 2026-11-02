*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_E01
*&---------------------------------------------------------------------*

LOAD-OF-PROGRAM.
sscrfields-functxt_01 = '수금 조회로'.
INITIALIZATION.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      SUBMIT zlfia00040
        VIA SELECTION-SCREEN.
  ENDCASE.
AT SELECTION-SCREEN OUTPUT.

START-OF-SELECTION.
  PERFORM get_data_dummy.
  CALL SCREEN 100.
