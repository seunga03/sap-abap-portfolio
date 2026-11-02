"&---------------------------------------------------------------------*
"& INCLUDE          zlsda00010_f01
"&---------------------------------------------------------------------*


FORM show_valid_kpi.
  DATA lt_w TYPE zcl_cm_kpi_html=>tt_widget.

  IF go_kpi IS INITIAL.
    CREATE OBJECT go_kpi_cc EXPORTING container_name = 'CC_KPI'.
    CREATE OBJECT go_kpi EXPORTING io_parent = go_kpi_cc.
  ENDIF.

  APPEND zcl_cm_kpi_html=>w_card( iv_label = '전체'
         iv_value = |{ gv_total_cnt }건| iv_color = 'B' ) TO lt_w.
  APPEND zcl_cm_kpi_html=>w_card( iv_label = '주문 가능'
         iv_value = |{ gv_success_cnt }건| iv_sub = '재고 충분' iv_color = 'G' ) TO lt_w.
  APPEND zcl_cm_kpi_html=>w_card( iv_label = 'PR 필요'
         iv_value = |{ gv_procure_cnt }건| iv_sub = '부족분 구매요청' iv_color = 'Y' ) TO lt_w.
  APPEND zcl_cm_kpi_html=>w_card( iv_label = '오류'
         iv_value = |{ gv_error_cnt }건| iv_sub = '생성 불가' iv_color = 'R' ) TO lt_w.

  go_kpi->show_widgets( it_widget = lt_w iv_title = '주문 검증 요약' ).
ENDFORM.


"&---------------------------------------------------------------------*
"& FORM set_toolbar_exclude
"&---------------------------------------------------------------------*
" ALV 표준 편집 버튼 숨김 (SD02~04와 동일)
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
"& FORM delete_valid_rows
"&---------------------------------------------------------------------*
FORM delete_valid_rows.

  DATA:
    lt_rows TYPE lvc_t_row,
    ls_row  TYPE lvc_s_row.

  CLEAR lt_rows.

  IF go_valid_grid IS BOUND.

    CALL METHOD go_valid_grid->get_selected_rows
      IMPORTING
        et_index_rows = lt_rows.

  ENDIF.

  IF lt_rows IS INITIAL.

    MESSAGE i021(zmsga) WITH '삭제할 검증결과'.

    RETURN.

  ENDIF.

"---------------------------------------------------------------------*
" 뒤쪽 행부터 삭제
"---------------------------------------------------------------------*
  SORT lt_rows
    BY index DESCENDING.

  LOOP AT lt_rows
    INTO ls_row.

    DELETE gt_valid_result
      INDEX ls_row-index.

  ENDLOOP.

"---------------------------------------------------------------------*
" 행번호(No)는 재정렬하지 않음 → 엑셀 원래 행번호 유지
"---------------------------------------------------------------------*

"---------------------------------------------------------------------*
" 남은 주문 전체 재검증
"---------------------------------------------------------------------*
  LOOP AT gt_valid_result
    ASSIGNING FIELD-SYMBOL(<ls_recheck>).

"   기본검증 오류행은 입력값이 그대로라 결과도 그대로 → 다시 돌리지 않음
    IF <ls_recheck>-basic_ok = 'N'.
      CONTINUE.
    ENDIF.

    CLEAR:
      <ls_recheck>-error_field,
      <ls_recheck>-result_text.

    PERFORM validate_order
      CHANGING
        <ls_recheck>.

    PERFORM set_valid_row_color
      CHANGING
        <ls_recheck>.

  ENDLOOP.

  PERFORM calculate_validation_count.

" KPI 카드(전체/주문가능/PR필요/오류)도 같이 갱신
  PERFORM show_valid_kpi.

  PERFORM save_valid_memory.

  IF go_valid_grid IS BOUND.

    CALL METHOD go_valid_grid->refresh_table_display.

    PERFORM clear_valid_selection.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM save_valid_memory
"&---------------------------------------------------------------------*
FORM save_valid_memory.

  EXPORT
    gt_valid_result = gt_valid_result
    TO MEMORY ID gc_mem_valid.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM load_valid_memory
"&---------------------------------------------------------------------*
FORM load_valid_memory.

  CLEAR:
    gt_valid_result,
    gs_valid_result.

  IMPORT
    gt_valid_result = gt_valid_result
    FROM MEMORY ID gc_mem_valid.

  IF gt_valid_result IS NOT INITIAL.

    PERFORM calculate_validation_count.

  ELSE.

    CLEAR:
      gv_total_cnt,
      gv_success_cnt,
      gv_procure_cnt,
      gv_error_cnt.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM clear_valid_memory
"&---------------------------------------------------------------------*
FORM clear_valid_memory.

  FREE MEMORY ID gc_mem_valid.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM validate_so_search_condition
"&---------------------------------------------------------------------*
" 판매오더 조회조건 검사
"----------------------------------------------------------------------*
" 오류 시 E 메시지 대신 S + DISPLAY LIKE 'E' → 입력칸이 잠기지 않고 같은 화면 유지
FORM validate_so_search_condition.

  DATA:
    lv_vbeln TYPE ztsda00010-vbeln,
    lv_kunnr TYPE ztcma00050-kunnr.

"---------------------------------------------------------------------*
" 조회조건 필수 : 판매오더번호 / 고객번호 / 주문일자 중 하나는 있어야 함
" (조건 없이 전체 조회 방지)
"---------------------------------------------------------------------*
  IF gv_so_vbeln    IS INITIAL
  AND gv_so_kunnr    IS INITIAL
  AND gv_so_audat_fr IS INITIAL
  AND gv_so_audat_to IS INITIAL.

    MESSAGE s020(zmsga) DISPLAY LIKE 'E' WITH '판매오더번호, 고객번호 또는 주문일자'.
    LEAVE TO SCREEN sy-dynnr.

  ENDIF.

"---------------------------------------------------------------------*
" 판매오더번호 존재 여부
"---------------------------------------------------------------------*
  IF gv_so_vbeln IS NOT INITIAL.

    CLEAR lv_vbeln.

    SELECT SINGLE vbeln
      FROM ztsda00010
      WHERE vbeln = @gv_so_vbeln
      INTO @lv_vbeln.

    IF sy-subrc <> 0.

      MESSAGE s034(zmsga) DISPLAY LIKE 'E' WITH '판매오더번호'.
      LEAVE TO SCREEN sy-dynnr.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 고객번호 형식 검사
"---------------------------------------------------------------------*
  IF gv_so_kunnr IS NOT INITIAL.

    IF strlen( gv_so_kunnr ) <> 10.

      MESSAGE s023(zmsga) DISPLAY LIKE 'E' WITH '고객번호'.
      LEAVE TO SCREEN sy-dynnr.

    ENDIF.

    IF gv_so_kunnr+0(1) <> 'C'.

      MESSAGE s023(zmsga) DISPLAY LIKE 'E' WITH '고객번호(C로 시작)'.
      LEAVE TO SCREEN sy-dynnr.

    ENDIF.

    IF gv_so_kunnr+1(9) CN '0123456789'.

      MESSAGE s023(zmsga) DISPLAY LIKE 'E' WITH '고객번호'.
      LEAVE TO SCREEN sy-dynnr.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 고객번호 존재 여부
" 조회는 거래정지/종료 고객의 과거 판매오더도 볼 수 있어야 하므로 존재만 확인
"---------------------------------------------------------------------*
  IF gv_so_kunnr IS NOT INITIAL.

    CLEAR lv_kunnr.

    SELECT SINGLE kunnr
      FROM ztcma00050
      WHERE kunnr = @gv_so_kunnr
      INTO @lv_kunnr.

    IF sy-subrc <> 0.

      MESSAGE s034(zmsga) DISPLAY LIKE 'E' WITH '고객번호'.
      LEAVE TO SCREEN sy-dynnr.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 주문일자 From 검사
"---------------------------------------------------------------------*
  IF gv_so_audat_fr IS NOT INITIAL.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gv_so_audat_fr
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.

    IF sy-subrc <> 0.

      MESSAGE s022(zmsga) DISPLAY LIKE 'E' WITH '주문일자 시작일'.
      LEAVE TO SCREEN sy-dynnr.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 주문일자 To 검사
"---------------------------------------------------------------------*
  IF gv_so_audat_to IS NOT INITIAL.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gv_so_audat_to
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.

    IF sy-subrc <> 0.

      MESSAGE s022(zmsga) DISPLAY LIKE 'E' WITH '주문일자 종료일'.
      LEAVE TO SCREEN sy-dynnr.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 주문일자 범위 검사
"---------------------------------------------------------------------*
  IF gv_so_audat_fr IS NOT INITIAL
     AND gv_so_audat_to IS NOT INITIAL
     AND gv_so_audat_fr > gv_so_audat_to.

    MESSAGE s026(zmsga) DISPLAY LIKE 'E'.
    LEAVE TO SCREEN sy-dynnr.

  ENDIF.

"---------------------------------------------------------------------*
" 판매오더번호 + 고객번호 조합 검사
"---------------------------------------------------------------------*
  IF gv_so_vbeln IS NOT INITIAL
     AND gv_so_kunnr IS NOT INITIAL.

    CLEAR lv_vbeln.

    SELECT SINGLE vbeln
      FROM ztsda00010
      WHERE vbeln = @gv_so_vbeln
        AND kunnr = @gv_so_kunnr
      INTO @lv_vbeln.

    IF sy-subrc <> 0.

      MESSAGE s041(zmsga) DISPLAY LIKE 'E'.
      LEAVE TO SCREEN sy-dynnr.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 판매오더번호 + 주문일자 조건 검사
"---------------------------------------------------------------------*
  IF gv_so_vbeln IS NOT INITIAL
     AND ( gv_so_audat_fr IS NOT INITIAL
        OR gv_so_audat_to IS NOT INITIAL ).

    CLEAR lv_vbeln.

    SELECT SINGLE vbeln
      FROM ztsda00010
      WHERE vbeln = @gv_so_vbeln
        AND ( @gv_so_audat_fr IS INITIAL
           OR audat >= @gv_so_audat_fr )
        AND ( @gv_so_audat_to IS INITIAL
           OR audat <= @gv_so_audat_to )
      INTO @lv_vbeln.

    IF sy-subrc <> 0.

" 판매오더는 있으나 조회 기간 밖 (고객번호 불일치 메시지와 구분)
      MESSAGE s255(zmsga) DISPLAY LIKE 'E'.
      LEAVE TO SCREEN sy-dynnr.

    ENDIF.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM control_input_mode
"&---------------------------------------------------------------------*
FORM control_input_mode.

  LOOP AT SCREEN.

    CASE screen-group1.

"---------------------------------------------------------------------*
" 단건입력 항목
"---------------------------------------------------------------------*
      WHEN 'SIN'.

        IF p_single = abap_true.

          screen-input  = 1.
          screen-active = 1.

        ELSE.
          screen-input  = 0.
          screen-active = 1.

        ENDIF.

"---------------------------------------------------------------------*
" Excel Upload 항목
"---------------------------------------------------------------------*
      WHEN 'EXL'.

        IF p_excel = abap_true.

          screen-input  = 1.
          screen-active = 1.

        ELSE.

          screen-input  = 0.
          screen-active = 1.

        ENDIF.

"---------------------------------------------------------------------*
" 자동 표시 항목
"---------------------------------------------------------------------*
      WHEN 'DSP'.

        screen-input  = 0.
        screen-active = 1.

    ENDCASE.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM select_excel_file
"&---------------------------------------------------------------------*
FORM select_excel_file.

  DATA:
    lt_filetab TYPE filetable,
    ls_filetab TYPE file_table,
    lv_rc      TYPE i.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title   = '주문 Excel 파일 선택'
      file_filter    = 'Excel Files (*.xlsx;*.xls)|*.xlsx;*.xls|'
      multiselection = abap_false
    CHANGING
      file_table     = lt_filetab
      rc             = lv_rc
    EXCEPTIONS
      OTHERS         = 1.

  IF sy-subrc <> 0
  OR lv_rc = 0.

    RETURN.

  ENDIF.

  READ TABLE lt_filetab
  INTO ls_filetab
  INDEX 1.

  IF sy-subrc = 0.

    p_file = ls_filetab-filename.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM refresh_order_input
"&---------------------------------------------------------------------*
FORM refresh_order_input.

  CLEAR:
    p_kunnr,
    p_name1,
    p_matnr,
    p_maktx,
    p_kmeng,
    p_reqfr,
    p_reqto,
    p_werks,
    p_lgort,
    p_file,
    gv_meins,
    gv_last_matnr.

  p_reqfr = sy-datum.

  CLEAR:
    gt_excel_raw,
    gs_excel_raw,
    gt_valid_result,
    gs_valid_result,
    gv_total_cnt,
    gv_success_cnt,
    gv_procure_cnt,
    gv_error_cnt.

  PERFORM clear_valid_memory.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM set_function_key
"&---------------------------------------------------------------------*
FORM set_function_key.

"---------------------------------------------------------------------*
" FC01 : 새로고침
"---------------------------------------------------------------------*
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name   = icon_refresh
      text   = ''
      info   = '입력값 초기화'
    IMPORTING
      result = sscrfields-functxt_01.

"---------------------------------------------------------------------*
" FC02 : 템플릿 다운로드
"---------------------------------------------------------------------*
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name   = icon_xls
      text   = '템플릿 다운로드'
      info   = '주문 양식 다운로드'
    IMPORTING
      result = sscrfields-functxt_02.

"---------------------------------------------------------------------*
" FC03 : 기존 검증결과 보기
"---------------------------------------------------------------------*
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name   = icon_display
      text   = '검증결과'
      info   = '기존 주문 검증결과 보기'
    IMPORTING
      result = sscrfields-functxt_03.

"---------------------------------------------------------------------*
" FC04 : 판매오더 조회 화면 이동
"---------------------------------------------------------------------*
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name   = icon_xlv
      text   = '판매오더'
      info   = '판매오더 조회 화면으로 이동'
    IMPORTING
      result = sscrfields-functxt_04.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM set_auto_display
