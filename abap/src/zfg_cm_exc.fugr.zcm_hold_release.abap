FUNCTION ZCM_HOLD_RELEASE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_EXNUM) TYPE  ZTEXA00030-EXNUM OPTIONAL
*"     REFERENCE(IV_HDNUM) TYPE  ZTEXA00030-HDNUM OPTIONAL
*"  EXPORTING
*"     REFERENCE(EV_CNT) TYPE  I
*"     REFERENCE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------
  CONSTANTS: lc_active   TYPE ztexa00030-hdsta VALUE 'ACTV',   " TODO(A1)
             lc_released TYPE ztexa00030-hdsta VALUE 'RLSD'.   " TODO(A1)

  DATA: ls_ret TYPE bapiret2.

  CLEAR: ev_cnt, et_return.

*--- 1. 입력 검증 (둘 중 하나는 필수)
  IF iv_exnum IS INITIAL AND iv_hdnum IS INITIAL.
    ls_ret-type    = 'E'.
    ls_ret-message = 'EXNUM 또는 HDNUM 중 하나는 필수입니다'.
    APPEND ls_ret TO et_return.
    RETURN.
  ENDIF.

*--- 2. 활성 Hold 해제
  IF iv_hdnum IS NOT INITIAL.
    UPDATE ztexa00030
      SET hdsta = lc_released
          rldat = sy-datum
          aenam = sy-uname
          aedat = sy-datum
          aezet = sy-uzeit
      WHERE hdnum = iv_hdnum
        AND hdsta = lc_active.
  ELSE.
    UPDATE ztexa00030
      SET hdsta = lc_released
          rldat = sy-datum
          aenam = sy-uname
          aedat = sy-datum
          aezet = sy-uzeit
      WHERE exnum = iv_exnum
        AND hdsta = lc_active.
  ENDIF.

  ev_cnt = sy-dbcnt.

  IF ev_cnt = 0.
    ls_ret-type    = 'W'.
    ls_ret-message = '해제할 활성 Hold가 없습니다'.
  ELSE.
    ls_ret-type    = 'S'.
    ls_ret-message = |Payment Hold { ev_cnt }건 해제 완료|.
  ENDIF.
  APPEND ls_ret TO et_return.
ENDFUNCTION.
