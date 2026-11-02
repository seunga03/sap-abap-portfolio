*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA : lv_answer TYPE abap_bool.
  CLEAR lv_answer.
  CASE ok_code.
    WHEN 'POST'.
      IF gt_alv_bot IS NOT INITIAL.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar       = TEXT-t05
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
          PERFORM zz_exe_qm.
        ENDIF.
      ELSE.
        MESSAGE S015 DISPLAY LIKE 'E'.
      ENDIF.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  DATA lv_ltext TYPE string.
  CLEAR : lv_ltext.
  CASE ok_code.
    WHEN 'SAVE'.

      REFRESH gt_note_text.

      go_textedit->get_text_as_stream(
        IMPORTING
          text = gt_note_text ).

      LOOP AT gt_note_text ASSIGNING FIELD-SYMBOL(<ls_text>).

        IF sy-tabix = 1.
          lv_ltext = <ls_text>.
        ELSE.
          CONCATENATE lv_ltext <ls_text>
            INTO lv_ltext
            SEPARATED BY cl_abap_char_utilities=>newline.
        ENDIF.

      ENDLOOP.

      READ TABLE gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_bot>) INDEX gv_note_row.
      IF sy-subrc = 0.
        <ls_bot>-deftx = lv_ltext.
      ENDIF.

      go_alv_bot->refresh_table_display( ).

      PERFORM zz_free_ltext_control.
      CLEAR gv_note_row.

      LEAVE TO SCREEN 0.

    WHEN 'BACK' OR 'CANC'.

      FREE: go_textedit, go_note_con.
      CLEAR gv_note_row.
      PERFORM zz_free_ltext_control.
      LEAVE TO SCREEN 0.

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
          titlebar       = TEXT-t07
          text_question  = TEXT-t07
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
          titlebar       = TEXT-t08
          text_question  = TEXT-t08
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
          titlebar       = TEXT-t09
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
