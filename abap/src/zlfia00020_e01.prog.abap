*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_E01
*&---------------------------------------------------------------------*

LOAD-OF-PROGRAM.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_payac.
  PERFORM f4_payac.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_lifnr.
  PERFORM f4_lifnr.

AT SELECTION-SCREEN OUTPUT.
  PERFORM set_lifnr_text.
  PERFORM set_bank_text.

START-OF-SELECTION.
  PERFORM get_data.                               " 들어오자마자 미결·부분지급 채무
  CALL SCREEN 0100.
