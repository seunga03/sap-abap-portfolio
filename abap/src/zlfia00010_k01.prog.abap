*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.

    CLASS-METHODS on_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_double_click.
    CHECK es_row_no-row_id > 0.                  " 소계 줄 더블클릭은 무시
    READ TABLE gt_head INTO gw_head INDEX es_row_no-row_id.
    CHECK sy-subrc = 0.

    PERFORM get_detail.
    PERFORM refresh_alv2.
  ENDMETHOD.

  METHOD on_hotspot_click.
    DATA ls_item LIKE gw_item.

    CHECK e_row_id-rowtype IS INITIAL.            " 합계 줄 클릭은 무시
    CHECK e_column_id-fieldname = 'IVNUM'.

    READ TABLE gt_item INTO ls_item INDEX e_row_id-index.
    CHECK sy-subrc = 0 AND ls_item-ivnum IS NOT INITIAL.

    PERFORM call_invoice USING ls_item-ivnum.
  ENDMETHOD.
ENDCLASS.
