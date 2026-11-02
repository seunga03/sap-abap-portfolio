*&---------------------------------------------------------------------*
*& Include          ZLFIA00090_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form free_controls  - 재실행 대비 초기화
*&---------------------------------------------------------------------*
FORM free_controls .
  IF go_alv_reg IS BOUND.  go_alv_reg->free( ).  FREE go_alv_reg.  ENDIF.
  IF go_cont_reg IS BOUND. go_cont_reg->free( ). FREE go_cont_reg. ENDIF.
  IF go_alv1 IS BOUND.     go_alv1->free( ).     FREE go_alv1.     ENDIF.
  IF go_alv2 IS BOUND.     go_alv2->free( ).     FREE go_alv2.     ENDIF.
  IF go_split IS BOUND.    go_split->free( ).    FREE go_split.    ENDIF.
  IF go_cont IS BOUND.     go_cont->free( ).     FREE go_cont.     ENDIF.
  FREE: go_top, go_bottom.

  CLEAR: gt_list, gt_res, gt_item, gt_item_all,
         gt_fcat_reg, gt_fcat1, gt_fcat2, gs_layo_reg.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data  - 보류/반려 송장 + 채무정보 + 3WM 미리보기
*&---------------------------------------------------------------------*
FORM get_data .
  DATA: lr_mstat TYPE RANGE OF ztfia00010-mstat,
        ls_mstat LIKE LINE OF lr_mstat,
        lt_hd    TYPE TABLE OF zsfia00070,
        ls_hd    TYPE zsfia00070,
        ls_style TYPE lvc_s_styl.

  ls_mstat-sign   = 'I'.
  ls_mstat-option = 'EQ'.
  IF p_hold = 'X'.
    ls_mstat-low = gc_hold.
    APPEND ls_mstat TO lr_mstat.
  ENDIF.
  IF p_rej = 'X'.
    ls_mstat-low = gc_qrej.
    APPEND ls_mstat TO lr_mstat.
  ENDIF.
  IF lr_mstat IS INITIAL.            " 비어 있으면 IN 조건이 전체를 잡으므로 안전장치
    RETURN.
  ENDIF.

  " 셀 잠금 테이블(deep)이 있는 gt_list 대신 평평한 테이블로 먼저 읽음
  SELECT h~ivnum h~xblnr h~ebeln h~lifnr v~name1
         h~bldat h~budat h~wrbtr h~waers h~mstat
    FROM ztfia00010 AS h
    LEFT OUTER JOIN ztcma00010 AS v ON v~lifnr = h~lifnr
    INTO CORRESPONDING FIELDS OF TABLE lt_hd
    WHERE h~ivnum IN s_ivnum
      AND h~lifnr IN s_lifnr
      AND h~ebeln IN s_ebeln
      AND h~budat IN s_budat
      AND h~mstat IN lr_mstat.

  SORT lt_hd BY ivnum.
  PERFORM read_requests.                         " 유진 후속 요청(FI01 대기분)

  LOOP AT lt_hd INTO ls_hd.
    CLEAR gw_list.
    MOVE-CORRESPONDING ls_hd TO gw_list.

    PERFORM read_ap_info USING    gw_list-ivnum
                         CHANGING gw_list-apnum gw_list-duedt gw_list-hdsta.

    " 3WM 미리보기 (DB 변경 없음)
    PERFORM simulate USING    gw_list-ivnum
                     CHANGING gw_list-expst gw_list-reason gw_list-adjam.
    " 유진 후속 요청 표시
    PERFORM find_request USING    gw_list-ivnum
                         CHANGING gw_list-rqnum gw_list-acttg gw_list-reqtx.

    " PASS 예상이 아니면 선택 체크박스 잠금
    IF gw_list-expst <> gc_pass.
      CLEAR ls_style.
      ls_style-fieldname = 'SEL'.
      ls_style-style     = cl_gui_alv_grid=>mc_style_disabled.
      INSERT ls_style INTO TABLE gw_list-celltab.
    ENDIF.

    APPEND gw_list TO gt_list.

  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form read_ap_info  - 채무번호 / 지급기한 / 홀드상태
*&---------------------------------------------------------------------*
FORM read_ap_info USING    pv_ivnum TYPE ztfia00010-ivnum
                  CHANGING pv_apnum TYPE ztcma00110-apnum
                           pv_duedt TYPE ztcma00110-duedt
                           pv_hdsta TYPE ztexa00030-hdsta.
  CLEAR: pv_apnum, pv_duedt, pv_hdsta.

  SELECT SINGLE apnum duedt FROM ztcma00110
    INTO (pv_apnum, pv_duedt)
    WHERE ivnum = pv_ivnum.

  IF pv_apnum IS NOT INITIAL.
    SELECT SINGLE hdsta FROM ztexa00030 INTO pv_hdsta
  WHERE tdtyp = 'AP' AND tdnum = pv_apnum AND hdsta = 'ACTV'.
    IF sy-subrc <> 0.                            " 활성 홀드 없으면 이력 상태(RLSD 등)
      SELECT SINGLE hdsta FROM ztexa00030 INTO pv_hdsta
        WHERE tdtyp = 'AP' AND tdnum = pv_apnum.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form simulate  - 3WM 미리보기 → 예상판정 + 남은 원인 문장
