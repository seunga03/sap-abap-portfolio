"&---------------------------------------------------------------------*
"& Include          ZLSDA00030_F01
"&---------------------------------------------------------------------*
"& 출하처리(GI) / 출하 취소 / 조회 구현
"&---------------------------------------------------------------------*


"***********************************************************************
" 0. 공통
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form SET_TOOLBAR_EXCLUDE
"&---------------------------------------------------------------------*
" ALV 표준 버튼 숨김 (SD01 ~ SD04 공통 기준)
"----------------------------------------------------------------------*
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


"&---------------------------------------------------------------------*
"& Form GET_CUSTOMER_NAMES
"&---------------------------------------------------------------------*
" ZTCMA00050 키가 KUNNR + ADRCDE라 고객번호별 1건으로 묶어서 사용
"----------------------------------------------------------------------*
FORM get_customer_names
  CHANGING ct_cust TYPE tt_cust.

  CLEAR ct_cust.

  SELECT kunnr,
         MIN( name1 ) AS name1
    FROM ztcma00050
    GROUP BY kunnr
    INTO CORRESPONDING FIELDS OF TABLE @ct_cust.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form CHECK_DELIVERY_STOCK
"&---------------------------------------------------------------------*
" 출고문서 1건 출하 가능 여부
" SO 생성 시 MM 예약(ZTMMA00150)이 있으면 예약 기준으로 판정
"  (ZTMMA00070-STQTY는 예약이 이미 차감된 값이라 다시 비교하면 안 됨)
" 예약 정보가 없는 Item만 STQTY로 현재고 비교 (같은 자재는 합산)
"----------------------------------------------------------------------*
FORM check_delivery_stock
  USING    iv_vbeln TYPE ztsda00030-vbeln
  CHANGING cv_ready TYPE char1
           cv_text  TYPE char100.

  DATA:
    lt_item  TYPE STANDARD TABLE OF ztsda00040,
    ls_item  TYPE ztsda00040,
    lt_req   TYPE STANDARD TABLE OF ty_stock_req,
    ls_req   TYPE ty_stock_req,
    lv_stqty TYPE ztmma00070-stqty.

  cv_ready = 'N'.
  CLEAR cv_text.

  SELECT *
    FROM ztsda00040
    WHERE vbeln = @iv_vbeln
    INTO TABLE @lt_item.

  IF lt_item IS INITIAL.
    cv_text = '출고문서 Item 없음'.
    RETURN.
  ENDIF.

  "---------------------------------------------------------------------*
  " Item별 예약 확인
  "  예약 있음 : 미충족 수요(주문 - 기출고 - 배정) > 0 이면 조달 대기
  "  예약 없음 : 현재고 비교 대상으로 모음
  "---------------------------------------------------------------------*
  LOOP AT lt_item INTO ls_item.

    SELECT SINGLE ordqt, sumqt, avlqt
      FROM ztmma00150
      WHERE vbeln = @ls_item-vgbel
        AND posnr = @ls_item-posnv
      INTO @DATA(ls_res).

    IF sy-subrc = 0.

      IF ls_res-ordqt - ls_res-sumqt - ls_res-avlqt > 0.
        cv_text = |{ ls_item-matnr } 조달 대기 중 (입고 후 출하 가능)|.
        RETURN.
      ENDIF.

    ELSE.

      CLEAR ls_req.
      ls_req-matnr = ls_item-matnr.
      ls_req-werks = ls_item-werks.
      ls_req-lgort = ls_item-lgort.
      ls_req-reqty = ls_item-lfimg.

      COLLECT ls_req INTO lt_req.

    ENDIF.

  ENDLOOP.

  "---------------------------------------------------------------------*
  " 예약 정보가 없는 Item만 현재고 비교
  "---------------------------------------------------------------------*
  LOOP AT lt_req INTO ls_req.

    CLEAR lv_stqty.

    SELECT SINGLE stqty
      FROM ztmma00070
      WHERE matnr = @ls_req-matnr
        AND werks = @ls_req-werks
        AND lgort = @ls_req-lgort
      INTO @lv_stqty.

    IF sy-subrc <> 0.
      cv_text = |{ ls_req-matnr } 재고정보 없음|.
      RETURN.
    ENDIF.

    IF lv_stqty < ls_req-reqty.
      cv_text = |{ ls_req-matnr } 현재고 부족 (출고 { ls_req-reqty DECIMALS = 0 } / 현재고 { lv_stqty DECIMALS = 0 })|.
      RETURN.
    ENDIF.

  ENDLOOP.

  cv_ready = 'Y'.
  cv_text  = '출하 처리 가능'.

ENDFORM.



