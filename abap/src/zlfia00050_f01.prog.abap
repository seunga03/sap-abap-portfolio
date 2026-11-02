*&---------------------------------------------------------------------*
*& Include          ZLFIA00050_F01
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
*& Form set_evt_handler  - 아래 수금액 고치면 바로 재계산 / ALV 툴바 버튼
*&---------------------------------------------------------------------*
FORM set_evt_handler .
  go_alv2->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_modified ).
  go_alv2->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_enter ).

  SET HANDLER: lcl_handler=>on_data_changed_finished FOR go_alv2,
               lcl_handler=>on_toolbar               FOR go_alv1,     " [수금 목록에 추가]
               lcl_handler=>on_toolbar               FOR go_alv2,     " [목록에서 제외] [수금 등록]
               lcl_handler=>on_user_command          FOR go_alv1,
               lcl_handler=>on_user_command          FOR go_alv2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout
*&---------------------------------------------------------------------*
FORM set_alv_layout .
  DATA ls_sort TYPE lvc_s_sort.

  CLEAR: gs_layout1, gs_layout2, gt_sort2, gt_exclude.

  PERFORM exclude_toolbar CHANGING gt_exclude.

  "─ 상단: 채권 목록
  gs_layout1-stylefname = 'CELLTAB'.              " 셀 스타일 (현재 미사용)
  gs_layout1-zebra      = 'X'.
  gs_layout1-info_fname = 'ROWCOL'.               " 행 색 (연체 빨강 / 7일 이내 주황)
  gs_layout1-sel_mode   = 'A'.                    " 왼쪽 행 선택 버튼 (Ctrl·Shift로 여러 행)

  "─ 하단: 수금 목록
  gs_layout2-stylefname = 'CELLTAB'.              " 수금 끝난 행 수금액 잠금
  gs_layout2-sel_mode   = 'A'.                    " [목록에서 제외]용 행 선택
  gs_layout2-zebra      = 'X'.
*  gs_layout2-no_toolbar = 'X'.                    " 툴바에 [목록에서 제외] [수금 등록] 버튼을 달아서 사용 (표준 버튼은 display_alv에서 전부 숨김)

  " 고객별 소계 + 총합계
  ls_sort-spos      = 1.
  ls_sort-fieldname = 'KUNNR'.
  ls_sort-up        = 'X'.
* ls_sort-subtot    = 'X'.
  APPEND ls_sort TO gt_sort2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog  (정렬: 글자 왼쪽 / 금액 오른쪽 / 날짜·통화·아이콘 가운데)
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  DATA ls TYPE lvc_s_fcat.

  CLEAR: gt_fcat1, gt_fcat2.

  "─ 상단: 채권 목록
  "  수금기한 → 기한 → 채권번호 → 고객명 → 잔액 → 통화 → 채권금액 → 수금누계 → 조정누계 → 청구번호 → 고객
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name   = 'ZSFIA00050'
      i_bypassing_buffer = 'X'
    CHANGING
      ct_fieldcat        = gt_fcat1.

  LOOP AT gt_fcat1 INTO ls.
    CASE ls-fieldname.
      WHEN 'SEL'.