"&---------------------------------------------------------------------*
FORM set_auto_display.

  CLEAR:
    p_maktx,
    gv_meins,
    p_werks,
    p_lgort.

  IF p_matnr IS NOT INITIAL.

    SELECT SINGLE
      maktx,
      meins
      FROM ztcma00020
      WHERE matnr = @p_matnr
      INTO (@p_maktx, @gv_meins).

    IF sy-subrc = 0.

      PERFORM determine_stock_location.

    ENDIF.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM download_template
"&---------------------------------------------------------------------*
FORM download_template.

  DATA:
    ls_wwwdata  TYPE wwwdatatab,
    lv_filename TYPE string,
    lv_path     TYPE string,
    lv_fullpath TYPE string,
    lv_action   TYPE i,
    lv_dest     TYPE rlgrap-filename,
    lv_rc       TYPE sy-subrc.

  CLEAR ls_wwwdata.

  SELECT SINGLE
  relid,
  objid
  FROM wwwdata
  WHERE relid = 'MI'
  AND objid = 'ZTTEOKIP_SO_TEMPLATE'
  AND srtf2 = 0
  INTO CORRESPONDING FIELDS OF @ls_wwwdata.

  IF sy-subrc <> 0.

    MESSAGE i042(zmsga) WITH '주문서 템플릿'.

    RETURN.

  ENDIF.

  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      window_title              = '주문서 템플릿 다운로드'
      default_extension         = 'xlsx'
      default_file_name         = '고객사명_떡잎반도체_주문서.xlsx'
      file_filter               = 'Excel Files (*.xlsx)|*.xlsx|'
    CHANGING
      filename                  = lv_filename
      path                      = lv_path
      fullpath                  = lv_fullpath
      user_action               = lv_action
    EXCEPTIONS
      cntl_error                = 1
      error_no_gui              = 2
      not_supported_by_gui      = 3
      invalid_default_file_name = 4
      OTHERS                    = 5.

  IF sy-subrc <> 0
  OR lv_action <> cl_gui_frontend_services=>action_ok.

    RETURN.

  ENDIF.

  lv_dest = lv_fullpath.

  CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
    EXPORTING
      key         = ls_wwwdata
      destination = lv_dest
    IMPORTING
      rc          = lv_rc.

  IF lv_rc <> 0.

    MESSAGE i067(zmsga) WITH '템플릿 다운로드'.

    RETURN.

  ENDIF.

  MESSAGE s000(zmsga).

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM add_valid_error
"&---------------------------------------------------------------------*
FORM add_valid_error
USING
pv_field TYPE char50
pv_text  TYPE char200
CHANGING
cs_result TYPE ty_valid_result.

  cs_result-basic_ok = 'N'.

  IF cs_result-error_field IS INITIAL.

    cs_result-error_field = pv_field.

  ELSE.

    CONCATENATE
    cs_result-error_field
    pv_field
    INTO cs_result-error_field
    SEPARATED BY ' / '.

  ENDIF.

  IF cs_result-result_text IS INITIAL.

    cs_result-result_text = pv_text.

  ELSE.

    CONCATENATE
    cs_result-result_text
    pv_text
    INTO cs_result-result_text
    SEPARATED BY ' / '.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM validate_single_order
"&---------------------------------------------------------------------*
FORM validate_single_order.

  DATA:
    lv_row_no TYPE i,
    ls_exist  TYPE ty_valid_result.

  CLEAR gs_valid_result.

"---------------------------------------------------------------------*
" 행번호 = 현재 가장 큰 No + 1 (삭제 후에도 번호가 겹치지 않도록)
"---------------------------------------------------------------------*
  CLEAR lv_row_no.

  LOOP AT gt_valid_result INTO DATA(ls_max_row).
    IF ls_max_row-row_no > lv_row_no.
      lv_row_no = ls_max_row-row_no.
    ENDIF.
  ENDLOOP.

  lv_row_no = lv_row_no + 1.

  gs_valid_result-row_no = lv_row_no.

  gs_valid_result-kunnr  = p_kunnr.
  gs_valid_result-matnr  = p_matnr.
  gs_valid_result-kwmeng = p_kmeng.

"---------------------------------------------------------------------*
" 요청납기일
"---------------------------------------------------------------------*
  IF p_reqto IS NOT INITIAL.

    gs_valid_result-reqdt = p_reqto.

  ELSE.

    gs_valid_result-reqdt = p_reqfr.

  ENDIF.

"---------------------------------------------------------------------*
" 동일 주문 중복 검사
"---------------------------------------------------------------------*
  CLEAR ls_exist.

  READ TABLE gt_valid_result
    INTO ls_exist
    WITH KEY
      kunnr  = gs_valid_result-kunnr
      matnr  = gs_valid_result-matnr
      kwmeng = gs_valid_result-kwmeng
      reqdt  = gs_valid_result-reqdt.

  IF sy-subrc = 0.

    MESSAGE i032(zmsga).

    RETURN.

  ENDIF.

"---------------------------------------------------------------------*
" 요청납기일 From / To 범위 검증
"---------------------------------------------------------------------*
  IF p_reqfr IS NOT INITIAL
     AND p_reqto IS NOT INITIAL
     AND p_reqfr > p_reqto.

    PERFORM add_valid_error
      USING
        '요청납기일'
        '요청납기 시작일은 종료일보다 클 수 없습니다.'
      CHANGING
        gs_valid_result.

    gs_valid_result-order_ok = 'N'.
    gs_valid_result-status   = icon_led_red.

  ELSE.

    PERFORM validate_order
      CHANGING
        gs_valid_result.

  ENDIF.

  p_werks = gs_valid_result-werks.
  p_lgort = gs_valid_result-lgort.

" 단건 입력도 엑셀 업로드와 같은 색상 적용
  PERFORM set_valid_row_color
    CHANGING
      gs_valid_result.

  APPEND gs_valid_result
    TO gt_valid_result.

  PERFORM calculate_validation_count.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM validate_order
"&---------------------------------------------------------------------*
"& 1차 : 기본 유효성 검증
"& 2차 : 재고 / Lead Time / 주문 가능 여부
"&---------------------------------------------------------------------*
FORM validate_order
CHANGING
cs_result TYPE ty_valid_result.

  DATA:
    lv_unitp       TYPE ztcma00060-unitp,
    lv_disrt       TYPE ztcma00060-disrt,
    lv_taxrt       TYPE ztcma00060-taxrt,
    lv_waers       TYPE ztcma00060-waers,
    lv_vkorg       TYPE ztcma00060-vkorg,
    lv_vtweg       TYPE ztcma00060-vtweg,

    lv_stqty       TYPE ztmma00070-stqty,
    lv_rsqty       TYPE ztmma00070-rsqty,

    lv_pending_qty TYPE ztsda00020-kwmeng,

    lv_lifnr       TYPE ztcma00040-lifnr,
    lv_plifz       TYPE ztcma00040-plifz,

    lv_material_ok TYPE abap_bool.


  IF cs_result-basic_ok IS INITIAL.
    cs_result-basic_ok = 'Y'.
  ENDIF.

  CLEAR:
  cs_result-order_ok,
  cs_result-procure_need,
  cs_result-status,
  cs_result-stqty,
  cs_result-rsqty,
  cs_result-avqty,
  cs_result-shiqty,
  cs_result-lifnr,
  cs_result-plifz,
  cs_result-expdt,
  cs_result-dup_vbeln.


"*********************************************************************
" 1차 검증
"*********************************************************************

"---------------------------------------------------------------------*
" 고객번호
"---------------------------------------------------------------------*
  IF cs_result-kunnr IS INITIAL.

    PERFORM add_valid_error
    USING
    '고객번호'
    '고객번호를 입력해 주십시오.'
    CHANGING
    cs_result.

  ELSE.

    SELECT SINGLE
    name1
    FROM ztcma00050
    WHERE kunnr = @cs_result-kunnr
    AND trdyn = 'Y'
    AND blkyn = 'N'
    AND actyn = 'Y'
    INTO @cs_result-name1.

    IF sy-subrc <> 0.

      PERFORM add_valid_error
      USING
      '고객번호'
      '거래 가능한 고객이 아닙니다.'
      CHANGING
      cs_result.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 자재번호
"---------------------------------------------------------------------*
  IF cs_result-matnr IS INITIAL.

    PERFORM add_valid_error
    USING
    '자재번호'
    '자재번호를 입력해 주십시오.'
    CHANGING
    cs_result.

    lv_material_ok = abap_false.

  ELSE.

    SELECT SINGLE
    maktx,
    meins
    FROM ztcma00020
    WHERE matnr = @cs_result-matnr
    AND slsyn = 'Y'
    AND actyn = 'Y'
    INTO
    (@cs_result-maktx,
    @cs_result-meins).

    IF sy-subrc <> 0.

      PERFORM add_valid_error
      USING
      '자재번호'
      '판매 가능한 자재가 아닙니다.'
      CHANGING
      cs_result.

      lv_material_ok = abap_false.

    ELSE.

      lv_material_ok = abap_true.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 자재가 정상일 때만 플랜트 / 저장위치 자동 결정
"---------------------------------------------------------------------*
  IF lv_material_ok = abap_true.

    PERFORM determine_order_location
    CHANGING
    cs_result.

    IF cs_result-werks IS INITIAL.

      PERFORM add_valid_error
      USING
      '플랜트'
      '자재의 플랜트를 결정할 수 없습니다.'
      CHANGING
      cs_result.

    ELSE.

      SELECT SINGLE
      werks
      FROM ztcma00140
      WHERE werks = @cs_result-werks
      AND actyn = 'Y'
      INTO @DATA(lv_werks).

      IF sy-subrc <> 0.

        PERFORM add_valid_error
        USING
        '플랜트'
        '유효한 플랜트가 아닙니다.'
        CHANGING
        cs_result.

      ENDIF.

    ENDIF.

    IF cs_result-lgort IS INITIAL.

      PERFORM add_valid_error
      USING
      '저장위치'
      '자재의 저장위치를 결정할 수 없습니다.'
      CHANGING
      cs_result.

    ELSE.

      SELECT SINGLE
      lgort
      FROM ztcma00150
      WHERE lgort = @cs_result-lgort
      AND werks = @cs_result-werks
      INTO @DATA(lv_lgort).

      IF sy-subrc <> 0.

        PERFORM add_valid_error
        USING
        '저장위치'
        '해당 플랜트의 유효한 저장위치가 아닙니다.'
        CHANGING
        cs_result.

      ENDIF.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 주문수량
"---------------------------------------------------------------------*
  IF cs_result-error_field NS '주문수량'.

    IF cs_result-kwmeng IS INITIAL
    OR cs_result-kwmeng <= 0.

      PERFORM add_valid_error
      USING
      '주문수량'
      '주문수량은 0보다 커야 합니다.'
      CHANGING
      cs_result.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 요청납기일
"---------------------------------------------------------------------*
  IF cs_result-error_field NS '요청납기일'.

    IF cs_result-reqdt IS INITIAL.

      PERFORM add_valid_error
      USING
      '요청납기일'
      '요청납기일을 입력해 주십시오.'
      CHANGING
      cs_result.

    ELSE.

      CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
        EXPORTING
          date                      = cs_result-reqdt
        EXCEPTIONS
          plausibility_check_failed = 1
          OTHERS                    = 2.

      IF sy-subrc <> 0.

        PERFORM add_valid_error
        USING
        '요청납기일'
        '요청납기일 형식이 올바르지 않습니다.'
        CHANGING
        cs_result.

      ELSEIF cs_result-reqdt < sy-datum.

        PERFORM add_valid_error
        USING
        '요청납기일'
        '요청납기일은 오늘 이전일 수 없습니다.'
        CHANGING
        cs_result.

      ENDIF.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 판매조건
"---------------------------------------------------------------------*
  IF cs_result-basic_ok = 'Y'.

    CLEAR:
    lv_unitp,
    lv_disrt,
    lv_taxrt,
    lv_waers,
    lv_vkorg,
    lv_vtweg.

    SELECT SINGLE
    unitp,
    disrt,
    taxrt,
    waers,
    vkorg,
    vtweg
    FROM ztcma00060
    WHERE matnr = @cs_result-matnr
    AND kunnr = @cs_result-kunnr
    AND vfrom <= @sy-datum
    AND vto   >= @sy-datum
    AND actyn = 'Y'
    INTO
    (@lv_unitp,
    @lv_disrt,
    @lv_taxrt,
    @lv_waers,
    @lv_vkorg,
    @lv_vtweg).

    IF sy-subrc <> 0.

      PERFORM add_valid_error
      USING
      '판매조건'
      '유효한 고객-자재 판매조건이 없습니다.'
      CHANGING
      cs_result.

    ELSE.

      cs_result-netpr = lv_unitp.
      cs_result-disrt = lv_disrt.
      cs_result-taxrt = lv_taxrt.

      cs_result-waers = lv_waers.
      cs_result-vkorg = lv_vkorg.
      cs_result-vtweg = lv_vtweg.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 기본검증 실패
"---------------------------------------------------------------------*
  IF cs_result-basic_ok = 'N'.

    cs_result-order_ok = 'N'.
    cs_result-status   = icon_led_red.

    RETURN.

  ENDIF.


"*********************************************************************
" 판매금액 계산
"*********************************************************************
  cs_result-disam =
   cs_result-netpr * cs_result-kwmeng
   * cs_result-disrt / 100.

  cs_result-netam =
  ( cs_result-netpr * cs_result-kwmeng )
  - cs_result-disam.

  cs_result-taxam =
  cs_result-netam * cs_result-taxrt / 100.

  cs_result-totam =
  cs_result-netam
  + cs_result-taxam.


"***********************************************************************
" 2차 검증 - 재고 / 주문 가능성 판단
"***********************************************************************
  CLEAR:
    lv_stqty,
    lv_rsqty,
    lv_pending_qty.

  SELECT SINGLE
    stqty,
    rsqty
    FROM ztmma00070
    WHERE matnr = @cs_result-matnr
      AND werks = @cs_result-werks
      AND lgort = @cs_result-lgort
    INTO
      (@lv_stqty,
       @lv_rsqty).

  IF sy-subrc <> 0.

    CLEAR:
      lv_stqty,
      lv_rsqty.

  ENDIF.

  cs_result-stqty = lv_stqty.
  cs_result-rsqty = lv_rsqty.

