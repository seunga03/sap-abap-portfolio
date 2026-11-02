*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_O01
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.

MODULE init_control_processing OUTPUT.
  IF go_cont IS NOT BOUND.
    PERFORM create_object.
    PERFORM set_evt_handler.
    PERFORM set_alv_layout.
    PERFORM set_field_catalog.
    PERFORM display_alv.
  ENDIF.
ENDMODULE.
