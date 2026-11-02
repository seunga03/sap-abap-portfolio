*&---------------------------------------------------------------------*
*& Include          ZLDPA00011_I01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  DATA: lv_exists       TYPE abap_bool,
        lv_confirm      TYPE abap_bool,
        lv_save_exists  TYPE abap_bool,
        lv_save_confirm TYPE abap_bool.

  CASE ok_code.
    WHEN 'DISP'.
      PERFORM zz_exe_check_preview CHANGING lv_exists.

      IF lv_exists = abap_true.

        PERFORM zz_exe_confirm_action USING '고객 수요정보 조회'
                '미저장 데이터가 있습니다. 조회 화면으로 이동하시겠습니까?'
          CHANGING lv_confirm.

        IF lv_confirm <> abap_true.
          MESSAGE s243. "	작업이 취소되었습니다.
          RETURN.
        ENDIF.

      ENDIF.

      CALL TRANSACTION 'ZDP13'.

    WHEN 'RADD'.
      PERFORM zz_exe_add_row.

    WHEN 'RDEL'.
      PERFORM zz_exe_delete_row.

    WHEN 'PLAN'.
      tab_main-activetab = 'PLAN'.
      gv_dynnr           = '0110'.

    WHEN 'EVEN'.
      tab_main-activetab = 'EVEN'.
      gv_dynnr           = '0120'.

    WHEN 'EXTR'.
      " 기존 Preview 데이터 존재 여부 확인
      PERFORM zz_exe_check_preview CHANGING lv_exists.

      " 기존 데이터가 있으면 재추출 확인
      IF lv_exists = abap_true.

        PERFORM zz_exe_confirm_action
          USING 'AI 재추출 확인' '기존 분석 결과와 수정 내용이 교체됩니다. 계속하시겠습니까?'
            CHANGING lv_confirm.

        IF lv_confirm <> abap_true.
          RETURN.
        ENDIF.

      ENDIF.

      " PDF는 바이너리를 사용하므로 Editor를 읽지 않음
      IF rb_file1 = abap_true AND gv_ftype = 'PDF'.
        CLEAR gv_raw_text.
      ELSE.
        " 직접입력과 TXT는 Editor의 텍스트를 사용
        PERFORM zz_get_editor_text.
      ENDIF.
      PERFORM zz_exe_ai_analytics.

    WHEN 'INIT'.
      PERFORM zz_set_clear_0100.

    WHEN 'SAVE'.
      PERFORM zz_exe_validate_result.

      IF gt_validation IS NOT INITIAL.
        CALL SCREEN 0200 STARTING AT 10 5 ENDING AT 120 23.
        RETURN.
      ENDIF.

      PERFORM zz_exe_check_preview CHANGING lv_save_exists.

      IF lv_save_exists <> abap_true.
        MESSAGE e306. " 저장할 데이터가 없습니다.
      ENDIF.

      " 저장 확인 팝업
      PERFORM zz_exe_confirm_action
        USING '수요정보 저장 확인' '입력한 수요정보를 저장하시겠습니까?'
        CHANGING lv_save_confirm.

      IF lv_save_confirm <> abap_true.
        MESSAGE s069. " 작업이 취소되었습니다. 변경사항이 반영되지 않았습니다.
        RETURN.
      ENDIF.

      " 최종 DB 저장
      PERFORM zz_exe_save_data.

    WHEN 'BACK'.
      DATA lv_exit TYPE abap_bool.

      PERFORM zz_exe_confirm_exit CHANGING lv_exit.

      IF lv_exit = abap_true.
        LEAVE TO SCREEN 0.
      ENDIF.

  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.

  DATA lv_exit2 TYPE abap_bool.

  CASE ok_code.

    WHEN 'EXIT' OR 'CANC'.

      PERFORM zz_exe_confirm_exit CHANGING lv_exit2.

      IF lv_exit2 = abap_true.
        LEAVE PROGRAM.
      ELSE.
        CLEAR ok_code.
      ENDIF.

  ENDCASE.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  MODIFY_PLAN_DATA  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE modify_plan_data INPUT.

  " 자재번호 기준 자재명, 기본 단위 자동 조회
  PERFORM zz_get_material_name USING gs_plan-matnr
    CHANGING gs_plan-maktx gs_plan-meins.

  " 증감방향명
  PERFORM zz_get_code_name USING 'DP_DIR' gs_plan-change_dir
    CHANGING gs_plan-change_name.

  MODIFY gt_plan FROM gs_plan INDEX tc_plan-current_line.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  MODIFY_EVENT_DATA  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE modify_event_data INPUT.

  DATA lv_meins TYPE ztcma00170-meins.

  " 자재명
  PERFORM zz_get_material_name USING gs_event-matnr
    CHANGING gs_event-maktx lv_meins.

  " Event 유형명
  PERFORM zz_get_code_name USING 'DP_EVT' gs_event-event_type
    CHANGING gs_event-event_name.

  " 영향방향명
  PERFORM zz_get_code_name USING 'DP_DIR' gs_event-impact_dir
    CHANGING gs_event-impact_name.

  MODIFY gt_event FROM gs_event INDEX tc_event-current_line.

ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.

  CASE ok_code.

    WHEN 'BACK'.

      PERFORM zz_set_free_alv.
      LEAVE TO SCREEN 0.

  ENDCASE.

ENDMODULE.