"---------------------------------------------------------------------*
" 앞서 검증된 동일 자재 주문의 예상 차감수량 (선착순)
"---------------------------------------------------------------------*
  CLEAR lv_pending_qty.

  LOOP AT gt_valid_result
    INTO DATA(ls_prev_result).

    IF ls_prev_result-row_no >= cs_result-row_no.

      CONTINUE.

    ENDIF.

    IF ls_prev_result-matnr = cs_result-matnr
       AND ls_prev_result-werks = cs_result-werks
       AND ls_prev_result-lgort = cs_result-lgort
       AND ls_prev_result-order_ok = 'Y'.

      lv_pending_qty =
        lv_pending_qty
        + ls_prev_result-kwmeng.

    ENDIF.

  ENDLOOP.

"---------------------------------------------------------------------*
" 예상 가용재고 = 가용재고(STQTY, 예약 차감 완료) - 앞선 검증주문수량
"---------------------------------------------------------------------*
" STQTY는 예약이 이미 차감된 가용재고 (MM 기준) → RSQTY를 다시 빼지 않음
  cs_result-avqty =
    lv_stqty
    - lv_pending_qty.

  IF cs_result-avqty < 0.

    cs_result-avqty = 0.

  ENDIF.

"---------------------------------------------------------------------*
" 예상 가용재고로 주문 가능
"---------------------------------------------------------------------*
  IF cs_result-kwmeng <= cs_result-avqty.

    CLEAR:
      cs_result-shiqty,
      cs_result-lifnr,
      cs_result-plifz,
      cs_result-expdt.

    cs_result-procure_need = 'N'.
    cs_result-order_ok     = 'Y'.

    cs_result-status =
      icon_led_green.

    IF lv_pending_qty > 0.

      cs_result-result_text =
        '기본검증 정상 / 앞선 주문 반영 예상 가용재고로 주문 가능'.

    ELSE.

      cs_result-result_text =
        '기본검증 정상 / 현재 가용재고로 주문 가능'.

    ENDIF.

"   재고 충분 건도 기생성 SO 중복 검사
    PERFORM check_dup_so
      CHANGING
        cs_result.

    RETURN.

  ENDIF.

"---------------------------------------------------------------------*
" 예상 가용재고 부족
"---------------------------------------------------------------------*
  cs_result-shiqty =
    cs_result-kwmeng
    - cs_result-avqty.

  cs_result-procure_need =
    'Y'.

"---------------------------------------------------------------------*
" 공급업체 Lead Time
"---------------------------------------------------------------------*
  CLEAR:
    lv_lifnr,
    lv_plifz.

  SELECT SINGLE
    lifnr,
    plifz
    FROM ztcma00040
    WHERE matnr = @cs_result-matnr
      AND priok = '0'
      AND valfr <= @sy-datum
      AND valto >= @sy-datum
      AND actyn = 'Y'
    INTO
      (@lv_lifnr,
       @lv_plifz).

  IF sy-subrc <> 0
     OR lv_plifz IS INITIAL.

    cs_result-order_ok =
      'N'.

    cs_result-status =
      icon_led_red.

    IF lv_pending_qty > 0.

      cs_result-result_text =
        '기본검증 정상 / 앞선 주문 반영 후 재고 부족 / 유효한 Lead Time 정보 없음'.

    ELSE.

      cs_result-result_text =
        '기본검증 정상 / 재고 부족 / 유효한 Lead Time 정보 없음'.

    ENDIF.

    RETURN.

  ENDIF.

  cs_result-lifnr =
    lv_lifnr.

  cs_result-plifz =
    lv_plifz.

  cs_result-expdt =
    sy-datum
    + lv_plifz.

"---------------------------------------------------------------------*
" 요청납기 내 조달 가능
"---------------------------------------------------------------------*
  IF cs_result-expdt <= cs_result-reqdt.

    cs_result-order_ok     = 'Y'.
    cs_result-procure_need = 'Y'.
    cs_result-status       = icon_led_yellow.

    IF lv_pending_qty > 0.

      cs_result-result_text =
        '기본검증 정상 / 앞선 주문 반영 후 재고 부족 / 요청납기 내 조달 가능'.

    ELSE.

      cs_result-result_text =
        '기본검증 정상 / 재고 부족 / 요청납기 내 조달 가능'.

    ENDIF.

"---------------------------------------------------------------------*
" 요청납기 내 조달 불가
"---------------------------------------------------------------------*
  ELSE.

    cs_result-order_ok = 'N'.
    cs_result-status   = icon_led_red.

    IF lv_pending_qty > 0.

      cs_result-result_text =
        '기본검증 정상 / 앞선 주문 반영 후 재고 부족 / 요청납기 내 조달 불가'.

    ELSE.

      cs_result-result_text =
        '기본검증 정상 / 재고 부족 / 요청납기 내 조달 불가'.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" 기존 생성 판매오더 중복 검사 (재고 부족 + 조달 가능 건)
"---------------------------------------------------------------------*
  PERFORM check_dup_so
    CHANGING
      cs_result.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM check_dup_so
"&---------------------------------------------------------------------*
"---------------------------------------------------------------------*
" 기존 생성 판매오더 중복 검사 (취소 SO 제외)
" → 오류가 아니라 "경고". 주문 가능 건이면 그대로 생성할 수 있다.
"   (실무처럼 재주문 허용, 생성 시 사용자에게 한 번 더 확인)
"---------------------------------------------------------------------*
FORM check_dup_so
CHANGING
cs_result TYPE ty_valid_result.

  CLEAR cs_result-dup_vbeln.

  IF cs_result-order_ok = 'Y'
  AND cs_result-kunnr  IS NOT INITIAL
  AND cs_result-matnr  IS NOT INITIAL
  AND cs_result-kwmeng > 0
  AND cs_result-reqdt IS NOT INITIAL.

    SELECT SINGLE
           i~vbeln
      FROM ztsda00020 AS i
      INNER JOIN ztsda00010 AS h
        ON h~vbeln = i~vbeln
      WHERE h~kunnr  = @cs_result-kunnr
        AND i~matnr  = @cs_result-matnr
        AND i~kwmeng = @cs_result-kwmeng
        AND i~reqdt  = @cs_result-reqdt
        AND h~sosta <> 'CN'
      INTO @DATA(lv_dup_vbeln).

    IF sy-subrc = 0.

      cs_result-dup_vbeln   = lv_dup_vbeln.
      cs_result-error_field = '기생성 SO'.

      cs_result-result_text =
        |{ cs_result-result_text } / [주의] 동일 주문 { lv_dup_vbeln } 존재|.

    ENDIF.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM upload_order_excel
"&---------------------------------------------------------------------*
FORM upload_order_excel.

  DATA:
    lo_excel     TYPE ole2_object,
    lo_workbooks TYPE ole2_object,
    lo_workbook  TYPE ole2_object,
    lo_sheets    TYPE ole2_object,
    lo_sheet     TYPE ole2_object,
    lo_cell      TYPE ole2_object.

  DATA:
    lv_row       TYPE i,
    lv_blank_cnt TYPE i,
    lv_kunnr     TYPE string,
    lv_matnr     TYPE string,
    lv_kwmeng    TYPE string,
    lv_reqdt     TYPE string,
    lv_error     TYPE abap_bool,
    lv_message   TYPE string.

  DATA:
  ls_valid TYPE ty_valid_result.


  CLEAR:
  gt_valid_result,
  gs_valid_result,
  gv_total_cnt,
  gv_success_cnt,
  gv_procure_cnt,
  gv_error_cnt.

  IF p_file IS INITIAL.

    MESSAGE e021(zmsga) WITH '주문 파일'.

  ENDIF.

  CREATE OBJECT lo_excel
    'EXCEL.APPLICATION'.

  IF sy-subrc <> 0.

    MESSAGE e091(zmsga).

  ENDIF.

  SET PROPERTY OF lo_excel
  'Visible' = 0.

  GET PROPERTY OF lo_excel
  'Workbooks' = lo_workbooks.

  IF sy-subrc <> 0.

    lv_error   = abap_true.
    lv_message = 'Excel Workbooks를 불러올 수 없습니다.'.

  ENDIF.

  IF lv_error = abap_false.

    CALL METHOD OF lo_workbooks
    'Open' = lo_workbook
    EXPORTING
    #1 = p_file.

    IF sy-subrc <> 0.

      lv_error   = abap_true.
      lv_message = '주문 파일을 열 수 없습니다.'.

    ENDIF.

  ENDIF.

  IF lv_error = abap_false.

    GET PROPERTY OF lo_workbook
    'Worksheets' = lo_sheets.

    IF sy-subrc <> 0.

      lv_error   = abap_true.
      lv_message = 'Excel 시트를 불러올 수 없습니다.'.

    ENDIF.

  ENDIF.

  IF lv_error = abap_false.

    GET PROPERTY OF lo_sheets
    'Item' = lo_sheet
    EXPORTING
    #1 = 1.

    IF sy-subrc <> 0.

      lv_error   = abap_true.
      lv_message = '첫 번째 Excel 시트를 읽을 수 없습니다.'.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" Excel 데이터 읽기
" a열 : 고객번호 / c열 : 자재번호 / e열 : 주문수량 / g열 : 요청납기일
"---------------------------------------------------------------------*
  IF lv_error = abap_false.

    lv_row       = 10.
    lv_blank_cnt = 0.

    WHILE lv_row <= 999.

      CLEAR:
      lv_kunnr,
      lv_matnr,
      lv_kwmeng,
      lv_reqdt,
      ls_valid.

      CALL METHOD OF lo_sheet
      'Cells' = lo_cell
      EXPORTING
      #1 = lv_row
      #2 = 1.

      GET PROPERTY OF lo_cell
      'Text' = lv_kunnr.

      FREE OBJECT lo_cell.

      CALL METHOD OF lo_sheet
      'Cells' = lo_cell
      EXPORTING
      #1 = lv_row
      #2 = 3.

      GET PROPERTY OF lo_cell
      'Text' = lv_matnr.

      FREE OBJECT lo_cell.

      CALL METHOD OF lo_sheet
      'Cells' = lo_cell
      EXPORTING
      #1 = lv_row
      #2 = 5.

      GET PROPERTY OF lo_cell
      'Text' = lv_kwmeng.

      FREE OBJECT lo_cell.

      CALL METHOD OF lo_sheet
      'Cells' = lo_cell
      EXPORTING
      #1 = lv_row
      #2 = 7.

      GET PROPERTY OF lo_cell
      'Text' = lv_reqdt.

      FREE OBJECT lo_cell.

      CONDENSE lv_kunnr.
      CONDENSE lv_matnr.
      CONDENSE lv_kwmeng.
      CONDENSE lv_reqdt.

      TRANSLATE lv_kunnr TO UPPER CASE.
      TRANSLATE lv_matnr TO UPPER CASE.

      REPLACE ALL OCCURRENCES OF ','
      IN lv_kwmeng
      WITH ''.

      REPLACE ALL OCCURRENCES OF '-'
      IN lv_reqdt
      WITH ''.

      REPLACE ALL OCCURRENCES OF '.'
      IN lv_reqdt
      WITH ''.

      REPLACE ALL OCCURRENCES OF '/'
      IN lv_reqdt
      WITH ''.

"---------------------------------------------------------------------*
" 완전히 빈 행
"---------------------------------------------------------------------*
      IF lv_kunnr  IS INITIAL
      AND lv_matnr  IS INITIAL
      AND lv_kwmeng IS INITIAL
      AND lv_reqdt  IS INITIAL.

        lv_blank_cnt = lv_blank_cnt + 1.

        IF lv_blank_cnt >= 20.
          EXIT.
        ENDIF.

        lv_row = lv_row + 1.

        CONTINUE.

      ENDIF.

      CLEAR lv_blank_cnt.

      ls_valid-row_no = lv_row.

      ls_valid-kunnr = lv_kunnr.

      ls_valid-matnr = lv_matnr.

      IF lv_kwmeng IS NOT INITIAL.

        TRY.

            ls_valid-kwmeng = lv_kwmeng.

          CATCH cx_sy_conversion_error.

            CLEAR ls_valid-kwmeng.

            PERFORM add_valid_error
            USING
            '주문수량'
            '주문수량 형식이 올바르지 않습니다.'
            CHANGING
            ls_valid.

        ENDTRY.

      ENDIF.

      IF lv_reqdt IS NOT INITIAL.

        IF strlen( lv_reqdt ) <> 8
        OR lv_reqdt CN '0123456789'.

          CLEAR ls_valid-reqdt.

          PERFORM add_valid_error
          USING
          '요청납기일'
          '요청납기일 형식이 올바르지 않습니다.'
          CHANGING
          ls_valid.

        ELSE.

          ls_valid-reqdt = lv_reqdt.

          CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
            EXPORTING
              date                      = ls_valid-reqdt
            EXCEPTIONS
              plausibility_check_failed = 1
              OTHERS                    = 2.

          IF sy-subrc <> 0.

            CLEAR ls_valid-reqdt.

            PERFORM add_valid_error
            USING
            '요청납기일'
            '요청납기일 형식이 올바르지 않습니다.'
            CHANGING
            ls_valid.

          ENDIF.

        ENDIF.

      ENDIF.

      APPEND ls_valid
      TO gt_valid_result.

      lv_row = lv_row + 1.

    ENDWHILE.

  ENDIF.

  IF lo_workbook-handle <> 0.

    CALL METHOD OF lo_workbook
      'Close'
      EXPORTING
        #1 = 0.

  ENDIF.

  IF lo_excel-handle <> 0.

    CALL METHOD OF lo_excel
      'Quit'.

  ENDIF.

  FREE OBJECT:
  lo_cell,
  lo_sheet,
  lo_sheets,
  lo_workbook,
  lo_workbooks,
  lo_excel.

  IF lv_error = abap_true.

    MESSAGE lv_message
    TYPE 'E'.

  ENDIF.

  IF gt_valid_result IS INITIAL.

    MESSAGE e018(zmsga).

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM validate_excel_order
"&---------------------------------------------------------------------*
FORM validate_excel_order.

  LOOP AT gt_valid_result
  ASSIGNING FIELD-SYMBOL(<ls_valid_result>).

    PERFORM validate_order
    CHANGING
    <ls_valid_result>.

    PERFORM set_valid_row_color
    CHANGING
    <ls_valid_result>.

  ENDLOOP.

  PERFORM calculate_validation_count.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM calculate_validation_count
