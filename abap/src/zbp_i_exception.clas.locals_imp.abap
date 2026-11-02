CLASS lcl_c DEFINITION FINAL.
  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF prsta,                      " Exception 처리상태
        open TYPE ztexa00010-prsta VALUE 'OPEN',
        prog TYPE ztexa00010-prsta VALUE 'PROG',
        actn TYPE ztexa00010-prsta VALUE 'ACTN',
        clsd TYPE ztexa00010-prsta VALUE 'CLSD',
        rjct TYPE ztexa00010-prsta VALUE 'RJCT',
      END OF prsta,
      BEGIN OF hdsta,                      " Payment Hold 상태 (ZTCMA00080 HDSTA)
        actv TYPE ztexa00030-hdsta VALUE 'ACTV',
        rlsd TYPE ztexa00030-hdsta VALUE 'RLSD',
      END OF hdsta,
      BEGIN OF rqsta,                      " 후속 요청 상태 (ZTCMA00080 RQSTA)
        wait TYPE ztexa00060-rqsta VALUE 'WAIT',
      END OF rqsta.
ENDCLASS.

CLASS lcl_hist_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-DATA mt_hist TYPE STANDARD TABLE OF ztexa00020 WITH EMPTY KEY.
    CLASS-METHODS add
      IMPORTING iv_exnum TYPE ztexa00020-exnum
                iv_prres TYPE ztexa00020-prres
                iv_prtxt TYPE ztexa00020-prtxt OPTIONAL.
    " 같은 저장 단위에 같은 건(exnum)+같은 결과코드 행이 있으면 문구만 덧붙임 (이력 행 합치기)
    CLASS-METHODS merge
      IMPORTING iv_exnum TYPE ztexa00020-exnum
                iv_prres TYPE ztexa00020-prres
                iv_add   TYPE string.
ENDCLASS.

CLASS lcl_hist_buffer IMPLEMENTATION.
  METHOD add.
    APPEND VALUE #( exnum = iv_exnum prres = iv_prres prtxt = iv_prtxt ) TO mt_hist.
  ENDMETHOD.
  METHOD merge.
    DATA(lv_idx) = 0.
    LOOP AT mt_hist ASSIGNING FIELD-SYMBOL(<ls_h>)
         WHERE exnum = iv_exnum AND prres = iv_prres.
      lv_idx = sy-tabix.
    ENDLOOP.
    IF lv_idx > 0.
      ASSIGN mt_hist[ lv_idx ] TO <ls_h>.
      <ls_h>-prtxt = |{ <ls_h>-prtxt }{ iv_add }|.
    ELSE.
      add( iv_exnum = iv_exnum iv_prres = iv_prres iv_prtxt = CONV #( condense( iv_add ) ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_notify_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_notify,
             exnum TYPE ztexa00010-exnum,
             uname TYPE syuname,
             event TYPE char4,
             rqnum TYPE ztexa00060-rqnum,
           END OF ty_notify.
    CLASS-DATA mt_notify TYPE STANDARD TABLE OF ty_notify WITH EMPTY KEY.
    CLASS-METHODS add
      IMPORTING iv_exnum TYPE ztexa00010-exnum
                iv_uname TYPE syuname
                iv_event TYPE char4 DEFAULT 'REAS'
                iv_rqnum TYPE ztexa00060-rqnum OPTIONAL.
ENDCLASS.

CLASS lcl_notify_buffer IMPLEMENTATION.
  METHOD add.
    APPEND VALUE #( exnum = iv_exnum uname = iv_uname
                    event = iv_event rqnum = iv_rqnum ) TO mt_notify.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_hold_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_rel,
             exnum TYPE ztexa00010-exnum,
             hdnum TYPE ztexa00030-hdnum,
             prsta TYPE ztexa00010-prsta,
           END OF ty_rel.
    CLASS-DATA mt_release TYPE STANDARD TABLE OF ty_rel WITH EMPTY KEY.
    CLASS-METHODS add_release
      IMPORTING iv_exnum TYPE ztexa00010-exnum
                iv_hdnum TYPE ztexa00030-hdnum
                iv_prsta TYPE ztexa00010-prsta.
ENDCLASS.

CLASS lcl_hold_buffer IMPLEMENTATION.
  METHOD add_release.
    APPEND VALUE #( exnum = iv_exnum hdnum = iv_hdnum prsta = iv_prsta ) TO mt_release.
  ENDMETHOD.
ENDCLASS.
CLASS lcl_req_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_req,
             exnum TYPE ztexa00010-exnum,
             acttp TYPE ztexa00060-acttp,
             rqtxt TYPE ztexa00060-rqtxt,
           END OF ty_req,
           BEGIN OF ty_cancel,
             exnum TYPE ztexa00010-exnum,
             prsta TYPE ztexa00010-prsta,
           END OF ty_cancel.
    CLASS-DATA: mt_req    TYPE STANDARD TABLE OF ty_req    WITH EMPTY KEY,
                mt_cancel TYPE STANDARD TABLE OF ty_cancel WITH EMPTY KEY.
    CLASS-METHODS add
      IMPORTING iv_exnum TYPE ztexa00010-exnum
                iv_acttp TYPE ztexa00060-acttp
                iv_rqtxt TYPE ztexa00060-rqtxt OPTIONAL.
    CLASS-METHODS add_cancel
      IMPORTING iv_exnum TYPE ztexa00010-exnum
                iv_prsta TYPE ztexa00010-prsta.
ENDCLASS.

CLASS lcl_req_buffer IMPLEMENTATION.
  METHOD add.
    APPEND VALUE #( exnum = iv_exnum acttp = iv_acttp rqtxt = iv_rqtxt ) TO mt_req.
  ENDMETHOD.
  METHOD add_cancel.
    APPEND VALUE #( exnum = iv_exnum prsta = iv_prsta ) TO mt_cancel.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_zi_exception DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.

  PRIVATE SECTION.
    METHODS from_ret
      IMPORTING is_ret TYPE bapiret2
      RETURNING VALUE(ro_msg) TYPE REF TO if_abap_behv_message.

ENDCLASS.

