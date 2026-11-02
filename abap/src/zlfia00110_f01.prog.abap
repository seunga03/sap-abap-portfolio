*&---------------------------------------------------------------------*
*& Include          ZLFIA00110_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& get_data : CDS 2개 읽기
*&---------------------------------------------------------------------*
FORM get_data.
  TYPES: BEGIN OF lty_cds_sum,
           dtype   TYPE c LENGTH 2,
           bucket  TYPE c LENGTH 1,
           waers   TYPE waers,
           openbal TYPE dmbtr,
           doccnt  TYPE i,
         END OF lty_cds_sum.
  DATA: lt_cds   TYPE STANDARD TABLE OF lty_cds_sum,
        ls_cds   TYPE lty_cds_sum,
        ls_tot   TYPE ty_sum,
        lv_waers TYPE waers,
        lv_tabix TYPE sy-tabix.

  CLEAR: gt_all, gt_sum, gv_bucket.

  " 1) 건별 : ZV_FI_OPEN_AGING (기준일 파라미터)
  SELECT dtype, docno, refno, partner, name1, duedt, waers,
         dmbtr, clrbt, adjbt, openbal, ovdays, bucket
    FROM zv_fi_open_aging( p_keydt = @p_keydt )
    INTO CORRESPONDING FIELDS OF TABLE @gt_all.

  LOOP AT gt_all INTO gw_item.
    PERFORM bucket_text USING gw_item-bucket CHANGING gw_item-bktxt.

    IF gw_item-dtype = 'AP'.
      gw_item-dttxt = '채무'.
    ELSE.
      gw_item-dttxt = '채권'.
    ENDIF.

    CASE gw_item-bucket.
      WHEN '1'. gw_item-stico = icon_led_red.        " 연체 = 빨강
      WHEN '2'. gw_item-stico = icon_led_yellow.     " 7일 이내 = 노랑
      WHEN OTHERS. gw_item-stico = icon_led_green.   " 여유 = 초록
    ENDCASE.

    " 연체일 → 글자 (마이너스 대신 '남음')
    IF gw_item-ovdays > 0.
      gw_item-ovtxt = |연체 { gw_item-ovdays }일|.
    ELSEIF gw_item-ovdays = 0.
      gw_item-ovtxt = '오늘 기한'.
    ELSE.
      gw_item-ovtxt = |{ abs( gw_item-ovdays ) }일 남음|.
    ENDIF.

    MODIFY gt_all FROM gw_item.
    lv_waers = gw_item-waers.
  ENDLOOP.

  PERFORM build_item.

  " 2) 구간별 합계 : ZV_FI_OPEN_SUM → 구간 1~4 를 채무/채권 옆으로 펼침
  SELECT dtype, bucket, waers, openbal, doccnt
    FROM zv_fi_open_sum( p_keydt = @p_keydt )
    INTO TABLE @lt_cds.

  DO 4 TIMES.
    CLEAR gw_sum.
    gw_sum-bucket = sy-index.
    gw_sum-waers  = lv_waers.
    PERFORM bucket_text USING gw_sum-bucket CHANGING gw_sum-bktxt.
    APPEND gw_sum TO gt_sum.
  ENDDO.

  LOOP AT lt_cds INTO ls_cds WHERE bucket <> '0'.
    READ TABLE gt_sum INTO gw_sum WITH KEY bucket = ls_cds-bucket.
    CHECK sy-subrc = 0.
    lv_tabix = sy-tabix.

    gw_sum-waers = ls_cds-waers.
    IF ls_cds-dtype = 'AP'.
      gw_sum-apbal = ls_cds-openbal.
      gw_sum-apcnt = ls_cds-doccnt.
    ELSE.
      gw_sum-arbal = ls_cds-openbal.
      gw_sum-arcnt = ls_cds-doccnt.
    ENDIF.
    gw_sum-netbal = gw_sum-arbal - gw_sum-apbal.

    MODIFY gt_sum FROM gw_sum INDEX lv_tabix.
  ENDLOOP.

  " 합계 줄 (ALV 자동 합계 대신 직접 만듦 → 순액까지 합계 표시)
  LOOP AT gt_sum INTO gw_sum.
    ls_tot-apcnt = ls_tot-apcnt + gw_sum-apcnt.
    ls_tot-apbal = ls_tot-apbal + gw_sum-apbal.
    ls_tot-arcnt = ls_tot-arcnt + gw_sum-arcnt.
    ls_tot-arbal = ls_tot-arbal + gw_sum-arbal.
  ENDLOOP.
  ls_tot-bucket = 'T'.
  ls_tot-bktxt  = '합계'.
  ls_tot-waers  = lv_waers.
  ls_tot-netbal = ls_tot-arbal - ls_tot-apbal.
  ls_tot-rowcol = 'C310'.                   " 노란 줄
  APPEND ls_tot TO gt_sum.

  " 순액 → 글자 (+ / - 를 앞에)
  LOOP AT gt_sum INTO gw_sum.
    PERFORM sign_amt USING gw_sum-netbal gw_sum-waers CHANGING gw_sum-nettxt.
    MODIFY gt_sum FROM gw_sum.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& build_item : 아래 목록 (완결 제외 + 구분 라디오버튼)
