"& Include          ZLSDA00050_F01
"&---------------------------------------------------------------------*


"&---------------------------------------------------------------------*
"& Form GET_DATA
"&---------------------------------------------------------------------*
FORM get_data .

  DATA:
    lr_kunnr TYPE RANGE OF ztcma00050-kunnr.

  CLEAR gt_cust.

  " 고객번호 : From만 → 1건 / From~To → 범위 / To만 → To까지 / 둘 다 없음 → 전체
  IF gv_s_kunfr IS NOT INITIAL AND gv_s_kunto IS NOT INITIAL.
    lr_kunnr = VALUE #( ( sign = 'I' option = 'BT' low = gv_s_kunfr high = gv_s_kunto ) ).
  ELSEIF gv_s_kunfr IS NOT INITIAL.
    lr_kunnr = VALUE #( ( sign = 'I' option = 'EQ' low = gv_s_kunfr ) ).
  ELSEIF gv_s_kunto IS NOT INITIAL.
    lr_kunnr = VALUE #( ( sign = 'I' option = 'LE' low = gv_s_kunto ) ).
  ENDIF.

  SELECT a~kunnr,
         a~adrcde,
         a~name1,
         a~land1,
         t~landx,
         a~addr1,
         a~telf1,
         a~smail,
         a~zterm,
         a~waers,
         a~trdyn,
         a~blkyn,
         a~actyn,
         a~inrsn,
         a~erdat,
         a~erzet,
         a~ernam,
         a~aedat,
         a~aezet,
         a~aenam
    FROM ztcma00050 AS a
    LEFT OUTER JOIN t005t AS t
      ON  t~land1 = a~land1
      AND t~spras = @sy-langu
   WHERE a~kunnr IN @lr_kunnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_cust.

  " 고객 상태
  CASE 'X'.
    WHEN rb_norm.                                   " 거래 가능
      DELETE gt_cust WHERE actyn = 'N' OR blkyn = 'Y'.
    WHEN rb_blck.                                   " 거래 정지
      DELETE gt_cust WHERE actyn = 'N' OR blkyn <> 'Y'.
    WHEN rb_clos.                                   " 거래 종료
      DELETE gt_cust WHERE actyn <> 'N'.
  ENDCASE.

  " 상태 Icon / 행 색상
  LOOP AT gt_cust INTO gs_cust.

    CLEAR: gs_cust-status,
           gs_cust-stat_txt,
           gs_cust-line_color.

    IF gs_cust-actyn = 'N'.
      gs_cust-status     = icon_led_inactive.
      gs_cust-stat_txt   = '거래 종료'.
      gs_cust-line_color = 'C200'.          " 회색 : 거래 종료
    ELSEIF gs_cust-blkyn = 'Y'.
      gs_cust-status     = icon_locked.
      gs_cust-stat_txt   = '거래 정지'.
      gs_cust-line_color = 'C610'.          " 빨강 : 거래 정지
    ELSE.
      gs_cust-status     = icon_led_green.
      gs_cust-stat_txt   = '거래 가능'.
    ENDIF.

    MODIFY gt_cust FROM gs_cust.
    CLEAR gs_cust.

  ENDLOOP.

  SORT gt_cust BY kunnr adrcde.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form DISPLAY_ALV
"&---------------------------------------------------------------------*
FORM display_alv .

  DATA:
    ls_stable TYPE lvc_s_stbl.

  IF go_cont IS INITIAL.

    CREATE OBJECT go_cont
      EXPORTING
        container_name = 'CC_0100'.

    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_cont.

    PERFORM set_fieldcat.
    PERFORM set_layout.
    PERFORM set_sort.
    PERFORM set_toolbar_exclude.

    CREATE OBJECT go_handler.
    SET HANDLER go_handler->handle_toolbar      FOR go_grid.
    SET HANDLER go_handler->handle_user_command FOR go_grid.

    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_layo
        it_toolbar_excluding = gt_excl
      CHANGING
        it_outtab            = gt_cust
        it_fieldcatalog      = gt_fcat
        it_sort              = gt_sort.

  ELSE.

    ls_stable-row = 'X'.
    ls_stable-col = 'X'.

    CALL METHOD go_grid->refresh_table_display
      EXPORTING
        is_stable = ls_stable.

  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_FIELDCAT
