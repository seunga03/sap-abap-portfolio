*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_object  - 위/아래 ALV (컨테이너 1개를 위아래로 나눔)
*&---------------------------------------------------------------------*
FORM create_object .
  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'CON_AREA_REG'.

  CREATE OBJECT go_split
    EXPORTING
      parent  = go_cont
      rows    = 2
      columns = 1.
  go_split->set_row_height( id = 1 height = 55 ).
  go_top    = go_split->get_container( row = 1 column = 1 ).
  go_bottom = go_split->get_container( row = 2 column = 1 ).

  CREATE OBJECT go_alv1 EXPORTING i_parent = go_top.
  CREATE OBJECT go_alv2 EXPORTING i_parent = go_bottom.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler  - 아래 지급액 고치면 바로 재계산 / ALV 툴바 버튼
*&---------------------------------------------------------------------*
FORM set_evt_handler .
  go_alv2->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_modified ).
  go_alv2->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_enter ).

  SET HANDLER: lcl_handler=>on_data_changed_finished FOR go_alv2,
               lcl_handler=>on_toolbar               FOR go_alv1,     " [지급 목록에 추가]
               lcl_handler=>on_toolbar               FOR go_alv2,     " [목록에서 제외]
               lcl_handler=>on_user_command          FOR go_alv1,
               lcl_handler=>on_user_command          FOR go_alv2,
               lcl_handler=>on_user_command          FOR go_alv2,
               lcl_handler=>on_hotspot_click         FOR go_alv1.     " 자물쇠 · 송장번호 클릭
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout
*&---------------------------------------------------------------------*
FORM set_alv_layout .
  DATA ls_sort TYPE lvc_s_sort.

  CLEAR: gs_layout1, gs_layout2, gt_sort2, gt_exclude.

  PERFORM exclude_toolbar CHANGING gt_exclude.

  "─ 상단: 지급 대상 채무
  gs_layout1-stylefname = 'CELLTAB'.              " 셀 스타일 (현재 미사용)
  gs_layout1-zebra      = 'X'.
  gs_layout1-info_fname = 'ROWCOL'.               " 행 색 (연체 빨강 / 7일 이내 주황)
  gs_layout1-sel_mode   = 'A'.                    " 왼쪽 행 선택 버튼 (Ctrl·Shift로 여러 행)

  "─ 하단: 지급 목록
  gs_layout2-stylefname = 'CELLTAB'.              " 지급 끝난 행 지급액 잠금
  gs_layout2-sel_mode   = 'A'.                    " [목록에서 제외]용 행 선택
  gs_layout2-zebra      = 'X'.
*  gs_layout2-no_toolbar = 'X'.                    " 툴바에 [목록에서 제외] 버튼을 달아서 사용 (표준 버튼은 display_alv에서 전부 숨김)

  " 공급업체 순 정렬 (소계·합계는 [공급업체별 합계] 버튼으로)
  ls_sort-spos      = 1.
  ls_sort-fieldname = 'LIFNR'.
  ls_sort-up        = 'X'.
*  ls_sort-subtot    = 'X'.                        " 자동 공급업체별 소계 (사용 안 함)
  APPEND ls_sort TO gt_sort2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog  (정렬: 글자 왼쪽 / 금액 오른쪽 / 날짜·통화·아이콘 가운데)
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  DATA ls TYPE lvc_s_fcat.

  CLEAR: gt_fcat1, gt_fcat2.

  "─ 상단: 지급 대상 채무
  "  홀드 → 지급기한 → 기한 → 채무번호 → 공급업체명 → 잔액 → 통화 → 채무금액 → 지급누계 → 조정누계 → 송장번호 → 공급업체
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name   = 'ZSFIA00020'
      i_bypassing_buffer = 'X'
    CHANGING
      ct_fieldcat        = gt_fcat1.

  LOOP AT gt_fcat1 INTO ls.
    CASE ls-fieldname.
      WHEN 'SEL'.
*        ls-col_pos = 1.  ls-coltext = '선택'.  ls-checkbox = 'X'.      " 조 통일: 체크박스 대신 왼쪽 행 선택
*        ls-edit = 'X'.   ls-outputlen = 2.
        ls-no_out = 'X'.
      WHEN 'DUEDT'.   ls-col_pos = 2.  ls-coltext = '지급기한'.   ls-outputlen = 7.  ls-just = 'C'.
      WHEN 'APNUM'.   ls-col_pos = 4.  ls-coltext = '채무번호'.   ls-outputlen = 7.
      WHEN 'NAME1'.   ls-col_pos = 5.  ls-coltext = '공급업체명'. ls-outputlen = 7.
      WHEN 'OPENBAL'. ls-col_pos = 6.  ls-coltext = '잔액'.       ls-outputlen = 8.  ls-emphasize = 'C300'.
      WHEN 'WAERS'.   ls-col_pos = 7.  ls-coltext = '통화'.       ls-outputlen = 2.  ls-just = 'C'.
      WHEN 'DMBTR'.   ls-col_pos = 8.  ls-coltext = '채무금액'.   ls-outputlen = 7.
      WHEN 'RCPBT'.   ls-col_pos = 9.  ls-coltext = '지급누계'.   ls-outputlen = 8.  ls-no_zero = 'X'.
      WHEN 'IVNUM'.   ls-col_pos = 11. ls-coltext = '송장번호'.   ls-outputlen = 7.  ls-hotspot = 'X'.
      WHEN 'LIFNR'.   ls-col_pos = 12. ls-coltext = '공급업체'.   ls-outputlen = 7.
      WHEN OTHERS.    ls-no_out = 'X'.            " 구조에 남아 있는 안 쓰는 필드 숨김
    ENDCASE.
    MODIFY gt_fcat1 FROM ls.
  ENDLOOP.

  CLEAR ls.
  ls-fieldname = 'HDICO'.
  ls-col_pos   = 1.
  ls-coltext   = '홀드'.
  ls-icon      = 'X'.
  ls-hotspot   = 'X'.                             " 누르면 홀드 사유
  ls-just      = 'C'.
  ls-outputlen = 2.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'DDTXT'.  ls-col_pos = 3.  ls-coltext = '기한'.
  ls-inttype = 'C'.  ls-intlen = 10.  ls-outputlen = 5.  ls-just = 'C'.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname  = 'ADJBT'.
  ls-col_pos    = 10.
  ls-coltext    = '조정누계'.
  ls-ref_table  = 'ZTCMA00110'.
  ls-ref_field  = 'ADJBT'.
  ls-cfieldname = 'WAERS'.
  ls-no_zero    = 'X'.
  ls-outputlen  = 8.
  APPEND ls TO gt_fcat1.

  "─ 하단: 지급 목록
  "  결과 → 공급업체 → 공급업체명 → 채무번호 → 지급액 → 지급 전 잔액 → 지급 후 잔액 → 통화
  "  → 지급상태 → 지급번호 → 처리 결과 → 채무금액 → 송장번호
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name   = 'ZSFIA00011'
      i_bypassing_buffer = 'X'
    CHANGING
      ct_fieldcat        = gt_fcat2.

  LOOP AT gt_fcat2 INTO ls.
    CASE ls-fieldname.
      WHEN 'APNUM'.   ls-col_pos = 4.  ls-coltext = '채무번호'.     ls-outputlen = 7.
      WHEN 'APCAM'.
        ls-col_pos = 5.  ls-coltext = '지급액'.       ls-outputlen = 8.
        ls-edit = 'X'.  ls-emphasize = 'C300'.
