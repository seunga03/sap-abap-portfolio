*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_I01
*&---------------------------------------------------------------------*
MODULE exit_0100 INPUT.                   " BACK / EXIT / CANC (기능 유형 E)
  PERFORM confirm_exit.
ENDMODULE.

MODULE user_command_0100 INPUT.
  gv_ucomm = ok_code.
  CLEAR ok_code.

  CASE gv_ucomm.
    WHEN 'SRCH'.
      PERFORM process_search.
    WHEN 'RESET'.
      PERFORM process_reset.
    WHEN 'ADD'.
      PERFORM process_add.
    WHEN 'DEL'.
      PERFORM process_del.
    WHEN 'PAY'.
      PERFORM process_pay.
  ENDCASE.
ENDMODULE.
