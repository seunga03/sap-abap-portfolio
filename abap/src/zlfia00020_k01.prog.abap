*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_K01
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

    CLASS-METHODS on_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id sender.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_data_changed_finished.
    CHECK e_modified = abap_true.
    PERFORM calc_openbal.                        " 지급 후 잔액 다시
    PERFORM refresh_alv2.                        " 소계·합계·제목
  ENDMETHOD.

  METHOD on_toolbar.
    DATA ls_btn TYPE stb_button.

    IF sender = go_alv1.                          " 위: 채무 목록
      CLEAR ls_btn.
      ls_btn-butn_type = 3.                       " 구분선 (표준 버튼 | 내 버튼)
      APPEND ls_btn TO e_object->mt_toolbar.

      CLEAR ls_btn.
      ls_btn-function  = 'ALV_ADD'.
      ls_btn-icon      = icon_insert_row.
      ls_btn-text      = '지급 목록에 추가'.
      ls_btn-quickinfo = '선택한 채무를 아래 지급 목록에 담습니다'.
      APPEND ls_btn TO e_object->mt_toolbar.

    ELSEIF sender = go_alv2.                      " 아래: [목록에서 제외] [공급업체별 합계] | [지급 등록]
      CLEAR ls_btn.                               " 1. 목록에서 제외
      ls_btn-function  = 'ALV_DEL'.
      ls_btn-icon      = icon_delete_row.
      ls_btn-text      = '목록에서 제외'.
      ls_btn-quickinfo = '선택한 행을 지급 목록에서 뺍니다'.
      APPEND ls_btn TO e_object->mt_toolbar.

      CLEAR ls_btn.                               " 2. 공급업체별 합계 보기 / 끄기
      ls_btn-function  = 'ALV_SUM'.
      ls_btn-icon      = icon_sum.
      IF gv_sumon = abap_true.
        ls_btn-text      = '공급업체별 합계 끄기'.
        ls_btn-checked   = 'X'.                   " 눌린 모양
        ls_btn-quickinfo = '공급업체별 합계와 총합계를 숨깁니다'.
      ELSE.
        ls_btn-text      = '공급업체별 합계 보기'.
        ls_btn-quickinfo = '지급액 공급업체별 합계와 총합계를 표시합니다'.
      ENDIF.
      APPEND ls_btn TO e_object->mt_toolbar.

      CLEAR ls_btn.
      ls_btn-butn_type = 3.                       " 구분선 (실행 버튼은 따로 떨어뜨림)
      APPEND ls_btn TO e_object->mt_toolbar.

      CLEAR ls_btn.                               " 3. 지급 등록
      ls_btn-function  = 'ALV_PAY'.
      ls_btn-icon      = icon_execute_object.
      ls_btn-text      = '지급 등록'.
      ls_btn-quickinfo = '지급 목록의 채무를 지급 처리합니다'.
      APPEND ls_btn TO e_object->mt_toolbar.
    ENDIF.
  ENDMETHOD.

  METHOD on_user_command.
    CASE e_ucomm.
      WHEN 'ALV_ADD'.
        PERFORM process_add.
      WHEN 'ALV_DEL'.
        PERFORM process_del.
      WHEN 'ALV_PAY'.
        PERFORM process_pay.
      WHEN 'ALV_SUM'.
        PERFORM toggle_sum.
    ENDCASE.
  ENDMETHOD.

  METHOD on_hotspot_click.
    CHECK sender = go_alv1.                       " 위 채무 목록만
    READ TABLE gt_apreg INTO gw_apreg INDEX e_row_id-index.
    CHECK sy-subrc = 0.

    CASE e_column_id-fieldname.
      WHEN 'HDICO'.                               " 자물쇠 → 홀드 사유
        CHECK gw_apreg-hdico IS NOT INITIAL.      " 홀드 아닌 줄의 빈 칸 클릭은 무시
        PERFORM show_hold USING gw_apreg-apnum gw_apreg-ivnum.
      WHEN 'IVNUM'.                               " 송장번호 → 송장 조회
        PERFORM call_invoice USING gw_apreg-ivnum.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
