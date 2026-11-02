*&---------------------------------------------------------------------*
*& Include          ZRDPA00013_I01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.
    WHEN 'CREA'.
      SUBMIT zldpa00011 AND RETURN.
      " 신규등록 후 같은 조건으로 재조회
      PERFORM zz_get_plan_data.

*    WHEN 'EDIT'.
*      PERFORM zz_exe_edit_plan.

    WHEN 'BACK'.
      PERFORM zz_free_plan_alv.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE ok_code.
    WHEN 'CREA'.
      SUBMIT zldpa00011 AND RETURN.
      " 신규등록 후 같은 조건으로 재조회
      PERFORM zz_get_event_data.

*    WHEN 'EDIT'.
*      PERFORM zz_exe_edit_event.

    WHEN 'BACK'.
      PERFORM zz_free_event_alv.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

  CASE ok_code.

    WHEN 'EXIT' OR 'CANC'.
      LEAVE PROGRAM.

  ENDCASE.

ENDMODULE.
