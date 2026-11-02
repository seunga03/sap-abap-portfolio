*&---------------------------------------------------------------------*
*& Include          ZRFIA00010_I01
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  gv_okcode = ok_code.
  CLEAR ok_code.

  CASE gv_okcode.
    WHEN 'BACK'.
      PERFORM free_alv_0100.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT' OR 'CANC'.
      PERFORM free_alv_0100.
      LEAVE PROGRAM.
    WHEN 'DETAIL'.
      PERFORM detail_selected.
    WHEN 'PREVIEW'.
      PERFORM print_docs USING abap_true.
    WHEN 'PRINT'.
      PERFORM print_docs USING abap_false.
    WHEN 'HISTORY'.
      PERFORM show_history.
    WHEN 'REFRESH'.
      PERFORM select_data.
    WHEN 'SALL' OR 'DALL'.
      PERFORM select_all USING gv_okcode.
  ENDCASE.
ENDMODULE.

MODULE user_command_0200 INPUT.
  gv_okcode = ok_code.
  CLEAR ok_code.

  CASE gv_okcode.
    WHEN 'PREVIEW'.
      PERFORM print_one USING gs_0200-clrnr abap_true.
    WHEN 'PRINT'.
      PERFORM print_one USING gs_0200-clrnr abap_false.
    WHEN 'CLOSE'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

MODULE user_command_0300 INPUT.
  gv_okcode = ok_code.
  CLEAR ok_code.

  IF gv_okcode = 'CLOSE'.
    IF go_cont_0300 IS BOUND.
      go_cont_0300->free( ).
    ENDIF.
    FREE: go_grid_0300, go_cont_0300.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDMODULE.
