*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA : lt_selected       TYPE lvc_t_row.
  DATA : lv_answer         TYPE abap_bool.
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'POST'.
      IF gt_alv_po IS INITIAL.
        MESSAGE s015 DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = '구매오더 팝업'
          text_question  = TEXT-t01
        IMPORTING
          answer         = lv_answer
        EXCEPTIONS
          text_not_found = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF lv_answer = '1'.
        PERFORM zz_create_po.
      ENDIF.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  CASE ok_code.
    WHEN 'OKAY'.
      REFRESH gt_history.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
