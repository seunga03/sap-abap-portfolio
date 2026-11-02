"& Include          ZLSDA00040_F01
"&---------------------------------------------------------------------*
"& [전체본] 청구 생성 + AR 연동 / AR 생성 / 청구 취소 / 조회
"&---------------------------------------------------------------------*


"***********************************************************************
" 0. 공통
"***********************************************************************


"---------------------------------------------------------------------*
" SET_TOOLBAR_EXCLUDE : ALV 표준 버튼 숨김 (SD01 ~ SD04 공통 기준)
"---------------------------------------------------------------------*
FORM set_toolbar_exclude.

  CLEAR gt_exclude.

  APPEND cl_gui_alv_grid=>mc_fc_loc_cut           TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy          TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste         TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row    TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row    TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row    TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row      TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo          TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_check             TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_refresh           TO gt_exclude.

  "---------------------------------------------------------------------*
  " 사용하지 않는 표준 버튼 숨김
  " (남기는 것: 정렬, 찾기, 필터, 엑셀 내보내기)
  "---------------------------------------------------------------------*
  APPEND cl_gui_alv_grid=>mc_fc_detail            TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_sum               TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_mb_sum               TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_subtot            TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_mb_subtot            TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_print             TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_print_back        TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_print_prev        TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_views             TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_mb_view              TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_info              TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_graph             TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_current_variant   TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_maintain_variant  TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_load_variant      TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_save_variant      TO gt_exclude.

ENDFORM.


"---------------------------------------------------------------------*
" GET_CUSTOMER_NAMES : 고객번호별 고객명 1건
"---------------------------------------------------------------------*
FORM get_customer_names
  CHANGING ct_cust TYPE tt_cust.

  CLEAR ct_cust.

  SELECT kunnr,
         MIN( name1 ) AS name1
    FROM ztcma00050
    GROUP BY kunnr
    INTO CORRESPONDING FIELDS OF TABLE @ct_cust.

ENDFORM.


"---------------------------------------------------------------------*
" REFRESH_SCREEN : 상·하단 재조회
"---------------------------------------------------------------------*
FORM refresh_screen.

  PERFORM search_billing_target.
  PERFORM reload_billing.

ENDFORM.



"***********************************************************************
" 1. 상단 ALV - 청구 대상 출고문서
"***********************************************************************


"---------------------------------------------------------------------*
" DISPLAY_TARGET_ALV
"---------------------------------------------------------------------*
FORM display_target_alv.

  IF go_target_container IS INITIAL.

    PERFORM set_default_search.

    "---------------------------------------------------------------------*
    " 최초 조회 (Grid 생성 전)
    "---------------------------------------------------------------------*
    PERFORM search_billing_target.

    CREATE OBJECT go_target_container
      EXPORTING
        container_name = 'CC_TARGET'.

    CREATE OBJECT go_target_grid
      EXPORTING
        i_parent = go_target_container.

    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.

    SET HANDLER:
      go_event_handler->handle_target_toolbar       FOR go_target_grid,
      go_event_handler->handle_target_user_command  FOR go_target_grid,
      go_event_handler->handle_target_hotspot_click FOR go_target_grid.

    PERFORM set_target_fieldcat.
    PERFORM set_toolbar_exclude.

    CLEAR gs_target_layout.

    gs_target_layout-zebra      = abap_true.
    gs_target_layout-cwidth_opt = abap_true.
    gs_target_layout-sel_mode   = 'A'.
    gs_target_layout-grid_title = '청구 대상 출고문서'.

    CALL METHOD go_target_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_target_layout
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab            = gt_target
        it_fieldcatalog      = gt_target_fcat.

    CALL METHOD go_target_grid->set_toolbar_interactive.

    CALL METHOD go_target_grid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.

    CALL METHOD cl_gui_cfw=>flush.

  ELSE.

    CALL METHOD go_target_grid->refresh_table_display.

  ENDIF.

ENDFORM.


"---------------------------------------------------------------------*
" SET_TARGET_FIELDCAT
"---------------------------------------------------------------------*
FORM set_target_fieldcat.

  CLEAR gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'NO'.
  gs_target_fcat-coltext   = 'No'.
  gs_target_fcat-outputlen = 4.
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'STATUS'.
  gs_target_fcat-coltext   = '상태'.
  gs_target_fcat-icon      = abap_true.
  gs_target_fcat-outputlen = 5.
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'BILL_STATUS'.
  gs_target_fcat-coltext   = '청구상태'.
  gs_target_fcat-outputlen = 10.
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'VBELN'.
  gs_target_fcat-coltext   = '출고문서번호'.
  gs_target_fcat-hotspot   = abap_true.
  gs_target_fcat-outputlen = 14.
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'VGBEL'.
  gs_target_fcat-coltext   = '판매오더번호'.
  gs_target_fcat-scrtext_l = '판매오더번호'.
  gs_target_fcat-scrtext_m = '판매오더번호'.
  gs_target_fcat-scrtext_s = '판매오더번호'.
  gs_target_fcat-outputlen = 22.         " 값(SO번호 + '외 n건')과 제목이 모두 보이도록 넓게
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'KUNNR'.
  gs_target_fcat-coltext   = '고객번호'.
  gs_target_fcat-outputlen = 12.
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'NAME1'.
  gs_target_fcat-coltext   = '고객명'.
  gs_target_fcat-outputlen = 20.
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'ACGDT'.
  gs_target_fcat-coltext   = '실제출하일'.
  gs_target_fcat-outputlen = 11.
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'BILL_AMOUNT'.
  gs_target_fcat-coltext   = '청구금액'.
  gs_target_fcat-cfieldname = 'WAERS'.
  gs_target_fcat-outputlen  = 16.
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'RESULT_TEXT'.
  gs_target_fcat-coltext   = '판정내용'.
  gs_target_fcat-outputlen = 40.
  APPEND gs_target_fcat TO gt_target_fcat.

  CLEAR gs_target_fcat.
  gs_target_fcat-fieldname = 'WAERS'.
  gs_target_fcat-no_out    = abap_true.
  APPEND gs_target_fcat TO gt_target_fcat.

ENDFORM.



"***********************************************************************
" 2. 청구 대상 조회 (R)
"***********************************************************************