"***********************************************************************
" 1. 상단 ALV - 출하 대상 출고문서
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form DISPLAY_SHIP_ALV
"&---------------------------------------------------------------------*
FORM display_ship_alv.

  IF go_ship_container IS INITIAL.

    "---------------------------------------------------------------------*
    " 최초 조회 (기본조건 적용 후 조회)
    "---------------------------------------------------------------------*
    PERFORM set_default_search.

    "---------------------------------------------------------------------*
    " SD02에서 방금 만든 출고문서번호 받기
    " (SD02가 SAP 메모리 ID 'ZSD_NEW_DL'에 담아 두고 이 화면으로 이동)
    " 한 번 읽으면 지워서 다음 실행에는 영향이 없게 함
    "---------------------------------------------------------------------*
    CLEAR gt_new_dl.

    IMPORT gt_new_dl = gt_new_dl
      FROM MEMORY ID 'ZSD_NEW_DL'.

    FREE MEMORY ID 'ZSD_NEW_DL'.

    PERFORM search_ship.

    CREATE OBJECT go_ship_container
      EXPORTING
        container_name = 'CC_SHIP'.

    CREATE OBJECT go_ship_grid
      EXPORTING
        i_parent = go_ship_container.

    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.

    SET HANDLER:
      go_event_handler->handle_ship_toolbar       FOR go_ship_grid,
      go_event_handler->handle_ship_user_command  FOR go_ship_grid,
      go_event_handler->handle_ship_hotspot_click FOR go_ship_grid.

    PERFORM set_ship_fieldcat.
    PERFORM set_toolbar_exclude.

    CLEAR gs_ship_layo.
    gs_ship_layo-grid_title = '출하 대상 출고문서'.
    gs_ship_layo-zebra      = abap_true.
    gs_ship_layo-cwidth_opt = abap_false.     " 판정내용 너비 유지
    gs_ship_layo-sel_mode   = 'A'.
    gs_ship_layo-info_fname = 'ROW_COLOR'.    " 방금 생성된 문서 행 강조

    CALL METHOD go_ship_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_ship_layo
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab            = gt_ship
        it_fieldcatalog      = gt_ship_fcat.

    CALL METHOD go_ship_grid->set_toolbar_interactive.

    CALL METHOD go_ship_grid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.

    CALL METHOD cl_gui_cfw=>flush.

  ELSE.

    CALL METHOD go_ship_grid->refresh_table_display.

  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_SHIP_FIELDCAT
"&---------------------------------------------------------------------*
FORM set_ship_fieldcat.

  CLEAR gt_ship_fcat.

  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'NO'.
  gs_ship_fcat-coltext   = 'No'.
  gs_ship_fcat-outputlen = 4.
  APPEND gs_ship_fcat TO gt_ship_fcat.

  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'STATUS'.
  gs_ship_fcat-coltext   = '상태'.
  gs_ship_fcat-icon      = abap_true.
  gs_ship_fcat-outputlen = 6.
  APPEND gs_ship_fcat TO gt_ship_fcat.

  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'SHIP_STATUS'.
  gs_ship_fcat-coltext   = '출하상태'.
  gs_ship_fcat-outputlen = 10.
  APPEND gs_ship_fcat TO gt_ship_fcat.

  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'VBELN'.
  gs_ship_fcat-coltext   = '출고문서번호'.
  gs_ship_fcat-outputlen = 12.
  gs_ship_fcat-hotspot   = abap_true.
  APPEND gs_ship_fcat TO gt_ship_fcat.

  "---------------------------------------------------------------------*
  " 원본 판매오더번호 (SD02와 같은 순서 : 출고문서번호 바로 옆)
  "---------------------------------------------------------------------*
  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'SO_VBELN'.
  gs_ship_fcat-coltext   = '판매오더번호'.
  gs_ship_fcat-outputlen = 12.
  APPEND gs_ship_fcat TO gt_ship_fcat.

  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'KUNNR'.
  gs_ship_fcat-coltext   = '고객번호'.
  gs_ship_fcat-outputlen = 11.
  APPEND gs_ship_fcat TO gt_ship_fcat.

  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'NAME1'.
  gs_ship_fcat-coltext   = '고객명'.
  gs_ship_fcat-outputlen = 18.
  APPEND gs_ship_fcat TO gt_ship_fcat.

  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'VSTEL'.
  gs_ship_fcat-coltext   = '출하지점'.
  gs_ship_fcat-outputlen = 8.
  APPEND gs_ship_fcat TO gt_ship_fcat.

  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'TDDAT'.
  gs_ship_fcat-coltext   = '출하예정일'.
  gs_ship_fcat-outputlen = 10.
  APPEND gs_ship_fcat TO gt_ship_fcat.

  CLEAR gs_ship_fcat.
  gs_ship_fcat-fieldname = 'RESULT_TEXT'.
  gs_ship_fcat-coltext   = '판정내용'.
  gs_ship_fcat-outputlen = 60.
  APPEND gs_ship_fcat TO gt_ship_fcat.

ENDFORM.