"&---------------------------------------------------------------------*
FORM set_fieldcat .

  CLEAR gt_fcat.

  " 길이 : 팀 ALV 컬럼 길이 표준
  " 순서 : 상태 → 고객 상태 → 고객번호 → 고객명 → 배송처번호
  " 키 열(마지막에서 두 번째 값)을 ' ' 로 해야 ALV가 앞으로 고정하지 않는다
  PERFORM add_fcat USING 'STATUS'   '상태'       4  ' ' 'X'.
  PERFORM add_fcat USING 'STAT_TXT' '고객 상태'  10 ' ' 'X'.
  PERFORM add_fcat USING 'KUNNR'    '고객번호'   12 ' ' ' '.
  PERFORM add_fcat USING 'NAME1'    '고객명'     20 ' ' ' '.
  PERFORM add_fcat USING 'ADRCDE'   '배송처번호' 12 ' ' ' '.
  PERFORM add_fcat USING 'LAND1'    '국가'       5  ' ' 'X'.
  PERFORM add_fcat USING 'LANDX'    '국가명'     10 ' ' ' '.
  PERFORM add_fcat USING 'ADDR1'    '주소'       30 ' ' ' '.
  PERFORM add_fcat USING 'TELF1'    '전화번호'   15 ' ' ' '.
  PERFORM add_fcat USING 'SMAIL'    '이메일'     30 ' ' ' '.
  PERFORM add_fcat USING 'ZTERM'    '지급조건'   5  ' ' 'X'.
  PERFORM add_fcat USING 'WAERS'    '통화'       5  ' ' 'X'.
  PERFORM add_fcat USING 'INRSN'    '특이사항'   30 ' ' ' '.
  PERFORM add_fcat USING 'ERDAT'    '생성일'     10 ' ' 'X'.
  PERFORM add_fcat USING 'ERNAM'    '생성자'     12 ' ' ' '.
  PERFORM add_fcat USING 'AEDAT'    '변경일'     10 ' ' 'X'.
  PERFORM add_fcat USING 'AENAM'    '변경자'     12 ' ' ' '.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form ADD_FCAT
"&---------------------------------------------------------------------*
FORM add_fcat USING pv_field
                    pv_text
                    pv_len
                    pv_key
                    pv_center.

  CLEAR gs_fcat.

  gs_fcat-fieldname = pv_field.
  gs_fcat-coltext   = pv_text.
  gs_fcat-scrtext_s = pv_text.
  gs_fcat-scrtext_m = pv_text.
  gs_fcat-scrtext_l = pv_text.
  gs_fcat-outputlen = pv_len.
  gs_fcat-key       = pv_key.

  IF pv_center = 'X'.
    gs_fcat-just = 'C'.
  ENDIF.

  CASE pv_field.
    WHEN 'STATUS'.
      gs_fcat-icon = 'X'.
    WHEN 'STAT_TXT'.
      " 화면용 텍스트 (DDIC 참조 없음)
    WHEN 'LANDX'.
      gs_fcat-ref_table = 'T005T'.
      gs_fcat-ref_field = 'LANDX'.
    WHEN OTHERS.
      gs_fcat-ref_table = 'ZTCMA00050'.     " 날짜·통화 등 DDIC 형식 그대로 출력
      gs_fcat-ref_field = pv_field.
  ENDCASE.

  APPEND gs_fcat TO gt_fcat.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_LAYOUT
"&---------------------------------------------------------------------*
FORM set_layout .

  CLEAR gs_layo.

  gs_layo-zebra      = 'X'.
  gs_layo-sel_mode   = 'A'.
  gs_layo-info_fname = 'LINE_COLOR'.
  gs_layo-grid_title = |고객 목록 ({ lines( gt_cust ) }건)|.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_SORT
"&---------------------------------------------------------------------*
FORM set_sort .

  DATA:
    ls_sort TYPE lvc_s_sort.

  CLEAR gt_sort.

  ls_sort-spos      = 1.
  ls_sort-fieldname = 'KUNNR'.
  ls_sort-up        = 'X'.
  APPEND ls_sort TO gt_sort.

  CLEAR ls_sort.
  ls_sort-spos      = 2.
  ls_sort-fieldname = 'ADRCDE'.
  ls_sort-up        = 'X'.
  APPEND ls_sort TO gt_sort.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_TOOLBAR_EXCLUDE
"&---------------------------------------------------------------------*
FORM set_toolbar_exclude .

  CLEAR gt_excl.

  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row    TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row    TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row    TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy          TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row      TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut           TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste         TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo          TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_check             TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_refresh           TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_graph             TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_info              TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_views             TO gt_excl.

  " 사용하지 않는 표준 버튼 숨김 (남기는 것: 정렬, 필터, 엑셀 내보내기)
  APPEND cl_gui_alv_grid=>mc_fc_detail            TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_sum               TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_mb_sum               TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_subtot            TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_mb_subtot            TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_print             TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_print_back        TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_print_prev        TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_mb_view              TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_current_variant   TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_maintain_variant  TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_load_variant      TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_save_variant      TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_find              TO gt_excl.
  APPEND cl_gui_alv_grid=>mc_fc_find_more         TO gt_excl.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form REFRESH_DATA
