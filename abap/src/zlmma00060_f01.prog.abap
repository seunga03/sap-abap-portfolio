**&---------------------------------------------------------------------*
**& Include          ZLMMA00060_F01
**&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Report  ZRMMA00060
*& 공급업체 평가 배치
*&---------------------------------------------------------------------*


*&---------------------------------------------------------------------*
*& Form zz_get_data
*& 최근 3개월 평가 원천 데이터 조회
*&---------------------------------------------------------------------*
FORM zz_get_data .

  DATA(lv_hist_from) = p_from.

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = p_from
      days      = 0
      months    = 2
      years     = 0
      signum    = '-'
    IMPORTING
      calc_date = lv_hist_from.

  lv_hist_from+6(2) = '01'.

  REFRESH: gt_lifnr,
           gt_po_head,
           gt_po_item,
           gt_gr_item,
           gt_move_head,
           gt_integrity,
           gt_inspection_head,
           gt_inspection_item.

  " 거래 가능 업체
  SELECT lifnr
    FROM ztcma00010
    INTO CORRESPONDING FIELDS OF TABLE @gt_lifnr
    WHERE trdyn = 'Y'.

  IF gt_lifnr IS INITIAL.
    MESSAGE s130 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 거래 가능 업체의 PO 헤더
  SELECT ebeln, lifnr, bedat, bukrs, ekorg, ekgrp
    FROM ztmma00050
    INTO CORRESPONDING FIELDS OF TABLE @gt_po_head
    FOR ALL ENTRIES IN @gt_lifnr
    WHERE lifnr = @gt_lifnr-lifnr.

  IF gt_po_head IS INITIAL.
    MESSAGE s130 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT gt_po_head BY ebeln.

  " PO 아이템
  SELECT ebeln, ebelp, matnr, werks, lgort,
         menge, meins, netpr, waers, eindt, ptype
    FROM ztmma00060
    INTO CORRESPONDING FIELDS OF TABLE @gt_po_item
    FOR ALL ENTRIES IN @gt_po_head
    WHERE ebeln = @gt_po_head-ebeln.

  IF gt_po_item IS INITIAL.
    MESSAGE s130 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT gt_po_item BY ebeln ebelp.

  " PO 아이템 기준 101 입고
  SELECT mblnr, mjahr, zeile, ebeln, ebelp,
         matnr, werks, lgort, menge, meins, bwart
    FROM ztmma00090
    INTO CORRESPONDING FIELDS OF TABLE @gt_gr_item
    FOR ALL ENTRIES IN @gt_po_item
    WHERE ebeln = @gt_po_item-ebeln
      AND ebelp = @gt_po_item-ebelp
      AND bwart = '101'.

  IF gt_gr_item IS INITIAL.
    MESSAGE s131 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 최근 3개월 입고 헤더만 조회
  SELECT mblnr, mjahr, budat
    FROM ztmma00080
    INTO CORRESPONDING FIELDS OF TABLE @gt_move_head
    FOR ALL ENTRIES IN @gt_gr_item
    WHERE mblnr = @gt_gr_item-mblnr
      AND mjahr = @gt_gr_item-mjahr
      AND budat BETWEEN @lv_hist_from AND @p_to.

  IF gt_move_head IS INITIAL.
    MESSAGE s132 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT gt_move_head BY mblnr mjahr.

  " 기간 밖의 101 입고 아이템 제거
  LOOP AT gt_gr_item ASSIGNING FIELD-SYMBOL(<ls_gr_item>).

    READ TABLE gt_move_head TRANSPORTING NO FIELDS
      WITH KEY mblnr = <ls_gr_item>-mblnr
               mjahr = <ls_gr_item>-mjahr
      BINARY SEARCH.

    IF sy-subrc <> 0.
      DELETE gt_gr_item.
    ENDIF.

  ENDLOOP.

  IF gt_gr_item IS INITIAL.
    MESSAGE s132 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT gt_gr_item BY mblnr mjahr zeile.

  " 외주 정합성 확정 건
  SELECT cevno, ebeln, ebelp, matnr, werks,
         lgort, pliss, aciss, pluse, acuse,
         meins, rcsts, cfdat, cfusr, znote
    FROM ztmma00110
    INTO CORRESPONDING FIELDS OF TABLE @gt_integrity
    FOR ALL ENTRIES IN @gt_po_item
    WHERE ebeln = @gt_po_item-ebeln
      AND ebelp = @gt_po_item-ebelp
      AND cfdat BETWEEN @lv_hist_from AND @p_to.

  " 입고 기준 품질검사 헤더
  SELECT inspn, mblnr, mjahr, insdt
    FROM ztmma00120
    INTO CORRESPONDING FIELDS OF TABLE @gt_inspection_head
    FOR ALL ENTRIES IN @gt_gr_item
    WHERE mblnr = @gt_gr_item-mblnr
      AND mjahr = @gt_gr_item-mjahr.

  IF gt_inspection_head IS NOT INITIAL.

    SORT gt_inspection_head BY inspn.

    SELECT inspn, inspp, gritm, matnr, insqt,
           pasqt, faiqt, meins, defcd, deftx
      FROM ztmma00130
      INTO CORRESPONDING FIELDS OF TABLE @gt_inspection_item
      FOR ALL ENTRIES IN @gt_inspection_head
      WHERE inspn = @gt_inspection_head-inspn.

  ENDIF.

  " 이번 달 101 입고가 있는 업체만 평가 대상
  PERFORM zz_set_target_vendor.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_set_target_vendor
