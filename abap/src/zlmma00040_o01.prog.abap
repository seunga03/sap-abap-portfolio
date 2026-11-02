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

  IF go_con_tree IS NOT BOUND.
    PERFORM create_tree_container.
    PERFORM create_node_event.
    PERFORM build_node_table.
  ELSE.
  ENDIF.
ENDMODULE.