"&---------------------------------------------------------------------*
FORM refresh_data .

  DATA:
    ls_stable TYPE lvc_s_stbl.

  PERFORM get_data.

  CHECK go_grid IS BOUND.

  " ALV 제목 건수 갱신
  gs_layo-grid_title = |고객 목록 ({ lines( gt_cust ) }건)|.
  CALL METHOD go_grid->set_frontend_layout
    EXPORTING
      is_layout = gs_layo.

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.

  CALL METHOD go_grid->refresh_table_display
    EXPORTING
      is_stable = ls_stable.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form GET_SELECTED_ROW
"&---------------------------------------------------------------------*
"  1행만 선택했을 때 해당 행을 돌려줌
"&---------------------------------------------------------------------*
FORM get_selected_row CHANGING cs_cust TYPE ty_cust
                               cv_ok   TYPE char1.

  DATA:
    lt_rows TYPE lvc_t_row,
    ls_row  TYPE lvc_s_row.

  CLEAR: cs_cust,
         cv_ok.

  CALL METHOD go_grid->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  IF lines( lt_rows ) <> 1.
    MESSAGE s231(zmsga) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO ls_row INDEX 1.
  READ TABLE gt_cust INTO cs_cust INDEX ls_row-index.

  IF sy-subrc = 0.
    cv_ok = 'X'.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form LOCK_TABLE / UNLOCK_TABLE
"&---------------------------------------------------------------------*
"  채번·저장 중 다른 사용자와 겹치지 않도록 고객 마스터 잠금
"&---------------------------------------------------------------------*
FORM lock_table CHANGING cv_ok TYPE char1.

  CLEAR cv_ok.

  CALL FUNCTION 'ENQUEUE_E_TABLE'
    EXPORTING
      tabname        = 'ZTCMA00050'
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  IF sy-subrc <> 0.
    MESSAGE i245(zmsga).
    RETURN.
  ENDIF.

  cv_ok = 'X'.

ENDFORM.

FORM unlock_table .

  CALL FUNCTION 'DEQUEUE_E_TABLE'
    EXPORTING
      tabname = 'ZTCMA00050'.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form GET_NEXT_KUNNR
"&---------------------------------------------------------------------*
"  고객번호 : C + 9자리 (C000000006 ...)
"&---------------------------------------------------------------------*
FORM get_next_kunnr CHANGING cv_kunnr TYPE ztcma00050-kunnr.

  DATA:
    lv_max TYPE ztcma00050-kunnr,
    lv_num TYPE n LENGTH 9.

  CLEAR cv_kunnr.

  SELECT MAX( kunnr )
    FROM ztcma00050
   WHERE kunnr LIKE 'C%'
    INTO @lv_max.

  IF lv_max IS NOT INITIAL.
    lv_num = lv_max+1(9).
  ENDIF.

  lv_num = lv_num + 1.

  cv_kunnr = |C{ lv_num }|.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form GET_NEXT_ADRCDE
"&---------------------------------------------------------------------*
"  배송처번호 : SHP + 7자리 (SHP0000003 ...) - 전체 고객 통틀어 유일
"&---------------------------------------------------------------------*
FORM get_next_adrcde CHANGING cv_adrcde TYPE ztcma00050-adrcde.

  DATA:
    lv_max TYPE ztcma00050-adrcde,
    lv_num TYPE n LENGTH 7.

  CLEAR cv_adrcde.

  SELECT MAX( adrcde )
    FROM ztcma00050
   WHERE adrcde LIKE 'SHP%'
    INTO @lv_max.

  IF lv_max IS NOT INITIAL.
    lv_num = lv_max+3(7).
  ENDIF.

  lv_num = lv_num + 1.

  cv_adrcde = |SHP{ lv_num }|.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form POPUP_INPUT