*& 이번 달 입고가 있는 업체만 최종 평가 대상으로 전환
*&---------------------------------------------------------------------*
FORM zz_set_target_vendor .

  DATA lt_lifnr LIKE gt_lifnr.

  LOOP AT gt_gr_item ASSIGNING FIELD-SYMBOL(<ls_gr_item>).

    READ TABLE gt_po_head ASSIGNING FIELD-SYMBOL(<ls_po_head>)
      WITH KEY ebeln = <ls_gr_item>-ebeln
      BINARY SEARCH.
    CHECK sy-subrc = 0.

    READ TABLE gt_move_head ASSIGNING FIELD-SYMBOL(<ls_move_head>)
      WITH KEY mblnr = <ls_gr_item>-mblnr
               mjahr = <ls_gr_item>-mjahr
      BINARY SEARCH.
    CHECK sy-subrc = 0.

    CHECK <ls_move_head>-budat BETWEEN p_from AND p_to.

    APPEND VALUE #(
      lifnr = <ls_po_head>-lifnr
    ) TO lt_lifnr.

  ENDLOOP.

  SORT lt_lifnr BY lifnr.
  DELETE ADJACENT DUPLICATES FROM lt_lifnr COMPARING lifnr.

  gt_lifnr = lt_lifnr.

  IF gt_lifnr IS INITIAL.
    MESSAGE s133 DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_build_month_score
*& 최근 3개월 반영 비율 생성
*&---------------------------------------------------------------------*
FORM zz_build_month_score
  CHANGING ct_month TYPE ty_t_month_score.

  DATA(lv_date) = p_from.

  CLEAR ct_month.

  INSERT VALUE #(
    month  = lv_date(6)
    weight = '0.40'
  ) INTO TABLE ct_month.

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_date
      days      = 0
      months    = 1
      years     = 0
      signum    = '-'
    IMPORTING
      calc_date = lv_date.

  INSERT VALUE #(
    month  = lv_date(6)
    weight = '0.35'
  ) INTO TABLE ct_month.

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_date
      days      = 0
      months    = 1
      years     = 0
      signum    = '-'
    IMPORTING
      calc_date = lv_date.

  INSERT VALUE #(
    month  = lv_date(6)
    weight = '0.25'
  ) INTO TABLE ct_month.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_get_weighted_score
*& 월별 건수 평균에 최근 3개월 가중치 반영
*&---------------------------------------------------------------------*
FORM zz_get_weighted_score
  USING    pt_month TYPE ty_t_month_score
  CHANGING cv_score TYPE decfloat34
           cv_valid TYPE abap_bool.

  DATA(lv_weight) = CONV decfloat34( 0 ).

  CLEAR: cv_score, cv_valid.

  LOOP AT pt_month ASSIGNING FIELD-SYMBOL(<ls_month>)
    WHERE count > 0.

    cv_score += ( <ls_month>-score / <ls_month>-count )
              * <ls_month>-weight.

    lv_weight += <ls_month>-weight.

  ENDLOOP.

  IF lv_weight > 0.
    cv_score /= lv_weight.
    cv_valid = abap_true.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_calculate_dscore
