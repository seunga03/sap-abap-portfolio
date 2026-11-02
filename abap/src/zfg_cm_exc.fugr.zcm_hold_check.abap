FUNCTION ZCM_HOLD_CHECK.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_EXNUM) TYPE  ZTEXA00030-EXNUM OPTIONAL
*"     REFERENCE(IV_TDTYP) TYPE  ZTEXA00030-TDTYP OPTIONAL
*"     REFERENCE(IV_TDNUM) TYPE  ZTEXA00030-TDNUM OPTIONAL
*"  EXPORTING
*"     REFERENCE(EV_HELD) TYPE  ABAP_BOOL
*"     REFERENCE(EV_HDNUM) TYPE  ZTEXA00030-HDNUM
*"----------------------------------------------------------------------
  CONSTANTS: lc_active TYPE ztexa00030-hdsta VALUE 'ACTV'.   " TODO(A1)

  DATA: lv_hdnum TYPE ztexa00030-hdnum,
        lr_exnum TYPE RANGE OF ztexa00030-exnum,
        lr_tdtyp TYPE RANGE OF ztexa00030-tdtyp,
        lr_tdnum TYPE RANGE OF ztexa00030-tdnum.

  CLEAR: ev_held, ev_hdnum.

*--- 조회 조건이 모두 비면 전체 조회가 되므로 막는다
  IF iv_exnum IS INITIAL AND iv_tdnum IS INITIAL.
    RETURN.
  ENDIF.

*--- 입력된 값만 조건으로 만든다
  IF iv_exnum IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = iv_exnum ) TO lr_exnum.
  ENDIF.
  IF iv_tdtyp IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = iv_tdtyp ) TO lr_tdtyp.
  ENDIF.
  IF iv_tdnum IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = iv_tdnum ) TO lr_tdnum.
  ENDIF.

  SELECT SINGLE hdnum
    FROM ztexa00030
    WHERE hdsta = @lc_active
      AND exnum IN @lr_exnum
      AND tdtyp IN @lr_tdtyp
      AND tdnum IN @lr_tdnum
    INTO @lv_hdnum.

  IF sy-subrc = 0.
    ev_held  = abap_true.
    ev_hdnum = lv_hdnum.
  ENDIF.
ENDFUNCTION.