*&---------------------------------------------------------------------*
FORM build_item.
  CLEAR gt_item.

  LOOP AT gt_all INTO gw_item WHERE bucket <> '0'.
    IF r_ap = 'X' AND gw_item-dtype <> 'AP'.
      CONTINUE.
    ENDIF.
    IF r_ar = 'X' AND gw_item-dtype <> 'AR'.
      CONTINUE.
    ENDIF.
    APPEND gw_item TO gt_item.
  ENDLOOP.

  SORT gt_item BY bucket duedt dtype docno.
  gv_cnt = lines( gt_item ).
ENDFORM.

*&---------------------------------------------------------------------*
*& bucket_text : 구간 코드 → 이름
*&---------------------------------------------------------------------*
FORM bucket_text USING pv_bucket TYPE c
                 CHANGING pv_text TYPE c.
  CASE pv_bucket.
    WHEN '0'. pv_text = '완결'.
    WHEN '1'. pv_text = '연체'.
    WHEN '2'. pv_text = '7일 이내'.
    WHEN '3'. pv_text = '30일 이내'.
    WHEN '4'. pv_text = '30일 초과'.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& create_controls : CON_AREA 를 KPI / 구간 ALV / 건별 ALV 3칸으로
*&---------------------------------------------------------------------*
FORM create_controls.
  CREATE OBJECT go_con
    EXPORTING
      container_name = 'CON_AREA'.

  CREATE OBJECT go_split
    EXPORTING
      parent  = go_con
      rows    = 3
      columns = 1.

  go_c_kpi  = go_split->get_container( row = 1 column = 1 ).
  go_c_sum  = go_split->get_container( row = 2 column = 1 ).
  go_c_item = go_split->get_container( row = 3 column = 1 ).

  " 높이를 px로 고정 (1칸은 show_kpi 에서 KPI 높이에 맞춤, 3칸은 나머지)
  go_split->set_row_mode( mode = cl_gui_splitter_container=>mode_absolute ).
  go_split->set_row_height( id = 2 height = 190 ).
ENDFORM.