"---------------------------------------------------------------------*
" SEARCH_BILLING_TARGET
" 출하 완료(GISTA = C 또는 실제출하일 있음)된 출고문서
"---------------------------------------------------------------------*
FORM search_billing_target.

  DATA:
    lt_delivery TYPE STANDARD TABLE OF ztsda00030,
    ls_delivery TYPE ztsda00030,
    lt_cust     TYPE tt_cust,
    ls_cust     TYPE ty_cust,

    lv_bilno    TYPE ztsda00050-bilno,
    lv_totam    TYPE ztsda00050-totam,
    lv_waers    TYPE ztsda00050-waers,
    lv_no       TYPE i,

    lr_vbeln    TYPE RANGE OF ztsda00030-vbeln,
    lr_kunnr    TYPE RANGE OF ztsda00030-kunnr,
    lr_acgdt    TYPE RANGE OF ztsda00030-acgdt.

  CLEAR:
    gt_target,
    gs_target.

  "---------------------------------------------------------------------*
  " 조회조건 Range
  "---------------------------------------------------------------------*
  IF gv_s_vbeln IS NOT INITIAL.
    lr_vbeln = VALUE #( ( sign = 'I' option = 'EQ' low = gv_s_vbeln ) ).
  ENDIF.

  IF gv_s_kunnr IS NOT INITIAL.
    lr_kunnr = VALUE #( ( sign = 'I' option = 'EQ' low = gv_s_kunnr ) ).
  ENDIF.

  IF gv_s_acgfr IS NOT INITIAL AND gv_s_acgto IS NOT INITIAL.
    lr_acgdt = VALUE #( ( sign = 'I' option = 'BT' low = gv_s_acgfr high = gv_s_acgto ) ).
  ELSEIF gv_s_acgfr IS NOT INITIAL.
    lr_acgdt = VALUE #( ( sign = 'I' option = 'GE' low = gv_s_acgfr ) ).
  ELSEIF gv_s_acgto IS NOT INITIAL.
    lr_acgdt = VALUE #( ( sign = 'I' option = 'LE' low = gv_s_acgto ) ).
  ENDIF.

  SELECT *
    FROM ztsda00030
    WHERE vbeln IN @lr_vbeln
      AND kunnr IN @lr_kunnr
      AND acgdt IN @lr_acgdt
    INTO TABLE @lt_delivery.

  "---------------------------------------------------------------------*
  " 출하 완료 건만 (SD03과 같은 기준)
  "---------------------------------------------------------------------*
  DELETE lt_delivery
    WHERE gista <> 'C'
      AND acgdt IS INITIAL.

  IF lt_delivery IS NOT INITIAL.
    PERFORM get_customer_names CHANGING lt_cust.
  ENDIF.

  LOOP AT lt_delivery INTO ls_delivery.

    "---------------------------------------------------------------------*
    " 이미 청구된 출고문서인지
    "---------------------------------------------------------------------*
    CLEAR lv_bilno.

    SELECT SINGLE bilno
      FROM ztsda00060
      WHERE vleln = @ls_delivery-vbeln
      INTO @lv_bilno.

    IF rb_pending = 'X'
       AND lv_bilno IS NOT INITIAL.
      CONTINUE.
    ENDIF.

    CLEAR:
      gs_target,
      lv_totam,
      lv_waers.

    gs_target-vbeln = ls_delivery-vbeln.
    gs_target-kunnr = ls_delivery-kunnr.
    gs_target-acgdt = ls_delivery-acgdt.

    PERFORM get_so_text
      USING    ls_delivery-vbeln
      CHANGING gs_target-vgbel.

    READ TABLE lt_cust INTO ls_cust
      WITH TABLE KEY kunnr = ls_delivery-kunnr.

    IF sy-subrc = 0.
      gs_target-name1 = ls_cust-name1.
    ENDIF.

    "---------------------------------------------------------------------*
    " 청구 예상금액 (원본 SO Item 금액 합계)
    "---------------------------------------------------------------------*
    SELECT SUM( s~totam )
      FROM ztsda00040 AS d
      INNER JOIN ztsda00020 AS s
        ON s~vbeln = d~vgbel
       AND s~posnr = d~posnv
      WHERE d~vbeln = @ls_delivery-vbeln
      INTO @lv_totam.

    gs_target-bill_amount = lv_totam.

    SELECT SINGLE h~waers
      FROM ztsda00040 AS d
      INNER JOIN ztsda00010 AS h
        ON h~vbeln = d~vgbel
      WHERE d~vbeln = @ls_delivery-vbeln
      INTO @lv_waers.

    gs_target-waers = lv_waers.

    "---------------------------------------------------------------------*
    " 청구 가능 여부
    "---------------------------------------------------------------------*
    IF lv_bilno IS INITIAL.

      gs_target-status      = icon_led_green.
      gs_target-bill_status = '미청구'.
      gs_target-result_text = '청구 생성 가능'.
      gs_target-ready_yn    = 'Y'.

    ELSE.

      gs_target-status      = icon_checked.
      gs_target-bill_status = '청구완료'.
      gs_target-result_text = |청구문서 { lv_bilno } 생성됨|.
      gs_target-ready_yn    = 'N'.

    ENDIF.

    APPEND gs_target TO gt_target.

  ENDLOOP.

  "---------------------------------------------------------------------*
  " 청구 가능 우선 → 최근 출하 순
  "---------------------------------------------------------------------*
  SORT gt_target BY ready_yn DESCENDING
                    acgdt    DESCENDING
                    vbeln    DESCENDING.

  LOOP AT gt_target ASSIGNING FIELD-SYMBOL(<fs_target>).
    lv_no = lv_no + 1.
    <fs_target>-no = lv_no.
  ENDLOOP.

  IF go_target_grid IS BOUND.
    CALL METHOD go_target_grid->refresh_table_display.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_DEFAULT_SEARCH
"&---------------------------------------------------------------------*
" 기본 조회조건 : 실제출하일 이번 달 1일 ~ 다음 달 말일, 미청구만
" (SD02·SD03과 같은 기준으로 통일)
"----------------------------------------------------------------------*
FORM set_default_search.

  DATA lv_next TYPE d.

  CLEAR:
    gv_s_vbeln,
    gv_s_kunnr,
    rb_all.

  rb_pending = 'X'.

  gv_s_acgfr = sy-datum.
  gv_s_acgfr+6(2) = '01'.

  lv_next = gv_s_acgfr + 32.

  CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
    EXPORTING
      day_in            = lv_next
    IMPORTING
      last_day_of_month = gv_s_acgto.

ENDFORM.


"---------------------------------------------------------------------*
" CLEAR_SEARCH_CONDITION
"---------------------------------------------------------------------*
FORM clear_search_condition.

  PERFORM set_default_search.
  PERFORM search_billing_target.

ENDFORM.


"---------------------------------------------------------------------*
" SELECT_ALL_TARGET
"---------------------------------------------------------------------*
FORM select_all_target.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_target ASSIGNING FIELD-SYMBOL(<fs_target>).

    IF <fs_target>-ready_yn = 'Y'.
      <fs_target>-sel = 'X'.
      APPEND VALUE #( index = sy-tabix ) TO lt_rows.
    ELSE.
      CLEAR <fs_target>-sel.
    ENDIF.

  ENDLOOP.

  IF go_target_grid IS BOUND.
    CALL METHOD go_target_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.


