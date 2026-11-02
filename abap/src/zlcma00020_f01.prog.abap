*&---------------------------------------------------------------------*
*& Include          ZLCMA00020_F01
*&---------------------------------------------------------------------*
*--- SCR 1000 --------------------------------------------------------*
FORM init_selection.
  sscrfields-functxt_01 = VALUE smp_dyntxt( icon_id   = icon_refresh
                                            icon_text = '초기화'
                                            quickinfo = '조회조건 초기화' ).
ENDFORM.

FORM check_selection.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.                               " [초기화]
      CLEAR: s_lifnr, s_lifnr[], s_name1, s_name1[], p_land1, p_y, p_n.
      p_all = 'X'.
      RETURN.
  ENDCASE.

  " 공급업체번호 From > To 는 SELECT-OPTIONS 표준 체크가 처리
  IF p_land1 IS NOT INITIAL.
    SELECT SINGLE @abap_true FROM t005
      WHERE land1 = @p_land1
      INTO @DATA(lv_exist).
    IF sy-subrc <> 0.
      MESSAGE e034 WITH p_land1.
    ENDIF.
  ENDIF.
ENDFORM.

FORM f4_lifnr USING iv_field TYPE dynfnam.
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

*--- 조회 ------------------------------------------------------------*
FORM select_data.
  DATA: lr_land1 TYPE RANGE OF ztcma00010-land1,
        lr_trdyn TYPE RANGE OF ztcma00010-trdyn.
  DATA: lv_zttxt TYPE ztfia00080-zttxt.

  IF p_land1 IS NOT INITIAL.
    lr_land1 = VALUE #( ( sign = 'I' option = 'EQ' low = p_land1 ) ).
  ENDIF.
  CASE 'X'.
    WHEN p_y. lr_trdyn = VALUE #( ( sign = 'I' option = 'EQ' low = 'Y' ) ).
    WHEN p_n. lr_trdyn = VALUE #( ( sign = 'I' option = 'EQ' low = 'N' ) ).
  ENDCASE.

  " 업체명 부분 조회: 와일드카드가 없는 단일 값은 *값* 으로 변환
  DATA(lr_name) = s_name1[].
  LOOP AT lr_name ASSIGNING FIELD-SYMBOL(<ls_name>)
       WHERE option = 'EQ' AND low IS NOT INITIAL AND low NA '*'.
    <ls_name>-option = 'CP'.
    <ls_name>-low    = |*{ <ls_name>-low }*|.
  ENDLOOP.

  " 거래가능(Y) 먼저, 거래불가(N)는 뒤 / 같은 그룹 안에서는 번호순
  SELECT lifnr, name1, land1, regio, telf1, zterm, trdyn, inrsn, erdat
    FROM ztcma00010
    WHERE lifnr IN @s_lifnr
      AND name1 IN @lr_name
      AND land1 IN @lr_land1
      AND trdyn IN @lr_trdyn
    ORDER BY trdyn DESCENDING, lifnr ASCENDING
    INTO CORRESPONDING FIELDS OF TABLE @gt_vendor.

  LOOP AT gt_vendor ASSIGNING FIELD-SYMBOL(<ls_vendor>).
    " 국가 텍스트 (현재 언어 → 영어 → 코드 그대로)
    SELECT SINGLE landx FROM t005t
      WHERE spras = @sy-langu AND land1 = @<ls_vendor>-land1
      INTO @<ls_vendor>-land_txt.
    IF sy-subrc <> 0.
      SELECT SINGLE landx FROM t005t
        WHERE spras = 'E' AND land1 = @<ls_vendor>-land1
        INTO @<ls_vendor>-land_txt.
      IF sy-subrc <> 0.
        <ls_vendor>-land_txt = <ls_vendor>-land1.
      ENDIF.
    ENDIF.

    " 지역 텍스트 (현재 언어 → 영어 → 코드 그대로)
    SELECT SINGLE bezei FROM t005u
      WHERE spras = @sy-langu AND land1 = @<ls_vendor>-land1
        AND bland = @<ls_vendor>-regio
      INTO @<ls_vendor>-regio_txt.
    IF sy-subrc <> 0.
      SELECT SINGLE bezei FROM t005u
        WHERE spras = 'E' AND land1 = @<ls_vendor>-land1
          AND bland = @<ls_vendor>-regio
        INTO @<ls_vendor>-regio_txt.
      IF sy-subrc <> 0.
        <ls_vendor>-regio_txt = <ls_vendor>-regio.
      ENDIF.
    ENDIF.

    " 지급조건 텍스트 (ZTFIA00080 = 상세 화면 검증·F4와 같은 출처)
    CLEAR lv_zttxt.
    SELECT SINGLE zttxt FROM ztfia00080
      WHERE zterm = @<ls_vendor>-zterm
      INTO @lv_zttxt.
    IF sy-subrc = 0 AND lv_zttxt IS NOT INITIAL.
      <ls_vendor>-zterm_txt = lv_zttxt.
    ELSE.
      <ls_vendor>-zterm_txt = <ls_vendor>-zterm.
    ENDIF.

    IF <ls_vendor>-trdyn = 'N'.
      <ls_vendor>-rowcolor = 'C200'.             " 회색
    ENDIF.
  ENDLOOP.

  gv_kpi_dirty = abap_true.
