*&---------------------------------------------------------------------*
*& Include          ZLDPA00021_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form 1000_onli
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM 1000_onli .

  CHECK sy-ucomm = zlea_onli.

  IF pa_bsdat IS INITIAL.
    MESSAGE '예측기준일을 입력해주세요.' TYPE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_forecast_target
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_forecast_target .

  CLEAR: gt_forecast, gt_history, gt_ext_plan, gt_ext_event,
         gv_ai_done, gv_confirm, gv_ai_date, gv_ai_time, gt_workdays.

  PERFORM zz_set_period_data.

  """ 과거 SO/GI 실적
  PERFORM zz_get_so_history.
  PERFORM zz_get_gi_history.
  PERFORM zz_exe_calc_gap.

  """ 실적 기반 예측 대상
  PERFORM zz_set_forecast_data.

  """ 미완료 SO 및 외부요인 기반 예측 대상
  PERFORM zz_set_forecast_data2.

  """ 플랜트별 활성 자재 검증
  PERFORM zz_get_plant_material.

  """ 실적이 없는 월 보완
  PERFORM zz_set_empty_history.

  """ 미완료 SO 조회
  PERFORM zz_get_open_so.

  """ 고객 생산계획 및 이벤트 조회
  PERFORM zz_get_external_factor.

  """ 자재별 외부요인 건수 설정
  PERFORM zz_set_factor_count.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_field_catalog .

  CLEAR gt_fcat.

  PERFORM zz_exe_add_fcat USING 'ITENO'       'Item'          1.
  PERFORM zz_exe_add_fcat USING 'MATNR'       '자재번호'      2.
  PERFORM zz_exe_add_fcat USING 'MAKTX'       '자재명'        3.
  PERFORM zz_exe_add_fcat USING 'SOQTY'       '과거 SO'       4.
  PERFORM zz_exe_add_fcat USING 'GIQTY'       '과거 GI'       5.
  PERFORM zz_exe_add_fcat USING 'GAPQTY'      'SO-GI'         6.
  PERFORM zz_exe_add_fcat USING 'OPQTY'       '미완료 SO'     7.
  PERFORM zz_exe_add_fcat USING 'MEINS'       '단위'          8.
  PERFORM zz_exe_add_fcat USING 'PLAN_COUNT'  '생산계획 건수' 9.
  PERFORM zz_exe_add_fcat USING 'EVENT_COUNT' 'Event 건수'    10.
  PERFORM zz_exe_add_fcat USING 'AIQTY'       'AI 예측수량'   11.
  PERFORM zz_exe_add_fcat USING 'REASON_LINK' 'AI 예측사유'   12.
  PERFORM zz_exe_add_fcat USING 'ADQTY'       '조정수량'      13.
  PERFORM zz_exe_add_fcat USING 'FIQTY'       '최종수량'      14.
  PERFORM zz_exe_add_fcat USING 'RDATE'       '필요일자'      15.
  PERFORM zz_exe_add_fcat USING 'AISTAT_TEXT' 'AI 실행상태'   16.

  LOOP AT gt_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).

    CASE <fs_fcat>-fieldname.

      WHEN 'MATNR'.
        <fs_fcat>-key = abap_true.

      WHEN 'SOQTY' OR 'GIQTY' OR 'GAPQTY' OR 'OPQTY' OR 'AIQTY' OR 'FIQTY'.
        <fs_fcat>-qfieldname = 'MEINS'.
        <fs_fcat>-ref_table  = 'ZTMMA00020'.
        <fs_fcat>-ref_field  = <fs_fcat>-fieldname.

      WHEN 'ADQTY'.
        IF gv_ai_done = abap_true AND gv_confirm <> abap_true.
          <fs_fcat>-edit = abap_true.
        ELSE.
          <fs_fcat>-edit = abap_false.
        ENDIF.
        <fs_fcat>-qfieldname = 'MEINS'.
        <fs_fcat>-ref_table  = 'ZTMMA00020'.
        <fs_fcat>-ref_field  = 'ADQTY'.

      WHEN 'REASON_LINK'.
        <fs_fcat>-hotspot   = abap_true.
        <fs_fcat>-outputlen = 20.

    ENDCASE.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_layout .

  CLEAR gs_layo.
  gs_layo-zebra      = abap_true.
  gs_layo-cwidth_opt = abap_true.
  gs_layo-sel_mode   = 'A'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_ai_forecast
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_ai_forecast .

  DATA: ls_input        TYPE ty_ai_input,
        ls_response     TYPE ty_ai_response,
        lv_input_json   TYPE string,
        lv_output_json  TYPE string,
        lv_success      TYPE abap_bool,
        lv_message      TYPE string,
        ls_ai           TYPE ty_ai_result,
        lv_factor_error TYPE abap_bool.

  DATA: lt_unique TYPE SORTED TABLE OF ztmma00020-matnr WITH UNIQUE KEY table_line.
  FIELD-SYMBOLS <fs_forecast> TYPE ty_forecast.

  "-------------------------------------------------------------
  " 실행 가능 여부 확인
  "-------------------------------------------------------------
  CHECK go_grid IS BOUND.

  IF gv_confirm = abap_true.
    MESSAGE '이미 확정된 수요예측입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF gt_forecast IS INITIAL.
    MESSAGE '수요예측 대상이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 외부요인 사전 검증
  PERFORM zz_check_external_factor CHANGING lv_factor_error.

  IF lv_factor_error = abap_true.
    RETURN.
  ENDIF.

  """ 기존 AI 결과 초기화 및 실행 중 상태 설정
  gv_ai_done = abap_false.

  CLEAR: gv_ai_date, gv_ai_time.

  LOOP AT gt_forecast ASSIGNING <fs_forecast>.

    <fs_forecast>-aistat = '0020'.

    CLEAR: <fs_forecast>-aiqty,
           <fs_forecast>-aireason,
           <fs_forecast>-reason_link,
           <fs_forecast>-adqty,
           <fs_forecast>-fiqty.

  ENDLOOP.

  PERFORM zz_set_status_text.
  PERFORM zz_exe_update_fcat.

  """ AI 입력 구성
  ls_input-werks          = pa_werks.
  ls_input-base_date      = pa_bsdat.
  ls_input-forecast_from  = gv_fc_from.
  ls_input-forecast_to    = gv_fc_to.
  ls_input-history_months = gv_hmons.
  ls_input-forecasts      = gt_forecast.
  ls_input-history        = gt_history.
  ls_input-plans          = gt_ext_plan.
  ls_input-events         = gt_ext_event.

  """ ABAP -> JSON
  TRY.

      lv_input_json = /ui2/cl_json=>serialize(
        data           = ls_input
        pretty_name    = /ui2/cl_json=>pretty_mode-low_case
        numc_as_string = abap_true ).

    CATCH cx_root INTO DATA(lx_json).

      PERFORM zz_set_ai_failed.

      MESSAGE lx_json->get_text( )
        TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

  ENDTRY.

  """ 실제 AI API 호출
  zcl_dp_ai_service=>predict_demand(
    EXPORTING
      iv_input_json  = lv_input_json
    IMPORTING
      ev_output_json = lv_output_json
      ev_success     = lv_success
      ev_message     = lv_message ).

  IF lv_success <> abap_true.

    PERFORM zz_set_ai_failed.
    MESSAGE lv_message TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.

  ENDIF.

  """ 응답 JSON -> ABAP
  TRY.

      /ui2/cl_json=>deserialize(
        EXPORTING
          json        = lv_output_json
          pretty_name = /ui2/cl_json=>pretty_mode-low_case
        CHANGING
          data        = ls_response ).

    CATCH cx_root INTO DATA(lx_result).

      PERFORM zz_set_ai_failed.

      MESSAGE lx_result->get_text( )
        TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

  ENDTRY.

  """ 응답 건수 검증
  IF lines( ls_response-forecasts ) <> lines( gt_forecast ).

    PERFORM zz_set_ai_failed.
    MESSAGE 'AI 응답 건수가 예측 대상과 일치하지 않습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.

  ENDIF.

  """ AI 응답 전체 검증
  LOOP AT ls_response-forecasts INTO ls_ai.

    " 대상 자재 여부
    READ TABLE gt_forecast INTO DATA(ls_target)
      WITH KEY matnr = ls_ai-matnr.

    IF sy-subrc <> 0 OR ls_ai-matnr IS INITIAL.

      PERFORM zz_set_ai_failed.
      MESSAGE 'AI 응답에 잘못된 자재번호가 있습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

    " 중복 자재 방지
    INSERT ls_ai-matnr INTO TABLE lt_unique.

    IF sy-subrc <> 0.

      PERFORM zz_set_ai_failed.
      MESSAGE 'AI 응답에 중복된 자재가 있습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

    " 예측수량 및 사유 검증
    IF ls_ai-aiqty < 0 OR ls_ai-aireason IS INITIAL.

      PERFORM zz_set_ai_failed.
      MESSAGE 'AI 예측수량 또는 예측사유가 유효하지 않습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

    " AI 예측사유 길이 검증
    IF strlen( ls_ai-aireason ) > 255.

      PERFORM zz_set_ai_failed.
      MESSAGE |{ ls_ai-matnr }: AI 예측사유가 255자를 초과했습니다.| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

    " 확정 주문 최소수량 검증
    IF ls_ai-aiqty < ls_target-opqty.

      PERFORM zz_set_ai_failed.
      MESSAGE 'AI 예측수량이 미완료 SO보다 적습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

  ENDLOOP.

  """ 검증 성공 후 ALV 반영
  LOOP AT gt_forecast ASSIGNING <fs_forecast>.

    READ TABLE ls_response-forecasts INTO ls_ai WITH KEY matnr = <fs_forecast>-matnr.

    <fs_forecast>-aiqty    = ls_ai-aiqty.
    <fs_forecast>-aireason = ls_ai-aireason.
    <fs_forecast>-aistat   = '0030'.

    " 예측 근거 링크 설정
    IF <fs_forecast>-aireason IS NOT INITIAL.
      <fs_forecast>-reason_link = '예측 근거 보기'.
    ELSE.
      CLEAR <fs_forecast>-reason_link.
    ENDIF.

    " AI 예측수량을 조정수량 기본값으로 설정
    <fs_forecast>-adqty = <fs_forecast>-aiqty.

    " 최종수량은 SAVE 시 확정
    CLEAR <fs_forecast>-fiqty.

  ENDLOOP.

  """ AI 실행 완료
  gv_ai_date = sy-datum.
  gv_ai_time = sy-uzeit.

  gv_ai_done = abap_true.

  " 코드명 및 ALV 갱신
  PERFORM zz_set_status_text.
  PERFORM zz_exe_update_fcat.

  MESSAGE 'AI 수요예측이 완료되었습니다.' TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_save_forecast
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_save_forecast .

  DATA: lv_fcsno   TYPE ztmma00010-fcsno,
        lt_header  TYPE tt_dp21_head,
        lt_item    TYPE tt_dp21_item,
        lt_history TYPE tt_dp21_hist,
        lt_factor  TYPE tt_dp21_fact,
        lv_error   TYPE abap_bool,
        lv_answer  TYPE c.

  """ AI 실행 여부
  IF gv_ai_done <> abap_true.
    MESSAGE 'AI 수요예측을 먼저 실행해주세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  """ 중복 저장 방지
  IF gv_confirm = abap_true.
    MESSAGE '이미 확정 및 저장된 수요예측입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  """ ALV에서 수정한 ADQTY 반영
  IF go_grid IS BOUND.
    go_grid->check_changed_data( ).
  ENDIF.

  """ 최종수량 계산 및 입력 검증
  PERFORM zz_check_save_forecast CHANGING lv_error.

  IF lv_error = abap_true.
    RETURN.
  ENDIF.

  """ 영업일수 검증
  PERFORM zz_exe_check_workdays CHANGING lv_error.

  IF lv_error = abap_true.
    RETURN.
  ENDIF.

  """ 저장 및 확정 여부 확인
  PERFORM zz_exe_confirm_save CHANGING lv_answer.

  IF lv_answer <> zlea_1.
    RETURN.
  ENDIF.

  """ 동일 플랜트/예측기간에 대한 저장 잠금
  PERFORM zz_exe_lock_forecast CHANGING lv_error.

  IF lv_error = abap_true.
    RETURN.
  ENDIF.

  """ FCSNO 채번
  PERFORM zz_get_next_fcsno CHANGING lv_fcsno lv_error.

  IF lv_error = abap_true.
    PERFORM zz_exe_unlock_forecast.
    RETURN.
  ENDIF.

  """ 테이블별 저장 데이터 구성
  PERFORM zz_build_save_forecast
    USING lv_fcsno  CHANGING lt_header lt_item lt_history lt_factor.

  IF lt_header IS INITIAL OR lt_item IS INITIAL.
    MESSAGE '저장할 수요예측 Header/Item이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    PERFORM zz_exe_unlock_forecast.
    RETURN.
  ENDIF.

  """ 기존 Forecast 비활성화
  PERFORM zz_set_deactivate_forecast CHANGING lv_error.

  IF lv_error = abap_true.
    ROLLBACK WORK.
    PERFORM zz_exe_unlock_forecast.
    RETURN.
  ENDIF.

  """ DB INSERT
  PERFORM zz_insert_save_forecast
    USING lt_header lt_item lt_history lt_factor CHANGING lv_error.

  IF lv_error = abap_true.
    ROLLBACK WORK.
    MESSAGE '수요예측 저장 중 오류가 발생했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    PERFORM zz_exe_unlock_forecast.
    RETURN.
  ENDIF.

  """ 전체 저장 성공 시 확정
  COMMIT WORK AND WAIT.

  DATA(lv_commit_subrc) = sy-subrc.

  PERFORM zz_exe_unlock_forecast.

  IF lv_commit_subrc <> 0.
    MESSAGE '저장 확정 중 오류가 발생했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  gv_confirm = abap_true.

  """ 확정 후 조정수량 편집 비활성화
  PERFORM zz_exe_update_fcat.

  MESSAGE |수요예측 { lv_fcsno } 저장 및 확정이 완료되었습니다.| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_period_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_period_data .

  DATA: lv_base_month TYPE sy-datum,
        lv_prev_month TYPE sy-datum.

