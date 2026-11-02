*&---------------------------------------------------------------------*
*& Include          ZLSDA00010_CLS
*&---------------------------------------------------------------------*


*---------------------------------------------------------------------*
* Local Event Handler Class
*---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.

  PUBLIC SECTION.

*---------------------------------------------------------------------*
* 주문 검증 ALV Toolbar
*---------------------------------------------------------------------*
    METHODS:
      handle_valid_toolbar
        FOR EVENT toolbar
        OF cl_gui_alv_grid
        IMPORTING
          e_object
          e_interactive.


*---------------------------------------------------------------------*
* 주문 검증 ALV User Command
*---------------------------------------------------------------------*
    METHODS:
      handle_valid_user_command
        FOR EVENT user_command
        OF cl_gui_alv_grid
        IMPORTING
          e_ucomm.


*---------------------------------------------------------------------*
* 판매오더 Header ALV Double Click
*---------------------------------------------------------------------*
    METHODS:
      handle_so_double_click
        FOR EVENT double_click
        OF cl_gui_alv_grid
        IMPORTING
          e_row
          e_column
          es_row_no.

*---------------------------------------------------------------------*
* 판매오더 Header ALV Hotspot Click (판매오더번호 클릭 → 상세 팝업)
*---------------------------------------------------------------------*
    METHODS:
      handle_so_hotspot_click
        FOR EVENT hotspot_click
        OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          e_column_id
          es_row_no.

*---------------------------------------------------------------------*
* 판매오더 ALV Toolbar (Screen 0100 하단에서만 [조회] 버튼 표시)
*---------------------------------------------------------------------*
    METHODS:
      handle_so_toolbar
        FOR EVENT toolbar
        OF cl_gui_alv_grid
        IMPORTING
          e_object
          e_interactive.

    METHODS:
      handle_so_user_command
        FOR EVENT user_command
        OF cl_gui_alv_grid
        IMPORTING
          e_ucomm.

ENDCLASS.



*---------------------------------------------------------------------*
* Local Event Handler Implementation
*---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.


*---------------------------------------------------------------------*
* 주문 검증 ALV Toolbar
*---------------------------------------------------------------------*
  METHOD handle_valid_toolbar.

    DATA:
      ls_toolbar TYPE stb_button.


*---------------------------------------------------------------------*
* 구분선
*---------------------------------------------------------------------*
    CLEAR ls_toolbar.

    ls_toolbar-butn_type = 3.

    APPEND ls_toolbar
      TO e_object->mt_toolbar.


*---------------------------------------------------------------------*
* 생성 가능 선택
*---------------------------------------------------------------------*
    CLEAR ls_toolbar.

    ls_toolbar-function  = 'SELALL'.
    ls_toolbar-icon      = icon_okay.
    ls_toolbar-quickinfo = '판매오더 생성 가능 주문 선택'.
    ls_toolbar-text      = '선택'.
    ls_toolbar-disabled  = space.

    APPEND ls_toolbar
      TO e_object->mt_toolbar.


*---------------------------------------------------------------------*
* 선택 해제
*---------------------------------------------------------------------*
    CLEAR ls_toolbar.

    ls_toolbar-function  = 'DESEL'.
    ls_toolbar-icon      = icon_cancel.
    ls_toolbar-quickinfo = '선택 해제'.
    ls_toolbar-text      = '해제'.
    ls_toolbar-disabled  = space.

    APPEND ls_toolbar
      TO e_object->mt_toolbar.


*---------------------------------------------------------------------*
* 삭제
*---------------------------------------------------------------------*
    CLEAR ls_toolbar.

    ls_toolbar-function  = 'DELE'.
    ls_toolbar-icon      = icon_delete.
    ls_toolbar-quickinfo = '선택한 검증결과 삭제'.
    ls_toolbar-text      = '삭제'.
    ls_toolbar-disabled  = space.


*---------------------------------------------------------------------*
* 검증 데이터가 없으면 삭제버튼 비활성
*---------------------------------------------------------------------*
    IF gt_valid_result IS INITIAL.

      ls_toolbar-disabled = abap_true.

    ENDIF.

    APPEND ls_toolbar
      TO e_object->mt_toolbar.


*---------------------------------------------------------------------*
* 구분선
*---------------------------------------------------------------------*
    CLEAR ls_toolbar.

    ls_toolbar-butn_type = 3.

    APPEND ls_toolbar
      TO e_object->mt_toolbar.


*---------------------------------------------------------------------*
* 판매오더 생성
*---------------------------------------------------------------------*
    CLEAR ls_toolbar.

    ls_toolbar-function  = 'CRSO'.
    ls_toolbar-icon      = icon_create.
    ls_toolbar-quickinfo = '선택 주문 판매오더 생성'.
    ls_toolbar-text      = '생성'.
    ls_toolbar-disabled  = space.


*---------------------------------------------------------------------*
* 검증 데이터가 없으면 생성버튼 비활성
*---------------------------------------------------------------------*
    IF gt_valid_result IS INITIAL.

      ls_toolbar-disabled = abap_true.

    ENDIF.

    APPEND ls_toolbar
      TO e_object->mt_toolbar.

  ENDMETHOD.



