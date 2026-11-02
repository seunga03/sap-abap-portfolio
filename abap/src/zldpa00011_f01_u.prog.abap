*&---------------------------------------------------------------------*
*& Include          ZLDPA00011_U_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form zz_set_file_f4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_file_f4 .

  DATA: lt_filet  TYPE filetable,
        ls_file   TYPE file_table,
        lv_rcode  TYPE i,
        lv_action TYPE i.

  CHECK rb_file1 = abap_true.

  CLEAR: lt_filet, lv_rcode, lv_action.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title      = '고객 수요정보 원문 파일 선택'
      default_extension = 'txt'
      file_filter       = 'TXT/PDF 파일 (*.txt;*.pdf)|*.txt;*.pdf|'
      multiselection     = abap_false
    CHANGING
      file_table        = lt_filet
      rc                = lv_rcode
      user_action       = lv_action
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5
  ).

  IF sy-subrc <> 0.
    MESSAGE '파일 선택창을 열 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF lv_action <> cl_gui_frontend_services=>action_ok.
    RETURN.
  ENDIF.

  IF lv_rcode <= 0.
    RETURN.
  ENDIF.

  READ TABLE lt_filet INTO ls_file INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  pa_file1 = ls_file-filename.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_modify_screen
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_modify_screen .

  LOOP AT SCREEN.
    IF screen-group1 = 'FIL'.
      IF rb_file1 = abap_true.
        screen-active = 1.
        screen-input  = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form 1000_onli
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM 1000_onli .

  DATA: lv_kunnr    TYPE ztcma00050-kunnr,
        lv_filename TYPE string,
        lv_ext      TYPE string,
        lv_exist    TYPE abap_bool.


  IF pa_kunnr IS INITIAL.
    MESSAGE e020 WITH '고객코드'. " &을(를) 입력해 주십시오.
  ENDIF.

  """" 고객 존재 여부
  SELECT SINGLE kunnr
    FROM ztcma00050
    INTO @lv_kunnr
   WHERE kunnr = @pa_kunnr.

  IF sy-subrc <> 0.
    MESSAGE e034 WITH '고객코드'. " & 값이 존재하지 않습니다.
  ENDIF.

  """ 파일업로드 선택 시 검증
  IF rb_file1 = abap_true.

    " 파일명 필수
    IF pa_file1 IS INITIAL.
      MESSAGE e021 WITH '파일'.
    ENDIF.

    lv_filename = pa_file1.

    " 확장자 추출
    FIND REGEX '\.([^.]+)$'
      IN lv_filename
      SUBMATCHES lv_ext.

    IF sy-subrc <> 0.
      MESSAGE e300.
    ENDIF.

    TRANSLATE lv_ext TO UPPER CASE.

    " 파일 형식 검증
    IF lv_ext <> 'PDF' AND lv_ext <> 'TXT'.
      MESSAGE e300.
    ENDIF.

    " 실제 파일 존재 여부 확인
    cl_gui_frontend_services=>file_exist(
      EXPORTING
        file   = lv_filename
      RECEIVING
        result = lv_exist
      EXCEPTIONS
        OTHERS = 1
    ).

    IF sy-subrc <> 0 OR lv_exist <> abap_true.
      MESSAGE '선택한 파일이 존재하지 않습니다.'
        TYPE 'E'.
    ENDIF.

  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_set_header_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_header_data .

  CLEAR: gv_name1, gv_ttext, gv_itext, gv_rtype.

  """ 고객명
  SELECT SINGLE name1
    FROM ztcma00050
    INTO @gv_name1
   WHERE kunnr = @pa_kunnr.

  """ 자료유형 Text
  IF rb_auto1 = abap_true.
    gv_ttext = '자동분류'.
    gv_rtype = zlea_a.
  ELSEIF rb_plan1 = abap_true.
    gv_ttext = '생산계획'.
    gv_rtype = zlea_p.
  ELSEIF rb_event = abap_true.
    gv_ttext = 'Event'.
    gv_rtype = zlea_e.
  ENDIF.

  """ 입력방식
  IF rb_direc = abap_true.
    gv_itext = '직접입력'.
  ELSE.
    gv_itext = '파일업로드'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_editor_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_editor_text .

  CLEAR gv_raw_text.

  CHECK go_text_editor IS BOUND.

  CALL METHOD go_text_editor->get_textstream
    IMPORTING
      text   = gv_raw_text       " Text as String with Carriage Returns and Linefeeds
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc <> 0.
    MESSAGE e307. " 원문을 읽는 중 오류가 발생했습니다.
  ENDIF.

  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      cntl_system_error = 1                " cntl_system_error
      cntl_error        = 2                " cntl_error
      OTHERS            = 3.

  IF sy-subrc <> 0.
    MESSAGE e308. " Text Editor 데이터 동기화 중 오류가 발생했습니다.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_editor_hint                                 [신규 추가]
*&---------------------------------------------------------------------*
*& 편집기가 비어 있을 때(업로드된 파일 내용이 없을 때) 안내문을
*& 집어넣는다.
*&  - 이 안내문은 "회색 placeholder"가 아니라 보통 검은 글씨로
*&    편집기에 들어간다. SAP GUI Text Editor(cl_gui_textedit)는
*&    자체적으로 흐린 힌트 글자를 지원하지 않기 때문이다.
*&  - 그래서 안내문이 남아 있는 채로 [AI 추출]을 눌러도 막을 수
*&    있도록, zz_exe_ai_analytics 쪽에서 편집기 내용이 이 안내문과
*&    똑같은지 한 번 더 검사한다 (아래 FORM zz_exe_ai_analytics 참고).
*&  - O01의 MODULE create_text_editor_0100 OUTPUT 에서 편집기를
*&    새로 만든 직후 호출한다.
*&---------------------------------------------------------------------*
FORM zz_set_editor_hint.

  DATA lt_hint TYPE STANDARD TABLE OF char255.

  " 편집기 객체가 없으면 넣을 곳이 없으므로 중단
  CHECK go_text_editor IS BOUND.

  " 이미 업로드된 TXT 내용이 있으면(gt_text) 안내문을 덮어쓰지 않는다
  CHECK gt_text IS INITIAL.

  CLEAR lt_hint.
  APPEND gv_editor_hint TO lt_hint.

  go_text_editor->set_text_as_r3table(
    EXPORTING
      table           = lt_hint
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3
  ).

  IF sy-subrc <> 0.
    " 안내문 표시 실패는 화면 동작에 치명적이지 않으므로 메시지 없이 넘어간다
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_ai_analytics
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_ai_analytics .

  DATA: lt_plan    TYPE STANDARD TABLE OF ty_plan,
        lt_event   TYPE STANDARD TABLE OF ty_event,
        lv_success TYPE abap_bool.

  "---------------------------------------------------------------*
  " [신규 추가] 편집기에 안내문이 그대로 남아 있으면
  " 원문이 없는 것으로 본다.
  " (붙여넣기나 타이핑을 하지 않고 안내문 그대로 [AI 추출]을 누른
  "  경우, 안내문 글자 자체가 AI에 넘어가 이상한 결과가 나오는
  "  것을 막기 위함)
  "---------------------------------------------------------------*
  IF rb_direc = abap_true AND gv_raw_text = gv_editor_hint.
    CLEAR gv_raw_text.
  ENDIF.

  IF rb_file1 = abap_true AND gv_ftype = 'PDF'.
    " PDF 파일 데이터 확인
    IF gt_binary IS INITIAL OR gv_file_length <= 0.
      MESSAGE e303.
    ENDIF.
  ELSE.
    " 직접입력 또는 TXT 원문 확인
    IF gv_raw_text IS INITIAL.
      MESSAGE e304.
    ENDIF.

  ENDIF.

  """ 기준 데이터 조회
  PERFORM zz_get_reference_data.

  """ AI 분석 결과를 임시 테이블로 받음
  PERFORM zz_exe_ai_service CHANGING lt_plan lt_event lv_success.

  """ AI 호출 실패 시 기존 Preview 유지
  IF lv_success <> abap_true.
    RETURN.
  ENDIF.

  """ 분석 결과가 없는 경우
  IF lt_plan IS INITIAL AND lt_event IS INITIAL.
    MESSAGE s309 DISPLAY LIKE 'E'. " AI 분석 결과가 없습니다. 직접 입력해 주십시오.
    RETURN.
  ENDIF.

  """ 성공한 경우에만 기존 Preview 교체
  gt_plan  = lt_plan.
  gt_event = lt_event.

  """ AI 분석 결과 유효성 검증
  PERFORM zz_exe_validate_result.

  """ 분석 결과에 따라 탭 설정
  IF gt_plan IS NOT INITIAL AND gt_event IS INITIAL.
    tab_main-activetab = 'PLAN'.
    gv_dynnr = '0110'.
  ELSEIF gt_plan IS INITIAL AND gt_event IS NOT INITIAL.
    tab_main-activetab = 'EVEN'.
    gv_dynnr = '0120'.
  ENDIF.

  MESSAGE s305. " AI 분석 결과가 생성되었습니다.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_ai_service
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_ai_service CHANGING pt_plan    TYPE STANDARD TABLE
                                pt_event   TYPE STANDARD TABLE
                                pv_success TYPE abap_bool.

  DATA: lt_plan_ai  TYPE zttdpa00010,
        lt_event_ai TYPE zttdpa00020,
        lv_success  TYPE abap_bool,
        lv_message  TYPE string.

  DATA: ls_plan  TYPE ty_plan,
        ls_event TYPE ty_event.

  DATA: lv_material_json TYPE string,
        lv_code_json     TYPE string.

  CLEAR pv_success.
  REFRESH: pt_plan, pt_event.

  """ 자재 마스터 JSON 변환
  lv_material_json = /ui2/cl_json=>serialize(
    data        = gt_ai_material
    pretty_name = /ui2/cl_json=>pretty_mode-low_case
  ).

  """ 공통 코드 JSON 변환
  lv_code_json = /ui2/cl_json=>serialize(
    data        = gt_ai_code
    pretty_name = /ui2/cl_json=>pretty_mode-low_case
  ).

  """ AI Service 호출
  CALL METHOD zcl_dp_ai_service=>extract_customer_demand
    EXPORTING
      iv_type          = gv_rtype
      iv_text          = gv_raw_text
      iv_filename      = gv_fname
      it_binary        = gt_binary
      iv_file_length   = gv_file_length
      iv_material_json = lv_material_json
      iv_code_json     = lv_code_json
    IMPORTING
      et_plan          = lt_plan_ai
      et_event         = lt_event_ai
      ev_success       = lv_success
      ev_message       = lv_message.

  """ 호출 실패 처리
  IF lv_success <> abap_true.
    IF lv_message IS INITIAL.
      MESSAGE s092 DISPLAY LIKE 'E'. " 외부 시스템 호출 중 오류가 발생했습니다.
    ELSE.
      MESSAGE lv_message TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.
    RETURN.
  ENDIF.

  """ 생산계획 Mapping
  LOOP AT lt_plan_ai INTO DATA(ls_plan_ai).

    CLEAR ls_plan.
    MOVE-CORRESPONDING ls_plan_ai TO ls_plan.

    SELECT SINGLE maktx, meins
      FROM ztcma00020
      INTO ( @ls_plan-maktx, @ls_plan-meins )
     WHERE matnr = @ls_plan-matnr.

    PERFORM zz_get_code_name USING 'DP_DIR' ls_plan-change_dir CHANGING ls_plan-change_name.

    APPEND ls_plan TO pt_plan.

  ENDLOOP.

  """ Event Mapping
  LOOP AT lt_event_ai INTO DATA(ls_event_ai).

    CLEAR ls_event.
    MOVE-CORRESPONDING ls_event_ai TO ls_event.

    SELECT SINGLE maktx
      FROM ztcma00020
      INTO @ls_event-maktx
     WHERE matnr = @ls_event-matnr.

    PERFORM zz_get_code_name USING 'DP_EVT' ls_event-event_type CHANGING ls_event-event_name.

    PERFORM zz_get_code_name USING 'DP_DIR' ls_event-impact_dir CHANGING ls_event-impact_name.

    APPEND ls_event TO pt_event.

  ENDLOOP.

  """ 성공 여부 반환
  pv_success = abap_true.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_clear_0100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_clear_0100 .

  " PDF Viewer 해제
  IF go_pdf_viewer IS BOUND.
    go_pdf_viewer->free( ).
    FREE go_pdf_viewer.
  ENDIF.

  IF go_pdf_container IS BOUND.
    go_pdf_container->free( ).
    FREE go_pdf_container.
  ENDIF.

  " PDF Viewer 표시 상태 초기화
  CLEAR: gv_pdf_url, gv_pdf_loaded.

  " Preview 및 검증 결과 초기화
  CLEAR: gt_plan, gt_event, gt_validation,
         gs_plan, gs_event, gs_validation.

  " 원문 및 파일 버퍼 초기화
  CLEAR: gv_raw_text, gt_text, gv_text,
         gt_binary, gv_file_length,
         gv_fname, gv_ftype, pa_file1.

  " 문서번호 초기화
  CLEAR: gv_colno, gv_plnno, gv_evtno.

  " Preview 기본 행 생성
  PERFORM zz_set_initial_rows.

  " Tabstrip 및 Table Control 초기화
  tab_main-activetab = 'PLAN'.
  gv_dynnr           = '0110'.

  tc_plan-top_line  = 1.
  tc_event-top_line = 1.

  " Text Editor 초기화
  IF go_text_editor IS BOUND.

    go_text_editor->set_text_as_r3table(
      EXPORTING
        table   = gt_text
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3
    ).

    IF sy-subrc <> 0.
      MESSAGE 'Text Editor 초기화에 실패했습니다.'
        TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.

    " [신규 추가] 초기화 후 다시 비어 있는 상태이므로 안내문을 띄운다
    PERFORM zz_set_editor_hint.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_load_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_load_file .

  DATA: lv_filename  TYPE string,
        lv_extension TYPE string.

  lv_filename = pa_file1.
  gv_fname    = lv_filename.

  """ 확장자 추출
  FIND REGEX '\.([^.]+)$' IN lv_filename SUBMATCHES lv_extension.

  IF sy-subrc <> 0.
    MESSAGE e300. " PDF 또는 TXT 파일만 지원합니다.
  ENDIF.

  TRANSLATE lv_extension TO UPPER CASE.
  gv_ftype = lv_extension.

  CASE gv_ftype.

    WHEN 'TXT'.
      PERFORM zz_set_upload_text.

    WHEN 'PDF'.
      PERFORM zz_set_upload_pdf.

    WHEN OTHERS.
      MESSAGE e300. " PDF 또는 TXT 파일만 지원합니다.

  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_upload_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_upload_text .

  DATA: lt_string TYPE STANDARD TABLE OF string,
        lv_string TYPE string,
        lv_text   TYPE char255,
        lv_length TYPE i,
        lv_offset TYPE i,
        lv_chunk  TYPE i.

  CLEAR: gt_text, lt_string.

  """ TXT 파일 업로드
  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename = CONV string( pa_file1 )
      filetype = 'ASC'
      codepage = '4110'    " UTF-8
    CHANGING
      data_tab = lt_string
    EXCEPTIONS
      OTHERS   = 1
  ).

  IF sy-subrc <> 0.
    MESSAGE e301. " TXT 파일을 읽을 수 없습니다.
  ENDIF.

  """ 파일 내용을 255자 단위로 분할
  LOOP AT lt_string INTO lv_string.

    lv_length = strlen( lv_string ).
    lv_offset = 0.

    " 빈 줄도 유지
    IF lv_length = 0.
      CLEAR lv_text.
      APPEND lv_text TO gt_text.
      CONTINUE.
    ENDIF.

    WHILE lv_offset < lv_length.

      " 남은 문자열 길이
      lv_chunk = lv_length - lv_offset.

      " 한 번에 최대 255자 처리
      IF lv_chunk > 255.
        lv_chunk = 255.
      ENDIF.

      " 문자열 일부 추출
      CLEAR lv_text.
      lv_text = lv_string+lv_offset(lv_chunk).

      " Text Editor용 테이블에 추가
      APPEND lv_text TO gt_text.

      " 다음 시작 위치로 이동
      lv_offset = lv_offset + lv_chunk.

    ENDWHILE.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_upload_pdf
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_upload_pdf .

  CLEAR: gt_binary, gv_file_length.

  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename    = CONV string( pa_file1 )    " Name of file
      filetype    = 'BIN'                      " File Type (ASCII, Binary)
    IMPORTING
      filelength  = gv_file_length             " File Length
    CHANGING
      data_tab    = gt_binary                  " Transfer table for file contents
    EXCEPTIONS
      OTHERS      = 1
  ).

  IF sy-subrc <> 0.
    MESSAGE e302. " PDF 파일을 읽을 수 없습니다.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_save_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_save_data .

  DATA: lt_plan_db  TYPE STANDARD TABLE OF ztcma00170,
        ls_plan_db  TYPE ztcma00170,
        lt_event_db TYPE STANDARD TABLE OF ztcma00180,
        ls_event_db TYPE ztcma00180.

  DATA lv_iteno TYPE zde_iteno.

  DATA: lv_plan_exists  TYPE abap_bool,
        lv_event_exists TYPE abap_bool.

  " 검증 오류가 있으면 저장 차단
  IF gt_validation IS NOT INITIAL.
    MESSAGE e313. " 검증 오류가 있습니다. 저장할 수 없습니다.
  ENDIF.

  CLEAR: gv_colno, gv_plnno, gv_evtno, lv_plan_exists, lv_event_exists.

  LOOP AT gt_plan INTO gs_plan.
    IF gs_plan-matnr       IS NOT INITIAL OR
       gs_plan-perio       IS NOT INITIAL OR
       gs_plan-plan_qty    IS NOT INITIAL OR
       gs_plan-meins       IS NOT INITIAL OR
       gs_plan-change_dir  IS NOT INITIAL OR
       gs_plan-change_rate IS NOT INITIAL.
      lv_plan_exists = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.

  LOOP AT gt_event INTO gs_event.
    IF gs_event-matnr       IS NOT INITIAL OR
       gs_event-event_type  IS NOT INITIAL OR
       gs_event-valid_from  IS NOT INITIAL OR
       gs_event-valid_to    IS NOT INITIAL OR
       gs_event-impact_dir  IS NOT INITIAL OR
       gs_event-impact_rate IS NOT INITIAL OR
       gs_event-event_text  IS NOT INITIAL.
      lv_event_exists = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF lv_plan_exists <> abap_true AND lv_event_exists <> abap_true.
    MESSAGE e306. " 저장할 데이터가 없습니다.
  ENDIF.

  """ 수집번호
  PERFORM zz_get_next_number USING 'ZDP_COLNO' CHANGING gv_colno.

  """ 생산계획
  IF lv_plan_exists = abap_true.

    PERFORM zz_get_next_number USING 'ZDP_PLNNO' CHANGING gv_plnno.

    CLEAR: lv_iteno.

    LOOP AT gt_plan INTO gs_plan.

      " 완전히 빈 행은 저장하지 않음
      IF gs_plan-matnr       IS INITIAL AND
         gs_plan-perio       IS INITIAL AND
         gs_plan-plan_qty    IS INITIAL AND
         gs_plan-meins       IS INITIAL AND
         gs_plan-change_dir  IS INITIAL AND
         gs_plan-change_rate IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR: ls_plan_db.

      lv_iteno = lv_iteno + 1.

      ls_plan_db-plnno       = gv_plnno.
      ls_plan_db-iteno       = lv_iteno.
      ls_plan_db-colno       = gv_colno.

      ls_plan_db-kunnr       = pa_kunnr.
      ls_plan_db-matnr       = gs_plan-matnr.
      ls_plan_db-perio       = gs_plan-perio.
      ls_plan_db-plan_qty    = gs_plan-plan_qty.
      ls_plan_db-meins       = gs_plan-meins.

      ls_plan_db-change_dir  = gs_plan-change_dir.
      ls_plan_db-change_rate = gs_plan-change_rate.

      ls_plan_db-source       = pa_sourc.
      ls_plan_db-collect_date = pa_coldt.
