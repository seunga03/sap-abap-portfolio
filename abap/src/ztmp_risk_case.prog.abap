*&---------------------------------------------------------------------*
*& Report ZTMP_RISK_CASE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZTMP_RISK_CASE.

PARAMETERS p_ebeln TYPE ztmma00060-ebeln DEFAULT '4500009001'.
PARAMETERS p_gr    AS CHECKBOX.   " OFF = PO+RISK 생성 / ON = 입고(101) 행 추가

DATA: lv_ex  TYPE ztexa00010-exnum,
      lt_ret TYPE bapiret2_t.

START-OF-SELECTION.
  IF p_gr = abap_false.
    SELECT SINGLE matnr, meins FROM ztmma00060 INTO @DATA(ls_ref).
    SELECT SINGLE lifnr FROM ztcma00010 INTO @DATA(lv_lifnr).

    DATA(ls_h) = VALUE ztmma00050( ebeln = p_ebeln lifnr = lv_lifnr
                                   bedat = sy-datum pstat = '0010' ).
    INSERT ztmma00050 FROM @ls_h.

    DATA(ls_i) = VALUE ztmma00060( ebeln = p_ebeln ebelp = '00010'
                                   matnr = ls_ref-matnr meins = ls_ref-meins
                                   menge = 10 eindt = sy-datum - 10 ).
    INSERT ztmma00060 FROM @ls_i.

    CALL FUNCTION 'ZCM_EXC_CREATE'
      EXPORTING iv_srtyp = 'RISK' iv_srnum = p_ebeln iv_sritm = '00010'
                iv_owgrp = 'MM' iv_extyp = 'PROC' iv_notify = abap_false
      IMPORTING ev_exnum = lv_ex
                et_return = lt_ret.
    COMMIT WORK.
    WRITE: / '생성된 Exception:', lv_ex.
  ELSE.
    DATA(ls_g) = VALUE ztmma00090( mblnr = '5999999001' mjahr = sy-datum(4)
                                   zeile = '0001' ebeln = p_ebeln ebelp = '00010'
                                   menge = 10 bwart = '101' ).
    INSERT ztmma00090 FROM @ls_g.
    COMMIT WORK.
    WRITE: / '입고(101) 10개 추가 완료'.
  ENDIF.