CLASS lsc_zi_exception IMPLEMENTATION.
  METHOD cleanup_finalize.
    " 저장 후/실패·롤백 시 버퍼를 비움 (이전 요청 데이터가 다음 저장에 섞이는 것 방지)
    CLEAR: lcl_hist_buffer=>mt_hist,
           lcl_notify_buffer=>mt_notify,
           lcl_hold_buffer=>mt_release,
           lcl_req_buffer=>mt_req,
           lcl_req_buffer=>mt_cancel.
  ENDMETHOD.

  METHOD from_ret.
    IF is_ret-id IS INITIAL.
      ro_msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-warning
                 text     = is_ret-message ).
    ELSE.
      ro_msg = new_message( id       = is_ret-id
                            number   = is_ret-number
                            severity = if_abap_behv_message=>severity-warning
                            v1       = is_ret-message_v1
                            v2       = is_ret-message_v2
                            v3       = is_ret-message_v3
                            v4       = is_ret-message_v4 ).
    ENDIF.
  ENDMETHOD.

  METHOD save_modified.

    " ── 후속 요청 생성 (decideAction) — FM 안에서 COMMIT 안 함, 프레임워크 COMMIT 시 확정
    "    ※ 이력 INSERT보다 앞에 둘 것 (여기서 추가한 이력도 같은 저장에 포함)
    DATA: lv_rqnum TYPE ztexa00060-rqnum,
          lv_rdup  TYPE abap_bool,
          lv_notgt TYPE abap_bool,
          lt_rret  TYPE bapiret2_t.

    LOOP AT lcl_req_buffer=>mt_req INTO DATA(ls_rq).
      CLEAR: lv_rqnum, lv_rdup, lv_notgt, lt_rret.
      CALL FUNCTION 'ZCM_EXC_REQ_CREATE'
        EXPORTING
          iv_exnum  = ls_rq-exnum
          iv_acttp  = ls_rq-acttp
          iv_rqtxt  = ls_rq-rqtxt
        IMPORTING
          ev_rqnum  = lv_rqnum
          ev_dup    = lv_rdup
          ev_notgt  = lv_notgt
          et_return = lt_rret.

      " 오류면 경고만 표시 (조치 결정 자체는 이미 저장 대상)
      LOOP AT lt_rret INTO DATA(ls_rret) WHERE type CA 'EA'.
        APPEND VALUE #( exnum = ls_rq-exnum
                        %msg = from_ret( ls_rret ) )
          TO reported-exception.
      ENDLOOP.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      " 대상 프로그램 없는 조치(손실확정·모니터링유지 등)는 요청서·이력 없음
      IF lv_notgt = abap_true.
        CONTINUE.
      ENDIF.

      " 이미 대기 중인 요청이면 이력 행을 만들지 않음 (반복 행 방지)
      IF lv_rdup = abap_true.
        CONTINUE.
      ENDIF.

      " 조치 결정 행에 합침: [APRC …] 메모 → 후속 요청 RQ…
      lcl_hist_buffer=>merge( iv_exnum = ls_rq-exnum
                              iv_prres = lcl_c=>prsta-actn
                              iv_add   = | → 후속 요청 { lv_rqnum }| ).
      " 후속 요청 알림: 대상 부서 활성 사원 중 미결이 가장 적은 1명
      DATA lv_tg TYPE ztexa00060-tgpgm.
      CLEAR lv_tg.
      SELECT SINGLE tgpgm FROM ztexa00060
        WHERE rqnum = @lv_rqnum INTO @lv_tg.
      DATA(lv_dept) = CONV ztcma00190-dept( lv_tg(2) ).

      SELECT e~uname, COUNT( x~exnum ) AS cnt
        FROM ztcma00190 AS e
        LEFT OUTER JOIN ztexa00010 AS x
          ON  x~uname = e~uname
          AND x~prsta NOT IN ( 'CLSD', 'RJCT' )
        WHERE e~dept = @lv_dept
          AND e~actyn = 'Y'
        GROUP BY e~uname
        ORDER BY cnt ASCENDING, e~uname ASCENDING
        INTO TABLE @DATA(lt_cand) UP TO 1 ROWS.

      IF lt_cand IS NOT INITIAL.
        lcl_notify_buffer=>add( iv_exnum = ls_rq-exnum
                                iv_uname = lt_cand[ 1 ]-uname
                                iv_event = 'RQNW'
                                iv_rqnum = lv_rqnum ).
      ELSE.
        APPEND VALUE #( exnum = ls_rq-exnum
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-warning
                                 text     = |{ lv_dept } 부서 알림 대상 없음| ) )
          TO reported-exception.
      ENDIF.
    ENDLOOP.
    CLEAR lcl_req_buffer=>mt_req.

    " ── 종료·반려 시 대기 요청 자동 취소 (close / reject / recheck 통과)
    DATA: lv_ccnt  TYPE i,
          lv_clist TYPE string,
          lt_cret  TYPE bapiret2_t.

    LOOP AT lcl_req_buffer=>mt_cancel INTO DATA(ls_cn).
      CLEAR: lv_ccnt, lv_clist, lt_cret.
      CALL FUNCTION 'ZCM_EXC_REQ_CANCEL'
        EXPORTING
          iv_exnum  = ls_cn-exnum
        IMPORTING
          ev_cnt    = lv_ccnt
          ev_list   = lv_clist
          et_return = lt_cret.

      LOOP AT lt_cret INTO DATA(ls_cret) WHERE type CA 'EA'.
        APPEND VALUE #( exnum = ls_cn-exnum
                        %msg = from_ret( ls_cret ) )
          TO reported-exception.
      ENDLOOP.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      IF lv_ccnt > 0.
        " 종료/반려 행에 합침
        lcl_hist_buffer=>merge( iv_exnum = ls_cn-exnum
                                iv_prres = ls_cn-prsta
                                iv_add   = | (후속 요청 취소: { lv_clist })| ).
      ENDIF.
    ENDLOOP.
    CLEAR lcl_req_buffer=>mt_cancel .

        " ③ Payment Hold 해제 — 이력 INSERT보다 먼저 (H: 실패 시 이력 미기록)
    DATA: lt_hret TYPE bapiret2_t,
          lv_hcnt TYPE i.

    LOOP AT lcl_hold_buffer=>mt_release INTO DATA(ls_rel).
      CLEAR: lt_hret, lv_hcnt.
      CALL FUNCTION 'ZCM_HOLD_RELEASE'
        EXPORTING
          iv_exnum  = ls_rel-exnum
        IMPORTING
          ev_cnt    = lv_hcnt
          et_return = lt_hret.
      LOOP AT lt_hret INTO DATA(ls_hret) WHERE type CA 'EAW'.
        APPEND VALUE #( exnum = ls_rel-exnum
                        %msg  = from_ret( ls_hret ) )
          TO reported-exception.
      ENDLOOP.
      IF sy-subrc = 0.            " E/A/W가 하나라도 있으면 이력 기록 안 함
        CONTINUE.
      ENDIF.
      IF lv_hcnt > 0.
        " 처리결과 'HRLS'(Hold 해제) — ZTCMA00080에 이력 결과 코드로 등록 필요
        lcl_hist_buffer=>add( iv_exnum = ls_rel-exnum
                              iv_prres = 'HRLS'
                              iv_prtxt = |Payment Hold 해제: { ls_rel-hdnum }| ).
      ENDIF.
    ENDLOOP.
    CLEAR lcl_hold_buffer=>mt_release.

    " ④ 처리이력 INSERT (B: CHECK 대신 IF — 이력이 없어도 뒤쪽 알림은 실행)
    IF lcl_hist_buffer=>mt_hist IS NOT INITIAL.
      LOOP AT lcl_hist_buffer=>mt_hist ASSIGNING FIELD-SYMBOL(<ls_hist>).
        CALL FUNCTION 'NUMBER_GET_NEXT'
          EXPORTING
            nr_range_nr             = '01'
            object                  = 'ZEX_LOGNO'
            quantity                = '1'
          IMPORTING
            number                  = <ls_hist>-logno
          EXCEPTIONS
            interval_not_found      = 1
            number_range_not_intern = 2
            object_not_found        = 3
            quantity_is_0           = 4
            quantity_is_not_1       = 5
            interval_overflow       = 6
            buffer_overflow         = 7
            OTHERS                  = 8.
        IF sy-subrc <> 0.
          CLEAR <ls_hist>-logno.
          APPEND VALUE #( exnum = <ls_hist>-exnum
                          %msg  = new_message_with_text(
                                    severity = if_abap_behv_message=>severity-error
                                    text     = '처리이력 채번 오류.' ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.

        <ls_hist>-uname = sy-uname.
        <ls_hist>-prtms = utclong_current( ).
        <ls_hist>-ernam = sy-uname.
        <ls_hist>-erdat = sy-datum.
        <ls_hist>-erzet = sy-uzeit.
      ENDLOOP.

      DELETE lcl_hist_buffer=>mt_hist WHERE logno IS INITIAL.
      INSERT ztexa00020 FROM TABLE @lcl_hist_buffer=>mt_hist.
      CLEAR lcl_hist_buffer=>mt_hist.
    ENDIF.

    " ⑤ 알림 (재배정·후속 요청)
    DATA lt_ret TYPE bapiret2_t.

    LOOP AT lcl_notify_buffer=>mt_notify INTO DATA(ls_ntf).
      CLEAR lt_ret.
      CALL FUNCTION 'ZCM_EXC_NOTIFY'
        EXPORTING
          iv_exnum  = ls_ntf-exnum
          iv_uname  = ls_ntf-uname
          iv_event  = ls_ntf-event
          iv_rqnum  = ls_ntf-rqnum
        IMPORTING
          et_return = lt_ret.
      LOOP AT lt_ret INTO DATA(ls_ret) WHERE type CA 'EAW'.
        APPEND VALUE #( exnum = ls_ntf-exnum
                        %msg  = from_ret( ls_ret ) )
          TO reported-exception.
      ENDLOOP.
    ENDLOOP.
    CLEAR lcl_notify_buffer=>mt_notify.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_exception DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS assignto FOR MODIFY
      IMPORTING keys FOR ACTION exception~assignto RESULT result.
    METHODS assigntome FOR MODIFY
      IMPORTING keys FOR ACTION exception~assigntome RESULT result.
    METHODS releasehold FOR MODIFY
      IMPORTING keys FOR ACTION exception~releasehold RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR exception RESULT result.
    METHODS close FOR MODIFY
      IMPORTING keys FOR ACTION exception~close RESULT result.

    METHODS reject FOR MODIFY
      IMPORTING keys FOR ACTION exception~reject RESULT result.
    METHODS decideaction FOR MODIFY
      IMPORTING keys FOR ACTION exception~decideaction RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR exception RESULT result.
    METHODS recheck FOR MODIFY
      IMPORTING keys FOR ACTION exception~recheck RESULT result.
    METHODS msg
      IMPORTING iv_no  TYPE symsgno
                iv_v1  TYPE clike OPTIONAL
                iv_v2  TYPE clike OPTIONAL
                iv_sev TYPE if_abap_behv_message=>t_severity
                       DEFAULT if_abap_behv_message=>severity-error
      RETURNING VALUE(ro_msg) TYPE REF TO if_abap_behv_message.
    METHODS airecommend FOR MODIFY
      IMPORTING keys FOR ACTION exception~airecommend RESULT result.
    METHODS getairecommend FOR MODIFY
      IMPORTING keys FOR ACTION exception~getairecommend RESULT result.
    METHODS wait_req
      IMPORTING iv_exnum        TYPE ztexa00010-exnum
      RETURNING VALUE(rv_rqnum) TYPE ztexa00060-rqnum.