*&---------------------------------------------------------------------*
FORM simulate USING    pv_ivnum  TYPE ztfia00010-ivnum
              CHANGING pv_expst  TYPE ztfia00010-mstat
                       pv_reason TYPE c
                       pv_adjam  TYPE ztfia00030-apcam.

  DATA: lt_result TYPE TABLE OF zsfia00071,
        ls_result TYPE zsfia00071,
        lv_q1     TYPE c LENGTH 20,
        lv_q2     TYPE c LENGTH 20,
        lv_p1     TYPE c LENGTH 20,
        lv_p2     TYPE c LENGTH 20,
        lv_line   TYPE string,
        lv_text   TYPE string.

  CLEAR: pv_expst, pv_reason, pv_adjam.

  CALL FUNCTION 'Z_3WAY_MATCH'
    EXPORTING
      iv_ivnum    = pv_ivnum
      iv_simulate = 'X'
    IMPORTING
      ev_mstat    = pv_expst
    TABLES
      et_item     = lt_result
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc <> 0.
    pv_reason = '3-Way Match 미리보기 실패'.
    RETURN.
  ENDIF.

  IF pv_expst = gc_pass.
    pv_reason = '모든 라인 통과 - 저장 가능'.
    RETURN.
  ENDIF.

  " 통과 못 한 라인마다 원인 한 줄
  LOOP AT lt_result INTO ls_result WHERE mstat <> gc_pass.
    CLEAR lv_line.
    CASE ls_result-mstat.
      WHEN gc_qrej.
        WRITE ls_result-cumqt TO lv_q1 UNIT ls_result-meins.
        WRITE ls_result-pasqt TO lv_q2 UNIT ls_result-meins.
        CONDENSE: lv_q1, lv_q2.
        lv_line = |PO라인 { ls_result-ebelp ALPHA = OUT }: 누적 { lv_q1 } > 합격 { lv_q2 }|.
      WHEN gc_hold.
        pv_adjam = pv_adjam + ( ls_result-netpr - ls_result-ponpr ) * ls_result-menge.
        WRITE ls_result-netpr TO lv_p1 CURRENCY ls_result-waers.
        WRITE ls_result-ponpr TO lv_p2 CURRENCY ls_result-waers.
        CONDENSE: lv_p1, lv_p2.
        lv_line = |PO라인 { ls_result-ebelp ALPHA = OUT }: 청구단가 { lv_p1 } ≠ PO단가 { lv_p2 }|.
      WHEN OTHERS.
        lv_line = |PO라인 { ls_result-ebelp ALPHA = OUT }: 판정 { ls_result-mstat }|.
    ENDCASE.

    IF lv_text IS INITIAL.
      lv_text = lv_line.
    ELSE.
      lv_text = |{ lv_text } / { lv_line }|.
    ENDIF.
  ENDLOOP.

  pv_reason = lv_text.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object  - 0100 (ALV 1개)
