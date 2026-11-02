*&---------------------------------------------------------------------*
*& Include          ZLFIA00090_K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_double_click.
    DATA ls_stable TYPE lvc_s_stbl.

    READ TABLE gt_res INTO gw_res INDEX es_row_no-row_id.
    CHECK sy-subrc = 0.

    CLEAR gt_item.
    LOOP AT gt_item_all INTO gw_item WHERE ivnum = gw_res-ivnum.
      APPEND gw_item TO gt_item.
    ENDLOOP.

    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    go_alv2->refresh_table_display( is_stable = ls_stable ).
  ENDMETHOD.

ENDCLASS.
