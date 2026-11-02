"&---------------------------------------------------------------------*
"& Include          ZLSDA00020_CLS
"&---------------------------------------------------------------------*


"---------------------------------------------------------------------*
" Event Handler
"---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.

  PUBLIC SECTION.

    METHODS:
      handle_so_toolbar
        FOR EVENT toolbar
        OF cl_gui_alv_grid
        IMPORTING
          e_object
          e_interactive,

      handle_so_user_command
        FOR EVENT user_command
        OF cl_gui_alv_grid
        IMPORTING
          e_ucomm,

"---------------------------------------------------------------------*
" 판매오더번호 Hotspot Click
"---------------------------------------------------------------------*
      handle_so_hotspot_click
        FOR EVENT hotspot_click
        OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          e_column_id
          es_row_no,

      handle_de_toolbar
        FOR EVENT toolbar
        OF cl_gui_alv_grid
        IMPORTING
          e_object
          e_interactive,

"---------------------------------------------------------------------*
" 출고문서번호 Hotspot Click
"---------------------------------------------------------------------*
      handle_de_hotspot_click
        FOR EVENT hotspot_click
        OF cl_gui_alv_grid
        IMPORTING
          e_row_id
          e_column_id
          es_row_no,

      handle_de_user_command
        FOR EVENT user_command
        OF cl_gui_alv_grid
        IMPORTING
          e_ucomm.

ENDCLASS.



"---------------------------------------------------------------------*
" Implementation
"---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.


"---------------------------------------------------------------------*
" 상단 SO Toolbar
"---------------------------------------------------------------------*
  METHOD handle_so_toolbar.

    DATA:
      ls_toolbar TYPE stb_button.

"---------------------------------------------------------------------*
" 구분선
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" 출고가능 전체선택
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'SALL'.
    ls_toolbar-icon      = icon_select_all.
    ls_toolbar-text      = '전체'.
    ls_toolbar-quickinfo = '출고 가능한 판매오더만 전체 선택'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" 선택 해제
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'DSEL'.
    ls_toolbar-icon      = icon_deselect_all.
    ls_toolbar-text      = '해제'.
    ls_toolbar-quickinfo = '선택 해제'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" 출고문서 생성 (C)
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'CRDL'.
    ls_toolbar-icon      = icon_create.
    ls_toolbar-text      = ' 출고문서 생성'.
    ls_toolbar-quickinfo = '선택한 판매오더 출고문서 생성'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 상단 SO User Command
"---------------------------------------------------------------------*
  METHOD handle_so_user_command.

    CASE e_ucomm.

      WHEN 'SALL'.
        PERFORM select_all_so.

      WHEN 'DSEL'.
        PERFORM deselect_all_so.

      WHEN 'CRDL'.
        PERFORM confirm_create_delivery.

    ENDCASE.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 상단 SO Hotspot Click
"---------------------------------------------------------------------*
  METHOD handle_so_hotspot_click.

    DATA:
      ls_so    TYPE ty_so,
      lv_index TYPE sy-tabix.

"---------------------------------------------------------------------*
" 판매오더번호에서만 동작
"---------------------------------------------------------------------*
    IF e_column_id-fieldname <> 'VBELN'.
      RETURN.
    ENDIF.

"---------------------------------------------------------------------*
" 클릭한 실제 행 번호
"---------------------------------------------------------------------*
    lv_index = es_row_no-row_id.

    IF lv_index IS INITIAL.
      lv_index = e_row_id-index.
    ENDIF.

"---------------------------------------------------------------------*
" 클릭한 판매오더 조회
"---------------------------------------------------------------------*
    READ TABLE gt_so INTO ls_so INDEX lv_index.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

"---------------------------------------------------------------------*
" 판매오더 상세정보 팝업
" SD03·SD04와 같은 화면(SALV)으로 통일 : 제목·공급가액·세액·최종금액·합계 행
"---------------------------------------------------------------------*
    PERFORM show_so_detail USING ls_so-vbeln.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 하단 Delivery Toolbar
"---------------------------------------------------------------------*
  METHOD handle_de_toolbar.

    DATA:
      ls_toolbar TYPE stb_button.

"---------------------------------------------------------------------*
" 구분선
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" 전체 조회
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'ALLD'.
    ls_toolbar-icon      = icon_display.
    ls_toolbar-text      = '전체'.
    ls_toolbar-quickinfo = '출고문서 전체 조회'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" 미출하 조회
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'PEND'.
    ls_toolbar-icon      = icon_incomplete.
    ls_toolbar-text      = ' 미출하'.
    ls_toolbar-quickinfo = '전체 출고문서 중 미출하 건만 선택'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" 구분선
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" [추가] 출하예정일 변경 (U)
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'CHDL'.
    ls_toolbar-icon      = icon_change.
    ls_toolbar-text      = '변경'.
    ls_toolbar-quickinfo = '선택한 출고문서 출하예정일 변경'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

"---------------------------------------------------------------------*
" [추가] 출고문서 취소 (D)
"---------------------------------------------------------------------*
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'DLDL'.
    ls_toolbar-icon      = icon_delete.
    ls_toolbar-text      = '취소'.
    ls_toolbar-quickinfo = '선택한 출고문서 취소 (판매오더는 출고대상으로 복귀)'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 하단 Delivery Hotspot Click
"---------------------------------------------------------------------*
  METHOD handle_de_hotspot_click.

    DATA:
      ls_de    TYPE ty_de,
      lv_index TYPE sy-tabix.

    IF e_column_id-fieldname <> 'VBELN'.
      RETURN.
    ENDIF.

    lv_index = es_row_no-row_id.

    IF lv_index IS INITIAL.
      lv_index = e_row_id-index.
    ENDIF.

    READ TABLE gt_de INTO ls_de INDEX lv_index.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

"---------------------------------------------------------------------*
" 출고문서 상세정보 팝업
" SD03·SD04와 같은 화면(SALV)으로 통일 : 원본 판매오더가 맨 왼쪽,
" 공급가액·세액·최종금액과 합계 행 표시
"---------------------------------------------------------------------*
    PERFORM show_delivery_detail USING ls_de-vbeln.

  ENDMETHOD.


"---------------------------------------------------------------------*
" 하단 Delivery User Command
"---------------------------------------------------------------------*
  METHOD handle_de_user_command.

    CASE e_ucomm.

      WHEN 'ALLD'.
        PERFORM get_all_delivery.

      WHEN 'PEND'.
        PERFORM get_all_delivery.
        PERFORM select_all_delivery.

      WHEN 'CHDL'.
        PERFORM change_delivery_date.

      WHEN 'DLDL'.
        PERFORM cancel_delivery.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