*&---------------------------------------------------------------------*
*& show_kpi : 카드 5개 + 반제 진행률 2개 (채무·채권 전체 합계)
*&   색 규칙 (Fiori 대시보드와 같음)
*&   미지급 채무 빨강 / 미수 채권 초록 / 순채무 빨강·순채권 초록·0 무색
*&   연체는 0건 무색, 있으면 회색 / 진행률 막대 채무 빨강·채권 초록
*&---------------------------------------------------------------------*
FORM show_kpi.
  CONSTANTS lc_none TYPE c LENGTH 1 VALUE 'W'.     " 무색 카드 (ZCL_CM_KPI_HTML .cW 흰 카드)

  DATA: lt_w     TYPE zcl_cm_kpi_html=>tt_widget,
        lv_ap    TYPE dmbtr,       " 미지급 채무 (미결 잔액)
        lv_ar    TYPE dmbtr,       " 미수 채권
        lv_net   TYPE dmbtr,       " 미수 채권 - 미지급 채무
        lv_apov  TYPE dmbtr,       " 연체 채무
        lv_arov  TYPE dmbtr,       " 연체 채권
        lv_apdm  TYPE dmbtr,       " 채무 총액
        lv_apclr TYPE dmbtr,       " 채무 반제+조정
        lv_ardm  TYPE dmbtr,
        lv_arclr TYPE dmbtr,
        lv_apcnt TYPE i,
        lv_arcnt TYPE i,
        lv_apovc TYPE i,
        lv_arovc TYPE i,
        lv_waers TYPE waers VALUE 'KRW',
        lv_v     TYPE string,
        lv_v2    TYPE string,
        lv_color TYPE c LENGTH 1,
        lv_d     TYPE decfloat34,
        lv_pct   TYPE i,
        lv_title TYPE string,
        lv_foot  TYPE string,
        lv_px    TYPE i.

  LOOP AT gt_all INTO gw_item.
    lv_waers = gw_item-waers.
    IF gw_item-dtype = 'AP'.
      lv_apdm  = lv_apdm  + gw_item-dmbtr.
      lv_apclr = lv_apclr + gw_item-clrbt + gw_item-adjbt.
      IF gw_item-bucket <> '0'.
        lv_ap    = lv_ap + gw_item-openbal.
        lv_apcnt = lv_apcnt + 1.
      ENDIF.
      IF gw_item-bucket = '1'.
        lv_apov  = lv_apov + gw_item-openbal.
        lv_apovc = lv_apovc + 1.
      ENDIF.
    ELSE.
      lv_ardm  = lv_ardm  + gw_item-dmbtr.
      lv_arclr = lv_arclr + gw_item-clrbt + gw_item-adjbt.
      IF gw_item-bucket <> '0'.
        lv_ar    = lv_ar + gw_item-openbal.
        lv_arcnt = lv_arcnt + 1.
      ENDIF.
      IF gw_item-bucket = '1'.
        lv_arov  = lv_arov + gw_item-openbal.
        lv_arovc = lv_arovc + 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
  lv_net = lv_ar - lv_ap.

  " ---- 카드 5개 ----
  PERFORM fmt_amt USING lv_ap lv_waers CHANGING lv_v.
  APPEND zcl_cm_kpi_html=>w_card( iv_label = '미지급 채무'
                                  iv_value = lv_v
                                  iv_sub   = |{ lv_apcnt }건|
                                  iv_color = 'R' ) TO lt_w.

  PERFORM fmt_amt USING lv_ar lv_waers CHANGING lv_v.
  APPEND zcl_cm_kpi_html=>w_card( iv_label = '미수 채권'
                                  iv_value = lv_v
                                  iv_sub   = |{ lv_arcnt }건|
                                  iv_color = 'G' ) TO lt_w.

  " 순액 = 미수 채권 - 미지급 채무 : 플러스 순채권 / 마이너스 순채무 / 0 순액 (금액은 양수로 표시)
  IF lv_net > 0.
    PERFORM fmt_amt USING lv_net lv_waers CHANGING lv_v.
    APPEND zcl_cm_kpi_html=>w_card( iv_label = '순채권'
                                    iv_value = lv_v
                                    iv_sub   = '미수 채권 - 미지급 채무'
                                    iv_color = 'G' ) TO lt_w.
  ELSEIF lv_net < 0.
    lv_net = abs( lv_net ).
    PERFORM fmt_amt USING lv_net lv_waers CHANGING lv_v.
    APPEND zcl_cm_kpi_html=>w_card( iv_label = '순채무'
                                    iv_value = lv_v
                                    iv_sub   = '미수 채권 - 미지급 채무'
                                    iv_color = 'R' ) TO lt_w.
  ELSE.
    PERFORM fmt_amt USING lv_net lv_waers CHANGING lv_v.
    APPEND zcl_cm_kpi_html=>w_card( iv_label = '순액'
                                    iv_value = lv_v
                                    iv_sub   = '미수 채권 - 미지급 채무'
                                    iv_color = lc_none ) TO lt_w.
  ENDIF.

  PERFORM fmt_amt USING lv_apov lv_waers CHANGING lv_v.
  IF lv_apovc > 0.
    lv_color = 'N'.                                  " 연체 있음 = 회색
  ELSE.
    lv_color = lc_none.                              " 연체 없음 = 무색
  ENDIF.
  APPEND zcl_cm_kpi_html=>w_card( iv_label = '연체 채무'
                                  iv_value = lv_v
                                  iv_sub   = |{ lv_apovc }건|
                                  iv_color = lv_color ) TO lt_w.

  PERFORM fmt_amt USING lv_arov lv_waers CHANGING lv_v.
  IF lv_arovc > 0.
    lv_color = 'N'.
  ELSE.
    lv_color = lc_none.
  ENDIF.
  APPEND zcl_cm_kpi_html=>w_card( iv_label = '연체 채권'
                                  iv_value = lv_v
                                  iv_sub   = |{ lv_arovc }건|
                                  iv_color = lv_color ) TO lt_w.

  " ---- 반제 진행률 2개 : (반제+조정) / 금액 ----
  CLEAR lv_pct.
  IF lv_apdm > 0.
    lv_d   = lv_apclr * 100 / lv_apdm.
    lv_pct = round( val = lv_d dec = 0 ).
    IF lv_pct > 100.
      lv_pct = 100.
    ENDIF.
  ENDIF.
  PERFORM fmt_amt USING lv_apclr lv_waers CHANGING lv_v.
  PERFORM fmt_amt USING lv_apdm  lv_waers CHANGING lv_v2.
  APPEND zcl_cm_kpi_html=>w_progress( iv_label = '채무 반제 진행률 (지급+조정)'
                                      iv_pct   = lv_pct
                                      iv_text  = |{ lv_v } / { lv_v2 }|
                                      iv_color = 'R' ) TO lt_w.

  CLEAR lv_pct.
  IF lv_ardm > 0.
    lv_d   = lv_arclr * 100 / lv_ardm.
    lv_pct = round( val = lv_d dec = 0 ).
    IF lv_pct > 100.
      lv_pct = 100.
    ENDIF.
  ENDIF.
  PERFORM fmt_amt USING lv_arclr lv_waers CHANGING lv_v.
  PERFORM fmt_amt USING lv_ardm  lv_waers CHANGING lv_v2.
  APPEND zcl_cm_kpi_html=>w_progress( iv_label = '채권 반제 진행률 (수금+조정)'
                                      iv_pct   = lv_pct
                                      iv_text  = |{ lv_v } / { lv_v2 }|
                                      iv_color = 'G' ) TO lt_w.

  lv_title = '채권·채무 현황 (채무·채권 전체 합계)'.
  lv_foot  = '잔액 = 금액 - 반제누계 - 조정누계 / 진행률 = (반제누계 + 조정누계) ÷ 금액'.

  " KPI 칸 높이를 내용에 맞춤
  lv_px = zcl_cm_kpi_html=>height_hint( it_widget = lt_w
                                        iv_title  = lv_title
                                        iv_foot   = lv_foot ).
  go_split->set_row_height( id = 1 height = lv_px + 100 ).  " 진행률 2줄 + 하단 설명까지

  IF go_kpi IS INITIAL.
    CREATE OBJECT go_kpi
      EXPORTING
        io_parent = go_c_kpi.
  ENDIF.
  go_kpi->show_widgets( it_widget = lt_w
                        iv_title  = lv_title
                        iv_foot   = lv_foot ).
