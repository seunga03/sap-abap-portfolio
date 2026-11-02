*&---------------------------------------------------------------------*
*& Include          ZLFIA00070_E01
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
  ls_btn-icon_id   = icon_check.           " 체크 아이콘
  ls_btn-icon_text = '구매송장 재검증/취소'.
  ls_btn-quickinfo = '보류/반려 구매송장 관리'.
  sscrfields-functxt_02 = ls_btn.


AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      SUBMIT zlfia00080 VIA SELECTION-SCREEN.
    WHEN 'FC02'.
      SUBMIT zlfia00090 VIA SELECTION-SCREEN.
    WHEN 'PM01'.
      PERFORM set_budat USING 1.                 " 등록일만 채움, 조회는 F8
    WHEN 'PM03'.
      PERFORM set_budat USING 3.
    WHEN 'PM12'.
      PERFORM set_budat USING 12.
    WHEN 'ONLI'.
      IF p_ok IS INITIAL AND p_hold IS INITIAL
         AND p_rej IS INITIAL AND p_canc IS INITIAL.
        MESSAGE e401(zmsga) WITH '대사상태'.
      ENDIF.
      IF s_ivnum[] IS INITIAL AND s_xblnr[] IS INITIAL AND s_lifnr[] IS INITIAL
         AND s_ebeln[] IS INITIAL AND s_bldat[] IS INITIAL AND s_budat[] IS INITIAL.
        MESSAGE e412(zmsga).
      ENDIF.
  ENDCASE.

AT SELECTION-SCREEN OUTPUT.

START-OF-SELECTION.
  PERFORM free_controls.

  PERFORM get_data.

  IF gt_head IS INITIAL.
    MESSAGE s040(zmsga) DISPLAY LIKE 'E'.
  ELSE.
    CALL SCREEN 0100.
  ENDIF.
