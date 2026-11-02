*&---------------------------------------------------------------------*
*& Include          ZLFIA00170_F01
*&---------------------------------------------------------------------*
FORM get_data .
  TYPES: BEGIN OF ty_key,
           tdnum TYPE ztexa00030-tdnum,
         END OF ty_key,
         BEGIN OF ty_hd,
           tdnum TYPE ztexa00030-tdnum,
           hdsta TYPE ztexa00030-hdsta,
         END OF ty_hd.
  DATA: lr_mstat TYPE RANGE OF ztfia00010-mstat,
        ls_mstat LIKE LINE OF lr_mstat,
        lt_key   TYPE TABLE OF ty_key,           " 조회된 채무번호 (tdnum 타입으로)
        ls_key   TYPE ty_key,
        lt_hd    TYPE TABLE OF ty_hd,            " 홀드 상태 (한 번에 읽기)
        ls_hd    TYPE ty_hd.

  CLEAR: gt_head, gt_item.

  " 대사상태 체크박스 → range
  ls_mstat-sign = 'I'. ls_mstat-option = 'EQ'.
  IF p_ok   = 'X'. ls_mstat-low = 'PASS'. APPEND ls_mstat TO lr_mstat. ENDIF.
  IF p_hold = 'X'. ls_mstat-low = 'HOLD'. APPEND ls_mstat TO lr_mstat. ENDIF.
  IF p_rej  = 'X'. ls_mstat-low = 'QREJ'. APPEND ls_mstat TO lr_mstat. ENDIF.
  IF p_canc = 'X'. ls_mstat-low = 'CANC'. APPEND ls_mstat TO lr_mstat. ENDIF.
  CHECK lr_mstat IS NOT INITIAL.          " 빈 range = 전체 조회 방지

  SELECT h~ivnum h~xblnr h~ebeln h~lifnr v~name1
         h~bldat h~budat h~wrbtr h~taxam h~adjtx h~waers h~mstat
         a~apnum a~duedt a~adjbt
    FROM ztfia00010 AS h
    LEFT OUTER JOIN ztcma00010 AS v ON v~lifnr = h~lifnr
    LEFT OUTER JOIN ztcma00110 AS a ON a~ivnum = h~ivnum
    INTO CORRESPONDING FIELDS OF TABLE gt_head
    WHERE h~ivnum IN s_ivnum
      AND h~xblnr IN s_xblnr
      AND h~lifnr IN s_lifnr
      AND h~ebeln IN s_ebeln
      AND h~bldat IN s_bldat
      AND h~budat IN s_budat
      AND h~mstat IN lr_mstat.

  SORT gt_head BY ivnum DESCENDING.

  " 홀드 표시 (채무 있는 건만) — 한 번에 읽고, 활성(ACTV) 먼저 없으면 이력(RLSD 등)
  LOOP AT gt_head INTO gw_head WHERE apnum IS NOT INITIAL.
    ls_key-tdnum = gw_head-apnum.
    APPEND ls_key TO lt_key.
  ENDLOOP.

  IF lt_key IS NOT INITIAL.                      " 비어 있으면 FOR ALL ENTRIES가 전체를 읽음
    SELECT tdnum hdsta FROM ztexa00030
      INTO TABLE lt_hd
      FOR ALL ENTRIES IN lt_key
      WHERE tdtyp = 'AP'
        AND tdnum = lt_key-tdnum.
  ENDIF.
  SORT lt_hd BY tdnum hdsta.

  LOOP AT gt_head INTO gw_head WHERE apnum IS NOT INITIAL.
    ls_key-tdnum = gw_head-apnum.
    READ TABLE lt_hd INTO ls_hd
         WITH KEY tdnum = ls_key-tdnum hdsta = 'ACTV' BINARY SEARCH.
    IF sy-subrc <> 0.
      READ TABLE lt_hd INTO ls_hd
           WITH KEY tdnum = ls_key-tdnum BINARY SEARCH.
    ENDIF.
    IF sy-subrc = 0.
      gw_head-hdsta = ls_hd-hdsta.
      MODIFY gt_head FROM gw_head TRANSPORTING hdsta.
    ENDIF.
  ENDLOOP.

  " 대사상태 → 아이콘, 확정채무
  LOOP AT gt_head INTO gw_head.
    CASE gw_head-mstat.
      WHEN 'PASS'.
        IF gw_head-hdsta = 'ACTV'.               " FI 처리 끝, CM03 홀드 해제 전
          gw_head-stico = icon_led_inactive.
        ELSE.                                    " 지급 가능
          gw_head-stico = icon_led_green.
        ENDIF.
      WHEN 'HOLD'. gw_head-stico = icon_led_yellow.
      WHEN 'QREJ'. gw_head-stico = icon_led_red.
      WHEN 'CANC'. gw_head-stico = icon_cancel.
    ENDCASE.

    gw_head-totbt = gw_head-wrbtr + gw_head-taxam.   " 총청구금액 = 공급가액 + 세액 (예전 송장은 세액 0)

    IF gw_head-apnum IS NOT INITIAL.             " 채무 있는 건만
      gw_head-netbt = gw_head-totbt - gw_head-adjbt.
    ENDIF.

    " 확정세액: 세금계산서를 받아 채무로 잡은 송장만 (반려·취소는 매입세액공제 대상 아님)
    IF gw_head-mstat = 'PASS' OR gw_head-mstat = 'HOLD'.
      gw_head-dedtx = gw_head-taxam - gw_head-adjtx.
    ENDIF.

    MODIFY gt_head FROM gw_head TRANSPORTING stico totbt netbt dedtx.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object .
  CREATE OBJECT go_cc EXPORTING container_name = 'CC_KPI'.
  CREATE OBJECT go_kpi EXPORTING io_parent = go_cc.
  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'CON_AREA'.

  go_split  = NEW #( parent = go_cont rows = 2 columns = 1 ).
  go_top    = go_split->get_container( row = 1 column = 1 ).
  go_bottom = go_split->get_container( row = 2 column = 1 ).
  go_split->set_row_height( id = 1 height = 60 ).

  CREATE OBJECT go_alv1 EXPORTING i_parent = go_top.
  CREATE OBJECT go_alv2 EXPORTING i_parent = go_bottom.

  SET HANDLER lcl_handler=>on_double_click FOR go_alv1.
  SET HANDLER lcl_handler=>on_item_double_click FOR go_alv2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  DATA ls TYPE lvc_s_fcat.

  " ─ 상단: 송장 헤더 ─
  "   순서: 상태 → 인보이스번호 → 공급업체명 → 대사판정 → 홀드 → 증빙일
  "        → 공급가액 → 세액 → 총청구금액 → 조정액 → 조정세액 → 확정채무 → 확정세액 → 통화
  "        → 매입채무번호 → 등록일 → 거래처송장번호 → 구매문서 → 공급업체
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSFIA00070'
    CHANGING
      ct_fieldcat      = gt_fcat1.

  LOOP AT gt_fcat1 INTO ls.
    ls-outputlen = 5.
    CASE ls-fieldname.
        " 누구 송장 · 상태
      WHEN 'IVNUM'. ls-col_pos = 2.
      WHEN 'NAME1'. ls-col_pos = 3.
      WHEN 'MSTAT'. ls-col_pos = 4.  ls-coltext = '대사판정'.
      WHEN 'HDSTA'. ls-col_pos = 5.  ls-coltext = '홀드'.
      WHEN 'BLDAT'. ls-col_pos = 6.
        " 금액 (원본 → 조정 → 확정) : 7~13, 세액·합계 등은 아래 APPEND 열
      WHEN 'WRBTR'. ls-col_pos = 7.  ls-coltext = '공급가액'.
      WHEN 'WAERS'. ls-col_pos = 14. ls-outputlen = 2.
        " 참고 번호
      WHEN 'APNUM'. ls-col_pos = 15.
      WHEN 'BUDAT'. ls-col_pos = 16. ls-coltext = '등록일'.
      WHEN 'XBLNR'. ls-col_pos = 17. ls-coltext = '거래처송장번호'.
      WHEN 'EBELN'. ls-col_pos = 18.
      WHEN 'LIFNR'. ls-col_pos = 19.
      WHEN 'DUEDT'. ls-no_out  = 'X'.
      WHEN OTHERS.  ls-col_pos = ls-col_pos + 20.   " 구조에 다른 필드가 생기면 맨 뒤로
    ENDCASE.
    MODIFY gt_fcat1 FROM ls.
  ENDLOOP.

  " 상태 아이콘 (구조체에 없는 필드라 APPEND)
  CLEAR ls.
  ls-fieldname = 'STICO'.
  ls-col_pos   = 1.
  ls-coltext   = '상태'.
  ls-icon      = 'X'.
  ls-outputlen = 3.
  APPEND ls TO gt_fcat1.

  " 원본: 세액 / 총청구금액
  CLEAR ls.
  ls-fieldname  = 'TAXAM'.
  ls-col_pos    = 8.
  ls-coltext    = '세액'.
  ls-ref_table  = 'ZTFIA00010'.
  ls-ref_field  = 'TAXAM'.
  ls-cfieldname = 'WAERS'.
  ls-outputlen  = 5.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname  = 'TOTBT'.
  ls-col_pos    = 9.
  ls-coltext    = '총청구금액'.
  ls-tooltip    = '공급가액 + 세액'.
  ls-ref_table  = 'ZTFIA00010'.
  ls-ref_field  = 'WRBTR'.
  ls-cfieldname = 'WAERS'.
  ls-outputlen  = 5.
  APPEND ls TO gt_fcat1.

  " 조정: 조정액 / 조정세액
  CLEAR ls.
  ls-fieldname  = 'ADJBT'.
  ls-col_pos    = 10.
  ls-coltext    = '조정액'.
  ls-ref_table  = 'ZTCMA00110'.
  ls-ref_field  = 'ADJBT'.
  ls-cfieldname = 'WAERS'.
  ls-outputlen  = 5.
  ls-no_zero    = 'X'.                           " 조정 없으면 빈칸
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname  = 'ADJTX'.
  ls-col_pos    = 11.
  ls-coltext    = '조정세액'.
  ls-tooltip    = '단가차이 조정액 중 세액 부분'.
  ls-ref_table  = 'ZTFIA00010'.
  ls-ref_field  = 'ADJTX'.
  ls-cfieldname = 'WAERS'.
  ls-outputlen  = 5.
  ls-no_zero    = 'X'.                           " 조정 없으면 빈칸
  APPEND ls TO gt_fcat1.

  " 확정: 확정채무 / 확정세액
  CLEAR ls.
  ls-fieldname  = 'NETBT'.
  ls-col_pos    = 12.
  ls-coltext    = '확정채무'.
  ls-tooltip    = '총청구금액 - 조정액'.
  ls-ref_table  = 'ZTCMA00110'.
  ls-ref_field  = 'DMBTR'.
  ls-cfieldname = 'WAERS'.
  ls-outputlen  = 5.
  ls-no_zero    = 'X'.                           " 채무 없으면 빈칸
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname  = 'DEDTX'.
  ls-col_pos    = 13.
  ls-coltext    = '확정세액'.
  ls-tooltip    = '세액 - 조정세액 (매입세액공제 대상, 반려·취소 제외)'.
  ls-ref_table  = 'ZTFIA00010'.
  ls-ref_field  = 'TAXAM'.
  ls-cfieldname = 'WAERS'.
  ls-outputlen  = 5.
  ls-no_zero    = 'X'.                           " 반려·취소는 빈칸
  APPEND ls TO gt_fcat1.

  " ─ 하단: PO라인 상세 ─
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSFIA00071'
    CHANGING
      ct_fieldcat      = gt_fcat2.

  LOOP AT gt_fcat2 INTO ls.
    ls-outputlen = 5.
    CASE ls-fieldname.
      WHEN 'PASQT' OR 'CUMQT' OR 'PONPR' OR 'IVNUM'. ls-no_out = 'X'.   " 조회에서는 안 씀 (저장값만 표시)
      WHEN 'MENGE'. ls-coltext = '청구수량'.
      WHEN 'NETPR'. ls-coltext = '청구단가'.
      WHEN 'WRBTR'. ls-coltext = '청구금액'.
      WHEN 'MSTAT'. ls-coltext = '라인판정'.
      WHEN 'MEINS'. ls-coltext = '단위'. ls-outputlen = 2.
      WHEN 'WAERS'. ls-outputlen = 2.
    ENDCASE.
    MODIFY gt_fcat2 FROM ls.
  ENDLOOP.

  " 세금코드 (라인에 저장된 코드, 세율은 마스터)
  CLEAR ls.
  ls-fieldname = 'TAXCD'.
  ls-col_pos   = lines( gt_fcat2 ) + 1.          " 맨 뒤
  ls-coltext   = '세금코드'.
  ls-ref_table = 'ZTFIA00020'.
  ls-ref_field = 'TAXCD'.
  ls-just      = 'C'.
  ls-outputlen = 4.
  APPEND ls TO gt_fcat2.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  DATA: ls_layo1 TYPE lvc_s_layo,
        ls_layo2 TYPE lvc_s_layo.

  ls_layo1-zebra      = 'X'.
  ls_layo1-sel_mode   = 'B'.
  ls_layo1-grid_title = |구매송장 목록 ({ lines( gt_head ) }건)|.

  ls_layo2-zebra      = 'X'.
  ls_layo2-grid_title = '송장 라인 상세'.

  CALL METHOD go_alv1->set_table_for_first_display
    EXPORTING
      is_layout       = ls_layo1
    CHANGING
      it_outtab       = gt_head
      it_fieldcatalog = gt_fcat1
    EXCEPTIONS
      OTHERS          = 1.

  CALL METHOD go_alv2->set_table_for_first_display
    EXPORTING
      is_layout       = ls_layo2
    CHANGING
      it_outtab       = gt_item
      it_fieldcatalog = gt_fcat2
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_controls
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_controls .
  IF go_kpi IS BOUND.  go_kpi->free( ).  FREE go_kpi.  ENDIF.
  IF go_cc  IS BOUND.  go_cc->free( ).   FREE go_cc.   ENDIF.
  IF go_alv1 IS BOUND.  go_alv1->free( ).  FREE go_alv1.  ENDIF.
  IF go_alv2 IS BOUND.  go_alv2->free( ).  FREE go_alv2.  ENDIF.
  IF go_split IS BOUND. go_split->free( ). FREE go_split. ENDIF.
  IF go_cont IS BOUND.  go_cont->free( ).  FREE go_cont.  ENDIF.
  FREE: go_top, go_bottom.
  CLEAR: gt_head, gt_item, gt_fcat1, gt_fcat2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form mstat_reason  - 3WM 판정 → '판정 (사유)'
