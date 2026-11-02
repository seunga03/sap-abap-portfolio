"&---------------------------------------------------------------------*
"& Include          ZLSDA00020_F01
"&---------------------------------------------------------------------*


"&---------------------------------------------------------------------*
"& Form SELECT_ALL_DELIVERY
"&---------------------------------------------------------------------*
" 미출하(GI 미완료) 출고문서 전체 선택
"----------------------------------------------------------------------*
FORM select_all_delivery.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_de ASSIGNING FIELD-SYMBOL(<fs_de>).

    IF <fs_de>-gista <> 'C'.
      <fs_de>-sel = 'X'.
      APPEND VALUE #( index = sy-tabix ) TO lt_rows.
    ELSE.
      CLEAR <fs_de>-sel.
    ENDIF.

  ENDLOOP.

  IF go_de_grid IS BOUND.
    CALL METHOD go_de_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.


"***********************************************************************
" 0. 공통
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form VALIDATE_SEARCH_CONDITION
"&---------------------------------------------------------------------*
FORM validate_search_condition.

  IF gv_s_reqfr IS NOT INITIAL
     AND gv_s_reqto IS NOT INITIAL
     AND gv_s_reqfr > gv_s_reqto.

    MESSAGE e026(zmsga).

  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_TOOLBAR_EXCLUDE
"&---------------------------------------------------------------------*
" ALV 표준 편집 버튼 숨김
" 체크박스 때문에 Grid가 입력가능 상태라 행 삽입/삭제 버튼이 보이는데,
" 이걸 누르면 내부테이블만 바뀌고 DB와 어긋나므로 숨김
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
" 고객번호별 고객명 1건
" ZTCMA00050 키가 KUNNR + ADRCDE라 JOIN 시 중복행이 생길 수 있음
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
"& Form GET_AVAILABLE_QTY
"&---------------------------------------------------------------------*
" 출고 가능 재고 = 현재고(STQTY) - 아직 출하(GI) 안 된 Delivery 수량
"
" STQTY는 GI 시점에 차감되므로, Delivery만 만들어진 수량은
" 아직 STQTY에 남아 있음 → 빼주지 않으면 같은 재고로 중복 생성됨
"
" 같은 LUW에서 방금 INSERT한 Delivery도 SUM에 포함되므로
" 여러 건을 한 번에 생성할 때도 재고가 중복 할당되지 않음
"----------------------------------------------------------------------*
FORM get_available_qty
  USING    iv_matnr TYPE ztsda00020-matnr
           iv_werks TYPE ztsda00020-werks
           iv_lgort TYPE ztsda00020-lgort
  CHANGING cv_avail TYPE ztmma00070-stqty
           cv_found TYPE abap_bool.

  DATA:
    lv_stqty TYPE ztmma00070-stqty,
    lv_open  TYPE ztsda00040-lfimg.

  CLEAR:
    cv_avail,
    cv_found.

"---------------------------------------------------------------------*
" 현재고
"---------------------------------------------------------------------*
  SELECT SINGLE stqty
    FROM ztmma00070
    WHERE matnr = @iv_matnr
      AND werks = @iv_werks
      AND lgort = @iv_lgort
    INTO @lv_stqty.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  cv_found = abap_true.

"---------------------------------------------------------------------*
" 미출하 Delivery 수량
"---------------------------------------------------------------------*
  SELECT SUM( b~lfimg )
    FROM ztsda00030 AS a
    INNER JOIN ztsda00040 AS b
      ON b~vbeln = a~vbeln
    WHERE a~gista <> 'C'
      AND b~matnr = @iv_matnr
      AND b~werks = @iv_werks
      AND b~lgort = @iv_lgort
    INTO @lv_open.

  cv_avail = lv_stqty - lv_open.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form CHECK_SO_STOCK
"&---------------------------------------------------------------------*
" 판매오더 1건의 출고 가능 여부
" SD01 생성 시 MM 예약(ZTMMA00150)이 있으면 예약 기준으로 판정
"  (ZTMMA00070-STQTY는 예약이 이미 차감된 값이라 다시 비교하면 안 됨)
" 예약 정보가 없는 Item만 STQTY로 가용재고 비교
"----------------------------------------------------------------------*
FORM check_so_stock
  USING    it_item  TYPE tt_so_item
  CHANGING cv_ready TYPE char1
           cv_text  TYPE char100.

  DATA:
    lt_req   TYPE STANDARD TABLE OF ty_stock_req,
    ls_req   TYPE ty_stock_req,
    ls_item  TYPE ztsda00020,
    lv_avail TYPE ztmma00070-stqty,
    lv_found TYPE abap_bool.

  cv_ready = 'Y'.
  CLEAR cv_text.


"---------------------------------------------------------------------*
" Item별 예약 확인
"  예약 있음 : 미충족 수요(주문 - 기출고 - 배정) > 0 이면 조달 대기
"  예약 없음 : 가용재고 비교 대상으로 모음
"---------------------------------------------------------------------*
  LOOP AT it_item INTO ls_item.

    SELECT SINGLE ordqt, sumqt, avlqt
      FROM ztmma00150
      WHERE vbeln = @ls_item-vbeln
        AND posnr = @ls_item-posnr
      INTO @DATA(ls_res).

    IF sy-subrc = 0.

      IF ls_res-ordqt - ls_res-sumqt - ls_res-avlqt > 0.
        cv_ready = 'N'.
        cv_text  = |{ ls_item-matnr } 조달 대기 중 (입고 후 출고 가능)|.
        RETURN.
      ENDIF.

    ELSE.

      CLEAR ls_req.
      ls_req-matnr = ls_item-matnr.
      ls_req-werks = ls_item-werks.
      ls_req-lgort = ls_item-lgort.
      ls_req-reqty = ls_item-kwmeng.

      COLLECT ls_req INTO lt_req.

    ENDIF.

  ENDLOOP.


"---------------------------------------------------------------------*
" 예약 정보가 없는 Item만 가용재고 비교
"---------------------------------------------------------------------*
  LOOP AT lt_req INTO ls_req.

    PERFORM get_available_qty
      USING    ls_req-matnr
               ls_req-werks
               ls_req-lgort
      CHANGING lv_avail
               lv_found.

    IF lv_found = abap_false.
      cv_ready = 'N'.
      cv_text  = |{ ls_req-matnr } 재고정보 없음|.
      RETURN.
    ENDIF.

    IF lv_avail < ls_req-reqty.
      cv_ready = 'N'.
      cv_text  = |{ ls_req-matnr } 가용재고 부족 (필요 { ls_req-reqty DECIMALS = 0 } / 가용 { lv_avail DECIMALS = 0 })|.
      RETURN.
    ENDIF.

  ENDLOOP.

ENDFORM.



"***********************************************************************
" 1. 상단 ALV
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form DISPLAY_SO_ALV
"&---------------------------------------------------------------------*
FORM display_so_alv.

  IF go_so_container IS INITIAL.

