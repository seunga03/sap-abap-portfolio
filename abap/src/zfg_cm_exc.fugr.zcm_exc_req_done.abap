FUNCTION ZCM_EXC_REQ_DONE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_RQNUM) TYPE  ZTEXA00060-RQNUM
*"     VALUE(IV_RSTXT) TYPE  ZTEXA00060-RSTXT OPTIONAL
*"  EXPORTING
*"     VALUE(EV_EXNUM) TYPE  ZTEXA00060-EXNUM
*"     VALUE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------
*----------------------------------------------------------------------
* Exception 후속 요청 완료 처리 (ZTEXA00060: WAIT -> DONE)
* - 처리이력(ZTEXA00020)에 "후속 요청 완료" 기록
* - COMMIT 하지 않음(호출자 책임). 담당자 알림은 별도 단계에서 추가 예정
*----------------------------------------------------------------------
  CONSTANTS:
    lc_wait TYPE ztexa00060-rqsta VALUE 'WAIT',
    lc_done TYPE ztexa00060-rqsta VALUE 'DONE',
    lc_cncl TYPE ztexa00060-rqsta VALUE 'CNCL'.

  DATA: ls_hist TYPE ztexa00020,
        lv_txt  TYPE string,
        lt_nret TYPE bapiret2_t.

  CLEAR: ev_exnum, et_return.

* 1. 필수값
  IF iv_rqnum IS INITIAL.
    et_return = VALUE #( ( type = 'E' message = '요청번호(RQNUM)는 필수입니다.' ) ).
    RETURN.
  ENDIF.

* 2. 요청서 존재·상태 확인
  SELECT SINGLE exnum, rqsta
    FROM ztexa00060
    WHERE rqnum = @iv_rqnum
    INTO @DATA(ls_req).
  IF sy-subrc <> 0.
    et_return = VALUE #( ( type = 'E' message = |요청 { iv_rqnum }이(가) 존재하지 않습니다.| ) ).
    RETURN.
  ENDIF.

  IF ls_req-rqsta <> lc_wait.
    IF ls_req-rqsta = lc_cncl.
      et_return = VALUE #( ( type = 'E' message = |요청 { iv_rqnum }은(는) 취소된 요청입니다.| ) ).
    ELSE.
      et_return = VALUE #( ( type = 'E' message = |요청 { iv_rqnum }은(는) 이미 처리된 요청입니다.| ) ).
    ENDIF.
    RETURN.
  ENDIF.

* 3. 완료 처리
  UPDATE ztexa00060
    SET rqsta = @lc_done,
        rstxt = @iv_rstxt,
        cmdat = @sy-datum,
        cmusr = @sy-uname,
        aenam = @sy-uname,
        aedat = @sy-datum,
        aezet = @sy-uzeit
    WHERE rqnum = @iv_rqnum.
  IF sy-subrc <> 0.
    et_return = VALUE #( ( type = 'E' message = '요청서 완료 처리에 실패했습니다.' ) ).
    RETURN.
  ENDIF.

  ev_exnum  = ls_req-exnum.
  et_return = VALUE #( ( type = 'S' message = |요청 { iv_rqnum } 완료 처리 (Exception { ls_req-exnum })| ) ).

* 3-2. 담당자 알림 (실패해도 완료 처리는 유지 — NOTIFY는 W만 반환)
  SELECT SINGLE uname
    FROM ztexa00010
    WHERE exnum = @ls_req-exnum
    INTO @DATA(lv_owner).
  IF sy-subrc = 0 AND lv_owner IS NOT INITIAL.
    CLEAR lt_nret.
    CALL FUNCTION 'ZCM_EXC_NOTIFY'
      EXPORTING
        iv_exnum  = ls_req-exnum
        iv_uname  = lv_owner
        iv_event  = 'RQDN'
        iv_rqnum  = iv_rqnum
      IMPORTING
        et_return = lt_nret.
    APPEND LINES OF lt_nret TO et_return.
  ENDIF.


* 4. 처리이력 기록 (실패해도 완료 처리는 유지, 경고만 반환)
  SELECT SINGLE prsta
    FROM ztexa00010
    WHERE exnum = @ls_req-exnum
    INTO @DATA(lv_prsta).

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZEX_LOGNO'
    IMPORTING
      number      = ls_hist-logno
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'W' message = '처리이력 채번에 실패했습니다. 이력을 확인하세요.' ) TO et_return.
    RETURN.
  ENDIF.

  lv_txt = |후속 요청 완료: { iv_rqnum }|.
  IF iv_rstxt IS NOT INITIAL.
    lv_txt = |{ lv_txt } [{ iv_rstxt }]|.
  ENDIF.

  ls_hist-exnum = ls_req-exnum.
  ls_hist-prres = 'RQDN'.
  ls_hist-uname = sy-uname.
  ls_hist-prtms = utclong_current( ).
  ls_hist-prtxt = lv_txt.
  ls_hist-ernam = sy-uname.
  ls_hist-erdat = sy-datum.
  ls_hist-erzet = sy-uzeit.

  INSERT ztexa00020 FROM @ls_hist.
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'W' message = '처리이력 기록에 실패했습니다. 이력을 확인하세요.' ) TO et_return.
  ENDIF.
ENDFUNCTION.