ENDFORM.

*--- SCR 0100 ALV ----------------------------------------------------*
FORM build_fcat.
  CLEAR gt_fcat.
  PERFORM add_fcat USING 'LIFNR'     '공급업체번호'  'X'.
  PERFORM add_fcat USING 'NAME1'     '공급업체명'    ' '.
  PERFORM add_fcat USING 'LAND_TXT'  '국가'          ' '.
  PERFORM add_fcat USING 'REGIO_TXT' '지역'          ' '.
  PERFORM add_fcat USING 'TELF1'     '연락처'        ' '.
  PERFORM add_fcat USING 'ZTERM_TXT' '지급조건'      ' '.
  PERFORM add_fcat USING 'TRDYN'     '거래가능'      ' '.
  PERFORM add_fcat USING 'INRSN'     '거래불가 사유' ' '.
  PERFORM add_fcat USING 'ERDAT'     '등록일'        ' '.
  LOOP AT gt_fcat ASSIGNING FIELD-SYMBOL(<fc>).
    <fc>-outputlen = SWITCH #( <fc>-fieldname
      WHEN 'LIFNR'     THEN 14
      WHEN 'NAME1'     THEN 16
      WHEN 'LAND_TXT'  THEN 10
      WHEN 'REGIO_TXT' THEN 14
      WHEN 'TELF1'     THEN 16
      WHEN 'ZTERM_TXT' THEN 18
      WHEN 'TRDYN'     THEN 9
      WHEN 'INRSN'     THEN 24
      WHEN 'ERDAT'     THEN 10
      ELSE <fc>-outputlen ).
  ENDLOOP.
ENDFORM.

FORM add_fcat USING iv_field   TYPE lvc_fname
                    iv_text    TYPE lvc_txtcol
                    iv_hotspot TYPE c.
  APPEND VALUE #( fieldname = iv_field
                  ref_table = 'ZTCMA00010'
                  ref_field = iv_field
                  coltext   = iv_text
                  scrtext_m = iv_text
                  hotspot   = iv_hotspot
                  key       = COND #( WHEN iv_field = 'LIFNR' THEN 'X' ) )
    TO gt_fcat.
ENDFORM.

FORM free_alv.
  IF go_kpi IS BOUND.
    go_kpi->free( ).
  ENDIF.
  IF go_cont_kpi IS BOUND.
    go_cont_kpi->free( ).
  ENDIF.
  FREE: go_kpi, go_cont_kpi.
  IF go_container IS BOUND.
    go_container->free( ).
  ENDIF.
  FREE: go_grid, go_container, go_handler.
ENDFORM.

