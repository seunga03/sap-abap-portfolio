*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '100'.
  SET TITLEBAR '100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module INIT_CONTROL_PROCESSING OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE init_control_processing OUTPUT.
  IF go_con IS NOT BOUND. "IF go_cont IS INITIAL. 같음. NOT BOUND 권장.
    PERFORM create_object. "컨테이너 생성 + ALV 생성
    PERFORM set_event_handler.
    PERFORM set_alv_variant. "ALV에 대한 레이아웃 제어
    PERFORM set_alv_layout. "ALV에 대한 레이아웃 제어2
    PERFORM set_field_catalog. "ALV에 예외 컬럼 정보 구성.
    PERFORM display_alv.   "ALV 출력.
  ELSE.

  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.

  SET PF-STATUS '200'.
  SET TITLEBAR  '200'.

  IF go_note_con IS NOT BOUND.

    CREATE OBJECT go_note_con
      EXPORTING
        container_name = 'CUSTOM_LTEXT'.

    CREATE OBJECT go_textedit
      EXPORTING
        parent            = go_note_con
        max_number_chars  = 255
        wordwrap_mode     = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_position = 72.
  ENDIF.

  go_textedit->set_text_as_stream(
  EXPORTING
    text = gt_note_text ).
ENDMODULE.
