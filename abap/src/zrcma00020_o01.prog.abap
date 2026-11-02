*&---------------------------------------------------------------------*
*& Include          ZRCMA00020_O01
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  DATA(lv_cnt)  = CONV string( lines( gt_list ) ).
  DATA(lv_crit) = CONV string( REDUCE i( INIT n = 0 FOR ls IN gt_list
                                         WHERE ( rkgrd = 'CRITICAL' ) NEXT n = n + 1 ) ).
  DATA(lv_warn) = CONV string( REDUCE i( INIT n = 0 FOR ls IN gt_list
                                         WHERE ( rkgrd = 'WARNING' )  NEXT n = n + 1 ) ).
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100' WITH lv_cnt lv_crit lv_warn.
ENDMODULE.
MODULE init_alv_0100 OUTPUT.
  IF go_cont_0100 IS INITIAL.
    CREATE OBJECT go_cont_0100 EXPORTING container_name = 'CC_0100'.
    CREATE OBJECT go_grid_0100 EXPORTING i_parent = go_cont_0100.
    PERFORM build_fcat_0100.
    DATA lt_exclude TYPE ui_functions.
    PERFORM build_toolbar_exclude CHANGING lt_exclude.
    go_grid_0100->set_table_for_first_display(
      EXPORTING is_layout       = VALUE lvc_s_layo( zebra = 'X' cwidth_opt = 'X'
                                                    sel_mode = 'A' info_fname = 'ROWCOLOR' )
                                                    it_toolbar_excluding = lt_exclude
      CHANGING  it_outtab       = gt_list
                it_fieldcatalog = gt_fcat_0100 ).
  ELSE.
    go_grid_0100->refresh_table_display( ).
  ENDIF.
ENDMODULE.

MODULE status_0200 OUTPUT.
  SET PF-STATUS 'S0200'.
  SET TITLEBAR 'T0200'.
ENDMODULE.

MODULE init_alv_0200 OUTPUT.
  PERFORM build_fcat_0200.
  IF go_cont_0200 IS INITIAL.
    CREATE OBJECT go_cont_0200 EXPORTING container_name = 'CC_0200'.
    CREATE OBJECT go_grid_0200 EXPORTING i_parent = go_cont_0200.
    go_grid_0200->set_table_for_first_display(
      EXPORTING is_layout       = VALUE lvc_s_layo( zebra = 'X' cwidth_opt = 'X' )
      CHANGING  it_outtab       = gt_stat
                it_fieldcatalog = gt_fcat_0200 ).
  ELSE.
    go_grid_0200->set_frontend_fieldcatalog( gt_fcat_0200 ).   " 공급업체/자재군 제목 전환
    go_grid_0200->refresh_table_display( ).
  ENDIF.
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
