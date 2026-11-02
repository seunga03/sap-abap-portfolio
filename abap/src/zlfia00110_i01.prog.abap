*&---------------------------------------------------------------------*
*& Include          ZLFIA00110_I01
*&---------------------------------------------------------------------*
MODULE exit_0100 INPUT.
  PERFORM free_controls.
  LEAVE PROGRAM.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'SRCH'.                        " 조회
      PERFORM process_search.
    WHEN 'RESET'.                       " 초기화 (오늘, 전체)
      PERFORM process_reset.
    WHEN 'ALL'.                         " 전체 구간 보기 (더블클릭 거르기 해제)
      CLEAR gv_bucket.
      PERFORM refresh_alv2.
  ENDCASE.
  CLEAR ok_code.
ENDMODULE.
