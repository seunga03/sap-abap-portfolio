*&---------------------------------------------------------------------*
*& Include          ZLFIA00040_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_object  - 위/아래 ALV (컨테이너 1개를 위아래로 나눔)
*&---------------------------------------------------------------------*
FORM create_object .
  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'CON_AREA'.

  CREATE OBJECT go_split
    EXPORTING
      parent  = go_cont
      rows    = 2
      columns = 1.
  go_split->set_row_height( id = 1 height = 50 ).
  go_top    = go_split->get_container( row = 1 column = 1 ).
  go_bottom = go_split->get_container( row = 2 column = 1 ).

  CREATE OBJECT go_alv1 EXPORTING i_parent = go_top.
  CREATE OBJECT go_alv2 EXPORTING i_parent = go_bottom.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler  - 상단 줄 더블클릭 → 하단 세부내역
*&---------------------------------------------------------------------*
FORM set_evt_handler .
  SET HANDLER: lcl_handler=>on_double_click FOR go_alv1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout
*&---------------------------------------------------------------------*
FORM set_alv_layout .
  DATA ls_sort TYPE lvc_s_sort.

  CLEAR: gs_layout1, gs_layout2, gt_sort1.

  "─ 상단: 수금 내역
  gs_layout1-zebra      = 'X'.
*  gs_layout1-no_totline = 'X'.                    " 총합계 줄 없음 (날짜+계좌 소계만) → 이제 기간 총수금액 표시

  "─ 하단: 반제 세부내역
  gs_layout2-zebra      = 'X'.
  gs_layout2-no_toolbar = 'X'.                    " 세부내역은 몇 줄뿐이라 툴바 숨김

  " 수금일(최신순) → 수금번호 최신순 (소계·합계는 툴바 Σ·소계 버튼으로)
  CLEAR ls_sort.
  ls_sort-spos      = 1.
  ls_sort-fieldname = 'RCPDT'.
  ls_sort-down      = 'X'.
*  ls_sort-subtot    = 'X'.
  APPEND ls_sort TO gt_sort1.

*  CLEAR ls_sort.                                  " 입금계좌 소계 (열을 뒤로 보내서 사용 안 함)
*  ls_sort-spos      = 2.
*  ls_sort-fieldname = 'RCPAC'.
*  ls_sort-up        = 'X'.
*  ls_sort-subtot    = 'X'.
*  APPEND ls_sort TO gt_sort1.

  CLEAR ls_sort.
  ls_sort-spos      = 2.
  ls_sort-fieldname = 'RCPNR'.
  ls_sort-down      = 'X'.
  APPEND ls_sort TO gt_sort1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog  (정렬: 글자 왼쪽 / 금액·건수 오른쪽 / 날짜·통화 가운데)
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  DATA ls TYPE lvc_s_fcat.

  CLEAR: gt_fcat1, gt_fcat2.

  "─ 상단: 수금 내역 (1줄 = 통장 입금 1건)
  "  수금일 → 수금번호 → 고객명 → 수금액 → 통화 → 채권 건수 → 고객 → 입금계좌 → 은행 → 계좌번호

  CLEAR ls.
  ls-fieldname = 'RCPDT'.  ls-coltext = '수금일'.
  ls-ref_table = 'ZTFIA00060'.  ls-just = 'C'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'RCPNR'.  ls-coltext = '수금번호'.
  ls-ref_table = 'ZTFIA00060'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'NAME1'.  ls-coltext = '고객명'.
  ls-ref_table = 'ZTCMA00050'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname  = 'RCPAM'.  ls-coltext = '수금액'.
  ls-ref_table  = 'ZTFIA00060'.  ls-cfieldname = 'WAERS'.
  ls-emphasize = 'C300'.  ls-outputlen = 8.