"---------------------------------------------------------------------*
" 최초 데이터 조회 (Grid 생성 전에 조회)
"---------------------------------------------------------------------*
    PERFORM search_so.

    CREATE OBJECT go_so_container
      EXPORTING
        container_name = 'CC_SO'.

    CREATE OBJECT go_so_grid
      EXPORTING
        i_parent = go_so_container.

    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.

    SET HANDLER go_event_handler->handle_so_toolbar       FOR go_so_grid.
    SET HANDLER go_event_handler->handle_so_user_command  FOR go_so_grid.
    SET HANDLER go_event_handler->handle_so_hotspot_click FOR go_so_grid.

    PERFORM set_so_fieldcat.
    PERFORM set_toolbar_exclude.

    CLEAR gs_so_layo.
    gs_so_layo-grid_title = '출고대상 판매오더'.
    gs_so_layo-zebra      = abap_true.
    gs_so_layo-cwidth_opt = abap_false.
    gs_so_layo-sel_mode   = 'A'.

    CALL METHOD go_so_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_so_layo
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab            = gt_so
        it_fieldcatalog      = gt_so_fcat.

    CALL METHOD go_so_grid->set_toolbar_interactive.

    CALL METHOD go_so_grid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.

    CALL METHOD cl_gui_cfw=>flush.

  ELSE.

    CALL METHOD go_so_grid->refresh_table_display.

  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_SO_FIELDCAT
"&---------------------------------------------------------------------*
FORM set_so_fieldcat.

  CLEAR gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'NO'.
  gs_so_fcat-coltext   = 'No'.
  gs_so_fcat-outputlen = 4.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'STATUS'.
  gs_so_fcat-coltext   = '상태'.
  gs_so_fcat-icon      = abap_true.
  gs_so_fcat-outputlen = 6.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'SHIP_STATUS'.
  gs_so_fcat-coltext   = '처리상태'.
  gs_so_fcat-outputlen = 12.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'VBELN'.
  gs_so_fcat-coltext   = '판매오더번호'.
  gs_so_fcat-outputlen = 12.
  gs_so_fcat-hotspot   = abap_true.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'KUNNR'.
  gs_so_fcat-coltext   = '고객번호'.
  gs_so_fcat-outputlen = 12.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'NAME1'.
  gs_so_fcat-coltext   = '고객명'.
  gs_so_fcat-outputlen = 18.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'ITEM_CNT'.
  gs_so_fcat-coltext   = 'Item수'.
  gs_so_fcat-outputlen = 7.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'REQDT'.
  gs_so_fcat-coltext   = '요청납기일'.
  gs_so_fcat-outputlen = 10.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'RESULT_TEXT'.
  gs_so_fcat-coltext   = '판정내용'.
  gs_so_fcat-outputlen = 60.
  APPEND gs_so_fcat TO gt_so_fcat.

ENDFORM.



"***********************************************************************
" 2. SO 조회 (R)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form SEARCH_SO
"&---------------------------------------------------------------------*
FORM search_so.

  DATA:
    lt_header   TYPE STANDARD TABLE OF ztsda00010,
    ls_header   TYPE ztsda00010,
    lt_item_all TYPE tt_so_item,
    lt_item     TYPE tt_so_item,
    ls_item     TYPE ztsda00020,
    lt_cust     TYPE tt_cust,
    ls_cust     TYPE ty_cust,

    lr_vbeln    TYPE RANGE OF ztsda00010-vbeln,
    lr_kunnr    TYPE RANGE OF ztsda00010-kunnr.

  CLEAR:
    gt_so,
    gs_so.

"---------------------------------------------------------------------*
" 조회조건
" 판매오더번호가 있으면 그것만 / 없으면 고객번호 / 둘 다 없으면 전체
"---------------------------------------------------------------------*
  IF gv_s_vbeln IS NOT INITIAL.
    lr_vbeln = VALUE #( ( sign = 'I' option = 'EQ' low = gv_s_vbeln ) ).
  ELSEIF gv_s_kunnr IS NOT INITIAL.
    lr_kunnr = VALUE #( ( sign = 'I' option = 'EQ' low = gv_s_kunnr ) ).
  ENDIF.

"---------------------------------------------------------------------*
" SO Header
"---------------------------------------------------------------------*
  SELECT *
    FROM ztsda00010
    WHERE sosta = 'SO'
      AND vbeln IN @lr_vbeln
      AND kunnr IN @lr_kunnr
    INTO TABLE @lt_header.

"---------------------------------------------------------------------*
" SO Item (한 번에 조회)
"---------------------------------------------------------------------*
  IF lt_header IS NOT INITIAL.

    SELECT *
      FROM ztsda00020
      FOR ALL ENTRIES IN @lt_header
      WHERE vbeln = @lt_header-vbeln
      INTO TABLE @lt_item_all.

    PERFORM get_customer_names CHANGING lt_cust.

  ENDIF.

"---------------------------------------------------------------------*
" Header Loop
"---------------------------------------------------------------------*
  LOOP AT lt_header INTO ls_header.

    CLEAR gs_so.

    gs_so-vbeln = ls_header-vbeln.
    gs_so-kunnr = ls_header-kunnr.
    gs_so-erdat = ls_header-erdat.
    gs_so-erzet = ls_header-erzet.

    READ TABLE lt_cust INTO ls_cust
      WITH TABLE KEY kunnr = ls_header-kunnr.

    IF sy-subrc = 0.
      gs_so-name1 = ls_cust-name1.
    ENDIF.

"---------------------------------------------------------------------*
" 해당 SO의 Item
"---------------------------------------------------------------------*
    lt_item = VALUE #( FOR wa IN lt_item_all
                         WHERE ( vbeln = ls_header-vbeln )
                         ( wa ) ).

    IF lt_item IS INITIAL.
      CONTINUE.
    ENDIF.

    gs_so-item_cnt = lines( lt_item ).

"---------------------------------------------------------------------*
" 가장 빠른 요청납기일
"---------------------------------------------------------------------*
    LOOP AT lt_item INTO ls_item.
      IF gs_so-reqdt IS INITIAL
         OR ls_item-reqdt < gs_so-reqdt.
        gs_so-reqdt = ls_item-reqdt.
      ENDIF.
    ENDLOOP.

"---------------------------------------------------------------------*
" 요청납기일 조건 (판매오더번호 직접 입력 시 미적용)
"---------------------------------------------------------------------*
    IF gv_s_vbeln IS INITIAL
       AND gv_s_reqfr IS NOT INITIAL
       AND gs_so-reqdt < gv_s_reqfr.
      CONTINUE.
    ENDIF.

    IF gv_s_vbeln IS INITIAL
       AND gv_s_reqto IS NOT INITIAL
       AND gs_so-reqdt > gv_s_reqto.
      CONTINUE.
    ENDIF.

"---------------------------------------------------------------------*
" 재고 검사
"---------------------------------------------------------------------*
    PERFORM check_so_stock
      USING    lt_item
      CHANGING gs_so-ready_yn
               gs_so-result_text.

    IF gs_so-ready_yn = 'Y'.
      gs_so-status      = icon_led_green.
      gs_so-ship_status = '출고가능'.
      gs_so-result_text = '전체 품목 재고 확보 완료'.
    ELSE.
      gs_so-status      = icon_led_yellow.
      gs_so-ship_status = '출고대기'.
    ENDIF.

"---------------------------------------------------------------------*
" 출고 대상만 (판매오더번호 직접 입력 시 미적용)
"---------------------------------------------------------------------*
    IF gv_s_vbeln IS INITIAL
       AND rb_target = 'X'
       AND gs_so-ready_yn <> 'Y'.
      CONTINUE.
    ENDIF.

    APPEND gs_so TO gt_so.

  ENDLOOP.

