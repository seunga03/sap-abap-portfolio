*&---------------------------------------------------------------------*
*& Include          ZRFIA00010_F01
*&---------------------------------------------------------------------*


*--- SCR 1000 --------------------------------------------------------*
FORM init_selection.
  sscrfields-functxt_01 = VALUE smp_dyntxt( icon_id   = icon_refresh
                                            icon_text = '초기화' ).
  PERFORM default_clrdt.
*  PERFORM default_variant.
ENDFORM.

FORM default_clrdt.                               " 당월 1일 ~ 오늘
  CLEAR: s_clrdt, s_clrdt[].
  s_clrdt-sign   = 'I'.
  s_clrdt-option = 'BT'.
  s_clrdt-low    = sy-datum.
  s_clrdt-low+6(2) = '01'.
  s_clrdt-high   = sy-datum.
  APPEND s_clrdt.
ENDFORM.

FORM modify_selection.
   LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'KUN'.
        IF p_ap = 'X'. screen-input = 0. ENDIF.
      WHEN 'LIF'.
        IF p_ar = 'X'. screen-input = 0. ENDIF.
      WHEN 'DTL'.
        screen-active = COND #( WHEN gv_dtl_open = abap_true THEN 1 ELSE 0 ).
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

  btn_dtl = COND #( WHEN gv_dtl_open = abap_true THEN TEXT-b02    " - 상세조건 닫기
                                                 ELSE TEXT-b01 ). " + 상세조건 열기
ENDFORM.

FORM check_selection.
  CASE sscrfields-ucomm.
    WHEN 'TGDT'.                                    " [상세조건 열기/닫기]
      gv_dtl_open = xsdbool( gv_dtl_open = abap_false ).
      RETURN.

    WHEN 'FC01'.                                    " [초기화]
      CLEAR: s_lifnr, s_lifnr[], s_kunnr, s_kunnr[], s_clrnr, s_clrnr[],
             s_orgnr, s_orgnr[], p_ar, p_all, p_q_op, p_q_al.
      p_ap = p_q_np = p_adj = 'X'.
      p_waers = 'KRW'.
      gv_dtl_open = abap_false.
      PERFORM default_clrdt.
      RETURN.
  ENDCASE.

  " 반제일 필수(OBLIGATORY) · From > To 는 표준 체크
  "IF sscrfields-ucomm = 'ONLI'.
  DATA lv_ex TYPE abap_bool.
  IF p_waers IS NOT INITIAL.
    SELECT SINGLE @abap_true FROM tcurc WHERE waers = @p_waers INTO @lv_ex.
    IF sy-subrc <> 0. MESSAGE e034 WITH p_waers. ENDIF.
  ENDIF.
  IF s_lifnr[] IS NOT INITIAL AND p_ar IS INITIAL.
    SELECT SINGLE @abap_true FROM ztcma00010 WHERE lifnr IN @s_lifnr INTO @lv_ex.
    IF sy-subrc <> 0. MESSAGE e034 WITH TEXT-f01. ENDIF.   " 공급업체
  ENDIF.
  IF s_kunnr[] IS NOT INITIAL AND p_ap IS INITIAL.
    SELECT SINGLE @abap_true FROM ztcma00050 WHERE kunnr IN @s_kunnr INTO @lv_ex.
    IF sy-subrc <> 0. MESSAGE e034 WITH TEXT-f02. ENDIF.   " 고객

ENDIF.
ENDFORM.

*--- 조회 ------------------------------------------------------------*
FORM select_data.
  CLEAR gt_list.
  PERFORM select_data_ap.     " 조회 대상·기간·번호·통화·조정 조건은 각 FORM의 WHERE에서 처리
  PERFORM select_data_ar.
  PERFORM set_pr_cnt.
  PERFORM map_rsn_text.

  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<ls_list>).
    PERFORM set_display CHANGING <ls_list>.        " ★ 잔액(OPENAM) 계산이 먼저
  ENDLOOP.

  " ★ 빠른 조회 (잔액 계산 다음에 적용)
  CASE 'X'.
    WHEN p_q_np. DELETE gt_list WHERE pr_cnt > 0.   " 확인서 미출력
    WHEN p_q_op. DELETE gt_list WHERE openam <= 0.  " 잔액 남은 건
  ENDCASE.

  SORT gt_list BY clrdt DESCENDING clrnr clrsq.
  gv_kpi_dirty = abap_true.
ENDFORM.

