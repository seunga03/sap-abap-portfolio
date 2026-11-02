FUNCTION ZSD_GET_NEXT_NO.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_DOCTY) TYPE  CHAR2
*"  EXPORTING
*"     REFERENCE(EV_NUMBER) TYPE  CHAR10
*"  EXCEPTIONS
*"      INVALID_DOCTY
*"      NUMBER_ERROR
*"----------------------------------------------------------------------


  DATA:
    lv_nr  TYPE nrnr,
    lv_seq TYPE n LENGTH 8.

  CLEAR ev_number.

*---------------------------------------------------------------------*
* 문서유형 → 번호범위 구간
* SNRO ZSD_NUM : 01 SO / 02 DL / 03 BI / 04 RK
*---------------------------------------------------------------------*
  CASE iv_docty.
    WHEN 'SO'.
      lv_nr = '01'.
    WHEN 'DL'.
      lv_nr = '02'.
    WHEN 'BI'.
      lv_nr = '03'.
    WHEN 'RK'.
      lv_nr = '04'.
    WHEN OTHERS.
      RAISE invalid_docty.
  ENDCASE.

*---------------------------------------------------------------------*
* 채번
*---------------------------------------------------------------------*
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = lv_nr
      object      = 'ZSD_NUM'
    IMPORTING
      number      = lv_seq
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc <> 0.
    RAISE number_error.
  ENDIF.

*---------------------------------------------------------------------*
* 접두어 2자리 + 8자리
*---------------------------------------------------------------------*
  ev_number = |{ iv_docty }{ lv_seq }|.


ENDFUNCTION.
