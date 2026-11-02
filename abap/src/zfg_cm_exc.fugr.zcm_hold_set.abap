FUNCTION ZCM_HOLD_SET.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_EXNUM) TYPE  ZTEXA00030-EXNUM
*"     REFERENCE(IV_TDTYP) TYPE  ZTEXA00030-TDTYP
*"     REFERENCE(IV_TDNUM) TYPE  ZTEXA00030-TDNUM
*"     REFERENCE(IV_HDRSN) TYPE  ZTEXA00030-HDRSN OPTIONAL
*"  EXPORTING
*"     REFERENCE(EV_HDNUM) TYPE  ZTEXA00030-HDNUM
*"     REFERENCE(EV_DUP) TYPE  ABAP_BOOL
*"     REFERENCE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------
  CONSTANTS: lc_active TYPE ztexa00030-hdsta VALUE 'ACTV'.

  DATA: ls_hold  TYPE ztexa00030,
        ls_ret   TYPE bapiret2,
        lv_exnum TYPE ztexa00010-exnum,
        lv_hdnum TYPE ztexa00030-hdnum,
        lv_seq   TYPE n LENGTH 8.

  CLEAR: ev_hdnum, ev_dup, et_return.

*--- 1. 필수값 검증
  IF iv_exnum IS INITIAL OR iv_tdtyp IS INITIAL OR iv_tdnum IS INITIAL.
    ls_ret-type    = 'E'.
    ls_ret-message = 'EXNUM, TDTYP, TDNUM은 필수입니다'.
    APPEND ls_ret TO et_return.
    RETURN.
  ENDIF.

*--- 2. TDTYP 검증 (AP/AR)
  IF iv_tdtyp <> 'AP' AND iv_tdtyp <> 'AR'.
    ls_ret-type    = 'E'.
    ls_ret-message = |TDTYP은 AP 또는 AR만 가능합니다 ({ iv_tdtyp })|.
    APPEND ls_ret TO et_return.
    RETURN.
  ENDIF.

*--- 3. Exception 존재 확인 (Exception 먼저, Hold는 나중)
  SELECT SINGLE exnum FROM ztexa00010
    INTO lv_exnum
    WHERE exnum = iv_exnum.
  IF sy-subrc <> 0.
    ls_ret-type    = 'E'.
    ls_ret-message = |Exception { iv_exnum }이(가) 없습니다|.
    APPEND ls_ret TO et_return.
    RETURN.
  ENDIF.

*--- 4. 중복 Hold 확인 (같은 Exception + 대상에 활성 Hold)
  SELECT SINGLE hdnum FROM ztexa00030
    INTO lv_hdnum
    WHERE exnum = iv_exnum
      AND tdtyp = iv_tdtyp
      AND tdnum = iv_tdnum
      AND hdsta = lc_active.
  IF sy-subrc = 0.
    ev_hdnum = lv_hdnum.
    ev_dup   = abap_true.
    ls_ret-type    = 'I'.
    ls_ret-message = |이미 활성 Hold가 있습니다 ({ lv_hdnum })|.
    APPEND ls_ret TO et_return.
    RETURN.
  ENDIF.

*--- 5. 번호 채번
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZEX_HDNUM'
    IMPORTING
      number      = lv_seq
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc <> 0.
    ls_ret-type    = 'E'.
    ls_ret-message = 'Hold 번호 채번에 실패했습니다 (SNRO ZEX_HDNUM 확인)'.
    APPEND ls_ret TO et_return.
    RETURN.
  ENDIF.

*--- 6. Hold 저장
  ls_hold-hdnum = |HD{ lv_seq }|.
  ls_hold-exnum = iv_exnum.
  ls_hold-tdtyp = iv_tdtyp.
  ls_hold-tdnum = iv_tdnum.
  ls_hold-hdsta = lc_active.
  ls_hold-hdrsn = iv_hdrsn.
  ls_hold-erdat = sy-datum.
  ls_hold-erzet = sy-uzeit.
  ls_hold-ernam = sy-uname.

  INSERT ztexa00030 FROM ls_hold.
  IF sy-subrc <> 0.
    ls_ret-type    = 'E'.
    ls_ret-message = 'Hold 저장에 실패했습니다'.
    APPEND ls_ret TO et_return.
    RETURN.
  ENDIF.

  ev_hdnum = ls_hold-hdnum.
  ls_ret-type    = 'S'.
  ls_ret-message = |Payment Hold { ev_hdnum } 생성 완료|.
  APPEND ls_ret TO et_return.
ENDFUNCTION.