"&---------------------------------------------------------------------*
"  pv_mode : N 신규 고객 / A 배송처 추가 / C 변경
"  검증 오류가 있으면 입력값을 유지한 채 팝업을 다시 띄움
"&---------------------------------------------------------------------*
FORM popup_input USING    pv_mode TYPE char1
                 CHANGING cs_data TYPE ztcma00050
                          cv_ok   TYPE char1.

  DATA:
    lt_fields TYPE TABLE OF sval,
    ls_field  TYPE sval,
    lv_title  TYPE c LENGTH 40,
    lv_rc     TYPE c LENGTH 1,
    lv_err    TYPE c LENGTH 1.

  FIELD-SYMBOLS:
    <lv_value> TYPE any.

  CLEAR cv_ok.

  CASE pv_mode.
    WHEN 'N'.
      lv_title = '신규 고객 등록'(t01).
    WHEN 'A'.
      lv_title = '배송처 추가'(t02).
    WHEN 'C'.
      lv_title = '고객 정보 변경'(t03).
  ENDCASE.

  " 팝업 필드 구성
  DEFINE _add_field.
    CLEAR ls_field.
    ls_field-tabname    = 'ZTCMA00050'.
    ls_field-fieldname  = &1.
    ls_field-fieldtext  = &2.
    ls_field-field_obl  = &3.
    ls_field-field_attr = &4.
    APPEND ls_field TO lt_fields.
  END-OF-DEFINITION.

  IF pv_mode <> 'N'.
    _add_field 'KUNNR'  '고객번호'   ' ' '02'.
  ENDIF.

  IF pv_mode = 'C'.
    _add_field 'ADRCDE' '배송처번호' ' ' '02'.
  ENDIF.

  _add_field 'NAME1' '고객명'   'X' ' '.
  _add_field 'LAND1' '국가'     'X' ' '.
  _add_field 'ADDR1' '주소'     'X' ' '.
  _add_field 'TELF1' '전화번호' 'X' ' '.
  _add_field 'SMAIL' '이메일'   'X' ' '.
  _add_field 'ZTERM' '지급조건' 'X' ' '.
  _add_field 'WAERS' '통화'     'X' ' '.

  IF pv_mode = 'C'.
    _add_field 'ACTYN' '사용여부(N=거래 종료)' 'X' ' '.
  ENDIF.

  _add_field 'INRSN' '특이사항' ' ' ' '.

  DO.

    " 현재 값 → 팝업
    LOOP AT lt_fields INTO ls_field.
      ASSIGN COMPONENT ls_field-fieldname OF STRUCTURE cs_data TO <lv_value>.
      IF sy-subrc = 0.
        ls_field-value = <lv_value>.
        MODIFY lt_fields FROM ls_field.
      ENDIF.
    ENDLOOP.

    CLEAR lv_rc.

    CALL FUNCTION 'POPUP_GET_VALUES'
      EXPORTING
        popup_title     = lv_title
      IMPORTING
        returncode      = lv_rc
      TABLES
        fields          = lt_fields
      EXCEPTIONS
        error_in_fields = 1
        OTHERS          = 2.

    IF sy-subrc <> 0 OR lv_rc = 'A'.
      MESSAGE s243(zmsga).
      RETURN.
    ENDIF.

    " 팝업 → 구조 (입력 가능한 필드만)
    LOOP AT lt_fields INTO ls_field WHERE field_attr <> '02'.
      ASSIGN COMPONENT ls_field-fieldname OF STRUCTURE cs_data TO <lv_value>.
      IF sy-subrc = 0.
        <lv_value> = ls_field-value.
      ENDIF.
    ENDLOOP.

    TRANSLATE cs_data-land1 TO UPPER CASE.
    TRANSLATE cs_data-waers TO UPPER CASE.
    TRANSLATE cs_data-zterm TO UPPER CASE.
    TRANSLATE cs_data-actyn TO UPPER CASE.

    " 앞뒤 공백 제거 / 이메일은 소문자로 통일
    CONDENSE cs_data-name1.
    CONDENSE cs_data-addr1.
    CONDENSE cs_data-telf1 NO-GAPS.
    CONDENSE cs_data-smail NO-GAPS.
    TRANSLATE cs_data-smail TO LOWER CASE.

    PERFORM validate_input USING    pv_mode
                                    cs_data
                           CHANGING lv_err.

    IF lv_err IS INITIAL.
      cv_ok = 'X'.
      EXIT.
    ENDIF.

  ENDDO.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form VALIDATE_INPUT