*---------------------------------------------------------------------*
* 주문 검증 ALV User Command
*---------------------------------------------------------------------*
  METHOD handle_valid_user_command.

    CASE e_ucomm.


*---------------------------------------------------------------------*
* 생성 가능 주문 전체 선택
*---------------------------------------------------------------------*
      WHEN 'SELALL'.

        PERFORM select_all_valid.


*---------------------------------------------------------------------*
* 선택 해제
*---------------------------------------------------------------------*
      WHEN 'DESEL'.

        PERFORM deselect_all_valid.


*---------------------------------------------------------------------*
* 선택 검증결과 삭제
*---------------------------------------------------------------------*
      WHEN 'DELE'.

        PERFORM delete_valid_rows.


*---------------------------------------------------------------------*
* 판매오더 생성
*---------------------------------------------------------------------*
      WHEN 'CRSO'.

        PERFORM create_sales_order.

    ENDCASE.

  ENDMETHOD.



*---------------------------------------------------------------------*
* 판매오더 Header ALV Double Click
*---------------------------------------------------------------------*
  METHOD handle_so_double_click.

    DATA:
      lv_index TYPE i.


*---------------------------------------------------------------------*
* 실제 Internal Table 행번호 확인
*---------------------------------------------------------------------*
    IF es_row_no-row_id IS INITIAL.

      RETURN.

    ENDIF.


*---------------------------------------------------------------------*
* ALV 실제 데이터 행번호
*---------------------------------------------------------------------*
    lv_index =
      es_row_no-row_id.


*---------------------------------------------------------------------*
* 선택 판매오더 상세조회
*---------------------------------------------------------------------*
    PERFORM get_so_detail
      USING lv_index.

  ENDMETHOD.



*---------------------------------------------------------------------*
* 판매오더 Header ALV Hotspot Click
*---------------------------------------------------------------------*
  METHOD handle_so_hotspot_click.

    DATA:
      ls_so    TYPE ty_so_list,
      lv_index TYPE sy-tabix.

*---------------------------------------------------------------------*
* 판매오더번호에서만 동작
*---------------------------------------------------------------------*
    IF e_column_id-fieldname <> 'VBELN'.
      RETURN.
    ENDIF.

*---------------------------------------------------------------------*
* 클릭한 실제 행 번호
*---------------------------------------------------------------------*
    lv_index = es_row_no-row_id.

    IF lv_index IS INITIAL.
      lv_index = e_row_id-index.
    ENDIF.

    READ TABLE gt_so_list INTO ls_so INDEX lv_index.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

*---------------------------------------------------------------------*
* 이전 팝업 ALV 제거
*---------------------------------------------------------------------*
    IF go_so_pop_grid IS BOUND.
      CALL METHOD go_so_pop_grid->free.
      FREE go_so_pop_grid.
    ENDIF.

    IF go_so_pop_container IS BOUND.
      CALL METHOD go_so_pop_container->free.
      FREE go_so_pop_container.
    ENDIF.

    CLEAR gt_so_pop.

*---------------------------------------------------------------------*
* 200번 화면 : 팝업 대신 하단 상세 ALV에 품목 표시
*---------------------------------------------------------------------*
    IF sy-dynnr = '0200'.

      PERFORM get_so_detail USING lv_index.

      IF go_so_detail_grid IS BOUND.
        CALL METHOD go_so_detail_grid->refresh_table_display.
      ENDIF.

      RETURN.

    ENDIF.

    gv_so_vbeln_pop = ls_so-vbeln.

*---------------------------------------------------------------------*
* 판매오더 상세정보 팝업
*---------------------------------------------------------------------*
    CALL SCREEN 0300
      STARTING AT 20 5
      ENDING AT 115 23.

  ENDMETHOD.

*---------------------------------------------------------------------*
* 판매오더 ALV Toolbar : 100번 하단에서만 [조회] 버튼
*---------------------------------------------------------------------*
  METHOD handle_so_toolbar.

    DATA:
      ls_toolbar TYPE stb_button.

    IF sy-dynnr <> '0100'.
      RETURN.
    ENDIF.

    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR ls_toolbar.
    ls_toolbar-function  = 'GOSO'.
    ls_toolbar-icon      = icon_search.
    ls_toolbar-quickinfo = '판매오더 조회 화면으로 이동 (기간/고객/번호 검색)'.
    ls_toolbar-text      = '조회'.
    ls_toolbar-disabled  = space.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.



*---------------------------------------------------------------------*
* 판매오더 ALV User Command
*---------------------------------------------------------------------*
  METHOD handle_so_user_command.

    CASE e_ucomm.

      WHEN 'GOSO'.

*---------------------------------------------------------------------*
* ALV 이벤트 안에서 화면을 바꾸지 않고 OK 코드로 넘긴다.
* (user_command_0100의 'SD01' 처리: ALV 해제 → 판매오더 조회 화면 200)
*---------------------------------------------------------------------*
        cl_gui_cfw=>set_new_ok_code( new_code = 'SD01' ).

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
