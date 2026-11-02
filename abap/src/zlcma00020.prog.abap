*&---------------------------------------------------------------------*
*& Report ZLCMA00020
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*& CM04 공급업체 Master 관리 (ZTCMA00010 CRUD)
*& 작성자: 이유진
*&---------------------------------------------------------------------*
REPORT zlcma00020 MESSAGE-ID zmsga..

INCLUDE zlcma00020_top.    " 전역 선언
INCLUDE zlcma00020_sel.    " 선택화면 SCR 1000
INCLUDE zlcma00020_c01.    " ALV 이벤트 클래스
INCLUDE zlcma00020_o01.    " PBO
INCLUDE zlcma00020_i01.    " PAI
INCLUDE zlcma00020_f01.    " FORM

INITIALIZATION.
  PERFORM init_selection.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_lifnr-low.
  PERFORM f4_lifnr USING 'S_LIFNR-LOW'.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_lifnr-high.
  PERFORM f4_lifnr USING 'S_LIFNR-HIGH'.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_land1.
  PERFORM f4_land1_sel CHANGING p_land1.

AT SELECTION-SCREEN.
  PERFORM check_selection.

START-OF-SELECTION.
  PERFORM select_data.
  IF gt_vendor IS INITIAL.
    MESSAGE s041 DISPLAY LIKE 'E'.   " 조회 결과가 없습니다 (ZMSGA 번호 확인)
    RETURN.                          " 선택화면에 머무름
  ENDIF.
  CALL SCREEN 0100.