"---------------------------------------------------------------------*
" 방금 생성한 SO가 맨 위 (생성일시 최신순)
"---------------------------------------------------------------------*
  SORT gt_so BY erdat DESCENDING
                erzet DESCENDING
                vbeln DESCENDING.

  PERFORM renumber_so.

  IF go_so_grid IS BOUND.
    CALL METHOD go_so_grid->refresh_table_display.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

"---------------------------------------------------------------------*
" 결과 없음 메시지는 USER_COMMAND_0100에서 상태별로 처리
"---------------------------------------------------------------------*

ENDFORM.


"&---------------------------------------------------------------------*
"& Form RENUMBER_SO
"&---------------------------------------------------------------------*
FORM renumber_so.

  DATA:
    lv_no TYPE i.

  LOOP AT gt_so ASSIGNING FIELD-SYMBOL(<fs_so>).
    lv_no = lv_no + 1.
    <fs_so>-no = lv_no.
  ENDLOOP.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form CLEAR_SEARCH_CONDITION
"&---------------------------------------------------------------------*
FORM clear_search_condition.

"---------------------------------------------------------------------*
" 입력값 초기화 = 기본조건(이번 달~다음 달 요청납기일 / 출고 대상만)으로 되돌림
"---------------------------------------------------------------------*
  PERFORM set_default_search.

  PERFORM search_so.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_DEFAULT_SEARCH
"&---------------------------------------------------------------------*
" 기본 조회조건 : 요청납기일 이번 달 1일 ~ 다음 달 말일, 출고 대상만
" (SD01 주문 기본 요청납기일이 오늘+30일이라 다음 달까지 포함)
"----------------------------------------------------------------------*
FORM set_default_search.

  DATA lv_next TYPE d.

  CLEAR:
    gv_s_vbeln,
    gv_s_kunnr,
    rb_all.

  rb_target = 'X'.

"---------------------------------------------------------------------*
" 시작일 : 이번 달 1일
"---------------------------------------------------------------------*
  gv_s_reqfr = sy-datum.
  gv_s_reqfr+6(2) = '01'.

"---------------------------------------------------------------------*
" 종료일 : 다음 달 말일
"---------------------------------------------------------------------*
  lv_next = gv_s_reqfr + 32.

  CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
    EXPORTING
      day_in            = lv_next
    IMPORTING
      last_day_of_month = gv_s_reqto
    EXCEPTIONS
      day_in_no_date    = 1
      OTHERS            = 2.

  IF sy-subrc <> 0.
    gv_s_reqto = sy-datum + 60.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form REFRESH_SCREEN
"&---------------------------------------------------------------------*
FORM refresh_screen.

  PERFORM search_so.
  PERFORM reload_delivery.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form REFRESH_SO
"&---------------------------------------------------------------------*
FORM refresh_so.

  PERFORM search_so.

ENDFORM.



"***********************************************************************
" 3. SO 선택
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form SELECT_ALL_SO
"&---------------------------------------------------------------------*
FORM select_all_so.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_so ASSIGNING FIELD-SYMBOL(<fs_so>).
    IF <fs_so>-ready_yn = 'Y'.
      <fs_so>-sel = 'X'.
      APPEND VALUE #( index = sy-tabix ) TO lt_rows.
    ELSE.
      CLEAR <fs_so>-sel.
    ENDIF.
  ENDLOOP.

  IF go_so_grid IS BOUND.
    CALL METHOD go_so_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form DESELECT_ALL_SO
"&---------------------------------------------------------------------*
FORM deselect_all_so.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_so ASSIGNING FIELD-SYMBOL(<fs_so>).
    CLEAR <fs_so>-sel.
  ENDLOOP.

  IF go_so_grid IS BOUND.
    CALL METHOD go_so_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.



"***********************************************************************
" 4. Delivery 생성 (C)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form CONFIRM_CREATE_DELIVERY
"&---------------------------------------------------------------------*
FORM confirm_create_delivery.

  DATA:
    lv_count    TYPE i,
    lv_answer   TYPE c LENGTH 1,
    lv_question TYPE string.

  IF go_so_grid IS BOUND.
    PERFORM sync_so_sel.
  ENDIF.

"---------------------------------------------------------------------*
" 출고대기 SO 선택 시 차단
"---------------------------------------------------------------------*
  IF line_exists( gt_so[ sel = 'X' ready_yn = 'N' ] ).
    MESSAGE i037(zmsga) WITH '출고대기' '출고문서 생성'.
    RETURN.
  ENDIF.

"---------------------------------------------------------------------*
" 선택 건수
"---------------------------------------------------------------------*
  LOOP AT gt_so TRANSPORTING NO FIELDS WHERE sel = 'X'.
    lv_count = lv_count + 1.
  ENDLOOP.

  IF lv_count = 0.
    MESSAGE i021(zmsga) WITH '출고문서를 생성할 판매오더'.
    RETURN.
  ENDIF.

  MESSAGE s211(zmsga) WITH lv_count INTO lv_question.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '출고문서 생성'
      text_question         = lv_question
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer = '1'.
    PERFORM create_delivery.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form CREATE_DELIVERY
"&---------------------------------------------------------------------*
" - 생성 직전에 상태/재고를 DB 기준으로 다시 확인
" - 재고부족·이미 처리된 SO는 건너뛰고 나머지는 생성
" - DB 오류가 나면 이번 실행분 전체 ROLLBACK
"----------------------------------------------------------------------*
FORM create_delivery.

  DATA:
    ls_so_header TYPE ztsda00010,
    lt_so_item   TYPE tt_so_item,
    lv_vbeln     TYPE ztsda00030-vbeln,
    lv_subrc     TYPE sy-subrc,
    lv_ready     TYPE char1,
    lv_text      TYPE char100,
    lv_created   TYPE i,
    lv_skipped   TYPE i,
    lv_skip_text TYPE string.

  CLEAR gt_new_delivery.

  IF go_so_grid IS BOUND.
    PERFORM sync_so_sel.
  ENDIF.

  LOOP AT gt_so INTO gs_so
    WHERE sel      = 'X'
      AND ready_yn = 'Y'.

"---------------------------------------------------------------------*
" SO Header 재조회 (다른 사용자가 이미 처리했는지)
"---------------------------------------------------------------------*
    CLEAR ls_so_header.

    SELECT SINGLE *
      FROM ztsda00010
      WHERE vbeln = @gs_so-vbeln
      INTO @ls_so_header.

    IF sy-subrc <> 0 OR ls_so_header-sosta <> 'SO'.
      lv_skipped = lv_skipped + 1.
      IF lv_skip_text IS INITIAL.
        lv_skip_text = |{ gs_so-vbeln }: 이미 처리된 판매오더|.
      ENDIF.
      CONTINUE.
    ENDIF.

"---------------------------------------------------------------------*
" SO Item
"---------------------------------------------------------------------*
    CLEAR lt_so_item.

    SELECT *
      FROM ztsda00020
      WHERE vbeln = @gs_so-vbeln
      ORDER BY posnr
      INTO TABLE @lt_so_item.

    IF lt_so_item IS INITIAL.
      lv_skipped = lv_skipped + 1.
      IF lv_skip_text IS INITIAL.
        lv_skip_text = |{ gs_so-vbeln }: Item 없음|.
      ENDIF.
      CONTINUE.
    ENDIF.

