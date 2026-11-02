*&---------------------------------------------------------------------*
*& Include          ZRCMA00020_F01
*&---------------------------------------------------------------------*

FORM init_selection.
  sscrfields-functxt_01 = VALUE smp_dyntxt( icon_id   = icon_refresh
                                            icon_text = '초기화' ).
ENDFORM.

FORM check_selection.
  IF sscrfields-ucomm = 'FC01'.
    CLEAR: s_werks, s_werks[], s_lifnr, s_lifnr[], s_matkl, s_matkl[],
           p_q_op, p_q_dr.
    p_q_rk = 'X'.                                   " 빠른 조회 = 위험 건만
    p_nor = 'X'. p_war = 'X'. p_cri = 'X'. p_open = 'X'.   " 직접 조건 기본값
  ENDIF.
  IF sscrfields-ucomm = 'ONLI' AND p_q_dr = 'X'
     AND p_nor IS INITIAL AND p_war IS INITIAL AND p_cri IS INITIAL.
    MESSAGE e320(zmsga).
  ENDIF.
ENDFORM.
*--- 조회 ------------------------------------------------------------*
FORM select_data.
  CLEAR gt_list.

  PERFORM select_data_db.

  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<ls_list>).
    <ls_list>-dlday = nmax( val1 = 0 val2 = sy-datum - <ls_list>-eindt ).
    PERFORM set_grade CHANGING <ls_list>.
  ENDLOOP.

  PERFORM set_exflg.
  CASE 'X'.
    WHEN p_q_rk.                       " 위험 건만: WARNING·CRITICAL
      DELETE gt_list WHERE rkgrd = 'NORMAL'.
    WHEN p_q_op.                       " 전체 미입고: 등급 필터 없음
    WHEN p_q_dr.                       " 직접 조건: 체크박스 반영
      IF p_nor IS INITIAL. DELETE gt_list WHERE rkgrd = 'NORMAL'.   ENDIF.
      IF p_war IS INITIAL. DELETE gt_list WHERE rkgrd = 'WARNING'.  ENDIF.
      IF p_cri IS INITIAL. DELETE gt_list WHERE rkgrd = 'CRITICAL'. ENDIF.
  ENDCASE.
  gv_kpi_dirty = abap_true.
  ENDFORM.

FORM set_grade CHANGING cs_list TYPE ty_list.
  CLEAR: cs_list-rkgrd, cs_list-rowcolor.

  CALL FUNCTION 'ZCM_RISK_GRADE_GET'
    EXPORTING
      iv_dlday = cs_list-dlday
    IMPORTING
      ev_grade = cs_list-rkgrd
      ev_color = cs_list-rowcolor.

ENDFORM.
*--- 통계 ------------------------------------------------------------*
FORM build_stat.
  CLEAR gt_stat.

  LOOP AT gt_list INTO DATA(ls_list) WHERE dlday > 0.
    CHECK ls_list-eindt(6) = gv_spmon.
    DATA(lv_key) = COND char40( WHEN gv_rb_ven = 'X' THEN ls_list-name1
                                ELSE ls_list-matkl ).
    IF lv_key IS INITIAL.
      lv_key = TEXT-s01.
    ENDIF.

    READ TABLE gt_stat ASSIGNING FIELD-SYMBOL(<ls_stat>) WITH KEY grpky = lv_key.
    IF sy-subrc <> 0.
      APPEND VALUE #( grpky = lv_key ) TO gt_stat ASSIGNING <ls_stat>.
    ENDIF.
    <ls_stat>-delay_cnt += 1.
    <ls_stat>-avg_dlday += ls_list-dlday.          " 합계 → 아래서 평균
    IF ls_list-rkgrd = 'CRITICAL'.
      <ls_stat>-crit_cnt += 1.
    ENDIF.
  ENDLOOP.
  " 평균 계산 LOOP
  LOOP AT gt_stat ASSIGNING <ls_stat>.
    <ls_stat>-avg_dlday = <ls_stat>-avg_dlday / <ls_stat>-delay_cnt.
  ENDLOOP.

 SORT gt_stat BY crit_cnt DESCENDING delay_cnt DESCENDING grpky.

  IF gt_stat IS INITIAL.
    DATA(lv_mon) = |{ gv_spmon(4) }.{ gv_spmon+4(2) }|.
    MESSAGE s042 WITH lv_mon.
  ENDIF.

