"& Include          ZLSDA00050_SCR
"&---------------------------------------------------------------------*

" 선택화면 없음 : 조회 조건은 화면 0100 상단에 직접 배치 (SD02 와 동일)

START-OF-SELECTION.

  " 처음 들어오면 기본 조건(전체)으로 바로 조회
  PERFORM get_data.

  IF gt_cust IS INITIAL.
    MESSAGE s230(zmsga) DISPLAY LIKE 'E'.
  ENDIF.

  CALL SCREEN 0100.
