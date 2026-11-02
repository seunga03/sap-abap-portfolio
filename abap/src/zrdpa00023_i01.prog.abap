*&---------------------------------------------------------------------*
*& Include          ZRDPA00023_I01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.

    WHEN 'BACK' OR 'CANC'.
      CLEAR ok_code.
      LEAVE TO SCREEN 0.

    WHEN 'EXIT'.
      CLEAR ok_code.
      LEAVE PROGRAM.

  ENDCASE.

  CLEAR ok_code.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE ok_code.

    WHEN 'BACK' OR 'CANC' OR 'EXIT' OR 'OKAY'.
      CLEAR ok_code.
      PERFORM zz_free_reason.
      LEAVE TO SCREEN 0.

  ENDCASE.

  CLEAR ok_code.

ENDMODULE.
