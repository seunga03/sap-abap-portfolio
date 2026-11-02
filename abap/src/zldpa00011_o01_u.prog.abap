*&---------------------------------------------------------------------*
*& Include          ZLDPA00011_U_O01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module CLEAR_OK_CODE OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE clear_ok_code OUTPUT.

  CLEAR ok_code.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  SET PF-STATUS 'G0100'.
  SET TITLEBAR  'T0100'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module CREATE_TEXT_EDITOR_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE create_text_editor_0100 OUTPUT.

  IF go_text_editor IS BOUND.
    RETURN.
  ENDIF.

  IF go_text_container IS NOT BOUND.

    CREATE OBJECT go_text_container
      EXPORTING
        container_name = 'CC_TEXT'
*       repid          = sy-repid
*       dynnr          = '0140'
      EXCEPTIONS
        OTHERS         = 1.

    IF sy-subrc <> 0.
      MESSAGE 'CC_TEXT 컨테이너 생성 실패'
        TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

  ENDIF.

  CREATE OBJECT go_text_editor
    EXPORTING
      parent = go_text_container
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc <> 0.
    MESSAGE 'Text Editor 객체 생성 실패'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  go_text_editor->set_toolbar_mode(
    EXPORTING toolbar_mode = 1
    EXCEPTIONS OTHERS = 1
  ).

  go_text_editor->set_statusbar_mode(
    EXPORTING statusbar_mode = 0
    EXCEPTIONS OTHERS = 1
  ).

  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      cntl_system_error = 1
      cntl_error        = 2
      OTHERS            = 3.

  IF sy-subrc <> 0.
    MESSAGE 'Text Editor GUI 동기화 실패'
      TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

  "---------------------------------------------------------------*
  " [신규 추가] 편집기가 방금 새로 만들어졌고, 업로드된 내용이
  " 없으면(gt_text 비어 있음) 안내문을 띄운다.
  " F01의 FORM zz_set_editor_hint 참고.
  "---------------------------------------------------------------*
  PERFORM zz_set_editor_hint.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module SET_TEXT_EDITOR_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_text_editor_0100 OUTPUT.

  CHECK go_text_editor IS BOUND.

  " 처음 들어왔을 때만 파일 내용 Setting
  IF gt_text IS NOT INITIAL.

    go_text_editor->set_text_as_r3table(
      EXPORTING
        table           = gt_text          " table with text
      EXCEPTIONS
        error_dp        = 1                " Error while sending R/3 table to TextEdit control!
        error_dp_create = 2                " ERROR_DP_CREATE
        OTHERS          = 3
    ).

    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

    CLEAR gt_text.

  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module SET_EDITOR_READONLY_0100 OUTPUT                 [신규 추가]
*&---------------------------------------------------------------------*
*& 파일업로드(PDF)일 때는 원문이 PDF 뷰어(화면 0130)에 표시되므로
*& 편집기는 읽기 전용으로 막아 "여기도 입력해야 하나?" 하는
*& 혼동을 없앤다.
*& 직접입력이거나 TXT 업로드일 때는 계속 수정 가능하게 둔다.
*& rb_file1 / gv_ftype 은 선택화면(1000) 파라미터·전역변수라서
*& 화면 0100에서도 그대로 값을 읽을 수 있다.
*&---------------------------------------------------------------------*
MODULE set_editor_readonly_0100 OUTPUT.

  CHECK go_text_editor IS BOUND.

  IF rb_file1 = abap_true AND gv_ftype = 'PDF'.

    " PDF 업로드 : 편집기 읽기 전용
    go_text_editor->set_readonly_mode(
      EXPORTING
        readonly_mode = 1
      EXCEPTIONS
        OTHERS        = 1
    ).

  ELSE.

    " 직접입력 / TXT 업로드 : 편집기 수정 가능
    go_text_editor->set_readonly_mode(
      EXPORTING
        readonly_mode = 0
      EXCEPTIONS
        OTHERS        = 1
    ).

  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module SET_TAB_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_tab_0100 OUTPUT.

  IF tab_main-activetab IS INITIAL.
    tab_main-activetab = 'PLAN'.
    gv_dynnr           = '0110'.
  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module SET_TC_PLAN_LINES OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_tc_plan_lines OUTPUT.

  tc_plan-lines = lines( gt_plan ).

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module SET_TC_EVENT_LINES OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_tc_event_lines OUTPUT.

  tc_event-lines = lines( gt_event ).

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'G0200'.
  SET TITLEBAR  'T0200'.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module CREATE_ALV_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE create_alv_0200 OUTPUT.

  IF go_val_cont IS NOT BOUND.

    CREATE OBJECT go_val_cont
      EXPORTING
        container_name = 'CC_VALIDATION'.

    CREATE OBJECT go_val_grid
      EXPORTING
        i_parent = go_val_cont.

    PERFORM zz_set_validation_fcat.

    CLEAR gs_val_layo.
    gs_val_layo-zebra      = abap_true.
    gs_val_layo-cwidth_opt = abap_true.
    gs_val_layo-no_toolbar = abap_true.

    go_val_grid->set_table_for_first_display(
      EXPORTING
        is_layout       = gs_val_layo
      CHANGING
        it_outtab       = gt_validation
        it_fieldcatalog = gt_val_fcat
    ).

  ELSE.

    go_val_grid->refresh_table_display( ).

  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module CREATE_PLAN_TOOLBAR OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE create_plan_toolbar OUTPUT.

  CHECK go_plan_toolbar IS NOT BOUND.

  CREATE OBJECT go_plan_tcont
    EXPORTING
      container_name = 'CC_PLAN_TOOLBAR'.

  CREATE OBJECT go_plan_toolbar
    EXPORTING
      parent = go_plan_tcont.

  PERFORM zz_set_tc_toolbar USING go_plan_toolbar.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module CREATE_EVENT_TOOLBAR OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE create_event_toolbar OUTPUT.

  CHECK go_event_toolbar IS NOT BOUND.

  CREATE OBJECT go_event_tcont
    EXPORTING
      container_name = 'CC_EVENT_TOOLBAR'.

  CREATE OBJECT go_event_toolbar
    EXPORTING
      parent = go_event_tcont.

  PERFORM zz_set_tc_toolbar USING go_event_toolbar.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module CREATE_PDF_VIEWER_0130 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE create_pdf_viewer_0130 OUTPUT.

  " PDF 파일 데이터가 없으면 처리하지 않음
  CHECK gt_binary IS NOT INITIAL.
  CHECK gv_file_length > 0.

  " PDF Viewer 객체 최초 생성
  IF go_pdf_viewer IS NOT BOUND.

    CREATE OBJECT go_pdf_container
      EXPORTING
        container_name = 'CC_PDF'
