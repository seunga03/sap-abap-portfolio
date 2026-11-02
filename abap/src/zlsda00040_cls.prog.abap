"&---------------------------------------------------------------------*
"& Include          ZLSDA00040_CLS
"&---------------------------------------------------------------------*


"---------------------------------------------------------------------*
" Event Handler
"---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.

  PUBLIC SECTION.

    METHODS:

      handle_target_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING
          e_object
          e_interactive,

      handle_target_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING
          e_ucomm,

      handle_target_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          e_column_id
          es_row_no,

      handle_bill_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING
          e_object
          e_interactive,

      handle_bill_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING
          e_ucomm,

      handle_bill_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          e_column_id
          es_row_no.

ENDCLASS.


"---------------------------------------------------------------------*
" Event Handler Implementation
"---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.


"---------------------------------------------------------------------*
" 상단 Toolbar
"---------------------------------------------------------------------*
  METHOD handle_target_toolbar.

    DATA:
      ls_toolbar TYPE stb_button.

    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR ls_toolbar.
    ls_toolbar-function  = 'SALL'.
    ls_toolbar-icon      = icon_select_all.
    ls_toolbar-text      = ' 전체'.
    ls_toolbar-quickinfo = '청구 가능한 출고문서 전체 선택'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR ls_toolbar.
    ls_toolbar-function  = 'DSEL'.
    ls_toolbar-icon      = icon_deselect_all.
    ls_toolbar-text      = ' 해제'.
    ls_toolbar-quickinfo = '선택 해제'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" 청구 생성 (AR은 청구 생성 시 자동으로 함께 생성됨)
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'CRBI'.
    ls_toolbar-icon      = icon_create.
    ls_toolbar-text      = ' 청구 생성'.   " 앞 공백 : 아이콘+글자가 잘리지 않게
    ls_toolbar-quickinfo = '선택한 출고문서 청구 생성 (매출채권 AR 자동 생성)'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 상단 User Command
"---------------------------------------------------------------------*
  METHOD handle_target_user_command.

    CASE e_ucomm.

      WHEN 'SALL'.
        PERFORM select_all_target.

      WHEN 'DSEL'.
        PERFORM deselect_all_target.

      WHEN 'CRBI'.
        PERFORM confirm_create_billing.

    ENDCASE.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 하단 Toolbar
"---------------------------------------------------------------------*
  METHOD handle_bill_toolbar.

    DATA:
      ls_toolbar TYPE stb_button.

    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR ls_toolbar.
    ls_toolbar-function  = 'ALLB'.
    ls_toolbar-icon      = icon_display.
    ls_toolbar-text      = ' 전체'.
    ls_toolbar-quickinfo = '전체 청구문서 조회'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" ('미생' 조회 / 'AR' 생성 버튼 삭제)
" AR은 청구 생성 시 자동으로 같이 만들어지므로
" 'AR 미생성' 조회나 'AR 생성' 버튼이 필요 없음
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" 청구 취소 (AR 생성 전만 가능)
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'CNBI'.
    ls_toolbar-icon      = icon_delete.
    ls_toolbar-text      = ' 취소'.
    ls_toolbar-quickinfo = '선택한 청구문서 취소 (AR 생성 전만 가능)'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 하단 User Command
"---------------------------------------------------------------------*
  METHOD handle_bill_user_command.

    CASE e_ucomm.

      WHEN 'ALLB'.
        PERFORM get_all_billing.

      WHEN 'CNBI'.
        PERFORM cancel_billing.

    ENDCASE.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 상단 출고문서번호 Hotspot Click
"---------------------------------------------------------------------*
  METHOD handle_target_hotspot_click.

    DATA:
      ls_row   TYPE ty_target,
      lv_index TYPE sy-tabix.

    IF e_column_id-fieldname <> 'VBELN'.
      RETURN.
    ENDIF.

    lv_index = es_row_no-row_id.

    IF lv_index IS INITIAL.
      lv_index = e_row_id-index.
    ENDIF.

    READ TABLE gt_target INTO ls_row INDEX lv_index.

    IF sy-subrc = 0.
      PERFORM show_delivery_detail USING ls_row-vbeln.
    ENDIF.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 하단 청구문서번호 / 출고문서번호 Hotspot Click
"---------------------------------------------------------------------*
  METHOD handle_bill_hotspot_click.

    DATA:
      ls_row   TYPE ty_bill,
      lv_index TYPE sy-tabix.

    lv_index = es_row_no-row_id.

    IF lv_index IS INITIAL.
      lv_index = e_row_id-index.
    ENDIF.

    READ TABLE gt_bill INTO ls_row INDEX lv_index.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CASE e_column_id-fieldname.

      WHEN 'BILNO'.
        PERFORM show_billing_detail USING ls_row-bilno.

      WHEN 'VLELN'.
        PERFORM show_delivery_detail USING ls_row-vleln.

    ENDCASE.

  ENDMETHOD.


ENDCLASS.

"&---------------------------------------------------------------------*