*      ls_plan_db-raw_text     = gs_plan-raw_text.

      IF gs_plan-raw_text IS INITIAL.
        ls_plan_db-raw_text = gv_raw_text.
      ELSE.
        ls_plan_db-raw_text = gs_plan-raw_text.
      ENDIF.

      ls_plan_db-confirm_yn = zlea_y.
      ls_plan_db-cuser      = sy-uname.
      ls_plan_db-cdate      = sy-datum.
      ls_plan_db-delfg      = space.

      ls_plan_db-erdat = sy-datum.
      ls_plan_db-erzet = sy-uzeit.
      ls_plan_db-ernam = sy-uname.

      APPEND ls_plan_db TO lt_plan_db.

    ENDLOOP.

  ENDIF.

  """ Event
  IF lv_event_exists = abap_true.

    PERFORM zz_get_next_number USING 'ZDP_EVTNO' CHANGING gv_evtno.

    CLEAR: lv_iteno.

    LOOP AT gt_event INTO gs_event.

      IF gs_event-matnr       IS INITIAL AND
         gs_event-event_type  IS INITIAL AND
         gs_event-valid_from  IS INITIAL AND
         gs_event-valid_to    IS INITIAL AND
         gs_event-impact_dir  IS INITIAL AND
         gs_event-impact_rate IS INITIAL AND
         gs_event-event_text  IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR: ls_event_db.

      lv_iteno = lv_iteno + 1.

      ls_event_db-evtno       = gv_evtno.
      ls_event_db-iteno       = lv_iteno.
      ls_event_db-colno       = gv_colno.

      ls_event_db-kunnr       = pa_kunnr.
      ls_event_db-matnr       = gs_event-matnr.
      ls_event_db-event_type  = gs_event-event_type.

      ls_event_db-valid_from = gs_event-valid_from.
      ls_event_db-valid_to   = gs_event-valid_to.

      ls_event_db-event_text = gs_event-event_text.
      ls_event_db-impact_dir = gs_event-impact_dir.
      ls_event_db-impact_rate = gs_event-impact_rate.

      ls_event_db-source       = pa_sourc.
      ls_event_db-collect_date = pa_coldt.

      ls_event_db-confirm_yn = zlea_y.
      ls_event_db-cuser      = sy-uname.
      ls_event_db-cdate      = sy-datum.
      ls_event_db-delfg      = space.

      ls_event_db-erdat = sy-datum.
      ls_event_db-erzet = sy-uzeit.
      ls_event_db-ernam = sy-uname.

      APPEND ls_event_db TO lt_event_db.

    ENDLOOP.

  ENDIF.

  """ DB INSERT
  IF lt_plan_db IS NOT INITIAL.

    INSERT ztcma00170 FROM TABLE lt_plan_db.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE e060. " 데이터를 저장하는 중 오류가 발생했습니다.
      RETURN.
    ENDIF.

  ENDIF.

  IF lt_event_db IS NOT INITIAL.

    INSERT ztcma00180 FROM TABLE lt_event_db.

    IF sy-subrc <> 0.
      ROLLBACK WORK.
      MESSAGE e060. " 데이터를 저장하는 중 오류가 발생했습니다.
      RETURN.
    ENDIF.

  ENDIF.

  COMMIT WORK AND WAIT.

  IF sy-subrc <> 0.
    MESSAGE s067 WITH 'COMMIT' DISPLAY LIKE 'E'. " & 처리 중 오류가 발생했습니다.
    RETURN.
  ENDIF.

  DATA(lv_saved_colno) = gv_colno.

  PERFORM zz_set_clear_0100.

  MESSAGE s312 WITH lv_saved_colno. " 수집번호 &가 저장되었습니다.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_next_number
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      <-- GV_COLNO
*&---------------------------------------------------------------------*
FORM zz_get_next_number USING     pv_object     TYPE inri-object
                        CHANGING  pv_number     TYPE any.

  DATA lv_number TYPE nriv-nrlevel.

  CLEAR: lv_number, pv_number.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = pv_object
    IMPORTING
      number                  = lv_number
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0.
    MESSAGE e311 WITH pv_object. " & Number Range 채번에 실패했습니다.
  ENDIF.

  """ NRLEVEL 20자리 중 뒤 10자리 사용
  pv_number = lv_number+10(10).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_add_row
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_add_row .

  CASE tab_main-activetab.
    WHEN 'PLAN'.
      CLEAR gs_plan.
      APPEND gs_plan TO gt_plan.
    WHEN 'EVEN'.
      CLEAR gs_event.
      APPEND gs_event TO gt_event.
  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_delete_row
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_delete_row .

*** 2안 - 팝업 띄우고 행 삭제 진행
  DATA: lv_count    TYPE i,
        lv_confirm  TYPE abap_bool,
        lv_question TYPE string.

  CLEAR: lv_count, lv_confirm, lv_question.

  " 현재 활성화된 탭의 선택행 개수 확인
  CASE tab_main-activetab.

    WHEN 'PLAN'.
      LOOP AT gt_plan TRANSPORTING NO FIELDS WHERE mark = abap_true.
        lv_count = lv_count + 1.
      ENDLOOP.

    WHEN 'EVEN'.
      LOOP AT gt_event TRANSPORTING NO FIELDS WHERE mark = abap_true.
        lv_count = lv_count + 1.
      ENDLOOP.

    WHEN OTHERS.
      RETURN.

  ENDCASE.

  " 선택한 행이 없으면 삭제 중단
  IF lv_count = 0.
    MESSAGE s325 DISPLAY LIKE 'E'. " 삭제할 행을 선택해 주세요.
    RETURN.
  ENDIF.

  " 삭제 확인 팝업
  lv_question = |선택한 { lv_count }개 행을 삭제하시겠습니까?|.

  PERFORM zz_exe_confirm_action USING '선택행 삭제 확인' lv_question CHANGING lv_confirm.

  " 아니오 또는 취소를 누르면 종료
  IF lv_confirm <> abap_true.
    RETURN.
  ENDIF.

  " 선택한 행 삭제
  CASE tab_main-activetab.

    WHEN 'PLAN'.

      DELETE gt_plan WHERE mark = abap_true.

      " 전체 삭제 시 기본 입력 행 1개 유지
      IF gt_plan IS INITIAL.
        CLEAR gs_plan.
        APPEND gs_plan TO gt_plan.
      ENDIF.

      " 첫 번째 행부터 표시
      tc_plan-top_line = 1.

    WHEN 'EVEN'.

      DELETE gt_event WHERE mark = abap_true.

      " 전체 삭제 시 기본 입력 행 1개 유지
      IF gt_event IS INITIAL.
        CLEAR gs_event.
        APPEND gs_event TO gt_event.
      ENDIF.

      " 첫 번째 행부터 표시
      tc_event-top_line = 1.

  ENDCASE.

  MESSAGE s324 WITH lv_count. " &개 행이 삭제되었습니다.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_initial_rows
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_initial_rows .

  IF gt_plan IS INITIAL.
    CLEAR gs_plan.
    APPEND gs_plan TO gt_plan.
  ENDIF.

  IF gt_event IS INITIAL.
    CLEAR gs_event.
    APPEND gs_event TO gt_event.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_reference_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_reference_data .

  CLEAR: gt_ai_material, gt_ai_code.

  " 1. 자재 마스터
  SELECT matnr, maktx
    FROM ztcma00020
    INTO TABLE @gt_ai_material.

  " 2. 공통 코드
  SELECT cdgrp, cdval, cdnam, cddsc
    FROM ztcma00080
    INTO TABLE @gt_ai_code
   WHERE cdgrp IN ( 'DP_DIR', 'DP_EVT' )
     AND actyn = @zlea_y
     AND ( valfr = '00000000' OR valfr <= @sy-datum )
     AND ( valto = '00000000' OR valto >= @sy-datum ).

  DATA(lv_tmp) = 1.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_validate_result
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_validate_result .

  DATA: lv_matnr TYPE ztcma00020-matnr,
        lv_cdval TYPE ztcma00080-cdval.

  CLEAR gt_validation.

  """ 생산계획 검증
  LOOP AT gt_plan INTO DATA(ls_plan).

    DATA(lv_row) = sy-tabix.

    """ 완전히 빈 기본 행은 제외
    IF ls_plan-matnr       IS INITIAL AND
       ls_plan-perio       IS INITIAL AND
       ls_plan-plan_qty    IS INITIAL AND
       ls_plan-meins       IS INITIAL AND
       ls_plan-change_dir  IS INITIAL AND
       ls_plan-change_rate IS INITIAL.
      CONTINUE.
    ENDIF.

    " 적용월 필수 및 YYYYMM 형식 검사
    IF ls_plan-perio IS INITIAL.

      PERFORM zz_exe_add_validation USING 'PLAN' lv_row 'PERIO'
              '적용월이 입력되지 않았습니다.'.

    ELSEIF ls_plan-perio CO '0123456789'
       AND ls_plan-perio+0(4) <> '0000'
       AND ls_plan-perio+4(2) >= '01'
       AND ls_plan-perio+4(2) <= '12'.

      " 정상적인 YYYYMM

    ELSE.

      PERFORM zz_exe_add_validation USING 'PLAN' lv_row 'PERIO'
              '적용월은 YYYYMM 형식의 유효한 월이어야 합니다.'.

    ENDIF.

    """ 생산계획수량
    IF ls_plan-plan_qty <= 0.

      PERFORM zz_exe_add_validation USING 'PLAN' lv_row 'PLAN_QTY'
              '생산계획수량은 0보다 커야 합니다.'.

    ENDIF.

    """ 기본 단위 (자재 마스터 기본 단위 검증)
    IF ls_plan-matnr IS NOT INITIAL AND ls_plan-meins IS INITIAL.

      PERFORM zz_exe_add_validation USING 'PLAN' lv_row 'MEINS'
              '자재 마스터에 기본 단위가 등록되지 않았습니다.'.

    ENDIF.

    """ 증감방향 필수
    IF ls_plan-change_dir IS INITIAL.

      PERFORM zz_exe_add_validation USING 'PLAN' lv_row 'CHANGE_DIR'
              '증감방향을 입력해 주십시오.'.

    ENDIF.

    """ 증감률
    IF ls_plan-change_rate < 0.

      PERFORM zz_exe_add_validation USING 'PLAN' lv_row 'CHANGE_RATE'
              '증감률은 0 이상으로 입력해 주세요.'.

    ENDIF.

    """ 자재번호 필수 및 존재 여부
    IF ls_plan-matnr IS INITIAL.

      PERFORM zz_exe_add_validation USING 'PLAN' lv_row 'MATNR'
              '자재번호가 입력되지 않았습니다.'.

    ELSE.

      CLEAR lv_matnr.

      SELECT SINGLE matnr
        FROM ztcma00020
        INTO @lv_matnr
       WHERE matnr = @ls_plan-matnr.

      IF sy-subrc <> 0.
        PERFORM zz_exe_add_validation USING 'PLAN' lv_row 'MATNR'
                '자재 마스터에 존재하지 않는 자재번호입니다.'.
      ENDIF.

    ENDIF.

    """ 생산계획 증감방향
    IF ls_plan-change_dir IS NOT INITIAL.

      CLEAR lv_cdval.

      SELECT SINGLE cdval
        FROM ztcma00080
        INTO @lv_cdval
       WHERE cdgrp = 'DP_DIR'
         AND cdval = @ls_plan-change_dir
         AND actyn = 'Y'
         AND ( valfr = '00000000' OR valfr <= @sy-datum )
         AND ( valto = '00000000' OR valto >= @sy-datum ).

      IF sy-subrc <> 0 OR ls_plan-change_dir = '0030'.
        PERFORM zz_exe_add_validation USING 'PLAN' lv_row 'CHANGE_DIR'
                '생산계획 증감방향은 증가 또는 감소만 허용됩니다.'.
      ENDIF.

    ENDIF.

  ENDLOOP.

  """ Event 검증
  LOOP AT gt_event INTO DATA(ls_event).

    lv_row = sy-tabix.

    " 완전히 빈 기본 행은 제외
    IF ls_event-matnr       IS INITIAL AND
       ls_event-event_type  IS INITIAL AND
       ls_event-valid_from  IS INITIAL AND
       ls_event-valid_to    IS INITIAL AND
       ls_event-impact_dir  IS INITIAL AND
       ls_event-impact_rate IS INITIAL AND
       ls_event-event_text  IS INITIAL.
      CONTINUE.
    ENDIF.

    """ Event 유형 필수
    IF ls_event-event_type IS INITIAL.

      PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'EVENT_TYPE'
              'Event 유형을 입력해 주십시오.'.

    ENDIF.

    """ 시작일
    IF ls_event-valid_from IS INITIAL.

      PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'VALID_FROM'
              '시작일을 입력해 주십시오.'.

    ELSE.

      CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
        EXPORTING
          date                      = ls_event-valid_from
        EXCEPTIONS
          plausibility_check_failed = 1
          OTHERS                    = 2.

      IF sy-subrc <> 0.

        PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'VALID_FROM'
                '올바르지 않은 시작일입니다.'.

      ENDIF.

    ENDIF.

    """ 종료일
    IF ls_event-valid_to IS INITIAL.

      PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'VALID_TO'
              '종료일을 입력해 주십시오.'.

    ELSE.

      CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
        EXPORTING
          date                      = ls_event-valid_to
        EXCEPTIONS
          plausibility_check_failed = 1
          OTHERS                    = 2.

      IF sy-subrc <> 0.

        PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'VALID_TO'
                '올바르지 않은 종료일입니다.'.

      ENDIF.

    ENDIF.

    """ 기간 순서
    IF ls_event-valid_from IS NOT INITIAL AND
       ls_event-valid_to   IS NOT INITIAL AND
       ls_event-valid_from > ls_event-valid_to.

      PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'VALID_TO'
              '종료일은 시작일보다 빠를 수 없습니다.'.

    ENDIF.

    """ 영향방향 필수
    IF ls_event-impact_dir IS INITIAL.

      PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'IMPACT_DIR'
              '영향방향을 입력해 주십시오.'.

    ENDIF.

    """ 영향률
    IF ls_event-impact_rate < 0.

      PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'IMPACT_RATE'
              '영향률은 0 이상으로 입력해 주세요.'.

    ENDIF.

    """ 자재번호
    IF ls_event-matnr IS INITIAL.

      PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'MATNR'
              '자재번호가 입력되지 않았습니다.'.

    ELSE.

      CLEAR lv_matnr.

      SELECT SINGLE matnr
        FROM ztcma00020
        INTO @lv_matnr
       WHERE matnr = @ls_event-matnr.

      IF sy-subrc <> 0.
        PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'MATNR'
                '자재 마스터에 존재하지 않는 자재번호입니다.'.
      ENDIF.

    ENDIF.

    """ Event 유형
    IF ls_event-event_type IS NOT INITIAL.

      CLEAR lv_cdval.

      SELECT SINGLE cdval
        FROM ztcma00080
        INTO @lv_cdval
       WHERE cdgrp = 'DP_EVT'
         AND cdval = @ls_event-event_type
         AND actyn = 'Y'
         AND ( valfr = '00000000' OR valfr <= @sy-datum )
         AND ( valto = '00000000' OR valto >= @sy-datum ).

      IF sy-subrc <> 0.

        PERFORM zz_exe_add_validation
          USING 'EVENT' lv_row 'EVENT_TYPE'
                '등록되지 않았거나 비활성화된 Event 유형입니다.'.

      ENDIF.

    ENDIF.

    " Event 영향방향
    IF ls_event-impact_dir IS NOT INITIAL.

      CLEAR lv_cdval.

      SELECT SINGLE cdval
        FROM ztcma00080
        INTO @lv_cdval
       WHERE cdgrp = 'DP_DIR'
         AND cdval = @ls_event-impact_dir
         AND actyn = 'Y'
         AND ( valfr = '00000000' OR valfr <= @sy-datum )
         AND ( valto = '00000000' OR valto >= @sy-datum ).

      IF sy-subrc <> 0.

        PERFORM zz_exe_add_validation USING 'EVENT' lv_row 'IMPACT_DIR'
                '등록되지 않았거나 비활성화된 영향방향입니다.'.

      ENDIF.

    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_add_validation
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> LV_ROW
*&      --> P_
*&      --> P_
*&---------------------------------------------------------------------*
FORM zz_exe_add_validation  USING pv_type    TYPE char10
                                  pv_row     TYPE i
                                  pv_field   TYPE char30
                                  pv_message TYPE string.

  DATA ls_validation TYPE ty_validation.

  CLEAR ls_validation.

  " 오류 아이콘
  ls_validation-status_icon = icon_red_light.

  " Preview 구분
  CASE pv_type.
    WHEN 'PLAN'.
      ls_validation-data_type = '생산계획 Preview'.
    WHEN 'EVENT'.
      ls_validation-data_type = 'Event Preview'.
    WHEN OTHERS.
      ls_validation-data_type = pv_type.
  ENDCASE.

  " 행 번호
  ls_validation-row_no = pv_row.

  " 오류 필드 한글 변환
  CASE pv_field.
    WHEN 'MATNR'.
      ls_validation-fieldname = '자재번호'.

    WHEN 'PERIO'.
      ls_validation-fieldname = '적용월'.

    WHEN 'PLAN_QTY'.
      ls_validation-fieldname = '생산계획수량'.

    WHEN 'MEINS'.
      ls_validation-fieldname = '단위'.

    WHEN 'CHANGE_DIR'.
      ls_validation-fieldname = '증감방향'.

    WHEN 'CHANGE_RATE'.
      ls_validation-fieldname = '증감률'.

    WHEN 'EVENT_TYPE'.
      ls_validation-fieldname = 'Event 유형'.

    WHEN 'VALID_FROM'.
      ls_validation-fieldname = '시작일'.

    WHEN 'VALID_TO'.
      ls_validation-fieldname = '종료일'.

    WHEN 'IMPACT_DIR'.
      ls_validation-fieldname = '영향방향'.

    WHEN 'IMPACT_RATE'.
      ls_validation-fieldname = '영향률'.

    WHEN 'EVENT_TEXT'.
      ls_validation-fieldname = 'Event 내용'.

    WHEN OTHERS.
      ls_validation-fieldname = pv_field.
  ENDCASE.

  " 오류 사유
  ls_validation-message = pv_message.

  APPEND ls_validation TO gt_validation.


ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_validation_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_validation_fcat .

  DATA ls_fcat TYPE lvc_s_fcat.

  CLEAR gt_val_fcat.

  " 오류 아이콘
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'STATUS_ICON'.
  ls_fcat-coltext   = '오류'.
  ls_fcat-icon      = abap_true.
  ls_fcat-outputlen = 10.
  ls_fcat-col_pos   = 1.
  APPEND ls_fcat TO gt_val_fcat.

  " 구분
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'DATA_TYPE'.
  ls_fcat-coltext   = '구분'.
  ls_fcat-outputlen = 22.
  ls_fcat-col_pos   = 2.
  APPEND ls_fcat TO gt_val_fcat.

  " 행 번호
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'ROW_NO'.
  ls_fcat-coltext   = '행'.
  ls_fcat-outputlen = 8.
  ls_fcat-col_pos   = 3.
  APPEND ls_fcat TO gt_val_fcat.

  " 오류 필드
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'FIELDNAME'.
  ls_fcat-coltext   = '오류 필드'.
  ls_fcat-outputlen = 30.
  ls_fcat-col_pos   = 4.
  APPEND ls_fcat TO gt_val_fcat.

  " 오류 사유
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'MESSAGE'.
  ls_fcat-coltext   = '오류 사유'.
  ls_fcat-outputlen = 300.
  ls_fcat-col_pos   = 5.
  APPEND ls_fcat TO gt_val_fcat.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_free_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_free_alv .

  IF go_val_grid IS BOUND.
    go_val_grid->free( ).
    FREE go_val_grid.
  ENDIF.

  IF go_val_cont IS BOUND.
    go_val_cont->free( ).
    FREE go_val_cont.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_material_name
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GS_PLAN_MATNR
*&      <-- GS_PLAN_MAKTX
*&---------------------------------------------------------------------*
FORM zz_get_material_name  USING    pv_matnr TYPE ztcma00020-matnr
                           CHANGING pv_maktx TYPE ztcma00020-maktx
                                    pv_meins TYPE ztcma00170-meins.

  CLEAR: pv_maktx, pv_meins.

  CHECK pv_matnr IS NOT INITIAL.

  SELECT SINGLE maktx, meins
    FROM ztcma00020
    INTO ( @pv_maktx, @pv_meins )
   WHERE matnr = @pv_matnr.


ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_customer_name
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_customer_name.

  CLEAR gv_name2.

  CHECK pa_kunnr IS NOT INITIAL.

  SELECT SINGLE name1
    FROM ztcma00050
    INTO @gv_name2
   WHERE kunnr = @pa_kunnr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_screen_help
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_screen_help.

  CLEAR: gv_htype, gv_hinpu.

  " 자료유형 안내
  CASE abap_true.

    WHEN rb_auto1.
      gv_htype = '자동분류: AI 분석 결과에 따라 생산계획 또는 Event를 표시합니다.'.

    WHEN rb_plan1.
      gv_htype = '생산계획: 고객의 생산계획 정보를 등록합니다.'.

    WHEN rb_event.
      gv_htype = 'Event: 고객의 수요 변동 이벤트를 등록합니다.'.

  ENDCASE.

  " 입력방식 안내
  CASE abap_true.

    WHEN rb_direc.
      gv_hinpu = '직접입력: 실행 후 원문을 입력하고 AI 추출을 수행합니다.'.

    WHEN rb_file1.
      gv_hinpu = '파일업로드: TXT 또는 PDF 파일을 선택하고 실행합니다.'.

  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_customer_f4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_customer_f4 .

  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_dynp   TYPE STANDARD TABLE OF dynpread,
        ls_dynp   TYPE dynpread.

  DATA: lv_kunnr TYPE ztcma00050-kunnr,
        lv_name1 TYPE ztcma00050-name1.

  " 기존 Dictionary F4 도움말 호출
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname    = 'ZTCMA00050'
      fieldname  = 'KUNNR'
      dynpprog   = sy-repid
      dynpnr     = sy-dynnr
    TABLES
      return_tab = lt_return
    EXCEPTIONS
      OTHERS     = 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " 선택한 고객번호 가져오기
  READ TABLE lt_return INTO ls_return INDEX 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  lv_kunnr = ls_return-fieldval.

  " 선택한 고객의 이름 조회
  CLEAR lv_name1.

  SELECT SINGLE name1
    FROM ztcma00050
    INTO @lv_name1
   WHERE kunnr = @lv_kunnr.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " ABAP 변수 갱신
  pa_kunnr = lv_kunnr.
  gv_name2 = lv_name1.

  " 고객번호 화면 필드 갱신
  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'PA_KUNNR'.
  ls_dynp-fieldvalue = lv_kunnr.
  APPEND ls_dynp TO lt_dynp.

  " 고객명 화면 필드 갱신
  CLEAR ls_dynp.
  ls_dynp-fieldname  = 'GV_NAME2'.
  ls_dynp-fieldvalue = lv_name1.
  APPEND ls_dynp TO lt_dynp.

  " Enter 없이 화면 값 즉시 변경
  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp
    EXCEPTIONS
      OTHERS     = 1.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_tc_toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> GO_EVENT_TOOLBAR