*        ls-col_pos = 1.  ls-coltext = '선택'.  ls-checkbox = 'X'.      " 조 통일: 체크박스 대신 왼쪽 행 선택
*        ls-edit = 'X'.   ls-outputlen = 2.
        ls-no_out = 'X'.
      WHEN 'DUEDT'.   ls-col_pos = 1.  ls-coltext = '수금기한'.   ls-outputlen = 7.  ls-just = 'C'.
      WHEN 'ARNUM'.   ls-col_pos = 3.  ls-coltext = '채권번호'.   ls-outputlen = 7.
      WHEN 'NAME1'.   ls-col_pos = 4.  ls-coltext = '고객명'.     ls-outputlen = 7.
      WHEN 'OPENBAL'. ls-col_pos = 5.  ls-coltext = '잔액'.       ls-outputlen = 8.  ls-emphasize = 'C300'.
      WHEN 'WAERS'.   ls-col_pos = 6.  ls-coltext = '통화'.       ls-outputlen = 2.  ls-just = 'C'.
      WHEN 'DMBTR'.   ls-col_pos = 7.  ls-coltext = '채권금액'.   ls-outputlen = 7.
      WHEN 'RCPBT'.   ls-col_pos = 8.  ls-coltext = '수금누계'.   ls-outputlen = 8.  ls-no_zero = 'X'.
      WHEN 'BILNO'.   ls-col_pos = 10. ls-coltext = '청구번호'.   ls-outputlen = 7.
      WHEN 'KUNNR'.   ls-col_pos = 11. ls-coltext = '고객'.       ls-outputlen = 7.
      WHEN OTHERS.    ls-no_out = 'X'.             " 구조에만 있고 안 쓰는 필드 (RCPAM)
    ENDCASE.
    MODIFY gt_fcat1 FROM ls.
  ENDLOOP.

  CLEAR ls.
  ls-fieldname = 'DDTXT'.  ls-col_pos = 2.  ls-coltext = '기한'.
  ls-inttype = 'C'.  ls-intlen = 10.  ls-outputlen = 5.  ls-just = 'C'.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname  = 'ADJBT'.
  ls-col_pos    = 9.
  ls-coltext    = '조정누계'.
  ls-ref_table  = 'ZTCMA00100'.
  ls-ref_field  = 'ADJBT'.
  ls-cfieldname = 'WAERS'.
  ls-no_zero    = 'X'.
  ls-outputlen  = 8.
  APPEND ls TO gt_fcat1.

  "─ 하단: 수금 목록
  "  결과 → 고객 → 고객명 → 채권번호 → 수금액 → 수금 전 잔액 → 수금 후 잔액 → 통화
  "  → 수금상태 → 수금번호 → 청구번호 → 채권금액 → 처리 결과
  "  (고객 KUNNR 소계라 고객 코드는 앞에 둠)
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name   = 'ZSFIA00041'
      i_bypassing_buffer = 'X'
    CHANGING
      ct_fieldcat        = gt_fcat2.

  LOOP AT gt_fcat2 INTO ls.
    CASE ls-fieldname.
      WHEN 'ARNUM'.   ls-col_pos = 4.  ls-coltext = '채권번호'.     ls-outputlen = 7.
      WHEN 'ARCAM'.
        ls-col_pos = 5.  ls-coltext = '수금액'.       ls-outputlen = 8.
        ls-edit = 'X'.  ls-emphasize = 'C300'.
*       ls-do_sum = 'X'.
      WHEN 'OPENBAL'. ls-col_pos = 7.  ls-coltext = '수금 후 잔액'. ls-outputlen = 8.
      WHEN 'WAERS'.   ls-col_pos = 8.  ls-coltext = '통화'.         ls-outputlen = 2.  ls-just = 'C'.
      WHEN 'RCPNR'.   ls-col_pos = 10. ls-coltext = '수금번호'.     ls-outputlen = 7.
      WHEN 'DMBTR'.   ls-col_pos = 12. ls-coltext = '채권금액'.     ls-outputlen = 8.
      WHEN OTHERS.    ls-no_out = 'X'.             " CLSTA 코드 → STTXT 글자로 대신 표시
    ENDCASE.
    MODIFY gt_fcat2 FROM ls.
  ENDLOOP.

  CLEAR ls.
  ls-fieldname = 'STICO'.  ls-col_pos = 1.  ls-coltext = '결과'.
  ls-icon = 'X'.  ls-just = 'C'.  ls-outputlen = 2.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'KUNNR'.  ls-col_pos = 2.  ls-coltext = '고객'.
  ls-ref_table = 'ZTCMA00100'.  ls-ref_field = 'KUNNR'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'NAME1'.  ls-col_pos = 3.  ls-coltext = '고객명'.
  ls-ref_table = 'ZTCMA00050'.  ls-ref_field = 'NAME1'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname  = 'BALBF'.  ls-col_pos = 6.  ls-coltext = '수금 전 잔액'.
  ls-ref_table  = 'ZTCMA00100'.  ls-ref_field = 'DMBTR'.  ls-outputlen = 8.
  ls-cfieldname = 'WAERS'.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'STTXT'.  ls-col_pos = 9.  ls-coltext = '수금상태'.
  ls-inttype = 'C'.  ls-intlen = 10.  ls-outputlen = 5.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'BILNO'.  ls-col_pos = 11.  ls-coltext = '청구번호'.
  ls-ref_table = 'ZTCMA00100'.  ls-ref_field = 'BILNO'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'MSG'.  ls-col_pos = 13.  ls-coltext = '처리 결과'.      " 문장이 길어서 맨 뒤
  ls-inttype = 'C'.  ls-intlen = 60.  ls-outputlen = 15.
  APPEND ls TO gt_fcat2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
FORM display_alv .
  DATA lt_excl2 TYPE ui_functions.                " 아래: 표준 버튼 전부 숨김 → 내 버튼 3개만

  APPEND cl_gui_alv_grid=>mc_fc_excl_all TO lt_excl2.

*── 상단: 채권 목록
  CALL METHOD go_alv1->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout1
      it_toolbar_excluding          = gt_exclude
    CHANGING
      it_outtab                     = gt_arreg
      it_fieldcatalog               = gt_fcat1
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a067(zmsga) WITH '화면 표시'.      " 화면 표시 처리 중 오류가 발생했습니다.
  ENDIF.