*        ls-do_sum = 'X'.                          " 자동 총합계 (사용 안 함 → [공급업체별 합계] 버튼으로)
      WHEN 'OPENBAL'. ls-col_pos = 7.  ls-coltext = '지급 후 잔액'. ls-outputlen = 8.
      WHEN 'WAERS'.   ls-col_pos = 8.  ls-coltext = '통화'.         ls-outputlen = 2.  ls-just = 'C'.
      WHEN 'PAYNR'.   ls-col_pos = 10. ls-coltext = '지급번호'.     ls-outputlen = 7.
      WHEN 'DMBTR'.   ls-col_pos = 12. ls-coltext = '채무금액'.     ls-outputlen = 8.
      WHEN OTHERS.    ls-no_out = 'X'.            " CLSTA(코드값)는 숨기고 STTXT(글자)로 표시
    ENDCASE.
    MODIFY gt_fcat2 FROM ls.
  ENDLOOP.

  CLEAR ls.
  ls-fieldname = 'STICO'.  ls-col_pos = 1.  ls-coltext = '결과'.
  ls-icon = 'X'.  ls-just = 'C'.  ls-outputlen = 2.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'LIFNR'.  ls-col_pos = 2.  ls-coltext = '공급업체'.
  ls-ref_table = 'ZTCMA00110'.  ls-ref_field = 'LIFNR'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'NAME1'.  ls-col_pos = 3.  ls-coltext = '공급업체명'.
  ls-ref_table = 'ZTCMA00010'.  ls-ref_field = 'NAME1'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname  = 'BALBF'.  ls-col_pos = 6.  ls-coltext = '지급 전 잔액'.
  ls-ref_table  = 'ZTCMA00110'.  ls-ref_field = 'DMBTR'.  ls-outputlen = 8.
  ls-cfieldname = 'WAERS'.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'STTXT'.  ls-col_pos = 9.  ls-coltext = '지급상태'.
  ls-inttype = 'C'.  ls-intlen = 10.  ls-outputlen = 5.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'MSG'.  ls-col_pos = 13.  ls-coltext = '처리 결과'.      " 문장이 길어서 맨 뒤
  ls-inttype = 'C'.  ls-intlen = 60.  ls-outputlen = 15.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'IVNUM'.  ls-col_pos = 11.  ls-coltext = '송장번호'.
  ls-ref_table = 'ZTCMA00110'.  ls-ref_field = 'IVNUM'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
FORM display_alv .
  DATA lt_excl2 TYPE ui_functions.                " 아래: 표준 버튼 전부 숨김 → [목록에서 제외]만

  APPEND cl_gui_alv_grid=>mc_fc_excl_all TO lt_excl2.

*── 상단: 지급 대상 채무
  CALL METHOD go_alv1->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout1
      it_toolbar_excluding          = gt_exclude
    CHANGING
      it_outtab                     = gt_apreg
      it_fieldcatalog               = gt_fcat1
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a067(zmsga) WITH '화면 표시'.         " 화면 표시 처리 중 오류가 발생했습니다
  ENDIF.

