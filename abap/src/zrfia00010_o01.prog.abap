*&---------------------------------------------------------------------*
*& Include          ZRFIA00010_O01
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  CLEAR gt_excl.
  IF gt_list IS INITIAL.
    gt_excl = VALUE #( ( 'DETAIL' ) ( 'PREVIEW' ) ( 'PRINT' )
                       ( 'HISTORY' ) ( 'SALL' ) ( 'DALL' ) ).
  ENDIF.
  SET PF-STATUS 'S0100' EXCLUDING gt_excl.

  DATA(lv_cnt) = CONV string( lines( gt_list ) ).
  DATA(lv_typ) = COND string( WHEN p_ap = 'X' THEN '매입채무(AP)'
                              WHEN p_ar = 'X' THEN '매출채권(AR)'
                              ELSE '전체' ).
  DATA(lv_qck) = COND string( WHEN p_q_np = 'X' THEN '확인서 미출력'
                              WHEN p_q_op = 'X' THEN '잔액 남은 건'
                              ELSE '전체' ).
  SET TITLEBAR 'T0100' WITH lv_typ lv_qck lv_cnt.
ENDMODULE.
MODULE init_alv_0100 OUTPUT.
  IF go_cont_0100 IS INITIAL.
    CREATE OBJECT go_cont_0100 EXPORTING container_name = 'CC_0100'.
    CREATE OBJECT go_grid_0100 EXPORTING i_parent = go_cont_0100.
    PERFORM build_fcat_0100.

    CREATE OBJECT go_handler.
    SET HANDLER go_handler->on_hotspot_click FOR go_grid_0100.
    DATA lt_exclude TYPE ui_functions.
    PERFORM build_toolbar_exclude CHANGING lt_exclude.
        go_grid_0100->set_table_for_first_display(
      EXPORTING is_layout       = VALUE lvc_s_layo( zebra = 'X' cwidth_opt = 'X'
                                                    info_fname = 'ROWCOLOR'
                                                    no_rowmark = 'X' )
                it_toolbar_excluding = lt_exclude
                is_variant      = VALUE disvariant( report = sy-repid )   " ★ p_vari 제거
                i_save          = 'A'
                i_default       = 'X'                                     " ★ 기본 레이아웃 자동 적용
      CHANGING  it_outtab       = gt_list
                it_fieldcatalog = gt_fcat_0100 ).
  ELSE.
    go_grid_0100->refresh_table_display( is_stable = VALUE #( row = 'X' col = 'X' ) ).
  ENDIF.
ENDMODULE.

MODULE status_0200 OUTPUT.
  SET PF-STATUS 'S0200'.
  SET TITLEBAR 'T0200' WITH gs_0200-clrnr.

  WRITE gs_0200-dmbtr  TO gv_dmbtr_c  CURRENCY gs_0200-waers RIGHT-JUSTIFIED.
  WRITE gs_0200-clram  TO gv_clram_c  CURRENCY gs_0200-waers RIGHT-JUSTIFIED.
  WRITE gs_0200-openam TO gv_openam_c CURRENCY gs_0200-waers RIGHT-JUSTIFIED.
ENDMODULE.

MODULE status_0300 OUTPUT.
  SET PF-STATUS 'S0300'.
  SET TITLEBAR 'T0300'.
ENDMODULE.

MODULE init_alv_0300 OUTPUT.
  IF go_cont_0300 IS INITIAL.
    CREATE OBJECT go_cont_0300 EXPORTING container_name = 'CC_0300'.
    CREATE OBJECT go_grid_0300 EXPORTING i_parent = go_cont_0300.
    gt_fcat_0300 = VALUE #(
      ( fieldname = 'PRNUM' coltext = '출력번호' )
      ( fieldname = 'DCTYP' coltext = '문서유형' )
      ( fieldname = 'DCNUM' coltext = '반제번호' )
      ( fieldname = 'FMTYP' coltext = '서류종류' )
      ( fieldname = 'PRTMS' coltext = '출력일시' )
      ( fieldname = 'UNAME' coltext = '출력자' ) ).
    go_grid_0300->set_table_for_first_display(
      EXPORTING is_layout       = VALUE lvc_s_layo( zebra = 'X' cwidth_opt = 'X' )
      CHANGING  it_outtab       = gt_hist
                it_fieldcatalog = gt_fcat_0300 ).
  ENDIF.
ENDMODULE.

MODULE init_kpi_0100 OUTPUT.
  IF go_cont_kpi IS INITIAL.
    CREATE OBJECT go_cont_kpi EXPORTING container_name = 'CC_KPI'.
    CREATE OBJECT go_kpi      EXPORTING io_parent      = go_cont_kpi.
    gv_kpi_dirty = abap_true.
  ENDIF.
  IF gv_kpi_dirty = abap_true.
    PERFORM show_kpi_0100.
    gv_kpi_dirty = abap_false.
  ENDIF.

ENDMODULE.