*&---------------------------------------------------------------------*
FORM create_object .
  CREATE OBJECT go_cont_reg
    EXPORTING
      container_name = 'CON_AREA_REG'.
  CREATE OBJECT go_alv_reg
    EXPORTING
      i_parent = go_cont_reg.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog  - 0100: 선택 + 헤더 + 예상판정 + 판정내용
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  DATA ls TYPE lvc_s_fcat.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSFIA00070'
    CHANGING
      ct_fieldcat      = gt_fcat_reg.

  LOOP AT gt_fcat_reg INTO ls.
    ls-col_pos = ls-col_pos + 1.               " 맨 앞을 '선택'으로 비움
    ls-outputlen = 5.                            " 기본 폭
    CASE ls-fieldname.
      WHEN 'XBLNR'. ls-coltext = '거래처송장번호'.
      WHEN 'BUDAT'. ls-coltext = '등록일'.
      WHEN 'WRBTR'. ls-coltext = '총청구금액'.
      WHEN 'MSTAT'. ls-coltext = '현재상태'.
      WHEN 'APNUM'. ls-coltext = '채무번호'.
      WHEN 'DUEDT'. ls-no_out  = 'X'.
      WHEN 'HDSTA'. ls-coltext = '홀드'.
      WHEN 'WAERS'. ls-outputlen = 2.
    ENDCASE.
    MODIFY gt_fcat_reg FROM ls.
  ENDLOOP.

  CLEAR ls.
  ls-fieldname = 'SEL'.
  ls-col_pos   = 1.
  ls-coltext   = '재검증 선택'.
  ls-tooltip   = '체크한 송장만 3-Way Match 재실행 (예상판정 PASS만 체크 가능)'.
  ls-checkbox  = 'X'.
  ls-edit      = 'X'.
  ls-inttype   = 'C'.
  ls-intlen    = 1.
  ls-outputlen = 4.
  APPEND ls TO gt_fcat_reg.

  CLEAR ls.
  ls-fieldname = 'REQTX'.
  ls-col_pos   = 88.
  ls-coltext   = '요청'.
  ls-tooltip   = '예외관리(CM03)가 지시한 처리 → 해당 버튼으로 처리하면 요청 완료'.
  ls-inttype   = 'C'.
  ls-intlen    = 20.
  ls-outputlen = 8.
  ls-emphasize = 'C310'.                         " 노란 강조
  APPEND ls TO gt_fcat_reg.

  CLEAR ls.
  ls-fieldname  = 'ADJAM'.
  ls-col_pos    = 89.
  ls-coltext    = '단가차액'.
  ls-ref_table  = 'ZTFIA00030'.
  ls-ref_field  = 'APCAM'.
  ls-cfieldname = 'WAERS'.
  ls-no_zero    = 'X'.
  ls-outputlen  = 5.
  APPEND ls TO gt_fcat_reg.

  CLEAR ls.
  ls-fieldname = 'EXPST'.
  ls-col_pos   = 90.
  ls-coltext   = '예상판정'.
  ls-inttype   = 'C'.
  ls-intlen    = 4.
  ls-outputlen = 5.
  APPEND ls TO gt_fcat_reg.

  CLEAR ls.
  ls-fieldname = 'REASON'.
  ls-col_pos   = 91.
  ls-coltext   = '판정 내용'.
  ls-inttype   = 'C'.
  ls-intlen    = 120.
  ls-outputlen = 15.
  APPEND ls TO gt_fcat_reg.

  gs_layo_reg-stylefname = 'CELLTAB'.          " 줄마다 체크박스 잠금
  gs_layo_reg-sel_mode   = 'A'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
FORM display_alv .
  DATA lt_exclude TYPE ui_functions.

  PERFORM exclude_toolbar CHANGING lt_exclude.


  CALL METHOD go_alv_reg->set_table_for_first_display
    EXPORTING
      is_layout            = gs_layo_reg
      it_toolbar_excluding = lt_exclude
    CHANGING
      it_outtab            = gt_list
      it_fieldcatalog      = gt_fcat_reg
    EXCEPTIONS
      OTHERS               = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_save  - 체크한 송장 저장 → 0200