"&---------------------------------------------------------------------*
FORM validate_input USING    pv_mode TYPE char1
                             ps_data TYPE ztcma00050
                    CHANGING cv_err  TYPE char1.

  DATA:
    lv_exist TYPE c LENGTH 1,
    lv_tel   TYPE string,
    lv_mail  TYPE string.

  CLEAR cv_err.

  " 1) 필수값
  IF ps_data-name1 IS INITIAL.
    MESSAGE i232(zmsga) WITH '고객명'.
    cv_err = 'X'. RETURN.
  ENDIF.

  IF ps_data-land1 IS INITIAL.
    MESSAGE i232(zmsga) WITH '국가'.
    cv_err = 'X'. RETURN.
  ENDIF.

  IF ps_data-addr1 IS INITIAL.
    MESSAGE i232(zmsga) WITH '주소'.
    cv_err = 'X'. RETURN.
  ENDIF.

  IF ps_data-telf1 IS INITIAL.
    MESSAGE i232(zmsga) WITH '전화번호'.
    cv_err = 'X'. RETURN.
  ENDIF.

  IF ps_data-smail IS INITIAL.
    MESSAGE i232(zmsga) WITH '이메일'.
    cv_err = 'X'. RETURN.
  ENDIF.

  IF ps_data-zterm IS INITIAL.
    MESSAGE i232(zmsga) WITH '지급조건'.
    cv_err = 'X'. RETURN.
  ENDIF.

  IF ps_data-waers IS INITIAL.
    MESSAGE i232(zmsga) WITH '통화'.
    cv_err = 'X'. RETURN.
  ENDIF.

  " 1-1) 최소 길이 : 고객명 / 주소 2자 이상
  IF strlen( ps_data-name1 ) < 2.
    MESSAGE i254(zmsga) WITH '고객명'.
    cv_err = 'X'. RETURN.
  ENDIF.

  IF strlen( ps_data-addr1 ) < 2.
    MESSAGE i254(zmsga) WITH '주소'.
    cv_err = 'X'. RETURN.
  ENDIF.

  " 2) 국가 / 통화 존재 여부
  CLEAR lv_exist.
  SELECT SINGLE @abap_true
    FROM t005
   WHERE land1 = @ps_data-land1
    INTO @lv_exist.

  IF lv_exist IS INITIAL.
    MESSAGE i233(zmsga) WITH ps_data-land1.
    cv_err = 'X'. RETURN.
  ENDIF.

  CLEAR lv_exist.
  SELECT SINGLE @abap_true
    FROM tcurc
   WHERE waers = @ps_data-waers
    INTO @lv_exist.

  IF lv_exist IS INITIAL.
    MESSAGE i234(zmsga) WITH ps_data-waers.
    cv_err = 'X'. RETURN.
  ENDIF.

  " 2-1) 지급조건 존재 여부 : 표준 T052 또는 기존 고객이 사용 중인 코드
  CLEAR lv_exist.
  SELECT SINGLE @abap_true
    FROM t052
   WHERE zterm = @ps_data-zterm
    INTO @lv_exist.

  IF lv_exist IS INITIAL.
    SELECT SINGLE @abap_true
      FROM ztcma00050
     WHERE zterm = @ps_data-zterm
       AND NOT ( kunnr  = @ps_data-kunnr
             AND adrcde = @ps_data-adrcde )
      INTO @lv_exist.
  ENDIF.

  IF lv_exist IS INITIAL.
    MESSAGE i252(zmsga) WITH ps_data-zterm.
    cv_err = 'X'. RETURN.
  ENDIF.

  " 3) 전화번호 형식 : 0으로 시작-3~4자리-4자리 (예: 02-555-0006)
  lv_tel = ps_data-telf1.

  FIND REGEX '^0[0-9]{1,2}-[0-9]{3,4}-[0-9]{4}$' IN lv_tel.
  IF sy-subrc <> 0.
    MESSAGE i253(zmsga).
    cv_err = 'X'. RETURN.
  ENDIF.

  " 4) 이메일 형식
  lv_mail = ps_data-smail.

  FIND REGEX '^[^@ ]+@[^@ ]+\.[^@ ]+$' IN lv_mail.
  IF sy-subrc <> 0.
    MESSAGE i235(zmsga).
    cv_err = 'X'. RETURN.
  ENDIF.

  " 5) 사용여부 (변경 시)
  IF pv_mode = 'C'
 AND ps_data-actyn <> 'Y'
 AND ps_data-actyn <> 'N'.
    MESSAGE i244(zmsga).
    cv_err = 'X'. RETURN.
  ENDIF.

  " 6) 중복 : 같은 고객명 + 같은 주소 (자기 자신 제외)
  SELECT SINGLE kunnr, adrcde
    FROM ztcma00050
   WHERE name1 = @ps_data-name1
     AND addr1 = @ps_data-addr1
     AND NOT ( kunnr  = @ps_data-kunnr
           AND adrcde = @ps_data-adrcde )
    INTO @DATA(ls_dup).

  IF sy-subrc = 0.
    MESSAGE i237(zmsga) WITH ls_dup-kunnr ls_dup-adrcde.
    cv_err = 'X'. RETURN.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form CREATE_CUSTOMER
"&---------------------------------------------------------------------*
FORM create_customer .

  DATA:
    ls_new  TYPE ztcma00050,
    lv_ok   TYPE c LENGTH 1,
    lv_lock TYPE c LENGTH 1.

  CLEAR ls_new.

  " 기본값
  ls_new-land1 = 'KR'.
  ls_new-waers = 'KRW'.
  ls_new-trdyn = 'Y'.
  ls_new-blkyn = 'N'.
  ls_new-actyn = 'Y'.

  PERFORM popup_input USING 'N' CHANGING ls_new lv_ok.
  CHECK lv_ok = 'X'.

  PERFORM lock_table CHANGING lv_lock.
  CHECK lv_lock = 'X'.

  PERFORM get_next_kunnr  CHANGING ls_new-kunnr.
  PERFORM get_next_adrcde CHANGING ls_new-adrcde.

  ls_new-erdat = sy-datum.
  ls_new-erzet = sy-uzeit.
  ls_new-ernam = sy-uname.

  INSERT ztcma00050 FROM ls_new.

  IF sy-subrc = 0.
    COMMIT WORK.
    PERFORM unlock_table.
    MESSAGE s238(zmsga) WITH ls_new-kunnr ls_new-adrcde.
  ELSE.
    ROLLBACK WORK.
    PERFORM unlock_table.
    MESSAGE i240(zmsga).
    RETURN.
  ENDIF.

  PERFORM refresh_data.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form CHANGE_CUSTOMER
