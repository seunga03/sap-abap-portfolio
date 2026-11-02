*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
 SET PF-STATUS 'S0100'.
* SET TITLEBAR 'xxx'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module ININT_CONTROL_PROCESSING OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE inint_control_processing OUTPUT.

IF go_cont IS NOT BOUND.

  PERFORM create_object.
  PERFORM set_evt_handler.

  PERFORM set_alv_layout.
  PERFORM set_field_catalog.

  PERFORM display_alv.

ENDIF.

ENDMODULE.