"***********************************************************************
" 2. 출하 대상 조회 (R)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form SEARCH_SHIP
"&---------------------------------------------------------------------*
" 출하 완료 판단 : GISTA = 'C' 또는 실제출하일(ACGDT) 있음
" (기존 과거 데이터는 GISTA 없이 ACGDT만 있는 경우가 있어서 둘 다 확인)
"----------------------------------------------------------------------*
FORM search_ship.

  DATA:
    lt_delivery TYPE STANDARD TABLE OF ztsda00030,
    ls_delivery TYPE ztsda00030,
    lt_cust     TYPE tt_cust,
    ls_cust     TYPE ty_cust,
    lv_done     TYPE abap_bool,
    lv_no       TYPE i,

    lr_vbeln    TYPE RANGE OF ztsda00030-vbeln,
    lr_kunnr    TYPE RANGE OF ztsda00030-kunnr,
    lr_tddat    TYPE RANGE OF ztsda00030-tddat.

  CLEAR:
    gt_ship,
    gs_ship.

  "---------------------------------------------------------------------*
  " 조회조건 Range
  "---------------------------------------------------------------------*
  IF gv_s_vbeln IS NOT INITIAL.
    lr_vbeln = VALUE #( ( sign = 'I' option = 'EQ' low = gv_s_vbeln ) ).
  ENDIF.

  IF gv_s_kunnr IS NOT INITIAL.
    lr_kunnr = VALUE #( ( sign = 'I' option = 'EQ' low = gv_s_kunnr ) ).
  ENDIF.

  IF gv_s_tdfr IS NOT INITIAL AND gv_s_tdto IS NOT INITIAL.
    lr_tddat = VALUE #( ( sign = 'I' option = 'BT' low = gv_s_tdfr high = gv_s_tdto ) ).
  ELSEIF gv_s_tdfr IS NOT INITIAL.
    lr_tddat = VALUE #( ( sign = 'I' option = 'GE' low = gv_s_tdfr ) ).
  ELSEIF gv_s_tdto IS NOT INITIAL.
    lr_tddat = VALUE #( ( sign = 'I' option = 'LE' low = gv_s_tdto ) ).
  ENDIF.

  "---------------------------------------------------------------------*
  " 출고문서 Header
  "---------------------------------------------------------------------*
  SELECT *
    FROM ztsda00030
    WHERE vbeln IN @lr_vbeln
      AND kunnr IN @lr_kunnr
      AND tddat IN @lr_tddat
    INTO TABLE @lt_delivery.

  IF lt_delivery IS NOT INITIAL.
    PERFORM get_customer_names CHANGING lt_cust.
  ENDIF.

  "---------------------------------------------------------------------*
  " 출고문서 Loop
  "---------------------------------------------------------------------*
  LOOP AT lt_delivery INTO ls_delivery.

    lv_done = xsdbool( ls_delivery-gista = 'C'
                    OR ls_delivery-acgdt IS NOT INITIAL ).

    "---------------------------------------------------------------------*
    " 미출하만 조회
    "---------------------------------------------------------------------*
    IF rb_pending = 'X'
       AND lv_done = abap_true.
      CONTINUE.
    ENDIF.

    CLEAR gs_ship.

    gs_ship-vbeln = ls_delivery-vbeln.

    "---------------------------------------------------------------------*
    " 원본 판매오더번호 : 출고문서 Item(ZTSDA00040)의 VGBEL
    " 한 출고문서의 Item은 같은 SO에서 만들어지므로 첫 건만 읽는다
    " (SD02의 판매오더번호 조회와 같은 방식)
    "---------------------------------------------------------------------*
    SELECT SINGLE vgbel
      FROM ztsda00040
      WHERE vbeln = @ls_delivery-vbeln
      INTO @gs_ship-so_vbeln.

    gs_ship-kunnr = ls_delivery-kunnr.
    gs_ship-vstel = ls_delivery-vstel.
    gs_ship-tddat = ls_delivery-tddat.
    gs_ship-dlvst = ls_delivery-dlvst.
    gs_ship-gista = ls_delivery-gista.
    gs_ship-erdat = ls_delivery-erdat.
    gs_ship-erzet = ls_delivery-erzet.

    "---------------------------------------------------------------------*
    " SD02에서 방금 만든 문서는 노란색 행으로 강조
    "---------------------------------------------------------------------*
    IF line_exists( gt_new_dl[ table_line = ls_delivery-vbeln ] ).
      gs_ship-row_color = 'C310'.
    ENDIF.

    READ TABLE lt_cust INTO ls_cust
      WITH TABLE KEY kunnr = ls_delivery-kunnr.

    IF sy-subrc = 0.
      gs_ship-name1 = ls_cust-name1.
    ENDIF.

    "---------------------------------------------------------------------*
    " 출하 상태 판정
    "---------------------------------------------------------------------*
    IF lv_done = abap_true.

      gs_ship-ready_yn    = 'N'.
      gs_ship-status      = icon_checked.
      gs_ship-ship_status = '출하 완료'.
      gs_ship-result_text = |출하 완료 ({ ls_delivery-acgdt DATE = USER })|.

    ELSE.

      gs_ship-ship_status = '미출하'.

      PERFORM check_delivery_stock
        USING    ls_delivery-vbeln
        CHANGING gs_ship-ready_yn
                 gs_ship-result_text.

      IF gs_ship-ready_yn = 'Y'.
        gs_ship-status = icon_led_green.
      ELSE.
        gs_ship-status = icon_led_yellow.
      ENDIF.

    ENDIF.

    APPEND gs_ship TO gt_ship.

  ENDLOOP.

  "---------------------------------------------------------------------*
  " 정렬 : 방금 생성한 문서(노란색) 맨 위 → 출하 가능 우선 → 최신 생성순
  " (생성일·생성시간이 같으면 출고문서번호가 큰 것이 위)
  "---------------------------------------------------------------------*
  SORT gt_ship BY row_color DESCENDING
                  ready_yn  DESCENDING
                  erdat     DESCENDING
                  erzet     DESCENDING
                  vbeln     DESCENDING.

  LOOP AT gt_ship ASSIGNING FIELD-SYMBOL(<fs_ship>).
    lv_no = lv_no + 1.
    <fs_ship>-no = lv_no.
  ENDLOOP.

  IF go_ship_grid IS BOUND.
    CALL METHOD go_ship_grid->refresh_table_display.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

  "---------------------------------------------------------------------*
  " 결과 없음 메시지는 USER_COMMAND_0100(검색 버튼)에서 처리
  "---------------------------------------------------------------------*