FORM change_selected.
  DATA lt_rows TYPE lvc_t_row.

  go_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
  IF lt_rows IS INITIAL.
    MESSAGE s014 DISPLAY LIKE 'E'.           " 처리할 데이터를 선택해 주십시오
    RETURN.
  ELSEIF lines( lt_rows ) > 1.
    MESSAGE s016 DISPLAY LIKE 'E'.           " 하나의 데이터만 선택해 주십시오
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
  READ TABLE gt_vendor INTO DATA(ls_vendor) INDEX ls_row-index.
  IF sy-subrc <> 0.
    MESSAGE s014 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM open_detail USING gc_mode_change ls_vendor-lifnr.
ENDFORM.

FORM delete_selected.
  DATA: lt_rows   TYPE lvc_t_row,
        lv_answer TYPE c,
        lv_cnt    TYPE i,
        ls_vendor TYPE ty_vendor.
*        lv_has_po TYPE abap_bool,
*        lv_has_ap TYPE abap_bool.

  go_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
  IF lt_rows IS INITIAL.
    MESSAGE s014 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " TODO(테이블 활성화 후 주석 해제): 거래 이력 체크 — 필드명은 테이블 기술서 확인
*  LOOP AT lt_rows INTO DATA(ls_row).
*    READ TABLE gt_vendor INTO ls_vendor INDEX ls_row-index.
*    CLEAR: lv_has_po, lv_has_ap.
*    SELECT SINGLE @abap_true FROM ztmma00050          " PO 헤더
*      WHERE lifnr = @ls_vendor-lifnr INTO @lv_has_po.
*    SELECT SINGLE @abap_true FROM ztcma00110          " AP
*      WHERE lifnr = @ls_vendor-lifnr INTO @lv_has_ap.
*    IF lv_has_po = abap_true OR lv_has_ap = abap_true.
*      MESSAGE s052 DISPLAY LIKE 'E'.
*      RETURN.
*    ENDIF.
*  ENDLOOP.

  MESSAGE i013 INTO DATA(lv_q).
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '삭제 확인'
      text_question         = lv_q
      text_button_1         = '삭제'
      text_button_2         = '취소'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      OTHERS                = 1.
  CHECK lv_answer = '1'.

  LOOP AT lt_rows INTO DATA(ls_del).
    READ TABLE gt_vendor INTO ls_vendor INDEX ls_del-index.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    DELETE FROM ztcma00010 WHERE lifnr = @ls_vendor-lifnr.
    DATA(lv_subrc) = sy-subrc.                 " ROLLBACK 전에 값을 보관
    IF lv_subrc <> 0.
      ROLLBACK WORK.
      IF lv_subrc = 4.
        MESSAGE s045 DISPLAY LIKE 'E'.         " 이미 삭제된 데이터입니다
      ELSE.
        MESSAGE s062 DISPLAY LIKE 'E'.         " 데이터를 삭제하는 중 오류가 발생했습니다
      ENDIF.
      RETURN.
    ENDIF.
    lv_cnt = lv_cnt + 1.
  ENDLOOP.

  COMMIT WORK.
  MESSAGE s073 WITH lv_cnt.
  PERFORM select_data.
ENDFORM.

*--- SCR 0200 --------------------------------------------------------*
FORM open_detail USING iv_mode  TYPE c
                       iv_lifnr TYPE ztcma00010-lifnr.
  " ★ 변경 모드면 먼저 잠금
  IF iv_mode = gc_mode_change.
    CALL FUNCTION 'ENQUEUE_EZ_ZTCMA00010'
      EXPORTING
        mode_ztcma00010 = 'E'
        mandt           = sy-mandt
        lifnr           = iv_lifnr
      EXCEPTIONS
        foreign_lock    = 1
        system_failure  = 2
        OTHERS          = 3.
    IF sy-subrc = 1.
      MESSAGE |{ iv_lifnr }: { sy-msgv1 } 사용자가 수정 중입니다.| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ELSEIF sy-subrc <> 0.
      MESSAGE s087 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
  ENDIF.
  gv_mode = iv_mode.
  CLEAR gs_0200.

  IF iv_mode = gc_mode_create.
    gs_0200-trdyn = 'Y'.
  ELSE.
    SELECT SINGLE * FROM ztcma00010
      WHERE lifnr = @iv_lifnr
      INTO @gs_0200.
    " TODO(FM): 변경 모드면 ENQUEUE (Lock Object) 추가
  ENDIF.

  gv_rb_y = xsdbool( gs_0200-trdyn <> 'N' ).
  gv_rb_n = xsdbool( gs_0200-trdyn =  'N' ).
  gs_0200_org = gs_0200.

  CALL SCREEN 0200.

  " ★ 0200에서 돌아오면 잠금 해제 (저장·취소 모두)
  IF iv_mode = gc_mode_change.
    CALL FUNCTION 'DEQUEUE_EZ_ZTCMA00010'
      EXPORTING
        mode_ztcma00010 = 'E'
        mandt           = sy-mandt
        lifnr           = iv_lifnr.
  ENDIF.

  PERFORM select_data.                         " 돌아오면 목록 재조회