*& PO 납기일과 101 입고일을 비교해 납기 점수 계산
*&---------------------------------------------------------------------*
FORM zz_calculate_dscore
  USING    pv_lifnr TYPE ztmma00050-lifnr
  CHANGING cv_score TYPE ztmma00100-dscor
           cv_valid TYPE abap_bool.

  DATA: lt_month TYPE ty_t_month_score,
        lv_score TYPE decfloat34.

  CLEAR: cv_score, cv_valid.

  PERFORM zz_build_month_score CHANGING lt_month.

  LOOP AT gt_gr_item ASSIGNING FIELD-SYMBOL(<ls_gr_item>).

    READ TABLE gt_po_item ASSIGNING FIELD-SYMBOL(<ls_po_item>)
      WITH KEY ebeln = <ls_gr_item>-ebeln
               ebelp = <ls_gr_item>-ebelp
      BINARY SEARCH.
    CHECK sy-subrc = 0.
    CHECK <ls_po_item>-eindt IS NOT INITIAL.

    READ TABLE gt_po_head ASSIGNING FIELD-SYMBOL(<ls_po_head>)
      WITH KEY ebeln = <ls_gr_item>-ebeln
      BINARY SEARCH.
    CHECK sy-subrc = 0.
    CHECK <ls_po_head>-lifnr = pv_lifnr.

    READ TABLE gt_move_head ASSIGNING FIELD-SYMBOL(<ls_move_head>)
      WITH KEY mblnr = <ls_gr_item>-mblnr
               mjahr = <ls_gr_item>-mjahr
      BINARY SEARCH.
    CHECK sy-subrc = 0.

    READ TABLE lt_month ASSIGNING FIELD-SYMBOL(<ls_month>)
      WITH TABLE KEY month = <ls_move_head>-budat(6).
    CHECK sy-subrc = 0.

    DATA(lv_delay) = <ls_move_head>-budat - <ls_po_item>-eindt.

    <ls_month>-score += COND decfloat34(
      WHEN lv_delay <= 0  THEN 100
      WHEN lv_delay <= 3  THEN 90
      WHEN lv_delay <= 7  THEN 80
      WHEN lv_delay <= 14 THEN 60
      ELSE 30
    ).

    <ls_month>-count += 1.

  ENDLOOP.

  PERFORM zz_get_weighted_score
    USING lt_month
    CHANGING lv_score
             cv_valid.

  IF cv_valid = abap_true.
    cv_score = round( val = lv_score dec = 0 ).
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_calculate_qscore
*& 검사수량 대비 합격수량으로 품질 점수 계산
*&---------------------------------------------------------------------*
FORM zz_calculate_qscore
  USING    pv_lifnr TYPE ztmma00050-lifnr
  CHANGING cv_score TYPE ztmma00100-qscor
           cv_valid TYPE abap_bool.

  DATA: lt_month TYPE ty_t_month_score,
        lv_score TYPE decfloat34.

  CLEAR: cv_score, cv_valid.

  PERFORM zz_build_month_score CHANGING lt_month.

  LOOP AT gt_inspection_item ASSIGNING FIELD-SYMBOL(<ls_insp_item>).

    CHECK <ls_insp_item>-insqt IS NOT INITIAL.

    READ TABLE gt_inspection_head ASSIGNING FIELD-SYMBOL(<ls_insp_head>)
      WITH KEY inspn = <ls_insp_item>-inspn
      BINARY SEARCH.
    CHECK sy-subrc = 0.

    READ TABLE gt_gr_item ASSIGNING FIELD-SYMBOL(<ls_gr_item>)
      WITH KEY mblnr = <ls_insp_head>-mblnr
               mjahr = <ls_insp_head>-mjahr
               zeile = <ls_insp_item>-gritm
      BINARY SEARCH.
    CHECK sy-subrc = 0.

    READ TABLE gt_po_head ASSIGNING FIELD-SYMBOL(<ls_po_head>)
      WITH KEY ebeln = <ls_gr_item>-ebeln
      BINARY SEARCH.
    CHECK sy-subrc = 0.
    CHECK <ls_po_head>-lifnr = pv_lifnr.

    READ TABLE gt_move_head ASSIGNING FIELD-SYMBOL(<ls_move_head>)
      WITH KEY mblnr = <ls_gr_item>-mblnr
               mjahr = <ls_gr_item>-mjahr
      BINARY SEARCH.
    CHECK sy-subrc = 0.

    READ TABLE lt_month ASSIGNING FIELD-SYMBOL(<ls_month>)
      WITH TABLE KEY month = <ls_move_head>-budat(6).
    CHECK sy-subrc = 0.

    <ls_month>-score += COND decfloat34(
      WHEN <ls_insp_item>-pasqt >= <ls_insp_item>-insqt
        THEN 100
      ELSE CONV decfloat34( <ls_insp_item>-pasqt )
         * 100
         / CONV decfloat34( <ls_insp_item>-insqt )
    ).

    <ls_month>-count += 1.

  ENDLOOP.

  PERFORM zz_get_weighted_score
    USING lt_month
    CHANGING lv_score
             cv_valid.

  IF cv_valid = abap_true.
    cv_score = round( val = lv_score dec = 0 ).
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_calculate_accuracy
*& 계획수량과 실제수량의 일치율을 0~100점으로 변환
*& 계획수량이 없으면 -1을 반환해 계산에서 제외
*&---------------------------------------------------------------------*
FORM zz_calculate_accuracy
  USING    pv_plan   TYPE ztmma00110-pliss
           pv_actual TYPE ztmma00110-aciss
  CHANGING cv_score  TYPE decfloat34.

  cv_score = -1.

  CHECK pv_plan > 0.

  cv_score = 100 - ( abs( pv_plan - pv_actual ) / pv_plan * 100 ).

  IF cv_score < 0.
    cv_score = 0.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_calculate_pscore
