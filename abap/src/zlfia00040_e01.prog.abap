*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_E01
*&---------------------------------------------------------------------*
LOAD-OF-PROGRAM.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_rcpac.
  PERFORM f4_rcpac.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_kunnr.
  PERFORM f4_kunnr.

AT SELECTION-SCREEN OUTPUT.
  PERFORM set_kunnr_text.
  PERFORM set_bank_text.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'PM01'. PERFORM set_period USING 1.
    WHEN 'PM03'. PERFORM set_period USING 3.
    WHEN 'PM12'. PERFORM set_period USING 12.
  ENDCASE.

START-OF-SELECTION.
  PERFORM get_data.                               " 들어오자마자 최근 10건
  CALL SCREEN 0100.