"&---------------------------------------------------------------------*
FORM calculate_validation_count.

  CLEAR:
  gv_total_cnt,
  gv_success_cnt,
  gv_procure_cnt,
  gv_error_cnt.

  LOOP AT gt_valid_result
  INTO gs_valid_result.

    gv_total_cnt =
    gv_total_cnt + 1.

    IF gs_valid_result-order_ok = 'Y'
    AND gs_valid_result-procure_need = 'N'.

      gv_success_cnt =
      gv_success_cnt + 1.

    ELSEIF gs_valid_result-order_ok = 'Y'
    AND gs_valid_result-procure_need = 'Y'.

      gv_procure_cnt =
      gv_procure_cnt + 1.

    ELSE.

      gv_error_cnt =
      gv_error_cnt + 1.

    ENDIF.

  ENDLOOP.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM display_valid_popup
"&---------------------------------------------------------------------*
FORM display_valid_popup.

  PERFORM calculate_validation_count.

  CALL SCREEN 0100.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM display_valid_alv
"&---------------------------------------------------------------------*
FORM display_valid_alv.

  IF go_valid_container IS INITIAL.

    CREATE OBJECT go_valid_container
      EXPORTING
        container_name = 'CC_VALID'.

    CREATE OBJECT go_valid_grid
      EXPORTING
        i_parent = go_valid_container.

    IF go_event_handler IS INITIAL.

      CREATE OBJECT go_event_handler.

    ENDIF.

    SET HANDLER
    go_event_handler->handle_valid_toolbar
    FOR go_valid_grid.

    SET HANDLER
    go_event_handler->handle_valid_user_command
    FOR go_valid_grid.

    PERFORM set_valid_fieldcat.

    CLEAR gs_valid_layo.

    gs_valid_layo-grid_title =
    '주문 검증 결과'.

    gs_valid_layo-zebra =
    abap_true.

    gs_valid_layo-cwidth_opt =
    abap_true.

    gs_valid_layo-sel_mode =
    'A'.

    gs_valid_layo-info_fname =
    'ROW_COLOR'.

    gs_valid_layo-ctab_fname =
      'CELL_COLOR'.

    PERFORM set_toolbar_exclude.

    CALL METHOD go_valid_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_valid_layo
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab            = gt_valid_result
        it_fieldcatalog      = gt_valid_fcat.

  ELSE.

    CALL METHOD go_valid_grid->refresh_table_display.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM set_valid_fieldcat
"&---------------------------------------------------------------------*
FORM set_valid_fieldcat.

  CLEAR gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'ROW_COLOR'.
  gs_valid_fcat-tech      = abap_true.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname  = 'STATUS'.
  gs_valid_fcat-coltext    = '상태'.
  gs_valid_fcat-icon       = abap_true.
  gs_valid_fcat-outputlen  = 6.
  gs_valid_fcat-fix_column = abap_true.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname  = 'ROW_NO'.
  gs_valid_fcat-coltext    = 'No'.
  gs_valid_fcat-outputlen  = 5.
  gs_valid_fcat-fix_column = abap_true.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'ORDER_OK'.
  gs_valid_fcat-coltext   = '주문가능'.
  gs_valid_fcat-outputlen = 8.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'PROCURE_NEED'.
  gs_valid_fcat-coltext   = '조달필요'.
  gs_valid_fcat-outputlen = 8.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'ERROR_FIELD'.
  gs_valid_fcat-coltext   = '오류항목'.
  gs_valid_fcat-outputlen = 20.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'BASIC_OK'.
  gs_valid_fcat-coltext   = '기본검증'.
  gs_valid_fcat-outputlen = 8.
  gs_valid_fcat-no_out    = abap_true.     " 상태 아이콘과 중복 → 숨김
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'KUNNR'.
  gs_valid_fcat-coltext   = '고객번호'.
  gs_valid_fcat-outputlen = 12.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'NAME1'.
  gs_valid_fcat-coltext   = '고객명'.
  gs_valid_fcat-outputlen = 15.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'MATNR'.
  gs_valid_fcat-coltext   = '자재번호'.
  gs_valid_fcat-outputlen = 15.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'MAKTX'.
  gs_valid_fcat-coltext   = '자재명'.
  gs_valid_fcat-outputlen = 16.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname  = 'KWMENG'.
  gs_valid_fcat-coltext    = '주문수량'.
  gs_valid_fcat-outputlen  = 10.
  gs_valid_fcat-decimals_o = '0'.          " 소수점 숨김
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname  = 'AVQTY'.
  gs_valid_fcat-coltext    = '가용수량'.
  gs_valid_fcat-outputlen  = 10.
  gs_valid_fcat-decimals_o = '0'.          " 소수점 숨김
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname  = 'SHIQTY'.
  gs_valid_fcat-coltext    = '부족수량'.
  gs_valid_fcat-outputlen  = 10.
  gs_valid_fcat-decimals_o = '0'.          " 소수점 숨김
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'LIFNR'.
  gs_valid_fcat-coltext   = '공급업체'.
  gs_valid_fcat-outputlen = 12.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'PLIFZ'.
  gs_valid_fcat-coltext   = 'Lead Time'.
  gs_valid_fcat-outputlen = 10.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'EXPDT'.
  gs_valid_fcat-coltext   = '예상확보일'.
  gs_valid_fcat-outputlen = 10.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'REQDT'.
  gs_valid_fcat-coltext   = '요청납기일'.
  gs_valid_fcat-outputlen = 10.
  APPEND gs_valid_fcat TO gt_valid_fcat.

  CLEAR gs_valid_fcat.
  gs_valid_fcat-fieldname = 'RESULT_TEXT'.
  gs_valid_fcat-coltext   = '검증내용'.
  gs_valid_fcat-outputlen = 45.
  APPEND gs_valid_fcat TO gt_valid_fcat.

ENDFORM.



"&---------------------------------------------------------------------*
"& Form CREATE_SALES_ORDER
"&---------------------------------------------------------------------*
" 생성 SO를 강조 목록에 저장 / 생성 후 전체 목록에서 강조 표시
"----------------------------------------------------------------------*
FORM create_sales_order.

  DATA:
    ls_header    TYPE ztsda00010,
    ls_item      TYPE ztsda00020,
    lt_rows      TYPE lvc_t_row,
    ls_row       TYPE lvc_s_row,
    lv_vbeln     TYPE ztsda00010-vbeln,
    lv_posnr     TYPE ztsda00020-posnr,
    lv_answer    TYPE c LENGTH 1,
    lv_question  TYPE c LENGTH 200,
    lv_kunnr     TYPE ztsda00010-kunnr,
"   MM 연동용
    lt_header    TYPE zttsda00010,
    lt_item      TYPE zttsda00020,
    ls_150       TYPE ztmma00150,
    lt_reserve   TYPE zttmma00090,
    lt_pr        TYPE zttmma00010,
    ls_pr        LIKE LINE OF lt_pr,
    lt_pr_result TYPE zttmma00020,
    ls_pr_result LIKE LINE OF lt_pr_result,
    lt_return    TYPE STANDARD TABLE OF bapiret2,
    lt_pr_return TYPE bapiret2_t,
    ls_return    TYPE bapiret2,
    lv_pr_cnt    TYPE i,
    lv_pr_err    TYPE abap_bool,
    lv_pr_text   TYPE string.

  CLEAR lt_rows.

  IF go_valid_grid IS BOUND.

    CALL METHOD go_valid_grid->get_selected_rows
      IMPORTING
        et_index_rows = lt_rows.

  ENDIF.

  IF lt_rows IS INITIAL.

    MESSAGE i021(zmsga) WITH '생성할 주문'.

    RETURN.

  ENDIF.

"---------------------------------------------------------------------*
" 선택한 모든 행이 판매오더 생성 가능한지 확인
"---------------------------------------------------------------------*
  LOOP AT lt_rows INTO ls_row.

    READ TABLE gt_valid_result
      INTO gs_valid_result
      INDEX ls_row-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF gs_valid_result-order_ok <> 'Y'.

      MESSAGE i037(zmsga) WITH '주문 불가' '판매오더 생성'.

      RETURN.

    ENDIF.

  ENDLOOP.

"---------------------------------------------------------------------*
" 첫 번째 선택 건 고객 확인
"---------------------------------------------------------------------*
  READ TABLE lt_rows
    INTO ls_row
    INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE gt_valid_result
    INTO gs_valid_result
    INDEX ls_row-index.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  lv_kunnr = gs_valid_result-kunnr.

"---------------------------------------------------------------------*
" 하나의 SO에는 동일 고객만 허용
"---------------------------------------------------------------------*
  LOOP AT lt_rows INTO ls_row.

    READ TABLE gt_valid_result
      INTO gs_valid_result
      INDEX ls_row-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    IF gs_valid_result-kunnr <> lv_kunnr.

      MESSAGE i200(zmsga).

      RETURN.

    ENDIF.

  ENDLOOP.

"---------------------------------------------------------------------*
" 사용자 확인
" 기생성 SO와 동일한 주문이 포함되어 있으면 경고 문구를 추가한다.
"---------------------------------------------------------------------*
  CLEAR lv_question.

  MESSAGE s209(zmsga) INTO lv_question.

  LOOP AT lt_rows INTO ls_row.

    READ TABLE gt_valid_result
      INTO gs_valid_result
      INDEX ls_row-index.

    IF sy-subrc = 0
    AND gs_valid_result-dup_vbeln IS NOT INITIAL.

      MESSAGE s210(zmsga)
        WITH gs_valid_result-dup_vbeln
        INTO lv_question.

      EXIT.

    ENDIF.

  ENDLOOP.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '판매오더 생성'
      text_question         = lv_question
      text_button_1         = '예'
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = '아니오'
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.

    MESSAGE i005(zmsga).

    RETURN.

  ENDIF.

"---------------------------------------------------------------------*
" SO 번호 채번 (SD 공통 FM : SO + 8자리)
"---------------------------------------------------------------------*
  PERFORM get_next_vbeln
    CHANGING
      lv_vbeln.

  IF lv_vbeln IS INITIAL.
    RETURN.
  ENDIF.

"---------------------------------------------------------------------*
" 첫 번째 선택 Item
"---------------------------------------------------------------------*
  READ TABLE lt_rows
    INTO ls_row
    INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  READ TABLE gt_valid_result
    INTO gs_valid_result
    INDEX ls_row-index.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

"---------------------------------------------------------------------*
" Header 구성
"---------------------------------------------------------------------*
  CLEAR ls_header.

  ls_header-vbeln = lv_vbeln.
  ls_header-kunnr = gs_valid_result-kunnr.
  ls_header-audat = sy-datum.
  ls_header-vkorg = gs_valid_result-vkorg.
  ls_header-vtweg = gs_valid_result-vtweg.
  ls_header-waers = gs_valid_result-waers.
  ls_header-sosta = 'SO'.
  ls_header-ernam = sy-uname.
  ls_header-erdat = sy-datum.
  ls_header-erzet = sy-uzeit.

"---------------------------------------------------------------------*
" Header 금액 - 선택된 Item만 합산
"---------------------------------------------------------------------*
  LOOP AT lt_rows INTO ls_row.

    READ TABLE gt_valid_result
      INTO gs_valid_result
      INDEX ls_row-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    ls_header-netam = ls_header-netam + gs_valid_result-netam.
    ls_header-taxam = ls_header-taxam + gs_valid_result-taxam.
    ls_header-totam = ls_header-totam + gs_valid_result-totam.

  ENDLOOP.

"---------------------------------------------------------------------*
" Header 저장
"---------------------------------------------------------------------*
  INSERT ztsda00010
    FROM ls_header.

  IF sy-subrc <> 0.

    ROLLBACK WORK.

    MESSAGE i063(zmsga).

    RETURN.

  ENDIF.

"---------------------------------------------------------------------*
" MM 예약 FM 전달용 Header
"---------------------------------------------------------------------*
  APPEND ls_header TO lt_header.

"---------------------------------------------------------------------*
" Item 저장
"---------------------------------------------------------------------*
  CLEAR lv_posnr.

  LOOP AT lt_rows INTO ls_row.

    READ TABLE gt_valid_result
      INTO gs_valid_result
      INDEX ls_row-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_posnr = lv_posnr + 10.

    CLEAR ls_item.

    ls_item-vbeln  = lv_vbeln.
    ls_item-posnr  = lv_posnr.
    ls_item-matnr  = gs_valid_result-matnr.
    ls_item-werks  = gs_valid_result-werks.
    ls_item-lgort  = gs_valid_result-lgort.
    ls_item-kwmeng = gs_valid_result-kwmeng.
    ls_item-meins  = gs_valid_result-meins.
    ls_item-netpr  = gs_valid_result-netpr.
    ls_item-disrt  = gs_valid_result-disrt.
    ls_item-disam  = gs_valid_result-disam.
    ls_item-netam  = gs_valid_result-netam.
    ls_item-taxrt  = gs_valid_result-taxrt.
    ls_item-taxam  = gs_valid_result-taxam.
    ls_item-totam  = gs_valid_result-totam.
    ls_item-reqdt  = gs_valid_result-reqdt.
    ls_item-ernam  = sy-uname.
    ls_item-erdat  = sy-datum.
    ls_item-erzet  = sy-uzeit.

    INSERT ztsda00020
      FROM ls_item.

    IF sy-subrc <> 0.

      ROLLBACK WORK.

      MESSAGE i063(zmsga).

      RETURN.

    ENDIF.

"---------------------------------------------------------------------*
" MM 예약 FM 전달용 Item
"---------------------------------------------------------------------*
    APPEND ls_item TO lt_item.