*&---------------------------------------------------------------------*
FORM process_save .
  DATA: lv_valid  TYPE c LENGTH 1,
        lv_ok     TYPE c LENGTH 1,
        lv_new    TYPE ztfia00010-mstat,
        lv_apnum  TYPE ztcma00110-apnum,
        lv_duedt  TYPE ztcma00110-duedt,
        lv_text   TYPE string,
        lv_cnt    TYPE i,
        lv_saved  TYPE i,
        lv_fail   TYPE i,
        lt_result TYPE TABLE OF zsfia00071,
        ls_result TYPE zsfia00071.

  go_alv_reg->check_changed_data( IMPORTING e_valid = lv_valid ).
  CHECK lv_valid = 'X'.

  LOOP AT gt_list INTO gw_list WHERE sel = 'X'.
    lv_cnt = lv_cnt + 1.
  ENDLOOP.
  IF lv_cnt = 0.
    MESSAGE s426(zmsga) DISPLAY LIKE 'E'.     " 저장할 송장을 선택해 주십시오. (예상판정 PASS만 선택 가능)
    RETURN.
  ENDIF.

  CLEAR: gt_res, gt_item_all.

  LOOP AT gt_list INTO gw_list WHERE sel = 'X'.
    CLEAR: lv_ok, lv_new, lv_text, lv_apnum, lv_duedt, lt_result, gw_res.
    MOVE-CORRESPONDING gw_list TO gw_res.
    gw_res-oldst = gw_list-mstat.

    "─ 1. 저장 시점에 3WM 실제 실행 (판정 UPDATE, 아직 COMMIT 전)
    CALL FUNCTION 'Z_3WAY_MATCH'
      EXPORTING
        iv_ivnum = gw_list-ivnum
      IMPORTING
        ev_mstat = lv_new
      TABLES
        et_item  = lt_result
      EXCEPTIONS
        OTHERS   = 1.

    IF sy-subrc <> 0.
      lv_text = '3-Way Match 실행 실패'.

    ELSEIF lv_new <> gc_pass.
      " 미리보기 뒤에 데이터가 바뀐 경우 → 저장하지 않음
      lv_text = |저장 시점 재판정 { lv_new } - 저장 안 함|.

    ELSE.
      "─ 2. PASS 처리: 원래 상태별
      CASE gw_list-mstat.

        WHEN gc_qrej.                                " 채무 없던 송장 → 채무 생성
          SELECT SINGLE apnum FROM ztcma00110 INTO lv_apnum
            WHERE ivnum = gw_list-ivnum.
          IF sy-subrc = 0.
            lv_text = |이미 채무 { lv_apnum } 존재 - 확인 필요|.
          ELSE.
            CALL FUNCTION 'Z_FI_CREATE_AP'
              EXPORTING
                iv_ivnum = gw_list-ivnum
                iv_mstat = gc_pass
              IMPORTING
                ev_apnum = lv_apnum
                ev_duedt = lv_duedt
              EXCEPTIONS
                OTHERS   = 1.
            IF sy-subrc = 0.
              lv_ok   = 'X'.
              lv_text = |수량 해결 → 채무 { lv_apnum } 생성 (지급기한 { lv_duedt DATE = USER })|.
            ELSE.
              lv_text = '채무 생성 실패'.
            ENDIF.
          ENDIF.

        WHEN gc_hold.                                " 채무+홀드 → PASS만 (홀드 해제는 CM03에서 유진)
          IF gw_list-apnum IS INITIAL.
            lv_text = 'HOLD 상태인데 채무가 없음 - 확인 필요'.     " lv_ok 공란 → 롤백
          ELSE.
            lv_ok   = 'X'.
            lv_text = '단가 해결 → PASS (홀드 해제는 예외관리 CM03에서)'.
          ENDIF.

      ENDCASE.
    ENDIF.

    "─ 2-1. 유진 요청(APRC) 있으면 완료 (같은 COMMIT)
    PERFORM req_done USING    gw_list-ivnum gc_act_aprc lv_text
                     CHANGING lv_ok lv_text.

    "─ 3. 송장 단위 COMMIT / ROLLBACK
    IF lv_ok = 'X'.
      COMMIT WORK AND WAIT.
      lv_saved = lv_saved + 1.
    ELSE.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
    ENDIF.

    "─ 4. 결과 행: DB 최신값으로
    SELECT SINGLE mstat FROM ztfia00010 INTO gw_res-mstat
      WHERE ivnum = gw_res-ivnum.
    PERFORM read_ap_info USING    gw_res-ivnum
                         CHANGING gw_res-apnum gw_res-duedt gw_res-hdsta.
    gw_res-msg = lv_text.
    APPEND gw_res TO gt_res.

    LOOP AT lt_result INTO ls_result.
      CLEAR gw_item.
      MOVE-CORRESPONDING ls_result TO gw_item.
      APPEND gw_item TO gt_item_all.
    ENDLOOP.
  ENDLOOP.

  MESSAGE s427(zmsga) WITH lv_cnt lv_saved lv_fail.     " 재검증 n건: 저장 n / 저장 안 됨 n

  CALL SCREEN 0200.
  LEAVE TO SCREEN 0.          " 0200에서 뒤로 → 0100 건너뛰고 선택화면 (목록 다시 조회하도록)
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object_0200  - 0200 Split
*&---------------------------------------------------------------------*
FORM create_object_0200 .
  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'CON_AREA'.

  go_split  = NEW #( parent = go_cont rows = 2 columns = 1 ).
  go_top    = go_split->get_container( row = 1 column = 1 ).
  go_bottom = go_split->get_container( row = 2 column = 1 ).

  CREATE OBJECT go_alv1 EXPORTING i_parent = go_top.
  CREATE OBJECT go_alv2 EXPORTING i_parent = go_bottom.

  SET HANDLER lcl_handler=>on_double_click FOR go_alv1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_0200
*&---------------------------------------------------------------------*
FORM set_field_catalog_0200 .
  DATA ls TYPE lvc_s_fcat.

  "─ 상단: 처리 결과
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSFIA00070'
    CHANGING
      ct_fieldcat      = gt_fcat1.

  LOOP AT gt_fcat1 INTO ls.
    ls-outputlen = 5.                            " 기본 폭
    CASE ls-fieldname.
      WHEN 'XBLNR'. ls-coltext = '거래처송장번호'.
      WHEN 'BUDAT'. ls-coltext = '등록일'.
      WHEN 'WRBTR'. ls-coltext = '총청구금액'.
      WHEN 'MSTAT'. ls-coltext = '현재상태'.
      WHEN 'APNUM'. ls-coltext = '채무번호'.
      WHEN 'DUEDT'. ls-coltext = '지급기한'.
      WHEN 'HDSTA'. ls-coltext = '홀드'.
    ENDCASE.
    MODIFY gt_fcat1 FROM ls.
  ENDLOOP.

  CLEAR ls.
  ls-fieldname = 'OLDST'.
  ls-col_pos   = 90.
  ls-coltext   = '이전상태'.
  ls-inttype   = 'C'.
  ls-intlen    = 4.
  ls-outputlen = 5.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'MSG'.
  ls-col_pos   = 91.
  ls-coltext   = '처리 결과'.
  ls-inttype   = 'C'.
  ls-intlen    = 100.
  ls-outputlen = 15.
  APPEND ls TO gt_fcat1.

  "─ 하단: PO라인
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSFIA00071'
    CHANGING
      ct_fieldcat      = gt_fcat2.

  LOOP AT gt_fcat2 INTO ls.
    CASE ls-fieldname.
      WHEN 'IVNUM'. ls-no_out  = 'X'.
      WHEN 'EBELP'. ls-coltext = 'PO라인'.
      WHEN 'PASQT'. ls-coltext = '합격수량누계'.
      WHEN 'MENGE'. ls-coltext = '이번청구량'.
      WHEN 'CUMQT'. ls-coltext = '누적청구량'.
      WHEN 'NETPR'. ls-coltext = '청구단가'.
      WHEN 'PONPR'. ls-coltext = 'PO단가'.
      WHEN 'WRBTR'. ls-coltext = '청구금액'.
      WHEN 'MSTAT'. ls-coltext = '라인판정'.
    ENDCASE.
    MODIFY gt_fcat2 FROM ls.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_0200  - 처음엔 하단 비어 있음 → 상단 더블클릭
