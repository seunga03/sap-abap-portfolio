*&---------------------------------------------------------------------*
*& Include          ZRDPA00023_O01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  SET PF-STATUS 'G0100'.
  SET TITLEBAR 'T0100'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

  SET PF-STATUS 'G0200'.
  SET TITLEBAR 'T0200'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module display_reason OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_reason OUTPUT.

  IF go_reason_edit IS NOT BOUND.

    CREATE OBJECT go_reason_cont
      EXPORTING container_name = 'CC_REASON'.

    CREATE OBJECT go_reason_edit
      EXPORTING parent = go_reason_cont.

    go_reason_edit->set_readonly_mode( readonly_mode = 1 ).
    go_reason_edit->set_toolbar_mode( toolbar_mode = 0 ).
    go_reason_edit->set_statusbar_mode( statusbar_mode = 0 ).

  ENDIF.

  go_reason_edit->set_textstream( text = gv_reason ).
  cl_gui_cfw=>flush( ).

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module DISPLAY_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_alv OUTPUT.

  IF go_grid IS NOT BOUND.
    CREATE OBJECT go_cont
      EXPORTING container_name = 'CC_MAIN'.

    CREATE OBJECT go_grid
      EXPORTING i_parent = go_cont.

    CREATE OBJECT go_event.

    SET HANDLER go_event->handle_hotspot_click FOR go_grid.

    PERFORM zz_set_fcat.

    CLEAR gs_layo.
    gs_layo-zebra = abap_true.
    gs_layo-cwidth_opt = abap_true.
    gs_layo-sel_mode = 'A'.

    go_grid->set_table_for_first_display(
      EXPORTING is_layout = gs_layo
      CHANGING it_outtab = gt_display
               it_fieldcatalog = gt_fcat ).
  ENDIF.

ENDMODULE.