"---------------------------------------------------------------------*
" DESELECT_ALL_TARGET
"---------------------------------------------------------------------*
FORM deselect_all_target.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_target ASSIGNING FIELD-SYMBOL(<fs_target>).
    CLEAR <fs_target>-sel.
  ENDLOOP.

  IF go_target_grid IS BOUND.
    CALL METHOD go_target_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.



"***********************************************************************
" 3. 청구 생성 (C) + AR 생성
"***********************************************************************


"---------------------------------------------------------------------*
" CONFIRM_CREATE_BILLING
"---------------------------------------------------------------------*
FORM confirm_create_billing.

  DATA:
    lv_answer   TYPE c LENGTH 1,
    lv_selected TYPE i,
    lv_question TYPE string.

  IF go_target_grid IS BOUND.
    PERFORM sync_target_sel.
  ENDIF.

  IF line_exists( gt_target[ sel = 'X' ready_yn = 'N' ] ).
    MESSAGE i037(zmsga) WITH '청구완료' '청구 생성'.
    RETURN.
  ENDIF.

  LOOP AT gt_target TRANSPORTING NO FIELDS
       WHERE sel      = 'X'
         AND ready_yn = 'Y'.
    lv_selected = lv_selected + 1.
  ENDLOOP.

  IF lv_selected = 0.
    MESSAGE s014(zmsga) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  MESSAGE s215(zmsga) WITH lv_selected INTO lv_question.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '청구 생성'
      text_question         = lv_question
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
    RETURN.
  ENDIF.

  PERFORM create_billing.

ENDFORM.


"---------------------------------------------------------------------*
" CREATE_BILLING
"
" 출고문서 1건 = 청구문서 1건 = AR 1건
" 문서 단위로 처리 (한 건 실패해도 나머지는 계속)
"
"   1. 청구번호 채번 (SD 공통 FM, BI + 8자리)
"   2. 청구 Header / Item INSERT
"   3. 판매오더 상태 → BI
"   4. Z_FI_CREATE_AR 호출 (AR 생성 + ARYNO = 'Y'는 함수가 처리)
"   5. 성공 → COMMIT / 실패 → 해당 문서 전체 ROLLBACK
"---------------------------------------------------------------------*
FORM create_billing.

  DATA:
    lt_ditem     TYPE STANDARD TABLE OF ztsda00040,
    ls_ditem     TYPE ztsda00040,

    ls_soitem    TYPE ztsda00020,
    ls_sohead    TYPE ztsda00010,

    ls_bhead     TYPE ztsda00050,
    lt_bitem     TYPE STANDARD TABLE OF ztsda00060,
    ls_bitem     TYPE ztsda00060,

    lt_so        TYPE tt_vgbel,
    lv_so        TYPE ztsda00040-vgbel,

    lv_bilno     TYPE ztsda00050-bilno,
    lv_exist     TYPE ztsda00050-bilno,

    lv_arnum     TYPE ztcma00100-arnum,
    lv_duedt     TYPE ztcma00100-duedt,
    lv_msg       TYPE string,

    lv_created   TYPE i,
    lv_failed    TYPE i,
    lv_fail_text TYPE string.

  IF go_target_grid IS BOUND.
    PERFORM sync_target_sel.
  ENDIF.

  CLEAR gt_new_bill.

  LOOP AT gt_target INTO gs_target
       WHERE sel      = 'X'
         AND ready_yn = 'Y'.

    "---------------------------------------------------------------------*
    " 중복 청구 재확인
    "---------------------------------------------------------------------*
    CLEAR lv_exist.

    SELECT SINGLE bilno
      FROM ztsda00060
      WHERE vleln = @gs_target-vbeln
      INTO @lv_exist.

    IF lv_exist IS NOT INITIAL.
      lv_failed = lv_failed + 1.
      IF lv_fail_text IS INITIAL.
        lv_fail_text = |{ gs_target-vbeln }: 이미 청구됨 ({ lv_exist })|.
      ENDIF.
      CONTINUE.
    ENDIF.

    "---------------------------------------------------------------------*
    " 출고문서 Item
    "---------------------------------------------------------------------*
    CLEAR lt_ditem.

    SELECT *
      FROM ztsda00040
      WHERE vbeln = @gs_target-vbeln
      INTO TABLE @lt_ditem.

    IF lt_ditem IS INITIAL.
      lv_failed = lv_failed + 1.
      IF lv_fail_text IS INITIAL.
        lv_fail_text = |{ gs_target-vbeln }: 출고문서 Item 없음|.
      ENDIF.
      CONTINUE.
    ENDIF.

    "---------------------------------------------------------------------*
    " 1. 청구번호 채번 (SNRO ZSD_NUM 구간 03)
    "---------------------------------------------------------------------*
    CLEAR lv_bilno.

    CALL FUNCTION 'ZSD_GET_NEXT_NO'
      EXPORTING
        iv_docty      = 'BI'
      IMPORTING
        ev_number     = lv_bilno
      EXCEPTIONS
        invalid_docty = 1
        number_error  = 2
        OTHERS        = 3.

    IF sy-subrc <> 0 OR lv_bilno IS INITIAL.
      MESSAGE i311(zmsga) WITH '청구문서'.
      EXIT.
    ENDIF.

    "---------------------------------------------------------------------*
    " 2. 청구 Header / Item 구성
    "---------------------------------------------------------------------*
    CLEAR:
      ls_bhead,
      lt_bitem,
      lt_so.

    ls_bhead-bilno = lv_bilno.
    ls_bhead-kunnr = gs_target-kunnr.
    ls_bhead-bildt = sy-datum.

    LOOP AT lt_ditem INTO ls_ditem.

      CLEAR ls_soitem.

      SELECT SINGLE *
        FROM ztsda00020
        WHERE vbeln = @ls_ditem-vgbel
          AND posnr = @ls_ditem-posnv
        INTO @ls_soitem.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      CLEAR ls_sohead.

      SELECT SINGLE *
        FROM ztsda00010
        WHERE vbeln = @ls_ditem-vgbel
        INTO @ls_sohead.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      IF ls_bhead-waers IS INITIAL.
        ls_bhead-waers = ls_sohead-waers.
      ENDIF.

      CLEAR ls_bitem.

      ls_bitem-bilno = lv_bilno.
      ls_bitem-itmno = ls_ditem-posnr.
      ls_bitem-matnr = ls_ditem-matnr.
      ls_bitem-vleln = ls_ditem-vbeln.
      ls_bitem-posnr = ls_ditem-posnr.
      ls_bitem-bilqt = ls_ditem-lfimg.
      ls_bitem-meins = ls_ditem-meins.
      ls_bitem-unitp = ls_soitem-netpr.

      "---------------------------------------------------------------------*
      " 금액 = SO Item 금액 × (출고수량 / 주문수량)
      "---------------------------------------------------------------------*
      IF ls_soitem-kwmeng IS NOT INITIAL.

        ls_bitem-netam = ls_soitem-netam * ls_ditem-lfimg / ls_soitem-kwmeng.
        ls_bitem-taxam = ls_soitem-taxam * ls_ditem-lfimg / ls_soitem-kwmeng.
        ls_bitem-totam = ls_soitem-totam * ls_ditem-lfimg / ls_soitem-kwmeng.

      ENDIF.

      ls_bitem-ernam = sy-uname.
      ls_bitem-erdat = sy-datum.
      ls_bitem-erzet = sy-uzeit.

      ls_bhead-netam = ls_bhead-netam + ls_bitem-netam.
      ls_bhead-taxam = ls_bhead-taxam + ls_bitem-taxam.
      ls_bhead-totam = ls_bhead-totam + ls_bitem-totam.

      APPEND ls_bitem TO lt_bitem.

      IF NOT line_exists( lt_so[ table_line = ls_ditem-vgbel ] ).
        APPEND ls_ditem-vgbel TO lt_so.
      ENDIF.

    ENDLOOP.

    IF lt_bitem IS INITIAL.
      lv_failed = lv_failed + 1.
      IF lv_fail_text IS INITIAL.
        lv_fail_text = |{ gs_target-vbeln }: 원본 판매오더 Item을 찾을 수 없음|.
      ENDIF.
      CONTINUE.
    ENDIF.

    ls_bhead-aryno = 'N'.        " AR 생성 시 함수가 'Y'로 변경
    ls_bhead-ernam = sy-uname.
    ls_bhead-erdat = sy-datum.
    ls_bhead-erzet = sy-uzeit.

    "---------------------------------------------------------------------*
    " 청구 저장
    "---------------------------------------------------------------------*
    INSERT ztsda00050 FROM @ls_bhead.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      lv_failed = lv_failed + 1.
      IF lv_fail_text IS INITIAL.
        lv_fail_text = |{ gs_target-vbeln }: 청구 Header 저장 실패|.
      ENDIF.
      CONTINUE.
    ENDIF.

    INSERT ztsda00060 FROM TABLE @lt_bitem.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      lv_failed = lv_failed + 1.
      IF lv_fail_text IS INITIAL.
        lv_fail_text = |{ gs_target-vbeln }: 청구 Item 저장 실패|.
      ENDIF.
      CONTINUE.
    ENDIF.

    "---------------------------------------------------------------------*
    " 3. 판매오더 상태 → BI
    "---------------------------------------------------------------------*
    LOOP AT lt_so INTO lv_so.

      UPDATE ztsda00010
         SET sosta = 'BI',
             aenam = @sy-uname,
             aedat = @sy-datum,
             aezet = @sy-uzeit
       WHERE vbeln = @lv_so
         AND sosta <> 'CN'.

    ENDLOOP.

    "---------------------------------------------------------------------*
    " 4. AR 생성 (FI 공통함수)
    "    같은 LUW라 방금 INSERT한 청구 Header를 함수가 읽을 수 있음
    "---------------------------------------------------------------------*
    CLEAR:
      lv_arnum,
      lv_duedt,
      lv_msg.

    CALL FUNCTION 'Z_FI_CREATE_AR'
      EXPORTING
        iv_bilno       = lv_bilno
      IMPORTING
        ev_arnum       = lv_arnum
        ev_duedt       = lv_duedt
        ev_msg         = lv_msg
      EXCEPTIONS
        not_found      = 1
        already_exists = 2
        no_zterm       = 3
        insert_failed  = 4
        OTHERS         = 5.

    "---------------------------------------------------------------------*
    " 5. 실패 → 이 문서의 청구/SO상태/AR 전부 취소
    "---------------------------------------------------------------------*
    IF sy-subrc <> 0.

      ROLLBACK WORK.

      lv_failed = lv_failed + 1.

      IF lv_fail_text IS INITIAL.
        IF lv_msg IS INITIAL.
          lv_fail_text = |{ gs_target-vbeln }: 매출채권 생성 실패|.
        ELSE.
          lv_fail_text = |{ gs_target-vbeln }: { lv_msg }|.
        ENDIF.
      ENDIF.

      CONTINUE.

    ENDIF.

    COMMIT WORK AND WAIT.

    APPEND lv_bilno TO gt_new_bill.

    lv_created = lv_created + 1.

  ENDLOOP.

  "---------------------------------------------------------------------*
  " 화면 갱신 + 결과 메시지
  "---------------------------------------------------------------------*
  gv_bill_mode = 'A'.

  PERFORM refresh_screen.

  IF lv_created = 0 AND lv_failed = 0.
    RETURN.
  ENDIF.

  "---------------------------------------------------------------------*
  " 결과 메시지 : 성공 시 AR(매출채권)이 자동 생성되었음을 같이 안내
  "---------------------------------------------------------------------*
  IF lv_failed = 0.
    MESSAGE |청구문서 { lv_created }건이 생성되었으며, 매출채권이 자동 생성되었습니다.|
      TYPE 'S'.
  ELSEIF lv_created = 0.
    MESSAGE i208(zmsga) WITH lv_fail_text.
  ELSE.
    MESSAGE i207(zmsga) WITH lv_created lv_failed lv_fail_text.
  ENDIF.

