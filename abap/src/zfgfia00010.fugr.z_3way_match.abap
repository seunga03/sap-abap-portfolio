FUNCTION z_3way_match.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_IVNUM) TYPE  ZTFIA00010-IVNUM
*"     VALUE(IV_SIMULATE) TYPE  CHAR1 DEFAULT SPACE
*"  EXPORTING
*"     VALUE(EV_MSTAT) TYPE  ZTFIA00010-MSTAT
*"  TABLES
*"      ET_ITEM STRUCTURE  ZSFIA00071
*"  EXCEPTIONS
*"      NOT_FOUND
*"      UPDATE_FAILED
*"----------------------------------------------------------------------
* 규칙 (라인 = PO라인 단위, 누계 기준)
*  ① 누적청구량(다른 채무생성 송장 + 이번) > 합격수량누계 → QREJ
*  ② 청구단가 ≠ PO단가                                   → HOLD
*  ③ 그 외                                                → PASS
*  헤더 = QREJ 하나라도 있으면 QREJ > HOLD 있으면 HOLD > PASS
*  COMMIT 하지 않음 (호출한 쪽에서 COMMIT/ROLLBACK)

  DATA: ls_head   TYPE ztfia00010,
        lt_item   TYPE TABLE OF ztfia00020,
        ls_item   TYPE ztfia00020,
        ls_out    TYPE zsfia00071,
        lv_pasqt  TYPE ztmma00130-pasqt,
        lv_billed TYPE ztfia00020-menge,
        lv_ponpr  TYPE ztmma00060-netpr,
        lv_qrej   TYPE c LENGTH 1,
        lv_hold   TYPE c LENGTH 1.

  CLEAR: ev_mstat, et_item[].

  SELECT SINGLE * FROM ztfia00010 INTO ls_head
    WHERE ivnum = iv_ivnum.
  IF sy-subrc <> 0.
    RAISE not_found.
  ENDIF.

  SELECT * FROM ztfia00020 INTO TABLE lt_item
    WHERE ivnum = iv_ivnum.
  IF lt_item IS INITIAL.
    RAISE not_found.
  ENDIF.
  SORT lt_item BY invit.

  LOOP AT lt_item INTO ls_item.
    CLEAR: lv_pasqt, lv_billed, lv_ponpr, ls_out.

    " PO단가
    SELECT SINGLE netpr FROM ztmma00060 INTO lv_ponpr
      WHERE ebeln = ls_head-ebeln
        AND ebelp = ls_item-ebelp.

    " 합격수량누계 (130 → 120 → 090)
    SELECT SUM( c~pasqt )
      FROM ztmma00130 AS c
      INNER JOIN ztmma00120 AS h ON h~inspn = c~inspn
      INNER JOIN ztmma00090 AS g ON g~mblnr = h~mblnr
                                AND g~mjahr = h~mjahr
                                AND g~zeile = c~gritm
      INTO lv_pasqt
      WHERE g~ebeln = ls_head-ebeln
        AND g~ebelp = ls_item-ebelp.

    " 기청구 (자기 자신 제외, 채무 생성된 송장만)
    SELECT SUM( i~menge )
      FROM ztfia00020 AS i
      INNER JOIN ztfia00010 AS h ON h~ivnum = i~ivnum
      INTO lv_billed
      WHERE h~ebeln = ls_head-ebeln
        AND i~ebelp = ls_item-ebelp
        AND h~ivnum <> iv_ivnum
        AND ( h~mstat = 'PASS' OR h~mstat = 'HOLD' ).

    " 라인 판정
    ls_out-cumqt = lv_billed + ls_item-menge.
    IF ls_out-cumqt > lv_pasqt.
      ls_item-mstat = 'QREJ'.
      lv_qrej = 'X'.
    ELSEIF ls_item-netpr <> lv_ponpr.
      ls_item-mstat = 'HOLD'.
      lv_hold = 'X'.
    ELSE.
      ls_item-mstat = 'PASS'.
    ENDIF.

    " 판정 당시 값 (ZTFIA00020 / 결과 라인 공통)
    ls_item-ponpr = lv_ponpr.
    ls_item-pasqt = lv_pasqt.
    ls_item-cumqt = ls_out-cumqt.

    IF iv_simulate IS INITIAL.
      UPDATE ztfia00020
         SET mstat = ls_item-mstat
             ponpr = ls_item-ponpr
             pasqt = ls_item-pasqt
             cumqt = ls_item-cumqt
             aenam = sy-uname
             aedat = sy-datum
             aezet = sy-uzeit
       WHERE ivnum = ls_item-ivnum
         AND invit = ls_item-invit.
      IF sy-subrc <> 0.
        RAISE update_failed.
      ENDIF.
    ENDIF.

    " 결과 라인 (0200 / 재검증 화면용)
    MOVE-CORRESPONDING ls_item TO ls_out.
    ls_out-pasqt = lv_pasqt.
    ls_out-ponpr = lv_ponpr.
    ls_out-waers = ls_head-waers.
    APPEND ls_out TO et_item.
  ENDLOOP.

  " 헤더 판정
  IF lv_qrej = 'X'.
    ev_mstat = 'QREJ'.
  ELSEIF lv_hold = 'X'.
    ev_mstat = 'HOLD'.
  ELSE.
    ev_mstat = 'PASS'.
  ENDIF.

  IF iv_simulate IS INITIAL.
    UPDATE ztfia00010
       SET mstat = ev_mstat
           aenam = sy-uname
           aedat = sy-datum
           aezet = sy-uzeit
     WHERE ivnum = iv_ivnum.
    IF sy-subrc <> 0.
      RAISE update_failed.
    ENDIF.
  ENDIF.

ENDFUNCTION.