*       repid          = sy-repid
*       dynnr          = '0130'
      EXCEPTIONS
        OTHERS         = 1.

    IF sy-subrc <> 0.
      MESSAGE 'PDF 컨테이너 생성에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CREATE OBJECT go_pdf_viewer
      EXPORTING
        parent = go_pdf_container
      EXCEPTIONS
        OTHERS = 1.

    IF sy-subrc <> 0.
      MESSAGE 'PDF Viewer 생성에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

  ENDIF.

  " 동일한 PDF의 반복 로드 방지
  IF gv_pdf_loaded = abap_true.
    RETURN.
  ENDIF.

  CLEAR gv_pdf_url.

  " PDF 화면 출력을 위한 로컬 데이터
  DATA: lv_pdf_x TYPE xstring,
        lt_bin   TYPE solix_tab.

  " SOLIX_TAB → XSTRING
  lv_pdf_x = cl_bcs_convert=>solix_to_xstring(
    it_solix = gt_binary
    iv_size  = gv_file_length
  ).

  " XSTRING → SOLIX_TAB
  lt_bin = cl_bcs_convert=>xstring_to_solix(
    iv_xstring = lv_pdf_x
  ).

  CLEAR gv_pdf_url.

  go_pdf_viewer->load_data(
    EXPORTING
      type         = 'application'
      subtype      = 'pdf'
      size         = xstrlen( lv_pdf_x )
    IMPORTING
      assigned_url = gv_pdf_url
    CHANGING
      data_table   = lt_bin
    EXCEPTIONS
      OTHERS       = 1
  ).

  IF sy-subrc <> 0 OR gv_pdf_url IS INITIAL.
    MESSAGE 'PDF 데이터를 불러올 수 없습니다.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  go_pdf_viewer->show_url(
    EXPORTING
      url = gv_pdf_url
    EXCEPTIONS
      OTHERS = 1
  ).

  IF sy-subrc <> 0.
    MESSAGE 'PDF 미리보기를 표시할 수 없습니다.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  gv_pdf_loaded = abap_true.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module SET_SOURCE_SCREEN_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_source_screen_0100 OUTPUT.

  IF rb_file1 = abap_true AND gv_ftype = 'PDF'.
    " PDF 업로드
    gv_source_dynnr = '0130'.

  ELSE.
    " 직접입력 또는 TXT
    gv_source_dynnr = '0140'.

  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_plan_matnr INPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE f4_plan_matnr INPUT.

  PERFORM zz_set_material_f4 USING 'GS_PLAN-MATNR'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_event_matnr INPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE f4_event_matnr INPUT.

  PERFORM zz_set_material_f4 USING 'GS_EVENT-MATNR'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_plan_change_dir INPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE f4_plan_change_dir INPUT.

  PERFORM zz_set_code_f4 USING 'DP_DIR' 'GS_PLAN-CHANGE_DIR' abap_true.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_event_impact_dir INPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE f4_event_impact_dir INPUT.

  PERFORM zz_set_code_f4 USING 'DP_DIR' 'GS_EVENT-IMPACT_DIR' abap_false.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_event_type INPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE f4_event_type INPUT.

  PERFORM zz_set_code_f4 USING 'DP_EVT' 'GS_EVENT-EVENT_TYPE' abap_false.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module F4_EVENT_VALID_FROM INPUT
*&---------------------------------------------------------------------*
MODULE f4_event_valid_from INPUT.

  PERFORM zz_set_date_f4 USING 'GS_EVENT-VALID_FROM'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module F4_EVENT_VALID_TO INPUT
*&---------------------------------------------------------------------*
MODULE f4_event_valid_to INPUT.

  PERFORM zz_set_date_f4 USING 'GS_EVENT-VALID_TO'.

ENDMODULE.
