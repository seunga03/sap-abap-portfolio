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
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'POST'.
      IF gv_check IS INITIAL.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar       = '입고처리 팝업'
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
          PERFORM zz_make_docu.
        ENDIF.
      ELSE.
        MESSAGE s044 DISPLAY LIKE 'E'.
      ENDIF.

  ENDCASE.
ENDMODULE.