"---------------------------------------------------------------------*
" 생성 시점 재고 재검사
" 이 Loop에서 앞서 만든 Delivery 수량도 반영됨
"---------------------------------------------------------------------*
    PERFORM check_so_stock
      USING    lt_so_item
      CHANGING lv_ready
               lv_text.

    IF lv_ready <> 'Y'.
      lv_skipped = lv_skipped + 1.
      IF lv_skip_text IS INITIAL.
        lv_skip_text = |{ gs_so-vbeln }: { lv_text }|.
      ENDIF.
      CONTINUE.
    ENDIF.

"---------------------------------------------------------------------*
" Delivery Header / Item INSERT + SO 상태 변경
"---------------------------------------------------------------------*
    PERFORM insert_delivery
      USING    ls_so_header
               lt_so_item
      CHANGING lv_vbeln
               lv_subrc.

    IF lv_subrc <> 0.

      ROLLBACK WORK.

      CLEAR gt_new_delivery.

      MESSAGE i067(zmsga) WITH |판매오더 { gs_so-vbeln }|.

      PERFORM search_so.
      PERFORM get_all_delivery.

      RETURN.

    ENDIF.

    APPEND lv_vbeln TO gt_new_delivery.

    lv_created = lv_created + 1.

  ENDLOOP.

"---------------------------------------------------------------------*
" 생성 0건
"---------------------------------------------------------------------*
  IF lv_created = 0.

    IF lv_skip_text IS INITIAL.
      MESSAGE i018(zmsga).
    ELSE.
      MESSAGE i206(zmsga) WITH lv_skip_text.
    ENDIF.

    PERFORM search_so.

    RETURN.

  ENDIF.

  COMMIT WORK AND WAIT.

"---------------------------------------------------------------------*
" 재조회 : SO는 상단에서 빠지고 새 Delivery는 하단에 강조 표시
"---------------------------------------------------------------------*
  PERFORM search_so.
  PERFORM get_all_delivery.

  IF lv_skipped = 0.
    MESSAGE s006(zmsga) WITH lv_created.
  ELSE.
    MESSAGE i205(zmsga) WITH lv_created lv_skipped lv_skip_text.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form INSERT_DELIVERY
"&---------------------------------------------------------------------*
FORM insert_delivery
  USING    is_so_header TYPE ztsda00010
           it_so_item   TYPE tt_so_item
  CHANGING cv_vbeln     TYPE ztsda00030-vbeln
           cv_subrc     TYPE sy-subrc.

  DATA:
    ls_header  TYPE ztsda00030,
    ls_item    TYPE ztsda00040,
    ls_so_item TYPE ztsda00020,
    lv_posnr   TYPE ztsda00040-posnr,
    lv_reqdt   TYPE ztsda00020-reqdt.

  CLEAR cv_vbeln.
  cv_subrc = 4.

"---------------------------------------------------------------------*
" Delivery 번호 채번 (SD 공통 FM : SNRO ZSD_NUM 구간 02, DL + 8자리)
"---------------------------------------------------------------------*
  CALL FUNCTION 'ZSD_GET_NEXT_NO'
    EXPORTING
      iv_docty      = 'DL'
    IMPORTING
      ev_number     = cv_vbeln
    EXCEPTIONS
      invalid_docty = 1
      number_error  = 2
      OTHERS        = 3.

  IF sy-subrc <> 0 OR cv_vbeln IS INITIAL.
    RETURN.
  ENDIF.

"---------------------------------------------------------------------*
" 가장 빠른 요청납기일 = 출하예정일
"---------------------------------------------------------------------*
  LOOP AT it_so_item INTO ls_so_item.
    IF lv_reqdt IS INITIAL
       OR ls_so_item-reqdt < lv_reqdt.
      lv_reqdt = ls_so_item-reqdt.
    ENDIF.
  ENDLOOP.

"---------------------------------------------------------------------*
" Header
"---------------------------------------------------------------------*
  CLEAR ls_header.

  ls_header-vbeln = cv_vbeln.
  ls_header-kunnr = is_so_header-kunnr.
  ls_header-vstel = '0001'.                 " 기존 데이터 기준 출하지점
  ls_header-kunwe = is_so_header-kunnr.     " 별도 Ship-to 미사용
  ls_header-tddat = lv_reqdt.
  ls_header-gista = 'N'.                    " N = GI 미처리
  ls_header-ernam = sy-uname.
  ls_header-erdat = sy-datum.
  ls_header-erzet = sy-uzeit.

  INSERT ztsda00030 FROM @ls_header.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

"---------------------------------------------------------------------*
" Item (부분출하 없음 → SO 수량 전체 승계)
"---------------------------------------------------------------------*
  LOOP AT it_so_item INTO ls_so_item.

    lv_posnr = lv_posnr + 10.

    CLEAR ls_item.

    ls_item-vbeln = cv_vbeln.
    ls_item-posnr = lv_posnr.
    ls_item-vgbel = ls_so_item-vbeln.
    ls_item-posnv = ls_so_item-posnr.
    ls_item-matnr = ls_so_item-matnr.
    ls_item-werks = ls_so_item-werks.
    ls_item-lgort = ls_so_item-lgort.
    ls_item-lfimg = ls_so_item-kwmeng.
    ls_item-meins = ls_so_item-meins.
    ls_item-ernam = sy-uname.
    ls_item-erdat = sy-datum.
    ls_item-erzet = sy-uzeit.

    INSERT ztsda00040 FROM @ls_item.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

  ENDLOOP.

"---------------------------------------------------------------------*
" SO 상태 SO → DO
" WHERE에 sosta = 'SO'를 넣어 동시 처리 방어
"---------------------------------------------------------------------*
  UPDATE ztsda00010
    SET sosta = 'DO',
        aenam = @sy-uname,
        aedat = @sy-datum,
        aezet = @sy-uzeit
    WHERE vbeln = @is_so_header-vbeln
      AND sosta = 'SO'.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  cv_subrc = 0.

ENDFORM.


"***********************************************************************
" 5. 하단 ALV - Delivery 조회 (R)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form DISPLAY_DE_ALV
"&---------------------------------------------------------------------*
FORM display_de_alv.

  IF go_de_container IS INITIAL.

    PERFORM get_all_delivery.

    CREATE OBJECT go_de_container
      EXPORTING
        container_name = 'CC_DE'.

    CREATE OBJECT go_de_grid
      EXPORTING
        i_parent = go_de_container.

    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.

    SET HANDLER go_event_handler->handle_de_toolbar       FOR go_de_grid.
    SET HANDLER go_event_handler->handle_de_user_command  FOR go_de_grid.
    SET HANDLER go_event_handler->handle_de_hotspot_click FOR go_de_grid.

    PERFORM set_de_fieldcat.
    PERFORM set_toolbar_exclude.

    CLEAR gs_de_layo.
    gs_de_layo-grid_title = '출고문서 정보'.
    gs_de_layo-zebra      = abap_true.
    gs_de_layo-cwidth_opt = abap_true.
    gs_de_layo-sel_mode   = 'A'.
    gs_de_layo-info_fname = 'ROW_COLOR'.

    CALL METHOD go_de_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_de_layo
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab            = gt_de
        it_fieldcatalog      = gt_de_fcat.

    CALL METHOD go_de_grid->set_toolbar_interactive.

    CALL METHOD go_de_grid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.

    CALL METHOD cl_gui_cfw=>flush.

  ELSE.

    CALL METHOD go_de_grid->refresh_table_display.
    CALL METHOD cl_gui_cfw=>flush.

  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_DE_FIELDCAT