"---------------------------------------------------------------------*
" SO별 예약재고 현황(ZTMMA00150) 먼저 생성
"   ORDQT = 주문수량 / SUMQT, AVLQT = 0 (AVLQT는 MM 예약 FM이 갱신)
"   ※ 기존 ZTMMA00070 직접 UPDATE 삭제 (재고는 MM 함수가 갱신)
"---------------------------------------------------------------------*
    CLEAR ls_150.

    ls_150-vbeln = lv_vbeln.
    ls_150-posnr = lv_posnr.
    ls_150-matnr = gs_valid_result-matnr.
    ls_150-werks = gs_valid_result-werks.
    ls_150-lgort = gs_valid_result-lgort.
    ls_150-ordqt = gs_valid_result-kwmeng.
    ls_150-sumqt = 0.
    ls_150-avlqt = 0.
    ls_150-meins = gs_valid_result-meins.
    ls_150-ernam = sy-uname.
    ls_150-erdat = sy-datum.
    ls_150-erzet = sy-uzeit.

    INSERT ztmma00150
      FROM ls_150.

    IF sy-subrc <> 0.

      ROLLBACK WORK.

      MESSAGE i063(zmsga).

      RETURN.

    ENDIF.

"---------------------------------------------------------------------*
" 조달 요청 대상 수집 (PR FM은 COMMIT 후 1회 호출)
"   SO번호/품목번호만 넘기면 MM이 ZTMMA00150 기준으로 부족수량 계산
"---------------------------------------------------------------------*
    IF gs_valid_result-procure_need = 'Y'
       AND gs_valid_result-shiqty > 0.

      CLEAR ls_pr.

      ls_pr-srtyp = '0020'.
      ls_pr-srdoc = lv_vbeln.
      ls_pr-sritm = lv_posnr.

      APPEND ls_pr TO lt_pr.

    ENDIF.

  ENDLOOP.

"---------------------------------------------------------------------*
" 재고 예약 : MM FM 1회 호출 (FM 내부에 COMMIT 없음)
"   - 재고 부족분은 W 로 반환 (오류 아님) / E, A, X 만 롤백
"---------------------------------------------------------------------*
  CLEAR:
    lt_return,
    lt_reserve.

  CALL FUNCTION 'ZFM_MM_MATERIAL_RESERVE'
    EXPORTING
      sales_header     = lt_header
      sales_item       = lt_item
    IMPORTING
      reserve_material = lt_reserve
    TABLES
      et_return        = lt_return.

  LOOP AT lt_return INTO ls_return
       WHERE type = 'E' OR type = 'A' OR type = 'X'.
    EXIT.
  ENDLOOP.

  IF sy-subrc = 0.

    ROLLBACK WORK.

    MESSAGE i204(zmsga) WITH ls_return-message.

    RETURN.

  ENDIF.

"---------------------------------------------------------------------*
" 부족수량 조달요청(PR) : SO 저장과 같은 LUW에서 호출 (MM 연계 가이드)
"   - ZFM_MM_PR_CREATE 는 내부에서 COMMIT / ROLLBACK 하지 않음
"   - SD가 SO번호 / 품목번호만 전달, 부족수량 계산은 MM FM이 수행
"   - 아래 중 하나라도 해당하면 SO까지 전체 ROLLBACK
"       · ET_RETURN 에 E / A / X
"       · 요청 건수 <> 결과 건수
"       · RESULT 가 CREATED / EXISTING / SKIPPED 가 아님
"   - FM이 잡은 ZTMMA00040 잠금은 호출 후 반드시 DEQUEUE
"---------------------------------------------------------------------*
  CLEAR:
    lv_pr_cnt,
    lv_pr_err,
    lv_pr_text.

  IF lt_pr IS NOT INITIAL.

    CLEAR:
      lt_pr_result,
      lt_pr_return.

    CALL FUNCTION 'ZFM_MM_PR_CREATE'
      EXPORTING
        it_pr_request = lt_pr
      IMPORTING
        et_pr_result  = lt_pr_result
        et_return     = lt_pr_return.

    LOOP AT lt_pr_return INTO ls_return
         WHERE type = 'E' OR type = 'A' OR type = 'X'.
      lv_pr_err  = abap_true.
      lv_pr_text = ls_return-message.
      EXIT.
    ENDLOOP.

    IF lv_pr_err = abap_false
    AND lines( lt_pr_result ) <> lines( lt_pr ).
      lv_pr_err  = abap_true.
      lv_pr_text = |요청 { lines( lt_pr ) }건 / 결과 { lines( lt_pr_result ) }건|.
    ENDIF.

    IF lv_pr_err = abap_false.

      LOOP AT lt_pr_result INTO ls_pr_result.

        CASE ls_pr_result-result.
          WHEN 'CREATED'.
            lv_pr_cnt = lv_pr_cnt + 1.
          WHEN 'EXISTING' OR 'SKIPPED'.
"           기존 PR 존재 / 신규 생성 불필요 : 정상
          WHEN OTHERS.
            lv_pr_err  = abap_true.
            lv_pr_text = ls_pr_result-result.
            EXIT.
        ENDCASE.

      ENDLOOP.

    ENDIF.

    IF lv_pr_err = abap_true.
      ROLLBACK WORK.
    ENDIF.

"   MM FM이 잡은 ZTMMA00040 잠금 해제
    CALL FUNCTION 'DEQUEUE_E_TABLE'
      EXPORTING
        mode_rstable = 'E'
        tabname      = 'ZTMMA00040'
        varkey       = space
        _scope       = '1'.

    IF lv_pr_err = abap_true.

      MESSAGE i203(zmsga) WITH lv_pr_text.

      RETURN.

    ENDIF.

  ENDIF.

"---------------------------------------------------------------------*
" SO 헤더 / 품목 / 예약정보 / 예약 이동문서 / PR 확정
"---------------------------------------------------------------------*
  COMMIT WORK AND WAIT.

"---------------------------------------------------------------------*
" 방금 생성한 SO 강조 목록에 저장
"---------------------------------------------------------------------*
  PERFORM load_new_so_memory.

  IF NOT line_exists( gt_new_so[ table_line = lv_vbeln ] ).
    APPEND lv_vbeln TO gt_new_so.
  ENDIF.

  PERFORM save_new_so_memory.

"---------------------------------------------------------------------*
" 판매오더 생성 완료 건 검증목록에서 제거
"---------------------------------------------------------------------*
  SORT lt_rows
    BY index DESCENDING.

  LOOP AT lt_rows INTO ls_row.

    DELETE gt_valid_result
      INDEX ls_row-index.

  ENDLOOP.

  PERFORM calculate_validation_count.

" KPI 카드(전체/주문가능/PR필요/오류)도 같이 갱신
  PERFORM show_valid_kpi.

  PERFORM save_valid_memory.

  IF go_valid_grid IS BOUND.

    CALL METHOD go_valid_grid->refresh_table_display.

    PERFORM clear_valid_selection.

  ENDIF.

"---------------------------------------------------------------------*
" 이번 달 기준으로 조회 + 방금 만든 SO는 맨 위 노란색
" (조건 없이 전체 기간 조회하지 않음)
"---------------------------------------------------------------------*
  PERFORM set_so_default_condition.

  gv_so_searched = abap_true.

  PERFORM get_so_list.

  IF lv_pr_cnt > 0.
    MESSAGE s202(zmsga) WITH lv_vbeln lv_pr_cnt.
  ELSE.
    MESSAGE s201(zmsga) WITH lv_vbeln.
  ENDIF.

ENDFORM.


"&---------------------------------------------------------------------*
"& Form get_next_vbeln
"&---------------------------------------------------------------------*
" MAX + 1 → SD 공통 채번 FM (SNRO ZSD_NUM 구간 01, SO + 8자리)
"----------------------------------------------------------------------*
FORM get_next_vbeln
  CHANGING
    cv_vbeln TYPE ztsda00010-vbeln.

  CLEAR cv_vbeln.

  CALL FUNCTION 'ZSD_GET_NEXT_NO'
    EXPORTING
      iv_docty      = 'SO'
    IMPORTING
      ev_number     = cv_vbeln
    EXCEPTIONS
      invalid_docty = 1
      number_error  = 2
      OTHERS        = 3.

  IF sy-subrc <> 0 OR cv_vbeln IS INITIAL.

    CLEAR cv_vbeln.

    MESSAGE i311(zmsga) WITH '판매오더'.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM clear_so_condition
"&---------------------------------------------------------------------*
FORM clear_so_condition.

  DATA lv_searched TYPE abap_bool.

" 판매오더번호 / 고객번호는 비우고 주문일자는 이번 달 1일~말일로
" (조회 여부 플래그는 그대로 유지)
  lv_searched = gv_so_searched.

  PERFORM set_so_default_condition.

  gv_so_searched = lv_searched.

ENDFORM.



"&---------------------------------------------------------------------*
"& Form GET_SO_LIST
"&---------------------------------------------------------------------*
" 생성일시 최신순 정렬 + 방금 생성한 SO 노란색
"----------------------------------------------------------------------*
FORM get_so_list.

  DATA:
    lt_header TYPE STANDARD TABLE OF ztsda00010,
    ls_header TYPE ztsda00010.

  CLEAR:
    gt_so_list,
    gt_so_detail,
    lt_header.

" 목록을 다시 조회하면 상세 제목도 기본값으로
  gs_so_detail_layo-grid_title = '판매오더 상세정보'.

  IF go_so_detail_grid IS BOUND.
    go_so_detail_grid->set_gridtitle(
      i_gridtitle = gs_so_detail_layo-grid_title ).
  ENDIF.

  PERFORM load_new_so_memory.

"---------------------------------------------------------------------*
" [검색] 전 : 방금 생성한 판매오더만 표시
" [검색] 후 : 조회조건(주문일자, 판매오더번호, 고객번호)에 맞는 오더 표시
"---------------------------------------------------------------------*
  IF gv_so_searched = abap_true.

    SELECT *
      FROM ztsda00010
      WHERE ( @gv_so_vbeln IS INITIAL OR vbeln = @gv_so_vbeln )
        AND ( @gv_so_kunnr IS INITIAL OR kunnr = @gv_so_kunnr )
        AND ( @gv_so_audat_fr IS INITIAL OR audat >= @gv_so_audat_fr )
        AND ( @gv_so_audat_to IS INITIAL OR audat <= @gv_so_audat_to )
      INTO TABLE @lt_header.

  ELSEIF gt_new_so IS NOT INITIAL.

    DATA lt_new_rng TYPE RANGE OF ztsda00010-vbeln.

    LOOP AT gt_new_so INTO DATA(lv_new_vbeln).

      APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_new_vbeln )
        TO lt_new_rng.

    ENDLOOP.

    SELECT *
      FROM ztsda00010
      WHERE vbeln IN @lt_new_rng
      INTO TABLE @lt_header.

  ENDIF.

  LOOP AT lt_header
    INTO ls_header.

    IF gv_so_vbeln IS NOT INITIAL
       AND ls_header-vbeln <> gv_so_vbeln.
      CONTINUE.
    ENDIF.

    IF gv_so_kunnr IS NOT INITIAL
       AND ls_header-kunnr <> gv_so_kunnr.
      CONTINUE.
    ENDIF.

    IF gv_so_audat_fr IS NOT INITIAL
       AND ls_header-audat < gv_so_audat_fr.
      CONTINUE.
    ENDIF.

    IF gv_so_audat_to IS NOT INITIAL
       AND ls_header-audat > gv_so_audat_to.
      CONTINUE.
    ENDIF.

    CLEAR gs_so_list.

    gs_so_list-vbeln = ls_header-vbeln.

"---------------------------------------------------------------------*
" 진행상태 (SO → DO → GI → BI)
"---------------------------------------------------------------------*
    CASE ls_header-sosta.
      WHEN 'SO'.
        gs_so_list-sosta_t = |{ icon_led_inactive }출고대기|.
      WHEN 'DO'.
        gs_so_list-sosta_t = |{ icon_led_yellow }출고문서생성|.
      WHEN 'GI'.
        gs_so_list-sosta_t = |{ icon_led_green }출하완료|.
      WHEN 'BI'.
        gs_so_list-sosta_t = |{ icon_okay }청구완료|.
      WHEN 'CN'.
        gs_so_list-sosta_t = |{ icon_cancel }취소|.
      WHEN OTHERS.
        gs_so_list-sosta_t = ls_header-sosta.
    ENDCASE.

    gs_so_list-kunnr = ls_header-kunnr.
    gs_so_list-audat = ls_header-audat.

"---------------------------------------------------------------------*
" 품목 수 / 가장 빠른 요청납기일
"---------------------------------------------------------------------*
    SELECT COUNT(*), MIN( reqdt )
      FROM ztsda00020
      WHERE vbeln = @ls_header-vbeln
      INTO ( @gs_so_list-itm_cnt, @gs_so_list-reqdt ).

"---------------------------------------------------------------------*
" 조달 상태 : 예약재고(ZTMMA00150)의 미충족 수요(ORDQT-SUMQT-AVLQT) > 0 이면 조달중
" 조달 소요일 : 부족한 자재의 Lead Time 중 가장 긴 값
"---------------------------------------------------------------------*
    DATA:
      lt_res  TYPE STANDARD TABLE OF ztmma00150,
      lv_plif TYPE ztcma00040-plifz.

    CLEAR lt_res.

    SELECT *
      FROM ztmma00150
      WHERE vbeln = @ls_header-vbeln
      INTO TABLE @lt_res.

    gs_so_list-proc_t = |{ icon_okay }재고확보|.

    LOOP AT lt_res ASSIGNING FIELD-SYMBOL(<ls_res>).

