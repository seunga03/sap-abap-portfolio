FUNCTION ZCM_EXC_ASSIGN_AUTO.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_EXNUM) TYPE  ZTEXA00010-EXNUM
*"     VALUE(IV_OWGRP) TYPE  ZTEXA00010-OWGRP
*"     VALUE(IV_NOTIFY) TYPE  ABAP_BOOL DEFAULT ABAP_TRUE
*"  EXPORTING
*"     VALUE(EV_UNAME) TYPE  SYUNAME
*"     VALUE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------
CLEAR: ev_uname, et_return.

CONSTANTS lc_prres TYPE ztexa00020-prres VALUE 'ASGN'.

DATA: lr_dept  TYPE RANGE OF ztcma00190-dept,
      lt_nret  TYPE bapiret2_t,
      lv_logno TYPE ztexa00020-logno,
      ls_hist  TYPE ztexa00020,
      lv_ts    TYPE timestampl.

" 후보 부서: BOTH면 MM+FI 합집합, 아니면 같은 부서
IF iv_owgrp = 'BOTH'.
  lr_dept = VALUE #( ( sign = 'I' option = 'EQ' low = 'MM' )
                     ( sign = 'I' option = 'EQ' low = 'FI' ) ).
ELSE.
  lr_dept = VALUE #( ( sign = 'I' option = 'EQ' low = iv_owgrp ) ).
ENDIF.

" 미결 최소 1명 (동률이면 ID 오름차순)
SELECT e~uname, COUNT( x~exnum ) AS cnt
  FROM ztcma00190 AS e
  LEFT OUTER JOIN ztexa00010 AS x
    ON  x~uname = e~uname
    AND x~prsta NOT IN ( 'CLSD', 'RJCT' )
  WHERE e~actyn = 'Y'
    AND e~dept IN @lr_dept
  GROUP BY e~uname
  ORDER BY cnt, e~uname
  INTO TABLE @DATA(lt_cand)
  UP TO 1 ROWS.

IF lt_cand IS INITIAL.
  APPEND VALUE #( type = 'W'
    message = |{ iv_exnum }: 배정 가능한 담당자 없음 - 미배정 유지| ) TO et_return.
  RETURN.
ENDIF.

ev_uname = lt_cand[ 1 ]-uname.

" 담당자 반영 (변경자/변경일시/ETag 함께 갱신)
GET TIME STAMP FIELD lv_ts.
UPDATE ztexa00010
   SET uname = @ev_uname,
       aedat = @sy-datum,
       aezet = @sy-uzeit,
       aenam = @sy-uname,
       local_last_changed_at = @lv_ts,
       last_changed_at       = @lv_ts
 WHERE exnum = @iv_exnum.
IF sy-subrc <> 0.
  CLEAR ev_uname.
  APPEND VALUE #( type = 'E'
    message = |{ iv_exnum }: Exception 없음 - 배정 실패| ) TO et_return.
  RETURN.
ENDIF.

" 처리 이력 1건 (실패해도 배정은 유지)
CALL FUNCTION 'NUMBER_GET_NEXT'
  EXPORTING
    nr_range_nr = '01'
    object      = 'ZEX_LOGNO'
  IMPORTING
    number      = lv_logno
  EXCEPTIONS
    OTHERS      = 1.
IF sy-subrc = 0.
  ls_hist-logno = lv_logno.
  ls_hist-exnum = iv_exnum.
  ls_hist-uname = sy-uname.
  ls_hist-prres = lc_prres.
  ls_hist-prtxt = |자동 배정: { ev_uname }|.
  ls_hist-prtms = utclong_current( ).
  ls_hist-erdat = sy-datum.
  ls_hist-erzet = sy-uzeit.
  ls_hist-ernam = sy-uname.
  INSERT ztexa00020 FROM @ls_hist.
ELSE.
  APPEND VALUE #( type = 'W' message = '이력 채번 실패 - 이력 생략' ) TO et_return.
ENDIF.

" 알림 (실패해도 배정은 유지)
IF iv_notify = abap_true.
  CALL FUNCTION 'ZCM_EXC_NOTIFY'
    EXPORTING
      iv_exnum  = iv_exnum
      iv_uname  = ev_uname
      iv_event  = 'ASGN'
    IMPORTING
      et_return = lt_nret.
   APPEND LINES OF lt_nret TO et_return.
ENDIF.
ENDFUNCTION.