ENDFORM.


"&---------------------------------------------------------------------*
"& Form CLEAR_SEARCH_CONDITION
"&---------------------------------------------------------------------*
FORM clear_search_condition.

  "---------------------------------------------------------------------*
  " 입력값 초기화 = 기본조건(이번 달~다음 달 출하예정일 / 미출하만)으로 되돌림
  "---------------------------------------------------------------------*
  PERFORM set_default_search.

  PERFORM search_ship.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_DEFAULT_SEARCH
"&---------------------------------------------------------------------*
" 기본 조회조건 : 출하예정일 이번 달 1일 ~ 다음 달 말일, 미출하만
" (SD02와 같은 기준)
"----------------------------------------------------------------------*
FORM set_default_search.

  DATA lv_next TYPE d.

  CLEAR:
    gv_s_vbeln,
    gv_s_kunnr,
    rb_all.

  rb_pending = 'X'.

  gv_s_tdfr = sy-datum.
  gv_s_tdfr+6(2) = '01'.

  lv_next = gv_s_tdfr + 32.

  CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
    EXPORTING
      day_in            = lv_next
    IMPORTING
      last_day_of_month = gv_s_tdto
    EXCEPTIONS
      day_in_no_date    = 1
      OTHERS            = 2.

  IF sy-subrc <> 0.
    gv_s_tdto = sy-datum + 60.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form REFRESH_SCREEN
"&---------------------------------------------------------------------*
FORM refresh_screen.

  PERFORM search_ship.
  PERFORM get_shipment_history.

ENDFORM.



"***********************************************************************
" 3. 선택 처리
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form SELECT_ALL_SHIP
"&---------------------------------------------------------------------*
FORM select_all_ship.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_ship ASSIGNING FIELD-SYMBOL(<fs_ship>).

    IF <fs_ship>-ready_yn = 'Y'.
      <fs_ship>-sel = 'X'.
      APPEND VALUE #( index = sy-tabix ) TO lt_rows.
    ELSE.
      CLEAR <fs_ship>-sel.
    ENDIF.

  ENDLOOP.

  IF go_ship_grid IS BOUND.
    CALL METHOD go_ship_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form DESELECT_ALL_SHIP
"&---------------------------------------------------------------------*
FORM deselect_all_ship.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_ship ASSIGNING FIELD-SYMBOL(<fs_ship>).
    CLEAR <fs_ship>-sel.
  ENDLOOP.

  IF go_ship_grid IS BOUND.
    CALL METHOD go_ship_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.



"***********************************************************************
" 4. 출하 처리 (GI)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form CONFIRM_POST_SHIPMENT
"&---------------------------------------------------------------------*
FORM confirm_post_shipment.

  DATA:
    lv_count    TYPE i,
    lv_answer   TYPE c LENGTH 1,
    lv_question TYPE string.

  IF go_ship_grid IS BOUND.
    PERFORM sync_ship_sel.
  ENDIF.

  "---------------------------------------------------------------------*
  " 처리 불가 문서 선택 시 차단
  "---------------------------------------------------------------------*
  IF line_exists( gt_ship[ sel = 'X' ready_yn = 'N' ] ).
    MESSAGE i036(zmsga).
    RETURN.
  ENDIF.

  LOOP AT gt_ship TRANSPORTING NO FIELDS WHERE sel = 'X'.
    lv_count = lv_count + 1.
  ENDLOOP.

  IF lv_count = 0.
    MESSAGE i014(zmsga).
    RETURN.
  ENDIF.

  MESSAGE s213(zmsga) WITH lv_count INTO lv_question.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '출하 처리'
      text_question         = lv_question
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer = '1'.
    PERFORM post_shipment.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form POST_SHIPMENT
