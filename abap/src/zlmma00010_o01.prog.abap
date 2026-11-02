*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_O01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module CLEAR_OK_CODE OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE clear_ok_code OUTPUT.

  CLEAR ok_code.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  SET PF-STATUS 'G0100' EXCLUDING 'CRPR'.
  SET TITLEBAR 'T0100'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module DISPLAY_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_alv OUTPUT.

  IF go_cont IS INITIAL.

    CREATE OBJECT go_cont
      EXPORTING
        container_name = 'CC_MAIN'.

    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_cont.

    PERFORM zz_set_field_catalog.
    PERFORM zz_set_layout.

    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layo
      CHANGING
        it_outtab       = gt_shortage
        it_fieldcatalog = gt_fcat.

  ENDIF.

ENDMODULE.
