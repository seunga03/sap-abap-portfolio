*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_I01
*&---------------------------------------------------------------------*
MODULE exit_0100 INPUT.                   " BACK / EXIT / CANC (기능 유형 E)
  PERFORM confirm_exit.                   " 종료 확인 → [예]일 때만 LEAVE PROGRAM
ENDMODULE.

MODULE user_command_0100 INPUT.
  gv_ucomm = ok_code.
  CLEAR ok_code.

  CASE gv_ucomm.
    WHEN 'SRCH'.
      PERFORM process_search.
    WHEN 'RESET'.
      PERFORM process_reset.
  ENDCASE.
ENDMODULE.