*&---------------------------------------------------------------------*
FORM display_alv_0200 .
  CALL METHOD go_alv1->set_table_for_first_display
    CHANGING
      it_outtab       = gt_res
      it_fieldcatalog = gt_fcat1
    EXCEPTIONS
      OTHERS          = 1.

  CALL METHOD go_alv2->set_table_for_first_display
    EXPORTING
      i_structure_name = 'ZSFIA00071'
    CHANGING
      it_outtab        = gt_item
      it_fieldcatalog  = gt_fcat2
    EXCEPTIONS
      OTHERS           = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_cancel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM process_cancel .
  DATA: lt_rows   TYPE lvc_t_row,
        ls_row    TYPE lvc_s_row,
        lt_target LIKE gt_list,
        lv_skip   TYPE i,
        lv_cnt    TYPE i,
        lv_done   TYPE i,
        lv_fail   TYPE i,
        lv_answer TYPE c LENGTH 1,
        lv_text   TYPE string,
        ls_stable TYPE lvc_s_stbl,
        lv_ok     TYPE c LENGTH 1,
        lv_msg    TYPE string.

  "─ 1. 선택 행 (왼쪽 행 선택 버튼)
  go_alv_reg->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
  IF lt_rows IS INITIAL.
    MESSAGE s402(zmsga) WITH '취소할 송장' DISPLAY LIKE 'E'.  " 취소할 송장 행을 선택해 주십시오. (왼쪽 행 선택 버튼)
    RETURN.
  ENDIF.

  "─ 2. QREJ이면서 채무 없는 송장만 대상
  LOOP AT lt_rows INTO ls_row.
    READ TABLE gt_list INTO gw_list INDEX ls_row-index.
    CHECK sy-subrc = 0.
    IF gw_list-mstat = gc_qrej AND gw_list-apnum IS INITIAL.
      APPEND gw_list TO lt_target.
    ELSE.
      lv_skip = lv_skip + 1.                     " HOLD 등은 취소 불가
    ENDIF.
  ENDLOOP.

  lv_cnt = lines( lt_target ).
  IF lv_cnt = 0.
    MESSAGE s428(zmsga) DISPLAY LIKE 'E'.       " 반려(QREJ) 송장만 취소할 수 있습니다.
    RETURN.
  ENDIF.

  "─ 3. 확인 팝업 (DB 쓰기 전)
  lv_text = |반려 송장 { lv_cnt }건을 취소하시겠습니까? 취소 후 되돌릴 수 없습니다.|.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '송장 취소'
      text_question         = lv_text
      text_button_1         = '취소 실행'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      OTHERS                = 1.
  IF sy-subrc <> 0 OR lv_answer <> '1'.
    MESSAGE s005(zmsga).               " 처리가 취소되었습니다.
    RETURN.
  ENDIF.

  "─ 4. 송장 단위 UPDATE → COMMIT / ROLLBACK
  LOOP AT lt_target INTO gw_list.
    " 화면 띄운 사이 상태가 바뀌었을 수 있으므로 QREJ 조건으로만 UPDATE
    UPDATE ztfia00010
       SET mstat = gc_canc
           aenam = sy-uname
           aedat = sy-datum
           aezet = sy-uzeit
     WHERE ivnum = gw_list-ivnum
       AND mstat = gc_qrej.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
      CONTINUE.
    ENDIF.

    "─ 유진 요청(REIS) 있으면 완료 (같은 COMMIT)
    lv_ok  = 'X'.
    lv_msg = '송장 취소(CANC) - 거래처 재발행 송장 대기'.
    PERFORM req_done USING    gw_list-ivnum gc_act_reis lv_msg
                     CHANGING lv_ok lv_msg.
    IF lv_ok <> 'X'.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
      CONTINUE.
    ENDIF.

    UPDATE ztfia00020
       SET mstat = gc_canc
           aenam = sy-uname
           aedat = sy-datum
           aezet = sy-uzeit
     WHERE ivnum = gw_list-ivnum.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
      CONTINUE.
    ENDIF.

    COMMIT WORK AND WAIT.
    lv_done = lv_done + 1.
  ENDLOOP.

  "─ 5. 목록 다시 조회 (CANC는 대상에서 빠짐)
  CLEAR gt_list.
  PERFORM get_data.
  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv_reg->refresh_table_display( is_stable = ls_stable ).

  MESSAGE s429(zmsga) WITH lv_done lv_fail lv_skip.       " 송장 취소 n건 완료 / 실패 n건 / 제외 n건 (QREJ만 가능)
