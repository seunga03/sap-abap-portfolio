FUNCTION z_fi_create_ap.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_IVNUM) TYPE  ZTFIA00010-IVNUM
*"     VALUE(IV_MSTAT) TYPE  ZTFIA00010-MSTAT
*"  EXPORTING
*"     REFERENCE(EV_APNUM) TYPE  ZTCMA00110-APNUM
*"     REFERENCE(EV_DUEDT) TYPE  ZTCMA00110-DUEDT
*"     REFERENCE(EV_MSG) TYPE  STRING
*"  EXCEPTIONS
*"      NOT_FOUND
*"      INSERT_FAILED
*"      HOLD_FAILED
*"      NO_ZTERM
*"----------------------------------------------------------------------
  DATA: ls_hd    TYPE ztfia00010,
        ls_ap    TYPE ztcma00110,
        lv_max   TYPE ztcma00110-apnum,
        lv_n     TYPE n LENGTH 8,
        lv_zterm TYPE ztcma00010-zterm,
        lv_ztday TYPE ztfia00080-ztday,
        lv_days  TYPE i,
        lv_tdtyp TYPE ztexa00030-tdtyp VALUE 'AP',
        lv_tdnum TYPE ztexa00030-tdnum,
        lv_hdrsn TYPE ztexa00030-hdrsn VALUE '3-Way Match 단가차이',
        lv_sritm TYPE ztexa00010-sritm,       " Exception 대표 라인
        lv_exnum TYPE ztexa00010-exnum,
        lv_dup   TYPE abap_bool,
        lt_ret   TYPE bapiret2_t.

  CLEAR: ev_apnum, ev_duedt, ev_msg.

  SELECT SINGLE * FROM ztfia00010 INTO ls_hd
    WHERE ivnum = iv_ivnum.
  IF sy-subrc <> 0.
    RAISE not_found.
  ENDIF.

  "─ 채무번호 (AP + 8자리, ⚠️ 임시 MAX+1)
  SELECT MAX( apnum ) FROM ztcma00110 INTO lv_max
    WHERE apnum LIKE 'AP%'.
  IF lv_max IS NOT INITIAL.
    lv_n = lv_max+2(8).
  ENDIF.
  lv_n = lv_n + 1.
  CONCATENATE 'AP' lv_n INTO ls_ap-apnum.

  "─ 지급기한 = AP 인식일 + 지급조건 일수 (지급조건 없으면 채무 생성 불가)
  SELECT SINGLE zterm FROM ztcma00010 INTO lv_zterm
    WHERE lifnr = ls_hd-lifnr.
  IF sy-subrc <> 0 OR lv_zterm IS INITIAL.
    ev_msg = '공급업체 지급조건(ZTERM)이 없습니다.'.
    RAISE no_zterm.
  ENDIF.

  SELECT SINGLE ztday FROM ztfia00080 INTO lv_ztday
    WHERE zterm = lv_zterm
      AND actyn = 'Y'.
  IF sy-subrc <> 0.
    ev_msg = |지급조건 { lv_zterm }이(가) 지급조건 마스터에 없거나 미사용입니다.|.
    RAISE no_zterm.
  ENDIF.
  lv_days = lv_ztday.

  ls_ap-ivnum = ls_hd-ivnum.
  ls_ap-lifnr = ls_hd-lifnr.
  ls_ap-dmbtr = ls_hd-wrbtr.
  ls_ap-waers = ls_hd-waers.
  ls_ap-bldat = ls_hd-budat.
  ls_ap-duedt = ls_hd-budat + lv_days.
  ls_ap-clsta = '0010'.                      " 미결
  ls_ap-ernam = sy-uname.
  ls_ap-erdat = sy-datum.
  ls_ap-erzet = sy-uzeit.

  INSERT ztcma00110 FROM ls_ap.
  IF sy-subrc <> 0.
    RAISE insert_failed.
  ENDIF.

  ev_apnum = ls_ap-apnum.
  ev_duedt = ls_ap-duedt.

  "─ HOLD면: ① Exception 먼저 → ② Payment Hold (송장 단위 Exception 1건, Hold 1건)
  CHECK iv_mstat = 'HOLD'.
  lv_tdnum = ls_ap-apnum.

  " Exception 대표 라인 = HOLD 판정 라인 중 첫 번째 (CM03 INVC 섹션이 IVNUM/INVIT으로 조회)
  SELECT MIN( invit ) FROM ztfia00020 INTO lv_sritm
    WHERE ivnum = iv_ivnum
      AND mstat = 'HOLD'.
  IF lv_sritm IS INITIAL.                    " 라인 MSTAT이 아직 안 바뀐 경우 대비
    SELECT MIN( invit ) FROM ztfia00020 INTO lv_sritm
      WHERE ivnum = iv_ivnum.
  ENDIF.

  " ① Exception 생성 (같은 출처·EXTYP 미종결 건이 있으면 기존 번호 반환)
  CALL FUNCTION 'ZCM_EXC_CREATE'
    EXPORTING
      iv_srtyp  = 'INVC'
      iv_srnum  = iv_ivnum
      iv_sritm  = lv_sritm
      iv_owgrp  = 'BOTH'
      iv_extyp  = 'SETL'
    IMPORTING
      ev_exnum  = lv_exnum
      ev_dup    = lv_dup
      et_return = lt_ret.
  IF line_exists( lt_ret[ type = 'E' ] ).
    ev_msg = lt_ret[ type = 'E' ]-message.
    RAISE hold_failed.
  ENDIF.

  " ② Payment Hold 등록 (Exception 번호 필수)
  CLEAR lt_ret.
  CALL FUNCTION 'ZCM_HOLD_SET'
    EXPORTING
      iv_exnum  = lv_exnum
      iv_tdtyp  = lv_tdtyp
      iv_tdnum  = lv_tdnum
      iv_hdrsn  = lv_hdrsn
    IMPORTING
      et_return = lt_ret.
  IF line_exists( lt_ret[ type = 'E' ] ).
    ev_msg = lt_ret[ type = 'E' ]-message.
    RAISE hold_failed.
  ENDIF.

  ev_msg = |Exception { lv_exnum } 생성, Payment Hold 등록 ({ lv_tdnum })|.

ENDFUNCTION.