*── 하단: 지급 목록
  CALL METHOD go_alv2->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout2
      it_toolbar_excluding          = lt_excl2
    CHANGING
      it_outtab                     = gt_pay
      it_fieldcatalog               = gt_fcat2
      it_sort                       = gt_sort2
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a067(zmsga) WITH '화면 표시'.         " 화면 표시 처리 중 오류가 발생했습니다
  ENDIF.

  go_alv1->set_toolbar_interactive( ).            " 툴바에 [지급 목록에 추가] 반영
  go_alv2->set_toolbar_interactive( ).            " 툴바에 [목록에서 제외] 반영

  PERFORM refresh_alv1.
  PERFORM refresh_alv2.                           " 처음 제목 '지급 목록 (0건)'
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_search  - [조회]
*&---------------------------------------------------------------------*
FORM process_search .
  DATA lv_cnt TYPE i.

  IF p_open IS INITIAL AND p_part IS INITIAL AND p_done IS INITIAL.
    MESSAGE s401(zmsga) WITH '지급상태' DISPLAY LIKE 'E'.      " 지급상태을(를) 하나 이상 선택해 주십시오.
    RETURN.
  ENDIF.

  PERFORM get_data.
  PERFORM refresh_alv1.

  lv_cnt = lines( gt_apreg ).
  MESSAGE s055(zmsga) WITH lv_cnt.                           " 처리 대상 n건을 조회했습니다
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data  - AP + 홀드 확인 (아래에 담긴 건 제외)
*&---------------------------------------------------------------------*
FORM get_data .
  TYPES: BEGIN OF lty_name,
           lifnr TYPE ztcma00010-lifnr,
           name1 TYPE ztcma00010-name1,
         END OF lty_name.
  DATA: lr_clsta TYPE RANGE OF ztcma00110-clsta,
        ls_clsta LIKE LINE OF lr_clsta,
        lt_ap    TYPE TABLE OF ztcma00110,
        ls_ap    TYPE ztcma00110,
        lt_name  TYPE SORTED TABLE OF lty_name WITH UNIQUE KEY lifnr,
        ls_name  TYPE lty_name,
        ls_style TYPE lvc_s_styl,
        lv_tdtyp TYPE ztexa00030-tdtyp VALUE 'AP',
        lv_tdnum TYPE ztexa00030-tdnum,
        lv_held  TYPE abap_bool,
        lv_hdnum TYPE ztexa00030-hdnum,
        lr_lifnr TYPE RANGE OF ztcma00110-lifnr,
        ls_lifnr LIKE LINE OF lr_lifnr.

  CLEAR gt_apreg.

  ls_clsta-sign   = 'I'.
  ls_clsta-option = 'EQ'.
  IF p_open = 'X'.
    ls_clsta-low = gc_clsta_open.
    APPEND ls_clsta TO lr_clsta.
  ENDIF.
  IF p_part = 'X'.
    ls_clsta-low = gc_clsta_part.
    APPEND ls_clsta TO lr_clsta.
  ENDIF.
  IF p_done = 'X'.
    ls_clsta-low = gc_clsta_done.
    APPEND ls_clsta TO lr_clsta.
  ENDIF.
  CHECK lr_clsta IS NOT INITIAL.                  " 하나도 체크 안 하면 조회 안 함 (비면 전부 나옴)

  IF p_lifnr IS NOT INITIAL.
    ls_lifnr-sign   = 'I'.
    ls_lifnr-option = 'EQ'.
    ls_lifnr-low    = p_lifnr.
    APPEND ls_lifnr TO lr_lifnr.
  ENDIF.

  SELECT * FROM ztcma00110 INTO TABLE lt_ap
    WHERE lifnr IN lr_lifnr
      AND duedt IN s_duedt
      AND clsta IN lr_clsta.
  SORT lt_ap BY duedt lifnr apnum.

  " 공급업체명 한 번에 (루프 안 SELECT 없음)
  IF lt_ap IS NOT INITIAL.
    SELECT lifnr name1 FROM ztcma00010 INTO TABLE lt_name
      FOR ALL ENTRIES IN lt_ap
      WHERE lifnr = lt_ap-lifnr.
  ENDIF.

  LOOP AT lt_ap INTO ls_ap.
    " 아래 '지급 목록'에 담겨 있고 아직 지급 전이면 위에서는 제외
    READ TABLE gt_pay TRANSPORTING NO FIELDS
         WITH KEY apnum = ls_ap-apnum paynr = space.
    CHECK sy-subrc <> 0.

    CLEAR gw_apreg.
    MOVE-CORRESPONDING ls_ap TO gw_apreg.         " lifnr apnum ivnum duedt dmbtr waers adjbt
    gw_apreg-rcpbt   = ls_ap-paybt.               " 지급누계
    gw_apreg-openbal = ls_ap-dmbtr - ls_ap-paybt - ls_ap-adjbt.

    " 기한 글자·행 색 (잔액 남은 건만)
    IF gw_apreg-openbal > 0.
      PERFORM due_text USING    gw_apreg-duedt
                       CHANGING gw_apreg-ddtxt gw_apreg-rowcol.
    ENDIF.

    READ TABLE lt_name INTO ls_name WITH TABLE KEY lifnr = ls_ap-lifnr.
    IF sy-subrc = 0.
      gw_apreg-name1 = ls_name-name1.
    ENDIF.

    " 유진 홀드 확인
    lv_tdnum = ls_ap-apnum.
    CLEAR: lv_held, lv_hdnum.
    CALL FUNCTION 'ZCM_HOLD_CHECK'
      EXPORTING
        iv_tdtyp = lv_tdtyp
        iv_tdnum = lv_tdnum
      IMPORTING
        ev_held  = lv_held
        ev_hdnum = lv_hdnum.

    " 홀드·잔액 없는 채무는 체크 못 하게 잠금
    IF lv_held = abap_true OR gw_apreg-openbal <= 0.
      IF lv_held = abap_true.
        gw_apreg-hdico = icon_locked.
      ENDIF.
*      CLEAR ls_style.
*      ls_style-fieldname = 'SEL'.          " 체크박스 잠금 (체크박스 사용 안 함)
*      ls_style-style     = cl_gui_alv_grid=>mc_style_disabled.
*      INSERT ls_style INTO TABLE gw_apreg-celltab.
    ENDIF.

    APPEND gw_apreg TO gt_apreg.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form due_text  - 기한 글자 + 행 색 (00110 만기 구간과 같은 기준)
*&   기한 지남 → '연체 n일' 빨강 / 오늘~7일 → '오늘'·'D-n' 주황 / 그 뒤 → 'D-n'
*&---------------------------------------------------------------------*
FORM due_text USING    pv_duedt  TYPE d
              CHANGING pv_ddtxt  TYPE c
                       pv_rowcol TYPE c.
  CONSTANTS: lc_soon TYPE i VALUE 7,                  " 임박 기준 (일)
             lc_red  TYPE c LENGTH 4 VALUE 'C600',    " 연체
             lc_org  TYPE c LENGTH 4 VALUE 'C700'.    " 7일 이내
  DATA: lv_days TYPE i,
        lv_abs  TYPE i.

  CLEAR: pv_ddtxt, pv_rowcol.
  CHECK pv_duedt IS NOT INITIAL.

  lv_days = pv_duedt - sy-datum.                      " 남은 일수 (음수 = 연체)
  IF lv_days < 0.
    lv_abs    = abs( lv_days ).
    pv_ddtxt  = |연체 { lv_abs }일|.
    pv_rowcol = lc_red.
  ELSEIF lv_days = 0.
    pv_ddtxt  = '오늘'.
    pv_rowcol = lc_org.
  ELSE.
    pv_ddtxt  = |D-{ lv_days }|.
    IF lv_days <= lc_soon.
      pv_rowcol = lc_org.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_add  - [지급 목록에 추가] 채무 목록 선택 행 → 지급 목록으로
*&---------------------------------------------------------------------*
FORM process_add .
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row,
        lv_cnt  TYPE i.