"&---------------------------------------------------------------------*
" - 처리 직전에 DB 기준으로 출하 여부 / 재고 재확인
" - 재고 부족·이미 출하된 문서는 건너뛰고 나머지 처리
" - DB 오류 시 이번 실행분 전체 ROLLBACK
" - 부분 출하 없음 (출고문서 단위 전체 처리)
"----------------------------------------------------------------------*
FORM post_shipment.

  DATA:
    lt_sel       TYPE STANDARD TABLE OF ty_ship,
    ls_sel       TYPE ty_ship,
    lv_gista     TYPE ztsda00030-gista,
    lv_acgdt     TYPE ztsda00030-acgdt,
    lv_ready     TYPE char1,
    lv_text      TYPE char100,
    lv_subrc     TYPE sy-subrc,
    lv_err_text  TYPE string,
    lv_posted    TYPE i,
    lv_skipped   TYPE i,
    lv_skip_text TYPE string.

  IF go_ship_grid IS BOUND.
    PERFORM sync_ship_sel.
  ENDIF.

  lt_sel = VALUE #( FOR wa IN gt_ship WHERE ( sel = 'X' ) ( wa ) ).

  CLEAR gt_new_gi.

  LOOP AT lt_sel INTO ls_sel.

    "---------------------------------------------------------------------*
    " DB 기준 출하 여부 재확인
    "---------------------------------------------------------------------*
    CLEAR:
      lv_gista,
      lv_acgdt.

    SELECT SINGLE gista, acgdt
      FROM ztsda00030
      WHERE vbeln = @ls_sel-vbeln
      INTO (@lv_gista, @lv_acgdt).

    IF sy-subrc <> 0
       OR lv_gista = 'C'
       OR lv_acgdt IS NOT INITIAL.

      lv_skipped = lv_skipped + 1.
      IF lv_skip_text IS INITIAL.
        lv_skip_text = |{ ls_sel-vbeln }: 이미 출하되었거나 없는 문서|.
      ENDIF.
      CONTINUE.

    ENDIF.

    "---------------------------------------------------------------------*
    " 처리 시점 재고 재확인 (앞에서 처리한 문서의 차감도 반영됨)
    "---------------------------------------------------------------------*
    PERFORM check_delivery_stock
      USING    ls_sel-vbeln
      CHANGING lv_ready
               lv_text.

    IF lv_ready <> 'Y'.

      lv_skipped = lv_skipped + 1.
      IF lv_skip_text IS INITIAL.
        lv_skip_text = |{ ls_sel-vbeln }: { lv_text }|.
      ENDIF.
      CONTINUE.

    ENDIF.

    "---------------------------------------------------------------------*
    " 출하 처리
    "---------------------------------------------------------------------*
    CLEAR lv_err_text.

    PERFORM post_one_delivery
      USING    ls_sel-vbeln
      CHANGING lv_subrc
               lv_err_text.

    IF lv_subrc <> 0.

      ROLLBACK WORK.

      CLEAR gt_new_gi.

      "---------------------------------------------------------------------*
      " 실패 원인을 같이 보여줌 (예: MM 재고 부족, 저장위치 재고 없음 등)
      "---------------------------------------------------------------------*
      IF lv_err_text IS INITIAL.
        MESSAGE i067(zmsga) WITH |출고문서 { ls_sel-vbeln } 출하 처리|.
      ELSE.
        MESSAGE |출고문서 { ls_sel-vbeln } 출하 처리 중 오류: { lv_err_text }|
          TYPE 'I'.
      ENDIF.

      PERFORM refresh_screen.

      RETURN.

    ENDIF.

    APPEND ls_sel-vbeln TO gt_new_gi.

    lv_posted = lv_posted + 1.

  ENDLOOP.

  "---------------------------------------------------------------------*
  " 처리 0건
  "---------------------------------------------------------------------*
  IF lv_posted = 0.

    IF lv_skip_text IS INITIAL.
      MESSAGE i018(zmsga).
    ELSE.
      MESSAGE i208(zmsga) WITH lv_skip_text.
    ENDIF.

    PERFORM search_ship.

    RETURN.

  ENDIF.

  COMMIT WORK AND WAIT.

  "---------------------------------------------------------------------*
  " 재조회 : 상단에서 빠지고 하단 출하 완료 내역에 노란색으로 표시
  "---------------------------------------------------------------------*
  PERFORM refresh_screen.

  IF lv_skipped = 0.
    MESSAGE s006(zmsga) WITH lv_posted.
  ELSE.
    MESSAGE i207(zmsga) WITH lv_posted lv_skipped lv_skip_text.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form POST_ONE_DELIVERY