*&---------------------------------------------------------------------*
FORM mstat_reason USING    pv_mstat TYPE ztfia00010-mstat
                  CHANGING pv_text  TYPE c.
  CASE pv_mstat.
    WHEN 'PASS'. pv_text = 'PASS (일치)'.
    WHEN 'HOLD'. pv_text = 'HOLD (단가차이)'.
    WHEN 'QREJ'. pv_text = 'QREJ (수량초과)'.
    WHEN OTHERS. pv_text = pv_mstat.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_kpi  - 처리 대기 송장 (조회 조건과 관계없이 전체 기간 기준)
*&---------------------------------------------------------------------*
FORM show_kpi .
  TYPES: BEGIN OF ty_act,
           tdnum TYPE ztexa00030-tdnum,
         END OF ty_act,
         BEGIN OF ty_ap,
           apnum TYPE ztcma00110-apnum,
         END OF ty_ap.
  DATA: lt_w    TYPE zcl_cm_kpi_html=>tt_widget,
        lt_act  TYPE TABLE OF ty_act,              " 활성 홀드 (tdnum)
        ls_act  TYPE ty_act,
        lt_ap   TYPE TABLE OF ty_ap,               " 활성 홀드 채무번호 (apnum 타입으로)
        ls_ap   TYPE ty_ap,
        lt_wait TYPE TABLE OF ty_ap,               " 통과 + 활성 홀드
        lv_hold TYPE i,
        lv_qrej TYPE i,
        lv_wait TYPE i.

  "─ 보류 / 반려: 판정값으로 바로 셈
  SELECT COUNT(*) FROM ztfia00010 INTO lv_hold WHERE mstat = 'HOLD'.
  SELECT COUNT(*) FROM ztfia00010 INTO lv_qrej WHERE mstat = 'QREJ'.

  "─ 홀드 해제 대기: 활성 홀드(몇 건 안 됨)에서 출발 → 그 채무의 송장이 통과인 것
  SELECT tdnum FROM ztexa00030
    INTO TABLE lt_act
    WHERE tdtyp = 'AP'
      AND hdsta = 'ACTV'.

  LOOP AT lt_act INTO ls_act.
    ls_ap-apnum = ls_act-tdnum.
    APPEND ls_ap TO lt_ap.
  ENDLOOP.

  IF lt_ap IS NOT INITIAL.                          " 비어 있으면 FOR ALL ENTRIES가 전체를 읽음
    SELECT a~apnum
      FROM ztcma00110 AS a
      INNER JOIN ztfia00010 AS h ON h~ivnum = a~ivnum
      INTO TABLE lt_wait
      FOR ALL ENTRIES IN lt_ap
      WHERE a~apnum = lt_ap-apnum
        AND h~mstat = 'PASS'.
  ENDIF.
  lv_wait = lines( lt_wait ).

  APPEND zcl_cm_kpi_html=>w_card( iv_label = '홀드 해제 대기' iv_value = |{ lv_wait }건|
         iv_sub = 'FI 처리 완료 · CM03 해제 전' iv_color = 'N' ) TO lt_w.
   APPEND zcl_cm_kpi_html=>w_card( iv_label = '보류 HOLD'      iv_value = |{ lv_hold }건|
           iv_sub = '단가 차이 · ZFI02에서 처리'  iv_color = 'Y' ) TO lt_w.
  APPEND zcl_cm_kpi_html=>w_card( iv_label = '반려 QREJ'      iv_value = |{ lv_qrej }건|
           iv_sub = '수량 초과 · ZFI02에서 처리'  iv_color = 'R' ) TO lt_w.

  go_kpi->show_widgets( it_widget = lt_w
                        iv_title  = '처리 대기 송장 (조회 기간과 관계없이 전체 기준)' ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_budat  - 등록일 = (오늘 - n개월) ~ 오늘
*&---------------------------------------------------------------------*
FORM set_budat USING pv_months TYPE i.
  DATA: lv_months TYPE i,
        lv_from   TYPE sy-datum.

  lv_months = pv_months * -1.

  CALL FUNCTION 'MONTH_PLUS_DETERMINE'
    EXPORTING
      months  = lv_months
      olddate = sy-datum
    IMPORTING
      newdate = lv_from.

  CLEAR: s_budat, s_budat[].
  s_budat-sign   = 'I'.
  s_budat-option = 'BT'.
  s_budat-low    = lv_from.
  s_budat-high   = sy-datum.
  APPEND s_budat.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_refresh  - 같은 조회 조건으로 다시 읽기 (목록·라인·KPI)
*&---------------------------------------------------------------------*
FORM process_refresh .
  DATA lv_cnt TYPE i.
  PERFORM get_data.
  CLEAR gt_item.                                 " 라인 상세는 비우고 다시 더블클릭
  PERFORM refresh_alv1.
  PERFORM refresh_alv2.
  PERFORM show_kpi.

  lv_cnt = lines( gt_head ).
  MESSAGE s413(zmsga) WITH lv_cnt.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv1 / refresh_alv2  - 상단 / 하단 제목 + 화면 갱신
*&---------------------------------------------------------------------*
FORM refresh_alv1 .
  DATA ls_stable TYPE lvc_s_stbl.

  go_alv1->set_gridtitle( |구매송장 목록 ({ lines( gt_head ) }건)| ).

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv1->refresh_table_display( is_stable = ls_stable ).
ENDFORM.

FORM refresh_alv2 .
  DATA ls_stable TYPE lvc_s_stbl.

  go_alv2->set_gridtitle( '송장 라인 상세' ).

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv2->refresh_table_display( is_stable = ls_stable ).
ENDFORM.
