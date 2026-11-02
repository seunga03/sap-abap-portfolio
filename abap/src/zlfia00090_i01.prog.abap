*&---------------------------------------------------------------------*
*& Include          ZLFIA00090_I01
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  gv_ucomm = ok_code.
  CLEAR ok_code.

  CASE gv_ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'REVAL'.
      PERFORM process_save.
    WHEN 'IVCAN'.                         " 송장 취소 (QREJ → CANC)
      PERFORM process_cancel.
    WHEN 'ADJST'.                         " 단가차이 조정 (HOLD → 조정반제 + PASS)
      PERFORM process_adjust.
  ENDCASE.
ENDMODULE.

MODULE user_command_0200 INPUT.
  gv_ucomm = ok_code.
  CLEAR ok_code.

  CASE gv_ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.          " → process_save의 CALL SCREEN 다음 줄 → 선택화면으로
  ENDCASE.
ENDMODULE.