"&---------------------------------------------------------------------*
" MM GI 함수(ZFM_MM_MATERIAL_GI) 호출로 교체
" 1. 재고/예약재고(ZTMMA00070, ZTMMA00150) 갱신 : MM 함수가 처리 (651 출고)
" 2. 출고문서 : GISTA = 'C', ACGDT = 오늘
" 3. 판매오더 : SOSTA DO → GI
" ※ MM 함수 내부에 COMMIT 없음 → 호출부(post_shipment)가 COMMIT/ROLLBACK
"----------------------------------------------------------------------*
FORM post_one_delivery
  USING    iv_vbeln TYPE ztsda00030-vbeln
  CHANGING cv_subrc TYPE sy-subrc
           cv_text  TYPE string.

  DATA:
    lt_item TYPE STANDARD TABLE OF ztsda00040,
    ls_item TYPE ztsda00040,
    lt_so   TYPE tt_vgbel,
    lv_so   TYPE ztsda00040-vgbel,
    lt_gi   TYPE zttmma00132,
    ls_gi   LIKE LINE OF lt_gi,
    lt_mat  TYPE zttmma00090,
    lt_ret  TYPE STANDARD TABLE OF bapiret2,
    ls_ret  TYPE bapiret2.

  "---------------------------------------------------------------------*
  " 기본값 : 실패(4) + 원인 텍스트 초기화
  " (성공할 때만 마지막에 0으로 바꾼다)
  "---------------------------------------------------------------------*
  cv_subrc = 4.
  CLEAR cv_text.

  "---------------------------------------------------------------------*
  " 출고문서 Item 읽기
  "---------------------------------------------------------------------*
  SELECT *
    FROM ztsda00040
    WHERE vbeln = @iv_vbeln
    INTO TABLE @lt_item.

  IF lt_item IS INITIAL.
    cv_text = '출고문서 Item이 없습니다.'.
    RETURN.
  ENDIF.

  "---------------------------------------------------------------------*
  " MM GI 함수 호출 (ZSMMA00132 : 납품/SO 품목 + 출고수량)
  "---------------------------------------------------------------------*
  LOOP AT lt_item INTO ls_item.

    CLEAR ls_gi.

    ls_gi-vbeln_vl = ls_item-vbeln.
    ls_gi-posnr_d  = ls_item-posnr.
    ls_gi-vbeln    = ls_item-vgbel.
    ls_gi-posnr_s  = ls_item-posnv.
    ls_gi-matnr    = ls_item-matnr.
    ls_gi-werks    = ls_item-werks.
    ls_gi-lgort    = ls_item-lgort.
    ls_gi-giqty    = ls_item-lfimg.
    ls_gi-meins    = ls_item-meins.

    APPEND ls_gi TO lt_gi.

  ENDLOOP.

  CALL FUNCTION 'ZFM_MM_MATERIAL_GI'
    EXPORTING
      gi_input    = lt_gi
    IMPORTING
      gi_material = lt_mat
    TABLES
      et_return   = lt_ret.

  "---------------------------------------------------------------------*
  " MM 함수 결과 확인 : E/A/X 메시지가 하나라도 있으면 실패
  " → MM이 돌려준 메시지를 그대로 화면에 보여주기 위해 cv_text에 담는다
  "---------------------------------------------------------------------*
  LOOP AT lt_ret INTO ls_ret
       WHERE type = 'E' OR type = 'A' OR type = 'X'.
    EXIT.
  ENDLOOP.

  IF sy-subrc = 0.
    cv_text = ls_ret-message.
    IF cv_text IS INITIAL.
      cv_text = 'MM 출고 처리(ZFM_MM_MATERIAL_GI)에서 오류가 반환되었습니다.'.
    ENDIF.
    RETURN.            " cv_subrc = 4 → 호출부에서 전체 ROLLBACK
  ENDIF.

  "---------------------------------------------------------------------*
  " 출고문서 출하 완료
  "---------------------------------------------------------------------*
  UPDATE ztsda00030
    SET gista = 'C',
        acgdt = @sy-datum,
        aenam = @sy-uname,
        aedat = @sy-datum,
        aezet = @sy-uzeit
    WHERE vbeln = @iv_vbeln
      AND gista <> 'C'.

  IF sy-subrc <> 0.
    cv_text = '출고문서 상태(GISTA) 변경에 실패했습니다.'.
    RETURN.
  ENDIF.

  "---------------------------------------------------------------------*
  " 판매오더 상태 DO → GI
  "---------------------------------------------------------------------*
  SELECT DISTINCT vgbel
    FROM ztsda00040
    WHERE vbeln = @iv_vbeln
    INTO TABLE @lt_so.

  LOOP AT lt_so INTO lv_so.

    UPDATE ztsda00010
      SET sosta = 'GI',
          aenam = @sy-uname,
          aedat = @sy-datum,
          aezet = @sy-uzeit
      WHERE vbeln = @lv_so
        AND sosta = 'DO'.

  ENDLOOP.

  cv_subrc = 0.

