*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_K01
*&---------------------------------------------------------------------*

CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object e_interactive.

    CLASS-METHODS on_toolbar_bot FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object e_interactive.

    CLASS-METHODS on_user_command FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.

    CLASS-METHODS on_data_changed
      FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING er_data_changed e_onf4 e_onf4_before e_onf4_after e_ucomm.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_toolbar_bot.
    DATA ls_button TYPE stb_button.

    CLEAR ls_button.
    ls_button-function  = 'DEGR'.   "Function Code
    ls_button-text      = TEXT-B01."'입고처리 취소'.
    ls_button-icon      = icon_delete_row.
    ls_button-quickinfo = TEXT-B01.
    ls_button-butn_type = 0.             "일반 버튼
    APPEND ls_button TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD on_user_command.
    DATA : lv_error TYPE abap_bool.

    CASE e_ucomm.
      WHEN 'GRSE'.
        PERFORM create_gr.
        go_alv_top->refresh_table_display( ).
        go_alv_bot->refresh_table_display( ).
      WHEN 'DEGR'.
        PERFORM delete_gr.
        go_alv_top->refresh_table_display( ).
        go_alv_bot->refresh_table_display( ).
    ENDCASE.

  ENDMETHOD.

  METHOD on_toolbar.
    DATA ls_button TYPE stb_button.

    CLEAR ls_button.
    ls_button-function  = 'GRSE'.   "Function Code
    ls_button-text      = TEXT-B02.
    ls_button-icon      = icon_insert_row.
    ls_button-quickinfo = TEXT-B02.
    ls_button-butn_type = 0.             "일반 버튼
    APPEND ls_button TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD on_data_changed.
    LOOP AT er_data_changed->mt_mod_cells INTO DATA(ls_mod_cell).
      CASE ls_mod_cell-fieldname.
        WHEN 'MENGE_I'.
          READ TABLE gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_alv>) INDEX ls_mod_cell-row_id.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.

          DATA(lv_menge_i) = CONV zsmma00030-grmen( ls_mod_cell-value ).
          IF lv_menge_i <= 0  OR lv_menge_i > <ls_alv>-grmen.
            er_data_changed->add_protocol_entry(
              EXPORTING
                i_msgid     = '00'
                i_msgno     = '001'
                i_msgty     = 'E'
                i_msgv1     = |수량은 1 이상 { <ls_alv>-menge } 이하로 입력하세요.|
                i_fieldname = ls_mod_cell-fieldname
                i_row_id    = ls_mod_cell-row_id
            ).
            <ls_alv>-menge_i = 0.
            go_alv_bot->refresh_table_display( ).
          ENDIF.

      ENDCASE.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
