FUNCTION ZCM_EXC_REQ_CREATE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_EXNUM) TYPE  ZDE_EXNUM
*"     VALUE(IV_ACTTP) TYPE  ZTEXA00060-ACTTP
*"     VALUE(IV_RQTXT) TYPE  ZTEXA00060-RQTXT OPTIONAL
*"  EXPORTING
*"     VALUE(EV_RQNUM) TYPE  ZTEXA00060-RQNUM
*"     VALUE(EV_DUP) TYPE  ABAP_BOOL
*"     VALUE(EV_NOTGT) TYPE  ABAP_BOOL
*"     VALUE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------
*----------------------------------------------------------------------
* Exception 후속 요청서 생성 (ZTEXA00060) - COMMIT 하지 않음(호출자 책임)
*----------------------------------------------------------------------
  CONSTANTS:
    lc_wait TYPE ztexa00060-rqsta VALUE 'WAIT',   " TODO(A1) RQSTA 코드값 확정 시 점검
    lc_grp  TYPE ztcma00080-cdgrp VALUE 'ACTTG'.

  DATA: lv_nr    TYPE n LENGTH 8,
        ls_req   TYPE ztexa00060,
        lv_dup   TYPE ztexa00060-rqnum,
        lv_cdnam TYPE ztcma00080-cdnam.

  CLEAR: ev_rqnum, ev_dup, ev_notgt, et_return.

* 1. 필수값
  IF iv_exnum IS INITIAL OR iv_acttp IS INITIAL.
    et_return = VALUE #( ( type = 'E' message = 'EXNUM과 ACTTP는 필수입니다.' ) ).
    RETURN.
  ENDIF.

* 2. Exception 존재 확인 + 출처 정보
  SELECT SINGLE srtyp, srnum, sritm
    FROM ztexa00010
    WHERE exnum = @iv_exnum
    INTO @DATA(ls_hdr).
  IF sy-subrc <> 0.
    et_return = VALUE #( ( type = 'E' message = |Exception { iv_exnum }이(가) 존재하지 않습니다.| ) ).
    RETURN.
  ENDIF.

* 3. 조치유형 -> 대상 프로그램 (ACTTG). 없으면 요청 불필요
  SELECT SINGLE cdnam
    FROM ztcma00080
    WHERE cdgrp = @lc_grp
      AND cdval = @iv_acttp
    INTO @lv_cdnam.
  IF sy-subrc <> 0 OR lv_cdnam IS INITIAL.
    ev_notgt = abap_true.
    RETURN.
  ENDIF.
  ls_req-tgpgm = lv_cdnam(4).          " 'MM02-긴급구매전환' -> 'MM02'

* 4. 중복 방지
  SELECT SINGLE rqnum
    FROM ztexa00060
    WHERE exnum = @iv_exnum
      AND acttp = @iv_acttp
      AND rqsta = @lc_wait
    INTO @lv_dup.
  IF sy-subrc = 0.
    ev_rqnum = lv_dup.
    ev_dup   = abap_true.
    et_return = VALUE #( ( type = 'W' message = |이미 대기 중인 요청({ lv_dup })이 있습니다.| ) ).
    RETURN.
  ENDIF.

* 5. 번호 채번 : RQ + 8자리
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZEX_RQNUM'
    IMPORTING
      number      = lv_nr
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc <> 0.
    et_return = VALUE #( ( type = 'E' message = '요청번호 채번에 실패했습니다.' ) ).
    RETURN.
  ENDIF.

* 6. INSERT
  ls_req-rqnum = |RQ{ lv_nr }|.
  ls_req-exnum = iv_exnum.
  ls_req-acttp = iv_acttp.
  ls_req-srtyp = ls_hdr-srtyp.
  ls_req-srnum = ls_hdr-srnum.
  ls_req-sritm = ls_hdr-sritm.
  ls_req-rqsta = lc_wait.
  ls_req-rqtxt = iv_rqtxt.
  ls_req-ernam = sy-uname.
  ls_req-erdat = sy-datum.
  ls_req-erzet = sy-uzeit.

  INSERT ztexa00060 FROM @ls_req.
  IF sy-subrc <> 0.
    et_return = VALUE #( ( type = 'E' message = '요청서 저장에 실패했습니다.' ) ).
    RETURN.
  ENDIF.

  ev_rqnum  = ls_req-rqnum.
  et_return = VALUE #( ( type = 'S' message = |후속 요청 { ls_req-rqnum } 생성 ({ ls_req-tgpgm })| ) ).
ENDFUNCTION.
