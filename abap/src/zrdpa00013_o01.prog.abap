*&---------------------------------------------------------------------*
*& Include          ZRDPA00013_O01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  SET PF-STATUS 'G0100'.
  SET TITLEBAR  'T0100'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

  SET PF-STATUS 'G0200'.
  SET TITLEBAR  'T0200'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module CLEAR_OK_CODE OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE clear_ok_code OUTPUT.

  CLEAR ok_code.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module DISPLAY_PLAN_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_plan_alv OUTPUT.

  IF go_cont_plan IS NOT BOUND. " IF go_cont_plan IS INITIAL.

    CREATE OBJECT go_cont_plan
      EXPORTING
        container_name = 'CC_PLAN'.

    CREATE OBJECT go_grid_plan
      EXPORTING
        i_parent = go_cont_plan.

    PERFORM zz_set_plan_fcat.

    CLEAR gs_layo.
    gs_layo-sel_mode   = 'A'.
    gs_layo-zebra      = abap_true.
    gs_layo-cwidth_opt = abap_true.

    CALL METHOD go_grid_plan->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layo
      CHANGING
        it_outtab       = gt_plan
        it_fieldcatalog = gt_plan_fcat.

  ELSE.

    go_grid_plan->refresh_table_display( ).

  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module DISPLAY_EVENT_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_event_alv OUTPUT.

  IF go_cont_event IS NOT BOUND. " IF go_cont_event IS INITIAL.

    CREATE OBJECT go_cont_event
      EXPORTING
        container_name = 'CC_EVENT'.

    CREATE OBJECT go_grid_event
      EXPORTING
        i_parent = go_cont_event.

    PERFORM zz_set_event_fcat.

    CLEAR gs_layo.
    gs_layo-sel_mode   = 'A'.
    gs_layo-zebra      = abap_true.
    gs_layo-cwidth_opt = abap_true.

    CALL METHOD go_grid_event->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layo
      CHANGING
        it_outtab       = gt_event
        it_fieldcatalog = gt_event_fcat.

  ELSE.

    go_grid_event->refresh_table_display( ).

  ENDIF.


ENDMODULE.
