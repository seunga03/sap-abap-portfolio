*&---------------------------------------------------------------------*
*& Include          ZLFIA00070_K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.

    CLASS-METHODS on_item_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_double_click.
    DATA: ls_stable TYPE lvc_s_stbl,
          lv_amt    TYPE c LENGTH 30.

    READ TABLE gt_head INTO gw_head INDEX es_row_no-row_id.
    CHECK sy-subrc = 0.

    CLEAR gt_item.

    " 저장된 송장 라인 그대로 (3WM 재계산 안 함 → 헤더 판정과 항상 같은 기준)
    SELECT ivnum invit ebelp matnr menge meins netpr wrbtr mstat ponpr pasqt cumqt
      FROM ztfia00020
      INTO CORRESPONDING FIELDS OF TABLE gt_item
      WHERE ivnum = gw_head-ivnum.

    " 통화는 헤더에만 있으므로 헤더 값으로 채움
    gw_item-waers = gw_head-waers.
    MODIFY gt_item FROM gw_item TRANSPORTING waers WHERE waers IS INITIAL.

    " 하단 제목 = 선택한 송장 요약
    WRITE gw_head-wrbtr TO lv_amt CURRENCY gw_head-waers.   " KRW 100배 보정
    CONDENSE lv_amt.
    go_alv2->set_gridtitle(
      CONV lvc_title( |{ gw_head-ivnum } / { gw_head-name1 } / PO { gw_head-ebeln } / { gw_head-mstat } / { lv_amt } { gw_head-waers }| ) ).
    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    go_alv2->refresh_table_display( is_stable = ls_stable ).
  ENDMETHOD.

  METHOD on_item_double_click.
    TYPES: BEGIN OF ty_cmp,
             item TYPE c LENGTH 14,              " 구분
             val  TYPE c LENGTH 25,              " 값
           END OF ty_cmp.
    DATA: lt_cmp   TYPE TABLE OF ty_cmp,
          ls_cmp   TYPE ty_cmp,
          lv_judge TYPE ztfia00010-mstat,        " 저장값으로 본 3WM 판정
          lv_title TYPE lvc_title,
          lo_alv   TYPE REF TO cl_salv_table,
          lo_cols  TYPE REF TO cl_salv_columns_table,
          lo_col   TYPE REF TO cl_salv_column.

    READ TABLE gt_item INTO gw_item INDEX es_row_no-row_id.
    CHECK sy-subrc = 0.

    "─ 판정 근거 값이 없으면 (필드 추가 전 등록된 송장)
    IF gw_item-ponpr IS INITIAL AND gw_item-pasqt IS INITIAL AND gw_item-cumqt IS INITIAL.
      MESSAGE s414(zmsga) DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    "─ 저장값으로 판정 재구성 (3WM 규칙과 같음)
    IF gw_item-cumqt > gw_item-pasqt.
      lv_judge = 'QREJ'.
    ELSEIF gw_item-netpr <> gw_item-ponpr.
      lv_judge = 'HOLD'.
    ELSE.
      lv_judge = 'PASS'.
    ENDIF.

    "─ 표 행
    DEFINE add_qty.
      CLEAR ls_cmp.
      ls_cmp-item = &1.
      WRITE &2 TO ls_cmp-val UNIT gw_item-meins LEFT-JUSTIFIED.
      ls_cmp-val = |{ ls_cmp-val } { gw_item-meins }|.
      APPEND ls_cmp TO lt_cmp.
    END-OF-DEFINITION.

    DEFINE add_amt.
      CLEAR ls_cmp.
      ls_cmp-item = &1.
      WRITE &2 TO ls_cmp-val CURRENCY gw_head-waers LEFT-JUSTIFIED.
      APPEND ls_cmp TO lt_cmp.
    END-OF-DEFINITION.

    add_qty '청구수량'     gw_item-menge.
    add_qty '누적청구량'   gw_item-cumqt.
    add_qty '합격수량누계' gw_item-pasqt.
    add_amt '청구단가'     gw_item-netpr.
    add_amt 'PO단가'       gw_item-ponpr.

    CLEAR ls_cmp.
    ls_cmp-item = '판정'.
    PERFORM mstat_reason USING lv_judge CHANGING ls_cmp-val.
    APPEND ls_cmp TO lt_cmp.

    "─ 사람이 처리해서 상태가 바뀐 라인만 한 줄 더
    IF gw_item-mstat <> lv_judge.
      CLEAR ls_cmp.
      ls_cmp-item = '처리'.
      CASE gw_item-mstat.
        WHEN 'PASS'. ls_cmp-val = '조정 반제 → PASS'.
        WHEN 'CANC'. ls_cmp-val = '송장 취소 (CANC)'.
        WHEN OTHERS. ls_cmp-val = gw_item-mstat.
      ENDCASE.
      APPEND ls_cmp TO lt_cmp.
    ENDIF.

    "─ 팝업 ALV
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                                CHANGING  t_table      = lt_cmp ).
      CATCH cx_salv_msg.
        RETURN.
    ENDTRY.

    lo_cols = lo_alv->get_columns( ).
    lo_cols->set_optimize( abap_false ).
    TRY.
        lo_col = lo_cols->get_column( 'ITEM' ).
        lo_col->set_short_text( '구분' ).
        lo_col->set_medium_text( '구분' ).
        lo_col->set_long_text( '구분' ).
        lo_col->set_output_length( 8 ).
        lo_col = lo_cols->get_column( 'VAL' ).
        lo_col->set_short_text( '값' ).
        lo_col->set_medium_text( '값' ).
        lo_col->set_long_text( '값' ).
        lo_col->set_output_length( 9 ).
      CATCH cx_salv_not_found.
    ENDTRY.

    lv_title = |{ gw_head-ivnum } / 라인 { gw_item-invit ALPHA = OUT } / PO라인 { gw_item-ebelp ALPHA = OUT } / { gw_item-matnr }|.
    lo_alv->get_display_settings( )->set_list_header( lv_title ).
    lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).

    lo_alv->set_screen_popup( start_column = 30
                              end_column   = 75
                              start_line   = 6
                              end_line     = 15 ).
    lo_alv->display( ).
  ENDMETHOD.

ENDCLASS.
