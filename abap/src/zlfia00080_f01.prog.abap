*&---------------------------------------------------------------------*
*& Include          ZLFIA00080_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form f4_ebeln  - PO번호 검색도움말
*&---------------------------------------------------------------------*
FORM f4_ebeln .
  TYPES: BEGIN OF ty_f4,
           ebeln TYPE ztmma00050-ebeln,
           lifnr TYPE ztmma00050-lifnr,
           name1 TYPE ztcma00010-name1,
           bedat TYPE ztmma00050-bedat,
         END OF ty_f4.
  DATA lt_f4 TYPE TABLE OF ty_f4.

  SELECT p~ebeln p~lifnr v~name1 p~bedat
    FROM ztmma00050 AS p
    LEFT OUTER JOIN ztcma00010 AS v ON v~lifnr = p~lifnr
    INTO TABLE lt_f4.

  SORT lt_f4 BY ebeln DESCENDING.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'EBELN'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_EBELN'
      value_org   = 'S'
    TABLES
      value_tab   = lt_f4
    EXCEPTIONS
      OTHERS      = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_selection  - 실행 전 검증 (선택화면에 머물며 에러)
*&---------------------------------------------------------------------*
FORM check_selection .
  DATA: lv_ebelp TYPE ztmma00060-ebelp,
        lv_ivnum TYPE ztfia00010-ivnum,
        lv_msg   TYPE string.

  " 필수 입력
  IF p_ebeln IS INITIAL OR p_xblnr IS INITIAL
     OR p_bldat IS INITIAL OR p_budat IS INITIAL.
    MESSAGE e415(zmsga).        " PO번호, 거래처 송장번호, 발행일, AP 인식일을 모두 입력해 주십시오.
  ENDIF.

  " PO 존재
  SELECT SINGLE lifnr FROM ztmma00050 INTO gv_lifnr
    WHERE ebeln = p_ebeln.
  IF sy-subrc <> 0.
    MESSAGE e034(zmsga) WITH 'PO번호'.          " PO번호 값이 존재하지 않습니다.
  ENDIF.

  " 공급업체 지급조건 (없으면 지급기한 계산 불가 → 등록 차단)
  PERFORM check_vendor_zterm USING gv_lifnr.


  " PO 아이템 존재
  SELECT SINGLE ebelp FROM ztmma00060 INTO lv_ebelp
    WHERE ebeln = p_ebeln.
  IF sy-subrc <> 0.
    MESSAGE e043(zmsga) WITH 'PO 아이템'.          " PO 아이템 데이터가 존재하지 않습니다.
  ENDIF.

  " 총액
  IF p_total <= 0.
    MESSAGE e020(zmsga) WITH '인보이스 총액'.          " 인보이스 총액을(를) 입력해 주십시오.
  ENDIF.

  " 거래처 송장번호 중복 (상태 무관 전부 차단)
  SELECT SINGLE ivnum FROM ztfia00010 INTO lv_ivnum
    WHERE lifnr = gv_lifnr
      AND xblnr = p_xblnr.
  IF sy-subrc = 0.
    MESSAGE e416(zmsga) WITH lv_ivnum.         " 이미 등록된 거래처 송장번호입니다. (송장번호 IV00000001)
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_controls  - 재실행 시 이전 컨트롤/데이터 정리
*&---------------------------------------------------------------------*
FORM free_controls .
  IF go_alv_reg IS BOUND.  go_alv_reg->free( ).  FREE go_alv_reg.  ENDIF.
  IF go_html IS BOUND.      go_html->free( ).      FREE go_html.      ENDIF.
  IF go_split_reg IS BOUND. go_split_reg->free( ). FREE go_split_reg. ENDIF.
  IF go_cont_reg IS BOUND. go_cont_reg->free( ). FREE go_cont_reg. ENDIF.
*  IF go_alv1 IS BOUND.     go_alv1->free( ).     FREE go_alv1.     ENDIF.
  IF go_alv2 IS BOUND.     go_alv2->free( ).     FREE go_alv2.     ENDIF.
*  IF go_split IS BOUND.    go_split->free( ).    FREE go_split.    ENDIF.
  IF go_cont IS BOUND.     go_cont->free( ).     FREE go_cont.     ENDIF.
  IF go_html_sel IS BOUND. go_html_sel->free( ). FREE go_html_sel. ENDIF.
  IF go_dock_sel IS BOUND. go_dock_sel->free( ). FREE go_dock_sel. ENDIF.
  FREE: go_left_reg, go_right_reg.

  CLEAR: gt_ivreg, gt_fcat_reg, gt_head, gt_item,  gt_fcat2,
         gv_name1, gv_waers, gv_lsum, gv_diff, gv_holdmsg. "gt_fcat1,
*  FREE: go_top, go_bottom, go_left_reg, go_right_reg.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_po_data  - PO 라인 + 합격누계 + 청구가능 → 0100 초기값
*&---------------------------------------------------------------------*
FORM get_po_data .
  TYPES: BEGIN OF ty_po,
           ebelp TYPE ztmma00060-ebelp,
           matnr TYPE ztmma00060-matnr,
           menge TYPE ztmma00060-menge,
           meins TYPE ztmma00060-meins,
           netpr TYPE ztmma00060-netpr,
           waers TYPE ztmma00060-waers,
         END OF ty_po.
  DATA: lt_po     TYPE TABLE OF ty_po,
        ls_po     TYPE ty_po,
        ls_ai     TYPE ty_ai_line,
        lv_billed TYPE ztfia00020-menge,
        lv_excl   TYPE ztfia00010-ivnum.     " 제외할 송장 없음 (빈값)

  SELECT SINGLE lifnr FROM ztmma00050 INTO gv_lifnr WHERE ebeln = p_ebeln.
  SELECT SINGLE name1 FROM ztcma00010 INTO gv_name1 WHERE lifnr = gv_lifnr.

  SELECT ebelp matnr menge meins netpr waers
    FROM ztmma00060
    INTO TABLE lt_po
    WHERE ebeln = p_ebeln.
  SORT lt_po BY ebelp.

  " 통화는 PO 아이템 기준 (PO 헤더에 통화 없음)
  READ TABLE lt_po INTO ls_po INDEX 1.
  gv_waers = ls_po-waers.
  IF gv_waers IS INITIAL.
    gv_waers = 'KRW'.
  ENDIF.
  PERFORM get_cur_factor USING gv_waers CHANGING gv_factor.

  LOOP AT lt_po INTO ls_po.
    CLEAR gw_ivreg.
    gw_ivreg-ebelp = ls_po-ebelp.
    gw_ivreg-matnr = ls_po-matnr.
    gw_ivreg-poqty = ls_po-menge.
    gw_ivreg-meins = ls_po-meins.
    gw_ivreg-ponpr = ls_po-netpr.
    gw_ivreg-waers = gv_waers.

    PERFORM get_pasqt  USING p_ebeln ls_po-ebelp       CHANGING gw_ivreg-pasqt.
    PERFORM get_billed USING p_ebeln ls_po-ebelp lv_excl CHANGING lv_billed.

    gw_ivreg-avlqt = gw_ivreg-pasqt - lv_billed.       " 청구가능 = 합격누계 - 기청구
    IF gw_ivreg-avlqt < 0.
      gw_ivreg-avlqt = 0.
    ENDIF.

    " 노란칸 초기값 (송장과 다르면 사용자가 수정)
    gw_ivreg-menge = gw_ivreg-avlqt.
    gw_ivreg-netpr = gw_ivreg-ponpr.

    " PDF에서 읽은 수량/단가가 있으면 덮어쓰기 (같은 PO일 때만)
    IF gv_ai_ebeln = p_ebeln.
      READ TABLE gt_ai_line INTO ls_ai WITH KEY matnr = ls_po-matnr.
      IF sy-subrc = 0.
        gw_ivreg-menge = ls_ai-menge.
        gw_ivreg-netpr = ls_ai-netpr / gv_factor.     " 원 → 내부값 (KRW ÷100)
      ENDIF.
    ENDIF.

    gw_ivreg-wrbtr = gw_ivreg-menge * gw_ivreg-netpr.

    APPEND gw_ivreg TO gt_ivreg.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_pasqt  - PO라인 합격수량 누계 (130 → 120 → 090)