ENDFORM.



"***********************************************************************
" 5. 하단 ALV - 출하 완료 내역
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form DISPLAY_HIST_ALV
"&---------------------------------------------------------------------*
FORM display_hist_alv.

  IF go_hist_container IS INITIAL.

    PERFORM get_shipment_history.

    CREATE OBJECT go_hist_container
      EXPORTING
        container_name = 'CC_HIST'.

    CREATE OBJECT go_hist_grid
      EXPORTING
        i_parent = go_hist_container.

    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.

"---------------------------------------------------------------------*
" 하단 ALV 이벤트 : 구분선 툴바 + 출고문서번호 클릭
" (청구 버튼 삭제로 user_command 핸들러는 사용하지 않음)
"---------------------------------------------------------------------*
    SET HANDLER:
      go_event_handler->handle_hist_toolbar       FOR go_hist_grid,
      go_event_handler->handle_hist_hotspot_click FOR go_hist_grid.

    PERFORM set_hist_fieldcat.
    PERFORM set_toolbar_exclude.

    CLEAR gs_hist_layo.
    gs_hist_layo-grid_title = '출하 완료 내역'.
    gs_hist_layo-zebra      = abap_true.
    gs_hist_layo-cwidth_opt = abap_true.
    gs_hist_layo-sel_mode   = 'A'.
    gs_hist_layo-info_fname = 'ROW_COLOR'.

    CALL METHOD go_hist_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_hist_layo
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab            = gt_hist
        it_fieldcatalog      = gt_hist_fcat.

    CALL METHOD go_hist_grid->set_toolbar_interactive.

    CALL METHOD go_hist_grid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.

    CALL METHOD cl_gui_cfw=>flush.

  ELSE.

    CALL METHOD go_hist_grid->refresh_table_display.

  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_HIST_FIELDCAT
"&---------------------------------------------------------------------*
FORM set_hist_fieldcat.

  CLEAR gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'NO'.
  gs_hist_fcat-coltext   = 'No'.
  gs_hist_fcat-outputlen = 4.
  APPEND gs_hist_fcat TO gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'STATUS'.
  gs_hist_fcat-coltext   = '상태'.
  gs_hist_fcat-icon      = abap_true.
  gs_hist_fcat-outputlen = 6.
  APPEND gs_hist_fcat TO gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'SHIP_STATUS'.
  gs_hist_fcat-coltext   = '출하상태'.
  gs_hist_fcat-outputlen = 10.
  APPEND gs_hist_fcat TO gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'VBELN'.
  gs_hist_fcat-coltext   = '출고문서번호'.
  gs_hist_fcat-outputlen = 12.
  gs_hist_fcat-hotspot   = abap_true.
  APPEND gs_hist_fcat TO gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'SO_VBELN'.
  gs_hist_fcat-coltext   = '판매오더번호'.
  gs_hist_fcat-outputlen = 12.
  APPEND gs_hist_fcat TO gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'KUNNR'.
  gs_hist_fcat-coltext   = '고객번호'.
  gs_hist_fcat-outputlen = 11.
  APPEND gs_hist_fcat TO gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'NAME1'.
  gs_hist_fcat-coltext   = '고객명'.
  gs_hist_fcat-outputlen = 18.
  APPEND gs_hist_fcat TO gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'VSTEL'.
  gs_hist_fcat-coltext   = '출하지점'.
  gs_hist_fcat-outputlen = 8.
  APPEND gs_hist_fcat TO gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'TDDAT'.
  gs_hist_fcat-coltext   = '출하예정일'.
  gs_hist_fcat-outputlen = 10.
  APPEND gs_hist_fcat TO gt_hist_fcat.

  CLEAR gs_hist_fcat.
  gs_hist_fcat-fieldname = 'ACGDT'.
  gs_hist_fcat-coltext   = '실제출하일'.
  gs_hist_fcat-outputlen = 10.
  APPEND gs_hist_fcat TO gt_hist_fcat.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form GET_SHIPMENT_HISTORY
