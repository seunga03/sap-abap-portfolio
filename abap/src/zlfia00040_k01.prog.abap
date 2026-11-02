*&---------------------------------------------------------------------*
*& Include          ZLFIA00040_K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_double_click.
    CHECK es_row_no-row_id > 0.                  " 소계 줄 더블클릭은 무시
    READ TABLE gt_head INTO gw_head INDEX es_row_no-row_id.
    CHECK sy-subrc = 0.

    PERFORM get_detail.
    PERFORM refresh_alv2.
  ENDMETHOD.
ENDCLASS.
