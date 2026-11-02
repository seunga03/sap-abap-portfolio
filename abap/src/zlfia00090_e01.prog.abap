*&---------------------------------------------------------------------*
*& Include          ZLFIA00090_E01
*&---------------------------------------------------------------------*
LOAD-OF-PROGRAM.

INITIALIZATION.
  DATA ls_btn TYPE smp_dyntxt.

  CLEAR ls_btn.
  ls_btn-icon_id   = icon_new_task.
  ls_btn-icon_text = '구매송장 등록'.
  ls_btn-quickinfo = '구매송장 등록 프로그램으로 이동'.   " 마우스 올리면 뜨는 설명
  sscrfields-functxt_01 = ls_btn.

  CLEAR ls_btn.
  ls_btn-icon_id   = icon_display.
  ls_btn-icon_text = '구매송장 조회'.
  ls_btn-quickinfo = '구매송장 조회 프로그램으로 이동'.
  sscrfields-functxt_02 = ls_btn.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      SUBMIT zlfia00080 VIA SELECTION-SCREEN.     " 송장 등록
    WHEN 'FC02'.
      SUBMIT zlfia00070 VIA SELECTION-SCREEN.     " 송장 조회
    WHEN 'ONLI'.
      IF p_hold IS INITIAL AND p_rej IS INITIAL.
        MESSAGE e401(zmsga) WITH '대상(보류/반려)'.     " 대상(보류/반려)을(를) 하나 이상 선택해 주십시오.
      ENDIF.
  ENDCASE.

AT SELECTION-SCREEN OUTPUT.

START-OF-SELECTION.
  PERFORM free_controls.
  PERFORM get_data.                    " 대상 조회 + 송장마다 3WM 미리보기

  IF gt_list IS INITIAL.
    MESSAGE s018(zmsga) DISPLAY LIKE 'E'.        " 처리 가능한 데이터가 없습니다.
    RETURN.
  ENDIF.

  CALL SCREEN 0100.