*  go_alv1->check_changed_data( ).              " 체크박스 값 내부 테이블로 (체크박스 사용 안 함)
  go_alv1->get_selected_rows( IMPORTING et_index_rows = lt_rows ).   " 왼쪽 행 선택 버튼으로 고른 행
  IF lt_rows IS INITIAL.
    MESSAGE s402(zmsga) WITH '담을' DISPLAY LIKE 'E'.   " 담을 행을 선택해 주십시오. (왼쪽 행 선택 버튼)
    RETURN.
  ENDIF.

  " 지난 지급 결과(지급번호 있는 행)는 지우고 새로 시작
  DELETE gt_pay WHERE paynr IS NOT INITIAL.

  SORT lt_rows BY index DESCENDING.               " 뒤에서부터 (위 목록에서 행을 지우므로 번호 안 밀리게)
  LOOP AT lt_rows INTO ls_row.
    READ TABLE gt_apreg INTO gw_apreg INDEX ls_row-index.
    CHECK sy-subrc = 0.
    CHECK gw_apreg-hdico IS INITIAL AND gw_apreg-openbal > 0.   " 홀드·지급완료 건은 제외

    CLEAR gw_pay.
    gw_pay-lifnr   = gw_apreg-lifnr.
    gw_pay-name1   = gw_apreg-name1.
    gw_pay-apnum   = gw_apreg-apnum.
    gw_pay-ivnum   = gw_apreg-ivnum.
    gw_pay-dmbtr   = gw_apreg-dmbtr.
    gw_pay-balbf   = gw_apreg-openbal.
    gw_pay-apcam   = gw_apreg-openbal.            " 기본 = 잔액 전액
    gw_pay-openbal = 0.
    gw_pay-waers   = gw_apreg-waers.
    APPEND gw_pay TO gt_pay.

    DELETE gt_apreg INDEX ls_row-index.           " 담은 채무는 위 목록에서 뺌
    lv_cnt = lv_cnt + 1.
  ENDLOOP.

  IF lv_cnt = 0.
    MESSAGE s403(zmsga) DISPLAY LIKE 'E'.         " 홀드·지급완료 건만 골랐을 때
    RETURN.
  ENDIF.

*  DELETE gt_apreg WHERE sel = 'X' AND hdico IS INITIAL AND openbal > 0.   " 체크박스 방식 (위 LOOP에서 행 단위로 삭제)
  SORT gt_pay BY lifnr apnum.

  PERFORM refresh_alv1.
  PERFORM refresh_alv2.

  MESSAGE s405(zmsga) WITH lv_cnt '지급'.    " n건을 지급 목록에 추가했습니다. 지급액은 아래에서 수정할 수 있습니다.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_del  - [목록에서 제외] 지급 목록 선택 행 → 채무 목록으로
*&---------------------------------------------------------------------*
FORM process_del .
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row,
        lv_cnt  TYPE i.

  go_alv2->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
  IF lt_rows IS INITIAL.
    MESSAGE s402(zmsga) WITH '뺄' DISPLAY LIKE 'E'.      " 뺄 행을 선택해 주십시오. (왼쪽 행 선택 버튼)
    RETURN.
  ENDIF.

  SORT lt_rows BY index DESCENDING.               " 뒤에서부터 지워야 번호 안 밀림
  LOOP AT lt_rows INTO ls_row.
    READ TABLE gt_pay INTO gw_pay INDEX ls_row-index.
    CHECK sy-subrc = 0 AND gw_pay-paynr IS INITIAL.   " 지급 끝난 행은 못 뺌
    DELETE gt_pay INDEX ls_row-index.
    lv_cnt = lv_cnt + 1.
  ENDLOOP.

  PERFORM get_data.                               " 뺀 채무가 위에 다시 나오게
  PERFORM refresh_alv1.
  PERFORM refresh_alv2.

  MESSAGE s406(zmsga) WITH lv_cnt '지급'.     " n건을 지급 목록에서 제외했습니다.
ENDFORM.
FORM process_reset .
  DATA: lv_answer TYPE c LENGTH 1,
        lv_cnt    TYPE i.

  " 아래에 담아만 두고 아직 지급 안 한 건이 있으면 확인
  READ TABLE gt_pay TRANSPORTING NO FIELDS WITH KEY paynr = space.
  IF sy-subrc = 0.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = '처음 화면으로'
        text_question         = '미등록 목록이 있습니다. 실행하시겠습니까?'
        text_button_1         = '예'
        text_button_2         = '아니오'
        default_button        = '2'
        display_cancel_button = space
      IMPORTING
        answer                = lv_answer
      EXCEPTIONS
        OTHERS                = 1.
    IF sy-subrc <> 0 OR lv_answer <> '1'.
      MESSAGE s005(zmsga).                        " 처리가 취소되었습니다.
      RETURN.
    ENDIF.
  ENDIF.

  CLEAR: gt_apreg, gt_pay,
         p_lifnr, s_duedt, s_duedt[], p_payac, p_done.
  p_open  = 'X'.
  p_part  = 'X'.
  p_paydt = sy-datum.

  PERFORM get_data.                               " 시작 화면과 같은 기본 조회
  PERFORM refresh_alv1.
  PERFORM refresh_alv2.

  lv_cnt = lines( gt_apreg ).
  MESSAGE s413(zmsga) WITH lv_cnt.                " 최신 상태로 다시 조회했습니다. (n건)
ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_openbal  - 지급 후 잔액 = 지급 전 잔액 - 지급액
*&---------------------------------------------------------------------*
FORM calc_openbal .
  LOOP AT gt_pay INTO gw_pay WHERE paynr IS INITIAL.
    gw_pay-openbal = gw_pay-balbf - gw_pay-apcam.
    MODIFY gt_pay FROM gw_pay.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv1 / refresh_alv2  - 상단 / 하단 제목 + 화면 갱신
*&---------------------------------------------------------------------*
FORM refresh_alv1 .
  DATA ls_stable TYPE lvc_s_stbl.

  go_alv1->set_gridtitle( |채무 목록 ({ lines( gt_apreg ) }건)| ).

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv1->refresh_table_display( is_stable = ls_stable ).
ENDFORM.

