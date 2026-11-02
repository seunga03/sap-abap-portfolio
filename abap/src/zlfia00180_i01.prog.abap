*&---------------------------------------------------------------------*
*& Include          ZLFIA00080_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module USER_COMMAND_0100 INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  gv_ucomm = ok_code.
  CLEAR ok_code.

  CASE gv_ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      PERFORM process_save.
    WHEN OTHERS.                 " REFR 등: 아무것도 안 하고 PBO 재실행
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module USER_COMMAND_0200 INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  gv_ucomm = ok_code.
  CLEAR ok_code.

  CASE gv_ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO SCREEN 0.         " → process_save의 CALL SCREEN 다음 줄로 복귀
  ENDCASE.
ENDMODULE.