FORM set_display CHANGING cs_list TYPE ty_list.
  cs_list-openam   = cs_list-dmbtr - cs_list-cumam.        " ★ 헤더 기준 잔액
  cs_list-stat_nm  = COND #( WHEN cs_list-openam > 0 THEN '부분반제'
                             ELSE '반제완료' ).             " ★ 잔액으로 판정
  cs_list-pr_icon  = COND #( WHEN cs_list-pr_cnt > 0 THEN icon_led_green
                             ELSE icon_led_inactive ).
  cs_list-rowcolor = COND #( WHEN cs_list-pr_cnt > 0 THEN 'C500'   " 출력 완료 = 초록
                             ELSE 'C300' ).
ENDFORM.

*--- SCR 0100 ALV ----------------------------------------------------*
FORM build_fcat_0100.
  gt_fcat_0100 = VALUE #(
    ( fieldname = 'SEL'      coltext = '선택'      checkbox = 'X' edit = 'X' )
    ( fieldname = 'PR_ICON'  coltext = '출력'      icon = 'X' )
    ( fieldname = 'DCTYP'    coltext = '구분' )
    ( fieldname = 'CLRNR'    coltext = '반제번호' )
    ( fieldname = 'CLRSQ'    coltext = '순번' )
    ( fieldname = 'ORGNR'    coltext = '원천번호'  hotspot = 'X' )
    ( fieldname = 'PARTN'    coltext = '거래처' )
    ( fieldname = 'PARTN_NM' coltext = '거래처명' )
    ( fieldname = 'DMBTR'    coltext = '원금액'    cfieldname = 'WAERS' )
    ( fieldname = 'CLRAM'    coltext = '반제액'    cfieldname = 'WAERS' do_sum = 'X' )
    ( fieldname = 'OPENAM'   coltext = '잔액'      cfieldname = 'WAERS' )
    ( fieldname = 'CLRDT'    coltext = '반제일' )
    ( fieldname = 'WAERS'    coltext = '통화' )
    ( fieldname = 'RSN_NM'   coltext = '반제사유' )
    ( fieldname = 'PAYNR'    coltext = '지급/수금번호' hotspot = 'X' )
    ( fieldname = 'STAT_NM'  coltext = '상태' )
    ( fieldname = 'PR_CNT'   coltext = '출력횟수' ) ).
ENDFORM.

FORM free_alv_0100.
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
  FREE: go_grid_0100, go_cont_0100, go_handler.
ENDFORM.

FORM select_all USING iv_ucomm TYPE sy-ucomm.
  DATA(lv_sel) = COND char1( WHEN iv_ucomm = 'SALL' THEN 'X' ELSE space ).
  MODIFY gt_list FROM VALUE #( sel = lv_sel ) TRANSPORTING sel WHERE sel <> lv_sel.
ENDFORM.

FORM get_selected CHANGING ct_clrnr TYPE tt_clrnr.
  go_grid_0100->check_changed_data( ).           " 체크박스 값 반영
  ct_clrnr = VALUE #( FOR ls IN gt_list WHERE ( sel = 'X' ) ( ls-clrnr ) ).
  SORT ct_clrnr BY table_line.
  DELETE ADJACENT DUPLICATES FROM ct_clrnr COMPARING table_line.
  ENDFORM.

*--- 상세 (0200) -----------------------------------------------------*
FORM detail_selected.
  go_grid_0100->check_changed_data( ).
  DATA(lv_selcnt) = REDUCE i( INIT n = 0 FOR ls IN gt_list WHERE ( sel = 'X' ) NEXT n = n + 1 ).
  IF lv_selcnt = 0.
    MESSAGE s014 DISPLAY LIKE 'E'.   " 선택 없음
    RETURN.
  ELSEIF lv_selcnt > 1.
    MESSAGE s016 DISPLAY LIKE 'E'.   " 하나만 선택
    RETURN.
  ENDIF.
  DATA(lv_idx) = line_index( gt_list[ sel = 'X' ] ).
  PERFORM open_detail USING lv_idx.
ENDFORM.

FORM open_detail USING iv_index TYPE i.
  READ TABLE gt_list INTO gs_0200 INDEX iv_index.
  CHECK sy-subrc = 0.
  CALL SCREEN 0200 STARTING AT 10 3 ENDING AT 130 25.
ENDFORM.