*── 하단: 수금 목록
  CALL METHOD go_alv2->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout2
      it_toolbar_excluding          = lt_excl2
    CHANGING
      it_outtab                     = gt_rcp
      it_fieldcatalog               = gt_fcat2
      it_sort                       = gt_sort2
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a067(zmsga) WITH '화면 표시'.      " 화면 표시 처리 중 오류가 발생했습니다.
  ENDIF.

  go_alv1->set_toolbar_interactive( ).            " 툴바 맨 뒤에 [수금 목록에 추가] 반영
  go_alv2->set_toolbar_interactive( ).            " 툴바에 [목록에서 제외] [수금 등록] | Σ 소계 반영

  PERFORM refresh_alv1.                           " 채권 목록 (n건)
  PERFORM refresh_alv2.                           " 수금 목록 (0건)
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_search  - [조회]
*&---------------------------------------------------------------------*
FORM process_search .
  DATA lv_cnt TYPE i.

  IF p_open IS INITIAL AND p_part IS INITIAL AND p_done IS INITIAL.
    MESSAGE s401(zmsga) WITH '수금상태' DISPLAY LIKE 'E'.      " 수금상태을(를) 하나 이상 선택해 주십시오.
    RETURN.
  ENDIF.

  PERFORM get_data.
  PERFORM refresh_alv1.

  lv_cnt = lines( gt_arreg ).
  MESSAGE s055(zmsga) WITH lv_cnt.      " 처리 대상 n건을 조회했습니다.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data  - 채권 조회 (아래에 담긴 건 제외, 수금기한 빠른 순)
*&---------------------------------------------------------------------*
FORM get_data .
  TYPES: BEGIN OF lty_name,
           kunnr TYPE ztcma00050-kunnr,
           name1 TYPE ztcma00050-name1,
         END OF lty_name.

  DATA: lr_clsta TYPE RANGE OF ztcma00100-clsta,
        ls_clsta LIKE LINE OF lr_clsta,
        lr_kunnr TYPE RANGE OF ztcma00100-kunnr,
        ls_kunnr LIKE LINE OF lr_kunnr,
        lt_ar    TYPE TABLE OF ztcma00100,
        ls_ar    TYPE ztcma00100,
        lt_name  TYPE STANDARD TABLE OF lty_name,
        ls_name  TYPE lty_name,
        ls_style TYPE lvc_s_styl.

  CLEAR gt_arreg.

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

  IF p_kunnr IS NOT INITIAL.
    ls_kunnr-sign   = 'I'.
    ls_kunnr-option = 'EQ'.
    ls_kunnr-low    = p_kunnr.
    APPEND ls_kunnr TO lr_kunnr.
  ENDIF.

  SELECT * FROM ztcma00100 INTO TABLE lt_ar
    WHERE kunnr IN lr_kunnr
      AND duedt IN s_duedt
      AND clsta IN lr_clsta.
  CHECK lt_ar IS NOT INITIAL.
  SORT lt_ar BY duedt kunnr arnum.

  " 고객명 한 번에 (고객 마스터 키 = 고객+주소코드 → 고객당 1줄만 남김)
  SELECT kunnr name1 FROM ztcma00050 INTO TABLE lt_name
    FOR ALL ENTRIES IN lt_ar
    WHERE kunnr = lt_ar-kunnr.
  SORT lt_name BY kunnr.
  DELETE ADJACENT DUPLICATES FROM lt_name COMPARING kunnr.

  LOOP AT lt_ar INTO ls_ar.
    " 아래 '수금 목록'에 담겨 있고 아직 수금 전이면 위에서는 제외
    READ TABLE gt_rcp TRANSPORTING NO FIELDS
         WITH KEY arnum = ls_ar-arnum rcpnr = space.
    CHECK sy-subrc <> 0.

    CLEAR gw_arreg.
    MOVE-CORRESPONDING ls_ar TO gw_arreg.         " kunnr arnum bilno duedt dmbtr rcpbt waers adjbt
    gw_arreg-openbal = ls_ar-dmbtr - ls_ar-rcpbt - ls_ar-adjbt.

    " 기한 글자·행 색 (잔액 남은 건만)
    IF gw_arreg-openbal > 0.
      PERFORM due_text USING    gw_arreg-duedt
                       CHANGING gw_arreg-ddtxt gw_arreg-rowcol.
    ENDIF.

    READ TABLE lt_name INTO ls_name
         WITH KEY kunnr = ls_ar-kunnr BINARY SEARCH.
    IF sy-subrc = 0.
      gw_arreg-name1 = ls_name-name1.
    ENDIF.

    " 잔액 없는 채권(수금완료) (선택해도 [추가] 때 제외)
    IF gw_arreg-openbal <= 0.