ENDFORM.



"***********************************************************************
" 4. 하단 ALV - 청구문서 (R)
"***********************************************************************


"---------------------------------------------------------------------*
" DISPLAY_BILL_ALV
"---------------------------------------------------------------------*
FORM display_bill_alv.

  IF go_bill_container IS INITIAL.

    CREATE OBJECT go_bill_container
      EXPORTING
        container_name = 'CC_BILL'.

    CREATE OBJECT go_bill_grid
      EXPORTING
        i_parent = go_bill_container.

    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.

    SET HANDLER:
      go_event_handler->handle_bill_toolbar       FOR go_bill_grid,
      go_event_handler->handle_bill_user_command  FOR go_bill_grid,
      go_event_handler->handle_bill_hotspot_click FOR go_bill_grid.

    PERFORM set_bill_fieldcat.
    PERFORM set_toolbar_exclude.

    "---------------------------------------------------------------------*
    " 최초 조회 (SET_TABLE_FOR_FIRST_DISPLAY 전에는 Refresh 금지)
    "---------------------------------------------------------------------*
    PERFORM get_all_billing_no_refresh.

    CLEAR gs_bill_layout.

    gs_bill_layout-zebra      = abap_true.
    gs_bill_layout-cwidth_opt = abap_false.
    gs_bill_layout-sel_mode   = 'A'.
    gs_bill_layout-grid_title = '청구문서 정보'.
    gs_bill_layout-info_fname = 'ROW_COLOR'.

    CALL METHOD go_bill_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_bill_layout
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab            = gt_bill
        it_fieldcatalog      = gt_bill_fcat.

    CALL METHOD go_bill_grid->set_toolbar_interactive.

    CALL METHOD go_bill_grid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.

    CALL METHOD cl_gui_cfw=>flush.

  ELSE.

    CALL METHOD go_bill_grid->refresh_table_display.

  ENDIF.