*--- 출력 ------------------------------------------------------------*
FORM print_docs USING iv_preview TYPE abap_bool.
  DATA lt_clrnr TYPE tt_clrnr.
  PERFORM get_selected CHANGING lt_clrnr.
  IF lt_clrnr IS INITIAL.
    MESSAGE s014 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  PERFORM do_print USING lt_clrnr iv_preview.
ENDFORM.

FORM print_one USING iv_clrnr TYPE ty_list-clrnr iv_preview TYPE abap_bool.
  DATA(lt_clrnr) = VALUE tt_clrnr( ( iv_clrnr ) ).
  PERFORM do_print USING lt_clrnr iv_preview.
ENDFORM.

FORM do_print USING it_clrnr TYPE tt_clrnr iv_preview TYPE abap_bool.
  DATA lv_answer TYPE c.

  IF iv_preview = abap_true.
    " 선택한 문서 전체를 한 번에 미리보기 (이력 기록 안 함)
    DATA: lv_fm TYPE rs38l_fnam,
          lv_ok TYPE abap_bool.
    PERFORM ssf_open_session USING abap_true CHANGING lv_fm lv_ok.
    CHECK lv_ok = abap_true.
    LOOP AT it_clrnr INTO DATA(lv_clrnr).
      READ TABLE gt_list INTO DATA(ls_prev) WITH KEY clrnr = lv_clrnr.
      CHECK sy-subrc = 0.
      PERFORM ssf_call_doc USING lv_fm ls_prev CHANGING lv_ok.
    ENDLOOP.
    PERFORM ssf_close_session CHANGING lv_ok.
    RETURN.
  ENDIF.

  " 재출력 건수 안내 (설계 V-11) — 문서(반제번호) 기준
  DATA(lv_reprint) = 0.
  LOOP AT it_clrnr INTO DATA(lv_c).
    LOOP AT gt_list TRANSPORTING NO FIELDS WHERE clrnr = lv_c AND pr_cnt > 0.
      lv_reprint += 1.
      EXIT.                                 " 같은 문서의 다른 행은 세지 않음
    ENDLOOP.
  ENDLOOP.
  MESSAGE i009 INTO DATA(lv_text).                 " 선택한 데이터를 처리하시겠습니까?
  lv_text = |{ lv_text } ({ lines( it_clrnr ) }건)|.
  IF lv_reprint > 0.
    DATA(lv_note) = CONV string( TEXT-p02 ).
    REPLACE '&1' IN lv_note WITH |{ lv_reprint }|.
    lv_text = |{ lv_text } { lv_note }|.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = TEXT-p01
      text_question         = lv_text
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      OTHERS                = 1.
  IF lv_answer <> '1'.
    MESSAGE s005.
    RETURN.
  ENDIF.

    " ── 선택 문서를 SmartForm 1회 세션으로 출력 (성공 건만 이력 저장) ──
  DATA: lt_done TYPE tt_clrnr,
        lv_pok  TYPE abap_bool,
        lv_fail TYPE i,
        lv_pfm  TYPE rs38l_fnam,
        lv_sok  TYPE abap_bool.

  PERFORM ssf_open_session USING abap_false CHANGING lv_pfm lv_sok.
  CHECK lv_sok = abap_true.                 " 취소·오류면 출력·이력 없이 종료

  LOOP AT it_clrnr INTO DATA(lv_cn).
    READ TABLE gt_list INTO DATA(ls_pr) WITH KEY clrnr = lv_cn.
    CHECK sy-subrc = 0.
    CLEAR lv_pok.
    PERFORM ssf_call_doc USING lv_pfm ls_pr CHANGING lv_pok.
    IF lv_pok = abap_true.
      APPEND lv_cn TO lt_done.
    ELSE.
      lv_fail += 1.
    ENDIF.
  ENDLOOP.

  PERFORM ssf_close_session CHANGING lv_sok.
  CHECK lv_sok = abap_true.                 " 닫기 실패면 스풀 미확정 → 이력 저장 안 함

  IF lt_done IS INITIAL.
    MESSAGE s018 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  DATA lv_hist_ok TYPE abap_bool.
  PERFORM save_print_hist USING lt_done CHANGING lv_hist_ok.   " 내부에서 COMMIT
  CHECK lv_hist_ok = abap_true.

  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<ls_list>).
    CHECK line_exists( lt_done[ table_line = <ls_list>-clrnr ] ).
    <ls_list>-pr_cnt += 1.
    <ls_list>-sel     = space.
    PERFORM set_display CHANGING <ls_list>.
  ENDLOOP.
  gv_kpi_dirty = abap_true.

  DATA(lv_dlike)  = COND char1( WHEN lv_fail > 0 THEN 'W' ELSE 'S' ).
  DATA(lv_okcnt)  = lines( lt_done ).
  MESSAGE s096 WITH lv_okcnt lv_fail DISPLAY LIKE lv_dlike.