*  ls-do_sum     = 'X'.                           " 자동 합계 (사용 안 함 → 툴바 Σ)
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'WAERS'.  ls-coltext = '통화'.
  ls-ref_table = 'ZTFIA00060'.  ls-just = 'C'.  ls-outputlen = 2.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'ARCNT'.  ls-coltext = '채권 건수'.
  ls-inttype   = 'I'.  ls-just = 'R'.  ls-outputlen = 4.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'KUNNR'.  ls-coltext = '고객'.
  ls-ref_table = 'ZTFIA00060'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'RCPAC'.  ls-coltext = '입금계좌'.
  ls-ref_table = 'ZTFIA00060'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'BANKA'.  ls-coltext = '은행'.
  ls-ref_table = 'ZTFIA00070'.  ls-outputlen = 5.
  APPEND ls TO gt_fcat1.

  CLEAR ls.
  ls-fieldname = 'BANKN'.  ls-coltext = '계좌번호'.
  ls-ref_table = 'ZTFIA00070'.  ls-outputlen = 10.
  APPEND ls TO gt_fcat1.

  "─ 하단: 반제 세부내역
  "  채권번호 → 청구번호 → 이번 수금액 → 수금 전 잔액 → 수금 후 잔액 → 현재 잔액 → 현재 상태
  "  → 채권금액 → 통화 → 반제번호 → 순번

  CLEAR ls.
  ls-fieldname = 'ARNUM'.  ls-coltext = '채권번호'.
  ls-ref_table = 'ZTFIA00040'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'BILNO'.  ls-coltext = '청구번호'.
  ls-ref_table = 'ZTCMA00100'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname  = 'ARCAM'.  ls-coltext = '이번 수금액'.
  ls-ref_table  = 'ZTFIA00040'.  ls-cfieldname = 'WAERS'.
  ls-emphasize = 'C300'.  ls-outputlen = 8.
*  ls-do_sum     = 'X'.                           " 합계 (위 수금액과 같으므로 표시 안 함)
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname  = 'BEFBAL'.  ls-coltext = '수금 전 잔액'.
  ls-ref_table  = 'ZTCMA00100'.  ls-ref_field = 'DMBTR'.
  ls-cfieldname = 'WAERS'.  ls-outputlen = 8.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname  = 'AFTBAL'.  ls-coltext = '수금 후 잔액'.
  ls-ref_table  = 'ZTCMA00100'.  ls-ref_field = 'DMBTR'.
  ls-cfieldname = 'WAERS'.  ls-outputlen = 8.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname  = 'OPENBAL'.  ls-coltext = '현재 잔액'.
  ls-ref_table  = 'ZTCMA00100'.  ls-ref_field = 'DMBTR'.
  ls-cfieldname = 'WAERS'.  ls-outputlen = 8.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'STTXT'.  ls-coltext = '현재 상태'.
  ls-inttype   = 'C'.  ls-intlen = 10.  ls-outputlen = 5.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname  = 'DMBTR'.  ls-coltext = '채권금액'.
  ls-ref_table  = 'ZTCMA00100'.  ls-cfieldname = 'WAERS'.  ls-outputlen = 8.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'WAERS'.  ls-coltext = '통화'.
  ls-ref_table = 'ZTFIA00040'.  ls-just = 'C'.  ls-outputlen = 2.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'ARCNR'.  ls-coltext = '반제번호'.
  ls-ref_table = 'ZTFIA00040'.  ls-outputlen = 7.
  APPEND ls TO gt_fcat2.

  CLEAR ls.
  ls-fieldname = 'ARCSQ'.  ls-coltext = '순번'.
  ls-ref_table = 'ZTFIA00040'.  ls-just = 'C'.  ls-outputlen = 3.
  APPEND ls TO gt_fcat2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv  - 상단은 시작부터 최근 10건, 하단은 빈 표
*&---------------------------------------------------------------------*
FORM display_alv .

*── 상단: 수금 내역
  CALL METHOD go_alv1->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout1
    CHANGING
      it_outtab                     = gt_head
      it_fieldcatalog               = gt_fcat1
      it_sort                       = gt_sort1
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a067(zmsga) WITH '화면 표시'.         " 화면 표시 처리 중 오류가 발생했습니다
  ENDIF.

*── 하단: 반제 세부내역
  CALL METHOD go_alv2->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout2
    CHANGING
      it_outtab                     = gt_item
      it_fieldcatalog               = gt_fcat2
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a067(zmsga) WITH '화면 표시'.         " 화면 표시 처리 중 오류가 발생했습니다
  ENDIF.

  PERFORM refresh_alv1.                           " 제목 붙이기
  PERFORM refresh_alv2.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data  - 조건 없으면 최근 10건, 있으면 전부