"---------------------------------------------------------------------*
" 미충족 수요 = 주문수량(ORDQT) - 기출고수량(SUMQT) - 출고가능 배정수량(AVLQT)
"---------------------------------------------------------------------*
      IF <ls_res>-ordqt - <ls_res>-sumqt - <ls_res>-avlqt <= 0.
        CONTINUE.
      ENDIF.

      gs_so_list-proc_t = |{ icon_time }조달중|.

      CLEAR lv_plif.

      SELECT SINGLE plifz
        FROM ztcma00040
        WHERE matnr = @<ls_res>-matnr
          AND priok = '0'
          AND valfr <= @sy-datum
          AND valto >= @sy-datum
          AND actyn = 'Y'
        INTO @lv_plif.

      IF lv_plif > gs_so_list-plifz.
        gs_so_list-plifz = lv_plif.
      ENDIF.

    ENDLOOP.

    IF lt_res IS INITIAL
    OR ls_header-sosta = 'CN'.
      CLEAR gs_so_list-proc_t.
    ENDIF.
    gs_so_list-waers = ls_header-waers.
    gs_so_list-totam = ls_header-totam.
    gs_so_list-erdat = ls_header-erdat.
    gs_so_list-erzet = ls_header-erzet.

    SELECT SINGLE name1
      FROM ztcma00050
      WHERE kunnr = @ls_header-kunnr
      INTO @gs_so_list-name1.

    IF line_exists( gt_new_so[ table_line = ls_header-vbeln ] ).
      gs_so_list-row_color = 'C310'.
    ENDIF.

    APPEND gs_so_list
      TO gt_so_list.

  ENDLOOP.

  SORT gt_so_list
    BY erdat DESCENDING
       erzet DESCENDING
       vbeln DESCENDING.

"---------------------------------------------------------------------*
" 순번(NO)
"---------------------------------------------------------------------*
  LOOP AT gt_so_list ASSIGNING FIELD-SYMBOL(<ls_so_no>).

    <ls_so_no>-no = sy-tabix.

  ENDLOOP.

  IF gt_so_list IS INITIAL
  AND gv_so_searched = abap_true.

    MESSAGE i040(zmsga).

  ENDIF.

  IF go_so_grid IS BOUND.

    CALL METHOD go_so_grid->refresh_table_display.

  ENDIF.

  IF go_so_detail_grid IS BOUND.

    CALL METHOD go_so_detail_grid->refresh_table_display.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM display_so_alv
"&---------------------------------------------------------------------*
" 행 색상 필드(ROW_COLOR) 연결
"----------------------------------------------------------------------*
FORM display_so_alv.

  IF go_so_container IS INITIAL.

    CREATE OBJECT go_so_container
      EXPORTING
        container_name = 'CC_SO'.

    CREATE OBJECT go_so_grid
      EXPORTING
        i_parent = go_so_container.

    IF go_event_handler IS INITIAL.

      CREATE OBJECT go_event_handler.

    ENDIF.

    SET HANDLER
      go_event_handler->handle_so_double_click
      FOR go_so_grid.

    SET HANDLER
      go_event_handler->handle_so_hotspot_click
      FOR go_so_grid.

    SET HANDLER
      go_event_handler->handle_so_toolbar
      FOR go_so_grid.

    SET HANDLER
      go_event_handler->handle_so_user_command
      FOR go_so_grid.

    PERFORM set_so_fieldcat.

    CLEAR gs_so_layo.

    IF sy-dynnr = '0100'.
      gs_so_layo-grid_title = '생성한 판매오더'.
    ELSE.
      gs_so_layo-grid_title = '판매오더 정보'.
    ENDIF.
    gs_so_layo-zebra      = abap_true.
" 처음 그릴 때 데이터가 없어도 컬럼이 잘리지 않도록 폭 자동조정 대신 고정폭 사용
    gs_so_layo-cwidth_opt = abap_false.
    gs_so_layo-sel_mode   = 'A'.
    gs_so_layo-info_fname = 'ROW_COLOR'.

    PERFORM set_toolbar_exclude.

    CALL METHOD go_so_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_so_layo
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab            = gt_so_list
        it_fieldcatalog      = gt_so_fcat.

  ELSE.

    CALL METHOD go_so_grid->refresh_table_display.

  ENDIF.

ENDFORM.





"&---------------------------------------------------------------------*
"& FORM set_so_default_condition
"&---------------------------------------------------------------------*
" 조회조건 기본값 : 이번 달 1일 ~ 오늘 (화면에는 채워 두고, 조회는 [검색] 후)
"----------------------------------------------------------------------*
FORM set_so_default_condition.

  CLEAR:
    gv_so_vbeln,
    gv_so_kunnr.

  gv_so_audat_fr = sy-datum.
  gv_so_audat_fr+6(2) = '01'.

"---------------------------------------------------------------------*
" 종료일 : 이번 달 말일
"---------------------------------------------------------------------*
  CALL FUNCTION 'RP_LAST_DAY_OF_MONTHS'
    EXPORTING
      day_in            = sy-datum
    IMPORTING
      last_day_of_month = gv_so_audat_to
    EXCEPTIONS
      day_in_no_date    = 1
      OTHERS            = 2.

  IF sy-subrc <> 0.
    gv_so_audat_to = sy-datum.
  ENDIF.

  gv_so_searched = abap_false.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM display_so_on_0100
"&---------------------------------------------------------------------*
" Screen 0100 하단 판매오더 ALV (처음 한 번만 전체 조회)
"----------------------------------------------------------------------*
FORM display_so_on_0100.

  IF go_so_container IS INITIAL.

    PERFORM set_so_default_condition.

    PERFORM get_so_list.

  ENDIF.

  PERFORM display_so_alv.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM get_so_pop
"&---------------------------------------------------------------------*
" 판매오더 상세 팝업 데이터 (Screen 0300)
"----------------------------------------------------------------------*
FORM get_so_pop.

  CLEAR gt_so_pop.

  SELECT
    h~kunnr,
    c~name1,
    a~posnr,
    a~matnr,
    b~maktx,
    a~werks,
    a~lgort,
    a~kwmeng,
    a~meins,
    a~reqdt,
    a~itmst,
    a~netpr,
    a~disrt,
    a~disam,
    a~netam,
    a~taxrt,
    a~taxam,
    a~totam,
    h~waers
    FROM ztsda00020 AS a
    LEFT OUTER JOIN ztcma00020 AS b
      ON b~matnr = a~matnr
    LEFT OUTER JOIN ztsda00010 AS h
      ON h~vbeln = a~vbeln
    LEFT OUTER JOIN ztcma00050 AS c
      ON c~kunnr = h~kunnr
    WHERE a~vbeln = @gv_so_vbeln_pop
    ORDER BY a~posnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_so_pop.

  IF gt_so_pop IS INITIAL.
    MESSAGE s042(zmsga) DISPLAY LIKE 'E' WITH '판매오더 상세정보'.
  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM display_so_pop_alv
"&---------------------------------------------------------------------*
" 판매오더 상세 팝업(Screen 0300) ALV
"  - 처음 열 때 : 컨테이너/그리드 생성 후 표시
"  - 두 번째부터 : 데이터만 다시 읽고 새로고침
"  - 창 제목줄(T0300 : 판매오더 &1 상세정보 (&2))에 SO번호·고객명 표시
"    (다른 프로그램과 통일하려고 ALV 제목 grid_title 은 사용하지 않음)
"----------------------------------------------------------------------*
FORM display_so_pop_alv.

IF go_so_pop_container IS INITIAL.

PERFORM get_so_pop.

CREATE OBJECT go_so_pop_container

EXPORTING

container_name = 'CC_SO_POP'.

CREATE OBJECT go_so_pop_grid

EXPORTING

i_parent = go_so_pop_container.

PERFORM set_so_detail_fieldcat.
"---------------------------------------------------------------------*
" 팝업 크기를 다른 프로그램과 같게 유지하기 위해 일부 컬럼 숨김
"---------------------------------------------------------------------*

LOOP AT gt_so_detail_fcat ASSIGNING FIELD-SYMBOL(<ls_pop_fcat>).

CASE <ls_pop_fcat>-fieldname.

WHEN 'WERKS' OR 'LGORT'

OR 'MEINS' OR 'DISAM' OR 'TAXRT' OR 'ITMST'.

<ls_pop_fcat>-no_out = abap_true.

ENDCASE.

ENDLOOP.

PERFORM set_toolbar_exclude.
"---------------------------------------------------------------------*
" Layout : ALV 제목 없이 줄무늬 + 컬럼폭 자동
"---------------------------------------------------------------------*

CLEAR gs_so_pop_layo.

gs_so_pop_layo-zebra      = abap_true.

gs_so_pop_layo-cwidth_opt = abap_true.

CALL METHOD go_so_pop_grid->set_table_for_first_display

EXPORTING

is_layout            = gs_so_pop_layo

it_toolbar_excluding = gt_exclude

CHANGING

it_outtab            = gt_so_pop

it_fieldcatalog      = gt_so_detail_fcat.

CALL METHOD cl_gui_cfw=>flush.

ELSE.
"---------------------------------------------------------------------*
" 두 번째 팝업부터 : 선택한 SO의 데이터만 다시 읽고 새로고침
"---------------------------------------------------------------------*

PERFORM get_so_pop.

CALL METHOD go_so_pop_grid->refresh_table_display.

CALL METHOD cl_gui_cfw=>flush.

ENDIF.
"---------------------------------------------------------------------*
" 창 제목줄 : 판매오더 SO번호 상세정보 (고객명)
"  - 데이터를 읽은 뒤에 설정해야 팝업을 열 때마다 새 SO번호로 바뀜
"  - 고객명은 상세 데이터 첫 줄의 name1 사용 (없으면 빈칸)
"---------------------------------------------------------------------*

DATA(lv_pop_name1) = VALUE ztcma00050-name1( gt_so_pop[ 1 ]-name1 OPTIONAL ).

SET TITLEBAR 'T0300' WITH gv_so_vbeln_pop lv_pop_name1.
ENDFORM.




"&---------------------------------------------------------------------*
"& FORM set_so_fieldcat
"&---------------------------------------------------------------------*
FORM set_so_fieldcat.

  CLEAR gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'NO'.
  gs_so_fcat-coltext   = 'No'.
  gs_so_fcat-outputlen = 5.
  gs_so_fcat-just      = 'C'.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'SOSTA_T'.
  gs_so_fcat-coltext   = '진행상태'.
  gs_so_fcat-outputlen = 16.
  gs_so_fcat-icon      = abap_true.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'PROC_T'.
  gs_so_fcat-coltext   = '조달상태'.
  gs_so_fcat-outputlen = 12.
  gs_so_fcat-just      = 'C'.
  gs_so_fcat-icon      = abap_true.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'VBELN'.
  gs_so_fcat-coltext   = '판매오더번호'.
  gs_so_fcat-outputlen = 13.
  gs_so_fcat-hotspot   = abap_true.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'KUNNR'.
  gs_so_fcat-coltext   = '고객번호'.
  gs_so_fcat-outputlen = 11.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'NAME1'.
  gs_so_fcat-coltext   = '고객명'.
  gs_so_fcat-outputlen = 18.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'PLIFZ'.
  gs_so_fcat-coltext   = '조달소요일'.
  gs_so_fcat-outputlen = 11.
  gs_so_fcat-just      = 'C'.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'REQDT'.
  gs_so_fcat-coltext   = '요청납기일'.
  gs_so_fcat-outputlen = 11.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'ITM_CNT'.
  gs_so_fcat-coltext   = '품목수'.
  gs_so_fcat-outputlen = 7.
  gs_so_fcat-just      = 'C'.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'AUDAT'.
  gs_so_fcat-coltext   = '주문일자'.
  gs_so_fcat-outputlen = 10.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname  = 'TOTAM'.
  gs_so_fcat-coltext    = '총금액'.
  gs_so_fcat-outputlen  = 16.
  gs_so_fcat-decimals_o = '0'.
  APPEND gs_so_fcat TO gt_so_fcat.

  CLEAR gs_so_fcat.
  gs_so_fcat-fieldname = 'WAERS'.
  gs_so_fcat-coltext   = '통화'.
  gs_so_fcat-outputlen = 6.
  APPEND gs_so_fcat TO gt_so_fcat.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM display_so_detail_alv
"&---------------------------------------------------------------------*
FORM display_so_detail_alv.

  IF go_so_detail_container IS INITIAL.

    CREATE OBJECT go_so_detail_container
      EXPORTING
        container_name = 'CC_SO_DETAIL'.

    CREATE OBJECT go_so_detail_grid
      EXPORTING
        i_parent = go_so_detail_container.

    PERFORM set_so_detail_fieldcat.

"---------------------------------------------------------------------*
" 데이터가 없는 상태에서 처음 그려도 컬럼이 잘리지 않도록 폭을 고정
"---------------------------------------------------------------------*
    LOOP AT gt_so_detail_fcat ASSIGNING FIELD-SYMBOL(<ls_det_fcat>).

      CASE <ls_det_fcat>-fieldname.
        WHEN 'POSNR'.
          <ls_det_fcat>-outputlen = 6.
        WHEN 'MATNR'.
          <ls_det_fcat>-outputlen = 16.
        WHEN 'MAKTX'.
          <ls_det_fcat>-outputlen = 18.
        WHEN 'WERKS'.
          <ls_det_fcat>-outputlen = 7.
        WHEN 'KWMENG'.
          <ls_det_fcat>-outputlen = 10.
        WHEN 'MEINS'.
          <ls_det_fcat>-outputlen = 5.
        WHEN 'REQDT'.
          <ls_det_fcat>-outputlen = 11.
        WHEN 'NETPR'.
          <ls_det_fcat>-outputlen = 13.
        WHEN 'DISRT'.
          <ls_det_fcat>-outputlen = 8.
        WHEN 'NETAM' OR 'TOTAM'.
          <ls_det_fcat>-outputlen = 15.
        WHEN 'TAXAM'.
          <ls_det_fcat>-outputlen = 13.
        WHEN 'LGORT' OR 'DISAM' OR 'TAXRT'.
          <ls_det_fcat>-no_out = abap_true.
      ENDCASE.

    ENDLOOP.

