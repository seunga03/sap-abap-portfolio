FUNCTION z_fi_create_ar.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BILNO) TYPE  ZTSDA00050-BILNO
*"  EXPORTING
*"     REFERENCE(EV_ARNUM) TYPE  ZTCMA00100-ARNUM
*"     REFERENCE(EV_DUEDT) TYPE  ZTCMA00100-DUEDT
*"     REFERENCE(EV_MSG) TYPE  STRING
*"  EXCEPTIONS
*"      NOT_FOUND
*"      ALREADY_EXISTS
*"      NO_ZTERM
*"      INSERT_FAILED
*"----------------------------------------------------------------------
  DATA: ls_bil   TYPE ztsda00050,
        ls_ar    TYPE ztcma00100,
        lv_max   TYPE ztcma00100-arnum,
        lv_n     TYPE n LENGTH 8,
        lv_zterm TYPE ztcma00050-zterm,
        lv_ztday TYPE ztfia00080-ztday,
        lv_days  TYPE i.

  CLEAR: ev_arnum, ev_duedt, ev_msg.

  "─ 1. 청구 헤더
  SELECT SINGLE * FROM ztsda00050 INTO ls_bil
    WHERE bilno = iv_bilno.
  IF sy-subrc <> 0.
    ev_msg = |청구 { iv_bilno }이(가) 없습니다.|.
    RAISE not_found.
  ENDIF.

  "─ 2. 중복 방지 (청구 1건 = AR 1건)
  SELECT SINGLE arnum FROM ztcma00100 INTO ev_arnum
    WHERE bilno = iv_bilno.
  IF sy-subrc = 0.
    ev_msg = |청구 { iv_bilno }의 매출채권 { ev_arnum }이(가) 이미 있습니다.|.
    RAISE already_exists.
  ENDIF.

  "─ 3. 수금기한 = 청구일 + 고객 지급조건 일수
  "     (고객 마스터 키가 고객번호+배송처라 고객당 여러 행 → 아무 행의 ZTERM)
  SELECT SINGLE zterm FROM ztcma00050 INTO lv_zterm
    WHERE kunnr = ls_bil-kunnr.
  IF sy-subrc <> 0 OR lv_zterm IS INITIAL.
    ev_msg = |고객 { ls_bil-kunnr }의 지급조건(ZTERM)이 없습니다.|.
    RAISE no_zterm.
  ENDIF.

  SELECT SINGLE ztday FROM ztfia00080 INTO lv_ztday
    WHERE zterm = lv_zterm
      AND actyn = 'Y'.
  IF sy-subrc <> 0.
    ev_msg = |지급조건 { lv_zterm }이(가) 지급조건 마스터에 없거나 미사용입니다.|.
    RAISE no_zterm.
  ENDIF.
  lv_days = lv_ztday.

  "─ 4. 채권번호 (AR + 8자리, AP와 같은 MAX+1)
  SELECT MAX( arnum ) FROM ztcma00100 INTO lv_max
    WHERE arnum LIKE 'AR%'.
  IF lv_max IS NOT INITIAL.
    lv_n = lv_max+2(8).
  ENDIF.
  lv_n = lv_n + 1.
  CONCATENATE 'AR' lv_n INTO ls_ar-arnum.

  "─ 5. AR INSERT
  ls_ar-bilno = ls_bil-bilno.
  ls_ar-kunnr = ls_bil-kunnr.
  ls_ar-dmbtr = ls_bil-totam.                " 총 청구금액 (공급가액 + 세액)
  ls_ar-waers = ls_bil-waers.
  ls_ar-bldat = ls_bil-bildt.                " 발생일 = 청구일
  ls_ar-duedt = ls_bil-bildt + lv_days.      " 수금기한
  ls_ar-clsta = '0010'.                      " 미결
  ls_ar-ernam = sy-uname.
  ls_ar-erdat = sy-datum.
  ls_ar-erzet = sy-uzeit.

  INSERT ztcma00100 FROM ls_ar.
  IF sy-subrc <> 0.
    ev_msg = |매출채권 { ls_ar-arnum } 저장 실패|.
    RAISE insert_failed.
  ENDIF.

  "─ 6. 청구에 AR 생성 표시
  UPDATE ztsda00050
     SET aryno = 'Y'
         aenam = sy-uname
         aedat = sy-datum
         aezet = sy-uzeit
   WHERE bilno = iv_bilno.

  ev_arnum = ls_ar-arnum.
  ev_duedt = ls_ar-duedt.
  ev_msg   = |매출채권 { ls_ar-arnum } 생성 (수금기한 { ls_ar-duedt DATE = USER })|.

ENDFUNCTION.