ENDFORM.

*--- 출력이력 (0300) -------------------------------------------------*
FORM show_history.
  TYPES: BEGIN OF ty_key,
           dctyp TYPE ztexa00050-dctyp,
           dcnum TYPE ztexa00050-dcnum,
         END OF ty_key.
  DATA: lt_clrnr TYPE tt_clrnr,
        lt_key   TYPE STANDARD TABLE OF ty_key WITH EMPTY KEY.

  PERFORM get_selected CHANGING lt_clrnr.          " check_changed_data 포함
  IF lt_clrnr IS INITIAL.                          " 선택 없으면 조회 전체 기준
    lt_key = VALUE #( FOR ls IN gt_list ( dctyp = ls-dctyp dcnum = ls-clrnr ) ).
  ELSE.
    lt_key = VALUE #( FOR ls IN gt_list WHERE ( sel = 'X' )
                      ( dctyp = ls-dctyp dcnum = ls-clrnr ) ).
  ENDIF.
  SORT lt_key BY dctyp dcnum.
  DELETE ADJACENT DUPLICATES FROM lt_key COMPARING dctyp dcnum.

  CLEAR gt_hist.
  IF lt_key IS NOT INITIAL.
    SELECT prnum, dctyp, dcnum, fmtyp, prtms, uname
      FROM ztexa00050
      FOR ALL ENTRIES IN @lt_key
      WHERE dctyp = @lt_key-dctyp
        AND dcnum = @lt_key-dcnum
      INTO TABLE @DATA(lt_db).
    SORT lt_db BY prtms DESCENDING prnum DESCENDING.

    LOOP AT lt_db INTO DATA(ls_db).
      CONVERT UTCLONG ls_db-prtms TIME ZONE sy-zonlo
              INTO DATE DATA(lv_d) TIME DATA(lv_t).
      APPEND VALUE #( prnum = ls_db-prnum
                      dctyp = |{ ls_db-dctyp }반제|
                      dcnum = ls_db-dcnum
                      fmtyp = SWITCH #( ls_db-fmtyp
                                WHEN 'PAYC' THEN '지급확인서'
                                WHEN 'RCPC' THEN '수금확인서'
                                ELSE ls_db-fmtyp )
                      prtms = |{ lv_d DATE = ISO } { lv_t(2) }:{ lv_t+2(2) }|
                      uname = ls_db-uname ) TO gt_hist.
    ENDLOOP.
  ENDIF.

  IF gt_hist IS INITIAL.
    MESSAGE s040.
    RETURN.
  ENDIF.
  CALL SCREEN 0300 STARTING AT 10 3 ENDING AT 130 30.
ENDFORM.

*FORM f4_variant .
*  DATA: ls_variant TYPE disvariant,
*        lv_exit    TYPE c.
*  ls_variant-report = sy-repid.
*  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
*    EXPORTING
*      is_variant = ls_variant
*      i_save     = 'A'
*    IMPORTING
*      e_exit     = lv_exit
*      es_variant = ls_variant
*    EXCEPTIONS
*      OTHERS     = 1.
*  IF sy-subrc = 0 AND lv_exit IS INITIAL.
*    p_vari = ls_variant-variant.
*  ENDIF.
*
*ENDFORM.