" 상세 데이터를 먼저 읽은 경우 get_so_detail 에서 정한 제목(SO번호 포함) 유지
    DATA(lv_det_title) = gs_so_detail_layo-grid_title.

    CLEAR gs_so_detail_layo.

    IF lv_det_title IS INITIAL.
      lv_det_title = '판매오더 상세정보'.
    ENDIF.

    gs_so_detail_layo-grid_title =
    lv_det_title.

    gs_so_detail_layo-zebra =
    abap_true.

    gs_so_detail_layo-cwidth_opt =
    abap_false.

    gs_so_detail_layo-ctab_fname = 'CELL_COLOR'.

    PERFORM set_toolbar_exclude.

    CALL METHOD go_so_detail_grid->set_table_for_first_display
      EXPORTING
        is_layout            = gs_so_detail_layo
        it_toolbar_excluding = gt_exclude
      CHANGING
        it_outtab            = gt_so_detail
        it_fieldcatalog      = gt_so_detail_fcat.

  ELSE.

    CALL METHOD go_so_detail_grid->refresh_table_display.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& Form GET_SO_DETAIL
"&---------------------------------------------------------------------*
FORM get_so_detail
  USING
    pv_index TYPE i.

  DATA:
    ls_so_list TYPE ty_so_list.

  READ TABLE gt_so_list
    INTO ls_so_list
    INDEX pv_index.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  CLEAR gt_so_detail.

  SELECT
    a~posnr,
    a~matnr,
    b~maktx,
    a~werks,
    a~lgort,
    a~kwmeng,
    a~meins,
    a~reqdt,
    a~itmst,
    a~netpr,
    a~disrt,
    a~disam,
    a~netam,
    a~taxrt,
    a~taxam,
    a~totam,
    h~waers
    FROM ztsda00020 AS a
    LEFT OUTER JOIN ztcma00020 AS b
      ON b~matnr = a~matnr
    LEFT OUTER JOIN ztsda00010 AS h
      ON h~vbeln = a~vbeln
    WHERE a~vbeln = @ls_so_list-vbeln
    ORDER BY a~posnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_so_detail.

  LOOP AT gt_so_detail ASSIGNING FIELD-SYMBOL(<fs_det>).
    SELECT SINGLE ordqt, sumqt, avlqt
      FROM ztmma00150
      WHERE vbeln = @ls_so_list-vbeln
        AND posnr = @<fs_det>-posnr
      INTO @DATA(ls_rsv).
    IF sy-subrc <> 0 OR ls_rsv-ordqt - ls_rsv-sumqt - ls_rsv-avlqt <= 0.
      <fs_det>-itmst = '재고확보'.
    ELSE.
      <fs_det>-itmst = '조달중'.
      APPEND VALUE lvc_s_scol(
        fname = 'ITMST' color-col = 3 color-int = 1
      ) TO <fs_det>-cell_color.
    ENDIF.
  ENDLOOP.

" 상세 ALV 제목에 선택한 판매오더번호 / 고객명 표시
  gs_so_detail_layo-grid_title =
    |판매오더 { ls_so_list-vbeln } 상세정보 ({ ls_so_list-name1 })|.

  IF go_so_detail_grid IS BOUND.

    go_so_detail_grid->set_gridtitle(
      i_gridtitle = gs_so_detail_layo-grid_title ).

    CALL METHOD go_so_detail_grid->refresh_table_display.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM set_so_detail_fieldcat
"&---------------------------------------------------------------------*
FORM set_so_detail_fieldcat.

  CLEAR gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'POSNR'.
  gs_so_detail_fcat-coltext   = 'Item'.
  gs_so_detail_fcat-outputlen = 6.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'MATNR'.
  gs_so_detail_fcat-coltext   = '자재번호'.
  gs_so_detail_fcat-outputlen = 15.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'MAKTX'.
  gs_so_detail_fcat-coltext   = '자재명'.
  gs_so_detail_fcat-outputlen = 18.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'WERKS'.
  gs_so_detail_fcat-coltext   = '플랜트'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'LGORT'.
  gs_so_detail_fcat-coltext   = '저장위치'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'KWMENG'.
  gs_so_detail_fcat-coltext   = '주문수량'.
  gs_so_detail_fcat-decimals_o = '0'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'MEINS'.
  gs_so_detail_fcat-coltext   = '단위'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'REQDT'.
  gs_so_detail_fcat-coltext   = '요청납기일'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'ITMST'.
  gs_so_detail_fcat-coltext   = '조달상태'.
  gs_so_detail_fcat-outputlen = 10.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'NETPR'.
  gs_so_detail_fcat-coltext   = '기본단가'.
  gs_so_detail_fcat-decimals_o = '0'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'DISRT'.
  gs_so_detail_fcat-coltext   = '할인율(%)'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'DISAM'.
  gs_so_detail_fcat-coltext   = '할인금액'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'NETAM'.
  gs_so_detail_fcat-coltext   = '공급가액'.
  gs_so_detail_fcat-decimals_o = '0'.
  gs_so_detail_fcat-do_sum    = abap_true.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'TAXRT'.
  gs_so_detail_fcat-coltext   = '세율'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'TAXAM'.
  gs_so_detail_fcat-coltext   = '세액'.
  gs_so_detail_fcat-decimals_o = '0'.
  gs_so_detail_fcat-do_sum    = abap_true.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'TOTAM'.
  gs_so_detail_fcat-coltext   = '최종금액'.
  gs_so_detail_fcat-decimals_o = '0'.
  gs_so_detail_fcat-do_sum    = abap_true.
  gs_so_detail_fcat-emphasize = 'C110'.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

  CLEAR gs_so_detail_fcat.
  gs_so_detail_fcat-fieldname = 'WAERS'.
  gs_so_detail_fcat-coltext   = '통화'.
  gs_so_detail_fcat-outputlen = 6.
  APPEND gs_so_detail_fcat TO gt_so_detail_fcat.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM f4_matnr
"&---------------------------------------------------------------------*
" 자재번호 F4 : 화면에 입력된 고객이 주문할 수 있는 자재만 보여 줌
"  - 기준 : ZTCMA00060(고객-자재 판매조건)에 오늘 유효한 조건이 있는 자재
"  - 고객번호가 비어 있으면 목록을 띄우지 않고 고객번호 먼저 입력하도록 안내
"  - 선택한 자재의 자재명/단위는 기존처럼 화면에 바로 반영
"----------------------------------------------------------------------*
FORM f4_matnr.

  TYPES:
    BEGIN OF ty_matnr_f4,
      matnr TYPE ztcma00020-matnr,
      maktx TYPE ztcma00020-maktx,
    END OF ty_matnr_f4.

  DATA:
    lt_matnr_f4 TYPE STANDARD TABLE OF ty_matnr_f4,
    lt_return   TYPE STANDARD TABLE OF ddshretval,
    ls_return   TYPE ddshretval,
    lt_dynp     TYPE STANDARD TABLE OF dynpread,
    ls_dynp     TYPE dynpread,
    lv_kunnr    TYPE ztcma00060-kunnr.

"---------------------------------------------------------------------*
" 1. 화면에 입력된 고객번호 읽기
"    F4(VALUE-REQUEST) 시점에는 사용자가 방금 입력한 값이
"    아직 p_kunnr 변수로 넘어오지 않으므로 DYNP_VALUES_READ로 직접 읽음
"---------------------------------------------------------------------*
  CLEAR ls_dynp.
  ls_dynp-fieldname = 'P_KUNNR'.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname               = sy-repid
      dynumb               = sy-dynnr
    TABLES
      dynpfields           = lt_dynp
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      invalid_parameter    = 7
      undefind_error       = 8
      double_conversion    = 9
      stepl_not_found      = 10
      OTHERS               = 11.

  IF sy-subrc = 0.
    READ TABLE lt_dynp INTO ls_dynp INDEX 1.
    IF sy-subrc = 0.
      lv_kunnr = ls_dynp-fieldvalue.
    ENDIF.
  ENDIF.

" 화면 값을 직접 읽으면 소문자가 들어올 수 있어 대문자로 맞춤
  TRANSLATE lv_kunnr TO UPPER CASE.

"---------------------------------------------------------------------*
" 2. 고객번호가 없으면 자재 목록을 띄우지 않음
"    (어느 고객의 판매조건으로 걸러야 할지 알 수 없기 때문)
"---------------------------------------------------------------------*
  IF lv_kunnr IS INITIAL.
    MESSAGE s020(zmsga) WITH '고객번호' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

"---------------------------------------------------------------------*
" 3. 해당 고객이 주문 가능한 자재만 조회
"    - ZTCMA00020 : 판매 가능(slsyn = 'Y') + 사용 중(actyn = 'Y') 자재
"    - ZTCMA00060 : 이 고객의 판매조건이 오늘 날짜에 유효하고 사용 중
"    - 판매조건이 기간별로 여러 건 있어도 자재는 한 번만 나오도록 DISTINCT
"    ※ PAI 검증(고객-자재 판매조건 체크)과 같은 조건이라
"      F4에서 고른 자재는 검증에서 막히지 않음
"---------------------------------------------------------------------*
  SELECT DISTINCT
    m~matnr,
    m~maktx
    FROM ztcma00020 AS m
    INNER JOIN ztcma00060 AS c
      ON c~matnr = m~matnr
    WHERE c~kunnr  = @lv_kunnr
      AND c~vfrom <= @sy-datum
      AND c~vto   >= @sy-datum
      AND c~actyn  = 'Y'
      AND m~slsyn  = 'Y'
      AND m~actyn  = 'Y'
    INTO TABLE @lt_matnr_f4.

" 이 고객에게 등록된 판매조건이 하나도 없으면 안내 후 종료
  IF lt_matnr_f4 IS INITIAL.

    MESSAGE i040(zmsga).
    RETURN.

  ENDIF.

  SORT lt_matnr_f4 BY matnr.

"---------------------------------------------------------------------*
" 4. 검색도움말 팝업 표시
"---------------------------------------------------------------------*
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'MATNR'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'P_MATNR'
      value_org       = 'S'
    TABLES
      value_tab       = lt_matnr_f4
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

" 사용자가 팝업을 그냥 닫으면 선택값이 없으므로 종료
  READ TABLE lt_return
  INTO ls_return
  INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  p_matnr = ls_return-fieldval.

"---------------------------------------------------------------------*
" 5. 선택한 자재의 자재명/단위를 읽어서 화면에 바로 반영
"    (F4 시점에는 PBO가 다시 돌지 않으므로 DYNP_VALUES_UPDATE로 직접 갱신)
"---------------------------------------------------------------------*
  CLEAR:
  p_maktx,
  gv_meins.

  SELECT SINGLE
  maktx,
  meins
  FROM ztcma00020
  WHERE matnr = @p_matnr
  INTO (@p_maktx, @gv_meins).

  CLEAR lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'P_MATNR'.
  ls_dynp-fieldvalue = p_matnr.
  APPEND ls_dynp TO lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'P_MAKTX'.
  ls_dynp-fieldvalue = p_maktx.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp.

ENDFORM.




"&---------------------------------------------------------------------*
"& FORM f4_kunnr
"&---------------------------------------------------------------------*
FORM f4_kunnr.

  TYPES:
    BEGIN OF ty_kunnr_f4,
      kunnr TYPE ztcma00050-kunnr,
      name1 TYPE ztcma00050-name1,
    END OF ty_kunnr_f4.

  DATA:
    lt_kunnr_f4 TYPE STANDARD TABLE OF ty_kunnr_f4,
    lt_return   TYPE STANDARD TABLE OF ddshretval,
    ls_return   TYPE ddshretval,
    lt_dynp     TYPE STANDARD TABLE OF dynpread,
    ls_dynp     TYPE dynpread.

  SELECT
  kunnr,
  name1
  FROM ztcma00050
  WHERE trdyn = 'Y'
  AND blkyn = 'N'
  AND actyn = 'Y'
  INTO TABLE @lt_kunnr_f4.

  IF lt_kunnr_f4 IS INITIAL.

    MESSAGE i040(zmsga).
    RETURN.

  ENDIF.

  SORT lt_kunnr_f4 BY kunnr.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'KUNNR'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'P_KUNNR'
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

  READ TABLE lt_return
  INTO ls_return
  INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  p_kunnr = ls_return-fieldval.

  CLEAR p_name1.

  SELECT SINGLE name1
  FROM ztcma00050
  WHERE kunnr = @p_kunnr
  INTO @p_name1.

  CLEAR lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'P_KUNNR'.
  ls_dynp-fieldvalue = p_kunnr.
  APPEND ls_dynp TO lt_dynp.

  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'P_NAME1'.
  ls_dynp-fieldvalue = p_name1.
  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM determine_stock_location
"&---------------------------------------------------------------------*
" 자재 기준 플랜트 / 저장위치 자동 결정
"----------------------------------------------------------------------*
FORM determine_stock_location.

  TYPES:
    BEGIN OF ty_stock,
      werks TYPE ztmma00070-werks,
      lgort TYPE ztmma00070-lgort,
      stqty TYPE ztmma00070-stqty,
      rsqty TYPE ztmma00070-rsqty,
      avqty TYPE ztmma00070-stqty,
    END OF ty_stock.

  DATA:
    lt_stock TYPE STANDARD TABLE OF ty_stock,
    ls_stock TYPE ty_stock.

  CLEAR:
  p_werks,
  p_lgort.

  IF p_matnr IS INITIAL.
    RETURN.
  ENDIF.

  SELECT
  werks,
  lgort,
  stqty,
  rsqty
  FROM ztmma00070
  WHERE matnr = @p_matnr
  INTO CORRESPONDING FIELDS OF TABLE @lt_stock.

  IF lt_stock IS INITIAL.
    RETURN.
  ENDIF.

  LOOP AT lt_stock INTO ls_stock.

    ls_stock-avqty = ls_stock-stqty.

    IF ls_stock-avqty < 0.
      ls_stock-avqty = 0.
    ENDIF.

    MODIFY lt_stock FROM ls_stock.

  ENDLOOP.

  SORT lt_stock
  BY avqty DESCENDING
  werks ASCENDING
  lgort ASCENDING.

  READ TABLE lt_stock
  INTO ls_stock
  INDEX 1.

  IF sy-subrc = 0.

    p_werks = ls_stock-werks.
    p_lgort = ls_stock-lgort.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM determine_order_location
