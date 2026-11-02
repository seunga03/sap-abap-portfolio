FUNCTION ZCM_EXC_REQ_GET.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_TGPGM) TYPE  ZTEXA00060-TGPGM
*"  EXPORTING
*"     VALUE(ET_REQ) TYPE  ZTT_EXREQ
*"     VALUE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------
*----------------------------------------------------------------------
* Exception 후속 요청 대기 목록 조회 (ZTEXA00060, RQSTA = WAIT)
* - 대상 프로그램(TGPGM) 기준. 조회만 하며 DB 변경 없음
*----------------------------------------------------------------------
  CONSTANTS lc_wait TYPE ztexa00060-rqsta VALUE 'WAIT'.   " TODO(A1) RQSTA 코드값 확정 시 점검

  DATA lv_tgpgm TYPE ztexa00060-tgpgm.

  CLEAR: et_req, et_return.

  IF iv_tgpgm IS INITIAL.
    et_return = VALUE #( ( type = 'E' message = '대상 프로그램(TGPGM)은 필수입니다.' ) ).
    RETURN.
  ENDIF.

  lv_tgpgm = to_upper( iv_tgpgm ).

  SELECT *
    FROM ztexa00060
    WHERE tgpgm = @lv_tgpgm
      AND rqsta = @lc_wait
    ORDER BY rqnum
    INTO TABLE @et_req.

  IF sy-subrc <> 0.
    et_return = VALUE #( ( type = 'I' message = |{ lv_tgpgm }의 대기 중인 요청이 없습니다.| ) ).
  ENDIF.
ENDFUNCTION.