ENDFORM.
*&---------------------------------------------------------------------*
*& Form exclude_toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LT_EXCLUDE
*&---------------------------------------------------------------------*
FORM exclude_toolbar  CHANGING pt_exclude TYPE ui_functions.
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
*& Form process_adjust
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM process_adjust .
  DATA: lt_rows   TYPE lvc_t_row,
        ls_row    TYPE lvc_s_row,
        lt_target LIKE gt_list,
        lt_result TYPE TABLE OF zsfia00071,
        ls_result TYPE zsfia00071,
        ls_ap     TYPE ztcma00110,
        ls_apc    TYPE ztfia00030,
        lv_diff   TYPE ztfia00030-apcam,
        lv_open   TYPE ztcma00110-dmbtr,
        lv_amt    TYPE c LENGTH 30,
        lv_answer TYPE c LENGTH 1,
        lv_text   TYPE string,
        lv_skip   TYPE i,
        lv_done   TYPE i,
        lv_fail   TYPE i,
        ls_stable TYPE lvc_s_stbl,lv_cnt    TYPE i,
        lv_p1     TYPE c LENGTH 20,
        lv_p2     TYPE c LENGTH 20,
        lv_pd     TYPE c LENGTH 20,
        lv_q      TYPE c LENGTH 20,
        lv_dm     TYPE c LENGTH 20,
        lv_net    TYPE c LENGTH 20,
        lv_netbt  TYPE ztcma00110-dmbtr,
        lv_unitd  TYPE ztfia00020-netpr,
        lv_d1     TYPE c LENGTH 80,
        lv_d2     TYPE c LENGTH 80,
        lv_d3     TYPE c LENGTH 80,
        lv_t1     TYPE c LENGTH 80,
        lv_t2     TYPE c LENGTH 80,
        ls_first  TYPE zsfia00071,
        lv_ok     TYPE c LENGTH 1,
        lv_msg    TYPE string.

  "─ 1. 선택 행 중 HOLD + 채무 있는 것만
  go_alv_reg->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
  IF lt_rows IS INITIAL.
    MESSAGE s402(zmsga) WITH '조정할 송장' DISPLAY LIKE 'E'.  " 조정할 송장 행을 선택해 주십시오. (왼쪽 행 선택 버튼)
    RETURN.
  ENDIF.

  LOOP AT lt_rows INTO ls_row.
    READ TABLE gt_list INTO gw_list INDEX ls_row-index.
    CHECK sy-subrc = 0.
    IF gw_list-mstat = gc_hold AND gw_list-apnum IS NOT INITIAL.
      APPEND gw_list TO lt_target.
    ELSE.
      lv_skip = lv_skip + 1.
    ENDIF.
  ENDLOOP.

  IF lt_target IS INITIAL.
    MESSAGE s430(zmsga) DISPLAY LIKE 'E'.     " 단가차이(HOLD) 송장만 조정할 수 있습니다.
    RETURN.
  ENDIF.

  "─ 2. 송장 단위로 처리
  LOOP AT lt_target INTO gw_list.
    CLEAR: lt_result, lv_diff, ls_ap, ls_apc, lv_answer.

    " 2-1. 차액 계산: 3WM 시뮬레이션 (DB 변경 없음)
    CALL FUNCTION 'Z_3WAY_MATCH'
      EXPORTING
        iv_ivnum    = gw_list-ivnum
        iv_simulate = 'X'
      TABLES
        et_item     = lt_result
      EXCEPTIONS
        OTHERS      = 1.
    IF sy-subrc <> 0.
      lv_fail = lv_fail + 1.
      CONTINUE.
    ENDIF.

    LOOP AT lt_result INTO ls_result WHERE mstat = gc_hold.
      lv_diff = lv_diff + ( ls_result-netpr - ls_result-ponpr ) * ls_result-menge.
    ENDLOOP.
    IF lv_diff <= 0.                       " 청구단가 ≤ PO단가 → 조정 대상 아님
      lv_skip = lv_skip + 1.
      CONTINUE.
    ENDIF.

    " 2-2. 채무 확인 (이미 조정됐거나 잔액보다 크면 제외)
    SELECT SINGLE * FROM ztcma00110 INTO ls_ap
      WHERE apnum = gw_list-apnum.
    IF sy-subrc <> 0 OR ls_ap-adjbt > 0.
      lv_skip = lv_skip + 1.
      CONTINUE.
    ENDIF.
    lv_open = ls_ap-dmbtr - ls_ap-paybt - ls_ap-adjbt.
    IF lv_diff > lv_open.
      lv_skip = lv_skip + 1.
      CONTINUE.
    ENDIF.

    " 2-3. 확인 팝업: 단가차이 내역 → 차액 → 처리 후 확정채무
    CLEAR: lv_cnt, ls_first.
    LOOP AT lt_result INTO ls_result WHERE mstat = gc_hold.
      lv_cnt = lv_cnt + 1.
      IF lv_cnt = 1.
        ls_first = ls_result.
      ENDIF.
    ENDLOOP.

    WRITE lv_diff TO lv_amt CURRENCY gw_list-waers.
    CONDENSE lv_amt.

    lv_d1 = |{ gw_list-ivnum } { gw_list-name1 } / PO { gw_list-ebeln }|.

    IF lv_cnt = 1.
      lv_unitd = ls_first-netpr - ls_first-ponpr.
      WRITE ls_first-netpr TO lv_p1 CURRENCY gw_list-waers.
      WRITE ls_first-ponpr TO lv_p2 CURRENCY gw_list-waers.
      WRITE lv_unitd       TO lv_pd CURRENCY gw_list-waers.
      WRITE ls_first-menge TO lv_q  UNIT ls_first-meins.
      CONDENSE: lv_p1, lv_p2, lv_pd, lv_q.
      lv_d2 = |청구단가 { lv_p1 } - PO단가 { lv_p2 } = { lv_pd }|.
      lv_d3 = |청구수량 { lv_q } { ls_first-meins } x { lv_pd } = 차액 { lv_amt } { gw_list-waers }|.
    ELSE.
      lv_d2 = |단가차이 라인 { lv_cnt }건 (라인 { ls_first-ebelp ALPHA = OUT } 외)|.
      lv_d3 = |라인별 (청구단가 - PO단가) x 수량 합계 = 차액 { lv_amt } { gw_list-waers }|.
    ENDIF.

    lv_netbt = ls_ap-dmbtr - ls_ap-adjbt - lv_diff.
    WRITE ls_ap-dmbtr TO lv_dm  CURRENCY gw_list-waers.
    WRITE lv_netbt    TO lv_net CURRENCY gw_list-waers.
    CONDENSE: lv_dm, lv_net.
    lv_t1 = |확정채무 { lv_dm } → { lv_net } 후 PASS 처리|.
    lv_t2 = '단가차이 조정을 실행하시겠습니까? (홀드 해제는 CM03)'.

    CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE'
      EXPORTING
        defaultoption  = 'N'
        diagnosetext1  = lv_d1
        diagnosetext2  = lv_d2
        diagnosetext3  = lv_d3
        textline1      = lv_t1
        textline2      = lv_t2
        titel          = '단가차이 조정'
        cancel_display = space
      IMPORTING
        answer         = lv_answer
      EXCEPTIONS
        OTHERS         = 1.
    IF sy-subrc <> 0 OR lv_answer <> 'J'.        " J = 예
      lv_skip = lv_skip + 1.
      CONTINUE.
    ENDIF.

    " 2-4. 반제 테이블: 조정 행 (지급번호 공란)
    PERFORM next_apcnr CHANGING ls_apc-apcnr.
    ls_apc-apcsq = 1.
    ls_apc-apnum = ls_ap-apnum.
    ls_apc-apcam = lv_diff.
    ls_apc-apcdt = sy-datum.
    ls_apc-lifnr = ls_ap-lifnr.
    ls_apc-waers = ls_ap-waers.
    ls_apc-aprsn = gc_rsn_price.
    ls_apc-ernam = sy-uname.
    ls_apc-erdat = sy-datum.
    ls_apc-erzet = sy-uzeit.
    INSERT ztfia00030 FROM ls_apc.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
      CONTINUE.
    ENDIF.

    " 2-5. AP: 조정누계 + 지급상태
    ls_ap-adjbt = ls_ap-adjbt + lv_diff.
    IF ls_ap-paybt + ls_ap-adjbt >= ls_ap-dmbtr.
      ls_ap-clsta = gc_clsta_done.
      ls_ap-augdt = sy-datum.
    ELSE.
      ls_ap-clsta = gc_clsta_part.
    ENDIF.
    UPDATE ztcma00110
       SET adjbt = ls_ap-adjbt
           clsta = ls_ap-clsta
           augdt = ls_ap-augdt
           aenam = sy-uname
           aedat = sy-datum
           aezet = sy-uzeit
     WHERE apnum = ls_ap-apnum.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
      CONTINUE.
    ENDIF.

    " 2-6. 송장: HOLD → PASS (결과적으로 정상 처리 가능)
    UPDATE ztfia00010
       SET mstat = gc_pass
           aenam = sy-uname
           aedat = sy-datum
           aezet = sy-uzeit
     WHERE ivnum = gw_list-ivnum
       AND mstat = gc_hold.
    IF sy-subrc <> 0.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
      CONTINUE.
    ENDIF.

    UPDATE ztfia00020
       SET mstat = gc_pass
           aenam = sy-uname
           aedat = sy-datum
           aezet = sy-uzeit
     WHERE ivnum = gw_list-ivnum
       AND mstat = gc_hold.

    "─ 유진 요청(STLR) 있으면 완료 (같은 COMMIT)
    lv_ok  = 'X'.
    lv_msg = |단가차이 { lv_amt } 조정반제 ({ ls_apc-apcnr }) → PASS|.
    PERFORM req_done USING    gw_list-ivnum gc_act_stlr lv_msg
                     CHANGING lv_ok lv_msg.
    IF lv_ok <> 'X'.
      ROLLBACK WORK.
      lv_fail = lv_fail + 1.
      CONTINUE.
    ENDIF.

    COMMIT WORK AND WAIT.
    lv_done = lv_done + 1.
  ENDLOOP.

  "─ 3. 목록 다시 조회 (PASS 된 건은 빠짐)
  CLEAR gt_list.
  PERFORM get_data.
  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv_reg->refresh_table_display( is_stable = ls_stable ).

  MESSAGE s431(zmsga) WITH lv_done lv_fail lv_skip.      " 단가차이 조정 n건 완료 / 실패 n건 / 제외 n건 (홀드 해제는 CM03)