*&---------------------------------------------------------------------*
FORM get_pasqt USING    pv_ebeln TYPE ztfia00010-ebeln
                        pv_ebelp TYPE ztmma00060-ebelp
               CHANGING pv_pasqt TYPE zsfia00080-pasqt.
  CLEAR pv_pasqt.
  " ⚠️ 재열 확인: GR(090)에 EBELP 저장 여부 / 검사 완료(STATU)만 셀지
  SELECT SUM( c~pasqt )
    FROM ztmma00130 AS c
    INNER JOIN ztmma00120 AS h ON h~inspn = c~inspn
    INNER JOIN ztmma00090 AS g ON g~mblnr = h~mblnr
                              AND g~mjahr = h~mjahr
                              AND g~zeile = c~gritm
    INTO pv_pasqt
    WHERE g~ebeln = pv_ebeln
      AND g~ebelp = pv_ebelp.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_billed  - 같은 PO라인의 기청구수량 (채무 생성된 송장만)
*&---------------------------------------------------------------------*
FORM get_billed USING    pv_ebeln TYPE ztfia00010-ebeln
                         pv_ebelp TYPE ztmma00060-ebelp
                         pv_excl  TYPE ztfia00010-ivnum      " 제외할 송장 (없으면 space)
                CHANGING pv_qty   TYPE ztfia00020-menge.
  CLEAR pv_qty.
  SELECT SUM( i~menge )
    FROM ztfia00020 AS i
    INNER JOIN ztfia00010 AS h ON h~ivnum = i~ivnum
    INTO pv_qty
    WHERE h~ebeln = pv_ebeln
      AND i~ebelp = pv_ebelp
      AND h~ivnum <> pv_excl
      AND ( h~mstat = gc_pass OR h~mstat = gc_hold ).   " 반려(QREJ)는 제외
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_cur_factor  - 통화 소수자리로 내부값 변환 계수 (KRW → 100)
*&---------------------------------------------------------------------*
FORM get_cur_factor USING    pv_waers  TYPE ztmma00060-waers
                    CHANGING pv_factor TYPE i.
  DATA lv_dec TYPE tcurx-currdec.

  SELECT SINGLE currdec FROM tcurx INTO lv_dec WHERE currkey = pv_waers.
  IF sy-subrc <> 0.
    lv_dec = 2.                       " TCURX에 없으면 소수 2자리 통화
  ENDIF.

  IF lv_dec >= 2.
    pv_factor = 1.
  ELSE.
    pv_factor = 10 ** ( 2 - lv_dec ). " 0자리(KRW) = 100, 1자리 = 10
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form calc_total  - 청구금액 재계산 + 라인합계(원) + 차이
*&---------------------------------------------------------------------*
FORM calc_total .
  DATA lv_sum TYPE ztfia00010-wrbtr.

  CLEAR lv_sum.
  LOOP AT gt_ivreg INTO gw_ivreg.
    gw_ivreg-wrbtr = gw_ivreg-menge * gw_ivreg-netpr.    " 내부값 × 수량 = 내부값
    MODIFY gt_ivreg FROM gw_ivreg.
    lv_sum = lv_sum + gw_ivreg-wrbtr.
  ENDLOOP.

  gv_lsum = lv_sum * gv_factor.                          " 내부값 → 원 단위
  gv_diff = p_total - gv_lsum.

  " 숫자 → 문자로 옮겨서 화면에 표시 (음수면 '30,000-')
  WRITE p_total TO gv_total_t.
  WRITE gv_lsum TO gv_lsum_t.
  WRITE gv_diff TO gv_diff_t.

  CALL FUNCTION 'CLOI_PUT_SIGN_IN_FRONT'
    CHANGING
      value = gv_diff_t.

  SHIFT gv_diff_t RIGHT DELETING TRAILING ' '.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object