*FORM default_variant ." 기본 레이아웃 불러오기
*  DATA(ls_variant) = VALUE disvariant( report = sy-repid ).
*  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
*    EXPORTING
*      i_save     = 'A'
*    CHANGING
*      cs_variant = ls_variant
*    EXCEPTIONS
*      OTHERS     = 1.
*  IF sy-subrc = 0.
*    p_vari = ls_variant-variant.
*  ENDIF.
*ENDFORM.
*--- SmartForm 세션 열기 (1회) -----------------------------------------*
FORM ssf_open_session USING    iv_preview TYPE abap_bool
                      CHANGING cv_fm      TYPE rs38l_fnam
                               cv_ok      TYPE abap_bool.
  DATA: ls_ctrl TYPE ssfctrlop,
        ls_out  TYPE ssfcompop.
  cv_ok = abap_false.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname = 'ZSF_FI04_CLEAR'
    IMPORTING
      fm_name  = cv_fm
    EXCEPTIONS
      OTHERS   = 1.
  IF sy-subrc <> 0.
    MESSAGE s067 WITH 'SmartForm 조회' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 출력 장치: 사용자 기본값(SU3) → 없으면 LP01
  SELECT SINGLE spld FROM usr01
    WHERE bname = @sy-uname
    INTO @ls_out-tddest.
  IF ls_out-tddest IS INITIAL.
    ls_out-tddest = 'LP01'.
  ENDIF.
  ls_out-tdnewid = abap_true.            " 여러 문서를 스풀 1개로

  ls_ctrl-preview   = iv_preview.
  ls_ctrl-no_dialog = iv_preview.        " 미리보기는 대화상자 없음, 출력은 1회만 표시

  CALL FUNCTION 'SSF_OPEN'
    EXPORTING
      user_settings      = space
      output_options     = ls_out
      control_parameters = ls_ctrl
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.
  CASE sy-subrc.
    WHEN 0.
      cv_ok = abap_true.
    WHEN 4.
      MESSAGE s005.                      " 사용자가 취소
    WHEN OTHERS.
      MESSAGE s067 WITH 'SmartForm 출력' DISPLAY LIKE 'E'.
  ENDCASE.
ENDFORM.

*--- 문서 1건 호출 (세션은 열린 상태 유지) ------------------------------*
FORM ssf_call_doc USING    iv_fm   TYPE rs38l_fnam
                           is_list TYPE ty_list
                  CHANGING cv_ok   TYPE abap_bool.
  DATA ls_ctrl TYPE ssfctrlop.
  cv_ok = abap_false.
  ls_ctrl-no_open  = abap_true.
  ls_ctrl-no_close = abap_true.

  CALL FUNCTION iv_fm
    EXPORTING
      control_parameters = ls_ctrl
      user_settings      = space
      iv_dctyp           = is_list-dctyp
      iv_clrnr           = is_list-clrnr
      iv_orgnr           = is_list-orgnr
      iv_partn           = is_list-partn
      iv_partn_nm        = is_list-partn_nm
      iv_dmbtr           = is_list-dmbtr
      iv_clram           = is_list-clram
      iv_waers           = is_list-waers
      iv_clrdt           = is_list-clrdt
      iv_paynr           = is_list-paynr
      iv_rsn_nm          = is_list-rsn_nm
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.
  cv_ok = xsdbool( sy-subrc = 0 ).
ENDFORM.

*--- SmartForm 세션 닫기 (1회, 미리보기는 이때 화면에 뜸) ----------------*
FORM ssf_close_session CHANGING cv_ok TYPE abap_bool.
  cv_ok = abap_false.
  CALL FUNCTION 'SSF_CLOSE'
    EXCEPTIONS
      formatting_error = 1
      internal_error   = 2
      send_error       = 3
      OTHERS           = 4.
  IF sy-subrc = 0.
    cv_ok = abap_true.
  ELSE.
    MESSAGE s067 WITH 'SmartForm 출력' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*FORM call_smartform USING is_list    TYPE ty_list
