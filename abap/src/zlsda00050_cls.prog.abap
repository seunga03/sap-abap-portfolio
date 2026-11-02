"& Include          ZLSDA00050_CLS
"&---------------------------------------------------------------------*


"---------------------------------------------------------------------*
" CLASS lcl_event_handler DEFINITION
"---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.

  PUBLIC SECTION.

    METHODS:
      handle_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

      handle_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.

ENDCLASS.


"---------------------------------------------------------------------*
" CLASS lcl_event_handler IMPLEMENTATION
"---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

  METHOD handle_toolbar.

    DATA:
      ls_toolbar TYPE stb_button.

    " 구분선
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    " 등록 : 신규 고객
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'NEWC'.
    ls_toolbar-icon      = icon_create.
    ls_toolbar-text      = '등록'.
    ls_toolbar-quickinfo = '신규 고객 등록 (고객번호 자동 채번)'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    " 변경
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'CHNG'.
    ls_toolbar-icon      = icon_change.
    ls_toolbar-text      = '변경'.
    ls_toolbar-quickinfo = '선택한 고객 정보 변경'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    " 구분선
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    " 거래정지
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'BLCK'.
    ls_toolbar-icon      = icon_locked.
    ls_toolbar-text      = '정지'.
    ls_toolbar-quickinfo = '선택한 고객 거래 정지'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    " 거래정지 해제
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'UNBL'.
    ls_toolbar-icon      = icon_unlocked.
    ls_toolbar-text      = '해제'.
    ls_toolbar-quickinfo = '선택한 고객 거래 정지 해제'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    " 구분선
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    " [추가] 삭제 (거래 이력이 없는 고객만)
    CLEAR ls_toolbar.
    ls_toolbar-function  = 'DELE'.
    ls_toolbar-icon      = icon_delete.
    ls_toolbar-text      = '삭제'.
    ls_toolbar-quickinfo = '선택한 고객/배송처 삭제 (거래 이력이 없는 건만)'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.


  METHOD handle_user_command.

    CASE e_ucomm.

      WHEN 'NEWC'.
        PERFORM create_customer.

      WHEN 'CHNG'.
        PERFORM change_customer.

      WHEN 'BLCK'.
        PERFORM set_block USING 'Y'.

      WHEN 'UNBL'.
        PERFORM set_block USING 'N'.

      " [추가] 삭제
      WHEN 'DELE'.
        PERFORM delete_customer.

    ENDCASE.

  ENDMETHOD.

ENDCLASS.


"&---------------------------------------------------------------------*