"&---------------------------------------------------------------------*
FORM change_customer .

  DATA:
    ls_sel  TYPE ty_cust,
    ls_old  TYPE ztcma00050,
    ls_new  TYPE ztcma00050,
    lv_ok   TYPE c LENGTH 1,
    lv_lock TYPE c LENGTH 1.

  PERFORM get_selected_row CHANGING ls_sel lv_ok.
  CHECK lv_ok = 'X'.

  CLEAR ls_old.
  SELECT SINGLE *
    FROM ztcma00050
   WHERE kunnr  = @ls_sel-kunnr
     AND adrcde = @ls_sel-adrcde
    INTO @ls_old.

  IF sy-subrc <> 0.
    MESSAGE s230(zmsga) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  ls_new = ls_old.

  PERFORM popup_input USING 'C' CHANGING ls_new lv_ok.
  CHECK lv_ok = 'X'.

  IF ls_new = ls_old.
    MESSAGE s247(zmsga).
    RETURN.
  ENDIF.

  PERFORM lock_table CHANGING lv_lock.
  CHECK lv_lock = 'X'.

  ls_new-aedat = sy-datum.
  ls_new-aezet = sy-uzeit.
  ls_new-aenam = sy-uname.

  UPDATE ztcma00050 FROM ls_new.

  IF sy-subrc = 0.
    COMMIT WORK.
    PERFORM unlock_table.
    MESSAGE s239(zmsga) WITH ls_new-kunnr ls_new-adrcde.
  ELSE.
    ROLLBACK WORK.
    PERFORM unlock_table.
    MESSAGE i240(zmsga).
    RETURN.
  ENDIF.

  PERFORM refresh_data.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_BLOCK
"&---------------------------------------------------------------------*
"  pv_block : Y 거래정지 / N 정지 해제
"  고객 단위 처리 (해당 고객의 모든 배송처)
"  거래정지 시 거래가능여부 N → SD01 판매오더 생성에서 자동 차단
"&---------------------------------------------------------------------*
FORM set_block USING pv_block TYPE char1.

  DATA:
    ls_sel    TYPE ty_cust,
    lv_ok     TYPE c LENGTH 1,
    lv_lock   TYPE c LENGTH 1,
    lv_trdyn  TYPE ztcma00050-trdyn,
    lv_text   TYPE string,        " 확인 팝업 문구 (SD04 와 같이 string 사용)
    lv_answer TYPE c LENGTH 1.

  PERFORM get_selected_row CHANGING ls_sel lv_ok.
  CHECK lv_ok = 'X'.

  IF pv_block = 'Y' AND ls_sel-blkyn = 'Y'.
    MESSAGE s248(zmsga) DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  IF pv_block = 'N' AND ls_sel-blkyn <> 'Y'.
    MESSAGE s249(zmsga) DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " 확인 팝업 문구는 SD04 와 같이 메시지(SE91)로 만든다
  "   258 & 고객을 거래정지 하시겠습니까?
  "   259 & 고객의 거래정지를 해제하시겠습니까?
  IF pv_block = 'Y'.
    lv_trdyn = 'N'.
    MESSAGE s258(zmsga) WITH ls_sel-kunnr INTO lv_text.
  ELSE.
    lv_trdyn = 'Y'.
    MESSAGE s259(zmsga) WITH ls_sel-kunnr INTO lv_text.
  ENDIF.

  " POPUP_CONTINUE_YES_NO : textline1 의 글이 그대로 팝업 본문에 표시된다.
  " answer = 'J' 가 '예', 'N' 이 '아니오'
  CALL FUNCTION 'POPUP_CONTINUE_YES_NO'
    EXPORTING
      defaultoption = 'N'
      textline1     = lv_text
      titel         = '거래정지 처리'
    IMPORTING
      answer        = lv_answer
    EXCEPTIONS
      OTHERS        = 1.

  IF sy-subrc <> 0 OR lv_answer <> 'J'.
    MESSAGE s243(zmsga).
    RETURN.
  ENDIF.

  PERFORM lock_table CHANGING lv_lock.
  CHECK lv_lock = 'X'.

  UPDATE ztcma00050
     SET blkyn = @pv_block,
         trdyn = @lv_trdyn,
         aedat = @sy-datum,
         aezet = @sy-uzeit,
         aenam = @sy-uname
   WHERE kunnr = @ls_sel-kunnr.

  IF sy-subrc = 0.
    COMMIT WORK.
    PERFORM unlock_table.
    IF pv_block = 'Y'.
      MESSAGE s241(zmsga) WITH ls_sel-kunnr.
    ELSE.
      MESSAGE s242(zmsga) WITH ls_sel-kunnr.
    ENDIF.
  ELSE.
    ROLLBACK WORK.
    PERFORM unlock_table.
    MESSAGE i240(zmsga).
    RETURN.
  ENDIF.

  PERFORM refresh_data.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form DELETE_CUSTOMER