*&---------------------------------------------------------------------*
FORM get_data .
  TYPES: BEGIN OF lty_arc,
           arcnr TYPE ztfia00040-arcnr,
           arcsq TYPE ztfia00040-arcsq,
           rcpnr TYPE ztfia00040-rcpnr,
         END OF lty_arc,
         BEGIN OF lty_bank,
           bnkac TYPE ztfia00070-bnkac,
           banka TYPE ztfia00070-banka,
           bankn TYPE ztfia00070-bankn,
         END OF lty_bank,
         BEGIN OF lty_name,
           kunnr TYPE ztcma00050-kunnr,
           name1 TYPE ztcma00050-name1,
         END OF lty_name.
  DATA: lr_rcpac TYPE RANGE OF ztfia00060-rcpac,
        ls_rcpac LIKE LINE OF lr_rcpac,
        lr_kunnr TYPE RANGE OF ztfia00060-kunnr,
        ls_kunnr LIKE LINE OF lr_kunnr,
        lt_rcp   TYPE TABLE OF ztfia00060,
        ls_rcp   TYPE ztfia00060,
        lt_arc   TYPE SORTED TABLE OF lty_arc WITH NON-UNIQUE KEY rcpnr,
        lt_bank  TYPE SORTED TABLE OF lty_bank WITH UNIQUE KEY bnkac,
        ls_bank  TYPE lty_bank,
        lt_name  TYPE STANDARD TABLE OF lty_name,
        ls_name  TYPE lty_name.

  CLEAR: gt_head, gv_recent.

  IF p_rcpac IS NOT INITIAL.
    ls_rcpac-sign   = 'I'.
    ls_rcpac-option = 'EQ'.
    ls_rcpac-low    = p_rcpac.
    APPEND ls_rcpac TO lr_rcpac.
  ENDIF.

  IF p_kunnr IS NOT INITIAL.
    ls_kunnr-sign   = 'I'.
    ls_kunnr-option = 'EQ'.
    ls_kunnr-low    = p_kunnr.
    APPEND ls_kunnr TO lr_kunnr.
  ENDIF.

  IF s_rcpdt[] IS INITIAL AND p_kunnr IS INITIAL
     AND s_rcpnr[] IS INITIAL AND p_rcpac IS INITIAL.
    gv_recent = 'X'.
    SELECT * FROM ztfia00060 INTO TABLE lt_rcp
      UP TO 10 ROWS
      ORDER BY rcpdt DESCENDING rcpnr DESCENDING.
  ELSE.
    SELECT * FROM ztfia00060 INTO TABLE lt_rcp
      WHERE rcpdt IN s_rcpdt
        AND kunnr IN lr_kunnr
        AND rcpnr IN s_rcpnr
        AND rcpac IN lr_rcpac
      ORDER BY rcpdt DESCENDING rcpnr DESCENDING.
  ENDIF.

  " 은행·고객명·채권 건수를 한 번에 (루프 안 SELECT 없음)
  IF lt_rcp IS NOT INITIAL.
    SELECT bnkac banka bankn FROM ztfia00070
      INTO TABLE lt_bank
      FOR ALL ENTRIES IN lt_rcp
      WHERE bnkac = lt_rcp-rcpac.

    SELECT kunnr name1 FROM ztcma00050
      INTO TABLE lt_name
      FOR ALL ENTRIES IN lt_rcp
      WHERE kunnr = lt_rcp-kunnr.
    SORT lt_name BY kunnr.
    DELETE ADJACENT DUPLICATES FROM lt_name COMPARING kunnr.   " 배송처가 여러 개여도 고객당 1줄

    SELECT arcnr arcsq rcpnr FROM ztfia00040
      INTO TABLE lt_arc
      FOR ALL ENTRIES IN lt_rcp
      WHERE rcpnr = lt_rcp-rcpnr.
  ENDIF.

  LOOP AT lt_rcp INTO ls_rcp.
    CLEAR gw_head.
    MOVE-CORRESPONDING ls_rcp TO gw_head.       " rcpnr kunnr rcpdt rcpam waers rcpac

    READ TABLE lt_name INTO ls_name WITH KEY kunnr = ls_rcp-kunnr BINARY SEARCH.
    IF sy-subrc = 0.
      gw_head-name1 = ls_name-name1.
    ENDIF.

    READ TABLE lt_bank INTO ls_bank WITH TABLE KEY bnkac = ls_rcp-rcpac.
    IF sy-subrc = 0.
      gw_head-banka = ls_bank-banka.
      gw_head-bankn = ls_bank-bankn.
    ENDIF.

    LOOP AT lt_arc TRANSPORTING NO FIELDS WHERE rcpnr = ls_rcp-rcpnr.
      gw_head-arcnt = gw_head-arcnt + 1.
    ENDLOOP.

    APPEND gw_head TO gt_head.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_detail  - 더블클릭한 수금번호의 반제 줄
