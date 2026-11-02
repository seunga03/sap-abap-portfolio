*&---------------------------------------------------------------------*
*& Report ZRFIA00010 - FI04 반제 데이터 조회 및 SmartForm 출력
*& 작성자: 이유진
*&---------------------------------------------------------------------*
REPORT zrfia00010 MESSAGE-ID zmsga.

INCLUDE zrfia00010_top.
INCLUDE zrfia00010_sel.
INCLUDE zrfia00010_c01.
INCLUDE zrfia00010_o01.
INCLUDE zrfia00010_i01.
INCLUDE zrfia00010_f01.

INITIALIZATION.
  PERFORM init_selection.

AT SELECTION-SCREEN OUTPUT.
  PERFORM modify_selection.          " AP면 고객, AR이면 공급업체 입력불가

AT SELECTION-SCREEN.
  PERFORM check_selection.

*AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vari.
*  PERFORM f4_variant.

*AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_lifnr-low.
*  PERFORM f4_lifnr USING 'S_LIFNR-LOW'.
*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_lifnr-high.
*  PERFORM f4_lifnr USING 'S_LIFNR-HIGH'.

START-OF-SELECTION.
  PERFORM select_data.
  IF gt_list IS INITIAL.
    MESSAGE s041 DISPLAY LIKE 'E'.   " 조건에 해당하는 데이터가 없습니다.
    RETURN.                          " 선택화면에 머무름
  ENDIF.
  CALL SCREEN 0100.
