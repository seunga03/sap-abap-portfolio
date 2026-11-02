FUNCTION ZCM_EXC_REQ_CANCEL.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_EXNUM) TYPE  ZDE_EXNUM
*"  EXPORTING
*"     REFERENCE(EV_CNT) TYPE  I
*"     REFERENCE(EV_LIST) TYPE  STRING
*"     REFERENCE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------

  CONSTANTS: lc_wait TYPE ztexa00060-rqsta VALUE 'WAIT',
             lc_cncl TYPE ztexa00060-rqsta VALUE 'CNCL'.
  DATA lt_rq TYPE STANDARD TABLE OF ztexa00060-rqnum WITH EMPTY KEY.

  CLEAR: ev_cnt, ev_list, et_return.

  IF iv_exnum IS INITIAL.
    et_return = VALUE #( ( type = 'E' message = 'EXNUM은 필수입니다.' ) ).
    RETURN.
  ENDIF.

  SELECT rqnum FROM ztexa00060
    WHERE exnum = @iv_exnum AND rqsta = @lc_wait
    ORDER BY rqnum
    INTO TABLE @lt_rq.
  IF lt_rq IS INITIAL.
    RETURN.                       " 취소할 대기 요청 없음 (정상)
  ENDIF.

  UPDATE ztexa00060
     SET rqsta = @lc_cncl,
         aenam = @sy-uname, aedat = @sy-datum, aezet = @sy-uzeit
   WHERE exnum = @iv_exnum AND rqsta = @lc_wait.

  ev_cnt  = sy-dbcnt.
  ev_list = concat_lines_of( table = lt_rq sep = `, ` ).
  et_return = VALUE #( ( type = 'S' message = |후속 요청 취소: { ev_list }| ) ).
ENDFUNCTION.
