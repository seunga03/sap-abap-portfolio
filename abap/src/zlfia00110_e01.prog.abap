*&---------------------------------------------------------------------*
*& Include          ZLFIA00110_E01
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM get_data.

  IF gt_all IS INITIAL.
    MESSAGE s040(zmsga) DISPLAY LIKE 'W'.   " 조회된 데이터가 없습니다
  ELSE.
    MESSAGE s056(zmsga) WITH gv_cnt.        " 전체 n건이 조회되었습니다
  ENDIF.

  CALL SCREEN 0100.
