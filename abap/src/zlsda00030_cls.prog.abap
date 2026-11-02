"&---------------------------------------------------------------------*
"& Include          ZLSDA00030_CLS
"&---------------------------------------------------------------------*


CLASS lcl_event_handler DEFINITION.

  PUBLIC SECTION.

    METHODS:
      handle_ship_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING
          e_object
          e_interactive,

      handle_ship_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING
          e_ucomm,

      "---------------------------------------------------------------------*
      " 출고문서번호 Hotspot Click (상단)
      "---------------------------------------------------------------------*
      handle_ship_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          e_column_id
          es_row_no,

      "---------------------------------------------------------------------*
      " 출하 완료 Toolbar (하단)
      " - 청구 버튼 삭제 후 구분선만 남김
      " - 하단 ALV 에는 사용자 버튼이 없으므로 user_command 메서드도 삭제
      "---------------------------------------------------------------------*
      handle_hist_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING
          e_object
          e_interactive,

      "---------------------------------------------------------------------*
      " 출고문서번호 Hotspot Click (하단)
      "---------------------------------------------------------------------*
      handle_hist_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          e_column_id
          es_row_no.

ENDCLASS.


CLASS lcl_event_handler IMPLEMENTATION.


  "---------------------------------------------------------------------*
  " 출하 대상 Toolbar
  "---------------------------------------------------------------------*
  METHOD handle_ship_toolbar.

    DATA:
      ls_toolbar TYPE stb_button.

    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    "---------------------------------------------------------------------*
    " 출하가능 전체 선택
    "---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'SALL'.
    ls_toolbar-icon      = icon_select_all.
    ls_toolbar-text      = ' 가능 선택'.
    ls_toolbar-quickinfo = '출하 가능한 문서만 전체 선택'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    "---------------------------------------------------------------------*
    " 선택 해제
    "---------------------------------------------------------------------*
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
    " 출하 처리 (GI)
    "---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'POST'.
    ls_toolbar-icon      = icon_complete.
    ls_toolbar-text      = ' 출하 처리'.   " 앞 공백 : 아이콘+글자가 잘리지 않게
    ls_toolbar-quickinfo = '선택한 출고문서를 출하 처리 (재고 차감)'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.


  "---------------------------------------------------------------------*
  " 출하 대상 User Command
  "---------------------------------------------------------------------*
  METHOD handle_ship_user_command.

    CASE e_ucomm.

      WHEN 'SALL'.
        PERFORM select_all_ship.

      WHEN 'DSEL'.
        PERFORM deselect_all_ship.

      WHEN 'POST'.
        PERFORM confirm_post_shipment.

    ENDCASE.

  ENDMETHOD.


  "---------------------------------------------------------------------*
  " 출하 완료 Toolbar
  " - 청구(SD04) 이동 버튼 삭제 : 화면 이동은 상단 메뉴 SD04 버튼 사용
  " - 표준 버튼과 구분되도록 구분선만 추가
  "---------------------------------------------------------------------*
  METHOD handle_hist_toolbar.

    DATA:
      ls_toolbar TYPE stb_button.

    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.


  "---------------------------------------------------------------------*
  " 상단 출고문서번호 Hotspot Click
  "---------------------------------------------------------------------*
  METHOD handle_ship_hotspot_click.

    DATA:
      ls_ship  TYPE ty_ship,
      lv_index TYPE sy-tabix.

    IF e_column_id-fieldname <> 'VBELN'.
      RETURN.
    ENDIF.

    lv_index = es_row_no-row_id.

    IF lv_index IS INITIAL.
      lv_index = e_row_id-index.
    ENDIF.

    READ TABLE gt_ship INTO ls_ship INDEX lv_index.

    IF sy-subrc = 0.
      PERFORM show_delivery_detail USING ls_ship-vbeln.
    ENDIF.

  ENDMETHOD.


  "---------------------------------------------------------------------*
  " 하단 출고문서번호 Hotspot Click
  "---------------------------------------------------------------------*
  METHOD handle_hist_hotspot_click.

    DATA:
      ls_hist  TYPE ty_hist,
      lv_index TYPE sy-tabix.

    IF e_column_id-fieldname <> 'VBELN'.
      RETURN.
    ENDIF.

    lv_index = es_row_no-row_id.

    IF lv_index IS INITIAL.
      lv_index = e_row_id-index.
    ENDIF.

    READ TABLE gt_hist INTO ls_hist INDEX lv_index.

    IF sy-subrc = 0.
      PERFORM show_delivery_detail USING ls_hist-vbeln.
    ENDIF.

  ENDMETHOD.


ENDCLASS.



"&---------------------------------------------------------------------*
"& [F01 함께 수정] 하단 ALV SET HANDLER (최종본 989~992줄 근처)
"&  - handle_hist_user_command 줄 삭제 (메서드를 지웠으므로)
"&---------------------------------------------------------------------*
"    SET HANDLER:
"      go_event_handler->handle_hist_toolbar       FOR go_hist_grid,
"      go_event_handler->handle_hist_hotspot_click FOR go_hist_grid.
