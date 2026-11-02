FUNCTION ZCM_EXC_CREATE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_SRTYP) TYPE  ZTEXA00010-SRTYP
*"     REFERENCE(IV_SRNUM) TYPE  ZTEXA00010-SRNUM
*"     REFERENCE(IV_SRITM) TYPE  ZTEXA00010-SRITM OPTIONAL
*"     REFERENCE(IV_OWGRP) TYPE  ZTEXA00010-OWGRP
*"     REFERENCE(IV_EXTYP) TYPE  ZTEXA00010-EXTYP
*"     REFERENCE(IV_NOTIFY) TYPE  ABAP_BOOL DEFAULT ABAP_TRUE
*"  EXPORTING
*"     REFERENCE(EV_EXNUM) TYPE  ZTEXA00010-EXNUM
*"     REFERENCE(EV_DUP) TYPE  ABAP_BOOL
*"     REFERENCE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------

  CONSTANTS lc_open TYPE ztexa00010-prsta VALUE 'OPEN'.

  DATA: ls_hdr  TYPE ztexa00010,
        lv_seq  TYPE n LENGTH 8,
        lv_asg  TYPE syuname,
        lt_aret TYPE bapiret2_t.

  CLEAR: ev_exnum, ev_dup, et_return.

  " 1. 필수값
  IF iv_srtyp IS INITIAL OR iv_srnum IS INITIAL
     OR iv_owgrp IS INITIAL OR iv_extyp IS INITIAL.
    APPEND VALUE #( type = 'E' message = 'SRTYP/SRNUM/OWGRP/EXTYP은 필수입니다' ) TO et_return.
    RETURN.
  ENDIF.

  " 2. 코드값 검증
  IF iv_owgrp <> 'MM' AND iv_owgrp <> 'FI' AND iv_owgrp <> 'BOTH'.
    APPEND VALUE #( type = 'E' message = |OWGRP 값 오류: { iv_owgrp }| ) TO et_return.
    RETURN.
  ENDIF.
  IF iv_extyp <> 'PROC' AND iv_extyp <> 'QUAL' AND iv_extyp <> 'SETL'.
    APPEND VALUE #( type = 'E' message = |EXTYP 값 오류: { iv_extyp }| ) TO et_return.
    RETURN.
  ENDIF.

  " 3. 미종결 중복 → 기존 번호 반환
  SELECT SINGLE exnum FROM ztexa00010
    WHERE srtyp = @iv_srtyp AND srnum = @iv_srnum AND sritm = @iv_sritm
      AND extyp = @iv_extyp
      AND prsta NOT IN ( 'CLSD', 'RJCT' )
    INTO @DATA(lv_exist).
  IF sy-subrc = 0.
    ev_exnum = lv_exist.
    ev_dup   = abap_true.
    APPEND VALUE #( type = 'I' message = |{ lv_exist }: 이미 진행 중인 Exception - 기존 번호 반환| ) TO et_return.
    RETURN.
  ENDIF.

  " 4. 채번
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZEX_EXNUM'
    IMPORTING
      number      = lv_seq
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'E' message = 'Exception 채번 실패' ) TO et_return.
    RETURN.
  ENDIF.

  " 5. 헤더 INSERT
  ls_hdr-exnum = |EX{ lv_seq }|.
  ls_hdr-srtyp = iv_srtyp.
  ls_hdr-srnum = iv_srnum.
  ls_hdr-sritm = iv_sritm.
  ls_hdr-owgrp = iv_owgrp.
  ls_hdr-extyp = iv_extyp.
  ls_hdr-prsta = lc_open.
  ls_hdr-crdat = sy-datum.
  ls_hdr-erdat = sy-datum.
  ls_hdr-erzet = sy-uzeit.
  ls_hdr-ernam = sy-uname.
  GET TIME STAMP FIELD ls_hdr-local_last_changed_at.
  ls_hdr-last_changed_at = ls_hdr-local_last_changed_at.

  INSERT ztexa00010 FROM @ls_hdr.
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'E' message = |{ ls_hdr-exnum }: Exception 저장 실패| ) TO et_return.
    RETURN.
  ENDIF.
  ev_exnum = ls_hdr-exnum.
  APPEND VALUE #( type = 'S' message = |{ ev_exnum }: Exception 생성| ) TO et_return.

  " 6. 담당자 자동 배정 (실패해도 Exception은 유지, W 메시지만 추가)
  CALL FUNCTION 'ZCM_EXC_ASSIGN_AUTO'
    EXPORTING
      iv_exnum  = ev_exnum
      iv_owgrp  = iv_owgrp
      iv_notify = iv_notify
    IMPORTING
      ev_uname  = lv_asg
      et_return = lt_aret
    EXCEPTIONS
      OTHERS    = 1.
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'W' message = |{ ev_exnum }: 담당자 자동 배정 실패| ) TO et_return.
  ELSE.
    APPEND LINES OF lt_aret TO et_return.
  ENDIF.

ENDFUNCTION.