*&   채권금액 / 수금 전 잔액 / 이번 수금액 / 수금 후 잔액 (그 당시) + 현재 잔액·상태 (오늘)
*&---------------------------------------------------------------------*
FORM get_detail .
  TYPES: BEGIN OF lty_det,
           arcnr TYPE ztfia00040-arcnr,
           arcsq TYPE ztfia00040-arcsq,
           rcpnr TYPE ztfia00040-rcpnr,
           arnum TYPE ztfia00040-arnum,
           arcam TYPE ztfia00040-arcam,
           waers TYPE ztfia00040-waers,
           bilno TYPE ztcma00100-bilno,
           dmbtr TYPE ztcma00100-dmbtr,
           rcpbt TYPE ztcma00100-rcpbt,
           adjbt TYPE ztcma00100-adjbt,
           clsta TYPE ztcma00100-clsta,
         END OF lty_det,
         BEGIN OF lty_hist,
           arcnr TYPE ztfia00040-arcnr,
           arcsq TYPE ztfia00040-arcsq,
           arnum TYPE ztfia00040-arnum,
           arcam TYPE ztfia00040-arcam,
         END OF lty_hist.
  DATA: lt_det  TYPE TABLE OF lty_det,
        ls_det  TYPE lty_det,
        lt_hist TYPE SORTED TABLE OF lty_hist WITH NON-UNIQUE KEY arnum,
        ls_hist TYPE lty_hist,
        lv_prev TYPE ztcma00100-dmbtr.

  CLEAR gt_item.

  " 1) 반제 줄 + 채권 정보 (JOIN 한 번)
  SELECT a~arcnr a~arcsq a~rcpnr a~arnum a~arcam a~waers
         b~bilno b~dmbtr b~rcpbt b~adjbt b~clsta
    FROM ztfia00040 AS a
    LEFT OUTER JOIN ztcma00100 AS b
      ON b~arnum = a~arnum
    INTO TABLE lt_det
    WHERE a~rcpnr = gw_head-rcpnr
    ORDER BY a~arcnr a~arcsq.

  " 2) 그 채권들의 반제 이력 전체 (수금 + 조정) → 그 당시 잔액 계산용
  IF lt_det IS NOT INITIAL.
    SELECT arcnr arcsq arnum arcam FROM ztfia00040
      INTO TABLE lt_hist
      FOR ALL ENTRIES IN lt_det
      WHERE arnum = lt_det-arnum.
  ENDIF.

  LOOP AT lt_det INTO ls_det.
    CLEAR: gw_item, lv_prev.
    gw_item-rcpnr = ls_det-rcpnr.
    gw_item-arcnr = ls_det-arcnr.
    gw_item-arcsq = ls_det-arcsq.
    gw_item-arnum = ls_det-arnum.
    gw_item-arcam = ls_det-arcam.
    gw_item-waers = ls_det-waers.
    gw_item-bilno = ls_det-bilno.
    gw_item-dmbtr = ls_det-dmbtr.
    gw_item-clsta = ls_det-clsta.

    " 이 반제보다 앞선 반제(수금·조정) 합계
    LOOP AT lt_hist INTO ls_hist WHERE arnum = ls_det-arnum.
      IF ls_hist-arcnr < ls_det-arcnr
         OR ( ls_hist-arcnr = ls_det-arcnr AND ls_hist-arcsq < ls_det-arcsq ).
        lv_prev = lv_prev + ls_hist-arcam.
      ENDIF.
    ENDLOOP.

    gw_item-befbal  = ls_det-dmbtr - lv_prev.                         " 수금 전 잔액 (그 당시)
    gw_item-aftbal  = gw_item-befbal - ls_det-arcam.                  " 수금 후 잔액 (그 당시)
    gw_item-openbal = ls_det-dmbtr - ls_det-rcpbt - ls_det-adjbt.     " 현재 잔액 (오늘, 이후 수금·조정 포함)

    CASE gw_item-clsta.
      WHEN gc_clsta_open. gw_item-sttxt = '미수'.
      WHEN gc_clsta_part. gw_item-sttxt = '부분수금'.
      WHEN gc_clsta_done. gw_item-sttxt = '수금완료'.
    ENDCASE.

    APPEND gw_item TO gt_item.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_search  - [조회]
