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
    WHEN 'POST'.
      IF gt_po IS INITIAL.
        MESSAGE s015 DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = TEXT-t02
          text_question  = TEXT-t01
          display_cancel_button = space
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
  DATA : lv_exit TYPE abap_bool.
  CLEAR lv_exit.
  CASE ok_code.
    WHEN 'BACK'.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = TEXT-t03
          text_question  = TEXT-t04
          display_cancel_button = space
        IMPORTING
          answer         = lv_exit
        EXCEPTIONS
          text_not_found = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF lv_exit = '1'.
        LEAVE TO SCREEN 0.
      ENDIF.
    WHEN 'EXIT'.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = TEXT-t05
          text_question  = TEXT-t06
          display_cancel_button = space
        IMPORTING
          answer         = lv_exit
        EXCEPTIONS
          text_not_found = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF lv_exit = '1'.
        LEAVE PROGRAM.
      ENDIF.
    WHEN 'CANC'.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = TEXT-t08
          text_question  = TEXT-t09
          display_cancel_button = space
        IMPORTING
          answer         = lv_exit
        EXCEPTIONS
          text_not_found = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        RETURN.
      ENDIF.
      IF lv_exit = '1'.
        MESSAGE s141.
        ROLLBACK WORK.
      ENDIF.
  ENDCASE.
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