*&---------------------------------------------------------------------*
FORM zz_set_tc_toolbar  USING po_toolbar TYPE REF TO cl_gui_toolbar.

  DATA: lt_events TYPE cntl_simple_events,
        ls_event  TYPE cntl_simple_event.

  " 행추가 버튼
  po_toolbar->add_button(
    EXPORTING
      fcode     = 'RADD'
      icon      = icon_insert_row
      butn_type = cntb_btype_button
      text      = '행추가'
      quickinfo = '새로운 행 추가'
  ).

  " 선택행 삭제 버튼
  po_toolbar->add_button(
    EXPORTING
      fcode     = 'RDEL'
      icon      = icon_delete_row
      butn_type = cntb_btype_button
      text      = '행삭제'
      quickinfo = '선택한 행 삭제'
  ).

  " FUNCTION_SELECTED 이벤트 등록
  CLEAR ls_event.
  ls_event-eventid =
    cl_gui_toolbar=>m_id_function_selected.

  ls_event-appl_event = space.

  APPEND ls_event TO lt_events.

  po_toolbar->set_registered_events(
    EXPORTING
      events = lt_events
  ).

  " 이벤트 핸들러 객체 생성
  IF go_tc_toolbar_handler IS NOT BOUND.
    CREATE OBJECT go_tc_toolbar_handler.
  ENDIF.

  " 이벤트 핸들러 연결
  SET HANDLER
    go_tc_toolbar_handler->on_function_selected
    FOR po_toolbar.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_exe_check_preview
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_EXISTS
*&---------------------------------------------------------------------*
FORM zz_exe_check_preview  CHANGING pv_exists TYPE abap_bool.

  CLEAR pv_exists.

  " 생산계획 데이터 확인
  LOOP AT gt_plan INTO DATA(ls_plan).

    IF ls_plan-matnr       IS NOT INITIAL OR
       ls_plan-perio       IS NOT INITIAL OR
       ls_plan-plan_qty    IS NOT INITIAL OR
       ls_plan-meins       IS NOT INITIAL OR
       ls_plan-change_dir  IS NOT INITIAL OR
       ls_plan-change_rate IS NOT INITIAL.

      pv_exists = abap_true.
      RETURN.

    ENDIF.

  ENDLOOP.

  " Event 데이터 확인
  LOOP AT gt_event INTO DATA(ls_event).

    IF ls_event-matnr       IS NOT INITIAL OR
       ls_event-event_type  IS NOT INITIAL OR
       ls_event-valid_from  IS NOT INITIAL OR
       ls_event-valid_to    IS NOT INITIAL OR
       ls_event-impact_dir  IS NOT INITIAL OR
       ls_event-impact_rate IS NOT INITIAL OR
       ls_event-event_text  IS NOT INITIAL.

      pv_exists = abap_true.
      RETURN.

    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_exe_confirm_action
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      <-- LV_CONFIRM
*&---------------------------------------------------------------------*
FORM zz_exe_confirm_action  USING pv_title    TYPE string
                                  pv_question TYPE string
                         CHANGING pv_confirm  TYPE abap_bool.

  DATA lv_answer TYPE c LENGTH 1.

  CLEAR: pv_confirm, lv_answer.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = pv_title
      text_question         = pv_question
      text_button_1         = '예'
      text_button_2         = '아니오'
      default_button        = '2'
      display_cancel_button = abap_true
    IMPORTING
      answer                = lv_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.

  IF sy-subrc = 0 AND lv_answer = '1'.
    pv_confirm = abap_true.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_code_f4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> ABAP_FALSE