ENDFORM.


"---------------------------------------------------------------------*
" SET_BILL_FIELDCAT
"---------------------------------------------------------------------*
FORM set_bill_fieldcat.

  CLEAR gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'NO'.
  gs_bill_fcat-coltext   = 'No'.
  gs_bill_fcat-outputlen = 4.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'STATUS'.
  gs_bill_fcat-coltext   = '상태'.
  gs_bill_fcat-icon      = abap_true.
  gs_bill_fcat-outputlen = 5.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'BILL_STATUS'.
  gs_bill_fcat-coltext   = '청구상태'.
  gs_bill_fcat-outputlen = 14.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'BILNO'.
  gs_bill_fcat-coltext   = '청구문서번호'.
  gs_bill_fcat-hotspot   = abap_true.
  gs_bill_fcat-outputlen = 14.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'VLELN'.
  gs_bill_fcat-coltext   = '출고문서번호'.
  gs_bill_fcat-hotspot   = abap_true.
  gs_bill_fcat-outputlen = 16.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'VGBEL'.
  gs_bill_fcat-coltext   = '판매오더번호'.
  gs_bill_fcat-scrtext_l = '판매오더번호'.
  gs_bill_fcat-scrtext_m = '판매오더번호'.
  gs_bill_fcat-scrtext_s = '판매오더번호'.
  gs_bill_fcat-outputlen = 14.         " 값(SO번호 + '외 n건')과 제목이 모두 보이도록 넓게
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'KUNNR'.
  gs_bill_fcat-coltext   = '고객번호'.
  gs_bill_fcat-outputlen = 12.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'NAME1'.
  gs_bill_fcat-coltext   = '고객명'.
  gs_bill_fcat-outputlen = 20.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'BILDT'.
  gs_bill_fcat-coltext   = '청구일'.
  gs_bill_fcat-outputlen = 11.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'NETAM'.
  gs_bill_fcat-coltext   = '공급가액'.
  gs_bill_fcat-cfieldname = 'WAERS'.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'TAXAM'.
  gs_bill_fcat-coltext   = '세액'.
  gs_bill_fcat-cfieldname = 'WAERS'.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'TOTAM'.
  gs_bill_fcat-coltext   = '총액'.
  gs_bill_fcat-cfieldname = 'WAERS'.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'WAERS'.
  gs_bill_fcat-no_out    = abap_true.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'BILST'.
  gs_bill_fcat-no_out    = abap_true.
  APPEND gs_bill_fcat TO gt_bill_fcat.

  CLEAR gs_bill_fcat.
  gs_bill_fcat-fieldname = 'ARYNO'.
  gs_bill_fcat-no_out    = abap_true.
  APPEND gs_bill_fcat TO gt_bill_fcat.

ENDFORM.


"---------------------------------------------------------------------*
" GET_BILLING_DATA
" iv_mode : A = 전체 / P = AR 미생성
" ALV Refresh는 하지 않음 (최초 출력 전에도 호출되기 때문)
"---------------------------------------------------------------------*
FORM get_billing_data
  USING iv_mode TYPE char1.

  DATA:
    lt_bhead TYPE STANDARD TABLE OF ztsda00050,
    ls_bhead TYPE ztsda00050,
    lt_cust  TYPE tt_cust,
    ls_cust  TYPE ty_cust,
    lv_no    TYPE i,
    lr_aryno TYPE RANGE OF ztsda00050-aryno.

  CLEAR:
    gt_bill,
    gs_bill.

  gv_bill_mode = iv_mode.

  IF iv_mode = 'P'.
    lr_aryno = VALUE #( ( sign = 'E' option = 'EQ' low = 'Y' ) ).
  ENDIF.

  SELECT *
    FROM ztsda00050
    WHERE aryno IN @lr_aryno
    INTO TABLE @lt_bhead.

  IF lt_bhead IS NOT INITIAL.
    PERFORM get_customer_names CHANGING lt_cust.
  ENDIF.

  SORT lt_bhead BY erdat DESCENDING
                   erzet DESCENDING
                   bilno DESCENDING.

  LOOP AT lt_bhead INTO ls_bhead.

    CLEAR gs_bill.

    lv_no = lv_no + 1.

    gs_bill-no    = lv_no.
    gs_bill-bilno = ls_bhead-bilno.
    gs_bill-kunnr = ls_bhead-kunnr.
    gs_bill-bildt = ls_bhead-bildt.

    SELECT SINGLE vleln
      FROM ztsda00060
      WHERE bilno = @ls_bhead-bilno
      INTO @gs_bill-vleln.

    PERFORM get_so_text
      USING    gs_bill-vleln
      CHANGING gs_bill-vgbel.
    gs_bill-netam = ls_bhead-netam.
    gs_bill-taxam = ls_bhead-taxam.
    gs_bill-totam = ls_bhead-totam.
    gs_bill-waers = ls_bhead-waers.
    gs_bill-bilst = ls_bhead-bilst.
    gs_bill-aryno = ls_bhead-aryno.

    READ TABLE lt_cust INTO ls_cust
      WITH TABLE KEY kunnr = ls_bhead-kunnr.

    IF sy-subrc = 0.
      gs_bill-name1 = ls_cust-name1.
    ENDIF.

    IF ls_bhead-aryno = 'Y'.
      gs_bill-status      = icon_led_green.
      gs_bill-bill_status = '매출채권 생성완료'.
    ELSE.
      gs_bill-status      = icon_led_yellow.
      gs_bill-bill_status = '매출채권 미생성'.
    ENDIF.

    IF line_exists( gt_new_bill[ table_line = ls_bhead-bilno ] ).
      gs_bill-row_color = 'C310'.
    ENDIF.

    APPEND gs_bill TO gt_bill.

  ENDLOOP.

ENDFORM.


"---------------------------------------------------------------------*
" GET_ALL_BILLING_NO_REFRESH (최초 출력용)
"---------------------------------------------------------------------*
FORM get_all_billing_no_refresh.

  PERFORM get_billing_data USING 'A'.

ENDFORM.


"---------------------------------------------------------------------*
" GET_ALL_BILLING
"---------------------------------------------------------------------*
FORM get_all_billing.

  PERFORM get_billing_data USING 'A'.
  PERFORM refresh_bill_grid.

ENDFORM.


"---------------------------------------------------------------------*
" GET_PENDING_BILLING (AR 미생성만)
"---------------------------------------------------------------------*
FORM get_pending_billing.

  PERFORM get_billing_data USING 'P'.
  PERFORM refresh_bill_grid.

ENDFORM.