*      CLEAR ls_style.                                                  " 체크박스 잠금 (체크박스 사용 안 함)
*      ls_style-fieldname = 'SEL'.
*      ls_style-style     = cl_gui_alv_grid=>mc_style_disabled.
*      INSERT ls_style INTO TABLE gw_arreg-celltab.
    ENDIF.

    APPEND gw_arreg TO gt_arreg.
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
*& Form process_add  - [수금 목록에 추가] 채권 목록 선택 행 → 수금 목록으로
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

  " 지난 수금 결과(수금번호 있는 행)는 지우고 새로 시작
  DELETE gt_rcp WHERE rcpnr IS NOT INITIAL.

  SORT lt_rows BY index DESCENDING.               " 뒤에서부터 (위 목록에서 행을 지우므로 번호 안 밀리게)
  LOOP AT lt_rows INTO ls_row.
    READ TABLE gt_arreg INTO gw_arreg INDEX ls_row-index.
    CHECK sy-subrc = 0.
    CHECK gw_arreg-openbal > 0.                   " 수금완료 건은 제외

    CLEAR gw_rcp.
    gw_rcp-kunnr   = gw_arreg-kunnr.
    gw_rcp-name1   = gw_arreg-name1.
    gw_rcp-arnum   = gw_arreg-arnum.
    gw_rcp-bilno   = gw_arreg-bilno.
    gw_rcp-dmbtr   = gw_arreg-dmbtr.
    gw_rcp-balbf   = gw_arreg-openbal.
    gw_rcp-arcam   = gw_arreg-openbal.            " 기본 = 잔액 전액
    gw_rcp-openbal = 0.
    gw_rcp-waers   = gw_arreg-waers.
    APPEND gw_rcp TO gt_rcp.

    DELETE gt_arreg INDEX ls_row-index.           " 담은 채권은 위 목록에서 뺌
    lv_cnt = lv_cnt + 1.
  ENDLOOP.

  IF lv_cnt = 0.
    MESSAGE s404(zmsga) DISPLAY LIKE 'E'.         " 수금완료 건만 골랐을 때
    RETURN.
  ENDIF.

*  DELETE gt_arreg WHERE sel = 'X' AND openbal > 0.   " 체크박스 방식 (위 LOOP에서 행 단위로 삭제)
  SORT gt_rcp BY kunnr arnum.

  PERFORM refresh_alv1.
  PERFORM refresh_alv2.

  MESSAGE s405(zmsga) WITH lv_cnt '수금'.  " n건을 수금 목록에 추가했습니다. 수금액은 아래에서 수정할 수 있습니다.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_del  - [목록에서 제외] 수금 목록 선택 행 → 채권 목록으로
*&---------------------------------------------------------------------*
FORM process_del .
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row,
        lv_cnt  TYPE i.

  go_alv2->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
  IF lt_rows IS INITIAL.
    MESSAGE s402(zmsga) WITH '뺄' DISPLAY LIKE 'E'.   " 뺄 행을 선택해 주십시오. (왼쪽 행 선택 버튼)
    RETURN.
  ENDIF.

  SORT lt_rows BY index DESCENDING.               " 뒤에서부터 지워야 번호 안 밀림
  LOOP AT lt_rows INTO ls_row.
    READ TABLE gt_rcp INTO gw_rcp INDEX ls_row-index.
    CHECK sy-subrc = 0 AND gw_rcp-rcpnr IS INITIAL.   " 수금 끝난 행은 못 뺌
    DELETE gt_rcp INDEX ls_row-index.
    lv_cnt = lv_cnt + 1.
  ENDLOOP.

  PERFORM get_data.                               " 뺀 채권이 위에 다시 나오게
  PERFORM refresh_alv1.
  PERFORM refresh_alv2.

  MESSAGE s406(zmsga) WITH lv_cnt '수금'.      " n건을 수금 목록에서 제외했습니다.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_reset  - [화면 비우기] 조건을 처음 값으로 → 처음처럼 다시 조회
*&   DB에 등록된 수금은 그대로 (화면만 비움)
*&---------------------------------------------------------------------*
FORM process_reset .
  DATA: lv_answer TYPE c LENGTH 1,
        lv_cnt    TYPE i.

  " 아래에 담아만 두고 아직 수금 안 한 건이 있으면 확인
  READ TABLE gt_rcp TRANSPORTING NO FIELDS WITH KEY rcpnr = space.
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

  CLEAR: gt_arreg, gt_rcp,
         p_kunnr, s_duedt, s_duedt[], p_rcpac, p_done.
  p_open  = 'X'.
  p_part  = 'X'.
  p_rcpdt = sy-datum.

  PERFORM get_data.                               " 시작 화면과 같은 기본 조회
  PERFORM refresh_alv1.
  PERFORM refresh_alv2.

  lv_cnt = lines( gt_arreg ).
  MESSAGE s413(zmsga) WITH lv_cnt.                " 최신 상태로 다시 조회했습니다. (n건)
ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_openbal  - 수금 후 잔액 = 수금 전 잔액 - 수금액
*&---------------------------------------------------------------------*
FORM calc_openbal .
  LOOP AT gt_rcp INTO gw_rcp WHERE rcpnr IS INITIAL.
    gw_rcp-openbal = gw_rcp-balbf - gw_rcp-arcam.
    MODIFY gt_rcp FROM gw_rcp.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv1 / refresh_alv2  - 상단 / 하단 화면 갱신