ENDFORM.

*--- Fieldcatalog ----------------------------------------------------*
FORM build_fcat_0100.
  gt_fcat_0100 = VALUE #(
    ( fieldname = 'EBELN' coltext = 'PO' )
    ( fieldname = 'EBELP' coltext = 'Item' )
    ( fieldname = 'MATNR' coltext = '자재' )
    ( fieldname = 'NAME1' coltext = '공급업체' )
    ( fieldname = 'EINDT' coltext = '예정입고일' )
    ( fieldname = 'DLDAY' coltext = '지연일수' )
    ( fieldname = 'RKGRD' coltext = '위험등급' )
    ( fieldname = 'EXFLG' coltext = 'Exception' )
    ( fieldname = 'MATKL' coltext = '자재군' no_out = 'X' )
    ( fieldname = 'LIFNR' coltext = '공급업체번호' no_out = 'X' ) ).
ENDFORM.

FORM build_fcat_0200.
  gt_fcat_0200 = VALUE #(
    ( fieldname = 'GRPKY'
      coltext   = COND #( WHEN gv_rb_ven = 'X' THEN '공급업체' ELSE '자재군' ) )
    ( fieldname = 'DELAY_CNT' coltext = '지연건수' )
    ( fieldname = 'AVG_DLDAY' coltext = '평균지연일수' )
    ( fieldname = 'CRIT_CNT'  coltext = 'CRITICAL건수' ) ).
ENDFORM.

FORM free_alv.
    IF go_kpi IS BOUND.
    go_kpi->free( ).
  ENDIF.
  IF go_cont_kpi IS BOUND.
    go_cont_kpi->free( ).
  ENDIF.
  FREE: go_kpi, go_cont_kpi.
  IF go_cont_0100 IS BOUND.
    go_cont_0100->free( ).
  ENDIF.
  FREE: go_grid_0100, go_cont_0100.
ENDFORM.

*FORM load_grade_range .
*  " TODO(A1/FM): ZCM_RISK_GRADE_GET 또는 ZTCMA00080(CDGRP='RKGRD')로 교체
*  "             구간값은 FM 초안 기준 NORM 0~0 / WARN 1~4 / CRIT 5~9999
*  gt_range = VALUE #(
*    ( grade = 'NORMAL'   numfr = 0 numto = 0 )
*    ( grade = 'WARNING'  numfr = 1 numto = 4    color = 'C310' )     " 노랑
*    ( grade = 'CRITICAL' numfr = 5 numto = 9999 color = 'C610' ) ).  " 빨강
*
*ENDFORM.

FORM modify_selection.
  " '직접 조건'이 아니면 등급·미입고 조건은 회색 (값은 무시됨)
  LOOP AT SCREEN.
    IF screen-group1 = 'DRC' AND p_q_dr IS INITIAL.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_kpi_0100