*&---------------------------------------------------------------------*
FORM zz_set_code_f4  USING pv_cdgrp TYPE ztcma00080-cdgrp
                           pv_field TYPE dynfnam
                           pv_plan  TYPE abap_bool.

  TYPES: BEGIN OF ty_f4_code,
           cdval TYPE ztcma00080-cdval,
           cdnam TYPE ztcma00080-cdnam,
           cddsc TYPE ztcma00080-cddsc,
         END OF ty_f4_code.

  DATA: lt_values TYPE STANDARD TABLE OF ty_f4_code,
        lt_fcat   TYPE STANDARD TABLE OF dfies,
        ls_fcat   TYPE dfies,
        lv_stepl  TYPE sy-stepl,
        lv_title  TYPE c LENGTH 40.

  " 사용 가능한 공통코드 조회
  SELECT cdval, cdnam, cddsc
    FROM ztcma00080
    INTO TABLE @lt_values
   WHERE cdgrp = @pv_cdgrp
     AND actyn = @zlea_y
     AND ( valfr = '00000000'
        OR valfr <= @sy-datum )
     AND ( valto = '00000000'
        OR valto >= @sy-datum ).

  " 생산계획 증감방향은 증가/감소만 허용
  IF pv_plan = abap_true.
    DELETE lt_values WHERE cdval = '0030'.
  ENDIF.

  IF lt_values IS INITIAL.
    MESSAGE '선택 가능한 코드가 없습니다.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT lt_values BY cdval.

  " F4 컬럼 - 코드
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'CDVAL'.
  ls_fcat-reptext   = '코드'.
  ls_fcat-outputlen = 8.
  APPEND ls_fcat TO lt_fcat.

  " F4 컬럼 - 코드명
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'CDNAM'.
  ls_fcat-reptext   = '코드명'.
  ls_fcat-outputlen = 25.
  APPEND ls_fcat TO lt_fcat.

  " F4 컬럼 - 설명
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'CDDSC'.
  ls_fcat-reptext   = '설명'.
  ls_fcat-outputlen = 40.
  APPEND ls_fcat TO lt_fcat.

  " 팝업 제목
  CASE pv_field.
    WHEN 'GS_PLAN-CHANGE_DIR'.
      lv_title = '생산계획 증감방향 선택'.

    WHEN 'GS_EVENT-IMPACT_DIR'.
      lv_title = 'Event 영향방향 선택'.

    WHEN 'GS_EVENT-EVENT_TYPE'.
      lv_title = 'Event 유형 선택'.
  ENDCASE.

  " Table Control 현재 화면 행
  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl = lv_stepl
    EXCEPTIONS
      OTHERS   = 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " 공통코드 F4
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield     = 'CDVAL'
      dynpprog     = sy-repid
      dynpnr       = sy-dynnr
      dynprofield  = pv_field
      stepl        = lv_stepl
      value_org    = 'S'
      window_title = lv_title
    TABLES
      value_tab    = lt_values
