*&---------------------------------------------------------------------*
*& Include          ZLDPA00021_I01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

  DATA lv_exit TYPE abap_bool.

  CASE ok_code.

    WHEN 'EXIT' OR 'CANC'.

      PERFORM zz_exe_confirm_exit CHANGING lv_exit.

      IF lv_exit = abap_true.
        PERFORM zz_exe_free_main.
        LEAVE PROGRAM.
      ELSE.
        CLEAR ok_code.
      ENDIF.

  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.

    WHEN 'AIFC'.
      DATA lv_answer TYPE c.

      PERFORM zz_exe_confirm_ai CHANGING lv_answer.

      IF lv_answer = zlea_1.
        PERFORM zz_exe_ai_forecast.
      ENDIF.

    WHEN 'SAVE'.
      PERFORM zz_exe_save_forecast.

    WHEN 'BACK'.
      DATA lv_exit2 TYPE abap_bool.

      PERFORM zz_exe_confirm_exit CHANGING lv_exit2.

      IF lv_exit2 = abap_true.
        PERFORM zz_exe_free_main.
        LEAVE TO SCREEN 0.
      ENDIF.

  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  EXIT_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_0200 INPUT.

  CASE sy-ucomm.

    WHEN 'CANC' OR 'EXIT'.
      PERFORM zz_exe_free_popup.
      LEAVE TO SCREEN 0.

  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE sy-ucomm.

    WHEN 'OKAY' OR 'BACK' OR 'CANC'.
      PERFORM zz_exe_free_popup.
      LEAVE TO SCREEN 0.

  ENDCASE.

ENDMODULE.