*& 계획 지급·사용량과 실제 지급·사용량으로 외주정합성 점수 계산
*& PSCOR는 약속한 외주정합성 5% 점수로 사용
*&---------------------------------------------------------------------*
FORM zz_calculate_pscore
  USING    pv_lifnr TYPE ztmma00050-lifnr
  CHANGING cv_score TYPE ztmma00100-pscor
           cv_valid TYPE abap_bool.

  DATA: lt_month TYPE ty_t_month_score,
        lv_score TYPE decfloat34,
        lv_issue TYPE decfloat34,
        lv_usage TYPE decfloat34.

  CLEAR: cv_score, cv_valid.

  PERFORM zz_build_month_score CHANGING lt_month.

  LOOP AT gt_integrity ASSIGNING FIELD-SYMBOL(<ls_integrity>).

    CHECK <ls_integrity>-cfdat IS NOT INITIAL.

    READ TABLE gt_po_head ASSIGNING FIELD-SYMBOL(<ls_po_head>)
      WITH KEY ebeln = <ls_integrity>-ebeln
      BINARY SEARCH.
    CHECK sy-subrc = 0.
    CHECK <ls_po_head>-lifnr = pv_lifnr.

    READ TABLE lt_month ASSIGNING FIELD-SYMBOL(<ls_month>)
      WITH TABLE KEY month = <ls_integrity>-cfdat(6).
    CHECK sy-subrc = 0.

    PERFORM zz_calculate_accuracy
      USING <ls_integrity>-pliss
            <ls_integrity>-aciss
      CHANGING lv_issue.

    PERFORM zz_calculate_accuracy
      USING <ls_integrity>-pluse
            <ls_integrity>-acuse
      CHANGING lv_usage.

    CHECK lv_issue >= 0 OR lv_usage >= 0.

    <ls_month>-score += COND decfloat34(
      WHEN lv_issue >= 0 AND lv_usage >= 0
        THEN ( lv_issue + lv_usage ) / 2
      WHEN lv_issue >= 0
        THEN lv_issue
      ELSE lv_usage
    ).

    <ls_month>-count += 1.

  ENDLOOP.

  PERFORM zz_get_weighted_score
    USING lt_month
    CHANGING lv_score
             cv_valid.

  IF cv_valid = abap_true.
    cv_score = round( val = lv_score dec = 0 ).
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_calculate_grade
*& 종합 점수 기준 등급 산정
*&---------------------------------------------------------------------*
FORM zz_calculate_grade
  USING    pv_tscore TYPE ztmma00100-tscor
  CHANGING cv_grade  TYPE ztmma00100-grade.

  cv_grade = COND #(
    WHEN pv_tscore >= 95 THEN 'S'
    WHEN pv_tscore >= 90 THEN 'A'
    WHEN pv_tscore >= 80 THEN 'B'
    WHEN pv_tscore >= 70 THEN 'C'
    ELSE 'D'
  ).

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_calculate_result
*& 세 평가 항목이 모두 존재하는 업체만 신규 평가행 생성
*&---------------------------------------------------------------------*
FORM zz_calculate_result .

  DATA: ls_eval TYPE ztmma00100,
        lv_d_ok TYPE abap_bool,
        lv_q_ok TYPE abap_bool,
        lv_p_ok TYPE abap_bool.

  REFRESH gt_eval.

  LOOP AT gt_lifnr ASSIGNING FIELD-SYMBOL(<ls_lifnr>).

    CLEAR: ls_eval,
           lv_d_ok,
           lv_q_ok,
           lv_p_ok.

    PERFORM zz_calculate_dscore
      USING <ls_lifnr>-lifnr
      CHANGING ls_eval-dscor
               lv_d_ok.

    PERFORM zz_calculate_qscore
      USING <ls_lifnr>-lifnr
      CHANGING ls_eval-qscor
               lv_q_ok.

    PERFORM zz_calculate_pscore
      USING <ls_lifnr>-lifnr
      CHANGING ls_eval-pscor
               lv_p_ok.

    " 하나라도 평가 데이터가 없으면 해당 업체는 평가 제외
    CHECK lv_d_ok = abap_true
      AND lv_q_ok = abap_true.
