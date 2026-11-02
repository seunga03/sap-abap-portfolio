*&---------------------------------------------------------------------*
*& Include          ZRFIA00010_C01
*&---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS on_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD on_hotspot_click.
    " 원천번호 / 지급번호 클릭 → 0200 상세
    DATA lv_index TYPE i.
    lv_index = e_row_id-index.
    PERFORM open_detail USING lv_index.
  ENDMETHOD.
ENDCLASS.