*     field_tab    = lt_fcat
    EXCEPTIONS
      OTHERS       = 1.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_material_f4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&---------------------------------------------------------------------*
FORM zz_set_material_f4  USING pv_field TYPE dynfnam.

  TYPES: BEGIN OF ty_f4_mat,
           matnr TYPE ztcma00020-matnr,
           maktx TYPE ztcma00020-maktx,
         END OF ty_f4_mat.

  DATA: lt_values TYPE STANDARD TABLE OF ty_f4_mat,
        lt_fcat   TYPE STANDARD TABLE OF dfies,
        ls_fcat   TYPE dfies,
        lv_stepl  TYPE sy-stepl.

  " 자재 마스터 조회
  SELECT matnr, maktx
    FROM ztcma00020
    INTO TABLE @lt_values.

  IF lt_values IS INITIAL.
    MESSAGE '조회 가능한 자재가 없습니다.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " F4 컬럼 - 자재번호
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'MATNR'.
  ls_fcat-reptext   = '자재번호'.
  ls_fcat-outputlen = 20.
  APPEND ls_fcat TO lt_fcat.

  " F4 컬럼 - 자재명
  CLEAR ls_fcat.
  ls_fcat-fieldname = 'MAKTX'.
  ls_fcat-reptext   = '자재명'.
  ls_fcat-outputlen = 40.
  APPEND ls_fcat TO lt_fcat.

  " Table Control 현재 화면 행
  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl = lv_stepl
    EXCEPTIONS
      OTHERS   = 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " 자재 F4
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'MATNR'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_field
      stepl           = lv_stepl
      value_org       = 'S'
      window_title    = '자재 선택'
    TABLES
      value_tab       = lt_values
