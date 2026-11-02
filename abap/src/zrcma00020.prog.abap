
*&---------------------------------------------------------------------*
*& Report ZRCMA00020 - CM02 납기 리스크 모니터링
*& 작성자: 이유진
*&---------------------------------------------------------------------*
REPORT zrcma00020 MESSAGE-ID zmsga.

INCLUDE zrcma00020_top.
INCLUDE zrcma00020_sel.
INCLUDE zrcma00020_o01.
INCLUDE zrcma00020_i01.
INCLUDE zrcma00020_f01.

INITIALIZATION.
  PERFORM init_selection.

AT SELECTION-SCREEN OUTPUT.
  PERFORM modify_selection.

AT SELECTION-SCREEN.
  PERFORM check_selection.

START-OF-SELECTION.
  PERFORM select_data.
  IF gt_list IS INITIAL.
    MESSAGE s041 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  CALL SCREEN 0100.
