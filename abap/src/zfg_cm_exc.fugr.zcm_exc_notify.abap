FUNCTION zcm_exc_notify.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_EXNUM) TYPE  ZTEXA00010-EXNUM
*"     VALUE(IV_UNAME) TYPE  SYUNAME
*"     VALUE(IV_EVENT) TYPE  CHAR4 DEFAULT 'ASGN'
*"     VALUE(IV_RQNUM) TYPE  ZTEXA00060-RQNUM OPTIONAL
*"  EXPORTING
*"     VALUE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------
  CLEAR et_return.

  " 1) Exception 헤더
  SELECT SINGLE exnum, srtyp, extyp, owgrp
    FROM ztexa00010
    WHERE exnum = @iv_exnum
    INTO @DATA(ls_exc).
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'W' message = |Exception { iv_exnum } 없음 - 알림 생략| ) TO et_return.
    RETURN.
  ENDIF.

  " 2) 담당자 이메일·활성 여부 (사원 마스터 ZTCMA00190)
  SELECT SINGLE email, actyn
    FROM ztcma00190
    WHERE uname = @iv_uname
    INTO @DATA(ls_emp).
  IF sy-subrc <> 0 OR ls_emp-actyn <> 'Y'.
    APPEND VALUE #( type = 'W'
      message = |{ iv_uname } 사원 마스터에 없거나 비활성 - 알림 생략| ) TO et_return.
    RETURN.
  ENDIF.
  DATA(lv_mail) = ls_emp-email.

  " 3) 담당자의 미결 건수 (EXTYP별)
  SELECT extyp, COUNT(*) AS cnt
    FROM ztexa00010
    WHERE uname = @iv_uname
      AND prsta NOT IN ('CLSD','RJCT')
    GROUP BY extyp
    INTO TABLE @DATA(lt_cnt).

  " 4) 본문 조립
  DATA(lv_head) = SWITCH string( iv_event
                    WHEN 'ASGN' THEN '신규 배정'
                    WHEN 'REAS' THEN '재배정'
                    WHEN 'RQDN' THEN '후속 요청 완료'
                    WHEN 'RQNW' THEN '후속 요청 도착'
                    ELSE |알림({ iv_event })| ).
  DATA(lt_body) = VALUE bcsy_text(
    ( line = |[Exception 알림] { lv_head }| )
    ( line = || )
    ( line = |번호: { ls_exc-exnum }   출처: { ls_exc-srtyp }   유형: { ls_exc-extyp }| ) ).

  " 후속 요청 완료 알림: 요청 정보 추가
  IF ( iv_event = 'RQDN' OR iv_event = 'RQNW' ) AND iv_rqnum IS NOT INITIAL.
    SELECT SINGLE acttp, tgpgm, rqtxt, rstxt
      FROM ztexa00060
      WHERE rqnum = @iv_rqnum
      INTO @DATA(ls_rq).
    IF sy-subrc = 0.
      APPEND VALUE #( line = || ) TO lt_body.
      APPEND VALUE #( line = |요청번호: { iv_rqnum }   조치: { ls_rq-acttp }   처리 프로그램: { ls_rq-tgpgm }| ) TO lt_body.
      IF iv_event = 'RQNW'.
        IF ls_rq-rqtxt IS NOT INITIAL.
          APPEND VALUE #( line = |요청 메모: { ls_rq-rqtxt }| ) TO lt_body.
        ENDIF.
        APPEND VALUE #( line = |※ 처리 프로그램에서 요청을 처리하면 Exception 담당자에게 완료 알림이 갑니다.| ) TO lt_body.
      ELSE.
        IF ls_rq-rstxt IS NOT INITIAL.
          APPEND VALUE #( line = |처리 메모: { ls_rq-rstxt }| ) TO lt_body.
        ENDIF.
        APPEND VALUE #( line = |※ Exception은 조치중 상태입니다. 결과를 확인한 뒤 재검증 또는 종료를 진행하세요.| ) TO lt_body.
      ENDIF.
    ENDIF.
  ENDIF.

  APPEND VALUE #( line = || ) TO lt_body.
  APPEND VALUE #( line = |담당자 { iv_uname } 님의 미결 현황| ) TO lt_body.
  LOOP AT lt_cnt INTO DATA(ls_cnt).
    APPEND VALUE #( line = |  { ls_cnt-extyp } : { ls_cnt-cnt }건| ) TO lt_body.
  ENDLOOP.

  " ★ 바로가기 링크 (배포된 cm03app. 8000(http)은 44300 세션과 쿠키가 충돌하므로 44300 사용)
  DATA lv_base TYPE string.
  lv_base = `https://bgissap2.bgissap.co.kr:44300/sap/bc/ui5_ui5/sap/zcm03app/index.html`.
  lv_base = lv_base && `?sap-client=100&sap-ui-language=KO`.

  DATA lv_html TYPE string.
  LOOP AT lt_body INTO DATA(ls_b).
    lv_html = lv_html && |{ ls_b-line }<br>|.
  ENDLOOP.
  lv_html = lv_html && `<br><a href="` && lv_base.
  lv_html = lv_html && |#/Exception('{ ls_exc-exnum }')">|.
  lv_html = lv_html && |▶ { ls_exc-exnum } 상세 열기</a><br>|.
  lv_html = lv_html && `<a href="` && lv_base && `">`.
  lv_html = lv_html && `▶ Exception 목록 열기</a>`.
  DATA(lt_html) = cl_bcs_convert=>string_to_soli( lv_html ).

  " 5) 발송 (고속문서 항상 + 메일은 주소가 있을 때). COMMIT 하지 않음 - 호출자 LUW
  TRY.
      DATA(lo_req) = cl_bcs=>create_persistent( ).
      lo_req->set_document(
        cl_document_bcs=>create_document(
          i_type    = 'HTM'
          i_text    = lt_html
          i_subject = |[Exception] { ls_exc-exnum } { lv_head }| ) ).

      lo_req->add_recipient(
        i_recipient = cl_sapuser_bcs=>create( iv_uname )
        i_express   = abap_true ).

      IF lv_mail IS NOT INITIAL.
        lo_req->add_recipient(
          i_recipient = cl_cam_address_bcs=>create_internet_address( lv_mail ) ).
      ELSE.
        APPEND VALUE #( type = 'W'
          message = |{ iv_uname } 이메일 없음 - 고속문서만 발송| ) TO et_return.
      ENDIF.

      lo_req->set_send_immediately( abap_true ).
      lo_req->send( ).
    CATCH cx_bcs INTO DATA(lx).
      " 알림 실패가 Exception 생성을 막으면 안 되므로 E가 아니라 W
      APPEND VALUE #( type = 'W' message = lx->get_text( ) ) TO et_return.
  ENDTRY.
ENDFUNCTION.