"---------------------------------------------------------------------*
" RELOAD_BILLING (보고 있던 모드 그대로 재조회)
"---------------------------------------------------------------------*
FORM reload_billing.

  PERFORM get_billing_data USING gv_bill_mode.
  PERFORM refresh_bill_grid.

ENDFORM.


"---------------------------------------------------------------------*
" REFRESH_BILL_GRID
"---------------------------------------------------------------------*
FORM refresh_bill_grid.

  IF go_bill_grid IS BOUND.
    CALL METHOD go_bill_grid->refresh_table_display.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.



"***********************************************************************
" 5. (삭제) AR 수동 생성 : AR은 청구 생성(CREATE_BILLING) 때 자동 생성됨
"***********************************************************************



"***********************************************************************
" 6. 청구 취소 (D)
"***********************************************************************


"---------------------------------------------------------------------*
" CANCEL_BILLING
" AR이 만들어지지 않은 청구만 취소 가능
" 청구 Header/Item 삭제 → 연결 SO 상태 BI → GI
" → 출고문서가 다시 상단 청구 대상에 나타남
"---------------------------------------------------------------------*
FORM cancel_billing.

  DATA:
    lt_sel      TYPE STANDARD TABLE OF ty_bill,
    ls_sel      TYPE ty_bill,
    lt_so       TYPE tt_vgbel,
    lv_so       TYPE ztsda00040-vgbel,
    lv_arnum    TYPE ztcma00100-arnum,
    lv_answer   TYPE c LENGTH 1,
    lv_question TYPE string,
    lv_count    TYPE i.

  IF go_bill_grid IS BOUND.
    PERFORM sync_bill_sel.
  ENDIF.

  lt_sel = VALUE #( FOR wa IN gt_bill WHERE ( sel = 'X' ) ( wa ) ).

  IF lt_sel IS INITIAL.
    MESSAGE i021(zmsga) WITH '취소할 청구문서'.
    RETURN.
  ENDIF.

  IF line_exists( lt_sel[ aryno = 'Y' ] ).
    MESSAGE i037(zmsga) WITH '매출채권 생성완료' '청구 취소'.
    RETURN.
  ENDIF.

  DATA(lv_sel_cnt) = lines( lt_sel ).

  MESSAGE s216(zmsga) WITH lv_sel_cnt INTO lv_question.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '청구 취소'
      text_question         = lv_question
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
    RETURN.
  ENDIF.

  LOOP AT lt_sel INTO ls_sel.

    "---------------------------------------------------------------------*
    " DB 기준 AR 존재 재확인
    "---------------------------------------------------------------------*
    CLEAR lv_arnum.

    SELECT SINGLE arnum
      FROM ztcma00100
      WHERE bilno = @ls_sel-bilno
      INTO @lv_arnum.

    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    "---------------------------------------------------------------------*
    " 연결 SO 번호 (청구 Item → 출고 Item → SO)
    "---------------------------------------------------------------------*
    CLEAR lt_so.

    SELECT DISTINCT d~vgbel
      FROM ztsda00060 AS b
      INNER JOIN ztsda00040 AS d
        ON d~vbeln = b~vleln
       AND d~posnr = b~posnr
      WHERE b~bilno = @ls_sel-bilno
      INTO TABLE @lt_so.

    "---------------------------------------------------------------------*
    " 청구 삭제
    "---------------------------------------------------------------------*
    DELETE FROM ztsda00060 WHERE bilno = @ls_sel-bilno.
    DELETE FROM ztsda00050 WHERE bilno = @ls_sel-bilno.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      CONTINUE.
    ENDIF.

    "---------------------------------------------------------------------*
    " SO 상태 BI → GI
    "---------------------------------------------------------------------*
    LOOP AT lt_so INTO lv_so.

      UPDATE ztsda00010
         SET sosta = 'GI',
             aenam = @sy-uname,
             aedat = @sy-datum,
             aezet = @sy-uzeit
       WHERE vbeln = @lv_so
         AND sosta = 'BI'.

    ENDLOOP.

    COMMIT WORK AND WAIT.

    DELETE gt_new_bill WHERE table_line = ls_sel-bilno.

    lv_count = lv_count + 1.

  ENDLOOP.

  PERFORM refresh_screen.

  MESSAGE s006(zmsga) WITH lv_count.

ENDFORM.



"***********************************************************************
" 6. ALV 행 선택 -> SEL 값 반영 (드래그 / Shift / Ctrl 선택 지원)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form SYNC_TARGET_SEL
"&---------------------------------------------------------------------*
FORM sync_target_sel.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_target ASSIGNING FIELD-SYMBOL(<fs_target>).
    CLEAR <fs_target>-sel.
  ENDLOOP.

  IF go_target_grid IS NOT BOUND.
    RETURN.
  ENDIF.

  CALL METHOD go_target_grid->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_target ASSIGNING <fs_target> INDEX ls_row-index.
    IF sy-subrc = 0.
      <fs_target>-sel = 'X'.
    ENDIF.
  ENDLOOP.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SYNC_BILL_SEL
"&---------------------------------------------------------------------*
FORM sync_bill_sel.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_bill ASSIGNING FIELD-SYMBOL(<fs_bill>).
    CLEAR <fs_bill>-sel.
  ENDLOOP.

  IF go_bill_grid IS NOT BOUND.
    RETURN.
  ENDIF.

  CALL METHOD go_bill_grid->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_bill ASSIGNING <fs_bill> INDEX ls_row-index.
    IF sy-subrc = 0.
      <fs_bill>-sel = 'X'.
    ENDIF.
  ENDLOOP.

ENDFORM.



"***********************************************************************
" 7. 문서 추적 (판매오더번호) / 상세 팝업
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form GET_SO_TEXT
"&---------------------------------------------------------------------*
" 출고문서에 연결된 판매오더번호 (여러 건이면 첫 번째 + '외 n건')
"----------------------------------------------------------------------*
FORM get_so_text
  USING    iv_vbeln TYPE ztsda00030-vbeln
  CHANGING cv_text  TYPE char30.

  DATA lt_so TYPE tt_vgbel.

  CLEAR cv_text.

  IF iv_vbeln IS INITIAL.
    RETURN.
  ENDIF.

  SELECT DISTINCT vgbel
    FROM ztsda00040
    WHERE vbeln = @iv_vbeln
    ORDER BY vgbel
    INTO TABLE @lt_so.

  IF lt_so IS INITIAL.
    RETURN.
  ENDIF.

  cv_text = lt_so[ 1 ].

  IF lines( lt_so ) > 1.
    cv_text = |{ lt_so[ 1 ] } 외 { lines( lt_so ) - 1 }건|.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SHOW_DELIVERY_DETAIL