ENDCLASS.

CLASS lhc_exception IMPLEMENTATION.

  METHOD msg.
    ro_msg = new_message( id       = 'ZMSGA'
                          number   = iv_no
                          severity = iv_sev
                          v1       = iv_v1
                          v2       = iv_v2 ).
  ENDMETHOD.

  METHOD wait_req.
    " 해당 Exception에 대기(WAIT) 중인 후속 요청이 있으면 요청번호, 없으면 공백
    SELECT SINGLE rqnum FROM ztexa00060
      WHERE exnum = @iv_exnum
        AND rqsta = @lcl_c=>rqsta-wait
      INTO @rv_rqnum.
  ENDMETHOD.

  METHOD get_global_authorizations.
    " 프로젝트 범위: 권한 제한 없음 → 모든 Action 허용
    result = VALUE #(
                      %action-assignTo     = if_abap_behv=>auth-allowed
                      %action-assignToMe   = if_abap_behv=>auth-allowed
                      %action-releaseHold  = if_abap_behv=>auth-allowed
                      %action-reject       = if_abap_behv=>auth-allowed
                      %action-close        = if_abap_behv=>auth-allowed
                      %action-decideAction = if_abap_behv=>auth-allowed
                      %action-recheck      = if_abap_behv=>auth-allowed
                      %action-aiRecommend = if_abap_behv=>auth-allowed
                      %action-getAiRecommend = if_abap_behv=>auth-allowed
                       ).
  ENDMETHOD.
  METHOD recheck.
    CONSTANTS: lc_canc TYPE ztfia00010-mstat VALUE 'CANC'. " ZLFIA00090 gc_canc (송장 취소 = 최종반려)

    DATA: lv_held     TYPE abap_bool,
          lv_hdnum    TYPE ztexa00030-hdnum,
          lv_passed   TYPE abap_bool,
          lv_memo     TYPE string,
          lv_hmstat   TYPE ztfia00010-mstat,
          lv_cnt      TYPE i,
          lv_new_cevno TYPE ztmma00110-cevno,
          lv_new_rcsts TYPE ztmma00110-rcsts,
          lv_ordqty   TYPE ztmma00060-menge,
          lv_rcvqty   TYPE ztmma00060-menge.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception FIELDS ( prsta srtyp srnum sritm ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).

    LOOP AT lt_exc INTO DATA(ls_exc).
      CLEAR: lv_passed, lv_memo.

      " ① 조치중(ACTN) 건만
      IF ls_exc-prsta <> lcl_c=>prsta-actn.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( '036' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " INVC: 후속 요청(FI 처리)이 끝나기 전에는 진행 불가 (WAIT 요청 있음)
      IF ls_exc-srtyp = 'INVC'.
        DATA(lv_wrq_k) = wait_req( ls_exc-exnum ).
        IF lv_wrq_k IS NOT INITIAL.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( iv_no = '327' iv_v1 = lv_wrq_k ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.
      ENDIF.

      " ①-1 자동 판정 대상 소스만 허용
      CASE ls_exc-srtyp.
        WHEN 'INVC' OR 'SUBC' OR 'QM' OR 'RISK'.
        WHEN OTHERS.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( iv_no = '326' iv_v1 = ls_exc-srtyp ) )
            TO reported-exception.
          CONTINUE.
      ENDCASE.

      " ①-2 INVC: 사람이 입력한 passed 대신 송장 대사상태(DB)로 판정
      IF ls_exc-srtyp = 'INVC'.
        CLEAR: lv_hmstat, lv_cnt.
        DATA(lv_ivnum) = CONV ztfia00010-ivnum( ls_exc-srnum ).

        SELECT SINGLE mstat FROM ztfia00010
          WHERE ivnum = @lv_ivnum
          INTO @lv_hmstat.

        " 최종반려 송장은 재검증 불가 → 종료만 가능
        IF sy-subrc <> 0 OR lv_hmstat = lc_canc.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( '319' ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.

        " 통과 = HOLD/QREJ로 남은 라인이 없음
        SELECT COUNT(*) FROM ztfia00020
          WHERE ivnum = @lv_ivnum
            AND mstat IN ( 'HOLD', 'QREJ' )
          INTO @lv_cnt.

        IF lv_cnt = 0.
          lv_passed = abap_true.
          lv_memo = |송장 대사 완료 (HOLD/QREJ 없음)|.
        ELSE.
          lv_passed = abap_false.
          lv_memo   = |송장 대사 미해결 { lv_cnt }건 (HOLD/QREJ)|.
        ENDIF.
      ENDIF.

      " ①-3 SUBC: 같은 PO 품목·자재의 더 새로운 CEVNO(재업로드)가 정상(0020)이면 통과
      IF ls_exc-srtyp = 'SUBC'.
        CLEAR: lv_passed, lv_memo, lv_new_cevno, lv_new_rcsts.

        SELECT SINGLE ebeln, ebelp, matnr
          FROM ztmma00110
          WHERE cevno = @ls_exc-srnum
          INTO @DATA(ls_org).
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( iv_no = '034' iv_v1 = ls_exc-srnum ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.

        " 더 새로운 CEVNO 중 가장 최신 1건
        SELECT cevno, rcsts
          FROM ztmma00110
          WHERE ebeln = @ls_org-ebeln
            AND ebelp = @ls_org-ebelp
            AND matnr = @ls_org-matnr
            AND cevno > @ls_exc-srnum
          ORDER BY cevno DESCENDING
          INTO (@lv_new_cevno, @lv_new_rcsts)
          UP TO 1 ROWS.
        ENDSELECT.

        IF lv_new_cevno IS INITIAL.
          lv_passed = abap_false.
          lv_memo   = |재검증 대기: 정합성 재업로드(새 CEVNO) 없음|.
        ELSEIF lv_new_rcsts = '0020' OR lv_new_rcsts = 'PASS'.
          lv_passed = abap_true.
          lv_memo = |재업로드 { lv_new_cevno } 정합성 정상|.
        ELSE.
          lv_passed = abap_false.
          lv_memo   = |재업로드 { lv_new_cevno } 정합성 오류({ lv_new_rcsts })|.
        ENDIF.
      ENDIF.

            " ①-5 QM: 같은 PO 품목·자재의 더 새로운 검사(재검사)가 합격이면 통과
      IF ls_exc-srtyp = 'QM'.
        CLEAR: lv_passed, lv_memo.

        " 원 검사 품목 → 입고 문서·아이템
        SELECT SINGLE h~mblnr, h~mjahr, i~gritm, i~matnr
          FROM ztmma00130 AS i
          INNER JOIN ztmma00120 AS h ON h~inspn = i~inspn
          WHERE i~inspn = @ls_exc-srnum
            AND i~inspp = @ls_exc-sritm
          INTO @DATA(ls_qorg).
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( iv_no = '034'
                                      iv_v1 = |{ ls_exc-srnum }/{ ls_exc-sritm }| ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.

        " 입고 아이템 → PO 품목
        SELECT SINGLE ebeln, ebelp
          FROM ztmma00090
          WHERE mblnr = @ls_qorg-mblnr
            AND mjahr = @ls_qorg-mjahr
            AND zeile = @ls_qorg-gritm
          INTO @DATA(ls_qgr).
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( iv_no = '034'
                                      iv_v1 = |{ ls_qorg-mblnr }/{ ls_qorg-gritm }| ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.

        " 같은 PO 품목·자재의 더 새로운 검사 중 가장 최신 1건
        DATA: lv_q_inspn TYPE ztmma00130-inspn,
              lv_q_pasqt TYPE ztmma00130-pasqt,
              lv_q_faiqt TYPE ztmma00130-faiqt.
        CLEAR: lv_q_inspn, lv_q_pasqt, lv_q_faiqt.

        SELECT i~inspn, i~pasqt, i~faiqt
          FROM ztmma00130 AS i
          INNER JOIN ztmma00120 AS h ON h~inspn = i~inspn
          INNER JOIN ztmma00090 AS g ON g~mblnr = h~mblnr
                                    AND g~mjahr = h~mjahr
                                    AND g~zeile = i~gritm
          WHERE g~ebeln = @ls_qgr-ebeln
            AND g~ebelp = @ls_qgr-ebelp
            AND i~matnr = @ls_qorg-matnr
            AND i~inspn > @ls_exc-srnum
          ORDER BY i~inspn DESCENDING
          INTO (@lv_q_inspn, @lv_q_pasqt, @lv_q_faiqt)
          UP TO 1 ROWS.
        ENDSELECT.

        IF lv_q_inspn IS INITIAL.
          lv_passed = abap_false.
          lv_memo   = |재검증 대기: 재검사 결과(새 검사번호) 없음|.
        ELSEIF lv_q_faiqt = 0 AND lv_q_pasqt > 0.
          lv_passed = abap_true.
          lv_memo = |재검사 { lv_q_inspn } 합격 (합격 { lv_q_pasqt DECIMALS = 0 })|.
        ELSE.
          lv_passed = abap_false.
          lv_memo   = |재검사 { lv_q_inspn } 불합격(불량 { lv_q_faiqt DECIMALS = 0 })|.
        ENDIF.
      ENDIF.

      " ①-4 RISK: 입고 합계(BWART=101) >= 발주수량이면 통과 (CM02 배치와 같은 기준)
      IF ls_exc-srtyp = 'RISK'.
        CLEAR: lv_passed, lv_memo, lv_ordqty, lv_rcvqty.

        SELECT SINGLE menge
          FROM ztmma00060
          WHERE ebeln = @ls_exc-srnum
            AND ebelp = @ls_exc-sritm
          INTO @lv_ordqty.
        IF sy-subrc <> 0.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( iv_no = '034' iv_v1 = |{ ls_exc-srnum }/{ ls_exc-sritm }| ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.

        SELECT SUM( menge )
          FROM ztmma00090
          WHERE ebeln = @ls_exc-srnum
            AND ebelp = @ls_exc-sritm
            AND bwart = '101'
          INTO @lv_rcvqty.

        IF lv_rcvqty >= lv_ordqty.
          lv_passed = abap_true.
          lv_memo = |입고 { lv_rcvqty DECIMALS = 0 } / 발주 { lv_ordqty DECIMALS = 0 } (입고 완료)|.
        ELSE.
          lv_passed = abap_false.
          lv_memo   = |입고 { lv_rcvqty DECIMALS = 0 } / 발주 { lv_ordqty DECIMALS = 0 } (미입고)|.
        ENDIF.
      ENDIF.

      " ② 실패면 사유 필수 (INVC·SUBC·QM·RISK 모두 위에서 자동 채움 — 이 체크는 안전장치)
      IF lv_passed = abap_false AND lv_memo IS INITIAL.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no = '020' iv_v1 = '재검증 실패 사유' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " 통과(→종료)면 활성 Payment Hold가 없어야 함 (close와 동일)
      IF lv_passed = abap_true.
        CLEAR: lv_held, lv_hdnum.
        CALL FUNCTION 'ZCM_HOLD_CHECK'
          EXPORTING iv_exnum = ls_exc-exnum
          IMPORTING ev_held  = lv_held
                    ev_hdnum = lv_hdnum.
        IF lv_held = abap_true.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( iv_no = '315' iv_v1 = lv_hdnum ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.
      ENDIF.

      " ③ 통과 → CLSD / 실패 → ACTN 유지 (이전 단계로 되돌리지 않음)
      "    실패 시 상태는 그대로 두고 이력만 남김 → 이후 [재검증]·[종료]만 가능
      DATA(lv_tag) = COND string( WHEN lv_passed = abap_true
                                  THEN '재검증 통과' ELSE '재검증 실패' ).

      IF lv_passed = abap_true.
        MODIFY ENTITIES OF zi_exception IN LOCAL MODE
          ENTITY exception UPDATE FIELDS ( prsta aenam aedat aezet )
          WITH VALUE #( ( %tky  = ls_exc-%tky
                          prsta = lcl_c=>prsta-clsd
                          aenam = sy-uname  aedat = sy-datum  aezet = sy-uzeit ) ).

        lcl_hist_buffer=>add( iv_exnum = ls_exc-exnum
                              iv_prres = lcl_c=>prsta-clsd
                              iv_prtxt = |[{ lv_tag }] { lv_memo }| ).
        lcl_req_buffer=>add_cancel( iv_exnum = ls_exc-exnum iv_prsta = lcl_c=>prsta-clsd ).
      ELSE.
        " 상태(PRSTA)는 건드리지 않고 변경정보만 갱신 → save_modified가 호출돼 이력이 저장됨
        MODIFY ENTITIES OF zi_exception IN LOCAL MODE
          ENTITY exception UPDATE FIELDS ( aenam aedat aezet )
          WITH VALUE #( ( %tky  = ls_exc-%tky
                          aenam = sy-uname  aedat = sy-datum  aezet = sy-uzeit ) ).

        " 결과코드 RCFL(재검증 실패) — ZTCMA00080 등록 필요
        lcl_hist_buffer=>add( iv_exnum = ls_exc-exnum
                              iv_prres = 'RCFL'
                              iv_prtxt = |[{ lv_tag }] { lv_memo }| ).

        " 화면 토스트가 '완료'로만 보이지 않도록 경고 메시지 추가
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-warning
                                 text     = |재검증 실패: { lv_memo }| ) )
          TO reported-exception.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_res).
    result = VALUE #( FOR r IN lt_res ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD assigntome.
    DATA lv_ok TYPE i.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception FIELDS ( prsta uname ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_chk).

    LOOP AT lt_chk INTO DATA(ls_chk).
      " OPEN 이거나 담당자 없는 PROG만 허용 (타인 담당 건은 assignTo로 재배정)
      IF NOT ( ls_chk-prsta = lcl_c=>prsta-open
            OR ( ls_chk-prsta = lcl_c=>prsta-prog AND ls_chk-uname IS INITIAL ) ).
        DATA(lv_no) = COND symsgno(
                        WHEN ls_chk-prsta = lcl_c=>prsta-prog AND ls_chk-uname = sy-uname
                        THEN '032'      " 이미 내 담당
                        ELSE '036' ).   " 상태 불가 / 타인 담당
        APPEND VALUE #( %tky = ls_chk-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_chk-%tky
                        %msg = msg( iv_no = lv_no ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF zi_exception IN LOCAL MODE
        ENTITY exception
          UPDATE FIELDS ( uname prsta aenam aedat aezet )
          WITH VALUE #( ( %tky  = ls_chk-%tky
                          uname = sy-uname
                          prsta = lcl_c=>prsta-prog
                          aenam = sy-uname  aedat = sy-datum  aezet = sy-uzeit ) ).

      lcl_hist_buffer=>add( iv_exnum = ls_chk-exnum
                            iv_prres = lcl_c=>prsta-prog
                            iv_prtxt = |담당자 지정: { sy-uname }| ).
      lv_ok = lv_ok + 1.
    ENDLOOP.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).
    result = VALUE #( FOR ls_exc IN lt_exc ( %tky = ls_exc-%tky %param = ls_exc ) ).

    IF lv_ok > 0.
      APPEND new_message( id       = 'ZMSGA'
                          number   = '006'
                          severity = if_abap_behv_message=>severity-success
                          v1       = lv_ok ) TO reported-%other.
    ENDIF.
  ENDMETHOD.

  METHOD assignto.
    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception FIELDS ( prsta uname owgrp ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).

    LOOP AT lt_exc INTO DATA(ls_exc).
      DATA(ls_param) = keys[ %tky = ls_exc-%tky ]-%param.
      DATA(lv_new)   = to_upper( ls_param-uname ).

      " ① 담당자 필수
      IF lv_new IS INITIAL.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no = '020' iv_v1 = '담당자' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " ② 상태 재확인 (버튼 비활성 우회 방지)
      IF ls_exc-prsta <> lcl_c=>prsta-open AND ls_exc-prsta <> lcl_c=>prsta-prog.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( '036' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " ③ 같은 담당자면 거부
      IF lv_new = ls_exc-uname.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( '032' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " ③-2 사원 마스터 검증 (등록·사용 중인 담당자만)
      SELECT SINGLE dept, actyn FROM ztcma00190
        WHERE uname = @lv_new
        INTO @DATA(ls_emp).
      IF sy-subrc <> 0 OR ls_emp-actyn <> 'Y'.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no = '034' iv_v1 = lv_new ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " 담당그룹과 다른 부서면 경고만 (거부하지 않음)
      IF ls_emp-dept <> ls_exc-owgrp.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no  = '317'
                                    iv_v1  = ls_exc-owgrp
                                    iv_v2  = ls_emp-dept
                                    iv_sev = if_abap_behv_message=>severity-warning ) )
          TO reported-exception.
      ENDIF.


      " ④ 담당자만 변경 (PRSTA는 그대로)
      MODIFY ENTITIES OF zi_exception IN LOCAL MODE
        ENTITY exception UPDATE FIELDS ( uname aenam aedat aezet )
        WITH VALUE #( ( %tky  = ls_exc-%tky
                        uname = lv_new
                        aenam = sy-uname  aedat = sy-datum  aezet = sy-uzeit ) ).

      " ⑤ 이력: 현재 상태 코드로 기록 + 변경 내용
      lcl_hist_buffer=>add( iv_exnum = ls_exc-exnum
                            iv_prres = 'REAS'
                            iv_prtxt = |담당자 재배정: | &&
                                       COND string( WHEN ls_exc-uname IS INITIAL
                                                    THEN '(미지정)' ELSE ls_exc-uname ) &&
                                       | → { lv_new }| &&
                                       COND string( WHEN ls_param-memo IS NOT INITIAL
                                                    THEN | [{ ls_param-memo }]| ) ).
      lcl_notify_buffer=>add( iv_exnum = ls_exc-exnum
                              iv_uname = CONV #( lv_new ) ).
    ENDLOOP.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_res).
    result = VALUE #( FOR r IN lt_res ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD releasehold.
    DATA: lv_held  TYPE abap_bool,
          lv_hdnum TYPE ztexa00030-hdnum,
          lv_ok    TYPE i.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception FIELDS ( prsta srtyp ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).

    LOOP AT lt_exc INTO DATA(ls_exc).
      CLEAR: lv_held, lv_hdnum.
      CALL FUNCTION 'ZCM_HOLD_CHECK'
        EXPORTING
          iv_exnum = ls_exc-exnum
        IMPORTING
          ev_held  = lv_held
          ev_hdnum = lv_hdnum.

      " 활성 Hold 없으면 거부 (버튼 비활성 우회 방지)
      IF lv_held = abap_false.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( '316' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " INVC: 후속 요청(FI 처리)이 끝나기 전에는 진행 불가 (WAIT 요청 있음)
      IF ls_exc-srtyp = 'INVC'.
        DATA(lv_wrq_r) = wait_req( ls_exc-exnum ).
        IF lv_wrq_r IS NOT INITIAL.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( iv_no = '327' iv_v1 = lv_wrq_r ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.
      ENDIF.

      " 실제 UPDATE·이력은 save_modified에서 (Hold 해제 성공 시에만 이력 기록)
      lcl_hold_buffer=>add_release( iv_exnum = ls_exc-exnum
                                    iv_hdnum = lv_hdnum
                                    iv_prsta = ls_exc-prsta ).

      " save_modified가 호출되도록 변경정보만 갱신 (aiRecommend와 같은 패턴)
      MODIFY ENTITIES OF zi_exception IN LOCAL MODE
        ENTITY exception UPDATE FIELDS ( aenam aedat aezet )
        WITH VALUE #( ( %tky  = ls_exc-%tky
                        aenam = sy-uname  aedat = sy-datum  aezet = sy-uzeit ) ).
      lv_ok = lv_ok + 1.
    ENDLOOP.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_res).
    result = VALUE #( FOR r IN lt_res ( %tky = r-%tky %param = r ) ).

    IF lv_ok > 0.
      " 성공 메시지: ZMSGA 006 "&건이 정상적으로 처리되었습니다."
      APPEND new_message( id       = 'ZMSGA'
                          number   = '006'
                          severity = if_abap_behv_message=>severity-success
                          v1       = lv_ok ) TO reported-%other.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_features.

    DATA: lt_held TYPE SORTED TABLE OF ztexa00030-exnum WITH UNIQUE KEY table_line,
          lt_wait TYPE SORTED TABLE OF ztexa00060-exnum WITH UNIQUE KEY table_line.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception FIELDS ( prsta uname srtyp ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).

    " 활성 Hold가 있는 Exception 목록 (한 번에 조회)
    IF lt_exc IS NOT INITIAL.
      SELECT DISTINCT exnum FROM ztexa00030
        FOR ALL ENTRIES IN @lt_exc
        WHERE exnum = @lt_exc-exnum
          AND hdsta = @lcl_c=>hdsta-actv
        INTO TABLE @lt_held.

      " 대기(WAIT) 중인 후속 요청이 있는 Exception 목록 (INVC에서 Hold 해제·재검증·종료 잠금용)
      SELECT DISTINCT exnum FROM ztexa00060
        FOR ALL ENTRIES IN @lt_exc
        WHERE exnum = @lt_exc-exnum
          AND rqsta = @lcl_c=>rqsta-wait
        INTO TABLE @lt_wait.
    ENDIF.

    result = VALUE #( FOR ls IN lt_exc
      ( %tky = ls-%tky
        " 담당자 지정: OPEN·PROG 이면서 아직 내 담당이 아닐 때
        " 담당자 지정: OPEN(자동 배정 건 포함) 또는 담당자 없는 PROG만
        %action-assignToMe  = COND #( WHEN ls-prsta = lcl_c=>prsta-open
                                         OR ( ls-prsta = lcl_c=>prsta-prog AND ls-uname IS INITIAL )
                                      THEN if_abap_behv=>fc-o-enabled
                                      ELSE if_abap_behv=>fc-o-disabled )
        " 재배정: OPEN·PROG만
        %action-assignTo    = COND #( WHEN ls-prsta = lcl_c=>prsta-open OR ls-prsta = lcl_c=>prsta-prog
                                      THEN if_abap_behv=>fc-o-enabled
                                      ELSE if_abap_behv=>fc-o-disabled )        " Hold 해제: 활성 Hold가 있는 건만
        %action-releaseHold = COND #( WHEN line_exists( lt_held[ table_line = ls-exnum ] )
                                       AND NOT ( ls-srtyp = 'INVC'
                                                 AND line_exists( lt_wait[ table_line = ls-exnum ] ) )
                                      THEN if_abap_behv=>fc-o-enabled
                                      ELSE if_abap_behv=>fc-o-disabled )
        " 조치 결정: PROG(담당자 지정 후)만
        %action-decideAction = COND #( WHEN ls-prsta = lcl_c=>prsta-prog
                                       THEN if_abap_behv=>fc-o-enabled
                                       ELSE if_abap_behv=>fc-o-disabled )
        " 반려: OPEN·PROG
        %action-reject      = COND #( WHEN ls-prsta = lcl_c=>prsta-open OR ls-prsta = lcl_c=>prsta-prog
                                      THEN if_abap_behv=>fc-o-enabled
                                      ELSE if_abap_behv=>fc-o-disabled )
        " 재검증: ACTN(조치 진행 중)만
        %action-recheck     = COND #( WHEN ls-prsta = lcl_c=>prsta-actn
                                       AND NOT ( ls-srtyp = 'INVC'
                                                 AND line_exists( lt_wait[ table_line = ls-exnum ] ) )
                                      THEN if_abap_behv=>fc-o-enabled
                                      ELSE if_abap_behv=>fc-o-disabled )
        " 종료: ACTN(조치 완료 후)만
        %action-close       = COND #( WHEN ls-prsta = lcl_c=>prsta-actn
                                       AND NOT ( ls-srtyp = 'INVC'
                                                 AND line_exists( lt_wait[ table_line = ls-exnum ] ) )
                                      THEN if_abap_behv=>fc-o-enabled
                                      ELSE if_abap_behv=>fc-o-disabled )

        %action-aiRecommend = COND #( WHEN ls-prsta = lcl_c=>prsta-open OR ls-prsta = lcl_c=>prsta-prog
                                      THEN if_abap_behv=>fc-o-enabled
                                      ELSE if_abap_behv=>fc-o-disabled )

        " AI 추천 조회(조치 결정 팝업용): PROG만 (decideAction과 동일)
        %action-getAiRecommend = COND #( WHEN ls-prsta = lcl_c=>prsta-prog
                                         THEN if_abap_behv=>fc-o-enabled
                                         ELSE if_abap_behv=>fc-o-disabled )
        ) ).
  ENDMETHOD.

   METHOD close.
    DATA: lv_held  TYPE abap_bool,
          lv_hdnum TYPE ztexa00030-hdnum.
    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception FIELDS ( prsta srtyp ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).

    LOOP AT lt_exc INTO DATA(ls_exc).
            DATA(lv_memo) = keys[ %tky = ls_exc-%tky ]-%param-memo.

      IF lv_memo IS INITIAL.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no = '020' iv_v1 = '처리 결과 메모' ) )   " ★
          TO reported-exception.
        CONTINUE.
      ENDIF.

      IF ls_exc-prsta <> lcl_c=>prsta-actn.                                                 " ★
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( '036' ) )   " ★
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " INVC: 후속 요청(FI 처리)이 끝나기 전에는 진행 불가 (WAIT 요청 있음)
      IF ls_exc-srtyp = 'INVC'.
        DATA(lv_wrq_c) = wait_req( ls_exc-exnum ).
        IF lv_wrq_c IS NOT INITIAL.
          APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
          APPEND VALUE #( %tky = ls_exc-%tky
                          %msg = msg( iv_no = '327' iv_v1 = lv_wrq_c ) )
            TO reported-exception.
          CONTINUE.
        ENDIF.
      ENDIF.

      " 활성 Payment Hold가 남아 있으면 종료 거부 (원칙② 대칭)
      CLEAR: lv_held, lv_hdnum.
      CALL FUNCTION 'ZCM_HOLD_CHECK'
        EXPORTING
          iv_exnum = ls_exc-exnum
        IMPORTING
          ev_held  = lv_held
          ev_hdnum = lv_hdnum.
      IF lv_held = abap_true.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no = '315' iv_v1 = lv_hdnum ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF zi_exception IN LOCAL MODE
        ENTITY exception UPDATE FIELDS ( prsta aenam aedat aezet )
        WITH VALUE #( ( %tky  = ls_exc-%tky
                        prsta = lcl_c=>prsta-clsd                                           " ★
                        aenam = sy-uname  aedat = sy-datum  aezet = sy-uzeit ) ).
            lcl_hist_buffer=>add( iv_exnum = ls_exc-exnum iv_prres = lcl_c=>prsta-clsd iv_prtxt = lv_memo ).
            lcl_req_buffer=>add_cancel( iv_exnum = ls_exc-exnum iv_prsta = lcl_c=>prsta-clsd ).
    ENDLOOP.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_res).
    result = VALUE #( FOR r IN lt_res ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD reject.
    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception FIELDS ( prsta ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).

    DATA lt_held TYPE SORTED TABLE OF ztexa00030-exnum WITH UNIQUE KEY table_line.
    IF lt_exc IS NOT INITIAL.
      SELECT DISTINCT exnum FROM ztexa00030
        FOR ALL ENTRIES IN @lt_exc
        WHERE exnum = @lt_exc-exnum
          AND hdsta = @lcl_c=>hdsta-actv
        INTO TABLE @lt_held.
    ENDIF.

    LOOP AT lt_exc INTO DATA(ls_exc).
            DATA(lv_memo) = keys[ %tky = ls_exc-%tky ]-%param-memo.

      " 사유 필수
      IF lv_memo IS INITIAL.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no = '020' iv_v1 = '반려 사유' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " 상태 재확인 (버튼 비활성 우회 방지)
      IF ls_exc-prsta <> lcl_c=>prsta-open AND ls_exc-prsta <> lcl_c=>prsta-prog.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( '036' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " 활성 Payment Hold가 남아 있으면 반려 거부 (close와 대칭)
      IF line_exists( lt_held[ table_line = ls_exc-exnum ] ).
        SELECT SINGLE hdnum FROM ztexa00030
          WHERE exnum = @ls_exc-exnum AND hdsta = @lcl_c=>hdsta-actv
          INTO @DATA(lv_rhd).
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no = '315' iv_v1 = lv_rhd ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.


      MODIFY ENTITIES OF zi_exception IN LOCAL MODE
        ENTITY exception UPDATE FIELDS ( prsta aenam aedat aezet )
        WITH VALUE #( ( %tky  = ls_exc-%tky
                        prsta = lcl_c=>prsta-rjct
                        aenam = sy-uname  aedat = sy-datum  aezet = sy-uzeit ) ).
            lcl_hist_buffer=>add( iv_exnum = ls_exc-exnum iv_prres = lcl_c=>prsta-rjct iv_prtxt = lv_memo ).
            lcl_req_buffer=>add_cancel( iv_exnum = ls_exc-exnum iv_prsta = lcl_c=>prsta-rjct ).
    ENDLOOP.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_res).
    result = VALUE #( FOR r IN lt_res ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD decideAction.
    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception FIELDS ( prsta srtyp ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).

    LOOP AT lt_exc INTO DATA(ls_exc).
      DATA(ls_param) = keys[ %tky = ls_exc-%tky ]-%param.

      " ① 조치유형 필수
      IF ls_param-acttp IS INITIAL.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no = '020' iv_v1 = '조치유형' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " ② 처리중(PROG) 건만
      IF ls_exc-prsta <> lcl_c=>prsta-prog.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( '036' ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      " ③ 이 발생출처에 허용된 조치인지 (공통코드 CDDSC = 허용 SRTYP)
      SELECT SINGLE cdnam, cddsc FROM ztcma00080
        WHERE cdgrp = 'ACTTP' AND cdval = @ls_param-acttp
        INTO @DATA(ls_rule).
      IF sy-subrc <> 0 OR ls_rule-cddsc <> ls_exc-srtyp.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no = '318' iv_v1 = ls_exc-srtyp ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF zi_exception IN LOCAL MODE
        ENTITY exception UPDATE FIELDS ( prsta aenam aedat aezet )
        WITH VALUE #( ( %tky  = ls_exc-%tky
                        prsta = lcl_c=>prsta-actn
                        aenam = sy-uname  aedat = sy-datum  aezet = sy-uzeit ) ).

      " 이력: [코드 조치명] 메모
      " (이력 행은 AI 추천 채택 여부까지 계산한 뒤 1행으로 기록 — 아래 참고)
      DATA(lv_dtxt) = |[{ ls_param-acttp } { ls_rule-cdnam }] { ls_param-memo }|.

      " ★ AI 추천 채택/거절 기록
      "   - 커스텀 팝업: 팝업이 넘긴 추천 코드(ai_acttp) 기준
      "   - 표준 팝업(하위 호환): 직전 [AI 추천] 이력 행 기준
      DATA: lv_ai  TYPE ztexa00020-prtxt,
            lv_aic TYPE string.
      CLEAR: lv_ai, lv_aic.
      IF ls_param-ai_acttp IS NOT INITIAL.
        lv_aic = ls_param-ai_acttp.
      ELSE.
        SELECT prtxt FROM ztexa00020
          WHERE exnum = @ls_exc-exnum AND prres = 'AIRC'
          ORDER BY logno DESCENDING
          INTO @lv_ai UP TO 1 ROWS.
        ENDSELECT.
        IF sy-subrc = 0 AND lv_ai CP '[AI 추천]*'.
          lv_aic = condense( substring_after( val = lv_ai sub = '] ' ) ).
        ENDIF.
      ENDIF.
      IF lv_aic IS NOT INITIAL.
        lv_dtxt = lv_dtxt && COND string(
                    WHEN lv_aic = ls_param-acttp
                    THEN | (AI 추천 채택)|
                    ELSE | (AI 추천 { lv_aic } 거절)| ).
      ENDIF.

      " ★ 조치 결정 이력 1행 (후속 요청 번호는 save_modified에서 같은 행 뒤에 덧붙임)
      lcl_hist_buffer=>add( iv_exnum = ls_exc-exnum
                            iv_prres = lcl_c=>prsta-actn
                            iv_prtxt = CONV #( lv_dtxt ) ).

      " ★ 추가: 후속 요청 (실제 INSERT는 save_modified에서)
      lcl_req_buffer=>add( iv_exnum = ls_exc-exnum
                           iv_acttp = ls_param-acttp
                           iv_rqtxt = CONV #( ls_param-memo ) ).
    ENDLOOP.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_res).
    result = VALUE #( FOR r IN lt_res ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD aiRecommend.
    DATA: lv_acttp  TYPE ztcma00080-cdval,
          lv_actnm  TYPE ztcma00080-cdnam,
          lv_reason TYPE string,
          lv_cnt    TYPE i,
          lv_ok     TYPE abap_bool,
          lv_emsg   TYPE string.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).

    LOOP AT lt_exc INTO DATA(ls_exc).
      IF ls_exc-prsta <> lcl_c=>prsta-open AND ls_exc-prsta <> lcl_c=>prsta-prog.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky %msg = msg( '036' ) ) TO reported-exception.
        CONTINUE.
      ENDIF.

      " 소스별 상세 요약 (개인정보 제외)
      DATA(lv_ctx) = SWITCH string( ls_exc-srtyp
        WHEN 'RISK' THEN |지연 { ls_exc-rk_dlday }일, 위험등급 { ls_exc-rk_rkgrd }|
        WHEN 'INVC' THEN |송장-PO 차이금액 { ls_exc-iv_diff }, 대사상태 { ls_exc-iv_mstat }|
        WHEN 'QM'   THEN |검사수량 { ls_exc-qm_insqt }, 불량수량 { ls_exc-qm_faiqt }, 불량유형 { ls_exc-qm_defcd_text }|
        WHEN 'SUBC' THEN |지급차이 { ls_exc-sc_diff_iss }, 사용차이 { ls_exc-sc_diff_use }, 정합성 { ls_exc-sc_rcsts_text }|
        ELSE `` ).

      CLEAR: lv_acttp, lv_actnm, lv_reason, lv_cnt, lv_ok, lv_emsg.
      TRY.
          zcl_cm_ai_recommend=>recommend(
            EXPORTING iv_exnum   = ls_exc-exnum
                      iv_context = lv_ctx
            IMPORTING ev_acttp   = lv_acttp
                      ev_actnm   = lv_actnm
                      ev_reason  = lv_reason
                      ev_cnt     = lv_cnt
                      ev_success = lv_ok
                      ev_message = lv_emsg ).
        CATCH cx_root.
          lv_ok = abap_false.     " 덤프 대신 323 경고(직접 결정)로 처리
      ENDTRY.

      " 실패해도 failed는 채우지 않음 → 경고만, 다른 기능에 영향 없음
      IF lv_ok = abap_false.
        APPEND VALUE #( %tky = ls_exc-%tky
                        %msg = msg( iv_no  = '323'
                                    iv_sev = if_abap_behv_message=>severity-warning ) )
          TO reported-exception.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky = ls_exc-%tky
                      %msg = msg( iv_no  = '321'
                                  iv_v1  = |{ lv_acttp } { lv_actnm }|
                                  iv_v2  = |{ lv_cnt }|
                                  iv_sev = if_abap_behv_message=>severity-information ) )
        TO reported-exception.
      APPEND VALUE #( %tky = ls_exc-%tky
                      %msg = msg( iv_no  = '322'
                                  iv_v1  = substring( val = lv_reason
                                                      len = nmin( val1 = 50 val2 = strlen( lv_reason ) ) )
                                  iv_sev = if_abap_behv_message=>severity-information ) )
        TO reported-exception.

      " 추천 이력 (실제 INSERT는 save_modified)
      lcl_hist_buffer=>add( iv_exnum = ls_exc-exnum
                            iv_prres = 'AIRC'
                            iv_prtxt = |[AI 추천] { lv_acttp }| ).

      " save_modified가 호출되도록 변경정보만 갱신
      MODIFY ENTITIES OF zi_exception IN LOCAL MODE
        ENTITY exception UPDATE FIELDS ( aenam aedat aezet )
        WITH VALUE #( ( %tky  = ls_exc-%tky
                        aenam = sy-uname  aedat = sy-datum  aezet = sy-uzeit ) ).
    ENDLOOP.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_res).
    result = VALUE #( FOR r IN lt_res ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD getAiRecommend.
    " 조치 결정 팝업용: 추천만 계산해 반환 (DB·이력 변경 없음 → etag 영향 없음)
    DATA: lv_acttp  TYPE ztcma00080-cdval,
          lv_actnm  TYPE ztcma00080-cdnam,
          lv_reason TYPE string,
          lv_cnt    TYPE i,
          lv_ok     TYPE abap_bool,
          lv_emsg   TYPE string.

    READ ENTITIES OF zi_exception IN LOCAL MODE
      ENTITY exception ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_exc).

    LOOP AT lt_exc INTO DATA(ls_exc).
      IF ls_exc-prsta <> lcl_c=>prsta-open AND ls_exc-prsta <> lcl_c=>prsta-prog.
        APPEND VALUE #( %tky = ls_exc-%tky ) TO failed-exception.
        APPEND VALUE #( %tky = ls_exc-%tky %msg = msg( '036' ) ) TO reported-exception.
        CONTINUE.
      ENDIF.

      DATA(lv_ctx) = SWITCH string( ls_exc-srtyp
        WHEN 'RISK' THEN |지연 { ls_exc-rk_dlday }일, 위험등급 { ls_exc-rk_rkgrd }|
        WHEN 'INVC' THEN |송장-PO 차이금액 { ls_exc-iv_diff }, 대사상태 { ls_exc-iv_mstat }|
        WHEN 'QM'   THEN |검사수량 { ls_exc-qm_insqt }, 불량수량 { ls_exc-qm_faiqt }, 불량유형 { ls_exc-qm_defcd_text }|
        WHEN 'SUBC' THEN |지급차이 { ls_exc-sc_diff_iss }, 사용차이 { ls_exc-sc_diff_use }, 정합성 { ls_exc-sc_rcsts_text }|
        ELSE `` ).

      CLEAR: lv_acttp, lv_actnm, lv_reason, lv_cnt, lv_ok, lv_emsg.
      zcl_cm_ai_recommend=>recommend(
        EXPORTING iv_exnum   = ls_exc-exnum
                  iv_context = lv_ctx
        IMPORTING ev_acttp   = lv_acttp
                  ev_actnm   = lv_actnm
                  ev_reason  = lv_reason
                  ev_cnt     = lv_cnt
                  ev_success = lv_ok
                  ev_message = lv_emsg ).

      " 실패해도 failed 없이 success = ' ' 로만 알림 (팝업은 직접 선택 모드).
      " lv_emsg는 API 응답 본문이 섞일 수 있어 화면에 내보내지 않고 고정 문구 사용.
      APPEND VALUE #( %tky   = ls_exc-%tky
                      %param = VALUE #(
                        success = COND #( WHEN lv_ok = abap_true THEN 'X' ELSE ' ' )
                        acttp   = lv_acttp
                        actnm   = lv_actnm
                        reason  = lv_reason
                        cnt     = lv_cnt
                        message = COND #( WHEN lv_ok = abap_true THEN ``
                                          ELSE `AI 추천을 불러오지 못했습니다. 직접 조치를 결정하세요.` ) ) )
        TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