"&---------------------------------------------------------------------*
FORM determine_order_location
CHANGING
cs_result TYPE ty_valid_result.

  TYPES:
    BEGIN OF ty_stock,
      werks TYPE ztmma00070-werks,
      lgort TYPE ztmma00070-lgort,
      stqty TYPE ztmma00070-stqty,
      rsqty TYPE ztmma00070-rsqty,
      avqty TYPE ztmma00070-stqty,
    END OF ty_stock.

  DATA:
    lt_stock TYPE STANDARD TABLE OF ty_stock,
    ls_stock TYPE ty_stock.

  CLEAR:
  cs_result-werks,
  cs_result-lgort.

  IF cs_result-matnr IS INITIAL.
    RETURN.
  ENDIF.

  SELECT
  werks,
  lgort,
  stqty,
  rsqty
  FROM ztmma00070
  WHERE matnr = @cs_result-matnr
  INTO CORRESPONDING FIELDS OF TABLE @lt_stock.

  IF lt_stock IS INITIAL.

    PERFORM add_valid_error
    USING
    '플랜트/저장위치'
    '자재의 플랜트 및 저장위치 정보를 결정할 수 없습니다.'
    CHANGING
    cs_result.

    RETURN.

  ENDIF.

  LOOP AT lt_stock INTO ls_stock.

    ls_stock-avqty = ls_stock-stqty.

    IF ls_stock-avqty < 0.
      ls_stock-avqty = 0.
    ENDIF.

    MODIFY lt_stock FROM ls_stock.

  ENDLOOP.

  SORT lt_stock
  BY avqty DESCENDING
  werks ASCENDING
  lgort ASCENDING.

  READ TABLE lt_stock
  INTO ls_stock
  INDEX 1.

  IF sy-subrc = 0.

    cs_result-werks = ls_stock-werks.
    cs_result-lgort = ls_stock-lgort.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM validate_selection_input
"&---------------------------------------------------------------------*
FORM validate_selection_input.

  DATA:
    lv_kunnr TYPE ztcma00050-kunnr,
    lv_matnr TYPE ztcma00020-matnr.

"---------------------------------------------------------------------*
" 단건 입력 (Excel 모드가 아니면 단건으로 처리)
"---------------------------------------------------------------------*
  IF p_excel <> abap_true.

"--- 고객번호
    IF p_kunnr IS INITIAL.
      MESSAGE e020(zmsga) WITH '고객번호'.
    ENDIF.

    IF strlen( p_kunnr ) <> 10
    OR p_kunnr+0(1) <> 'C'
    OR p_kunnr+1(9) CN '0123456789'.
      MESSAGE e023(zmsga) WITH '고객번호(C+숫자 9자리)'.
    ENDIF.

    CLEAR lv_kunnr.

    SELECT SINGLE kunnr
      FROM ztcma00050
      WHERE kunnr = @p_kunnr
        AND trdyn = 'Y'
        AND blkyn = 'N'
        AND actyn = 'Y'
      INTO @lv_kunnr.

    IF sy-subrc <> 0.
      MESSAGE e035(zmsga) WITH '거래 불가 고객번호'.
    ENDIF.

"--- 자재번호
    IF p_matnr IS INITIAL.
      MESSAGE e020(zmsga) WITH '자재번호'.
    ENDIF.

    CLEAR lv_matnr.

    SELECT SINGLE matnr
      FROM ztcma00020
      WHERE matnr = @p_matnr
        AND slsyn = 'Y'
        AND actyn = 'Y'
      INTO @lv_matnr.

    IF sy-subrc <> 0.
      MESSAGE e035(zmsga) WITH '판매 불가 자재번호'.
    ENDIF.

"--- 고객-자재 판매조건
    SELECT SINGLE unitp
      FROM ztcma00060
      WHERE matnr = @p_matnr
        AND kunnr = @p_kunnr
        AND vfrom <= @sy-datum
        AND vto   >= @sy-datum
        AND actyn = 'Y'
      INTO @DATA(lv_unitp).

    IF sy-subrc <> 0.
      MESSAGE e034(zmsga) WITH '고객-자재 판매조건'.
    ENDIF.


"--- 주문수량
    IF p_kmeng IS INITIAL
    OR p_kmeng <= 0.
      MESSAGE e028(zmsga) WITH '주문수량'.
    ENDIF.

"--- 요청납기일
    IF p_reqfr IS INITIAL.
      MESSAGE e020(zmsga) WITH '요청납기일'.
    ENDIF.

    IF p_reqfr < sy-datum.
      MESSAGE e025(zmsga) WITH '요청납기일' '오늘'.
    ENDIF.

    IF p_reqto IS NOT INITIAL
    AND p_reqto < sy-datum.
      MESSAGE e025(zmsga) WITH '요청납기 종료일' '오늘'.
    ENDIF.

    IF p_reqto IS NOT INITIAL
    AND p_reqfr > p_reqto.
      MESSAGE e026(zmsga).
    ENDIF.

"---------------------------------------------------------------------*
" Excel Upload
"---------------------------------------------------------------------*
  ELSE.

    IF p_file IS INITIAL.
      MESSAGE e021(zmsga) WITH 'Excel 파일'.
    ENDIF.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM convert_excel_date
"&---------------------------------------------------------------------*
FORM convert_excel_date
USING
pv_value TYPE alsmex_tabline-value
CHANGING
cv_date  TYPE sy-datum.

  DATA:
  lv_date TYPE string.

  CLEAR cv_date.

  lv_date = pv_value.

  CONDENSE lv_date NO-GAPS.

  REPLACE ALL OCCURRENCES OF '.' IN lv_date
  WITH ''.

  REPLACE ALL OCCURRENCES OF '-' IN lv_date
  WITH ''.

  REPLACE ALL OCCURRENCES OF '/' IN lv_date
  WITH ''.

  IF strlen( lv_date ) = 8
  AND lv_date CO '0123456789'.

    cv_date = lv_date.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM select_all_valid
"&---------------------------------------------------------------------*
FORM select_all_valid.

  DATA:
    lt_rows TYPE lvc_t_row,
    ls_row  TYPE lvc_s_row.

  CLEAR lt_rows.

  LOOP AT gt_valid_result INTO gs_valid_result.

    IF gs_valid_result-order_ok = 'Y'.

      CLEAR ls_row.
      ls_row-index = sy-tabix.
      APPEND ls_row TO lt_rows.

    ENDIF.

  ENDLOOP.

  IF go_valid_grid IS BOUND.

    CALL METHOD go_valid_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM deselect_all_valid
"&---------------------------------------------------------------------*
FORM deselect_all_valid.

  DATA:
  lt_rows TYPE lvc_t_row.

  CLEAR lt_rows.

  IF go_valid_grid IS BOUND.

    CALL METHOD go_valid_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM request_mm_procurement
"&---------------------------------------------------------------------*
FORM request_mm_procurement
USING
pv_vbeln TYPE ztsda00010-vbeln
pv_posnr TYPE ztsda00020-posnr
pv_matnr TYPE ztsda00020-matnr
pv_werks TYPE ztsda00020-werks
pv_lgort TYPE ztsda00020-lgort
pv_shqty TYPE ztmma00070-stqty
pv_reqdt TYPE ztsda00020-reqdt.

"---------------------------------------------------------------------*
" mm 연계 Function Module 확정 후 구현
"---------------------------------------------------------------------*

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM set_valid_row_color
"&---------------------------------------------------------------------*
FORM set_valid_row_color
  CHANGING
    cs_result TYPE ty_valid_result.

  DATA:
    ls_color TYPE lvc_s_scol.

  CLEAR:
    cs_result-row_color,
    cs_result-cell_color.

"---------------------------------------------------------------------*
" 기생성 SO → 주요 정보만 파란 글씨
"---------------------------------------------------------------------*
  IF cs_result-error_field = '기생성 SO'.

    CLEAR ls_color.
    ls_color-fname     = 'KUNNR'.
    ls_color-color-col = col_key.
    ls_color-color-int = 0.
    ls_color-color-inv = 0.
    APPEND ls_color TO cs_result-cell_color.

    CLEAR ls_color.
    ls_color-fname     = 'NAME1'.
    ls_color-color-col = col_key.
    ls_color-color-int = 0.
    ls_color-color-inv = 0.
    APPEND ls_color TO cs_result-cell_color.

    CLEAR ls_color.
    ls_color-fname     = 'MATNR'.
    ls_color-color-col = col_key.
    ls_color-color-int = 0.
    ls_color-color-inv = 0.
    APPEND ls_color TO cs_result-cell_color.

    CLEAR ls_color.
    ls_color-fname     = 'MAKTX'.
    ls_color-color-col = col_key.
    ls_color-color-int = 0.
    ls_color-color-inv = 0.
    APPEND ls_color TO cs_result-cell_color.

    CLEAR ls_color.
    ls_color-fname     = 'KWMENG'.
    ls_color-color-col = col_key.
    ls_color-color-int = 0.
    ls_color-color-inv = 0.
    APPEND ls_color TO cs_result-cell_color.

    CLEAR ls_color.
    ls_color-fname     = 'REQDT'.
    ls_color-color-col = col_key.
    ls_color-color-int = 0.
    ls_color-color-inv = 0.
    APPEND ls_color TO cs_result-cell_color.

" 오류항목 칸은 주황 배경으로 경고 강조
    CLEAR ls_color.
    ls_color-fname     = 'ERROR_FIELD'.
    ls_color-color-col = col_group.
    ls_color-color-int = 1.
    ls_color-color-inv = 0.
    APPEND ls_color TO cs_result-cell_color.

    CLEAR ls_color.
    ls_color-fname     = 'RESULT_TEXT'.
    ls_color-color-col = col_key.
    ls_color-color-int = 0.
    ls_color-color-inv = 0.
    APPEND ls_color TO cs_result-cell_color.

    RETURN.

  ENDIF.

"---------------------------------------------------------------------*
" 주문 불가 → 오류항목 빨강 배경 / 검증내용 빨강 글씨
"---------------------------------------------------------------------*
  IF cs_result-order_ok = 'N'.

    IF cs_result-error_field IS NOT INITIAL.

      CLEAR ls_color.
      ls_color-fname     = 'ERROR_FIELD'.
      ls_color-color-col = col_negative.
      ls_color-color-int = 1.
      ls_color-color-inv = 0.
      APPEND ls_color TO cs_result-cell_color.

    ENDIF.

    CLEAR ls_color.
    ls_color-fname     = 'RESULT_TEXT'.
    ls_color-color-col = col_negative.
    ls_color-color-int = 0.
    ls_color-color-inv = 1.
    APPEND ls_color TO cs_result-cell_color.

    RETURN.

  ENDIF.

"---------------------------------------------------------------------*
" 조달 필요 / 정상 주문
"---------------------------------------------------------------------*
  IF cs_result-procure_need = 'Y'.

    cs_result-row_color = 'C310'.

"---------------------------------------------------------------------*
" 부족수량이 있으면 부족수량 셀만 파란색으로 강조 (조달 필요)
"---------------------------------------------------------------------*
    IF cs_result-shiqty > 0.

      CLEAR ls_color.
      ls_color-fname     = 'SHIQTY'.
      ls_color-color-col = col_heading.
      ls_color-color-int = 1.
      ls_color-color-inv = 0.
      APPEND ls_color TO cs_result-cell_color.

    ENDIF.

  ELSEIF cs_result-order_ok = 'Y'.

    cs_result-row_color = 'C510'.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM save_new_so_memory
"&---------------------------------------------------------------------*
FORM save_new_so_memory.

  EXPORT
    gt_new_so = gt_new_so
    TO MEMORY ID gc_mem_new_so.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM load_new_so_memory
"&---------------------------------------------------------------------*
FORM load_new_so_memory.

  CLEAR gt_new_so.

  IMPORT
    gt_new_so = gt_new_so
    FROM MEMORY ID gc_mem_new_so.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM clear_new_so_memory
"&---------------------------------------------------------------------*
" 새로고침 / 프로그램 종료 시 강조 해제
"----------------------------------------------------------------------*
FORM clear_new_so_memory.

  CLEAR gt_new_so.

  FREE MEMORY ID gc_mem_new_so.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM set_display_text
"&---------------------------------------------------------------------*
" 고객명 / 자재명을 입력칸(박스) 없이 글자로만 표시
"----------------------------------------------------------------------*
FORM set_display_text.

  gv_tnam = p_name1.
  gv_tmak = p_maktx.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM set_req_date_default
"&---------------------------------------------------------------------*
" 자재를 바꾸면 ZTCMA00040(공급업체 Lead Time)을 읽어
" 요청납기일 기본값 = 오늘 ~ 오늘 + Lead Time 으로 채움
" (같은 자재로 Enter를 다시 눌러도 사용자가 고친 날짜는 유지)
"----------------------------------------------------------------------*
FORM set_req_date_default.

  DATA lv_plifz TYPE ztcma00040-plifz.

  IF p_matnr IS INITIAL
     OR p_matnr = gv_last_matnr.
    RETURN.
  ENDIF.

  gv_last_matnr = p_matnr.

  SELECT SINGLE plifz
    FROM ztcma00040
    WHERE matnr = @p_matnr
      AND priok = '0'
      AND valfr <= @sy-datum
      AND valto >= @sy-datum
      AND actyn = 'Y'
    INTO @lv_plifz.

  IF sy-subrc = 0
     AND lv_plifz > 0.

    p_reqfr = sy-datum.
    p_reqto = sy-datum + lv_plifz.

  ENDIF.

ENDFORM.



"&---------------------------------------------------------------------*
"& FORM clear_valid_selection
"&---------------------------------------------------------------------*
" 주문 검증결과 ALV의 행 선택을 모두 해제
" (생성/삭제 후 이전 선택이 남아 있어 다시 생성되는 것을 방지)
"----------------------------------------------------------------------*
FORM clear_valid_selection.

  DATA lt_rows TYPE lvc_t_row.

  IF go_valid_grid IS BOUND.

    CALL METHOD go_valid_grid->set_selected_rows
      EXPORTING
        it_index_rows = lt_rows.

    CALL METHOD cl_gui_cfw=>flush.

  ENDIF.

ENDFORM.