*** 실적기준개월
  IF rb_06 = abap_true.
    gv_hmons = '06'.
  ELSEIF rb_12 = abap_true.
    gv_hmons = '12'.
  ELSEIF rb_24 = abap_true.
    gv_hmons = '24'.
  ENDIF.

*** 기준월의 1일 (예: BSDAT = 20260930 -> 20260901)
  lv_base_month = pa_bsdat.
  lv_base_month+6(2) = '01'.

*** 예측 시작일 (기준월 다음달 1일)
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_base_month
      days      = 0
      months    = 1
      signum    = '+'
      years     = 0
    IMPORTING
      calc_date = gv_fc_from.

*** 예측 종료일 (예측 시작월 다음달 1일 - 1일)
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = gv_fc_from
      days      = 0
      months    = 1
      signum    = '+'
      years     = 0
    IMPORTING
      calc_date = gv_fc_to.

  gv_fc_to = gv_fc_to - 1.

*** 분석 종료일 (기준월 1일 - 1일)
  gv_hist_to = lv_base_month - 1.

*** 분석 시작일 (6개월: 20260901 - 6개월 -> 20260301)
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = lv_base_month
      days      = 0
      months    = gv_hmons
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = gv_hist_from.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_so_history
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_so_history .

  TYPES: BEGIN OF ty_so,
           matnr TYPE ztsda00020-matnr,
           audat TYPE ztsda00010-audat,
           soqty TYPE ztsda00020-kwmeng,
           meins TYPE ztsda00020-meins,
         END OF ty_so.

  DATA: lt_so      TYPE STANDARD TABLE OF ty_so,
        ls_history TYPE ty_history.