ENDFORM.
*&---------------------------------------------------------------------*
*& Form next_apcnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LS_APC_APCNR
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
*& Form read_requests
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_requests .
  DATA lt_ret TYPE bapiret2_t.

  CLEAR gt_req.
  CALL FUNCTION 'ZCM_EXC_REQ_GET'
    EXPORTING
      iv_tgpgm  = gc_tgpgm
    IMPORTING
      et_req    = gt_req
      et_return = lt_ret.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form find_request
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GW_LIST_IVNUM
*&      <-- GW_LIST_RQNUM
*&      <-- GW_LIST_ACTTG
*&      <-- GW_LIST_REQTX
*&---------------------------------------------------------------------*
FORM find_request USING    pv_ivnum TYPE ztfia00010-ivnum
                  CHANGING pv_rqnum TYPE ztexa00060-rqnum
                           pv_acttg TYPE ztexa00060-acttp
                           pv_reqtx TYPE c.
  DATA ls_req LIKE LINE OF gt_req.

  CLEAR: pv_rqnum, pv_acttg, pv_reqtx.

  LOOP AT gt_req INTO ls_req.
    CHECK ls_req-srtyp = 'INVC' AND ls_req-srnum = pv_ivnum.
    pv_rqnum = ls_req-rqnum.
    pv_acttg = ls_req-acttp.
    CASE ls_req-acttp.
      WHEN gc_act_aprc. pv_reqtx = '재검증'.
      WHEN gc_act_reis. pv_reqtx = '송장 취소'.
      WHEN gc_act_stlr. pv_reqtx = '단가차이 조정'.
      WHEN OTHERS.      pv_reqtx = ls_req-acttp.
    ENDCASE.
    EXIT.                                        " 송장당 첫 요청 1건
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form req_done
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GW_LIST_IVNUM
*&      --> GC_ACT_STLR
*&      --> LV_MSG
*&      <-- LV_OK
*&      <-- LV_MSG
*&---------------------------------------------------------------------*
FORM req_done USING    pv_ivnum TYPE ztfia00010-ivnum
                       pv_acttg TYPE ztexa00060-acttp
                       pv_memo  TYPE string
              CHANGING pv_ok    TYPE c
                       pv_text  TYPE string.
  DATA: ls_req   LIKE LINE OF gt_req,
        lv_rstxt TYPE ztexa00060-rstxt,
        lt_ret   TYPE bapiret2_t,
        ls_ret   TYPE bapiret2.

  CHECK pv_ok = 'X'.

  LOOP AT gt_req INTO ls_req.
    CHECK ls_req-srtyp = 'INVC'
      AND ls_req-srnum = pv_ivnum
      AND ls_req-acttp = pv_acttg.

    lv_rstxt = pv_memo.
    CALL FUNCTION 'ZCM_EXC_REQ_DONE'
      EXPORTING
        iv_rqnum  = ls_req-rqnum
        iv_rstxt  = lv_rstxt
      IMPORTING
        et_return = lt_ret.

    READ TABLE lt_ret INTO ls_ret WITH KEY type = 'E'.
    IF sy-subrc = 0.
      CLEAR pv_ok.                               " → 호출한 쪽에서 ROLLBACK
      pv_text = |요청 { ls_req-rqnum } 완료 실패: { ls_ret-message }|.
    ELSE.
      pv_text = |{ pv_text } / 요청 { ls_req-rqnum } 완료|.
    ENDIF.
    EXIT.
  ENDLOOP.
ENDFORM.
