*&---------------------------------------------------------------------*
*& Include          ZLFIA00050_K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_data_changed_finished
      FOR EVENT data_changed_finished OF cl_gui_alv_grid
      IMPORTING e_modified.

    CLASS-METHODS on_toolbar
      FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object e_interactive sender.

    CLASS-METHODS on_user_command
      FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm sender.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_data_changed_finished.
    CHECK e_modified = abap_true.
    PERFORM calc_openbal.                        " 수금 후 잔액 다시
    PERFORM refresh_alv2.                        " 소계·합계·제목
  ENDMETHOD.

  METHOD on_toolbar.
    DATA ls_btn TYPE stb_button.

    IF sender = go_alv1.                          " 위: 채권 목록
      CLEAR ls_btn.
      ls_btn-butn_type = 3.                       " 구분선 (표준 버튼 | 내 버튼)
      APPEND ls_btn TO e_object->mt_toolbar.

      CLEAR ls_btn.
      ls_btn-function  = 'ALV_ADD'.
      ls_btn-icon      = icon_insert_row.
      ls_btn-text      = '수금 목록에 추가'.
      ls_btn-quickinfo = '선택한 채권을 아래 수금 목록에 담습니다'.
      APPEND ls_btn TO e_object->mt_toolbar.

    ELSEIF sender = go_alv2.                      " 아래: [목록에서 제외] [고객별 합계] | [수금 등록]
      CLEAR ls_btn.                               " 1. 목록에서 제외
      ls_btn-function  = 'ALV_DEL'.
      ls_btn-icon      = icon_delete_row.
      ls_btn-text      = '목록에서 제외'.
      ls_btn-quickinfo = '선택한 행을 수금 목록에서 뺍니다'.
      APPEND ls_btn TO e_object->mt_toolbar.

      CLEAR ls_btn.                               " 2. 고객별 합계 보기 / 끄기
      ls_btn-function  = 'ALV_SUM'.
      ls_btn-icon      = icon_sum.
      IF gv_sumon = abap_true.
        ls_btn-text      = '고객별 합계 끄기'.
        ls_btn-checked   = 'X'.                   " 눌린 모양
        ls_btn-quickinfo = '고객별 합계와 총합계를 숨깁니다'.
      ELSE.
        ls_btn-text      = '고객별 합계 보기'.
        ls_btn-quickinfo = '수금액 고객별 합계와 총합계를 표시합니다'.
      ENDIF.
      APPEND ls_btn TO e_object->mt_toolbar.

      CLEAR ls_btn.
      ls_btn-butn_type = 3.                       " 구분선 (실행 버튼은 따로 떨어뜨림)
      APPEND ls_btn TO e_object->mt_toolbar.

      CLEAR ls_btn.                               " 3. 수금 등록
      ls_btn-function  = 'ALV_RCP'.
      ls_btn-icon      = icon_execute_object.
      ls_btn-text      = '수금 등록'.
      ls_btn-quickinfo = '수금 목록의 채권을 수금 처리합니다'.
      APPEND ls_btn TO e_object->mt_toolbar.
    ENDIF.
  ENDMETHOD.

  METHOD on_user_command.
    CASE e_ucomm.
      WHEN 'ALV_ADD'.
        PERFORM process_add.
      WHEN 'ALV_DEL'.
        PERFORM process_del.
      WHEN 'ALV_RCP'.
        PERFORM process_rcp.
      WHEN 'ALV_SUM'.
        PERFORM toggle_sum.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