ENDFORM.

FORM close_detail.
  DATA lv_answer TYPE c.

  IF gv_mode <> gc_mode_display AND gs_0200 <> gs_0200_org.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = TEXT-p02
        text_question         = '저장하지 않은 변경 내용이 있습니다. 닫으시겠습니까?'
        display_cancel_button = space
      IMPORTING
        answer                = lv_answer
      EXCEPTIONS
        OTHERS                = 1.
    CHECK lv_answer = '1'.
  ENDIF.

  LEAVE TO SCREEN 0.
ENDFORM.

FORM save_vendor.
  DATA: lv_ok  TYPE abap_bool,
        lv_num TYPE i.

  PERFORM validate_0200 CHANGING lv_ok.
  CHECK lv_ok = abap_true.

  IF gv_mode = gc_mode_create.
    " TODO(FM): 채번 FM(SNRO)으로 교체 — 번호범위 객체명은 A6에서 확정
    " [임시] MAX + 1
    SELECT MAX( lifnr ) FROM ztcma00010 INTO @DATA(lv_max).
    lv_num = COND #( WHEN lv_max IS INITIAL THEN 1
                     ELSE CONV i( lv_max+1(9) ) + 1 ).
    gs_0200-lifnr = |V{ lv_num WIDTH = 9 ALIGN = RIGHT PAD = '0' }|.

    gs_0200-ernam = sy-uname.
    gs_0200-erdat = sy-datum.
    gs_0200-erzet = sy-uzeit.
    INSERT ztcma00010 FROM @gs_0200.
  ELSE.
    gs_0200-aenam = sy-uname.
    gs_0200-aedat = sy-datum.
    gs_0200-aezet = sy-uzeit.
    UPDATE ztcma00010 FROM @gs_0200.
  ENDIF.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    IF gv_mode = gc_mode_create.
      MESSAGE s060 DISPLAY LIKE 'E'.
    ELSE.
      MESSAGE s061 DISPLAY LIKE 'E'.
    ENDIF.
    RETURN.
  ENDIF.

  COMMIT WORK.
  IF gv_mode = gc_mode_create.
    MESSAGE s002.
  ELSE.
    MESSAGE s003.
  ENDIF.
  LEAVE TO SCREEN 0.
ENDFORM.