*&---------------------------------------------------------------------*
FORM show_kpi_0100.
  DATA: lv_crit TYPE i,
        lv_warn TYPE i,
        lv_norm TYPE i,
        lv_late TYPE i,
        lv_exc  TYPE i,
        lv_sum  TYPE i.

  LOOP AT gt_list INTO DATA(ls_l).
    CASE ls_l-rkgrd.
      WHEN 'CRITICAL'. lv_crit = lv_crit + 1.
      WHEN 'WARNING'.  lv_warn = lv_warn + 1.
      WHEN OTHERS.     lv_norm = lv_norm + 1.
    ENDCASE.
    IF ls_l-dlday > 0.
      lv_late = lv_late + 1.
      lv_sum  = lv_sum + ls_l-dlday.
    ENDIF.
    IF ls_l-exflg = '있음'.
      lv_exc = lv_exc + 1.
    ENDIF.
  ENDLOOP.

  DATA(lv_total)  = lines( gt_list ).
  DATA(lv_ontime) = COND i( WHEN lv_total > 0 THEN lv_norm * 100 / lv_total ELSE 0 ).
  DATA(lv_avg)    = COND decfloat34( WHEN lv_late > 0 THEN lv_sum / lv_late ELSE 0 ).

  " 차트 종류 : 'D' 도넛 / 'B' 막대
  CONSTANTS lc_chart TYPE zcl_cm_kpi_html=>ty_ctype VALUE 'D'.

  DATA(lt_card) = VALUE zcl_cm_kpi_html=>tt_card(
    ( label = '지연 건수'     value = |{ lv_late }건|
      sub = '예정입고일 경과'  color = COND #( WHEN lv_late > 0 THEN 'Y' ELSE 'G' ) )
    ( label = 'CRITICAL'      value = |{ lv_crit }건|
      sub = '즉시 조치 필요'   color = COND #( WHEN lv_crit > 0 THEN 'R' ELSE 'G' ) )
    ( label = '평균 지연일수' value = |{ lv_avg DECIMALS = 1 NUMBER = RAW }일|
      sub = '지연 건 기준'     color = 'B' )
    ( label = 'Exception 연결' value = |{ lv_exc }건|
      sub = 'CM03에서 처리'    color = 'B' ) ).

  DATA(lt_item) = VALUE zcl_cm_kpi_html=>tt_item(
    ( label = 'CRITICAL' value = lv_crit color = 'R' )
    ( label = 'WARNING'  value = lv_warn color = 'Y' )
    ( label = 'NORMAL'   value = lv_norm color = 'G' ) ).

  go_kpi->show_summary(
    iv_title = '납기 리스크 모니터링'
    iv_chart_type   = lc_chart
    iv_chart_title  = '위험등급 분포'
    it_chart_item   = lt_item
    iv_chart_center = |{ lv_total }건|
    it_card         = lt_card
    iv_foot         = '※ 조회 조건에 맞는 목록 기준 (가운데 숫자 = 조회 건수)' ).

ENDFORM.

*--- 실데이터 조회 (PO 아이템 - 입고 합계 - 헤더/업체/자재군) --------------*
FORM select_data_db.
  TYPES: BEGIN OF ty_rcv,
           ebeln TYPE ztmma00090-ebeln,
           ebelp TYPE ztmma00090-ebelp,
           menge TYPE ztmma00090-menge,
         END OF ty_rcv.
  DATA: lt_rcv TYPE SORTED TABLE OF ty_rcv WITH UNIQUE KEY ebeln ebelp,
        lv_rcv TYPE ztmma00090-menge.

  " 1) PO 아이템 + 헤더 + 업체명 + 자재군 (먼저 조회)
  SELECT i~ebeln, i~ebelp, i~matnr, i~menge, i~eindt,
         h~lifnr, v~name1, m~matkl
    FROM ztmma00060 AS i
    INNER JOIN ztmma00050 AS h ON h~ebeln = i~ebeln
    LEFT OUTER JOIN ztcma00010 AS v ON v~lifnr = h~lifnr
    LEFT OUTER JOIN mara AS m ON m~matnr = i~matnr
    WHERE i~werks IN @s_werks
      AND h~lifnr IN @s_lifnr
    ORDER BY i~eindt, i~ebeln, i~ebelp
    INTO TABLE @DATA(lt_po).

  DELETE lt_po WHERE matkl NOT IN s_matkl.
  CHECK lt_po IS NOT INITIAL.             " FAE는 빈 테이블이면 전체를 읽으니 반드시 가드

  " 2) 입고는 위 PO 품목만 (행 단위로 읽고 합산, 키 필드를 넣어야 중복 제거 안 됨)
  SELECT mblnr, mjahr, zeile, ebeln, ebelp, menge
    FROM ztmma00090
    FOR ALL ENTRIES IN @lt_po
    WHERE ebeln = @lt_po-ebeln
      AND ebelp = @lt_po-ebelp
      AND bwart = '101'
    INTO TABLE @DATA(lt_gr).

  LOOP AT lt_gr INTO DATA(ls_gr).
    COLLECT VALUE ty_rcv( ebeln = ls_gr-ebeln ebelp = ls_gr-ebelp menge = ls_gr-menge ) INTO lt_rcv.
  ENDLOOP.

  " 3) 미입고 건만 gt_list로
  CLEAR gt_list.
  LOOP AT lt_po ASSIGNING FIELD-SYMBOL(<ls_po>).
    CHECK <ls_po>-eindt IS NOT INITIAL.
    CLEAR lv_rcv.
    READ TABLE lt_rcv ASSIGNING FIELD-SYMBOL(<ls_rcv>)
         WITH TABLE KEY ebeln = <ls_po>-ebeln ebelp = <ls_po>-ebelp.
    IF sy-subrc = 0.
      lv_rcv = <ls_rcv>-menge.
    ENDIF.
    CHECK lv_rcv < <ls_po>-menge.
    APPEND VALUE #( ebeln = <ls_po>-ebeln ebelp = <ls_po>-ebelp
                    matnr = <ls_po>-matnr matkl = <ls_po>-matkl
                    lifnr = <ls_po>-lifnr name1 = <ls_po>-name1
                    eindt = <ls_po>-eindt ) TO gt_list.
  ENDLOOP.
ENDFORM.

*--- Exception 열: 미결 RISK Exception이 실제로 있는지 ----------------------*
FORM set_exflg.
  SELECT srnum, sritm FROM ztexa00010
    WHERE srtyp = 'RISK' AND prsta <> 'CLSD' AND prsta <> 'RJCT'
    INTO TABLE @DATA(lt_ex).

  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<ls_list>).
    <ls_list>-exflg = COND #( WHEN line_exists( lt_ex[ srnum = <ls_list>-ebeln
                                                       sritm = <ls_list>-ebelp ] )
                              THEN '있음' ELSE '-' ).
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form  build_toolbar_exclude
*&---------------------------------------------------------------------*
FORM build_toolbar_exclude CHANGING ct_exclude TYPE ui_functions.

  CLEAR ct_exclude.

  " 편집 계열
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row       TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row       TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row       TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row         TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy             TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut              TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste            TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row    TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo             TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_move_row         TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_check                TO ct_exclude.

  " 기본 상세/새로고침/인쇄 (우리 프로그램 자체 버튼 사용)
  APPEND cl_gui_alv_grid=>mc_fc_detail               TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_refresh              TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_print                TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_print_back           TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_print_prev           TO ct_exclude.

  " 집계·찾기 계열
  APPEND cl_gui_alv_grid=>mc_fc_sum                  TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_subtot               TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_average              TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_minimum              TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_maximum              TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_find                 TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_find_more            TO ct_exclude.

  " 그래픽·정보·뷰·연계
  APPEND cl_gui_alv_grid=>mc_fc_graph                TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_info                 TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_views                TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_view_grid            TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_view_excel           TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_view_lotus           TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_view_crystal         TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_html                 TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_to_office            TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_to_rep_tree          TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_send                 TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_word_processor       TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_call_abc             TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_call_xxl             TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_call_crbatch         TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_call_crweb           TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_call_lineitems       TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_call_master_data     TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_expcrdata            TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_expcrdesig           TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_reprep               TO ct_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_back_classic         TO ct_exclude.

ENDFORM.

FORM refresh_stat_0200.
  DATA lv_ok TYPE abap_bool.

  PERFORM check_spmon CHANGING lv_ok.
  IF lv_ok = abap_true.
    PERFORM build_stat.
  ELSE.
    CLEAR gt_stat.                                 " 잘못된 월이면 이전 결과를 비움
  ENDIF.
ENDFORM.

FORM check_spmon CHANGING cv_ok TYPE abap_bool.
  cv_ok = abap_false.

  IF gv_spmon IS INITIAL OR strlen( gv_spmon ) <> 6 OR gv_spmon CN '0123456789'.
    MESSAGE s022 WITH TEXT-s02 DISPLAY LIKE 'E'.   " 집계 기준월의 입력값이 올바르지 않습니다
    RETURN.
  ENDIF.
  IF gv_spmon+4(2) < '01' OR gv_spmon+4(2) > '12'.
    MESSAGE s022 WITH TEXT-s02 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  cv_ok = abap_true.
ENDFORM.