ENDFORM.

*&---------------------------------------------------------------------*
*& fmt_amt : 금액 → KPI 카드용 짧은 글자
*&   KRW 1억 이상 '152.1억원' / 1억 미만 '89,996,999원' / 다른 통화 '1,234.56 USD'
*&   (정확한 금액은 아래 표에 있음)
*&---------------------------------------------------------------------*
FORM fmt_amt USING pv_amt   TYPE dmbtr
                   pv_waers TYPE waers
             CHANGING pv_text TYPE string.
  DATA: lv_c    TYPE c LENGTH 30,
        lv_abs  TYPE dmbtr,
        lv_dec  TYPE tcurx-currdec,
        lv_disp TYPE p LENGTH 16 DECIMALS 2,   " 실제 금액 (내부값 소수점 보정 후)
        lv_eok  TYPE p LENGTH 15 DECIMALS 1,   " 억 단위 (소수 1자리 반올림)
        lv_sign TYPE string.

  lv_abs = abs( pv_amt ).
  IF pv_amt < 0.
    lv_sign = '-'.
  ENDIF.

  " 원화 아니면 금액 그대로
  IF pv_waers <> 'KRW'.
    WRITE lv_abs TO lv_c CURRENCY pv_waers.
    CONDENSE lv_c.
    pv_text = |{ lv_sign }{ lv_c } { pv_waers }|.
    RETURN.
  ENDIF.

  " KRW 내부값 보정 : 통화 소수 자리(TCURX, KRW = 0) 만큼 곱함 → 실제 원
  SELECT SINGLE currdec FROM tcurx INTO lv_dec
    WHERE currkey = pv_waers.
  IF sy-subrc <> 0.
    lv_dec = 2.                                    " 없으면 기본 2자리 = 보정 없음
  ENDIF.
  lv_disp = lv_abs * ipow( base = 10 exp = 2 - lv_dec ).

  IF lv_disp >= 100000000.                         " 1억 이상 → 억원
    lv_eok = lv_disp / 100000000.
    WRITE lv_eok TO lv_c.
    CONDENSE lv_c.
    pv_text = |{ lv_sign }{ lv_c }억원|.
  ELSE.                                            " 1억 미만 → 원
    WRITE lv_abs TO lv_c CURRENCY pv_waers.
    CONDENSE lv_c.
    pv_text = |{ lv_sign }{ lv_c }원|.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& sign_amt : 금액 → '+1,000,000' / '-1,000,000' (표용, 부호 앞, 통화는 옆 칸)