*&---------------------------------------------------------------------*
FORM create_object .
  DATA lo_parent TYPE REF TO cl_gui_container.

  CREATE OBJECT go_cont_reg
    EXPORTING
      container_name = 'CON_AREA_REG'.

  IF gv_pdf_x IS INITIAL.
    " PDF 없음: 지금처럼 ALV만 전체
    lo_parent = go_cont_reg.
  ELSE.
    " PDF 있음: 왼쪽 ALV / 오른쪽 PDF
    CREATE OBJECT go_split_reg
      EXPORTING
        parent  = go_cont_reg
        rows    = 1
        columns = 2.
    go_split_reg->set_column_width( id = 1 width = 62 ).
    go_left_reg  = go_split_reg->get_container( row = 1 column = 1 ).
    go_right_reg = go_split_reg->get_container( row = 1 column = 2 ).
    lo_parent    = go_left_reg.
  ENDIF.

  CREATE OBJECT go_alv_reg
    EXPORTING
      i_parent = lo_parent.

  " 셀 수정 후 엔터 / 커서 이동 시 바로 이벤트
  go_alv_reg->register_edit_event( EXPORTING i_event_id = cl_gui_alv_grid=>mc_evt_enter ).
  go_alv_reg->register_edit_event( EXPORTING i_event_id = cl_gui_alv_grid=>mc_evt_modified ).
  SET HANDLER lcl_handler=>on_data_changed_finished FOR go_alv_reg.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog  - 청구수량·청구단가만 편집
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSFIA00080'
    CHANGING
      ct_fieldcat      = gt_fcat_reg.

  LOOP AT gt_fcat_reg INTO gs_fcat_reg.
    CASE gs_fcat_reg-fieldname.
      WHEN 'EBELP'. gs_fcat_reg-coltext = 'PO라인'.
      WHEN 'POQTY'. gs_fcat_reg-coltext = 'PO주문수량'.
      WHEN 'PASQT'. gs_fcat_reg-coltext = '입고합격누계'.
      WHEN 'AVLQT'. gs_fcat_reg-coltext = '청구가능'.
      WHEN 'MENGE'. gs_fcat_reg-coltext = '청구수량'. gs_fcat_reg-edit = 'X'.
      WHEN 'MEINS'. gs_fcat_reg-coltext = '단위'.
      WHEN 'PONPR'. gs_fcat_reg-coltext = 'PO단가'.
      WHEN 'NETPR'. gs_fcat_reg-coltext = '청구단가'. gs_fcat_reg-edit = 'X'.
      WHEN 'WRBTR'. gs_fcat_reg-coltext = '청구금액'.
    ENDCASE.
    " 열 너비: 전부 같은 폭, 단위·통화만 절반
    CASE gs_fcat_reg-fieldname.
      WHEN 'MEINS' OR 'WAERS'.
        gs_fcat_reg-outputlen = 2.
      WHEN OTHERS.
        gs_fcat_reg-outputlen = 5.
    ENDCASE.
    MODIFY gt_fcat_reg FROM gs_fcat_reg.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
FORM display_alv .
  DATA lt_exclude TYPE ui_functions.
  DATA ls_layo TYPE lvc_s_layo.

  ls_layo-grid_title = '청구 품목'.

  PERFORM exclude_toolbar CHANGING lt_exclude.

  CALL METHOD go_alv_reg->set_table_for_first_display
    EXPORTING
      i_structure_name     = 'ZSFIA00080'
      it_toolbar_excluding = lt_exclude
      is_layout            = ls_layo
    CHANGING
      it_outtab            = gt_ivreg
      it_fieldcatalog      = gt_fcat_reg
    EXCEPTIONS
      OTHERS               = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_save  - SAVE: 1차 검증 → 저장/3WM → 0200
*&---------------------------------------------------------------------*
FORM process_save .
  " 편집 중인 셀 값 반영 (이벤트에서 calc_total 실행됨)
  DATA: lv_valid  TYPE c LENGTH 1,
        lv_answer TYPE c LENGTH 1.

  gv_saving = 'X'.
  go_alv_reg->check_changed_data( IMPORTING e_valid = lv_valid ).
  CLEAR gv_saving.
  CHECK lv_valid = 'X'.          " 숫자 형식 오류 등 잘못된 셀이 있으면 중단 (ALV가 빨간 표시)

  PERFORM check_before_save CHANGING gv_ok.
  CHECK gv_ok = 'X'.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '인보이스 저장'                              " 팝업 제목
      text_question         = '입력한 내용으로 인보이스를 저장하시겠습니까?'  " 질문
      text_button_1         = '저장'                                       " 1번 버튼
      text_button_2         = '취소'                                       " 2번 버튼
      default_button        = '1'                                          " Enter 치면 저장
      display_cancel_button = ' '                                          " 별도 X 취소 버튼 숨김
    IMPORTING
      answer                = lv_answer                                    " 1 = 저장, 2 = 취소
    EXCEPTIONS
      OTHERS                = 1.
  CHECK sy-subrc = 0 AND lv_answer = '1'.     " 저장 눌렀을 때만 아래로 진행

  PERFORM save_invoice CHANGING gv_ok.
  CHECK gv_ok = 'X'.

  CALL SCREEN 0200.
  LEAVE TO SCREEN 0.              " 0200에서 뒤로 → 0100 건너뛰고 선택화면으로 (중복 저장 방지)
ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_before_save  - 1차 입력 검증 (실패 시 0100에 머묾)
*&---------------------------------------------------------------------*
FORM check_before_save CHANGING pv_ok TYPE c.
  DATA: lv_cnt    TYPE i,
        lv_ivnum  TYPE ztfia00010-ivnum,
        lv_msg    TYPE string,
        lv_diff_c TYPE c LENGTH 20.

  CLEAR pv_ok.
  PERFORM calc_total.

  " ① 음수 입력
  LOOP AT gt_ivreg INTO gw_ivreg WHERE menge < 0 OR netpr < 0.
    MESSAGE s029(zmsga) WITH '청구수량/청구단가' DISPLAY LIKE 'E'.   " 청구수량/청구단가에 음수를 입력할 수 없습니다.
    RETURN.
  ENDLOOP.

  " ② 청구 라인 1개 이상
  LOOP AT gt_ivreg INTO gw_ivreg WHERE menge > 0.
    lv_cnt = lv_cnt + 1.
  ENDLOOP.
  IF lv_cnt = 0.
    MESSAGE s419(zmsga) DISPLAY LIKE 'E'.        " 청구수량이 입력된 라인이 없습니다.
    RETURN.
  ENDIF.

  " ③ 송장 총액 = 라인 합계
  IF gv_diff <> 0.
    WRITE gv_diff TO lv_diff_c.
    CONDENSE lv_diff_c.
    MESSAGE s420(zmsga) WITH lv_diff_c DISPLAY LIKE 'E'.     " 인보이스 총액과 라인 합계가 다릅니다. (차이 1,000,000)
    RETURN.
  ENDIF.

  " ④ 거래처 송장번호 중복 (선택화면 이후 다른 사람이 등록했을 수 있으니 재확인)
  SELECT SINGLE ivnum FROM ztfia00010 INTO lv_ivnum
    WHERE lifnr = gv_lifnr
      AND xblnr = p_xblnr.
  IF sy-subrc = 0.
    MESSAGE s416(zmsga) WITH lv_ivnum DISPLAY LIKE 'E'.   " 이미 등록된 거래처 송장번호입니다. (송장번호 IV00000001)
    RETURN.
  ENDIF.

  pv_ok = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_invoice  - 채번 → INSERT → 3WM → 채무/홀드 → COMMIT → 0200 데이터
