*&---------------------------------------------------------------------*
*& Include          ZLCMA00020_O01
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  DATA(lv_cnt) = CONV string( lines( gt_vendor ) ).
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100' WITH lv_cnt.
ENDMODULE.

MODULE init_alv_0100 OUTPUT.
  IF go_container IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING container_name = 'CC_0100'.
    CREATE OBJECT go_grid
      EXPORTING i_parent = go_container.

    PERFORM build_fcat.
    gs_layout = VALUE #( sel_mode   = 'A'          " 행 선택 버튼 (☐ 역할)
                         zebra      = 'X'
                         "cwidth_opt = 'A'
                         info_fname = 'ROWCOLOR' ).

    CREATE OBJECT go_handler.
    SET HANDLER go_handler->on_hotspot_click FOR go_grid.

    DATA lt_exclude TYPE ui_functions.                      " ← 추가 1
    PERFORM build_toolbar_exclude CHANGING lt_exclude.      " ← 추가 2

    go_grid->set_table_for_first_display(
      EXPORTING is_layout            = gs_layout
                it_toolbar_excluding = lt_exclude           " ← 추가 3
      CHANGING  it_outtab            = gt_vendor
                it_fieldcatalog      = gt_fcat ).
  ELSE.
    go_grid->refresh_table_display(
      is_stable = VALUE #( row = 'X' col = 'X' ) ).
  ENDIF.
ENDMODULE.

MODULE status_0200 OUTPUT.
  CLEAR gt_excl.
  IF gv_mode = gc_mode_display.
    APPEND 'SAVE' TO gt_excl.                  " 조회 모드: [저장] 비활성
  ENDIF.
  SET PF-STATUS 'S0200' EXCLUDING gt_excl.

  CASE gv_mode.
    WHEN gc_mode_create.  SET TITLEBAR 'T0200' WITH '생성'.
    WHEN gc_mode_change.  SET TITLEBAR 'T0200' WITH '변경'.
    WHEN gc_mode_display. SET TITLEBAR 'T0200' WITH '조회'.
  ENDCASE.
ENDMODULE.

MODULE modify_screen_0200 OUTPUT.
  " Group1: KEY=공급업체번호 / ADM=관리정보 / INP=일반 입력 / INR=비활성사유
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'KEY' OR 'ADM'.
        screen-input = 0.
      WHEN 'INP'.
        IF gv_mode = gc_mode_display.
          screen-input = 0.
        ENDIF.
      WHEN 'INR'.
        IF gv_mode = gc_mode_display OR gv_rb_y = 'X'.
          screen-input = 0.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.

MODULE init_kpi_0100 OUTPUT.
  IF go_cont_kpi IS INITIAL.
    CREATE OBJECT go_cont_kpi EXPORTING container_name = 'CC_KPI'.
    CREATE OBJECT go_kpi EXPORTING io_parent = go_cont_kpi.
    gv_kpi_dirty = abap_true.
  ENDIF.
  IF gv_kpi_dirty = abap_true.
    PERFORM show_kpi_0100.

    gv_kpi_dirty = abap_false.
  ENDIF.
ENDMODULE.
