*&---------------------------------------------------------------------*
*& Include          ZLFIA00110_C01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_dblclick FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_dblclick.
    " 위 ALV(만기 구간) 줄 더블클릭 → 아래 목록을 그 구간만
    IF e_row-rowtype IS NOT INITIAL.     " ALV 자동 합계 줄은 무시
      RETURN.
    ENDIF.
    PERFORM filter_bucket USING e_row-index.
  ENDMETHOD.
ENDCLASS.