*&---------------------------------------------------------------------*
FORM refresh_alv1 .
  DATA ls_stable TYPE lvc_s_stbl.

  go_alv1->set_gridtitle( |채권 목록 ({ lines( gt_arreg ) }건)| ).

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv1->refresh_table_display( is_stable = ls_stable ).
ENDFORM.

FORM refresh_alv2 .
  DATA: ls_stable TYPE lvc_s_stbl,
        lv_title  TYPE lvc_title,
        lv_cnt    TYPE i,
        lv_sum    TYPE ztfia00060-rcpam,
        lv_amt    TYPE c LENGTH 30,
        lv_waers  TYPE ztfia00060-waers,
        lt_kunnr  TYPE SORTED TABLE OF ztcma00100-kunnr WITH UNIQUE KEY table_line.

  LOOP AT gt_rcp INTO gw_rcp.
    lv_cnt   = lv_cnt + 1.
    lv_sum   = lv_sum + gw_rcp-arcam.
    lv_waers = gw_rcp-waers.
    INSERT gw_rcp-kunnr INTO TABLE lt_kunnr.
  ENDLOOP.

  IF lv_cnt = 0.
    lv_title = '수금 목록 (0건)'.
  ELSE.
    WRITE lv_sum TO lv_amt CURRENCY lv_waers.
    CONDENSE lv_amt.
    lv_title = |수금 목록 ({ lv_cnt }건) - 고객 { lines( lt_kunnr ) }곳 / 합계 { lv_amt } { lv_waers }|.
  ENDIF.
  go_alv2->set_gridtitle( lv_title ).

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv2->refresh_table_display( is_stable = ls_stable ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form status_text  - 수금상태 코드 → 글자 (텍스트 기호 C01~C03)
*&---------------------------------------------------------------------*
FORM status_text USING    pv_clsta TYPE ztcma00100-clsta
                 CHANGING pv_sttxt TYPE c.
  CASE pv_clsta.
    WHEN gc_clsta_open. pv_sttxt = TEXT-c01.      " 미수
    WHEN gc_clsta_part. pv_sttxt = TEXT-c02.      " 부분수금
    WHEN gc_clsta_done. pv_sttxt = TEXT-c03.      " 수금완료
    WHEN OTHERS.        CLEAR pv_sttxt.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_rcp  - [수금 등록]
*&---------------------------------------------------------------------*
FORM process_rcp .
  DATA: lv_valid  TYPE c LENGTH 1,
        lv_cnt    TYPE i,
        lv_sum    TYPE ztfia00060-rcpam,
        lv_amt    TYPE c LENGTH 30,
        lv_waers  TYPE ztfia00060-waers,
        lv_text   TYPE string,
        lv_answer TYPE c LENGTH 1,
        lv_bnkac  TYPE ztfia00070-bnkac,
        lt_kunnr  TYPE SORTED TABLE OF ztcma00100-kunnr WITH UNIQUE KEY table_line,
        lv_kunnr  TYPE ztcma00100-kunnr,
        lv_rcpnr  TYPE ztfia00060-rcpnr,
        lv_ok     TYPE c LENGTH 1,
        lv_err    TYPE string,
        lv_done   TYPE i,
        lv_fail   TYPE i,
        ls_style  TYPE lvc_s_styl.

  go_alv2->check_changed_data( IMPORTING e_valid = lv_valid ).
  CHECK lv_valid = 'X'.
  PERFORM calc_openbal.

  "─ 1. 검증
  LOOP AT gt_rcp INTO gw_rcp WHERE rcpnr IS INITIAL.
    lv_cnt = lv_cnt + 1.
    IF gw_rcp-arcam <= 0 OR gw_rcp-arcam > gw_rcp-balbf.
      MESSAGE s407(zmsga) WITH gw_rcp-arnum '수금' DISPLAY LIKE 'E'.   " AR00000001: 수금액은 0보다 크고 수금 전 잔액 이하여야 합니다.
      RETURN.
    ENDIF.
    IF lv_waers IS INITIAL.
      lv_waers = gw_rcp-waers.
    ELSEIF lv_waers <> gw_rcp-waers.
      MESSAGE s408(zmsga) DISPLAY LIKE 'E'.        " 통화가 다른 건은 한 번에 처리할 수 없습니다.
      RETURN.
    ENDIF.
    lv_sum = lv_sum + gw_rcp-arcam.
    INSERT gw_rcp-kunnr INTO TABLE lt_kunnr.
  ENDLOOP.

  IF lv_cnt = 0.
    MESSAGE s409(zmsga) WITH '수금' DISPLAY LIKE 'E'.    " 수금 목록이 비어 있습니다. (위 목록에서 체크 → 수금 목록에 추가)
    RETURN.
  ENDIF.
  IF p_rcpdt IS INITIAL.
    MESSAGE s020(zmsga) WITH '수금일' DISPLAY LIKE 'E'.       " 수금일을(를) 입력해 주십시오.
    RETURN.
  ENDIF.
  IF p_rcpdt > sy-datum.                                       " 실제 수금 기록 → 미래 날짜 불가
    MESSAGE s434(zmsga) WITH '수금일' DISPLAY LIKE 'E'.       " 수금일은(는) 오늘 이후 날짜로 입력할 수 없습니다.
    RETURN.
  ENDIF.
  SELECT SINGLE bnkac FROM ztfia00070 INTO lv_bnkac
    WHERE bnkac = p_rcpac.
  IF p_rcpac IS INITIAL OR sy-subrc <> 0.
    MESSAGE s410(zmsga) WITH '입금' DISPLAY LIKE 'E'.      " 입금계좌를 확인해 주십시오. (F4로 선택)
    RETURN.
  ENDIF.

  "─ 2. 확인 팝업
  WRITE lv_sum TO lv_amt CURRENCY lv_waers.
  CONDENSE lv_amt.
  lv_text = |{ p_rcpdt DATE = USER } 입금계좌 { p_rcpac }로 고객 { lines( lt_kunnr ) }곳, 채권 { lv_cnt }건, 총 { lv_amt } { lv_waers }을 수금 처리하시겠습니까?|.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '수금 등록'
      text_question         = lv_text
      text_button_1         = '수금'
      text_button_2         = '취소'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      OTHERS                = 1.
  IF sy-subrc <> 0 OR lv_answer <> '1'.
    MESSAGE s005(zmsga).           " 처리가 취소되었습니다.
    RETURN.
  ENDIF.

  "─ 3. 고객 단위로 저장 → COMMIT / ROLLBACK
  LOOP AT lt_kunnr INTO lv_kunnr.
    PERFORM rcp_customer USING    lv_kunnr
                         CHANGING lv_ok lv_err lv_rcpnr.

    IF lv_ok = 'X'.
      COMMIT WORK AND WAIT.
      lv_done = lv_done + 1.
      LOOP AT gt_rcp INTO gw_rcp WHERE rcpnr = lv_rcpnr.
        gw_rcp-stico = icon_led_green.
        gw_rcp-msg   = '수금 완료'.
        CLEAR ls_style.
        ls_style-fieldname = 'ARCAM'.
        ls_style-style     = cl_gui_alv_grid=>mc_style_disabled.
        INSERT ls_style INTO TABLE gw_rcp-celltab.
        MODIFY gt_rcp FROM gw_rcp.
      ENDLOOP.
    ELSE.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
      LOOP AT gt_rcp INTO gw_rcp WHERE kunnr = lv_kunnr
                                   AND ( rcpnr IS INITIAL OR rcpnr = lv_rcpnr ).
        CLEAR: gw_rcp-rcpnr, gw_rcp-clsta, gw_rcp-sttxt.
        gw_rcp-openbal = gw_rcp-balbf - gw_rcp-arcam.
        gw_rcp-stico   = icon_led_red.
        gw_rcp-msg     = lv_err.
        MODIFY gt_rcp FROM gw_rcp.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  "─ 4. 위 목록 다시 (수금누계·잔액 반영), 아래 결과 표시
  PERFORM get_data.
  PERFORM refresh_alv1.
  PERFORM refresh_alv2.

  MESSAGE s411(zmsga) WITH '수금' '고객' lv_done lv_fail.     " 수금 완료: 고객 n곳 / 실패 n곳
ENDFORM.
*&---------------------------------------------------------------------*
*& Form rcp_customer  - 고객 1곳: 수금 내역 1건 + 반제 n줄 + 채권 갱신 (COMMIT은 호출 쪽)
*&---------------------------------------------------------------------*
FORM rcp_customer USING    pv_kunnr TYPE ztcma00100-kunnr
                  CHANGING pv_ok    TYPE c
                           pv_err   TYPE string
                           pv_rcpnr TYPE ztfia00060-rcpnr.
  DATA: ls_rcp   TYPE ztfia00060,
        ls_arc   TYPE ztfia00040,
        ls_ar    TYPE ztcma00100,
        lv_arcnr TYPE ztfia00040-arcnr,
        lv_seq   TYPE ztfia00040-arcsq,
        lv_tabix TYPE sy-tabix.

  CLEAR: pv_ok, pv_err, pv_rcpnr.

  "─ 1. 수금 내역 (고객 1건)
  PERFORM next_rcpnr CHANGING ls_rcp-rcpnr.
  pv_rcpnr     = ls_rcp-rcpnr.
  ls_rcp-kunnr = pv_kunnr.
  ls_rcp-rcpdt = p_rcpdt.
  ls_rcp-rcpac = p_rcpac.
  LOOP AT gt_rcp INTO gw_rcp WHERE kunnr = pv_kunnr AND rcpnr IS INITIAL.
    ls_rcp-rcpam = ls_rcp-rcpam + gw_rcp-arcam.
    ls_rcp-waers = gw_rcp-waers.
  ENDLOOP.
  ls_rcp-ernam = sy-uname.
  ls_rcp-erdat = sy-datum.
  ls_rcp-erzet = sy-uzeit.

  INSERT ztfia00060 FROM ls_rcp.
  IF sy-subrc <> 0.
    pv_err = '수금 내역 저장 실패'.
    RETURN.
  ENDIF.

  "─ 2. 반제(채권마다 1줄, 반제번호 1개 + 순번) + 3. 채권 갱신
  PERFORM next_arcnr CHANGING lv_arcnr.

  LOOP AT gt_rcp INTO gw_rcp WHERE kunnr = pv_kunnr AND rcpnr IS INITIAL.
    lv_tabix = sy-tabix.
    lv_seq   = lv_seq + 1.

    CLEAR ls_arc.
    ls_arc-arcnr = lv_arcnr.
    ls_arc-arcsq = lv_seq.
    ls_arc-rcpnr = ls_rcp-rcpnr.
    ls_arc-arnum = gw_rcp-arnum.
    ls_arc-arcam = gw_rcp-arcam.
    ls_arc-arcdt = p_rcpdt.
    ls_arc-kunnr = pv_kunnr.
    ls_arc-waers = gw_rcp-waers.
    ls_arc-ernam = sy-uname.
    ls_arc-erdat = sy-datum.
    ls_arc-erzet = sy-uzeit.
    INSERT ztfia00040 FROM ls_arc.
    IF sy-subrc <> 0.
      pv_err = |{ gw_rcp-arnum } 반제 저장 실패|.
      RETURN.
    ENDIF.

    SELECT SINGLE * FROM ztcma00100 INTO ls_ar
      WHERE arnum = gw_rcp-arnum.
    IF sy-subrc <> 0.
      pv_err = |{ gw_rcp-arnum } 채권 없음|.
      RETURN.
    ENDIF.

    ls_ar-rcpbt = ls_ar-rcpbt + gw_rcp-arcam.
    IF ls_ar-rcpbt + ls_ar-adjbt >= ls_ar-dmbtr.
      ls_ar-clsta = gc_clsta_done.
      ls_ar-augdt = p_rcpdt.
    ELSE.
      ls_ar-clsta = gc_clsta_part.
    ENDIF.

    UPDATE ztcma00100
       SET rcpbt = ls_ar-rcpbt
           clsta = ls_ar-clsta
           augdt = ls_ar-augdt
           aenam = sy-uname
           aedat = sy-datum
           aezet = sy-uzeit
     WHERE arnum = ls_ar-arnum.
    IF sy-subrc <> 0.
      pv_err = |{ gw_rcp-arnum } 채권 갱신 실패|.
      RETURN.
    ENDIF.

    " 화면 행에 결과 (실패로 롤백되면 호출 쪽에서 되돌림)
    gw_rcp-rcpnr   = ls_rcp-rcpnr.
    gw_rcp-clsta   = ls_ar-clsta.
    PERFORM status_text USING ls_ar-clsta CHANGING gw_rcp-sttxt.
    gw_rcp-openbal = ls_ar-dmbtr - ls_ar-rcpbt - ls_ar-adjbt.
    MODIFY gt_rcp FROM gw_rcp INDEX lv_tabix.
  ENDLOOP.

  pv_ok = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form next_rcpnr  - 수금번호 (RCP + 7자리)
*&---------------------------------------------------------------------*
FORM next_rcpnr CHANGING pv_rcpnr TYPE ztfia00060-rcpnr.
  DATA: lv_max TYPE ztfia00060-rcpnr,
        lv_n   TYPE n LENGTH 7.

  SELECT MAX( rcpnr ) FROM ztfia00060 INTO lv_max
    WHERE rcpnr LIKE 'RCP%'.
  IF lv_max IS NOT INITIAL.
    lv_n = lv_max+3(7).
  ENDIF.
  lv_n = lv_n + 1.
  CONCATENATE 'RCP' lv_n INTO pv_rcpnr.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form next_arcnr  - 반제번호 (ARC + 7자리)
*&---------------------------------------------------------------------*
FORM next_arcnr CHANGING pv_arcnr TYPE ztfia00040-arcnr.
  DATA: lv_max TYPE ztfia00040-arcnr,
        lv_n   TYPE n LENGTH 7.

  SELECT MAX( arcnr ) FROM ztfia00040 INTO lv_max
    WHERE arcnr LIKE 'ARC%'.
  IF lv_max IS NOT INITIAL.
    lv_n = lv_max+3(7).
  ENDIF.
  lv_n = lv_n + 1.
  CONCATENATE 'ARC' lv_n INTO pv_arcnr.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_rcpac  - 입금계좌 F4 (은행명·계좌번호)
*&---------------------------------------------------------------------*
FORM f4_rcpac .
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
      dynprofield = 'P_RCPAC'
      value_org   = 'S'
    TABLES
      value_tab   = lt_f4
    EXCEPTIONS
      OTHERS      = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_kunnr  - 고객 F4 (번호 + 고객명, 배송처 중복 제거)
*&---------------------------------------------------------------------*
FORM f4_kunnr .
  TYPES: BEGIN OF ty_f4,
           kunnr TYPE ztcma00050-kunnr,
           name1 TYPE ztcma00050-name1,
         END OF ty_f4.
  DATA lt_f4 TYPE TABLE OF ty_f4.

  SELECT DISTINCT kunnr name1 FROM ztcma00050 INTO TABLE lt_f4
    ORDER BY kunnr.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'KUNNR'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_KUNNR'
      value_org   = 'S'
    TABLES
      value_tab   = lt_f4
    EXCEPTIONS
      OTHERS      = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_kunnr_text  - 고객 번호 옆 고객명
*&---------------------------------------------------------------------*
FORM set_kunnr_text .
  CLEAR gv_kunnm.
  CHECK p_kunnr IS NOT INITIAL.

  SELECT SINGLE name1 FROM ztcma00050 INTO gv_kunnm
    WHERE kunnr = p_kunnr.
  IF sy-subrc <> 0.
    gv_kunnm = '등록되지 않은 고객'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_bank_text  - 입금계좌 옆 은행명 + 계좌번호
*&---------------------------------------------------------------------*
FORM set_bank_text .
  DATA: lv_banka TYPE ztfia00070-banka,
        lv_bankn TYPE ztfia00070-bankn.

  CLEAR gv_bnktx.
  CHECK p_rcpac IS NOT INITIAL.

  SELECT SINGLE banka bankn FROM ztfia00070
    INTO (lv_banka, lv_bankn)
    WHERE bnkac = p_rcpac.
  IF sy-subrc = 0.
    gv_bnktx = |{ lv_banka } { lv_bankn }|.
  ELSE.
    gv_bnktx = '등록되지 않은 계좌'.
  ENDIF.
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
*& Form toggle_sum  - [고객별 합계 보기/끄기] 수금액 총합계 + 고객별 소계 켜고 끄기
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

  " 1) 수금액 열 합계 켜기/끄기
  go_alv2->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = lt_fcat ).
  LOOP AT lt_fcat INTO ls_fcat WHERE fieldname = 'ARCAM'.
    ls_fcat-do_sum = gv_sumon.
    MODIFY lt_fcat FROM ls_fcat.
  ENDLOOP.
  go_alv2->set_frontend_fieldcatalog( it_fieldcatalog = lt_fcat ).

  " 2) 고객 정렬에 소계 켜기/끄기 (정렬이 없어졌으면 다시 만듦)
  go_alv2->get_sort_criteria( IMPORTING et_sort = lt_sort ).
  LOOP AT lt_sort INTO ls_sort WHERE fieldname = 'KUNNR'.
    ls_sort-subtot = gv_sumon.
    MODIFY lt_sort FROM ls_sort.
  ENDLOOP.
  IF sy-subrc <> 0 AND gv_sumon = abap_true.
    CLEAR ls_sort.
    ls_sort-spos      = 1.
    ls_sort-fieldname = 'KUNNR'.
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
*&---------------------------------------------------------------------*
*& Form confirm_exit  - Back·Exit·Cancel → 종료 확인 팝업
*&   수금 목록에 아직 등록 안 한 건이 있으면 경고 문구
*&---------------------------------------------------------------------*
FORM confirm_exit .
  DATA: lv_answer TYPE c LENGTH 1,
        lv_text   TYPE string.

  READ TABLE gt_rcp TRANSPORTING NO FIELDS WITH KEY rcpnr = space.
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
