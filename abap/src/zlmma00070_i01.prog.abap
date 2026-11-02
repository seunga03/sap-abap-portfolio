*&---------------------------------------------------------------------*
*& Include          ZLMMA00070_I01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA : lv_answer TYPE abap_bool.
  DATA : lv_error  TYPE abap_bool.
  CLEAR : lv_answer, gv_error.
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.
      PERFORM zz_get_selected_row CHANGING lv_error.
      IF lv_error IS NOT INITIAL.
        RETURN.
      ENDIF.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar       = TEXT-t02
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
        go_alv->check_changed_data( ).
        PERFORM zz_make_document.
      ENDIF.
      IF gv_error IS INITIAL.
        PERFORM zz_get_data.
        MESSAGE s125.
        go_alv->refresh_table_display( ).
      ENDIF.
  ENDCASE.
ENDMODULE.