"&---------------------------------------------------------------------*
FORM set_de_fieldcat.

  CLEAR gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'NO'.
  gs_de_fcat-coltext   = 'No'.
  gs_de_fcat-outputlen = 4.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'STATUS'.
  gs_de_fcat-coltext   = '상태'.
  gs_de_fcat-icon      = abap_true.
  gs_de_fcat-outputlen = 6.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'SHIP_STATUS'.
  gs_de_fcat-coltext   = '출하상태'.
  gs_de_fcat-outputlen = 12.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'VBELN'.
  gs_de_fcat-coltext   = '출고문서번호'.
  gs_de_fcat-outputlen = 12.
  gs_de_fcat-hotspot   = abap_true.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'SO_VBELN'.
  gs_de_fcat-coltext   = '판매오더번호'.
  gs_de_fcat-outputlen = 12.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'KUNNR'.
  gs_de_fcat-coltext   = '고객번호'.
  gs_de_fcat-outputlen = 12.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'NAME1'.
  gs_de_fcat-coltext   = '고객명'.
  gs_de_fcat-outputlen = 18.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'VSTEL'.
  gs_de_fcat-coltext   = '출하지점'.
  gs_de_fcat-outputlen = 10.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'KUNWE'.
  gs_de_fcat-coltext   = '배송처번호'.
  gs_de_fcat-outputlen = 12.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'TDDAT'.
  gs_de_fcat-coltext   = '출하예정일'.
  gs_de_fcat-outputlen = 10.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'DLVST'.
  gs_de_fcat-coltext   = '출고문서상태'.
  gs_de_fcat-outputlen = 12.
  APPEND gs_de_fcat TO gt_de_fcat.

  CLEAR gs_de_fcat.
  gs_de_fcat-fieldname = 'ACGDT'.
  gs_de_fcat-coltext   = '실제출하일'.
  gs_de_fcat-outputlen = 10.
  APPEND gs_de_fcat TO gt_de_fcat.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form GET_ALL_DELIVERY
"&---------------------------------------------------------------------*
FORM get_all_delivery.

  PERFORM get_delivery USING 'A'.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form GET_PENDING_DELIVERY
"&---------------------------------------------------------------------*
FORM get_pending_delivery.

  PERFORM get_delivery USING 'P'.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form RELOAD_DELIVERY
"&---------------------------------------------------------------------*
" 보고 있던 모드(전체/미출하) 그대로 재조회
"----------------------------------------------------------------------*
FORM reload_delivery.

  PERFORM get_delivery USING gv_de_mode.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form REFRESH_DELIVERY
"&---------------------------------------------------------------------*
FORM refresh_delivery.

  PERFORM reload_delivery.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form GET_DELIVERY
"&---------------------------------------------------------------------*
" iv_mode : A = 전체 / P = 미출하
"----------------------------------------------------------------------*
FORM get_delivery
  USING iv_mode TYPE char1.

  DATA:
    lt_cust  TYPE tt_cust,
    ls_cust  TYPE ty_cust,
    lv_no    TYPE i,
    lr_gista TYPE RANGE OF ztsda00030-gista.

  CLEAR:
    gt_de,
    gs_de.

  gv_de_mode = iv_mode.

"---------------------------------------------------------------------*
" 미출하 모드 : GI 완료(C) 제외
"---------------------------------------------------------------------*
  IF iv_mode = 'P'.
    lr_gista = VALUE #( ( sign = 'E' option = 'EQ' low = 'C' ) ).
  ENDIF.

  SELECT vbeln,
         kunnr,
         vstel,
         kunwe,
         tddat,
         dlvst,
         gista,
         acgdt
    FROM ztsda00030
    WHERE gista IN @lr_gista
    INTO CORRESPONDING FIELDS OF TABLE @gt_de.

  IF gt_de IS NOT INITIAL.
    PERFORM get_customer_names CHANGING lt_cust.
  ENDIF.

  SORT gt_de BY vbeln DESCENDING.

  LOOP AT gt_de ASSIGNING FIELD-SYMBOL(<fs_de>).

    lv_no = lv_no + 1.
    <fs_de>-no = lv_no.

    CLEAR <fs_de>-sel.

"---------------------------------------------------------------------*
" 판매오더번호 (출고문서 Item의 원본 SO)
"---------------------------------------------------------------------*
    SELECT SINGLE vgbel
      FROM ztsda00040
      WHERE vbeln = @<fs_de>-vbeln
      INTO @<fs_de>-so_vbeln.

"---------------------------------------------------------------------*
" 고객명
"---------------------------------------------------------------------*
    READ TABLE lt_cust INTO ls_cust
      WITH TABLE KEY kunnr = <fs_de>-kunnr.

    IF sy-subrc = 0.
      <fs_de>-name1 = ls_cust-name1.
    ENDIF.

"---------------------------------------------------------------------*
" 출하상태
"---------------------------------------------------------------------*
    IF <fs_de>-gista = 'C'.
      <fs_de>-status      = icon_led_green.
      <fs_de>-ship_status = '출하완료'.
    ELSE.
      <fs_de>-status      = icon_led_yellow.
      <fs_de>-ship_status = '미출하'.
    ENDIF.

"---------------------------------------------------------------------*
" 방금 생성한 Delivery 강조
"---------------------------------------------------------------------*
    CLEAR <fs_de>-row_color.

    IF line_exists( gt_new_delivery[ table_line = <fs_de>-vbeln ] ).
      <fs_de>-row_color = 'C310'.
    ENDIF.

  ENDLOOP.

  IF go_de_grid IS BOUND.
    CALL METHOD go_de_grid->refresh_table_display.
    CALL METHOD cl_gui_cfw=>flush.
  ENDIF.

ENDFORM.



"***********************************************************************
" 6. Delivery 수정 (U) - 출하예정일 변경
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form CHANGE_DELIVERY_DATE
"&---------------------------------------------------------------------*
FORM change_delivery_date.

  DATA:
    lt_sel    TYPE STANDARD TABLE OF ty_de,
    ls_sel    TYPE ty_de,
    lt_fields TYPE STANDARD TABLE OF sval,
    ls_field  TYPE sval,
    lv_rc     TYPE c LENGTH 1,
    lv_value  TYPE c LENGTH 20,
    lv_date   TYPE d,
    lv_count  TYPE i.

  IF go_de_grid IS BOUND.
    PERFORM sync_de_sel.
  ENDIF.

"---------------------------------------------------------------------*
" 선택 건
"---------------------------------------------------------------------*
  lt_sel = VALUE #( FOR wa IN gt_de WHERE ( sel = 'X' ) ( wa ) ).

  IF lt_sel IS INITIAL.
    MESSAGE i021(zmsga) WITH '수정할 출고문서'.
    RETURN.
  ENDIF.

  IF line_exists( lt_sel[ gista = 'C' ] ).
    MESSAGE i037(zmsga) WITH '출하완료' '출하예정일 변경'.
    RETURN.
  ENDIF.