*      AND lv_p_ok = abap_true.

    ls_eval-datab = p_to + 1.
    ls_eval-datbi = '99991231'.
    ls_eval-lifnr = <ls_lifnr>-lifnr.
    ls_eval-uname = sy-uname.
    ls_eval-ernam = sy-uname.
    ls_eval-erdat = sy-datum.
    ls_eval-erzet = sy-uzeit.

    "이 부분을 교체
*    ls_eval-tscor = round(
*      val = CONV decfloat34( ls_eval-dscor ) * '0.50'
*          + CONV decfloat34( ls_eval-qscor ) * '0.45'
*          + CONV decfloat34( ls_eval-pscor ) * '0.05'
*      dec = 0
*    ).
    IF lv_p_ok = abap_true.

      "외주정합성 점수가 있는 경우
      ls_eval-tscor = round(
        val = CONV decfloat34( ls_eval-dscor ) * '0.50'
            + CONV decfloat34( ls_eval-qscor ) * '0.45'
            + CONV decfloat34( ls_eval-pscor ) * '0.05'
        dec = 0
      ).

    ELSE.

      "외주정합성 점수가 없는 경우
      ls_eval-tscor = round(
        val = ( CONV decfloat34( ls_eval-dscor ) * '0.50'
              + CONV decfloat34( ls_eval-qscor ) * '0.45' )
              / '0.95'
        dec = 0
      ).

    ENDIF.
    PERFORM zz_calculate_grade
      USING ls_eval-tscor
      CHANGING ls_eval-grade.

    APPEND ls_eval TO gt_eval.

  ENDLOOP.

  IF gt_eval IS INITIAL.
    MESSAGE s134 DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_save_result
*& 현재 유효 평가를 종료하고 신규 평가기록 INSERT
*&---------------------------------------------------------------------*
FORM zz_save_result .

  DATA: lv_datbi TYPE datbi,
        lv_vevno TYPE ztmma00100-vevno.
  DATA : lv_line TYPE i.
  lv_datbi = p_to.

  LOOP AT gt_eval ASSIGNING FIELD-SYMBOL(<ls_eval>).

    " 동일 업체의 현재 유효 평가 종료
    UPDATE ztmma00100
      SET datbi = @lv_datbi,
          aenam = @sy-uname,
          aedat = @sy-datum,
          aezet = @sy-uzeit
      WHERE lifnr = @<ls_eval>-lifnr
        AND datbi = '99991231'
        AND datab <= @p_to.

    CLEAR lv_vevno.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr = '01'
        object      = 'ZMM_VEVNO'
        quantity    = '1'
      IMPORTING
        number      = lv_vevno
      EXCEPTIONS
        OTHERS      = 1.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE s135 DISPLAY LIKE 'E'.
    ENDIF.

    <ls_eval>-mandt = sy-mandt.
    <ls_eval>-vevno = lv_vevno.

  ENDLOOP.

  INSERT ztmma00100 FROM TABLE @gt_eval.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE s136 DISPLAY LIKE 'E'.
  ENDIF.

  COMMIT WORK AND WAIT.
  lv_line = lines( gt_eval ).
  MESSAGE s137 WITH lv_line.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_period
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_period.

  "테스트용: 2026년 10월 평가
  p_from = '20261001'.
  p_to   = '20261031'.

ENDFORM.

*FORM zz_set_period .
*
*  "전월 마지막 날
*  p_to = sy-datum.
*  p_to+6(2) = '01'.
*  p_to = p_to - 1.
*
*  "전월 첫 번째 날
*  p_from = p_to.
*  p_from+6(2) = '01'.
*
*ENDFORM.
**  p_to = sy-datum.
**  p_to+6(2) = '01'.
**  p_to = p_to - 1.
**
**  p_from = p_to.
**  p_from+6(2) = '01'.
*
*  "올해 12월 31일
*  p_to = sy-datum.
*  p_to+4(4) = '1231'.
*
*  "올해 10월 1일: 10~12월 평가
*  p_from = sy-datum.
*  p_from+4(4) = '1001'.