*&---------------------------------------------------------------------*
FORM sign_amt USING pv_amt   TYPE dmbtr
                    pv_waers TYPE waers
              CHANGING pv_text TYPE c.
  DATA: lv_c   TYPE c LENGTH 30,
        lv_abs TYPE dmbtr.

  lv_abs = abs( pv_amt ).
  WRITE lv_abs TO lv_c CURRENCY pv_waers.   " KRW 100배 보정
  CONDENSE lv_c.

  IF pv_amt > 0.
    pv_text = |+{ lv_c }|.
  ELSEIF pv_amt < 0.
    pv_text = |-{ lv_c }|.
  ELSE.
    pv_text = lv_c.                         " 0
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& add_fcat : 필드 카탈로그 한 줄 (정렬: 글자 왼쪽 / 금액·건수 오른쪽 / 날짜·통화·아이콘 가운데)
*&---------------------------------------------------------------------*
FORM add_fcat USING pv_field   TYPE c
                    pv_text    TYPE c
                    pv_reftab  TYPE c
                    pv_reffld  TYPE c
                    pv_inttype TYPE c
                    pv_len     TYPE i
                    pv_cfield  TYPE c
                    pv_sum     TYPE c
                    pv_noout   TYPE c
              CHANGING ct_fcat TYPE lvc_t_fcat.
  DATA ls TYPE lvc_s_fcat.

  ls-fieldname  = pv_field.
  ls-coltext    = pv_text.
  ls-ref_table  = pv_reftab.
  ls-ref_field  = pv_reffld.
  ls-inttype    = pv_inttype.
  ls-outputlen  = pv_len.
  ls-cfieldname = pv_cfield.
  ls-do_sum     = pv_sum.
  ls-no_out     = pv_noout.

  CASE pv_field.
    WHEN 'STICO' OR 'DUEDT' OR 'WAERS' OR 'OVTXT'.
      ls-just = 'C'.                                   " 가운데
    WHEN 'DMBTR' OR 'CLRBT' OR 'ADJBT' OR 'OPENBAL'
      OR 'APCNT' OR 'APBAL' OR 'ARCNT' OR 'ARBAL' OR 'NETTXT'.
      ls-just = 'R'.                                   " 오른쪽
    WHEN OTHERS.
      ls-just = 'L'.                                   " 왼쪽
  ENDCASE.

  APPEND ls TO ct_fcat.
ENDFORM.