*&---------------------------------------------------------------------*
FORM process_search .
  DATA lv_cnt TYPE i.

  PERFORM get_data.
  CLEAR gt_item.                                  " 아래는 비우고 다시 더블클릭
  PERFORM refresh_alv1.
  PERFORM refresh_alv2.

  lv_cnt = lines( gt_head ).

  IF gt_head IS INITIAL.
    MESSAGE s041(zmsga) DISPLAY LIKE 'W'.         " 조건에 해당하는 데이터가 없습니다.
  ELSEIF gv_recent = 'X'.
    MESSAGE s400(zmsga) WITH '수금' lv_cnt.       " 최근 수금 n건을 조회했습니다.
  ELSE.
    MESSAGE s056(zmsga) WITH lv_cnt.              " 전체 n건이 조회되었습니다.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form process_reset  - [초기화] 조건 지우고 최근 10건
*&---------------------------------------------------------------------*
FORM process_reset .
  CLEAR: s_rcpdt, s_rcpdt[], s_rcpnr, s_rcpnr[],
         p_rcpac, p_kunnr.

  PERFORM process_search.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form refresh_alv1 / refresh_alv2  - 상단 / 하단 제목 + 화면 갱신
*&---------------------------------------------------------------------*
FORM refresh_alv1 .
  DATA: ls_stable TYPE lvc_s_stbl,
        lv_title  TYPE lvc_title,
        lv_cnt    TYPE i.

  lv_cnt = lines( gt_head ).
  IF gv_recent = 'X'.
    lv_title = |수금 내역 (최근 { lv_cnt }건)|.
  ELSE.
    lv_title = |수금 내역 ({ lv_cnt }건)|.
  ENDIF.
  go_alv1->set_gridtitle( lv_title ).

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv1->refresh_table_display( is_stable = ls_stable ).
ENDFORM.

*&---------------------------------------------------------------------*
*& Form refresh_alv2  - 하단 제목 + 화면 갱신 + 위/아래 비율
*&---------------------------------------------------------------------*
FORM refresh_alv2 .
  DATA: ls_stable TYPE lvc_s_stbl,
        lv_title  TYPE lvc_title,
        lv_cnt    TYPE i.

  IF gt_item IS INITIAL.
    lv_title = '수금 세부내역 (위 수금 건 더블클릭 시 상세 조회)'.
    go_split->set_row_height( id = 1 height = 70 ).   " 내역 없음 → 위 수금 내역 크게
  ELSE.
    lv_cnt   = lines( gt_item ).
    lv_title = |수금 세부내역 - { gw_head-rcpnr } / { gw_head-name1 } ({ lv_cnt }건)|.
    go_split->set_row_height( id = 1 height = 50 ).   " 더블클릭 → 위 60 : 아래 40
  ENDIF.
  go_alv2->set_gridtitle( lv_title ).

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  go_alv2->refresh_table_display( is_stable = ls_stable ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f4_rcpac  - 입금계좌 F4 (00050과 같음)
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
*& Form f4_kunnr  - 고객 F4 (번호 + 고객명, 배송처 중복 제거) — 00050과 같음
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
*& Form set_kunnr_text  - 고객 번호 옆 고객명 — 00050과 같음
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
*& Form set_bank_text  - 입금계좌 옆 은행명 + 계좌번호 — 00050과 같음
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
*& Form set_period  - 기간 버튼: 수금일 = (오늘 - n개월) ~ 오늘 → 바로 조회
*&---------------------------------------------------------------------*
FORM set_period USING pv_months TYPE i.
  DATA: lv_months TYPE i,
        lv_from   TYPE sy-datum.

  lv_months = pv_months * -1.

  CALL FUNCTION 'MONTH_PLUS_DETERMINE'
    EXPORTING
      months  = lv_months
      olddate = sy-datum
    IMPORTING
      newdate = lv_from.

  CLEAR: s_rcpdt, s_rcpdt[].
  s_rcpdt-sign   = 'I'.
  s_rcpdt-option = 'BT'.
  s_rcpdt-low    = lv_from.
  s_rcpdt-high   = sy-datum.
  APPEND s_rcpdt.

  PERFORM process_search.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form confirm_exit  - Back·Exit·Cancel → 종료 확인 팝업 (조회 프로그램)
*&---------------------------------------------------------------------*
FORM confirm_exit .
  DATA lv_answer TYPE c LENGTH 1.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '종료 확인'
      text_question         = '프로그램을 종료하시겠습니까?'
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
