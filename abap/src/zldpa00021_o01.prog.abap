*&---------------------------------------------------------------------*
*& Include          ZLDPA00021_O01
*&---------------------------------------------------------------------*

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
*& Module CLEAR_OK_CODE OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE clear_ok_code OUTPUT.

  CLEAR ok_code.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module DISPLAY_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_alv OUTPUT.

  IF go_cont IS INITIAL.

    CREATE OBJECT go_cont
      EXPORTING
        container_name = 'CC_MAIN'.

    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_cont.

    """ Hotspot 이벤트 핸들러 생성 및 등록
    CREATE OBJECT go_event.
    SET HANDLER go_event->handle_hotspot_click FOR go_grid.

    PERFORM zz_set_field_catalog.
    PERFORM zz_set_layout.

    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layo
      CHANGING
        it_outtab       = gt_forecast
        it_fieldcatalog = gt_fcat.

    " ADQTY 직접 수정 가능
    CALL METHOD go_grid->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

  ENDIF.

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
*& Module DISPLAY_REASON OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_reason OUTPUT.

  IF go_reason_cont IS NOT BOUND.

    """ Popup Custom Container
    CREATE OBJECT go_reason_cont
      EXPORTING
        container_name = 'CC_REASON'.

    """ Text Editor
    CREATE OBJECT go_reason_edit
      EXPORTING
        parent = go_reason_cont.

    """ 읽기 전용
    go_reason_edit->set_readonly_mode(
      EXPORTING
        readonly_mode = 1 ).

    """ 툴바 숨김
    go_reason_edit->set_toolbar_mode(
      EXPORTING
        toolbar_mode = 0 ).

    """ 상태 표시줄 숨김
    go_reason_edit->set_statusbar_mode(
      EXPORTING
        statusbar_mode = 0 ).

    """ 선택한 자재의 예측사유 표시
    go_reason_edit->set_textstream(
      EXPORTING
        text = gv_reason ).

    cl_gui_cfw=>flush( ).

  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module DISPLAY_KPI OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_kpi OUTPUT.

  IF go_kpi IS NOT BOUND.

    CREATE OBJECT go_kpi_cont
      EXPORTING
        container_name = 'CC_KPI'.

    CREATE OBJECT go_kpi
      EXPORTING
        io_parent = go_kpi_cont.

  ENDIF.

  PERFORM zz_exe_show_kpi.

ENDMODULE.