*&---------------------------------------------------------------------*
FORM save_invoice CHANGING pv_ok TYPE c.
  DATA: ls_hd     TYPE ztfia00010,
        ls_it     TYPE ztfia00020,
        lt_it     TYPE TABLE OF ztfia00020,
        ls_ap     TYPE ztcma00110,
        lt_result TYPE TABLE OF zsfia00071,
        ls_result TYPE zsfia00071,
        lv_mstat  TYPE ztfia00010-mstat,
        lv_days   TYPE i,
        lv_msg    TYPE string,
        lv_apmsg  TYPE string,
        lv_errtx  TYPE c LENGTH 100.

  CLEAR: pv_ok, gv_holdmsg.

  "─ 1. 송장 헤더 (대사대기)
  PERFORM next_ivnum CHANGING ls_hd-ivnum.
  ls_hd-xblnr = p_xblnr.
  ls_hd-ebeln = p_ebeln.
  ls_hd-lifnr = gv_lifnr.
  ls_hd-bldat = p_bldat.
  ls_hd-budat = p_budat.
  ls_hd-waers = gv_waers.
  ls_hd-wrbtr = p_total / gv_factor.             " 원 단위 → 내부값
  ls_hd-mstat = gc_wait.
  ls_hd-ernam = sy-uname.
  ls_hd-erdat = sy-datum.
  ls_hd-erzet = sy-uzeit.

  INSERT ztfia00010 FROM ls_hd.
  IF sy-subrc <> 0.
    PERFORM rollback_msg USING '송장 헤더 저장'.
    RETURN.
  ENDIF.

  "─ 2. 송장 아이템 (청구수량 > 0 라인만)
  LOOP AT gt_ivreg INTO gw_ivreg WHERE menge > 0.
    CLEAR ls_it.
    ls_it-ivnum = ls_hd-ivnum.
    ls_it-invit = sy-tabix.                      " 임시, 아래에서 재번호
    ls_it-ebelp = gw_ivreg-ebelp.
    ls_it-matnr = gw_ivreg-matnr.
    ls_it-menge = gw_ivreg-menge.
    ls_it-meins = gw_ivreg-meins.
    ls_it-netpr = gw_ivreg-netpr.
    ls_it-wrbtr = gw_ivreg-wrbtr.
    ls_it-mstat = gc_wait.
    ls_it-ernam = sy-uname.
    ls_it-erdat = sy-datum.
    ls_it-erzet = sy-uzeit.
    APPEND ls_it TO lt_it.
  ENDLOOP.

  LOOP AT lt_it INTO ls_it.                      " 라인번호 1,2,3... 로 정리
    ls_it-invit = sy-tabix.
    MODIFY lt_it FROM ls_it.
  ENDLOOP.

  INSERT ztfia00020 FROM TABLE lt_it.
  IF sy-subrc <> 0.
    PERFORM rollback_msg USING '송장 아이템 저장'.
    RETURN.
  ENDIF.

  "─ 3. 3-Way Match (라인 판정 → 헤더 판정, DB UPDATE까지)
  CALL FUNCTION 'Z_3WAY_MATCH'
    EXPORTING
      iv_ivnum      = ls_hd-ivnum
    IMPORTING
      ev_mstat      = lv_mstat
    TABLES
      et_item       = lt_result
    EXCEPTIONS
      not_found     = 1
      update_failed = 2
      OTHERS        = 3.
  IF sy-subrc <> 0.
    PERFORM rollback_msg USING '3-Way Match'.
    RETURN.
  ENDIF.

  "─ 4. 채무 생성 (PASS / HOLD) — HOLD면 함수 안에서 예외 + Payment Hold까지
  IF lv_mstat = gc_pass OR lv_mstat = gc_hold.
    CALL FUNCTION 'Z_FI_CREATE_AP'
      EXPORTING
        iv_ivnum = ls_hd-ivnum
        iv_mstat = lv_mstat
      IMPORTING
        ev_apnum = ls_ap-apnum
        ev_duedt = ls_ap-duedt
        ev_msg   = lv_apmsg
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
      lv_errtx = lv_apmsg.
      IF lv_errtx IS INITIAL.
        lv_errtx = '채무(AP) 생성'.
      ENDIF.
      PERFORM rollback_msg USING lv_errtx.       " AP·예외·홀드 전부 롤백
      RETURN.
    ENDIF.
    IF lv_mstat = gc_hold.
      gv_holdmsg = |/ { lv_apmsg }|.             " "Exception EX… 생성, Payment Hold 등록 (AP…)"
    ENDIF.
  ENDIF.

  "─ 5. QREJ는 채무가 없어서 함수를 안 탐 → 예외만 직접 등록
  IF lv_mstat = gc_qrej.
    PERFORM register_exception USING    ls_hd-ivnum
                                        lv_mstat
                                        ls_ap-apnum
                                        lt_result
                               CHANGING pv_ok.
    IF pv_ok <> 'X'.
      PERFORM rollback_msg USING 'Payment Hold 등록'.
      RETURN.
    ENDIF.
    CLEAR pv_ok.
  ENDIF.

  "─ 6. 전부 성공 → 커밋 (홀드 함수가 UPDATE TASK로 써도 아래 조회에 보이도록 AND WAIT)
  COMMIT WORK AND WAIT.

  "─ 7. 0200 결과 데이터
  CLEAR: gt_head, gt_item, gw_head.
  MOVE-CORRESPONDING ls_hd TO gw_head.
  gw_head-mstat = lv_mstat.
  gw_head-name1 = gv_name1.
  gw_head-apnum = ls_ap-apnum.                   " QREJ면 공란
  gw_head-duedt = ls_ap-duedt.                   " QREJ면 공란
  IF ls_ap-apnum IS NOT INITIAL.
    SELECT SINGLE hdsta FROM ztexa00030 INTO gw_head-hdsta
      WHERE tdtyp = 'AP'
        AND tdnum = ls_ap-apnum.
  ENDIF.
  APPEND gw_head TO gt_head.

  LOOP AT lt_result INTO ls_result.
    CLEAR gw_item.
    MOVE-CORRESPONDING ls_result TO gw_item.
    APPEND gw_item TO gt_item.
  ENDLOOP.

  PERFORM set_status_text.

  MESSAGE s421(zmsga) WITH ls_hd-ivnum lv_mstat gv_holdmsg.  " 송장 IV00000006 등록 완료 / 판정 PASS
  pv_ok = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form rollback_msg
*&---------------------------------------------------------------------*
FORM rollback_msg USING pv_text TYPE c.
  ROLLBACK WORK.
  MESSAGE s067(zmsga) WITH pv_text DISPLAY LIKE 'E'.     " 송장 헤더 저장 처리 중 오류가 발생했습니다.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form next_ivnum  - 송장번호 채번 (IV + 8자리)