"---------------------------------------------------------------------*
" 새 출하예정일 입력 팝업
"---------------------------------------------------------------------*
  CLEAR ls_field.
  ls_field-tabname   = 'ZTSDA00030'.
  ls_field-fieldname = 'TDDAT'.
  ls_field-fieldtext = '새 출하예정일'.
  ls_field-field_obl = 'X'.
  APPEND ls_field TO lt_fields.

  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      popup_title     = '출하예정일 변경'
    IMPORTING
      returncode      = lv_rc
    TABLES
      fields          = lt_fields
    EXCEPTIONS
      error_in_fields = 1
      OTHERS          = 2.

  IF sy-subrc <> 0 OR lv_rc = 'A'.
    RETURN.
  ENDIF.

  READ TABLE lt_fields INTO ls_field INDEX 1.

  lv_value = ls_field-value.
  CONDENSE lv_value NO-GAPS.

"---------------------------------------------------------------------*
" 날짜 변환 (내부형식 YYYYMMDD가 아니면 변환)
"---------------------------------------------------------------------*
  IF strlen( lv_value ) = 8 AND lv_value CO '0123456789'.
    lv_date = lv_value.
  ELSE.
    CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
      EXPORTING
        date_external = lv_value
      IMPORTING
        date_internal = lv_date
      EXCEPTIONS
        OTHERS        = 1.

    IF sy-subrc <> 0.
      MESSAGE i023(zmsga) WITH '출하예정일'.
      RETURN.
    ENDIF.
  ENDIF.

  IF lv_date IS INITIAL.
    MESSAGE i020(zmsga) WITH '출하예정일'.
    RETURN.
  ENDIF.

  IF lv_date < sy-datum.
    MESSAGE i025(zmsga) WITH '출하예정일' '오늘'.
    RETURN.
  ENDIF.

"---------------------------------------------------------------------*
" UPDATE (WHERE에 GI 미완료 조건 → 그 사이 출하된 건 방어)
"---------------------------------------------------------------------*
  LOOP AT lt_sel INTO ls_sel.

    UPDATE ztsda00030
      SET tddat = @lv_date,
          aenam = @sy-uname,
          aedat = @sy-datum,
          aezet = @sy-uzeit
      WHERE vbeln = @ls_sel-vbeln
        AND gista <> 'C'.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE i064(zmsga).
      PERFORM reload_delivery.
      RETURN.
    ENDIF.

    lv_count = lv_count + 1.

  ENDLOOP.

  COMMIT WORK AND WAIT.

  PERFORM reload_delivery.

  MESSAGE s072(zmsga) WITH lv_count.

ENDFORM.



"***********************************************************************
" 7. Delivery 취소 (D)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form CANCEL_DELIVERY
"&---------------------------------------------------------------------*
" GI 전 출고문서만 취소 가능
" Delivery Header/Item 삭제 → 연결된 SO 상태 DO → SO 복귀
" → SO가 다시 상단 출고대상 목록에 나타남
"----------------------------------------------------------------------*
FORM cancel_delivery.

  DATA:
    lt_sel      TYPE STANDARD TABLE OF ty_de,
    ls_sel      TYPE ty_de,
    lt_so       TYPE STANDARD TABLE OF ztsda00040-vgbel,
    lv_so       TYPE ztsda00040-vgbel,
    lv_gista    TYPE ztsda00030-gista,
    lv_answer   TYPE c LENGTH 1,
    lv_question TYPE string,
    lv_count    TYPE i.

  IF go_de_grid IS BOUND.
    PERFORM sync_de_sel.
  ENDIF.

  lt_sel = VALUE #( FOR wa IN gt_de WHERE ( sel = 'X' ) ( wa ) ).

  IF lt_sel IS INITIAL.
    MESSAGE i021(zmsga) WITH '취소할 출고문서'.
    RETURN.
  ENDIF.

  IF line_exists( lt_sel[ gista = 'C' ] ).
    MESSAGE i037(zmsga) WITH '출하완료' '출고문서 취소'.
    RETURN.
  ENDIF.

"---------------------------------------------------------------------*
" 확인
"---------------------------------------------------------------------*
  DATA(lv_sel_cnt) = lines( lt_sel ).

  MESSAGE s212(zmsga) WITH lv_sel_cnt INTO lv_question.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '출고문서 취소'
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

"---------------------------------------------------------------------*
" 취소 처리
"---------------------------------------------------------------------*
  LOOP AT lt_sel INTO ls_sel.

"---------------------------------------------------------------------*
" DB 기준 GI 상태 재확인
"---------------------------------------------------------------------*
    CLEAR lv_gista.

    SELECT SINGLE gista
      FROM ztsda00030
      WHERE vbeln = @ls_sel-vbeln
      INTO @lv_gista.

    IF sy-subrc <> 0 OR lv_gista = 'C'.
      ROLLBACK WORK.
      MESSAGE i044(zmsga).
      PERFORM reload_delivery.
      RETURN.
    ENDIF.

"---------------------------------------------------------------------*
" 연결된 SO 번호
"---------------------------------------------------------------------*
    CLEAR lt_so.

    SELECT DISTINCT vgbel
      FROM ztsda00040
      WHERE vbeln = @ls_sel-vbeln
      INTO TABLE @lt_so.

"---------------------------------------------------------------------*
" Delivery Item → Header 삭제
"---------------------------------------------------------------------*
    DELETE FROM ztsda00040
      WHERE vbeln = @ls_sel-vbeln.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE i065(zmsga).
      PERFORM reload_delivery.
      RETURN.
    ENDIF.

    DELETE FROM ztsda00030
      WHERE vbeln = @ls_sel-vbeln.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE i065(zmsga).
      PERFORM reload_delivery.
      RETURN.
    ENDIF.

"---------------------------------------------------------------------*
" SO 상태 DO → SO 복귀
"---------------------------------------------------------------------*
    LOOP AT lt_so INTO lv_so.

      UPDATE ztsda00010
        SET sosta = 'SO',
            aenam = @sy-uname,
            aedat = @sy-datum,
            aezet = @sy-uzeit
        WHERE vbeln = @lv_so
          AND sosta = 'DO'.

      IF sy-subrc <> 0.
        ROLLBACK WORK.
        MESSAGE i065(zmsga).
        PERFORM reload_delivery.
        RETURN.
      ENDIF.

    ENDLOOP.

    DELETE gt_new_delivery WHERE table_line = ls_sel-vbeln.

    lv_count = lv_count + 1.

  ENDLOOP.

  COMMIT WORK AND WAIT.

"---------------------------------------------------------------------*
" 재조회 : 취소된 SO는 상단에 다시 표시
"---------------------------------------------------------------------*
  PERFORM search_so.
  PERFORM reload_delivery.

  MESSAGE s006(zmsga) WITH lv_count.

ENDFORM.



"***********************************************************************
" 8. Navigation
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form MOVE_TO_SHIPMENT
"&---------------------------------------------------------------------*
FORM move_to_shipment.

  CLEAR gt_new_delivery.

  LEAVE TO TRANSACTION 'ZSD03'.

  PERFORM reload_delivery.

ENDFORM.



"***********************************************************************
" 9. 상세 팝업 - Delivery Item (Screen 0200)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form GET_DE_ITEM
"&---------------------------------------------------------------------*
FORM get_de_item.

  CLEAR:
    gt_de_item,
    gs_de_item.

