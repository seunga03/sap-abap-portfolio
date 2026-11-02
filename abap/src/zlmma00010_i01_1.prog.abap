*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_I01
*&---------------------------------------------------------------------*

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

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.

    WHEN 'FG'.
      tab_main-activetab = 'FG'.
      gv_dynnr = '0110'.

    WHEN 'COMP'.
      tab_main-activetab = 'COMP'.
      gv_dynnr = '0120'.

    WHEN 'PRRS'.
      tab_main-activetab = 'PRRS'.
      gv_dynnr = '0130'.

    WHEN 'CRPR'.
      IF gv_dynnr <> '0130'.
        MESSAGE 'PR 생성 후보 탭에서 실행해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
      ELSE.
        PERFORM zz_confirm_pr_selection.
      ENDIF.

    WHEN 'BACK'.
      LEAVE TO SCREEN 0.

  ENDCASE.

ENDMODULE.