*&---------------------------------------------------------------------*
*& display_alv1 : 만기 구간별 (합계 줄은 get_data 에서 직접 만듦)
*&---------------------------------------------------------------------*
FORM display_alv1.
  DATA: lt_fcat TYPE lvc_t_fcat,
        ls_layo TYPE lvc_s_layo.

  PERFORM add_fcat USING 'BKTXT'  '만기 구간'        ''           ''      'C' 8 ''      '' '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'APCNT'  '채무 건수'        ''           ''      'I' 4 ''      '' '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'APBAL'  '미지급 채무'      'ZTCMA00110' 'DMBTR' ''  8 'WAERS' '' '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'ARCNT'  '채권 건수'        ''           ''      'I' 4 ''      '' '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'ARBAL'  '미수 채권'        'ZTCMA00110' 'DMBTR' ''  8 'WAERS' '' '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'NETTXT' '순액 (채권-채무)' ''           ''      'C' 9 ''      '' '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'WAERS'  '통화'             'ZTCMA00110' 'WAERS' ''  3 ''      '' '' CHANGING lt_fcat.

  ls_layo-zebra      = 'X'.
  ls_layo-no_toolbar = 'X'.
  ls_layo-info_fname = 'ROWCOL'.            " 합계 줄 노란색
  ls_layo-grid_title = '만기 구간별 금액 (더블클릭 시 상세 조회)'.

  CREATE OBJECT go_alv1
    EXPORTING
      i_parent = go_c_sum.

  SET HANDLER lcl_handler=>on_dblclick FOR go_alv1.

  go_alv1->set_table_for_first_display(
    EXPORTING
      is_layout       = ls_layo
    CHANGING
      it_outtab       = gt_sum
      it_fieldcatalog = lt_fcat ).
ENDFORM.

*&---------------------------------------------------------------------*
*& display_alv2 : 건별 상세
*&---------------------------------------------------------------------*
FORM display_alv2.
  DATA: lt_fcat TYPE lvc_t_fcat,
        ls_fcat TYPE lvc_s_fcat,
        ls_layo TYPE lvc_s_layo.

  PERFORM add_fcat USING 'STICO'   '상태'           ''           ''      'C' 2 ''      ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'DTTXT'   '구분'           ''           ''      'C' 3 ''      ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'DOCNO'   '채무·채권번호'  ''           ''      'C' 6 ''      ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'REFNO'   '송장·청구번호'  ''           ''      'C' 6 ''      ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'PARTNER' '거래처'         ''           ''      'C' 5 ''      ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'NAME1'   '거래처명'       'ZTCMA00010' 'NAME1' ''  8 ''      ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'DUEDT'   '기한'           'ZTCMA00110' 'DUEDT' ''  5 ''      ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'DMBTR'   '금액'           'ZTCMA00110' 'DMBTR' ''  6 'WAERS' ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'CLRBT'   '반제누계'       'ZTCMA00110' 'DMBTR' ''  6 'WAERS' ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'ADJBT'   '조정누계'       'ZTCMA00110' 'DMBTR' ''  5 'WAERS' ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'OPENBAL' '잔액'           'ZTCMA00110' 'DMBTR' ''  8 'WAERS' 'X' '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'WAERS'   '통화'           'ZTCMA00110' 'WAERS' ''  3 ''      ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'OVTXT'   '연체·남은 일수' ''           ''      'C' 6 ''      ''  '' CHANGING lt_fcat.
  PERFORM add_fcat USING 'BKTXT'   '만기 구간'      ''           ''      'C' 5 ''      ''  '' CHANGING lt_fcat.

  " 신호등 칸은 아이콘으로 표시
  ls_fcat-icon = 'X'.
  MODIFY lt_fcat FROM ls_fcat TRANSPORTING icon WHERE fieldname = 'STICO'.

  ls_layo-zebra = 'X'.

  CREATE OBJECT go_alv2
    EXPORTING
      i_parent = go_c_item.

  go_alv2->set_table_for_first_display(
    EXPORTING
      is_layout       = ls_layo
    CHANGING
      it_outtab       = gt_item
      it_fieldcatalog = lt_fcat ).

  PERFORM refresh_alv2.      " 제목(건수) 세팅
ENDFORM.