*&---------------------------------------------------------------------*
FORM next_ivnum CHANGING pv_ivnum TYPE ztfia00010-ivnum.
  " ⚠️ 임시: MAX+1. 동시 등록까지 막으려면 Number Range(SNRO)로 교체
  DATA: lv_max TYPE ztfia00010-ivnum,
        lv_n   TYPE n LENGTH 8.

  SELECT MAX( ivnum ) FROM ztfia00010 INTO lv_max
    WHERE ivnum LIKE 'IV%'.
  IF lv_max IS NOT INITIAL.
    lv_n = lv_max+2(8).
  ENDIF.
  lv_n = lv_n + 1.
  CONCATENATE 'IV' lv_n INTO pv_ivnum.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form next_apnum  - 채무번호 채번 (AP + 8자리)
*&---------------------------------------------------------------------*
FORM next_apnum CHANGING pv_apnum TYPE ztcma00110-apnum.
  DATA: lv_max TYPE ztcma00110-apnum,
        lv_n   TYPE n LENGTH 8.

  SELECT MAX( apnum ) FROM ztcma00110 INTO lv_max
    WHERE apnum LIKE 'AP%'.
  IF lv_max IS NOT INITIAL.
    lv_n = lv_max+2(8).
  ENDIF.
  lv_n = lv_n + 1.
  CONCATENATE 'AP' lv_n INTO pv_apnum.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_due_days  - 공급업체 지급조건 → 결제일수 (없으면 30일)
*&---------------------------------------------------------------------*
FORM get_due_days USING    pv_lifnr TYPE ztmma00050-lifnr
                  CHANGING pv_days  TYPE i.
  DATA: lv_zterm TYPE ztcma00010-zterm,
        lv_ztday TYPE ztfia00080-ztday.

  pv_days = 30.

  SELECT SINGLE zterm FROM ztcma00010 INTO lv_zterm WHERE lifnr = pv_lifnr.
  CHECK sy-subrc = 0 AND lv_zterm IS NOT INITIAL.

  SELECT SINGLE ztday FROM ztfia00080 INTO lv_ztday
    WHERE zterm = lv_zterm
      AND actyn = 'Y'.
  IF sy-subrc = 0.
    pv_days = lv_ztday.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object_0200
*&---------------------------------------------------------------------*
FORM create_object_0200 .
  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'CON_AREA'.

*  go_split  = NEW #( parent = go_cont rows = 2 columns = 1 ).
*  go_top    = go_split->get_container( row = 1 column = 1 ).
*  go_bottom = go_split->get_container( row = 2 column = 1 ).

*  CREATE OBJECT go_alv1 EXPORTING i_parent = go_top.
  CREATE OBJECT go_alv2 EXPORTING i_parent = go_cont. "go_bottom.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_0200
*&---------------------------------------------------------------------*
FORM set_field_catalog_0200 .
  DATA ls TYPE lvc_s_fcat.

*  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
*    EXPORTING
*      i_structure_name = 'ZSFIA00070'
*    CHANGING
*      ct_fieldcat      = gt_fcat1.
*
*  LOOP AT gt_fcat1 INTO ls.
*    CASE ls-fieldname.
*      WHEN 'XBLNR'. ls-coltext = '거래처송장번호'.
*      WHEN 'BUDAT'. ls-coltext = 'AP 인식일'.
*      WHEN 'WRBTR'. ls-coltext = '총청구금액'.
*      WHEN 'MSTAT'. ls-coltext = '대사판정'.
*      WHEN 'APNUM'. ls-coltext = '채무번호'.
*      WHEN 'DUEDT'. ls-coltext = '지급기한'.
*      WHEN 'HDSTA'. ls-coltext = '홀드'.
*    ENDCASE.
*
*    CASE ls-fieldname.
*      WHEN 'WAERS'.
*        ls-outputlen = 2.
*      WHEN 'MSTAT'.
*        ls-outputlen = 3.
*      WHEN OTHERS.
*        ls-outputlen = 5.
*    ENDCASE.
*    MODIFY gt_fcat1 FROM ls.
*  ENDLOOP.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSFIA00071'
    CHANGING
      ct_fieldcat      = gt_fcat2.

  LOOP AT gt_fcat2 INTO ls.
    CASE ls-fieldname.
      WHEN 'IVNUM'.
        ls-no_out  = 'X'.              " 송장 1건이라 숨김
      WHEN 'EBELP'.
        ls-coltext = 'PO라인'.
      WHEN 'PASQT'.
        ls-coltext = '합격수량누계'.
      WHEN 'MENGE'.
        ls-coltext = '이번청구량'.
      WHEN 'CUMQT'.
        ls-coltext = '누적청구량'.
      WHEN 'NETPR'.
        ls-coltext = '청구단가'.
      WHEN 'PONPR'.
        ls-coltext = 'PO단가'.
      WHEN 'WRBTR'.
        ls-coltext = '청구금액'.
      WHEN 'MEINS'.
        ls-coltext = '단위'.
      WHEN 'MSTAT'.
        ls-coltext = '라인판정'.
    ENDCASE.

    CASE ls-fieldname.
      WHEN 'MEINS' OR 'WAERS'.
        ls-outputlen = 2.
      WHEN 'MSTAT'.
        ls-outputlen = 3.
      WHEN OTHERS.
        ls-outputlen = 5.
    ENDCASE.
    MODIFY gt_fcat2 FROM ls.
  ENDLOOP.

  CLEAR ls.
  ls-fieldname = 'LIGHT'.
  ls-coltext   = '판정'.
  ls-col_pos   = 1.
  ls-outputlen = 3.
  APPEND ls TO gt_fcat2.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_0200  - 1건이라 더블클릭 없이 하단에 전체 라인