*                          iv_preview TYPE abap_bool
*                    CHANGING cv_ok   TYPE abap_bool.
*  DATA: lv_fm   TYPE rs38l_fnam,
*        ls_ctrl TYPE ssfctrlop,
*        ls_out  TYPE ssfcompop.
*
*  cv_ok = abap_false.
*
*  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
*    EXPORTING
*      formname = 'ZSF_FI04_CLEAR'
*    IMPORTING
*      fm_name  = lv_fm
*    EXCEPTIONS
*      OTHERS   = 1.
*  IF sy-subrc <> 0.
*    MESSAGE s067 WITH 'SmartForm 조회' DISPLAY LIKE 'E'.
*    RETURN.
*  ENDIF.
*
*   출력 장치: 사용자 기본값(SU3) → 없으면 LP01
*  SELECT SINGLE spld FROM usr01
*    WHERE bname = @sy-uname
*    INTO @ls_out-tddest.
*  IF ls_out-tddest IS INITIAL.
*    ls_out-tddest = 'LP01'.
*  ENDIF.
*
*  ls_ctrl-preview   = iv_preview.
*  ls_ctrl-no_dialog = iv_preview.
*  CALL FUNCTION lv_fm
*    EXPORTING
*      control_parameters = ls_ctrl
*      output_options     = ls_out
*      user_settings      = space
*      iv_dctyp           = is_list-dctyp
*      iv_clrnr           = is_list-clrnr
*      iv_orgnr           = is_list-orgnr
*      iv_partn           = is_list-partn
*      iv_partn_nm        = is_list-partn_nm
*      iv_dmbtr           = is_list-dmbtr
*      iv_clram           = is_list-clram
*      iv_waers           = is_list-waers
*      iv_clrdt           = is_list-clrdt
*      iv_paynr           = is_list-paynr
*      iv_rsn_nm          = is_list-rsn_nm
*    EXCEPTIONS
*      formatting_error   = 1
*      internal_error     = 2
*      send_error         = 3
*      user_canceled      = 4
*      OTHERS             = 5.
*
*  DATA(lv_rc) = sy-subrc.
*  CASE lv_rc.
*    WHEN 0.
*    WHEN 4.
*      MESSAGE s005.                                " 사용자가 취소
*    WHEN OTHERS.
*      IF sy-msgid IS NOT INITIAL.
*        MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
*      ELSE.
*        MESSAGE s067 WITH 'SmartForm 출력' DISPLAY LIKE 'E'.
*      ENDIF.
*  ENDCASE.
*  cv_ok = xsdbool( lv_rc = 0 ).
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_lifnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&---------------------------------------------------------------------*
FORM f4_lifnr  USING    iv_field TYPE dynfnam.
  TYPES: BEGIN OF ty_f4,
           lifnr TYPE ztcma00010-lifnr,
           name1 TYPE ztcma00010-name1,
         END OF ty_f4.
  DATA lt_f4 TYPE STANDARD TABLE OF ty_f4.

  SELECT lifnr, name1 FROM ztcma00010
    ORDER BY lifnr
    INTO TABLE @lt_f4.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'LIFNR'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = iv_field
      value_org   = 'S'
    TABLES
      value_tab   = lt_f4
    EXCEPTIONS
      OTHERS      = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_kpi_0100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM show_kpi_0100.
  DATA: lv_printed TYPE i,
        lv_part    TYPE i,
        lv_clram   TYPE wrbtr,
        lv_open    TYPE wrbtr.

  LOOP AT gt_list INTO DATA(ls_l).
    IF ls_l-pr_cnt > 0.
      lv_printed = lv_printed + 1.
    ENDIF.
    " 금액은 선택한 통화 기준으로만 합산 (통화가 섞이면 합계가 틀려지므로)
    IF ls_l-waers = p_waers.
      lv_clram = lv_clram + ls_l-clram.
      IF ls_l-stat_nm = '부분반제'.
        lv_part = lv_part + 1.
        lv_open = lv_open + ls_l-openam.
      ENDIF.
    ENDIF.
  ENDLOOP.

  DATA(lv_total) = lines( gt_list ).
  DATA(lv_unprt) = lv_total - lv_printed.
  DATA(lv_pct)   = COND i( WHEN lv_total > 0 THEN lv_printed * 100 / lv_total ELSE 0 ).

  " 차트 종류 : 'D' 도넛 / 'B' 막대
  CONSTANTS lc_chart TYPE c LENGTH 1 VALUE 'D'.

  DATA(lt_card) = VALUE zcl_cm_kpi_html=>tt_card(
    ( label = '반제 내역'     value = |{ lv_total }건|
      sub = '조회 조건 기준'   color = 'B' )
    ( label = '반제액 합계'   value = |{ lv_clram CURRENCY = p_waers NUMBER = USER }|
      sub = |{ p_waers } 기준| color = 'G' )
    ( label = '부분반제 잔액' value = |{ lv_open CURRENCY = p_waers NUMBER = USER }|
      sub = |부분반제 { lv_part }건|
      color = COND #( WHEN lv_part > 0 THEN 'Y' ELSE 'G' ) )
    ( label = '미출력'        value = |{ lv_unprt }건|
      sub = '확인서 출력 필요'
      color = COND #( WHEN lv_unprt > 0 THEN 'Y' ELSE 'G' ) ) ).

  DATA(lt_item) = VALUE zcl_cm_kpi_html=>tt_item(
    ( label = '출력 완료' value = lv_printed color = 'G' )
    ( label = '미출력'    value = lv_unprt   color = 'Y' ) ).

  go_kpi->show_summary(
    iv_title = '반제 조회'
    iv_chart_type   = lc_chart
    iv_chart_title  = '출력 현황'
    it_chart_item   = lt_item
    iv_chart_center = |{ lv_pct }%|
    it_card         = lt_card
    iv_foot         = '※ 조회 조건에 맞는 목록 기준 (가운데 숫자 = 출력률)' ).

ENDFORM.

FORM fmt_amt USING iv_amt TYPE wrbtr iv_waers TYPE waers CHANGING cv_txt TYPE string.
  DATA lv_c TYPE c LENGTH 25.
  WRITE iv_amt TO lv_c CURRENCY iv_waers.
  cv_txt = condense( |{ lv_c } { iv_waers }| ).
ENDFORM.

*--- AP 반제 조회 (DB) --------------------------------------------------*
FORM select_data_ap.
  CHECK p_ap = 'X' OR p_all = 'X'.

  " 통화·조정 조건을 range로 만들어 WHERE에서 처리
  DATA: lr_waers TYPE RANGE OF ztfia00030-waers,
        lr_paynr TYPE RANGE OF ztfia00030-paynr.
  IF p_waers IS NOT INITIAL.
    lr_waers = VALUE #( ( sign = 'I' option = 'EQ' low = p_waers ) ).
  ENDIF.
  IF p_adj IS INITIAL.                 " 조정 건 제외 = 지급번호가 있는 건만
    lr_paynr = VALUE #( ( sign = 'I' option = 'NE' low = space ) ).
  ENDIF.

  SELECT a~apcnr, a~apcsq, a~apnum, a~lifnr, a~apcam, a~apcdt, a~waers,
         a~aprsn, a~paynr,
         h~dmbtr, h~paybt, h~adjbt,
         v~name1
    FROM ztfia00030 AS a
    INNER JOIN ztcma00110 AS h ON h~apnum = a~apnum
    LEFT OUTER JOIN ztcma00010 AS v ON v~lifnr = a~lifnr
    WHERE a~apcdt IN @s_clrdt
      AND a~lifnr IN @s_lifnr
      AND a~apcnr IN @s_clrnr
      AND a~apnum IN @s_orgnr
      AND a~waers IN @lr_waers
      AND a~paynr IN @lr_paynr
    INTO TABLE @DATA(lt_ap).

  " (아래 LOOP 부분은 기존과 동일, 마지막 줄의 TODO 주석만 삭제)
ENDFORM.

*--- AR 반제 조회 (DB) --------------------------------------------------*
FORM select_data_ar.
  CHECK p_ar = 'X' OR p_all = 'X'.

  SELECT a~arcnr, a~arcsq, a~arnum, a~kunnr, a~arcam, a~arcdt, a~waers,
         a~arrsn, a~rcpnr,
         h~dmbtr, h~rcpbt, h~adjbt,
         c~name1
    FROM ztfia00040 AS a
    INNER JOIN ztcma00100 AS h ON h~arnum = a~arnum
    LEFT OUTER JOIN ztcma00050 AS c ON c~kunnr = a~kunnr
    WHERE a~arcdt IN @s_clrdt
      AND a~kunnr IN @s_kunnr
      AND a~arcnr IN @s_clrnr
      AND a~arnum IN @s_orgnr
    INTO TABLE @DATA(lt_ar).

  IF p_waers IS NOT INITIAL.
    DELETE lt_ar WHERE waers <> p_waers.
  ENDIF.

  LOOP AT lt_ar INTO DATA(ls_ar).
    APPEND VALUE ty_list(
        dctyp    = 'AR'
        clrnr    = ls_ar-arcnr
        clrsq    = ls_ar-arcsq
        orgnr    = ls_ar-arnum
        partn    = ls_ar-kunnr
        partn_nm = ls_ar-name1
        dmbtr    = ls_ar-dmbtr
        clram    = ls_ar-arcam
        cumam    = ls_ar-rcpbt + ls_ar-adjbt
        clrdt    = ls_ar-arcdt
        waers    = ls_ar-waers
        paynr    = COND #( WHEN ls_ar-rcpnr IS INITIAL THEN '(조정)'
                           ELSE ls_ar-rcpnr )
        rsn_nm   = ls_ar-arrsn )          " TODO: 코드 → 텍스트 (도메인 값 확인 후)
      TO gt_list.
  ENDLOOP.
ENDFORM.

*--- 출력횟수 (ZTEXA00050) ---------------------------------------------*
FORM set_pr_cnt.
  CHECK gt_list IS NOT INITIAL.        " FAE 빈 테이블 가드 (필수)

  TYPES: BEGIN OF ty_pr,
           dctyp TYPE ztexa00050-dctyp,
           dcnum TYPE ztexa00050-dcnum,
           cnt   TYPE i,
         END OF ty_pr.
  DATA: lt_key TYPE STANDARD TABLE OF ty_pr WITH EMPTY KEY,
        lt_pr  TYPE SORTED TABLE OF ty_pr WITH UNIQUE KEY dctyp dcnum.

  lt_key = VALUE #( FOR g IN gt_list ( dctyp = g-dctyp dcnum = g-clrnr ) ).
  SORT lt_key BY dctyp dcnum.
  DELETE ADJACENT DUPLICATES FROM lt_key COMPARING dctyp dcnum.

    SELECT prnum, dctyp, dcnum
    FROM ztexa00050
    FOR ALL ENTRIES IN @lt_key
    WHERE dctyp = @lt_key-dctyp
      AND dcnum = @lt_key-dcnum
    INTO TABLE @DATA(lt_hist).

  LOOP AT lt_hist INTO DATA(ls_hist).
    COLLECT VALUE ty_pr( dctyp = ls_hist-dctyp dcnum = ls_hist-dcnum cnt = 1 ) INTO lt_pr.
  ENDLOOP.

  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<ls_pr>).
    READ TABLE lt_pr INTO DATA(ls_pr)
         WITH TABLE KEY dctyp = <ls_pr>-dctyp dcnum = <ls_pr>-clrnr.
    IF sy-subrc = 0.
      <ls_pr>-pr_cnt = ls_pr-cnt.
    ENDIF.
  ENDLOOP.
ENDFORM.

*--- 출력이력 저장 (ZTEXA00050) -----------------------------------------*
FORM save_print_hist USING it_clrnr TYPE tt_clrnr
                     CHANGING cv_ok TYPE abap_bool.
  DATA: lt_prn TYPE STANDARD TABLE OF ztexa00050,
        lv_seq TYPE n LENGTH 8.
  cv_ok = abap_false.

  " 다음 출력번호: PR + 8자리 (현재 최대값 + 1)
  SELECT MAX( prnum ) FROM ztexa00050 INTO @DATA(lv_maxnum).
  IF lv_maxnum IS NOT INITIAL AND lv_maxnum(2) = 'PR'.
    lv_seq = lv_maxnum+2(8).
  ENDIF.

  DATA(lv_ts) = utclong_current( ).

  LOOP AT it_clrnr INTO DATA(lv_clrnr).
    READ TABLE gt_list INTO DATA(ls_l) WITH KEY clrnr = lv_clrnr.
    CHECK sy-subrc = 0.
    lv_seq = lv_seq + 1.
    APPEND VALUE ztexa00050(
        prnum = |PR{ lv_seq }|
        dctyp = ls_l-dctyp                         " AP / AR
        dcnum = lv_clrnr                           " 반제번호
        prtms = lv_ts
        uname = sy-uname
        fmtyp = COND #( WHEN ls_l-dctyp = 'AP' THEN 'PAYC'   " 지급확인서
                        ELSE 'RCPC' )                        " 수금확인서
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit ) TO lt_prn.
  ENDLOOP.

 TRY.
      INSERT ztexa00050 FROM TABLE @lt_prn.
    CATCH cx_sy_open_sql_db.
      sy-subrc = 4.                               " 중복 키 등 DB 예외도 같은 처리
  ENDTRY.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE s060 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  COMMIT WORK.
  cv_ok = abap_true.
ENDFORM.

FORM map_rsn_text.
  SELECT cdgrp, cdval, cdnam FROM ztcma00080
    WHERE cdgrp IN ('APRSN','ARRSN')
      AND actyn = 'Y'
    INTO TABLE @DATA(lt_cd).

  LOOP AT gt_list ASSIGNING FIELD-SYMBOL(<l>).
    READ TABLE lt_cd INTO DATA(ls_cd)
      WITH KEY cdgrp = COND #( WHEN <l>-dctyp = 'AP' THEN 'APRSN' ELSE 'ARRSN' )
               cdval = <l>-rsn_nm.
    IF sy-subrc = 0.
      <l>-rsn_nm = ls_cd-cdnam.
    ENDIF.
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