FORM validate_0200 CHANGING cv_ok TYPE abap_bool.
  cv_ok = abap_false.

  " 필수값
  IF gs_0200-name1 IS INITIAL OR gs_0200-stcd1 IS INITIAL
  OR gs_0200-land1 IS INITIAL OR gs_0200-regio IS INITIAL
  OR gs_0200-adrnr IS INITIAL OR gs_0200-telf1 IS INITIAL
  OR gs_0200-smtp_addr IS INITIAL OR gs_0200-zterm IS INITIAL.
    MESSAGE s030 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 사업자번호 숫자 10자리
  DATA(lv_stcd1) = CONV string( gs_0200-stcd1 ).
  IF strlen( lv_stcd1 ) <> 10 OR lv_stcd1 CN '0123456789'.
    MESSAGE s023 WITH TEXT-f01 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 사업자번호 중복
  SELECT SINGLE lifnr FROM ztcma00010
    WHERE stcd1 = @gs_0200-stcd1
      AND lifnr <> @gs_0200-lifnr
    INTO @DATA(lv_dup).
  IF sy-subrc = 0.
    MESSAGE s032 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 국가 + 지역 조합
  SELECT SINGLE @abap_true FROM t005s
    WHERE land1 = @gs_0200-land1
      AND bland = @gs_0200-regio
    INTO @DATA(lv_region_ok).
  IF sy-subrc <> 0.
    MESSAGE s022 WITH TEXT-f02 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 이메일 검증을 NS '@' 대신 (소문자 정규화 포함)
  TRANSLATE gs_0200-smtp_addr TO LOWER CASE.
  IF NOT matches( val = gs_0200-smtp_addr
                  regex = '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$' ).
    MESSAGE s023 WITH TEXT-f03 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 지급조건 — ZTFIA00080 기준 (사용중인 값만 허용)
  SELECT SINGLE @abap_true FROM ztfia00080
    WHERE zterm = @gs_0200-zterm
      AND actyn = 'Y'
    INTO @DATA(lv_zterm_ok).
  IF sy-subrc <> 0.
    MESSAGE s034 WITH gs_0200-zterm DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 거래불가 사유
  IF gs_0200-trdyn = 'N' AND gs_0200-inrsn IS INITIAL.
    MESSAGE s020 WITH TEXT-f04 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  cv_ok = abap_true.
ENDFORM.

FORM f4_zterm.
  TYPES: BEGIN OF ty_f4,
           zterm TYPE ztfia00080-zterm,
           zttxt TYPE ztfia00080-zttxt,
         END OF ty_f4.
  DATA lt_f4 TYPE STANDARD TABLE OF ty_f4.

  SELECT zterm, zttxt FROM ztfia00080
    WHERE actyn = 'Y'                  " 사용중인 지급조건만
    ORDER BY zterm
    INTO TABLE @lt_f4.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield    = 'ZTERM'
              dynpprog    = sy-repid
              dynpnr      = sy-dynnr
              dynprofield = 'GS_0200-ZTERM'
              value_org   = 'S'
    TABLES    value_tab   = lt_f4
    EXCEPTIONS OTHERS     = 1.
ENDFORM.
FORM f4_land1.
  TYPES: BEGIN OF ty_f4,
           land1 TYPE t005t-land1,
           landx TYPE t005t-landx,
         END OF ty_f4.
  DATA lt_f4 TYPE STANDARD TABLE OF ty_f4.

  SELECT land1, landx FROM t005t
    WHERE spras = @sy-langu
    ORDER BY land1
    INTO TABLE @lt_f4.
  IF lt_f4 IS INITIAL.                      " 로그인 언어 텍스트가 없으면 영어
    SELECT land1, landx FROM t005t
      WHERE spras = 'E'
      ORDER BY land1
      INTO TABLE @lt_f4.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'LAND1' dynpprog = sy-repid dynpnr = sy-dynnr
              dynprofield = 'GS_0200-LAND1' value_org = 'S'
    TABLES    value_tab = lt_f4
    EXCEPTIONS OTHERS = 1.
ENDFORM.