"---------------------------------------------------------------------*
" 출고문서 Item + 자재명
"---------------------------------------------------------------------*
  SELECT i~vbeln,
         i~posnr,
         i~vgbel,
         i~posnv,
         i~matnr,
         m~maktx,
         i~werks,
         i~lgort,
         i~lfimg,
         i~meins
    FROM ztsda00040 AS i
    LEFT OUTER JOIN ztcma00020 AS m
      ON m~matnr = i~matnr
    WHERE i~vbeln = @gv_de_vbeln
    ORDER BY i~posnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_de_item.

  IF gt_de_item IS INITIAL.
    MESSAGE s042(zmsga) WITH '출고문서 상세정보' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_DE_ITEM_FIELDCAT
"&---------------------------------------------------------------------*
FORM set_de_item_fieldcat.

  CLEAR gt_de_item_fcat.

"---------------------------------------------------------------------*
" 원본 판매오더를 맨 왼쪽에 표시
" 출고문서번호는 팝업 제목에 있으므로 컬럼에서 제외
" SO Item은 Item과 같은 값이라 제외
"---------------------------------------------------------------------*
  CLEAR gs_de_item_fcat.
  gs_de_item_fcat-fieldname = 'VGBEL'.
  gs_de_item_fcat-coltext   = '원본 판매오더'.
  gs_de_item_fcat-outputlen = 12.
  APPEND gs_de_item_fcat TO gt_de_item_fcat.

  CLEAR gs_de_item_fcat.
  gs_de_item_fcat-fieldname = 'POSNR'.
  gs_de_item_fcat-coltext   = '품목번호'.
  gs_de_item_fcat-outputlen = 8.
  APPEND gs_de_item_fcat TO gt_de_item_fcat.

  CLEAR gs_de_item_fcat.
  gs_de_item_fcat-fieldname = 'MATNR'.
  gs_de_item_fcat-coltext   = '자재번호'.
  gs_de_item_fcat-outputlen = 18.
  APPEND gs_de_item_fcat TO gt_de_item_fcat.

  CLEAR gs_de_item_fcat.
  gs_de_item_fcat-fieldname = 'MAKTX'.
  gs_de_item_fcat-coltext   = '자재명'.
  gs_de_item_fcat-outputlen = 20.
  APPEND gs_de_item_fcat TO gt_de_item_fcat.

  CLEAR gs_de_item_fcat.
  gs_de_item_fcat-fieldname = 'WERKS'.
  gs_de_item_fcat-coltext   = 'Plant'.
  gs_de_item_fcat-outputlen = 8.
  APPEND gs_de_item_fcat TO gt_de_item_fcat.

  CLEAR gs_de_item_fcat.
  gs_de_item_fcat-fieldname = 'LGORT'.
  gs_de_item_fcat-coltext   = '저장위치'.
  gs_de_item_fcat-outputlen = 8.
  APPEND gs_de_item_fcat TO gt_de_item_fcat.

  CLEAR gs_de_item_fcat.
  gs_de_item_fcat-fieldname = 'LFIMG'.
  gs_de_item_fcat-coltext   = '출고수량'.
  gs_de_item_fcat-outputlen = 10.
  APPEND gs_de_item_fcat TO gt_de_item_fcat.

  CLEAR gs_de_item_fcat.
  gs_de_item_fcat-fieldname = 'MEINS'.
  gs_de_item_fcat-coltext   = '단위'.
  gs_de_item_fcat-outputlen = 6.
  APPEND gs_de_item_fcat TO gt_de_item_fcat.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form DISPLAY_DE_ITEM_ALV
"&---------------------------------------------------------------------*
FORM display_de_item_alv.

  IF go_de_item_container IS INITIAL.

    PERFORM get_de_item.

    CREATE OBJECT go_de_item_container
      EXPORTING
        container_name = 'CC_DE_ITEM'.

    CREATE OBJECT go_de_item_grid
      EXPORTING
        i_parent = go_de_item_container.

    PERFORM set_de_item_fieldcat.

    CLEAR gs_de_item_layo.
    gs_de_item_layo-grid_title = |출고문서 { gv_de_vbeln } 상세정보|.
    gs_de_item_layo-zebra      = abap_true.
    gs_de_item_layo-cwidth_opt = abap_true.

    PERFORM set_toolbar_exclude.

    CALL METHOD go_de_item_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_de_item_layo
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab       = gt_de_item
        it_fieldcatalog = gt_de_item_fcat.

    CALL METHOD cl_gui_cfw=>flush.

  ELSE.

    PERFORM get_de_item.

    CALL METHOD go_de_item_grid->refresh_table_display.
    CALL METHOD cl_gui_cfw=>flush.

  ENDIF.

ENDFORM.



"***********************************************************************
" 10. 상세 팝업 - SO Item (Screen 0300)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form GET_SO_ITEM_DETAIL
"&---------------------------------------------------------------------*
FORM get_so_item_detail.

  CLEAR:
    gt_so_item_detail,
    gs_so_item_detail.

  SELECT vbeln,
         posnr,
         matnr,
         werks,
         lgort,
         kwmeng,
         meins,
         reqdt
    FROM ztsda00020
    WHERE vbeln = @gv_so_vbeln_detail
    ORDER BY posnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_so_item_detail.

  IF gt_so_item_detail IS INITIAL.
    MESSAGE s042(zmsga) WITH '판매오더 상세정보' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SET_SO_ITEM_FIELDCAT
"&---------------------------------------------------------------------*
FORM set_so_item_fieldcat.

  CLEAR gt_so_item_fcat.

  CLEAR gs_so_item_fcat.
  gs_so_item_fcat-fieldname = 'VBELN'.
  gs_so_item_fcat-coltext   = '판매오더번호'.
  gs_so_item_fcat-outputlen = 12.
  APPEND gs_so_item_fcat TO gt_so_item_fcat.

  CLEAR gs_so_item_fcat.
  gs_so_item_fcat-fieldname = 'POSNR'.
  gs_so_item_fcat-coltext   = 'Item'.
  gs_so_item_fcat-outputlen = 6.
  APPEND gs_so_item_fcat TO gt_so_item_fcat.

  CLEAR gs_so_item_fcat.
  gs_so_item_fcat-fieldname = 'MATNR'.
  gs_so_item_fcat-coltext   = '자재번호'.
  gs_so_item_fcat-outputlen = 18.
  APPEND gs_so_item_fcat TO gt_so_item_fcat.

  CLEAR gs_so_item_fcat.
  gs_so_item_fcat-fieldname = 'WERKS'.
  gs_so_item_fcat-coltext   = 'Plant'.
  gs_so_item_fcat-outputlen = 8.
  APPEND gs_so_item_fcat TO gt_so_item_fcat.

  CLEAR gs_so_item_fcat.
  gs_so_item_fcat-fieldname = 'LGORT'.
  gs_so_item_fcat-coltext   = '저장위치'.
  gs_so_item_fcat-outputlen = 8.
  APPEND gs_so_item_fcat TO gt_so_item_fcat.

  CLEAR gs_so_item_fcat.
  gs_so_item_fcat-fieldname = 'KWMENG'.
  gs_so_item_fcat-coltext   = '주문수량'.
  gs_so_item_fcat-outputlen = 10.
  APPEND gs_so_item_fcat TO gt_so_item_fcat.

  CLEAR gs_so_item_fcat.
  gs_so_item_fcat-fieldname = 'MEINS'.
  gs_so_item_fcat-coltext   = '단위'.
  gs_so_item_fcat-outputlen = 6.
  APPEND gs_so_item_fcat TO gt_so_item_fcat.

  CLEAR gs_so_item_fcat.
  gs_so_item_fcat-fieldname = 'REQDT'.
  gs_so_item_fcat-coltext   = '요청납기일'.
  gs_so_item_fcat-outputlen = 10.
  APPEND gs_so_item_fcat TO gt_so_item_fcat.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form DISPLAY_SO_ITEM_ALV
