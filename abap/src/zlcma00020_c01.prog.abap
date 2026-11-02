*&---------------------------------------------------------------------*
*& Include          ZLCMA00020_C01
*&---------------------------------------------------------------------*

CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS on_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD on_hotspot_click.
    " 공급업체번호 클릭 → SCR 0200 조회 모드
    READ TABLE gt_vendor INTO DATA(ls_vendor) INDEX e_row_id-index.
    CHECK sy-subrc = 0.
    PERFORM open_detail USING gc_mode_display ls_vendor-lifnr.
  ENDMETHOD.
ENDCLASS.