*&---------------------------------------------------------------------*
FORM display_alv_0200 .
*  CALL METHOD go_alv1->set_table_for_first_display
*    EXPORTING
*      i_structure_name = 'ZSFIA00070'
*    CHANGING
*      it_outtab        = gt_head
*      it_fieldcatalog  = gt_fcat1
*    EXCEPTIONS
*      OTHERS           = 1.
*
*  CALL METHOD go_alv2->set_table_for_first_display
*    EXPORTING
*      i_structure_name = 'ZSFIA00071'
*    CHANGING
*      it_outtab        = gt_item
*      it_fieldcatalog  = gt_fcat2
*    EXCEPTIONS
*      OTHERS           = 1.
  DATA lt_exclude TYPE ui_functions.

  PERFORM exclude_toolbar CHANGING lt_exclude.

  DATA ls_layo TYPE lvc_s_layo.

  ls_layo-excp_fname = 'LIGHT'.          " 라인 신호등
  ls_layo-zebra      = 'X'.
  ls_layo-grid_title = '송장 라인 판정'.
  ls_layo-smalltitle = 'X'.

  CALL METHOD go_alv2->set_table_for_first_display
    EXPORTING
      is_layout            = ls_layo
      it_toolbar_excluding = lt_exclude
    CHANGING
      it_outtab            = gt_item
      it_fieldcatalog      = gt_fcat2
    EXCEPTIONS
      OTHERS               = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_vendor_name
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_vendor_name .
  DATA lv_name TYPE ztcma00010-name1.

  CLEAR gv_vname.
  CHECK p_ebeln IS NOT INITIAL.

  SELECT SINGLE v~name1
    INTO lv_name
    FROM ztmma00050 AS p
    INNER JOIN ztcma00010 AS v
      ON v~lifnr = p~lifnr
    WHERE p~ebeln = p_ebeln.

  IF sy-subrc = 0.
    gv_vname = lv_name.
  ELSE.
    gv_vname = '존재하지 않는 PO'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_required
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_required .
  LOOP AT SCREEN.
    IF screen-name = 'P_EBELN' OR screen-name = 'P_XBLNR'
    OR screen-name = 'P_BLDAT' OR screen-name = 'P_BUDAT'
    OR screen-name = 'P_TOTAL'.
      screen-required = '2'.          " 필수 표시만, 체크는 check_selection에서
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_vendor_zterm
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GV_LIFNR
*&---------------------------------------------------------------------*
FORM check_vendor_zterm USING pv_lifnr TYPE ztmma00050-lifnr.
  DATA: lv_zterm TYPE ztcma00010-zterm,
        lv_ztday TYPE ztfia00080-ztday,
        lv_msg   TYPE string.

  SELECT SINGLE zterm FROM ztcma00010 INTO lv_zterm
    WHERE lifnr = pv_lifnr.
  IF sy-subrc <> 0 OR lv_zterm IS INITIAL.
    MESSAGE e417(zmsga) WITH pv_lifnr.       " 공급업체 V000000001의 지급조건이 없습니다. 거래처 마스터를 확인해 주십시오.
  ENDIF.

  SELECT SINGLE ztday FROM ztfia00080 INTO lv_ztday
    WHERE zterm = lv_zterm
      AND actyn = 'Y'.
  IF sy-subrc <> 0.
    MESSAGE e418(zmsga) WITH lv_zterm.       " 지급조건 Z001이(가) 지급조건 마스터에 없거나 미사용입니다.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form read_pdf_invoice
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_pdf_invoice .
  DATA: lv_xpdf TYPE xstring,
        lv_b64  TYPE string,
        lv_text TYPE string,
        ls_ai   TYPE ty_ai.

  PERFORM upload_pdf CHANGING lv_xpdf.
  CHECK lv_xpdf IS NOT INITIAL.
  PERFORM show_pdf_sel USING lv_xpdf.            " 선택화면 오른쪽에 PDF 미리보기

  lv_b64 = cl_http_utility=>encode_x_base64( lv_xpdf ).

  PERFORM call_gemini USING lv_b64 CHANGING lv_text.
  CHECK lv_text IS NOT INITIAL.

  PERFORM parse_ai  USING lv_text CHANGING ls_ai.
  PERFORM fill_from_ai USING ls_ai.
  IF gv_ai_ebeln IS NOT INITIAL.          " AI가 PO까지 읽었을 때만
    gv_pdf_x = lv_xpdf.                   " 0100에서 보여줄 PDF 보관
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form upload_pdf
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_XPDF
*&---------------------------------------------------------------------*
FORM upload_pdf  CHANGING pv_xpdf TYPE xstring.
  DATA: lt_file   TYPE filetable,
        ls_file   TYPE file_table,
        lv_rc     TYPE i,
        lv_action TYPE i,
        lv_name   TYPE string,
        lt_bin    TYPE solix_tab,
        lv_len    TYPE i.

  CLEAR pv_xpdf.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title = '공급업체 송장 PDF 선택'
      file_filter  = 'PDF (*.pdf)|*.pdf'
    CHANGING
      file_table   = lt_file
      rc           = lv_rc
      user_action  = lv_action
    EXCEPTIONS
      OTHERS       = 1 ).
  CHECK sy-subrc = 0 AND lv_action = cl_gui_frontend_services=>action_ok.

  READ TABLE lt_file INTO ls_file INDEX 1.
  CHECK sy-subrc = 0.
  lv_name = ls_file-filename.

  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename   = lv_name
      filetype   = 'BIN'
    IMPORTING
      filelength = lv_len
    CHANGING
      data_tab   = lt_bin
    EXCEPTIONS
      OTHERS     = 1 ).
  IF sy-subrc <> 0.
    MESSAGE s302(zmsga) DISPLAY LIKE 'E'.      " PDF 파일을 읽을 수 없습니다.
    RETURN.
  ENDIF.

  pv_xpdf = cl_bcs_convert=>solix_to_xstring( it_solix = lt_bin
                                              iv_size  = lv_len ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form call_gemini
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_B64
*&      <-- LV_TEXT
*&---------------------------------------------------------------------*
FORM call_gemini  USING    pv_b64  TYPE string CHANGING pv_text TYPE string.
  TYPES: BEGIN OF ty_part,
           text TYPE string,
         END OF ty_part,
         ty_t_part TYPE STANDARD TABLE OF ty_part WITH DEFAULT KEY,
         BEGIN OF ty_content,
           parts TYPE ty_t_part,
         END OF ty_content,
         BEGIN OF ty_cand,
           content TYPE ty_content,
         END OF ty_cand,
         ty_t_cand TYPE STANDARD TABLE OF ty_cand WITH DEFAULT KEY,
         BEGIN OF ty_resp,
           candidates TYPE ty_t_cand,
         END OF ty_resp.

  DATA: lo_http   TYPE REF TO if_http_client,
        lv_key    TYPE string,
        lv_model  TYPE string,
        lv_url    TYPE string,
        lv_prompt TYPE string,
        lv_body   TYPE string,
        lv_resp   TYPE string,
        lv_code   TYPE i,
        lv_err    TYPE string,
        lv_msg    TYPE string,
        ls_resp   TYPE ty_resp,
        ls_cand   TYPE ty_cand,
        ls_part   TYPE ty_part.

  CLEAR pv_text.

  "─ 1. API 키 / 모델 (TOP 상수)
  lv_key   = gc_ai_key.
  lv_model = gc_ai_model.

  "─ 2. 지시문 (따옴표 쓰지 말 것: JSON 안에 그대로 들어감)
  lv_prompt = `이 PDF는 공급업체가 보낸 송장이다. 아래 키만 가진 JSON 객체 하나로만 답하라. ` &&
              `ebeln: 구매오더(PO) 번호 숫자만. ` &&
              `xblnr: 공급업체 송장번호. ` &&
              `bldat: 송장 발행일 YYYYMMDD 8자리. ` &&
              `total: 합계금액 원 단위 숫자만 쉼표 없이. ` &&
              `items: 배열, 각 원소는 matnr(자재코드), menge(수량 숫자만), netpr(단가 원 단위 숫자만). ` &&
              `값이 없으면 빈 문자열.`.

  "─ 3. 요청 본문 (PDF + 지시문, JSON으로만 답하게, 생각 최소)
  lv_body = |\{"contents":[\{"parts":[| &&
            |\{"inlineData":\{"mimeType":"application/pdf","data":"{ pv_b64 }"\}\},| &&
            |\{"text":"{ lv_prompt }"\}| &&
            |]\}],| &&
            |"generationConfig":\{"responseMimeType":"application/json",| &&
            |"thinkingConfig":\{"thinkingLevel":"low"\}\}\}|.

  "─ 4. 호출
  lv_url = |https://generativelanguage.googleapis.com/v1beta/models/{ lv_model }:generateContent|.

  cl_http_client=>create_by_url(
    EXPORTING
      url    = lv_url
      ssl_id = 'ANONYM'
    IMPORTING
      client = lo_http
    EXCEPTIONS
      OTHERS = 1 ).
  IF sy-subrc <> 0.
    MESSAGE s092(zmsga) DISPLAY LIKE 'E'.        " 외부 시스템 호출 중 오류가 발생했습니다.
    RETURN.
  ENDIF.

  lo_http->request->set_method( 'POST' ).
  lo_http->request->set_header_field( name = 'content-type'   value = 'application/json; charset=utf-8' ).
  lo_http->request->set_header_field( name = 'x-goog-api-key' value = lv_key ).
  lo_http->request->set_cdata( lv_body ).

  lo_http->send( EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc = 0.
    lo_http->receive( EXCEPTIONS OTHERS = 1 ).
  ENDIF.
  IF sy-subrc <> 0.
    lo_http->get_last_error( IMPORTING message = lv_err ).
    MESSAGE s422(zmsga) WITH lv_err DISPLAY LIKE 'E'.     " AI 통신 실패: (오류 원문, 50자까지)
    lo_http->close( ).
    RETURN.
  ENDIF.

  lo_http->response->get_status( IMPORTING code = lv_code ).
  lv_resp = lo_http->response->get_cdata( ).
  lo_http->close( ).

  IF lv_code <> 200.
    IF lv_code = 429.
      MESSAGE s432(zmsga) DISPLAY LIKE 'E'.                  " AI 무료 사용량 초과 (HTTP 429). 잠시 후 다시 시도해 주십시오.
    ELSE.
      MESSAGE s423(zmsga) WITH lv_code DISPLAY LIKE 'E'.     " AI 호출 실패 (HTTP 400). 모델 ID/키를 확인해 주십시오.
    ENDIF.
    RETURN.
  ENDIF.
  "─ 5. 응답에서 text만 꺼내기
  /ui2/cl_json=>deserialize( EXPORTING json = lv_resp
                             CHANGING  data = ls_resp ).
  READ TABLE ls_resp-candidates INTO ls_cand INDEX 1.
  IF sy-subrc = 0.
    LOOP AT ls_cand-content-parts INTO ls_part.
      pv_text = pv_text && ls_part-text.
    ENDLOOP.
  ENDIF.

  IF pv_text IS INITIAL.
    MESSAGE s093(zmsga) DISPLAY LIKE 'E'.      " 외부 시스템으로부터 응답을 받지 못했습니다.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form parse_ai
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_TEXT
*&      <-- LS_AI
*&---------------------------------------------------------------------*
FORM parse_ai     USING pv_text TYPE string CHANGING ps_ai TYPE ty_ai.
  DATA lv_json TYPE string.

  CLEAR ps_ai.
  lv_json = pv_text.
  REPLACE ALL OCCURRENCES OF '```json' IN lv_json WITH ''.   " 혹시 붙는 코드블록 표시 제거
  REPLACE ALL OCCURRENCES OF '```'     IN lv_json WITH ''.

  /ui2/cl_json=>deserialize( EXPORTING json = lv_json
                             CHANGING  data = ps_ai ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form fill_from_ai  - 선택화면 값 채우기 + 라인 수량/단가 보관
*&---------------------------------------------------------------------*
FORM fill_from_ai USING ps_ai TYPE ty_ai.

  DATA: ls_item TYPE ty_ai_item,
        ls_line TYPE ty_ai_line,
        lv_s    TYPE string.

  CLEAR: gt_ai_line, gv_ai_ebeln.

  IF ps_ai-ebeln IS INITIAL.
    MESSAGE s424(zmsga) DISPLAY LIKE 'E'.     " PDF에서 PO번호를 찾지 못했습니다. 직접 입력해 주십시오.
    RETURN.
  ENDIF.

  " 헤더
  lv_s = ps_ai-ebeln.  CONDENSE lv_s NO-GAPS.  p_ebeln = lv_s.
  lv_s = ps_ai-xblnr.  CONDENSE lv_s.          p_xblnr = lv_s.

  lv_s = ps_ai-bldat.
  REPLACE ALL OCCURRENCES OF REGEX '[^0-9]' IN lv_s WITH ''.
  IF strlen( lv_s ) = 8.
    p_bldat = lv_s.
  ENDIF.

  PERFORM to_number USING ps_ai-total CHANGING p_total.

  " 라인 (0100 화면에서 PO라인 자재코드로 맞춰 넣음)
  LOOP AT ps_ai-items INTO ls_item.
    CLEAR ls_line.
    lv_s = ls_item-matnr.
    CONDENSE lv_s NO-GAPS.
    TRANSLATE lv_s TO UPPER CASE.
    ls_line-matnr = lv_s.
    PERFORM to_number USING ls_item-menge CHANGING ls_line-menge.
    PERFORM to_number USING ls_item-netpr CHANGING ls_line-netpr.
    APPEND ls_line TO gt_ai_line.
  ENDLOOP.

  gv_ai_ebeln = p_ebeln.

  MESSAGE s425(zmsga).          " PDF 송장을 읽어 입력했습니다. 값을 확인한 뒤 실행(F8)해 주십시오.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form to_number
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_ITEM_MENGE
*&      <-- LS_LINE_MENGE
*&---------------------------------------------------------------------*
FORM to_number    USING pv_s TYPE string CHANGING pv_n TYPE p.
  DATA lv_s TYPE string.

  CLEAR pv_n.
  lv_s = pv_s.
  REPLACE ALL OCCURRENCES OF REGEX '[^0-9.\-]' IN lv_s WITH ''.
  CHECK lv_s IS NOT INITIAL.

  TRY.
      pv_n = lv_s.
    CATCH cx_sy_conversion_error.
      CLEAR pv_n.
  ENDTRY.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_pdf
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM show_pdf .
  DATA: lt_bin TYPE solix_tab,
        lv_url TYPE c LENGTH 255.

  CREATE OBJECT go_html
    EXPORTING
      parent = go_right_reg
    EXCEPTIONS
      OTHERS = 1.
  CHECK sy-subrc = 0.

  lt_bin = cl_bcs_convert=>xstring_to_solix( iv_xstring = gv_pdf_x ).

  go_html->load_data(
    EXPORTING
      type         = 'application'
      subtype      = 'pdf'
      size         = xstrlen( gv_pdf_x )
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_bin
    EXCEPTIONS
      OTHERS       = 1 ).
  CHECK sy-subrc = 0.

  go_html->show_url( url = lv_url ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_status_text  - 라인 판정코드 → 신호등 + 한글
*&---------------------------------------------------------------------*
FORM set_status_text .
  LOOP AT gt_item INTO gw_item.
    PERFORM mstat_to_text USING gw_item-mstat
                          CHANGING gw_item-light gw_item-mstxt.
    MODIFY gt_item FROM gw_item.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mstat_to_text  - PASS/HOLD/QREJ → 신호등 번호 + 한글
*&---------------------------------------------------------------------*
FORM mstat_to_text USING    pv_mstat TYPE ztfia00010-mstat
                   CHANGING pv_light TYPE c
                            pv_text  TYPE c.
  CASE pv_mstat.
    WHEN gc_pass.
      pv_light = '3'. pv_text = '통과'.
    WHEN gc_hold.
      pv_light = '2'. pv_text = '단가차이 보류'.
    WHEN gc_qrej.
      pv_light = '1'. pv_text = '수량초과 거절'.
    WHEN OTHERS.
      CLEAR: pv_light, pv_text.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form exclude_toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LT_EXCLUDE
*&---------------------------------------------------------------------*
FORM exclude_toolbar CHANGING pt_exclude TYPE ui_functions.
  APPEND cl_gui_alv_grid=>mc_fc_check             TO pt_exclude.  " 입력 점검
  APPEND cl_gui_alv_grid=>mc_fc_refresh           TO pt_exclude.  " 새로고침
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut           TO pt_exclude.  " 잘라내기
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy          TO pt_exclude.  " 복사
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste         TO pt_exclude.  " 붙여넣기
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO pt_exclude.  " 새 행으로 붙여넣기
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo          TO pt_exclude.  " 실행취소
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row    TO pt_exclude.  " 행 추가
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row    TO pt_exclude.  " 행 삽입
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row    TO pt_exclude.  " 행 삭제
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row      TO pt_exclude.  " 행 복사
ENDFORM.
*&---------------------------------------------------------------------*
*& Form register_exception
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_HD_IVNUM
*&      --> LV_MSTAT
*&      --> LS_AP_APNUM
*&      --> LT_RESULT
*&      <-- PV_OK
*&---------------------------------------------------------------------*
FORM register_exception USING    pv_ivnum  TYPE ztfia00010-ivnum
                                 pv_mstat  TYPE ztfia00010-mstat
                                 pv_apnum  TYPE ztcma00110-apnum
                                 pt_result TYPE STANDARD TABLE
                        CHANGING pv_ok     TYPE c.
  DATA: ls_result TYPE zsfia00071,
        lv_srtyp  TYPE ztexa00010-srtyp VALUE 'INVC',
        lv_srnum  TYPE ztexa00010-srnum,
        lv_sritm  TYPE ztexa00010-sritm,
        lv_owgrp  TYPE ztexa00010-owgrp VALUE 'FI',
        lv_extyp  TYPE ztexa00010-extyp VALUE 'SETL',
        lv_exnum  TYPE ztexa00010-exnum,
        lv_dup    TYPE abap_bool,
        lt_return TYPE bapiret2_t.

  CLEAR pv_ok.
  lv_srnum = pv_ivnum.

  " 문제 라인 = 판정이 같은 첫 라인 (HOLD면 단가차이 라인, QREJ면 수량초과 라인)
  LOOP AT pt_result INTO ls_result.
    IF ls_result-mstat = pv_mstat.
      lv_sritm = ls_result-invit.
      EXIT.
    ENDIF.
  ENDLOOP.

  "─ 1. 예외 등록
  CALL FUNCTION 'ZCM_EXC_CREATE'
    EXPORTING
      iv_srtyp  = lv_srtyp
      iv_srnum  = lv_srnum
      iv_sritm  = lv_sritm
      iv_owgrp  = lv_owgrp
      iv_extyp  = lv_extyp
    IMPORTING
      ev_exnum  = lv_exnum
      ev_dup    = lv_dup
      et_return = lt_return.

  LOOP AT lt_return TRANSPORTING NO FIELDS WHERE type CA 'EAX'.
    RETURN.                                      " pv_ok 공란 → 롤백
  ENDLOOP.
  IF lv_exnum IS INITIAL.
    RETURN.
  ENDIF.

  gv_holdmsg = |/ 예외 { lv_exnum }|.

  pv_ok = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_pdf_sel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_XPDF
*&---------------------------------------------------------------------*
FORM show_pdf_sel  USING  pv_xpdf TYPE xstring.

  DATA: lt_bin TYPE solix_tab,
        lv_url TYPE c LENGTH 255.

  CHECK pv_xpdf IS NOT INITIAL.

  IF go_dock_sel IS NOT BOUND.
    CREATE OBJECT go_dock_sel
      EXPORTING
        repid     = sy-repid
        dynnr     = '1000'
        side      = cl_gui_docking_container=>dock_at_right
        extension = 1000                          " 폭 (픽셀) - 화면 보고 조절
      EXCEPTIONS
        OTHERS    = 1.
    CHECK sy-subrc = 0.

    CREATE OBJECT go_html_sel
      EXPORTING
        parent = go_dock_sel
      EXCEPTIONS
        OTHERS = 1.
    CHECK sy-subrc = 0.
  ENDIF.

  lt_bin = cl_bcs_convert=>xstring_to_solix( iv_xstring = pv_xpdf ).

  go_html_sel->load_data(
    EXPORTING
      type         = 'application'
      subtype      = 'pdf'
      size         = xstrlen( pv_xpdf )
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_bin
    EXCEPTIONS
      OTHERS       = 1 ).
  CHECK sy-subrc = 0.

  go_html_sel->show_url( url = lv_url ).
ENDFORM.