"&---------------------------------------------------------------------*
FORM display_so_item_alv.

  IF go_so_item_container IS INITIAL.

    PERFORM get_so_item_detail.

    CREATE OBJECT go_so_item_container
      EXPORTING
        container_name = 'CC_SO_ITEM'.

    CREATE OBJECT go_so_item_grid
      EXPORTING
        i_parent = go_so_item_container.

    PERFORM set_so_item_fieldcat.

    CLEAR gs_so_item_layo.
    gs_so_item_layo-grid_title = |판매오더 { gv_so_vbeln_detail } 상세정보|.
    gs_so_item_layo-zebra      = abap_true.
    gs_so_item_layo-cwidth_opt = abap_true.

    PERFORM set_toolbar_exclude.

    CALL METHOD go_so_item_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_so_item_layo
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab       = gt_so_item_detail
        it_fieldcatalog = gt_so_item_fcat.

    CALL METHOD cl_gui_cfw=>flush.

  ELSE.

    PERFORM get_so_item_detail.

    CALL METHOD go_so_item_grid->refresh_table_display.
    CALL METHOD cl_gui_cfw=>flush.

  ENDIF.

ENDFORM.



"***********************************************************************
" 9. ALV 행 선택 -> SEL 값 반영 (드래그 / Shift / Ctrl 선택 지원)
"***********************************************************************


"&---------------------------------------------------------------------*
"& Form SYNC_SO_SEL
"&---------------------------------------------------------------------*
FORM sync_so_sel.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_so ASSIGNING FIELD-SYMBOL(<fs_so>).
    CLEAR <fs_so>-sel.
  ENDLOOP.

  IF go_so_grid IS NOT BOUND.
    RETURN.
  ENDIF.

  CALL METHOD go_so_grid->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_so ASSIGNING <fs_so> INDEX ls_row-index.
    IF sy-subrc = 0.
      <fs_so>-sel = 'X'.
    ENDIF.
  ENDLOOP.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form SYNC_DE_SEL
"&---------------------------------------------------------------------*
FORM sync_de_sel.

  DATA lt_rows TYPE lvc_t_row.

  LOOP AT gt_de ASSIGNING FIELD-SYMBOL(<fs_de>).
    CLEAR <fs_de>-sel.
  ENDLOOP.

  IF go_de_grid IS NOT BOUND.
    RETURN.
  ENDIF.

  CALL METHOD go_de_grid->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_de ASSIGNING <fs_de> INDEX ls_row-index.
    IF sy-subrc = 0.
      <fs_de>-sel = 'X'.
    ENDIF.
  ENDLOOP.

ENDFORM.



"***********************************************************************
" 10. 출고문서 Item 상세 팝업 (SALV - 출고문서번호 클릭)
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
" 판매오더 상세정보 팝업 (SALV)
" SD03·SD04의 상세정보 팝업과 같은 모양으로 통일한 FORM
"  - 제목은 ALV 안쪽 기본 제목(set_list_header)으로 표시
"  - 공급가액·세액·최종금액 컬럼과 하단 합계 행 포함
"***********************************************************************
FORM show_so_detail
  USING iv_vbeln TYPE ztsda00010-vbeln.

"---------------------------------------------------------------------*
" 표시용 구조 : 판매오더 Item 한 줄 = ALV 한 줄
"---------------------------------------------------------------------*
  TYPES:
    BEGIN OF ty_so_item,
      vbeln TYPE ztsda00020-vbeln,
      posnr TYPE ztsda00020-posnr,
      matnr TYPE ztsda00020-matnr,
      maktx TYPE ztcma00020-maktx,
      werks TYPE ztsda00020-werks,
      lgort TYPE ztsda00020-lgort,
      kwmeng TYPE ztsda00020-kwmeng,
      meins TYPE ztsda00020-meins,
      reqdt TYPE ztsda00020-reqdt,
      netam TYPE p LENGTH 15 DECIMALS 0,   " 공급가액
      taxam TYPE p LENGTH 15 DECIMALS 0,   " 세액
      totam TYPE p LENGTH 15 DECIMALS 0,   " 최종금액
    END OF ty_so_item.

  DATA:
    lt_item TYPE STANDARD TABLE OF ty_so_item,
    lo_alv  TYPE REF TO cl_salv_table,
    lo_cols TYPE REF TO cl_salv_columns_table.

"---------------------------------------------------------------------*
" 판매오더 Item + 자재명 + 금액 조회
"---------------------------------------------------------------------*
  SELECT i~vbeln,
         i~posnr,
         i~matnr,
         m~maktx,
         i~werks,
         i~lgort,
         i~kwmeng,
         i~meins,
         i~reqdt,
         i~netam,
         i~taxam,
         i~totam
    FROM ztsda00020 AS i
    LEFT OUTER JOIN ztcma00020 AS m
      ON m~matnr = i~matnr
    WHERE i~vbeln = @iv_vbeln
    ORDER BY i~posnr
    INTO CORRESPONDING FIELDS OF TABLE @lt_item.

  IF lt_item IS INITIAL.
    MESSAGE s042(zmsga) WITH '판매오더 상세정보' DISPLAY LIKE 'E'.
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
        |판매오더 { iv_vbeln } 상세정보| ).

      lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).

      lo_cols = lo_alv->get_columns( ).
      lo_cols->set_optimize( abap_true ).

"---------------------------------------------------------------------*
" 컬럼 제목 (있는 컬럼만 돌면서 지정)
"---------------------------------------------------------------------*
      DATA(lt_cols) = lo_cols->get( ).

      LOOP AT lt_cols INTO DATA(ls_col).

        CASE ls_col-columnname.
          WHEN 'VBELN'.
            ls_col-r_column->set_short_text( '판매오더' ).
            ls_col-r_column->set_medium_text( '판매오더번호' ).
            ls_col-r_column->set_long_text( '판매오더번호' ).
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
          WHEN 'KWMENG'.
            ls_col-r_column->set_short_text( '주문수량' ).
            ls_col-r_column->set_medium_text( '주문수량' ).
            ls_col-r_column->set_long_text( '주문수량' ).
          WHEN 'MEINS'.
            ls_col-r_column->set_short_text( '단위' ).
            ls_col-r_column->set_medium_text( '단위' ).
            ls_col-r_column->set_long_text( '단위' ).
          WHEN 'REQDT'.
            ls_col-r_column->set_short_text( '납기일' ).
            ls_col-r_column->set_medium_text( '요청납기일' ).
            ls_col-r_column->set_long_text( '요청납기일' ).
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
" 하단 합계 행 (주문수량 / 공급가액 / 세액 / 최종금액)
"---------------------------------------------------------------------*
      DATA(lo_aggr) = lo_alv->get_aggregations( ).

      lo_aggr->add_aggregation( columnname = 'KWMENG' ).
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
