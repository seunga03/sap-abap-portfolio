*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_E01
*&---------------------------------------------------------------------*

LOAD-OF-PROGRAM.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_kunnr.
  PERFORM f4_kunnr.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_rcpac.
  PERFORM f4_rcpac.

AT SELECTION-SCREEN OUTPUT.
  PERFORM set_kunnr_text.
  PERFORM set_bank_text.

START-OF-SELECTION.
  PERFORM get_data.                               " 들어오자마자 미수·부분수금 (수금기한 빠른 순)
  CALL SCREEN 0100.