FORM refresh_alv2 .
  DATA: ls_stable TYPE lvc_s_stbl,
        lv_title  TYPE lvc_title,
        lv_cnt    TYPE i,
        lv_sum    TYPE ztfia00050-payam,
        lv_amt    TYPE c LENGTH 30,
        lv_waers  TYPE ztfia00050-waers,
        lt_lifnr  TYPE SORTED TABLE OF ztcma00110-lifnr WITH UNIQUE KEY table_line.

  LOOP AT gt_pay INTO gw_pay.
    lv_cnt   = lv_cnt + 1.
    lv_sum   = lv_sum + gw_pay-apcam.
    lv_waers = gw_pay-waers.
    INSERT gw_pay-lifnr INTO TABLE lt_lifnr.
  ENDLOOP.

  IF lv_cnt = 0.
    lv_title = '지급 목록 (0건)'.
  ELSE.
    WRITE lv_sum TO lv_amt CURRENCY lv_waers.
    CONDENSE lv_amt.
    lv_title = |지급 목록 ({ lv_cnt }건) - 공급업체 { lines( lt_lifnr ) }곳 / 합계 { lv_amt } { lv_waers }|.
  ENDIF.
  go_alv2->set_gridtitle( lv_title ).

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv2->refresh_table_display( is_stable = ls_stable ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form status_text  - 지급상태 코드 → 글자 (00010과 같은 말)
*&---------------------------------------------------------------------*
FORM status_text USING    pv_clsta TYPE ztcma00110-clsta
                 CHANGING pv_text  TYPE c.
  CASE pv_clsta.
    WHEN gc_clsta_open. pv_text = '미지급'.
    WHEN gc_clsta_part. pv_text = '부분지급'.
    WHEN gc_clsta_done. pv_text = '지급완료'.
    WHEN OTHERS.        CLEAR pv_text.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_pay  - [지급 등록]
*&---------------------------------------------------------------------*
FORM process_pay .
  DATA: lv_valid  TYPE c LENGTH 1,
        lv_cnt    TYPE i,
        lv_sum    TYPE ztfia00050-payam,
        lv_amt    TYPE c LENGTH 30,
        lv_waers  TYPE ztfia00050-waers,
        lv_text   TYPE string,
        lv_answer TYPE c LENGTH 1,
        lv_bnkac  TYPE ztfia00070-bnkac,
        lt_lifnr  TYPE SORTED TABLE OF ztcma00110-lifnr WITH UNIQUE KEY table_line,
        lv_lifnr  TYPE ztcma00110-lifnr,
        lv_paynr  TYPE ztfia00050-paynr,
        lv_ok     TYPE c LENGTH 1,
        lv_err    TYPE string,
        lv_done   TYPE i,
        lv_fail   TYPE i,
        ls_style  TYPE lvc_s_styl.

  go_alv2->check_changed_data( IMPORTING e_valid = lv_valid ).
  CHECK lv_valid = 'X'.
  PERFORM calc_openbal.

  "─ 1. 검증
  LOOP AT gt_pay INTO gw_pay WHERE paynr IS INITIAL.
    lv_cnt = lv_cnt + 1.
    IF gw_pay-apcam <= 0 OR gw_pay-apcam > gw_pay-balbf.
      MESSAGE s407(zmsga) WITH gw_pay-apnum '지급' DISPLAY LIKE 'E'.   " AP00000001: 지급액은 0보다 크고 지급 전 잔액 이하여야 합니다.
      RETURN.
    ENDIF.
    IF lv_waers IS INITIAL.
      lv_waers = gw_pay-waers.
    ELSEIF lv_waers <> gw_pay-waers.
      MESSAGE s408(zmsga) DISPLAY LIKE 'E'.   " 통화가 다른 건은 한 번에 처리할 수 없습니다.
      RETURN.
    ENDIF.
    lv_sum = lv_sum + gw_pay-apcam.
    INSERT gw_pay-lifnr INTO TABLE lt_lifnr.
  ENDLOOP.

  IF lv_cnt = 0.
    MESSAGE s409(zmsga) WITH '지급' DISPLAY LIKE 'E'.     " 지급 목록이 비어 있습니다. (위 목록에서 체크 → 지급 목록에 추가)
    RETURN.
  ENDIF.
  IF p_paydt IS INITIAL.
    MESSAGE s020(zmsga) WITH '지급일' DISPLAY LIKE 'E'.       " 지급일을(를) 입력해 주십시오.
    RETURN.
  ENDIF.
  IF p_paydt > sy-datum.                                       " 실제 지급 기록 → 미래 날짜 불가
    MESSAGE s434(zmsga) WITH '지급일' DISPLAY LIKE 'E'.       " 지급일은(는) 오늘 이후 날짜로 입력할 수 없습니다.
    RETURN.
  ENDIF.
  SELECT SINGLE bnkac FROM ztfia00070 INTO lv_bnkac
    WHERE bnkac = p_payac.
  IF p_payac IS INITIAL OR sy-subrc <> 0.
    MESSAGE s410(zmsga) WITH '출금' DISPLAY LIKE 'E'.   " 출금계좌를 확인해 주십시오. (F4로 선택)
    RETURN.
  ENDIF.

  "─ 2. 확인 팝업
  WRITE lv_sum TO lv_amt CURRENCY lv_waers.
  CONDENSE lv_amt.
  lv_text = |{ p_paydt DATE = USER } 출금계좌 { p_payac }에서 공급업체 { lines( lt_lifnr ) }곳, 채무 { lv_cnt }건, 총 { lv_amt } { lv_waers }을 지급하시겠습니까?|.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '지급 등록'
      text_question         = lv_text
      text_button_1         = '지급'
      text_button_2         = '취소'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      OTHERS                = 1.
  IF sy-subrc <> 0 OR lv_answer <> '1'.
    MESSAGE s005(zmsga).      " 처리가 취소되었습니다.
    RETURN.
  ENDIF.

  "─ 3. 공급업체 단위로 저장 → COMMIT / ROLLBACK
  LOOP AT lt_lifnr INTO lv_lifnr.
    PERFORM pay_vendor USING    lv_lifnr
                       CHANGING lv_ok lv_err lv_paynr.

    IF lv_ok = 'X'.
      COMMIT WORK AND WAIT.
      lv_done = lv_done + 1.
      LOOP AT gt_pay INTO gw_pay WHERE paynr = lv_paynr.
        gw_pay-stico = icon_led_green.
        gw_pay-msg   = '지급 완료'.
        CLEAR ls_style.
        ls_style-fieldname = 'APCAM'.
        ls_style-style     = cl_gui_alv_grid=>mc_style_disabled.
        INSERT ls_style INTO TABLE gw_pay-celltab.
        MODIFY gt_pay FROM gw_pay.
      ENDLOOP.
    ELSE.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
      LOOP AT gt_pay INTO gw_pay WHERE lifnr = lv_lifnr
                                   AND ( paynr IS INITIAL OR paynr = lv_paynr ).
        CLEAR: gw_pay-paynr, gw_pay-clsta, gw_pay-sttxt.
        gw_pay-openbal = gw_pay-balbf - gw_pay-apcam.
        gw_pay-stico   = icon_led_red.
        gw_pay-msg     = lv_err.
        MODIFY gt_pay FROM gw_pay.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  "─ 4. 위 목록 다시 (지급누계·잔액 반영), 아래 결과 표시
  PERFORM get_data.
  PERFORM refresh_alv1.
  PERFORM refresh_alv2.

  MESSAGE s411(zmsga) WITH '지급' '공급업체' lv_done lv_fail. " 지급 완료: 공급업체 n곳 / 실패 n곳
ENDFORM.
*&---------------------------------------------------------------------*
*& Form pay_vendor  - 공급업체 1곳: 지급 내역 1건 + 반제 n줄 + AP 갱신 (COMMIT은 호출 쪽)
*&---------------------------------------------------------------------*
FORM pay_vendor USING    pv_lifnr TYPE ztcma00110-lifnr
                CHANGING pv_ok    TYPE c
                         pv_err   TYPE string
                         pv_paynr TYPE ztfia00050-paynr.
  DATA: ls_pay   TYPE ztfia00050,
        ls_apc   TYPE ztfia00030,
        ls_ap    TYPE ztcma00110,
        lv_apcnr TYPE ztfia00030-apcnr,
        lv_seq   TYPE ztfia00030-apcsq,
        lv_tdtyp TYPE ztexa00030-tdtyp VALUE 'AP',
        lv_tdnum TYPE ztexa00030-tdnum,
        lv_held  TYPE abap_bool,
        lv_hdnum TYPE ztexa00030-hdnum,
        lv_tabix TYPE sy-tabix.

  CLEAR: pv_ok, pv_err, pv_paynr.

  "─ 0. 저장 직전 홀드 재확인 (화면 띄운 사이 걸렸을 수 있음)
  LOOP AT gt_pay INTO gw_pay WHERE lifnr = pv_lifnr AND paynr IS INITIAL.
    lv_tdnum = gw_pay-apnum.
    CLEAR lv_held.
    CALL FUNCTION 'ZCM_HOLD_CHECK'
      EXPORTING
        iv_tdtyp = lv_tdtyp
        iv_tdnum = lv_tdnum
      IMPORTING
        ev_held  = lv_held
        ev_hdnum = lv_hdnum.
    IF lv_held = abap_true.
      pv_err = |{ gw_pay-apnum } Payment Hold 중 - 지급 불가|.
      RETURN.
    ENDIF.
  ENDLOOP.

  "─ 1. 지급 내역 (공급업체 1건)
  PERFORM next_paynr CHANGING ls_pay-paynr.
  pv_paynr     = ls_pay-paynr.
  ls_pay-lifnr = pv_lifnr.
  ls_pay-paydt = p_paydt.
  ls_pay-payac = p_payac.
  LOOP AT gt_pay INTO gw_pay WHERE lifnr = pv_lifnr AND paynr IS INITIAL.
    ls_pay-payam = ls_pay-payam + gw_pay-apcam.
    ls_pay-waers = gw_pay-waers.
  ENDLOOP.
  ls_pay-ernam = sy-uname.
  ls_pay-erdat = sy-datum.
  ls_pay-erzet = sy-uzeit.

  INSERT ztfia00050 FROM ls_pay.
  IF sy-subrc <> 0.
    pv_err = '지급 내역 저장 실패'.
    RETURN.
  ENDIF.

  "─ 2. 반제(채무마다 1줄, 반제번호 1개 + 순번) + 3. AP 갱신
  PERFORM next_apcnr CHANGING lv_apcnr.

  LOOP AT gt_pay INTO gw_pay WHERE lifnr = pv_lifnr AND paynr IS INITIAL.
    lv_tabix = sy-tabix.
    lv_seq   = lv_seq + 1.

    CLEAR ls_apc.
    ls_apc-apcnr = lv_apcnr.
    ls_apc-apcsq = lv_seq.
    ls_apc-paynr = ls_pay-paynr.
    ls_apc-apnum = gw_pay-apnum.
    ls_apc-apcam = gw_pay-apcam.
    ls_apc-apcdt = p_paydt.
    ls_apc-lifnr = pv_lifnr.
    ls_apc-waers = gw_pay-waers.
    ls_apc-ernam = sy-uname.
    ls_apc-erdat = sy-datum.
    ls_apc-erzet = sy-uzeit.
    INSERT ztfia00030 FROM ls_apc.
    IF sy-subrc <> 0.
      pv_err = |{ gw_pay-apnum } 반제 저장 실패|.
      RETURN.
    ENDIF.

    " 저장 직전 최신 누계로 갱신 (동시에 다른 지급이 있었을 수 있음)
    SELECT SINGLE * FROM ztcma00110 INTO ls_ap
      WHERE apnum = gw_pay-apnum.
    IF sy-subrc <> 0.
      pv_err = |{ gw_pay-apnum } 채무 없음|.
      RETURN.
    ENDIF.

    ls_ap-paybt = ls_ap-paybt + gw_pay-apcam.
    IF ls_ap-paybt + ls_ap-adjbt >= ls_ap-dmbtr.
      ls_ap-clsta = gc_clsta_done.
      ls_ap-augdt = p_paydt.
    ELSE.
      ls_ap-clsta = gc_clsta_part.
    ENDIF.

    UPDATE ztcma00110
       SET paybt = ls_ap-paybt
           clsta = ls_ap-clsta
           augdt = ls_ap-augdt
           aenam = sy-uname
           aedat = sy-datum
           aezet = sy-uzeit
     WHERE apnum = ls_ap-apnum.
    IF sy-subrc <> 0.
      pv_err = |{ gw_pay-apnum } 채무 갱신 실패|.
      RETURN.
    ENDIF.

    " 화면 행에 결과 (실패로 롤백되면 호출 쪽에서 되돌림)
    gw_pay-paynr   = ls_pay-paynr.
    gw_pay-clsta   = ls_ap-clsta.
    gw_pay-openbal = ls_ap-dmbtr - ls_ap-paybt - ls_ap-adjbt.
    PERFORM status_text USING ls_ap-clsta CHANGING gw_pay-sttxt.
    MODIFY gt_pay FROM gw_pay INDEX lv_tabix.
  ENDLOOP.

  pv_ok = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form next_paynr  - 지급번호 (PAY + 7자리)
*&---------------------------------------------------------------------*
FORM next_paynr CHANGING pv_paynr TYPE ztfia00050-paynr.
  DATA: lv_max TYPE ztfia00050-paynr,
        lv_n   TYPE n LENGTH 7.

  SELECT MAX( paynr ) FROM ztfia00050 INTO lv_max
    WHERE paynr LIKE 'PAY%'.
  IF lv_max IS NOT INITIAL.
    lv_n = lv_max+3(7).
  ENDIF.
  lv_n = lv_n + 1.
  CONCATENATE 'PAY' lv_n INTO pv_paynr.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form next_apcnr  - 반제번호 (APC + 7자리, 00090과 같은 규칙)
*&---------------------------------------------------------------------*
FORM next_apcnr CHANGING pv_apcnr TYPE ztfia00030-apcnr.
  DATA: lv_max TYPE ztfia00030-apcnr,
        lv_n   TYPE n LENGTH 7.

  SELECT MAX( apcnr ) FROM ztfia00030 INTO lv_max
    WHERE apcnr LIKE 'APC%'.
  IF lv_max IS NOT INITIAL.
    lv_n = lv_max+3(7).
  ENDIF.
  lv_n = lv_n + 1.
  CONCATENATE 'APC' lv_n INTO pv_apcnr.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_payac  - 출금계좌 F4 (은행명·계좌번호)
*&---------------------------------------------------------------------*
FORM f4_payac .
  TYPES: BEGIN OF ty_f4,
           bnkac TYPE ztfia00070-bnkac,
           banka TYPE ztfia00070-banka,
           bankn TYPE ztfia00070-bankn,
         END OF ty_f4.
  DATA lt_f4 TYPE TABLE OF ty_f4.

  SELECT bnkac banka bankn FROM ztfia00070 INTO TABLE lt_f4.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'BNKAC'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_PAYAC'
      value_org   = 'S'
    TABLES
      value_tab   = lt_f4
    EXCEPTIONS
      OTHERS      = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_lifnr  - 공급업체 F4 (번호 + 회사명)
*&---------------------------------------------------------------------*
FORM f4_lifnr .
  TYPES: BEGIN OF ty_f4,
           lifnr TYPE ztcma00010-lifnr,
           name1 TYPE ztcma00010-name1,
         END OF ty_f4.
  DATA lt_f4 TYPE TABLE OF ty_f4.

  SELECT lifnr name1 FROM ztcma00010 INTO TABLE lt_f4
    ORDER BY lifnr.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'LIFNR'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_LIFNR'
      value_org   = 'S'
    TABLES
      value_tab   = lt_f4
    EXCEPTIONS
      OTHERS      = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form exclude_toolbar
*&---------------------------------------------------------------------*
FORM exclude_toolbar CHANGING pt_exclude TYPE ui_functions.
  APPEND cl_gui_alv_grid=>mc_fc_check             TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_refresh           TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut           TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy          TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste         TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo          TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row    TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row    TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row    TO pt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row      TO pt_exclude.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_bank_text  - 계좌코드 옆에 은행명 + 계좌번호
*&---------------------------------------------------------------------*
FORM set_bank_text .
  DATA: lv_banka TYPE ztfia00070-banka,
        lv_bankn TYPE ztfia00070-bankn.

  CLEAR gv_bnktx.
  CHECK p_payac IS NOT INITIAL.

  SELECT SINGLE banka bankn FROM ztfia00070
    INTO (lv_banka, lv_bankn)
    WHERE bnkac = p_payac.
  IF sy-subrc = 0.
    gv_bnktx = |{ lv_banka } { lv_bankn }|.
  ELSE.
    gv_bnktx = '등록되지 않은 계좌'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_lifnr_text  - 공급업체 번호 옆 회사명
*&---------------------------------------------------------------------*
FORM set_lifnr_text .
  CLEAR gv_lifnm.
  CHECK p_lifnr IS NOT INITIAL.

  SELECT SINGLE name1 FROM ztcma00010 INTO gv_lifnm
    WHERE lifnr = p_lifnr.
  IF sy-subrc <> 0.
    gv_lifnm = '등록되지 않은 공급업체'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_hold  - 자물쇠 클릭 → 홀드 사유 팝업 (ZTEXA00030, HTML 창)
*&   홀드번호는 화면 띄운 뒤 바뀌었을 수 있으니 ZCM_HOLD_CHECK로 다시 확인
*&---------------------------------------------------------------------*
FORM show_hold USING pv_apnum TYPE ztcma00110-apnum
                     pv_ivnum TYPE ztcma00110-ivnum.
  DATA: lv_tdtyp TYPE ztexa00030-tdtyp VALUE 'AP',
        lv_tdnum TYPE ztexa00030-tdnum,
        lv_held  TYPE abap_bool,
        lv_hdnum TYPE ztexa00030-hdnum,
        ls_hold  TYPE ztexa00030,
        lv_rsn   TYPE string,
        lv_body  TYPE string,
        lv_html  TYPE string.

  lv_tdnum = pv_apnum.
  CALL FUNCTION 'ZCM_HOLD_CHECK'
    EXPORTING
      iv_tdtyp = lv_tdtyp
      iv_tdnum = lv_tdnum
    IMPORTING
      ev_held  = lv_held
      ev_hdnum = lv_hdnum.

  IF lv_held = abap_true AND lv_hdnum IS NOT INITIAL.
    SELECT SINGLE * FROM ztexa00030 INTO ls_hold
      WHERE hdnum = lv_hdnum.
  ENDIF.

  "─ 본문 (홀드 있음 / 그 사이 해제됨)
  IF ls_hold IS INITIAL.
    lv_body =
      |<span class="bd ok">해제됨</span>| &&
      |<table><tr><th>채무번호</th><td>{ pv_apnum }</td></tr>| &&
      |<tr><th>송장번호</th><td>{ pv_ivnum }</td></tr></table>| &&
      |<div class="rs">지금은 홀드가 걸려 있지 않습니다.<br>[조회]를 눌러 최신 상태로 다시 확인해 주십시오.</div>|.
  ELSE.
    lv_rsn = escape( val = ls_hold-hdrsn format = cl_abap_format=>e_html_text ).   " 사유 글자 그대로 표시
    lv_body =
      |<span class="bd">&#128274; 홀드 중</span>| &&
      |<table><tr><th>채무번호</th><td>{ pv_apnum }</td></tr>| &&
      |<tr><th>송장번호</th><td>{ pv_ivnum }</td></tr>| &&
      |<tr><th>홀드번호</th><td>{ ls_hold-hdnum } · 예외 { ls_hold-exnum }</td></tr>| &&
      |<tr><th>홀드일</th><td>{ ls_hold-erdat DATE = USER } · { ls_hold-ernam }</td></tr></table>| &&
      |<div class="lb">사유</div><div class="rs">{ lv_rsn }</div>|.
  ENDIF.

  "─ 디자인 (대시보드 상세 창과 같은 톤)
  lv_html =
    |<html><head><meta charset="utf-8"><style>| &&
    |body\{font-family:'Malgun Gothic',sans-serif;margin:16px;color:#3b4358;font-size:13px\}| &&
    |.bd\{display:inline-block;padding:3px 10px;border-radius:10px;background:#fdeaea;color:#cf5555;font-weight:bold\}| &&
    |.bd.ok\{background:#e6f6ee;color:#2a8a60\}| &&
    |table\{border-collapse:collapse;width:100%;margin:12px 0\}| &&
    |th\{text-align:left;width:80px;color:#7a8296;font-weight:normal;padding:6px 0;border-bottom:1px solid #eceff5\}| &&
    |td\{padding:6px 0;border-bottom:1px solid #eceff5;font-weight:bold\}| &&
    |.lb\{color:#7a8296;margin-bottom:4px\}| &&
    |.rs\{background:#f6f7fb;border-radius:8px;padding:10px 12px;line-height:1.5;word-break:break-all\}| &&
    |</style></head><body>{ lv_body }</body></html>|.

  cl_abap_browser=>show_html(
    html_string = lv_html
    title       = '홀드 사유'
    size        = cl_abap_browser=>small
    modal       = abap_true ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form call_invoice  - 송장번호 클릭 → ZFI03 송장 조회 (그 1건, 상태 전부)
*&   ※ ZLFIA00170 선택 화면 이름이 00070과 같다는 전제 (s_ivnum / p_ok / p_hold / p_rej / p_canc)
*&---------------------------------------------------------------------*
FORM call_invoice USING pv_ivnum TYPE ztcma00110-ivnum.
  SUBMIT zlfia00170 WITH s_ivnum = pv_ivnum
                    WITH p_ok    = 'X'
                    WITH p_hold  = 'X'
                    WITH p_rej   = 'X'
                    WITH p_canc  = 'X'
                    AND RETURN.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form confirm_exit  - Back·Exit·Cancel → 종료 확인 팝업
*&   지급 목록에 아직 등록 안 한 건이 있으면 경고 문구
*&---------------------------------------------------------------------*
FORM confirm_exit .
  DATA: lv_answer TYPE c LENGTH 1,
        lv_text   TYPE string.

  READ TABLE gt_pay TRANSPORTING NO FIELDS WITH KEY paynr = space.
  IF sy-subrc = 0.
    lv_text = '미등록 목록이 있습니다. 종료하시겠습니까?'.
  ELSE.
    lv_text = '프로그램을 종료하시겠습니까?'.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '종료 확인'
      text_question         = lv_text
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      OTHERS                = 1.
  IF sy-subrc = 0 AND lv_answer = '1'.
    LEAVE PROGRAM.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form toggle_sum  - [공급업체별 합계 보기/끄기] 지급액 총합계 + 공급업체별 소계 켜고 끄기
*&---------------------------------------------------------------------*
FORM toggle_sum .
  DATA: lt_fcat   TYPE lvc_t_fcat,
        ls_fcat   TYPE lvc_s_fcat,
        lt_sort   TYPE lvc_t_sort,
        ls_sort   TYPE lvc_s_sort,
        ls_stable TYPE lvc_s_stbl.

  IF gv_sumon = abap_true.
    gv_sumon = abap_false.
  ELSE.
    gv_sumon = abap_true.
  ENDIF.

  " 1) 지급액 열 합계 켜기/끄기
  go_alv2->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = lt_fcat ).
  LOOP AT lt_fcat INTO ls_fcat WHERE fieldname = 'APCAM'.
    ls_fcat-do_sum = gv_sumon.
    MODIFY lt_fcat FROM ls_fcat.
  ENDLOOP.
  go_alv2->set_frontend_fieldcatalog( it_fieldcatalog = lt_fcat ).

  " 2) 공급업체 정렬에 소계 켜기/끄기 (정렬이 없어졌으면 다시 만듦)
  go_alv2->get_sort_criteria( IMPORTING et_sort = lt_sort ).
  LOOP AT lt_sort INTO ls_sort WHERE fieldname = 'LIFNR'.
    ls_sort-subtot = gv_sumon.
    MODIFY lt_sort FROM ls_sort.
  ENDLOOP.
  IF sy-subrc <> 0 AND gv_sumon = abap_true.
    CLEAR ls_sort.
    ls_sort-spos      = 1.
    ls_sort-fieldname = 'LIFNR'.
    ls_sort-up        = 'X'.
    ls_sort-subtot    = 'X'.
    APPEND ls_sort TO lt_sort.
  ENDIF.
  go_alv2->set_sort_criteria( it_sort = lt_sort ).

  " 3) 버튼 글자 바꾸고 화면 갱신
  go_alv2->set_toolbar_interactive( ).
  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv2->refresh_table_display( is_stable = ls_stable ).
ENDFORM.