"&---------------------------------------------------------------------*
" 출고문서번호 클릭 -> 출고문서 Item 팝업 (SALV)
"----------------------------------------------------------------------*
FORM show_delivery_detail
  USING iv_vbeln TYPE ztsda00030-vbeln.

  TYPES:
    BEGIN OF ty_dl_item,
      vgbel TYPE ztsda00010-vbeln,   " 원본 SO (맨 왼쪽)
      posnv TYPE ztsda00020-posnr,   " 원본 SO Item
      posnr TYPE ztsda00040-posnr,   " 출고문서 Item
      matnr TYPE ztsda00040-matnr,
      maktx TYPE ztcma00020-maktx,
      werks TYPE ztsda00040-werks,
      lgort TYPE ztsda00040-lgort,
      lfimg TYPE ztsda00040-lfimg,
      meins TYPE ztsda00040-meins,
      netam TYPE p LENGTH 15 DECIMALS 0,   " 공급가액
      taxam TYPE p LENGTH 15 DECIMALS 0,   " 세액
      totam TYPE p LENGTH 15 DECIMALS 0,   " 최종금액
    END OF ty_dl_item.

  DATA:
    lt_item TYPE STANDARD TABLE OF ty_dl_item,
    lo_alv  TYPE REF TO cl_salv_table,
    lo_cols TYPE REF TO cl_salv_columns_table.

  SELECT i~posnr,
         i~matnr,
         m~maktx,
         i~werks,
         i~lgort,
         i~lfimg,
         i~meins,
         i~vgbel,
         i~posnv,
         s~netam,
         s~taxam,
         s~totam
    FROM ztsda00040 AS i
    LEFT OUTER JOIN ztcma00020 AS m
      ON m~matnr = i~matnr
    LEFT OUTER JOIN ztsda00020 AS s
      ON s~vbeln = i~vgbel
     AND s~posnr = i~posnv
    WHERE i~vbeln = @iv_vbeln
    ORDER BY i~posnr
    INTO CORRESPONDING FIELDS OF TABLE @lt_item.

  IF lt_item IS INITIAL.
    MESSAGE s042(zmsga) WITH '출고문서 상세정보' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  TRY.

      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_item ).

      "---------------------------------------------------------------------*
      " 버튼 모두 숨김 / 제목 / 줄무늬
      "---------------------------------------------------------------------*
      lo_alv->get_functions( )->set_all( abap_false ).

      lo_alv->get_display_settings( )->set_list_header(
        |출고문서 { iv_vbeln } 상세정보| ).

      lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).

      "---------------------------------------------------------------------*
      " 컬럼 제목
      "---------------------------------------------------------------------*
      lo_cols = lo_alv->get_columns( ).
      lo_cols->set_optimize( abap_true ).

      "---------------------------------------------------------------------*
      " 있는 컬럼만 돌면서 제목 지정 (없는 컬럼 때문에 예외 나지 않게)
      "---------------------------------------------------------------------*
      DATA(lt_cols) = lo_cols->get( ).

      LOOP AT lt_cols INTO DATA(ls_col).

        CASE ls_col-columnname.
          WHEN 'POSNR'.
            ls_col-r_column->set_short_text( 'Item' ).
            ls_col-r_column->set_medium_text( 'Item' ).
            ls_col-r_column->set_long_text( 'Item' ).
          WHEN 'MATNR'.
            ls_col-r_column->set_short_text( '자재번호' ).
            ls_col-r_column->set_medium_text( '자재번호' ).
            ls_col-r_column->set_long_text( '자재번호' ).
          WHEN 'MAKTX'.
            ls_col-r_column->set_short_text( '자재명' ).
            ls_col-r_column->set_medium_text( '자재명' ).
            ls_col-r_column->set_long_text( '자재명' ).
          WHEN 'WERKS'.
            ls_col-r_column->set_short_text( 'Plant' ).
            ls_col-r_column->set_medium_text( 'Plant' ).
            ls_col-r_column->set_long_text( 'Plant' ).
          WHEN 'LGORT'.
            ls_col-r_column->set_short_text( '저장위치' ).
            ls_col-r_column->set_medium_text( '저장위치' ).
            ls_col-r_column->set_long_text( '저장위치' ).
          WHEN 'LFIMG'.
            ls_col-r_column->set_short_text( '출고수량' ).
            ls_col-r_column->set_medium_text( '출고수량' ).
            ls_col-r_column->set_long_text( '출고수량' ).
          WHEN 'MEINS'.
            ls_col-r_column->set_short_text( '단위' ).
            ls_col-r_column->set_medium_text( '단위' ).
            ls_col-r_column->set_long_text( '단위' ).
          WHEN 'VGBEL'.
            ls_col-r_column->set_short_text( '원본SO' ).
            ls_col-r_column->set_medium_text( '원본 판매오더' ).
            ls_col-r_column->set_long_text( '원본 판매오더' ).
          WHEN 'POSNV'.
            ls_col-r_column->set_short_text( 'SO Item' ).
            ls_col-r_column->set_medium_text( 'SO Item' ).
            ls_col-r_column->set_long_text( 'SO Item' ).
          WHEN 'NETAM'.
            ls_col-r_column->set_short_text( '공급가액' ).
            ls_col-r_column->set_medium_text( '공급가액' ).
            ls_col-r_column->set_long_text( '공급가액' ).
          WHEN 'TAXAM'.
            ls_col-r_column->set_short_text( '세액' ).
            ls_col-r_column->set_medium_text( '세액' ).
            ls_col-r_column->set_long_text( '세액' ).
          WHEN 'TOTAM'.
            ls_col-r_column->set_short_text( '최종금액' ).
            ls_col-r_column->set_medium_text( '최종금액' ).
            ls_col-r_column->set_long_text( '최종금액' ).
        ENDCASE.

      ENDLOOP.

      "---------------------------------------------------------------------*
      " 하단 합계 행 (출고수량 / 공급가액 / 세액 / 최종금액)
      "---------------------------------------------------------------------*
      DATA(lo_aggr) = lo_alv->get_aggregations( ).

      lo_aggr->add_aggregation( columnname = 'LFIMG' ).
      lo_aggr->add_aggregation( columnname = 'NETAM' ).
      lo_aggr->add_aggregation( columnname = 'TAXAM' ).
      lo_aggr->add_aggregation( columnname = 'TOTAM' ).

      "---------------------------------------------------------------------*
      " 팝업 표시
      "---------------------------------------------------------------------*
      lo_alv->set_screen_popup(
        start_column = 20
        end_column   = 125
        start_line   = 5
        end_line     = 18 ).

      lo_alv->display( ).

    CATCH cx_salv_msg
          cx_salv_not_found
          cx_salv_existing
          cx_salv_data_error INTO DATA(lx_salv).

      "---------------------------------------------------------------------*
      " 오류 원인을 메시지로 표시
      "---------------------------------------------------------------------*
      MESSAGE lx_salv->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.

  ENDTRY.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SHOW_BILLING_DETAIL
