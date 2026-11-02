*&---------------------------------------------------------------------*
*& Include          ZLFIA00050_I01
*&---------------------------------------------------------------------*
MODULE exit_0100 INPUT.                          " BACK / EXIT / CANC (기능 유형 E)
  PERFORM confirm_exit.                       " 종료 확인 → [예]일 때만 LEAVE PROGRAM
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
    WHEN 'RCP'.
      PERFORM process_rcp.
  ENDCASE.
ENDMODULE.
