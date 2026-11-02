*&---------------------------------------------------------------------*
*& Include          ZLFIA00110_O01
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.
ENDMODULE.

MODULE init_0100 OUTPUT.
  IF go_con IS INITIAL.
    PERFORM create_controls.
    PERFORM show_kpi.
    PERFORM display_alv1.
    PERFORM display_alv2.
  ENDIF.
ENDMODULE.