"&---------------------------------------------------------------------*
" 청구문서번호 클릭 -> 청구문서 Item 팝업 (SALV)
"----------------------------------------------------------------------*
FORM show_billing_detail
  USING iv_bilno TYPE ztsda00050-bilno.

  TYPES:
    BEGIN OF ty_bi_item,
      itmno TYPE ztsda00060-itmno,
      matnr TYPE ztsda00060-matnr,
      maktx TYPE ztcma00020-maktx,
      vleln TYPE ztsda00060-vleln,
      bilqt TYPE ztsda00060-bilqt,
      meins TYPE ztsda00060-meins,
      unitp TYPE ztsda00060-unitp,
      netam TYPE ztsda00060-netam,
      taxam TYPE ztsda00060-taxam,
      totam TYPE ztsda00060-totam,
    END OF ty_bi_item.

  DATA:
    lt_item TYPE STANDARD TABLE OF ty_bi_item,
    lo_alv  TYPE REF TO cl_salv_table,
    lo_cols TYPE REF TO cl_salv_columns_table,
    lo_col  TYPE REF TO cl_salv_column_table.

  IF iv_bilno IS INITIAL.
    RETURN.
  ENDIF.

  SELECT i~itmno,
         i~matnr,
         m~maktx,
         i~vleln,
         i~bilqt,
         i~meins,
         i~unitp,
         i~netam,
         i~taxam,
         i~totam
    FROM ztsda00060 AS i
    LEFT OUTER JOIN ztcma00020 AS m
      ON m~matnr = i~matnr
    WHERE i~bilno = @iv_bilno
    ORDER BY i~itmno
    INTO CORRESPONDING FIELDS OF TABLE @lt_item.

  IF lt_item IS INITIAL.
    MESSAGE s042(zmsga) WITH '청구문서 상세정보' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  TRY.

      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = lo_alv
        CHANGING
          t_table      = lt_item ).

      lo_alv->get_functions( )->set_all( abap_false ).

      lo_alv->get_display_settings( )->set_list_header(
        |청구문서 { iv_bilno } 상세정보| ).

      lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).

      lo_cols = lo_alv->get_columns( ).
      lo_cols->set_optimize( abap_true ).

      lo_col ?= lo_cols->get_column( 'ITMNO' ).
      lo_col->set_short_text( 'Item' ).
      lo_col->set_medium_text( 'Item' ).
      lo_col->set_long_text( 'Item' ).

      lo_col ?= lo_cols->get_column( 'MATNR' ).
      lo_col->set_short_text( '자재번호' ).
      lo_col->set_medium_text( '자재번호' ).
      lo_col->set_long_text( '자재번호' ).

      lo_col ?= lo_cols->get_column( 'MAKTX' ).
      lo_col->set_short_text( '자재명' ).
      lo_col->set_medium_text( '자재명' ).
      lo_col->set_long_text( '자재명' ).

      lo_col ?= lo_cols->get_column( 'VLELN' ).
      lo_col->set_short_text( '출고문서' ).
      lo_col->set_medium_text( '출고문서번호' ).
      lo_col->set_long_text( '출고문서번호' ).

      lo_col ?= lo_cols->get_column( 'BILQT' ).
      lo_col->set_short_text( '청구수량' ).
      lo_col->set_medium_text( '청구수량' ).
      lo_col->set_long_text( '청구수량' ).

      lo_col ?= lo_cols->get_column( 'MEINS' ).
      lo_col->set_short_text( '단위' ).
      lo_col->set_medium_text( '단위' ).
      lo_col->set_long_text( '단위' ).

      lo_col ?= lo_cols->get_column( 'UNITP' ).
      lo_col->set_short_text( '단가' ).
      lo_col->set_medium_text( '단가' ).
      lo_col->set_long_text( '단가' ).

      lo_col ?= lo_cols->get_column( 'NETAM' ).
      lo_col->set_short_text( '공급가액' ).
      lo_col->set_medium_text( '공급가액' ).
      lo_col->set_long_text( '공급가액' ).

      lo_col ?= lo_cols->get_column( 'TAXAM' ).
      lo_col->set_short_text( '세액' ).
      lo_col->set_medium_text( '세액' ).
      lo_col->set_long_text( '세액' ).

      lo_col ?= lo_cols->get_column( 'TOTAM' ).
      lo_col->set_short_text( '총액' ).
      lo_col->set_medium_text( '총액' ).
      lo_col->set_long_text( '총액' ).

      "---------------------------------------------------------------------*
      " 하단 합계 행 (청구수량 / 공급가액 / 세액 / 총액)
      "---------------------------------------------------------------------*
      DATA(lo_aggr) = lo_alv->get_aggregations( ).

      lo_aggr->add_aggregation( columnname = 'BILQT' ).
      lo_aggr->add_aggregation( columnname = 'NETAM' ).
      lo_aggr->add_aggregation( columnname = 'TAXAM' ).
      lo_aggr->add_aggregation( columnname = 'TOTAM' ).

      lo_alv->set_screen_popup(
        start_column = 15
        end_column   = 135
        start_line   = 5
        end_line     = 18 ).

      lo_alv->display( ).

    CATCH cx_salv_msg
          cx_salv_not_found
          cx_salv_existing
          cx_salv_data_error INTO DATA(lx_salv).

      MESSAGE lx_salv->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.

  ENDTRY.

ENDFORM.


"&---------------------------------------------------------------------*
"& FORM f4_kunnr_cust
"&---------------------------------------------------------------------*
FORM f4_kunnr_cust.

  " F4 목록 한 줄의 구조 : 고객번호 + 고객명
  TYPES: BEGIN OF ty_kunnr_f4,
           kunnr TYPE ztcma00050-kunnr,
           name1 TYPE ztcma00050-name1,
         END OF ty_kunnr_f4.

  DATA: lt_kunnr_f4 TYPE STANDARD TABLE OF ty_kunnr_f4,
        lt_return   TYPE STANDARD TABLE OF ddshretval,
        ls_return   TYPE ddshretval.

  " 고객번호 기준으로 중복 없이 조회 (한 고객에 배송처가 여러 건이어도 1줄)
  SELECT DISTINCT kunnr, name1
    FROM ztcma00050
   ORDER BY kunnr
    INTO TABLE @lt_kunnr_f4.

  IF lt_kunnr_f4 IS INITIAL.
    MESSAGE '조회할 고객이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 선택한 고객번호를 조회조건 필드(GV_S_KUNNR)에 바로 넣어 준다
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'KUNNR'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GV_S_KUNNR'
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

  " 선택 없이 팝업을 닫으면 return 테이블이 비어 있으므로 종료
  READ TABLE lt_return INTO ls_return INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  gv_s_kunnr = ls_return-fieldval.

ENDFORM.