FORM f4_regio.
  TYPES: BEGIN OF ty_f4,
           bland TYPE t005u-bland,
           bezei TYPE t005u-bezei,
         END OF ty_f4.
  DATA: lt_f4    TYPE STANDARD TABLE OF ty_f4,
        lt_dynp  TYPE STANDARD TABLE OF dynpread,
        lv_land1 TYPE t005u-land1.

  " F4 시점엔 아직 PAI 전이라 화면의 국가 값을 직접 읽는다
  lt_dynp = VALUE #( ( fieldname = 'GS_0200-LAND1' ) ).
  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING dyname = sy-repid dynumb = sy-dynnr
    TABLES    dynpfields = lt_dynp
    EXCEPTIONS OTHERS = 1.
  READ TABLE lt_dynp INTO DATA(ls_dynp) INDEX 1.
  lv_land1 = to_upper( ls_dynp-fieldvalue ).

  IF lv_land1 IS INITIAL.
    " TODO: ZMSGA 공용 메시지로 교체 (임시 문구)
    MESSAGE '국가를 먼저 입력하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SELECT bland, bezei FROM t005u
    WHERE spras = @sy-langu AND land1 = @lv_land1
    ORDER BY bland
    INTO TABLE @lt_f4.
  IF lt_f4 IS INITIAL.
    SELECT bland, bezei FROM t005u
      WHERE spras = 'E' AND land1 = @lv_land1
      ORDER BY bland
      INTO TABLE @lt_f4.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'BLAND' dynpprog = sy-repid dynpnr = sy-dynnr
              dynprofield = 'GS_0200-REGIO' value_org = 'S'
    TABLES    value_tab = lt_f4
    EXCEPTIONS OTHERS = 1.
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
  SELECT COUNT(*)                                       AS total,
         SUM( CASE WHEN trdyn = 'N' THEN 1 ELSE 0 END ) AS stop,
         SUM( CASE WHEN zterm = ' '  THEN 1 ELSE 0 END ) AS noterm
    FROM ztcma00010
    INTO @DATA(ls_cnt).

  DATA(lv_total)  = ls_cnt-total.
  DATA(lv_stop)   = ls_cnt-stop.
  DATA(lv_noterm) = ls_cnt-noterm.

  DATA(lv_ok)  = lv_total - lv_stop.
  DATA(lv_pct) = COND i( WHEN lv_total > 0 THEN lv_ok * 100 / lv_total ELSE 0 ).

  " ① 차트 종류 : 'D' 도넛 / 'B' 막대  (이 한 글자만 바꾸면 됨)
  CONSTANTS lc_chart TYPE zcl_cm_kpi_html=>ty_ctype VALUE 'D'.

  " ② 패널 : 추가하려면 아래에 ( label = ... ) 줄만 더 넣으면 화면에 순서대로 생김
  DATA(lt_card) = VALUE zcl_cm_kpi_html=>tt_card(
    ( label = '전체 업체'  value = |{ lv_total }곳|  sub = '공급업체 Master 기준' color = 'B' )
    ( label = '거래 가능'       value = |{ lv_ok }곳|     sub = '거래가능여부 = Y'      color = 'G' )
    ( label = '지급조건 미입력' value = |{ lv_noterm }곳| sub = '지급기한 산정 불가'
      color = COND #( WHEN lv_noterm > 0 THEN 'Y' ELSE 'G' ) ) ).

  " ③ 차트에 들어갈 값
  DATA(lt_item) = VALUE zcl_cm_kpi_html=>tt_item(
    ( label = '거래 가능' value = lv_ok   color = 'G' )
    ( label = '거래 불가' value = lv_stop color = 'R' ) ).

  go_kpi->show_summary(
    iv_title = '공급업체 Master'
    iv_chart_type   = lc_chart
    iv_chart_title  = '거래가능 비율'
    it_chart_item   = lt_item
    iv_chart_center = |{ lv_pct }%|
    it_card         = lt_card
    iv_foot = '※ 조회 조건과 무관하게 전체 업체 기준' ).
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
FORM f4_land1_sel CHANGING pv_land TYPE any.
  DATA: lt_ret TYPE STANDARD TABLE OF ddshretval,
        ls_ret TYPE ddshretval.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname           = 'T005'
      fieldname         = 'LAND1'
      searchhelp        = 'H_T005'
      dynpprog          = sy-repid
      dynpnr            = sy-dynnr
      dynprofield       = 'P_LAND1'
    TABLES
      return_tab        = lt_ret
    EXCEPTIONS
      OTHERS            = 1.
  IF sy-subrc = 0.
    READ TABLE lt_ret INTO ls_ret INDEX 1.
    IF sy-subrc = 0.
      pv_land = ls_ret-fieldval.
    ENDIF.
  ENDIF.
ENDFORM.