*** 분석기간 내 발생한 실제 SO 조회
  SELECT b~matnr,
         a~audat,
         b~kwmeng AS soqty,
         b~meins
    FROM ztsda00010 AS a
    INNER JOIN ztsda00020 AS b
      ON b~vbeln = a~vbeln
   WHERE a~audat BETWEEN @gv_hist_from AND @gv_hist_to
     AND b~werks = @pa_werks
*     AND b~matnr IN @so_matnr
     AND a~sosta <> 'CN'
    INTO TABLE @lt_so.

*** 월별 집계
  LOOP AT lt_so INTO DATA(ls_so).

    CLEAR ls_history.
    ls_history-matnr = ls_so-matnr.
    ls_history-perio = ls_so-audat(6).
    ls_history-soqty = ls_so-soqty.
    ls_history-meins = ls_so-meins.
    COLLECT ls_history INTO gt_history.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_gi_history
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_gi_history .

  TYPES: BEGIN OF ty_gi,
           matnr TYPE ztsda00040-matnr,
           acgdt TYPE ztsda00030-acgdt,
           giqty TYPE ztsda00040-lfimg,
           meins TYPE ztsda00040-meins,
         END OF ty_gi.

  DATA: lt_gi      TYPE STANDARD TABLE OF ty_gi,
        ls_history TYPE ty_history.

  """ 분석기간 내 실제 GI 조회
  SELECT b~matnr,
         a~acgdt,
         b~lfimg AS giqty,
         b~meins
    FROM ztsda00030 AS a
   INNER JOIN ztsda00040 AS b
      ON b~vbeln = a~vbeln
   WHERE a~acgdt BETWEEN @gv_hist_from AND @gv_hist_to
     AND a~gista = @zlea_c
     AND b~werks = @pa_werks
*     AND b~matnr IN @so_matnr
  INTO TABLE @lt_gi.

  """ 월별 GI 집계
  LOOP AT lt_gi INTO DATA(ls_gi).

    CLEAR ls_history.
    ls_history-matnr = ls_gi-matnr.
    ls_history-perio = ls_gi-acgdt(6).
    ls_history-giqty = ls_gi-giqty.
    ls_history-meins = ls_gi-meins.
    COLLECT ls_history INTO gt_history.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_calc_gap
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_calc_gap .

  LOOP AT gt_history ASSIGNING FIELD-SYMBOL(<fs_history>).
    <fs_history>-gapqty = <fs_history>-soqty - <fs_history>-giqty.
  ENDLOOP.

  SORT gt_history BY matnr perio.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_forecast_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_forecast_data .

  DATA: lv_item TYPE i.

  CLEAR gt_forecast.

  """ 월별 Detail -> 자재별 전체 합계
  LOOP AT gt_history INTO gs_history.

    READ TABLE gt_forecast ASSIGNING FIELD-SYMBOL(<fs_forecast>)
                           WITH KEY matnr = gs_history-matnr.

    IF sy-subrc = 0.

      <fs_forecast>-soqty	= <fs_forecast>-soqty + gs_history-soqty.
      <fs_forecast>-giqty = <fs_forecast>-giqty + gs_history-giqty.
      <fs_forecast>-gapqty = <fs_forecast>-gapqty + gs_history-gapqty.

    ELSE.

      CLEAR gs_forecast.

      lv_item = lv_item + 10.

      gs_forecast-iteno  = lv_item.
      gs_forecast-matnr  = gs_history-matnr.
      gs_forecast-soqty  = gs_history-soqty.
      gs_forecast-giqty  = gs_history-giqty.
      gs_forecast-gapqty = gs_history-gapqty.
      gs_forecast-meins  = gs_history-meins.

      """ 예측 필요일
      gs_forecast-rdate = gv_fc_from.

      """ 자재명
      SELECT SINGLE maktx
        FROM ztcma00020
       WHERE matnr = @gs_history-matnr
        INTO @gs_forecast-maktx.

      APPEND gs_forecast TO gt_forecast.

    ENDIF.

  ENDLOOP.

  SORT gt_forecast BY matnr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_external_factor
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_external_factor .

  DATA lv_perio TYPE ztcma00170-perio.

  CLEAR: gt_ext_plan, gt_ext_event.

  " 예측 대상 자재가 없으면 조회하지 않음
  CHECK gt_forecast IS NOT INITIAL.

  " 예측 대상월 (YYYYMM)
  lv_perio = gv_fc_from(6).

  """ 고객 생산계획 수집
  SELECT plnno,
         iteno,
         colno,
         kunnr,
         matnr,
         perio,
         source,
         plan_qty,
         meins,
         change_dir,
         change_rate,
         collect_date
    FROM ztcma00170
    INTO CORRESPONDING FIELDS OF TABLE @gt_ext_plan
    FOR ALL ENTRIES IN @gt_forecast
   WHERE matnr = @gt_forecast-matnr
     AND perio = @lv_perio
     AND delfg = @space
     AND confirm_yn = @zlea_y.

  SORT gt_ext_plan BY matnr kunnr plnno iteno.

  """ 고객 Event 수집
  SELECT evtno,
         iteno,
         colno,
         kunnr,
         matnr,
         event_type,
         valid_from,
         valid_to,
         source,
         impact_dir,
         impact_rate,
         event_text,
         collect_date
    FROM ztcma00180
    INTO CORRESPONDING FIELDS OF TABLE @gt_ext_event
    FOR ALL ENTRIES IN @gt_forecast
   WHERE matnr = @gt_forecast-matnr
     AND valid_from <= @gv_fc_to
     AND valid_to   >= @gv_fc_from
     AND delfg = @space
     AND confirm_yn = @zlea_y.

  SORT gt_ext_event BY matnr kunnr evtno iteno.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_add_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> P_18
*&---------------------------------------------------------------------*
FORM zz_exe_add_fcat  USING pv_field pv_text pv_pos.

  CLEAR gs_fcat.
  gs_fcat-fieldname = pv_field.
  gs_fcat-coltext   = pv_text.
  gs_fcat-col_pos   = pv_pos.
  APPEND gs_fcat TO gt_fcat.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_refresh_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_refresh_alv .

  DATA: ls_stable TYPE lvc_s_stbl.

  CHECK go_grid IS BOUND.

  ls_stable-row = abap_true.
  ls_stable-col = abap_true.

  go_grid->refresh_table_display(
    EXPORTING
      is_stable = ls_stable ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_open_so
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_open_so .

*  TYPES: BEGIN OF ty_so_item,
*           vbeln  TYPE ztsda00020-vbeln,
*           posnr  TYPE ztsda00020-posnr,
*           matnr  TYPE ztsda00020-matnr,
*           kwmeng TYPE ztsda00020-kwmeng,
*           meins  TYPE ztsda00020-meins,
*           reqdt  TYPE ztsda00020-reqdt,
*         END OF ty_so_item.
*
*  DATA: lt_so_item TYPE STANDARD TABLE OF ty_so_item,
*        lv_gista   TYPE ztsda00030-gista.
*
*  FIELD-SYMBOLS: <fs_forecast> TYPE ty_forecast.
*
*  """ 기존 수량 초기화
*  LOOP AT gt_forecast ASSIGNING <fs_forecast>.
*    CLEAR: <fs_forecast>-opqty, <fs_forecast>-cur_open_qty, <fs_forecast>-overdue_qty.
*  ENDLOOP.
*
*  CHECK gt_forecast IS NOT INITIAL.
*
*  """ 미완료 SO 조회
*  SELECT b~vbeln,
*         b~posnr,
*         b~matnr,
*         b~kwmeng,
*         b~meins,
*         b~reqdt
*    FROM ztsda00010 AS a
*    INNER JOIN ztsda00020 AS b
*      ON b~vbeln = a~vbeln
*   WHERE b~werks = @pa_werks
**     AND b~matnr IN @so_matnr
*     AND b~reqdt <= @gv_fc_to
*     AND b~reqdt IS NOT INITIAL
*     AND a~audat <= @pa_bsdat
*     AND ( a~sosta = 'SO' OR a~sosta = 'DO' )
*    INTO TABLE @lt_so_item.
*
*  """ SO 품목별 미출고 여부 확인
*  LOOP AT lt_so_item INTO DATA(ls_so_item).
*
*    CLEAR lv_gista.
*
*    """ 해당 SO Item과 연결된 Delivery GI 상태
*    SELECT SINGLE d~gista
*      FROM ztsda00040 AS c
*      INNER JOIN ztsda00030 AS d
*        ON d~vbeln = c~vbeln
*     WHERE c~vgbel = @ls_so_item-vbeln
*       AND c~posnv = @ls_so_item-posnr
*      INTO @lv_gista.
*
*    """ GI 완료 품목 제외
*    IF lv_gista = 'C'.
*      CONTINUE.
*    ENDIF.
*
*    """ 예측 대상 자재 조회
*    READ TABLE gt_forecast ASSIGNING <fs_forecast>
*      WITH KEY matnr = ls_so_item-matnr.
*
*    IF sy-subrc <> 0.
*      CONTINUE.
*    ENDIF.
*
*    """ 수량 단위 검증
*    IF <fs_forecast>-meins <> ls_so_item-meins.
*      MESSAGE 'SO 수량 단위가 일치하지 않습니다.' TYPE 'E'.
*    ENDIF.
*
*    """ 요청납기일 기준 수량 분류
*    IF ls_so_item-reqdt < pa_bsdat.
*      """ 연체 SO
*      <fs_forecast>-overdue_qty = <fs_forecast>-overdue_qty + ls_so_item-kwmeng.
*    ELSEIF ls_so_item-reqdt < gv_fc_from.
*      """ 현재월 납기 미도래 SO
*      <fs_forecast>-cur_open_qty = <fs_forecast>-cur_open_qty + ls_so_item-kwmeng.
*    ELSE.
*      """ 예측월 미완료 SO
*      <fs_forecast>-opqty = <fs_forecast>-opqty + ls_so_item-kwmeng.
*    ENDIF.
*
*  ENDLOOP.

  TYPES: BEGIN OF ty_so_item,
           vbeln  TYPE ztsda00020-vbeln,
           posnr  TYPE ztsda00020-posnr,
           matnr  TYPE ztsda00020-matnr,
           kwmeng TYPE ztsda00020-kwmeng,
           meins  TYPE ztsda00020-meins,
           reqdt  TYPE ztsda00020-reqdt,
         END OF ty_so_item.

  DATA: lt_so_item TYPE STANDARD TABLE OF ty_so_item,
        lv_gista   TYPE ztsda00030-gista.

  FIELD-SYMBOLS <fs_forecast> TYPE ty_forecast.

  """ 기존 미완료 SO 수량 초기화
  LOOP AT gt_forecast ASSIGNING <fs_forecast>.
    CLEAR: <fs_forecast>-opqty, <fs_forecast>-cur_open_qty, <fs_forecast>-overdue_qty.
  ENDLOOP.

  CHECK gt_forecast IS NOT INITIAL.

  """ GI 이전 단계의 SO 품목 조회
  SELECT b~vbeln,
         b~posnr,
         b~matnr,
         b~kwmeng,
         b~meins,
         b~reqdt
    FROM ztsda00010 AS a
   INNER JOIN ztsda00020 AS b
      ON b~vbeln = a~vbeln
   WHERE b~werks = @pa_werks
     AND b~reqdt <= @gv_fc_to
     AND b~reqdt IS NOT INITIAL
     AND a~audat <= @pa_bsdat
     AND ( a~sosta = 'SO' OR a~sosta = 'DO' )
    INTO TABLE @lt_so_item.

  """ SO 품목별 미출고 여부 확인
  LOOP AT lt_so_item INTO DATA(ls_so_item).

    CLEAR lv_gista.

    """ SO Item에 연결된 Delivery의 GI 상태 조회
    SELECT SINGLE d~gista
      FROM ztsda00040 AS c
     INNER JOIN ztsda00030 AS d
        ON d~vbeln = c~vbeln
     WHERE c~vgbel = @ls_so_item-vbeln
       AND c~posnv = @ls_so_item-posnr
      INTO @lv_gista.

    """ GI 완료면 전체수량 출고이므로 제외
    IF lv_gista = 'C'.
      CONTINUE.
    ENDIF.

    """ 예측 대상 자재 확인
    READ TABLE gt_forecast ASSIGNING <fs_forecast> WITH KEY matnr = ls_so_item-matnr.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    """ 수량 단위 확인
    IF <fs_forecast>-meins <> ls_so_item-meins.
      MESSAGE 'SO 수량 단위가 일치하지 않습니다.' TYPE 'E'.
    ENDIF.

    """ GI 미완료이므로 KWMENG 전체를 미출고 수량으로 사용
    IF ls_so_item-reqdt < pa_bsdat.
      <fs_forecast>-overdue_qty = <fs_forecast>-overdue_qty + ls_so_item-kwmeng.
    ELSEIF ls_so_item-reqdt < gv_fc_from.
      <fs_forecast>-cur_open_qty = <fs_forecast>-cur_open_qty + ls_so_item-kwmeng.
    ELSE.
      <fs_forecast>-opqty = <fs_forecast>-opqty + ls_so_item-kwmeng.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_free_popup
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_free_popup .

  IF go_reason_edit IS BOUND.
    go_reason_edit->free( ).
    CLEAR go_reason_edit.
  ENDIF.

  IF go_reason_cont IS BOUND.
    go_reason_cont->free( ).
    CLEAR go_reason_cont.
  ENDIF.

  cl_gui_cfw=>flush( ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_forecast_data2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_forecast_data2 .

  TYPES: BEGIN OF ty_target,
           matnr TYPE ztmma00020-matnr,
           meins TYPE ztmma00020-meins,
         END OF ty_target.

  DATA: lt_so_target    TYPE STANDARD TABLE OF ty_target,
        lt_plan_target  TYPE STANDARD TABLE OF ty_target,
        lt_event_target TYPE STANDARD TABLE OF ty_target,
        ls_forecast     TYPE ty_forecast,
        lv_perio        TYPE ztcma00170-perio,
        lv_iteno        TYPE i.

  FIELD-SYMBOLS <fs_forecast> TYPE ty_forecast.

  lv_perio = gv_fc_from(6).

  """ 미완료 SO가 존재하는 자재
  SELECT DISTINCT b~matnr, b~meins
    FROM ztsda00010 AS a
    INNER JOIN ztsda00020 AS b
      ON b~vbeln = a~vbeln
   WHERE b~werks = @pa_werks
*     AND b~matnr IN @so_matnr
     AND b~reqdt <= @gv_fc_to
     AND b~reqdt IS NOT INITIAL
     AND a~audat <= @pa_bsdat
     AND ( a~sosta = 'SO' OR a~sosta = 'DO' )
    INTO TABLE @lt_so_target.

  """ 확정 고객 생산계획이 존재하는 자재
  SELECT DISTINCT matnr, meins
    FROM ztcma00170
   WHERE perio = @lv_perio
*     AND matnr IN @so_matnr
     AND confirm_yn = @zlea_y
     AND delfg = @space
    INTO TABLE @lt_plan_target.

  """ 확정 Event가 존재하는 자재 (Event에는 수량 단위가 없으므로 자재 마스터에서 조회)
  SELECT DISTINCT a~matnr, b~meins
    FROM ztcma00180 AS a
    INNER JOIN ztcma00020 AS b
      ON b~matnr = a~matnr
   WHERE a~valid_from <= @gv_fc_to
     AND a~valid_to >= @gv_fc_from
*     AND a~matnr IN @so_matnr
     AND a~confirm_yn = @zlea_y
     AND a~delfg = @space
    INTO TABLE @lt_event_target.

  """ SO 기준 신규 자재 추가
  LOOP AT lt_so_target INTO DATA(ls_target).

    READ TABLE gt_forecast TRANSPORTING NO FIELDS WITH KEY matnr = ls_target-matnr.

    IF sy-subrc <> 0.
      CLEAR ls_forecast.
      ls_forecast-matnr = ls_target-matnr.
      ls_forecast-meins = ls_target-meins.
      ls_forecast-rdate = gv_fc_from.
      APPEND ls_forecast TO gt_forecast.
    ENDIF.

  ENDLOOP.

  """ 생산계획 기준 신규 자재 추가
  LOOP AT lt_plan_target INTO ls_target.

    READ TABLE gt_forecast TRANSPORTING NO FIELDS WITH KEY matnr = ls_target-matnr.

    IF sy-subrc <> 0.
      CLEAR ls_forecast.
      ls_forecast-matnr = ls_target-matnr.
      ls_forecast-meins = ls_target-meins.
      ls_forecast-rdate = gv_fc_from.
      APPEND ls_forecast TO gt_forecast.
    ENDIF.

  ENDLOOP.

  """ Event 기준 신규 자재 추가
  LOOP AT lt_event_target INTO ls_target.

    READ TABLE gt_forecast TRANSPORTING NO FIELDS WITH KEY matnr = ls_target-matnr.

    IF sy-subrc <> 0.
      CLEAR ls_forecast.
      ls_forecast-matnr = ls_target-matnr.
      ls_forecast-meins = ls_target-meins.
      ls_forecast-rdate = gv_fc_from.
      APPEND ls_forecast TO gt_forecast.
    ENDIF.

  ENDLOOP.

  """ 최종 예측 대상 정렬 및 Item 번호 생성
  SORT gt_forecast BY matnr.

  CLEAR lv_iteno.

  LOOP AT gt_forecast ASSIGNING <fs_forecast>.

    lv_iteno = lv_iteno + 10.
    <fs_forecast>-iteno = lv_iteno.

    """ 신규 자재를 포함하여 자재명 조회
    SELECT SINGLE maktx
      FROM ztcma00020
     WHERE matnr = @<fs_forecast>-matnr
      INTO @<fs_forecast>-maktx.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_check_save_forecast
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_check_save_forecast  CHANGING pv_error TYPE abap_bool.

  CLEAR pv_error.

  IF gt_forecast IS INITIAL.
    MESSAGE '확정할 수요예측 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    pv_error = abap_true.
    RETURN.
  ENDIF.

  LOOP AT gt_forecast ASSIGNING FIELD-SYMBOL(<fs_forecast>).

    """ 필수정보 확인
    IF <fs_forecast>-matnr IS INITIAL OR
       <fs_forecast>-meins IS INITIAL OR
       <fs_forecast>-rdate IS INITIAL.
*      MESSAGE '필수 데이터가 누락되었습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      MESSAGE |필수 항목 누락: { <fs_forecast>-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      pv_error = abap_true.
      RETURN.
    ENDIF.

    """ ADQTY = AIQTY를 기본으로 채워두므로 0도 유효한 입력
    <fs_forecast>-fiqty = <fs_forecast>-adqty.

    """ 음수 검증
    IF <fs_forecast>-fiqty < 0 OR <fs_forecast>-fiqty < <fs_forecast>-opqty.
      MESSAGE |{ <fs_forecast>-matnr }: 최종수량은 음수 또는 미완료 SO 수량 미만일 수 없습니다.| TYPE 'S' DISPLAY LIKE 'E'.
      pv_error = abap_true.
      RETURN.
    ENDIF.

*    """ 미완료 SO 수량 검증
*    IF <fs_forecast>-fiqty < <fs_forecast>-opqty.
*      MESSAGE '최종수량이 미완료 SO 수량보다 작습니다.' TYPE 'S' DISPLAY LIKE 'E'.
*      pv_error = abap_true.
*      RETURN.
*    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_insert_save_forecast
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_HEADER
*&      --> LT_ITEM
*&      --> LT_HISTORY
*&      --> LT_FACTOR
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_insert_save_forecast  USING    pt_header  TYPE tt_dp21_head
                                       pt_item    TYPE tt_dp21_item
                                       pt_history TYPE tt_dp21_hist
                                       pt_factor  TYPE tt_dp21_fact
                              CHANGING pv_error   TYPE abap_bool.

  CLEAR pv_error.
  TRY.
      INSERT ztmma00010 FROM TABLE pt_header.
      IF sy-subrc <> 0.
        pv_error = abap_true.
        RETURN.
      ENDIF.

      """ 단위 테스트: Header INSERT 이후 강제 저장 실패
*      pv_error = abap_true.
*      RETURN.


      INSERT ztmma00020 FROM TABLE pt_item.
      IF sy-subrc <> 0.
        pv_error = abap_true.
        RETURN.
      ENDIF.

      IF pt_history IS NOT INITIAL.
        INSERT ztmma00022 FROM TABLE pt_history.
        IF sy-subrc <> 0.
          pv_error = abap_true.
          RETURN.
        ENDIF.
      ENDIF.

      IF pt_factor IS NOT INITIAL.
        INSERT ztmma00023 FROM TABLE pt_factor.
        IF sy-subrc <> 0.
          pv_error = abap_true.
          RETURN.
        ENDIF.
      ENDIF.

    CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
      pv_error = abap_true.
      MESSAGE lx_sql->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_build_save_forecast
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_FCSNO
*&      <-- LT_HEADER
*&      <-- LT_ITEM
*&      <-- LT_HISTORY
*&      <-- LT_FACTOR
*&---------------------------------------------------------------------*
FORM zz_build_save_forecast  USING pv_fcsno   TYPE ztmma00010-fcsno
                          CHANGING pt_header  TYPE tt_dp21_head
                                   pt_item    TYPE tt_dp21_item
                                   pt_history TYPE tt_dp21_hist
                                   pt_factor  TYPE tt_dp21_fact.

  DATA: ls_head    TYPE ztmma00010,
        ls_item    TYPE ztmma00020,
        ls_hist_db TYPE ztmma00022,
        ls_fact    TYPE ztmma00023,
        lv_fact_no TYPE i.

  CLEAR: pt_header, pt_item, pt_history, pt_factor.

  " Header
  ls_head-mandt  = sy-mandt.
  ls_head-fcsno  = pv_fcsno.
  ls_head-werks  = pa_werks.
  ls_head-fcdat  = gv_fc_from.
  ls_head-tcdat  = gv_fc_to.
  ls_head-bsdat  = pa_bsdat.
  ls_head-hmons  = gv_hmons.
  ls_head-cstat  = '0020'.  " 확정
  ls_head-activ = abap_true.
  ls_head-cuser  = sy-uname.
  ls_head-cdate  = sy-datum.
  ls_head-ctime  = sy-uzeit.
  ls_head-aistat = '0030'.  " AI 전체 성공
  ls_head-aidat  = gv_ai_date.
  ls_head-aitim  = gv_ai_time.
  ls_head-ernam  = sy-uname.
  ls_head-erdat  = sy-datum.
  ls_head-erzet  = sy-uzeit.
  APPEND ls_head TO pt_header.

  " Item
  LOOP AT gt_forecast INTO DATA(ls_fc).
    CLEAR ls_item.
    ls_item-mandt    = sy-mandt.
    ls_item-fcsno    = pv_fcsno.
    ls_item-iteno    = ls_fc-iteno.
    ls_item-matnr    = ls_fc-matnr.
    ls_item-aiqty    = ls_fc-aiqty.
    ls_item-opqty    = ls_fc-opqty.
    ls_item-aireason = ls_fc-aireason.
    ls_item-adqty    = ls_fc-adqty.
    ls_item-fiqty    = ls_fc-fiqty.
    ls_item-meins    = ls_fc-meins.
    ls_item-rdate    = ls_fc-rdate.
    ls_item-soqty    = ls_fc-soqty.
    ls_item-giqty    = ls_fc-giqty.
    ls_item-gapqty   = ls_fc-gapqty.
    ls_item-aistat   = ls_fc-aistat.
    ls_item-aidat    = gv_ai_date.
    ls_item-aitim    = gv_ai_time.
    ls_item-ernam    = sy-uname.
    ls_item-erdat    = sy-datum.
    ls_item-erzet    = sy-uzeit.
    APPEND ls_item TO pt_item.
  ENDLOOP.

  """ History: 분석기간 전체 월별 SO/GI 실적 Snapshot 저장 (실적이 없는 월은 0수량으로 저장)
  LOOP AT gt_history INTO DATA(ls_hist).
    READ TABLE gt_forecast INTO ls_fc WITH KEY matnr = ls_hist-matnr.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    READ TABLE gt_workdays INTO DATA(ls_wd)
      WITH TABLE KEY werks = pa_werks perio = ls_hist-perio.

    CLEAR ls_hist_db.
    ls_hist_db-mandt  = sy-mandt.
    ls_hist_db-fcsno  = pv_fcsno.
    ls_hist_db-iteno  = ls_fc-iteno.
    ls_hist_db-perio  = ls_hist-perio.
    ls_hist_db-matnr  = ls_hist-matnr.
    ls_hist_db-soqty  = ls_hist-soqty.
    ls_hist_db-giqty  = ls_hist-giqty.
    ls_hist_db-gapqty = ls_hist-gapqty.
    ls_hist_db-meins  = ls_hist-meins.
    ls_hist_db-wrkdy  = ls_wd-wrkdy.
    ls_hist_db-ernam  = sy-uname.
    ls_hist_db-erdat  = sy-datum.
    ls_hist_db-erzet  = sy-uzeit.
    APPEND ls_hist_db TO pt_history.
  ENDLOOP.

  " Factor: AI 입력에 포함된 확정 요인 전체 저장
  LOOP AT gt_forecast INTO ls_fc.
    CLEAR lv_fact_no.

    LOOP AT gt_ext_plan INTO DATA(ls_plan) WHERE matnr = ls_fc-matnr.
      ADD 1 TO lv_fact_no.
      CLEAR ls_fact.
      ls_fact-mandt       = sy-mandt.
      ls_fact-fcsno       = pv_fcsno.
      ls_fact-iteno       = ls_fc-iteno.
      ls_fact-factor_no   = lv_fact_no.
      ls_fact-factor_type = '0010'.
      ls_fact-kunnr       = ls_plan-kunnr.
      ls_fact-refno       = ls_plan-plnno.
      ls_fact-source      = ls_plan-source.
      ls_fact-asof_date   = ls_plan-collect_date.
      ls_fact-valid_from  = gv_fc_from.
      ls_fact-valid_to    = gv_fc_to.
      ls_fact-num_value   = ls_plan-change_rate.
      ls_fact-value_unit  = '%'.
      ls_fact-text_value = |계획품목:{ ls_plan-iteno } 수량:{ ls_plan-plan_qty } 방향:{ ls_plan-change_dir }|.
      ls_fact-ernam = sy-uname.
      ls_fact-erdat = sy-datum.
      ls_fact-erzet = sy-uzeit.
      APPEND ls_fact TO pt_factor.
    ENDLOOP.

    LOOP AT gt_ext_event INTO DATA(ls_event) WHERE matnr = ls_fc-matnr.
      ADD 1 TO lv_fact_no.
      CLEAR ls_fact.
      ls_fact-mandt       = sy-mandt.
      ls_fact-fcsno       = pv_fcsno.
      ls_fact-iteno       = ls_fc-iteno.
      ls_fact-factor_no   = lv_fact_no.
      ls_fact-factor_type = '0020'.
      ls_fact-kunnr       = ls_event-kunnr.
      ls_fact-refno       = ls_event-evtno.
      ls_fact-source      = ls_event-source.
      ls_fact-asof_date   = ls_event-collect_date.
      ls_fact-valid_from  = ls_event-valid_from.
      ls_fact-valid_to    = ls_event-valid_to.
      ls_fact-num_value   = ls_event-impact_rate.
      ls_fact-value_unit  = '%'.
      ls_fact-text_value = |Event품목:{ ls_event-iteno } 방향:{ ls_event-impact_dir } 유형:{ ls_event-event_type } { ls_event-event_text }|.
      ls_fact-ernam = sy-uname.
      ls_fact-erdat = sy-datum.
      ls_fact-erzet = sy-uzeit.
      APPEND ls_fact TO pt_factor.
    ENDLOOP.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_next_fcsno
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_FCSNO
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_get_next_fcsno  CHANGING pv_fcsno TYPE ztmma00010-fcsno
                                 pv_error TYPE abap_bool.

  CLEAR: pv_fcsno, pv_error.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'ZDP_FCSNO'
    IMPORTING
      number                  = pv_fcsno
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0 OR pv_fcsno IS INITIAL.
    pv_error = abap_true.
    MESSAGE 'FCSNO 번호 채번 실패: SNRO 설정을 확인해주세요.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_check_workdays
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_exe_check_workdays  CHANGING pv_error TYPE abap_bool.

*  DATA: lv_from TYPE ztcma00160-perio,
*        lv_to   TYPE ztcma00160-perio.
*
*  CLEAR: pv_error, gt_workdays.
*
*  IF gt_history IS INITIAL.
*    RETURN. " 저장될 History 행이 없으면 WRKDY 매핑도 없음
*  ENDIF.
*
*  lv_from = gv_hist_from(6).
*  lv_to   = gv_hist_to(6).
*
*  SELECT *
*    FROM ztcma00160
*    INTO CORRESPONDING FIELDS OF TABLE @gt_workdays
*   WHERE werks = @pa_werks
*     AND perio BETWEEN @lv_from AND @lv_to.
*
*  """ 실제 Snapshot으로 저장할 각 자재/월의 영업일 마스터 필수
*  LOOP AT gt_history INTO DATA(ls_hist).
*
*    READ TABLE gt_workdays INTO DATA(ls_wd) WITH TABLE KEY werks = pa_werks perio = ls_hist-perio.
*
*    IF sy-subrc <> 0 OR ls_wd-wrkdy IS INITIAL.
*      MESSAGE |영업일수 미등록: 플랜트 { pa_werks }, 연월 { ls_hist-perio } (SM30)| TYPE 'S' DISPLAY LIKE 'E'.
*      pv_error = abap_true.
*      RETURN.
*    ENDIF.
*
*  ENDLOOP.

  DATA: lv_month TYPE sy-datum,
        lv_perio TYPE ztcma00160-perio,
        lv_next  TYPE sy-datum,
        ls_wd    TYPE ztcma00160.

  CLEAR: pv_error, gt_workdays.

  """ 분석기간의 영업일수 일괄 조회
  SELECT *
    FROM ztcma00160
    INTO TABLE @gt_workdays
    WHERE werks = @pa_werks
      AND perio BETWEEN @gv_hist_from(6)
                    AND @gv_hist_to(6).

  """ 분석기간 전체 월 검증
  lv_month = gv_hist_from.

  WHILE lv_month <= gv_hist_to.

    lv_perio = lv_month(6).

    CLEAR ls_wd.

    READ TABLE gt_workdays INTO ls_wd WITH TABLE KEY werks = pa_werks
                                                     perio = lv_perio.

    IF sy-subrc <> 0 OR ls_wd-wrkdy IS INITIAL.
      MESSAGE |영업일수 미등록: { pa_werks } / { lv_perio }| TYPE 'S' DISPLAY LIKE 'E'.
      pv_error = abap_true.
      RETURN.
    ENDIF.

    """ 다음 달 1일 계산
    CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
      EXPORTING
        date      = lv_month
        days      = 0
        months    = 1
        signum    = '+'
        years     = 0
      IMPORTING
        calc_date = lv_next.

    lv_month = lv_next.

  ENDWHILE.


ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_deactivate_forecast
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_set_deactivate_forecast  CHANGING pv_error TYPE abap_bool.

*  CLEAR pv_error.
*
*  UPDATE ztmma00010
*     SET activ = @space,
*         aedat = @sy-datum,
*         aezet = @sy-uzeit,
*         aenam = @sy-uname
*   WHERE werks = @pa_werks
*     AND fcdat = @gv_fc_from
*     AND tcdat = @gv_fc_to
*     AND cstat = '0020'
*     AND activ = @abap_true.
*
*  IF sy-subrc <> 0 AND sy-subrc <> 4.
*    pv_error = abap_true.
*  ENDIF.

  CLEAR pv_error.

  TRY.

      """ 동일 플랜트/예측기간의 기존 활성 Forecast 비활성화
      UPDATE ztmma00010
         SET activ = @space,
             aedat = @sy-datum,
             aezet = @sy-uzeit,
             aenam = @sy-uname
       WHERE werks = @pa_werks
         AND fcdat = @gv_fc_from
         AND tcdat = @gv_fc_to
         AND cstat = '0020'
         AND activ = @abap_true.

      """ 기존 활성 Forecast가 없어도 정상
      IF sy-subrc <> 0 AND sy-subrc <> 4.
        pv_error = abap_true.
      ENDIF.

    CATCH cx_sy_open_sql_db INTO DATA(lx_sql).

      pv_error = abap_true.
      MESSAGE lx_sql->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.

  ENDTRY.


ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_empty_history
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_empty_history .

  DATA: lv_month   TYPE sy-datum,
        lv_next    TYPE sy-datum,
        lv_perio   TYPE ztmma00022-perio,
        ls_history TYPE ty_history.

  CHECK gt_forecast IS NOT INITIAL.

  """ 예측 대상 자재별 처리
  LOOP AT gt_forecast INTO DATA(ls_forecast).

    lv_month = gv_hist_from.

    """ 분석 시작월부터 종료월까지 반복
    WHILE lv_month <= gv_hist_to.

      lv_perio = lv_month(6).

      """ 해당 자재/월의 실적 존재 여부
      READ TABLE gt_history TRANSPORTING NO FIELDS WITH KEY matnr = ls_forecast-matnr
                                                            perio = lv_perio.

      IF sy-subrc <> 0.
        CLEAR ls_history.
        ls_history-matnr = ls_forecast-matnr.
        ls_history-perio = lv_perio.
        ls_history-meins = ls_forecast-meins.
        """ SOQTY/GIQTY/GAPQTY는 0으로 유지
        APPEND ls_history TO gt_history.
      ENDIF.

      """ 다음 달 1일 계산
      CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
        EXPORTING
          date      = lv_month
          days      = 0
          months    = 1
          signum    = '+'
          years     = 0
        IMPORTING
          calc_date = lv_next.

      lv_month = lv_next.

    ENDWHILE.

  ENDLOOP.

  SORT gt_history BY matnr perio.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_lock_forecast
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_exe_lock_forecast  CHANGING pv_error TYPE abap_bool.

  CLEAR pv_error.

  CALL FUNCTION 'ENQUEUE_EZDP21_SCOPE'
    EXPORTING
      mode_ztmma00024 = 'E'
      mandt           = sy-mandt
      werks           = pa_werks
      fcdat           = gv_fc_from
      tcdat           = gv_fc_to
      _scope          = '1'
      _wait           = space
    EXCEPTIONS
      foreign_lock    = 1
      system_failure  = 2
      OTHERS          = 3.

  CASE sy-subrc.
    WHEN 0.
      " 잠금 획득 성공

    WHEN 1.
      pv_error = abap_true.
      MESSAGE '다른 사용자가 동일 기간의 수요예측을 저장 중입니다.' TYPE 'S' DISPLAY LIKE 'E'.

    WHEN OTHERS.
      pv_error = abap_true.
      MESSAGE '수요예측 저장 잠금을 설정하지 못했습니다.' TYPE 'S' DISPLAY LIKE 'E'.

  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_unlock_forecast
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_unlock_forecast .

  CALL FUNCTION 'DEQUEUE_EZDP21_SCOPE'
    EXPORTING
      mode_ztmma00024 = 'E'
      mandt           = sy-mandt
      werks           = pa_werks
      fcdat           = gv_fc_from
      tcdat           = gv_fc_to
      _scope          = '1'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_confirm_ai
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ANSWER
*&---------------------------------------------------------------------*
FORM zz_exe_confirm_ai  CHANGING pv_answer TYPE c.

  DATA: lv_question TYPE string.
  CLEAR pv_answer.

  IF gv_ai_done = abap_true.
    lv_question = 'AI를 다시 실행하면 기존 예측 결과와 조정수량이 초기화됩니다. 계속하시겠습니까?'.
  ELSE.
    lv_question = 'AI 수요예측을 실행하시겠습니까?'.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'AI 수요예측 실행'
      text_question         = lv_question
      text_button_1         = '실행'
      text_button_2         = '취소'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = pv_answer.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_ai_codes
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_ai_codes .

  CLEAR gt_ai_code.

  SELECT cdval, cdnam
    FROM ztcma00080
   WHERE cdgrp = 'DP_AI'
    INTO TABLE @gt_ai_code.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_status_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_status_text .

  LOOP AT gt_forecast ASSIGNING FIELD-SYMBOL(<fs_forecast>).

    CLEAR <fs_forecast>-aistat_text.

    READ TABLE gt_ai_code INTO DATA(ls_code)
      WITH TABLE KEY cdval = <fs_forecast>-aistat.

    IF sy-subrc = 0.
      <fs_forecast>-aistat_text = ls_code-cdnam.
    ELSE.
      <fs_forecast>-aistat_text = <fs_forecast>-aistat.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_show_kpi
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_show_kpi .

  DATA: lt_widget TYPE zcl_cm_kpi_html=>tt_widget,
        lv_total  TYPE i,
        lv_succ   TYPE i,
        lv_perio  TYPE char7,
        lv_status TYPE char20.

  """ 대상 자재수
  lv_total = lines( gt_forecast ).

  """ AI 성공 건수
  LOOP AT gt_forecast TRANSPORTING NO FIELDS
    WHERE aistat = '0030'.
    lv_succ = lv_succ + 1.
  ENDLOOP.

  """ 예측 대상월 YYYY.MM
  lv_perio = |{ gv_fc_from+0(4) }.{ gv_fc_from+4(2) }|.

  """ 확정 여부
  IF gv_confirm = abap_true.
    lv_status = '확정'.
  ELSE.
    lv_status = '미확정'.
  ENDIF.

  """ 예측 대상월
  APPEND zcl_cm_kpi_html=>w_card(
    iv_label = '예측 대상월'
    iv_value = |{ lv_perio }|
    iv_sub   = '기준월 다음 달'
    iv_color = 'B' ) TO lt_widget.

  """ 대상 자재수
  APPEND zcl_cm_kpi_html=>w_card(
    iv_label = '대상 자재'
    iv_value = |{ lv_total }건|
    iv_sub   = '수요 발생 자재'
    iv_color = 'B' ) TO lt_widget.

  """ AI 성공 건수
  APPEND zcl_cm_kpi_html=>w_card(
    iv_label = 'AI 예측 성공'
    iv_value = |{ lv_succ }건|
    iv_sub   = |전체 { lv_total }건|
    iv_color = COND #(
      WHEN gv_ai_done = abap_true
      THEN 'G'
      ELSE 'N' ) ) TO lt_widget.

  """ 확정 상태
  APPEND zcl_cm_kpi_html=>w_card(
    iv_label = '확정 상태'
    iv_value = |{ lv_status }|
    iv_sub   = '담당자 최종 검토'
    iv_color = COND #(
      WHEN gv_confirm = abap_true
      THEN 'G'
      ELSE 'Y' ) ) TO lt_widget.

  """ HTML 출력
  go_kpi->show_widgets(
    it_widget = lt_widget
    iv_title  = |AI 수요예측 현황 - 플랜트 { pa_werks }| ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_ai_failed
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_ai_failed .

  """ AI 실행 완료 플래그 해제
  gv_ai_done = abap_false.

  """ AI 실행일시 초기화
  CLEAR: gv_ai_date, gv_ai_time.

  """ 전체 예측 대상 실패 상태 설정
  LOOP AT gt_forecast ASSIGNING FIELD-SYMBOL(<fs_fc>).

    <fs_fc>-aistat = '0040'.

    CLEAR: <fs_fc>-aiqty,
           <fs_fc>-aireason,
           <fs_fc>-reason_link,
           <fs_fc>-adqty,
           <fs_fc>-fiqty.

  ENDLOOP.

  """ ZTCMA00080 상태명 갱신
  PERFORM zz_set_status_text.

  """ 실패 상태이므로 조정수량 편집 비활성화
  PERFORM zz_exe_update_fcat.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_confirm_save
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ANSWER
*&---------------------------------------------------------------------*
FORM zz_exe_confirm_save  CHANGING pv_answer TYPE c.

  DATA: lv_count    TYPE i,
        lv_question TYPE string.

  CLEAR pv_answer.

  """ 동일 플랜트/예측기간의 기존 활성 예측 확인
  SELECT COUNT(*)
    FROM ztmma00010
    WHERE werks = @pa_werks
      AND fcdat = @gv_fc_from
      AND tcdat = @gv_fc_to
      AND cstat = '0020'
      AND activ = @abap_true
    INTO @lv_count.

  IF lv_count > 0.

    lv_question = '기존 활성 수요예측이 있습니다. 새 예측을 확정하면 기존 예측은 비활성화됩니다. 계속하시겠습니까?'.

  ELSE.

    lv_question = '검토한 AI 예측 결과와 조정수량을 최종 저장 및 확정하시겠습니까?'.

  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '수요예측 저장 및 확정'
      text_question         = lv_question
      text_button_1         = '확정'
      text_button_2         = '취소'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = pv_answer.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_exe_confirm_exit
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_EXIT
*&---------------------------------------------------------------------*
FORM zz_exe_confirm_exit  CHANGING pv_exit TYPE abap_bool.

  DATA lv_answer TYPE c.

  pv_exit = abap_true.

  """ 확정하지 않은 AI 실행 결과가 있는 경우
  IF gv_ai_done = abap_true
     AND gv_confirm <> abap_true.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = '미저장 수요예측 확인'
        text_question         = '확정하지 않은 AI 예측 결과가 있습니다. 저장하지 않고 종료하시겠습니까?'
        text_button_1         = '종료'
        text_button_2         = '돌아가기'
        default_button        = '2'
        display_cancel_button = space
      IMPORTING
        answer                = lv_answer.

    IF lv_answer <> zlea_1.
      pv_exit = abap_false.
    ENDIF.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_free_main
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_free_main .

  """ ALV Grid 해제
  IF go_grid IS BOUND.
    go_grid->free( ).
    CLEAR go_grid.
  ENDIF.

  """ ALV Container 해제
  IF go_cont IS BOUND.
    go_cont->free( ).
    CLEAR go_cont.
  ENDIF.

  """ KPI HTML 해제
  IF go_kpi IS BOUND.
    go_kpi->free( ).
    CLEAR go_kpi.
  ENDIF.

  """ KPI Container 해제
  IF go_kpi_cont IS BOUND.
    go_kpi_cont->free( ).
    CLEAR go_kpi_cont.
  ENDIF.

  CLEAR go_event.

  cl_gui_cfw=>flush( ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_plant_material
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_plant_material .

  TYPES: BEGIN OF ty_material,
           matnr TYPE ztcma00030-matnr,
           meins TYPE ztcma00030-meins,
         END OF ty_material.

  DATA: lt_material TYPE HASHED TABLE OF ty_material
                    WITH UNIQUE KEY matnr,
        lv_iteno    TYPE i.

  """ 선택 플랜트의 활성 관리 자재 조회
  SELECT matnr, meins
    FROM ztcma00030
    WHERE werks = @pa_werks
      AND actyn = @zlea_y
    INTO TABLE @lt_material.

  """ 플랜트 관리 대상이 아닌 자재 제외
  LOOP AT gt_forecast ASSIGNING
    FIELD-SYMBOL(<fs_forecast>).

    READ TABLE lt_material INTO DATA(ls_material)
      WITH TABLE KEY matnr = <fs_forecast>-matnr.

    IF sy-subrc <> 0.
      DELETE gt_forecast.
      CONTINUE.
    ENDIF.

    """ 플랜트별 자재 기본 단위 적용
    <fs_forecast>-meins = ls_material-meins.

  ENDLOOP.

  """ 예측 대상에서 제외된 자재의 과거 실적 제거
  LOOP AT gt_history INTO DATA(ls_history).

    READ TABLE gt_forecast TRANSPORTING NO FIELDS
      WITH KEY matnr = ls_history-matnr.

    IF sy-subrc <> 0.
      DELETE gt_history.
    ENDIF.

  ENDLOOP.

  """ Item 번호 재부여
  CLEAR lv_iteno.

  SORT gt_forecast BY matnr.

  LOOP AT gt_forecast ASSIGNING <fs_forecast>.
    lv_iteno = lv_iteno + 10.
    <fs_forecast>-iteno = lv_iteno.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_update_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_update_fcat .

  CHECK go_grid IS BOUND.

  """ 현재 AI/확정 상태에 따라 Field Catalog 재구성
  PERFORM zz_set_field_catalog.

  """ 변경된 Field Catalog를 ALV Grid에 반영
  go_grid->set_frontend_fieldcatalog(
    EXPORTING
      it_fieldcatalog = gt_fcat ).

  """ ALV 화면 갱신
  PERFORM zz_exe_refresh_alv.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_CHECK_EXTERNAL_FACTOR
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_check_external_factor CHANGING pv_error TYPE abap_bool.

  DATA: ls_fc     TYPE ty_forecast,
        ls_plan   TYPE ty_ext_plan,
        ls_event  TYPE ty_ext_event,
        lv_answer TYPE c.

  CLEAR pv_error.

  " 생산계획 단위 검증
  LOOP AT gt_ext_plan INTO ls_plan.

    READ TABLE gt_forecast INTO ls_fc WITH KEY matnr = ls_plan-matnr.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF ls_plan-meins <> ls_fc-meins.

      pv_error = abap_true.

      MESSAGE
        |{ ls_plan-matnr }: 생산계획 단위와 자재 기본 단위가 일치하지 않습니다.|
        TYPE 'S' DISPLAY LIKE 'E'.

      RETURN.

    ENDIF.

  ENDLOOP.

  " PLAN / Event 중복 가능성 검토
  LOOP AT gt_ext_plan INTO ls_plan.

    LOOP AT gt_ext_event INTO ls_event WHERE matnr = ls_plan-matnr
        AND kunnr = ls_plan-kunnr AND colno = ls_plan-colno.

      " 동일 변경 가능성이 있는 생산계획 변경 Event
      IF ls_event-event_type = '0030'
         AND ls_event-impact_dir = ls_plan-change_dir
         AND ls_event-impact_rate = ls_plan-change_rate.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = '외부요인 중복 가능성 확인'
            text_question         =
                                    '동일 수집문서에 유사한 생산계획과 Event가 있습니다. 검토 후 AI 예측을 계속하시겠습니까?'
            text_button_1         = '계속'
            text_button_2         = '취소'
            default_button        = '2'
            display_cancel_button = space
          IMPORTING
            answer                = lv_answer.

        IF lv_answer <> zlea_1.
          pv_error = abap_true.
          RETURN.
        ENDIF.

        " 현재는 의심 여부만 안내하고 자동 제외하지 않음
        EXIT.

      ENDIF.

    ENDLOOP.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_SET_FACTOR_COUNT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_factor_count.

  LOOP AT gt_forecast ASSIGNING FIELD-SYMBOL(<fs_forecast>).

    CLEAR: <fs_forecast>-plan_count, <fs_forecast>-event_count.

    LOOP AT gt_ext_plan TRANSPORTING NO FIELDS WHERE matnr = <fs_forecast>-matnr.
      <fs_forecast>-plan_count = <fs_forecast>-plan_count + 1.
    ENDLOOP.

    LOOP AT gt_ext_event TRANSPORTING NO FIELDS WHERE matnr = <fs_forecast>-matnr.
      <fs_forecast>-event_count = <fs_forecast>-event_count + 1.
    ENDLOOP.

  ENDLOOP.

ENDFORM.