*     field_tab       = lt_fcat
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_code_name
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> GS_PLAN_CHANGE_DIR
*&      <-- GS_PLAN_CHANGE_NAME
*&---------------------------------------------------------------------*
FORM zz_get_code_name  USING    pv_cdgrp TYPE ztcma00080-cdgrp
                                pv_cdval TYPE ztcma00080-cdval
                       CHANGING pv_cdnam TYPE ztcma00080-cdnam.

  CLEAR pv_cdnam.

  CHECK pv_cdval IS NOT INITIAL.

  SELECT SINGLE cdnam
    FROM ztcma00080
    INTO @pv_cdnam
   WHERE cdgrp = @pv_cdgrp
     AND cdval = @pv_cdval
     AND actyn = @zlea_y
     AND ( valfr = '00000000' OR valfr <= @sy-datum )
     AND ( valto = '00000000' OR valto >= @sy-datum ).


ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_date_f4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&---------------------------------------------------------------------*
FORM zz_set_date_f4  USING pv_field TYPE dynfnam.

  DATA: lv_date     TYPE sy-datum,
        lv_external TYPE char10,
        lv_stepl    TYPE sy-stepl,
        lv_index    TYPE i,
        lt_dynp     TYPE STANDARD TABLE OF dynpread,
        ls_dynp     TYPE dynpread.

  " 현재 Table Control 화면 행 확인
  CALL FUNCTION 'DYNP_GET_STEPL'
    IMPORTING
      povstepl = lv_stepl
    EXCEPTIONS
      OTHERS   = 1.

  IF sy-subrc <> 0 OR lv_stepl <= 0.
    RETURN.
  ENDIF.

  " 실제 Internal Table 행 번호
  lv_index = tc_event-top_line + lv_stepl - 1.

  " 기존 날짜가 있으면 해당 날짜를 초기값으로 사용
  READ TABLE gt_event INTO DATA(ls_event)
    INDEX lv_index.

  IF sy-subrc = 0.

    CASE pv_field.
      WHEN 'GS_EVENT-VALID_FROM'.
        lv_date = ls_event-valid_from.

      WHEN 'GS_EVENT-VALID_TO'.
        lv_date = ls_event-valid_to.
    ENDCASE.

  ENDIF.

  IF lv_date IS INITIAL.
    lv_date = sy-datum.
  ENDIF.

  " SAP 표준 달력 F4
  CALL FUNCTION 'F4_DATE'
    EXPORTING
      date_for_first_month = lv_date
    IMPORTING
      select_date          = lv_date
    EXCEPTIONS
      OTHERS               = 1.

  IF sy-subrc <> 0 OR lv_date IS INITIAL.
    RETURN.
  ENDIF.

  " 날짜 출력 형식 변환
  CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
    EXPORTING
      date_internal = lv_date
    IMPORTING
      date_external = lv_external
    EXCEPTIONS
      OTHERS        = 1.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " 선택 날짜를 현재 화면 행에 반영
  CLEAR ls_dynp.

  ls_dynp-fieldname  = pv_field.
  ls_dynp-fieldvalue = lv_external.
  ls_dynp-stepl      = lv_stepl.

  APPEND ls_dynp TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynp
    EXCEPTIONS
      OTHERS     = 1.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_confirm_exit
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_EXIT
*&---------------------------------------------------------------------*
FORM zz_exe_confirm_exit  CHANGING pv_exit TYPE abap_bool.

  DATA: lv_exists  TYPE abap_bool,
        lv_confirm TYPE abap_bool.

  " 기본적으로 이탈 허용
  pv_exit = abap_true.

  " Preview 데이터 존재 여부 확인
  PERFORM zz_exe_check_preview
    CHANGING lv_exists.

  " 미저장 데이터가 없으면 바로 이탈
  IF lv_exists <> abap_true.
    RETURN.
  ENDIF.

  " 미저장 데이터가 있으면 이탈 확인
  PERFORM zz_exe_confirm_action USING '미저장 수요정보 확인'
          '저장하지 않은 수요정보가 있습니다. 저장하지 않고 종료하시겠습니까?'
    CHANGING lv_confirm.

  " 아니오 / 취소 선택 시 이탈 차단
  IF lv_confirm <> abap_true.
    pv_exit = abap_false.
    MESSAGE s243. " 작업이 취소되었습니다.
  ENDIF.

ENDFORM.
