*&---------------------------------------------------------------------*
*& Include          ZLFIA00090_O01
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.

MODULE init_control_0100 OUTPUT.
  IF go_cont_reg IS NOT BOUND.
    PERFORM create_object.
    PERFORM set_field_catalog.
    PERFORM display_alv.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*& 0200 재검증 결과
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'S0200'.
  SET TITLEBAR 'T0200'.
ENDMODULE.

MODULE init_control_0200 OUTPUT.
  IF go_cont IS NOT BOUND.
    PERFORM create_object_0200.
    PERFORM set_field_catalog_0200.
    PERFORM display_alv_0200.
  ENDIF.
ENDMODULE.