"&---------------------------------------------------------------------*
"  선택한 1행(고객번호 + 배송처번호)을 ZTCMA00050 에서 삭제
"  이미 거래에 사용된 고객은 삭제하지 않고 거래 정지를 안내
"  (판매오더 ZTSDA00010 / 출고 ZTSDA00030 / 청구 ZTSDA00050 의 KUNNR 확인)
"  SE91 ZMSGA 메시지 256, 257 을 먼저 등록해야 한다
"      256  고객 &은(는) 거래 이력이 있어 삭제할 수 없습니다. 거래 정지를 사용하세요.
"      257  고객 & / 배송처 &이(가) 삭제되었습니다.
"&---------------------------------------------------------------------*
FORM delete_customer.

  DATA: ls_sel    TYPE ty_cust,                     " 선택한 행
        lv_ok     TYPE c LENGTH 1,                  " 행 선택 성공 여부
        lv_lock   TYPE c LENGTH 1,                  " 테이블 잠금 성공 여부
        lv_ref    TYPE c LENGTH 20,                 " 거래 이력 확인용 문서번호
        lv_text   TYPE string,                      " 확인 팝업 문구
        lv_answer TYPE c LENGTH 1.                  " 팝업 답변 (1 = 예)

  " 1) 행을 1개만 선택했는지 확인
  PERFORM get_selected_row CHANGING ls_sel lv_ok.
  CHECK lv_ok = 'X'.

  " 2) 거래 이력 확인 : 판매오더 / 출고 / 청구 중 하나라도 있으면 삭제 불가
  SELECT SINGLE vbeln FROM ztsda00010
    WHERE kunnr = @ls_sel-kunnr
    INTO @lv_ref.
  IF sy-subrc <> 0.
    SELECT SINGLE vbeln FROM ztsda00030
      WHERE kunnr = @ls_sel-kunnr
      INTO @lv_ref.
  ENDIF.
  IF sy-subrc <> 0.
    SELECT SINGLE bilno FROM ztsda00050
      WHERE kunnr = @ls_sel-kunnr
      INTO @lv_ref.
  ENDIF.

  IF sy-subrc = 0.
    MESSAGE s256(zmsga) WITH ls_sel-kunnr DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 3) 삭제 확인 팝업 (기본 버튼 = 아니오)
  " 260 고객 & / 배송처 &을(를) 삭제하시겠습니까? 삭제 후에는 복구할 수 없습니다.
  MESSAGE s260(zmsga) WITH ls_sel-kunnr ls_sel-adrcde INTO lv_text.

  " 본문 2줄: 1줄 = 삭제 대상 고객/배송처, 2줄 = 복구 불가 안내 (각 70자 이내)
  lv_text = |고객 { ls_sel-kunnr } / 배송처 { ls_sel-adrcde } 을(를) 삭제하시겠습니까?|.

  CALL FUNCTION 'POPUP_CONTINUE_YES_NO'
    EXPORTING
      defaultoption = 'N'
      textline1     = lv_text
      textline2     = '삭제 후에는 복구할 수 없습니다.'
      titel         = '고객 삭제'
    IMPORTING
      answer        = lv_answer
    EXCEPTIONS
      OTHERS        = 1.

  IF sy-subrc <> 0 OR lv_answer <> 'J'.
    MESSAGE s243(zmsga).             " 작업이 취소되었습니다.
    RETURN.
  ENDIF.

  " 4) 다른 사용자와 겹치지 않도록 고객 마스터 잠금
  PERFORM lock_table CHANGING lv_lock.
  CHECK lv_lock = 'X'.

  " 5) 삭제 (고객번호 + 배송처번호 = 테이블 키, 해당 1건만)
  DELETE FROM ztcma00050
    WHERE kunnr  = @ls_sel-kunnr
      AND adrcde = @ls_sel-adrcde.

  " 6) 결과 확인 : 성공만 COMMIT, 실패는 ROLLBACK
  IF sy-subrc = 0.
    COMMIT WORK.
    PERFORM unlock_table.
    MESSAGE s257(zmsga) WITH ls_sel-kunnr ls_sel-adrcde.
  ELSE.
    ROLLBACK WORK.
    PERFORM unlock_table.
    MESSAGE i240(zmsga).             " 저장 중 오류가 발생했습니다.
    RETURN.
  ENDIF.

  " 7) 목록 새로고침
  PERFORM refresh_data.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form F4_CUSTOMER