*&---------------------------------------------------------------------*
*& refresh_alv2 : 구간 거르기(gv_bucket) + 제목 + 새로 그림
*&---------------------------------------------------------------------*
FORM refresh_alv2.
  DATA: lt_filt  TYPE lvc_t_filt,
        ls_filt  TYPE lvc_s_filt,
        ls_stbl  TYPE lvc_s_stbl,
        lv_bktxt TYPE c LENGTH 20,
        lv_cnt   TYPE i,
        lv_title TYPE lvc_title.

  IF gv_bucket IS INITIAL.
    lv_cnt   = lines( gt_item ).
    lv_title = |채권·채무 건별 상세 ({ lv_cnt }건)|.
  ELSE.
    PERFORM bucket_text USING gv_bucket CHANGING lv_bktxt.
    LOOP AT gt_item TRANSPORTING NO FIELDS WHERE bucket = gv_bucket.
      lv_cnt = lv_cnt + 1.
    ENDLOOP.
    lv_title = |채권·채무 건별 상세 - { lv_bktxt } ({ lv_cnt }건)|.

    ls_filt-fieldname = 'BKTXT'.
    ls_filt-sign      = 'I'.
    ls_filt-option    = 'EQ'.
    ls_filt-low       = lv_bktxt.
    APPEND ls_filt TO lt_filt.
  ENDIF.

  go_alv2->set_filter_criteria( it_filter = lt_filt ).
  go_alv2->set_gridtitle( lv_title ).

  ls_stbl-row = 'X'.
  ls_stbl-col = 'X'.
  go_alv2->refresh_table_display( is_stable = ls_stbl ).
ENDFORM.

*&---------------------------------------------------------------------*
*& filter_bucket : 위 ALV 더블클릭한 구간으로 아래 ALV 거르기 (합계 줄 = 전체)
*&---------------------------------------------------------------------*
FORM filter_bucket USING pv_index TYPE lvc_s_row-index.
  READ TABLE gt_sum INTO gw_sum INDEX pv_index.
  CHECK sy-subrc = 0.

  IF gw_sum-bucket = 'T'.                   " 합계 줄 → 전체 구간
    CLEAR gv_bucket.
  ELSE.
    gv_bucket = gw_sum-bucket.
  ENDIF.
  PERFORM refresh_alv2.
ENDFORM.

*&---------------------------------------------------------------------*
*& process_search : 툴바 [조회] → 위 조건으로 다시 조회
*&---------------------------------------------------------------------*
FORM process_search.
  DATA ls_stbl TYPE lvc_s_stbl.

  IF p_keydt IS INITIAL.
    MESSAGE s020(zmsga) WITH '기준일' DISPLAY LIKE 'E'.   " 기준일을(를) 입력해 주십시오
    RETURN.
  ENDIF.

  IF p_keydt < sy-datum.                    " 과거 날짜 막기 (잔액이 지금 기준이라 과거 재현 불가)
    MESSAGE s433(zmsga) DISPLAY LIKE 'E'.   " 기준일은 오늘 이후 날짜만 입력할 수 있습니다.
    p_keydt = sy-datum.                     " 오늘로 되돌림
    RETURN.
  ENDIF.

  PERFORM get_data.
  PERFORM show_kpi.

  ls_stbl-row = 'X'.
  ls_stbl-col = 'X'.
  go_alv1->refresh_table_display( is_stable = ls_stbl ).
  PERFORM refresh_alv2.

  IF gv_cnt = 0.
    MESSAGE s041(zmsga) DISPLAY LIKE 'W'.   " 조건에 해당하는 데이터가 없습니다
  ELSE.
    MESSAGE s056(zmsga) WITH gv_cnt.        " 전체 n건이 조회되었습니다
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& process_reset : 툴바 [초기화] → 기준일 오늘, 구분 전체로 돌리고 다시 조회
*&---------------------------------------------------------------------*
FORM process_reset.
  p_keydt = sy-datum.
  r_all   = 'X'.
  CLEAR: r_ap, r_ar.

  PERFORM process_search.
ENDFORM.

*&---------------------------------------------------------------------*
*& free_controls : 화면 나갈 때 컨트롤 정리
*&---------------------------------------------------------------------*
FORM free_controls.
  IF go_kpi IS NOT INITIAL.
    go_kpi->free( ).
  ENDIF.
  IF go_alv1 IS NOT INITIAL.
    go_alv1->free( ).
  ENDIF.
  IF go_alv2 IS NOT INITIAL.
    go_alv2->free( ).
  ENDIF.
  IF go_split IS NOT INITIAL.
    go_split->free( ).
  ENDIF.
  IF go_con IS NOT INITIAL.
    go_con->free( ).
  ENDIF.

  CLEAR: go_kpi, go_alv1, go_alv2, go_c_kpi, go_c_sum, go_c_item,
         go_split, go_con, gv_bucket.
ENDFORM.
