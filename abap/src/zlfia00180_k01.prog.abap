*&---------------------------------------------------------------------*
*& Include          ZLFIA00080_K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_data_changed_finished
      FOR EVENT data_changed_finished OF cl_gui_alv_grid
      IMPORTING e_modified et_good_cells.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_data_changed_finished.
    DATA ls_stable TYPE lvc_s_stbl.

    CHECK e_modified = 'X'.

    PERFORM calc_total.                       " 청구금액 재계산 + 합계/차이

    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    go_alv_reg->refresh_table_display( EXPORTING is_stable = ls_stable ).

    " 화면 상단 합계/차이 필드 갱신용 PBO 재실행 (저장 중엔 생략)
    IF gv_saving IS INITIAL.
      cl_gui_cfw=>set_new_ok_code( new_code = 'REFR' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