"&---------------------------------------------------------------------*
FORM get_shipment_history.

  DATA:
    lt_delivery TYPE STANDARD TABLE OF ztsda00030,
    ls_delivery TYPE ztsda00030,
    lt_cust     TYPE tt_cust,
    ls_cust     TYPE ty_cust,
    lv_no       TYPE i.

  CLEAR:
    gt_hist,
    gs_hist.

  "---------------------------------------------------------------------*
  " 출하 완료 문서 (GISTA = C 또는 실제출하일 있음)
  "---------------------------------------------------------------------*
  SELECT *
    FROM ztsda00030
    WHERE gista = 'C'
       OR acgdt IS NOT INITIAL
    INTO TABLE @lt_delivery.

  IF lt_delivery IS NOT INITIAL.
    PERFORM get_customer_names CHANGING lt_cust.
  ENDIF.

  LOOP AT lt_delivery INTO ls_delivery.

    CLEAR gs_hist.

    gs_hist-vbeln       = ls_delivery-vbeln.
    "---------------------------------------------------------------------*
    " 원본 판매오더번호 : 출고문서 Item(ZTSDA00040)의 VGBEL (첫 건)
    "---------------------------------------------------------------------*
    SELECT SINGLE vgbel
      FROM ztsda00040
      WHERE vbeln = @ls_delivery-vbeln
      INTO @gs_hist-so_vbeln.
    gs_hist-kunnr       = ls_delivery-kunnr.
    gs_hist-vstel       = ls_delivery-vstel.
    gs_hist-tddat       = ls_delivery-tddat.
    gs_hist-gista       = ls_delivery-gista.
    gs_hist-acgdt       = ls_delivery-acgdt.
    gs_hist-status      = icon_checked.
    gs_hist-ship_status = '출하 완료'.

    READ TABLE lt_cust INTO ls_cust
      WITH TABLE KEY kunnr = ls_delivery-kunnr.

    IF sy-subrc = 0.
      gs_hist-name1 = ls_cust-name1.
    ENDIF.

    "---------------------------------------------------------------------*
    " 방금 출하 처리한 문서 노란색
    "---------------------------------------------------------------------*
    IF line_exists( gt_new_gi[ table_line = ls_delivery-vbeln ] ).
      gs_hist-row_color = 'C310'.
    ENDIF.

    APPEND gs_hist TO gt_hist.

  ENDLOOP.

  "---------------------------------------------------------------------*
  " 최근 출하 순
  "---------------------------------------------------------------------*
  SORT gt_hist BY acgdt DESCENDING
                  vbeln DESCENDING.

  LOOP AT gt_hist ASSIGNING FIELD-SYMBOL(<fs_hist>).
    lv_no = lv_no + 1.
    <fs_hist>-no = lv_no.
  ENDLOOP.

  IF go_hist_grid IS BOUND.
    CALL METHOD go_hist_grid->refresh_table_display.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.



"***********************************************************************
" 6. (삭제) 출하 취소 기능 : 출하 후에는 청구 화면(SD04)으로 바로 이동
"***********************************************************************



"***********************************************************************
" 7. Navigation
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form MOVE_TO_SD04
"&---------------------------------------------------------------------*
" 출하 완료 후 청구 화면(ZSD04)으로 바로 이동
" - 출하 취소 버튼을 없애는 대신 업무 흐름(출하 → 청구)을 이어주는 버튼
"----------------------------------------------------------------------*
FORM move_to_sd04.

  LEAVE TO TRANSACTION 'ZSD04'.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form MOVE_TO_SD02
"&---------------------------------------------------------------------*
FORM move_to_sd02.

  LEAVE TO TRANSACTION 'ZSD02'.

  PERFORM refresh_screen.

ENDFORM.



"***********************************************************************
" 8. 출고문서 Item 상세 팝업 (출고문서번호 클릭)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form SHOW_DELIVERY_DETAIL
"&---------------------------------------------------------------------*
" 출고문서번호를 클릭하면 해당 출고문서의 Item을 팝업으로 표시
" (SALV 팝업 - 별도 화면 없음)
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



"***********************************************************************
" 9. ALV 행 선택 -> SEL 값 반영 (드래그 / Shift / Ctrl 선택 지원)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form SYNC_SHIP_SEL
"&---------------------------------------------------------------------*
FORM sync_ship_sel.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_ship ASSIGNING FIELD-SYMBOL(<fs_ship>).
    CLEAR <fs_ship>-sel.
  ENDLOOP.

  IF go_ship_grid IS NOT BOUND.
    RETURN.
  ENDIF.

  CALL METHOD go_ship_grid->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_ship ASSIGNING <fs_ship> INDEX ls_row-index.
    IF sy-subrc = 0.
      <fs_ship>-sel = 'X'.
    ENDIF.
  ENDLOOP.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SYNC_HIST_SEL
"&---------------------------------------------------------------------*
FORM sync_hist_sel.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_hist ASSIGNING FIELD-SYMBOL(<fs_hist>).
    CLEAR <fs_hist>-sel.
  ENDLOOP.

  IF go_hist_grid IS NOT BOUND.
    RETURN.
  ENDIF.

  CALL METHOD go_hist_grid->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_hist ASSIGNING <fs_hist> INDEX ls_row-index.
    IF sy-subrc = 0.
      <fs_hist>-sel = 'X'.
    ENDIF.
  ENDLOOP.

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