"&---------------------------------------------------------------------*
"  고객번호 검색도움말 (SD01 F4_KUNNR 과 동일 방식)
"  선택하면 고객번호 + 옆 고객명 칸을 같이 채움
"  pv_kfield : 고객번호 화면필드 (GV_S_KUNFR / GV_S_KUNTO)
"  pv_nfield : 고객명   화면필드 (GV_S_NAMFR / GV_S_NAMTO)
"&---------------------------------------------------------------------*
FORM f4_customer USING pv_kfield TYPE csequence
                       pv_nfield TYPE csequence.

  TYPES:
    BEGIN OF ty_kunnr_f4,
      kunnr TYPE ztcma00050-kunnr,
      name1 TYPE ztcma00050-name1,
    END OF ty_kunnr_f4.

  DATA:
    lt_kunnr_f4 TYPE STANDARD TABLE OF ty_kunnr_f4,
    lt_return   TYPE STANDARD TABLE OF ddshretval,
    ls_return   TYPE ddshretval,
    lt_dynp     TYPE STANDARD TABLE OF dynpread,
    ls_dynp     TYPE dynpread,
    lv_kunnr    TYPE ztcma00050-kunnr,
    lv_name1    TYPE ztcma00050-name1.

  FIELD-SYMBOLS:
    <lv_kunnr> TYPE any,
    <lv_name1> TYPE any.

  " 관리 화면이라 상태와 관계없이 전체 고객
  SELECT DISTINCT kunnr, name1
    FROM ztcma00050
   ORDER BY kunnr
    INTO TABLE @lt_kunnr_f4.

  IF lt_kunnr_f4 IS INITIAL.
    MESSAGE s230(zmsga).
    RETURN.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'KUNNR'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_kfield
      value_org       = 'S'
    TABLES
      value_tab       = lt_kunnr_f4
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  lv_kunnr = ls_return-fieldval.

  CLEAR lv_name1.
  SELECT SINGLE name1
    FROM ztcma00050
   WHERE kunnr = @lv_kunnr
    INTO @lv_name1.

  " 전역 변수에도 반영
  ASSIGN (pv_kfield) TO <lv_kunnr>.
  IF sy-subrc = 0.
    <lv_kunnr> = lv_kunnr.
  ENDIF.

  ASSIGN (pv_nfield) TO <lv_name1>.
  IF sy-subrc = 0.
    <lv_name1> = lv_name1.
  ENDIF.

  " 화면 필드 바로 갱신 (Enter 없이 고객명 표시)
  CLEAR lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = pv_kfield.
  ls_dynp-fieldvalue = lv_kunnr.
  APPEND ls_dynp TO lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = pv_nfield.
  ls_dynp-fieldvalue = lv_name1.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp
    EXCEPTIONS
      OTHERS     = 1.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_CUST_NAMES
"&---------------------------------------------------------------------*
"  고객번호 직접 입력 후 Enter → 옆에 고객명 표시
"  없는 고객번호면 메시지 + cv_err = 'X'
"&---------------------------------------------------------------------*
FORM set_cust_names CHANGING cv_err TYPE char1.

  CLEAR: cv_err,
         gv_s_namfr,
         gv_s_namto.

  IF gv_s_kunfr IS NOT INITIAL.

    SELECT SINGLE name1
      FROM ztcma00050
     WHERE kunnr = @gv_s_kunfr
      INTO @gv_s_namfr.

    IF sy-subrc <> 0.
      MESSAGE s250(zmsga) WITH gv_s_kunfr DISPLAY LIKE 'E'.
      cv_err = 'X'.
      RETURN.
    ENDIF.

  ENDIF.

  IF gv_s_kunto IS NOT INITIAL.

    SELECT SINGLE name1
      FROM ztcma00050
     WHERE kunnr = @gv_s_kunto
      INTO @gv_s_namto.

    IF sy-subrc <> 0.
      MESSAGE s250(zmsga) WITH gv_s_kunto DISPLAY LIKE 'E'.
      cv_err = 'X'.
      RETURN.
    ENDIF.

  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form VALIDATE_SEARCH_CONDITION
"&---------------------------------------------------------------------*
FORM validate_search_condition CHANGING cv_err TYPE char1.

  CLEAR cv_err.

  IF gv_s_kunfr IS NOT INITIAL
 AND gv_s_kunto IS NOT INITIAL
 AND gv_s_kunfr > gv_s_kunto.
    MESSAGE s251(zmsga) DISPLAY LIKE 'E'.
    cv_err = 'X'.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form CLEAR_SEARCH_CONDITION
"&---------------------------------------------------------------------*
"  입력값 초기화 : 고객번호·고객명 비우고 고객 상태 '전체' 로 → 다시 조회
"&---------------------------------------------------------------------*
FORM clear_search_condition .

  CLEAR: gv_s_kunfr,
         gv_s_kunto,
         gv_s_namfr,
         gv_s_namto,
         rb_norm,
         rb_blck,
         rb_clos.

  rb_all = 'X'.

  PERFORM refresh_data.

ENDFORM.
