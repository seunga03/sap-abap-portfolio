*&---------------------------------------------------------------------*
*& Report ZRCMA00021
*& [CM02] 납기 리스크 배치 — 납기 지난 미입고 PO Item 스냅샷 + Exception 생성
*&---------------------------------------------------------------------*
REPORT zrcma00021 MESSAGE-ID zmsga.

*--- 선택화면 --------------------------------------------------------*
PARAMETERS: p_date TYPE sy-datum DEFAULT sy-datum OBLIGATORY,   " 기준일
            p_test AS CHECKBOX DEFAULT 'X',                     " 시뮬레이션 (DB 변경 없음)
            p_noti AS CHECKBOX DEFAULT ' '.                     " Exception 알림 발송

CONSTANTS gc_crit_days TYPE i VALUE 5.     " 이 일수 이상 지연이면 Exception 생성

TYPES: BEGIN OF ty_out,
         ebeln  TYPE ztmma00060-ebeln,
         ebelp  TYPE ztmma00060-ebelp,
         eindt  TYPE ztmma00060-eindt,
         menge  TYPE ztmma00060-menge,
         rcvqty TYPE ztmma00060-menge,
         dlday  TYPE i,
         rkgrd  TYPE char4,
         rknum  TYPE ztexa00040-rknum,
         exnum  TYPE ztexa00010-exnum,
         result TYPE char60,
       END OF ty_out.

DATA: gt_out TYPE STANDARD TABLE OF ty_out WITH EMPTY KEY,
      gv_new TYPE i,
      gv_dup TYPE i,
      gv_err TYPE i.

START-OF-SELECTION.

  IF p_test = space AND p_date <> sy-datum.
    MESSAGE '기준일이 오늘이 아니면 실제 실행할 수 없습니다. 시뮬레이션으로 실행하세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " ② 대상: 납기가 지난 PO Item (PO 헤더 조인 안 함)
  SELECT ebeln, ebelp, eindt, menge FROM ztmma00060
    WHERE eindt < @p_date
      AND eindt <> '00000000'                " 납기일 미입력 건 제외
    INTO TABLE @DATA(lt_po).

  " ③ 입고 합계: 입고 FM에 취소 로직이 없어 BWART 101만 합산
  SELECT ebeln, ebelp, SUM( menge ) AS rcvqty FROM ztmma00090
    WHERE bwart = '101'
    GROUP BY ebeln, ebelp
    INTO TABLE @DATA(lt_gr).

  " 기존 납기리스크 스냅샷 (EBELN+EBELP 기준 최신 1건으로 upsert)
  SELECT rknum, ebeln, ebelp, crdat FROM ztexa00040
    INTO TABLE @DATA(lt_rk).
  SORT lt_rk BY ebeln ebelp crdat DESCENDING.

  DATA: lv_grade TYPE char10,
        lv_color TYPE char4,
        lv_exnum TYPE ztexa00010-exnum,
        lv_dup   TYPE abap_bool,
        lt_ret   TYPE bapiret2_t.

  LOOP AT lt_po INTO DATA(ls_po).

    DATA(lv_rcv) = VALUE ztmma00060-menge( lt_gr[ ebeln = ls_po-ebeln
                                                  ebelp = ls_po-ebelp ]-rcvqty OPTIONAL ).
    CHECK lv_rcv < ls_po-menge.                         " 입고 완료 건 제외

    DATA(ls_out) = VALUE ty_out( ebeln  = ls_po-ebeln
                                 ebelp  = ls_po-ebelp
                                 eindt  = ls_po-eindt
                                 menge  = ls_po-menge
                                 rcvqty = lv_rcv ).
    ls_out-dlday = p_date - ls_po-eindt.

    " ④ 등급 (NORMAL/WARNING/CRITICAL → 4자리 NORM/WARN/CRIT)
    CLEAR: lv_grade, lv_color.
    CALL FUNCTION 'ZCM_RISK_GRADE_GET'
      EXPORTING iv_dlday = ls_out-dlday
      IMPORTING ev_grade = lv_grade
                ev_color = lv_color.
    ls_out-rkgrd = lv_grade.

    " ⑤ ZTEXA00040 upsert
    DATA lv_ok TYPE abap_bool.
    lv_ok = abap_true.
    READ TABLE lt_rk INTO DATA(ls_old)
         WITH KEY ebeln = ls_po-ebeln ebelp = ls_po-ebelp.
    IF sy-subrc = 0.
      ls_out-rknum = ls_old-rknum.
      IF p_test = 'X'.
        ls_out-result = '스냅샷 갱신 예정'.
      ELSE.
        UPDATE ztexa00040 SET dlday = @ls_out-dlday, rkgrd = @ls_out-rkgrd,
                              aenam = @sy-uname, aedat = @sy-datum, aezet = @sy-uzeit
          WHERE rknum = @ls_old-rknum.
        IF sy-subrc <> 0.
          lv_ok = abap_false.
        ELSE.
          ls_out-result = '스냅샷 갱신'.
        ENDIF.
      ENDIF.
    ELSE.
      IF p_test = 'X'.
        ls_out-result = '스냅샷 신규 예정'.
      ELSE.
        PERFORM new_rknum CHANGING ls_out-rknum lv_ok.
        IF lv_ok = abap_true.
          PERFORM insert_snapshot USING ls_out CHANGING lv_ok.
        ENDIF.
        IF lv_ok = abap_true.
          ls_out-result = '스냅샷 신규'.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lv_ok = abap_false.                     " 실패 건은 Exception 생성 없이 다음 건으로
      gv_err += 1.
      ls_out-result = '오류: 스냅샷 저장 실패'.
      APPEND ls_out TO gt_out.
      CONTINUE.
    ENDIF.

    " ⑥ CRITICAL만 Exception 생성
    IF ls_out-dlday >= gc_crit_days.
      IF p_test = 'X'.
        ls_out-result = |{ ls_out-result } / Exception 생성 예정|.
      ELSE.
        CLEAR: lv_exnum, lv_dup, lt_ret.
        CALL FUNCTION 'ZCM_EXC_CREATE'
          EXPORTING iv_srtyp  = 'RISK'
                    iv_srnum  = ls_po-ebeln
                    iv_sritm  = ls_po-ebelp
                    iv_owgrp  = 'MM'
                    iv_extyp  = 'PROC'
                    iv_notify = p_noti
          IMPORTING ev_exnum  = lv_exnum
                    ev_dup    = lv_dup
                    et_return = lt_ret.
        ls_out-exnum = lv_exnum.
        IF line_exists( lt_ret[ type = 'E' ] ).
          gv_err = gv_err + 1.
          ls_out-result = |오류: { lt_ret[ type = 'E' ]-message }|.
        ELSEIF lv_dup = abap_true.
          gv_dup = gv_dup + 1.
          ls_out-result = |{ ls_out-result } / Exception 중복|.
        ELSE.
          gv_new = gv_new + 1.
          ls_out-result = |{ ls_out-result } / Exception 신규|.
        ENDIF.
      ENDIF.
    ENDIF.

    APPEND ls_out TO gt_out.
  ENDLOOP.

  " ⑦ 마무리: 시뮬레이션이 아닐 때만 COMMIT WORK 1회 (자동종료는 보류)
  IF p_test = space.
    COMMIT WORK.
    IF gv_err > 0.
      MESSAGE s075 DISPLAY LIKE 'W'.           " 일부 데이터 처리에 실패했습니다.
    ENDIF.
  ENDIF.

  IF gt_out IS INITIAL.
    MESSAGE s041 DISPLAY LIKE 'E'.             " 대상 0건 → 빈 ALV로 넘어가지 않음
    RETURN.
  ENDIF.

  " 결과 ALV
  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_alv)
                              CHANGING  t_table      = gt_out ).
      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->get_display_settings( )->set_list_header(
        COND #( WHEN p_test = 'X'
                THEN |[시뮬레이션] 납기 리스크 배치 - 대상 { lines( gt_out ) }건|
                ELSE |납기 리스크 배치 - 신규 { gv_new } / 중복 { gv_dup } / 오류 { gv_err }| ) ).
            DATA(lo_cols) = lo_alv->get_columns( ).
      lo_cols->set_optimize( abap_true ).
      PERFORM set_col USING lo_cols 'EBELN'  '구매오더'.
      PERFORM set_col USING lo_cols 'EBELP'  '품목'.
      PERFORM set_col USING lo_cols 'EINDT'  '납기일'.
      PERFORM set_col USING lo_cols 'MENGE'  '발주수량'.
      PERFORM set_col USING lo_cols 'RCVQTY' '입고수량'.
      PERFORM set_col USING lo_cols 'DLDAY'  '지연일'.
      PERFORM set_col USING lo_cols 'RKGRD'  '위험등급'.
      PERFORM set_col USING lo_cols 'RKNUM'  '리스크번호'.
      PERFORM set_col USING lo_cols 'EXNUM'  '예외번호'.
      PERFORM set_col USING lo_cols 'RESULT' '처리결과'.

      lo_alv->display( ).
    CATCH cx_salv_msg.
  ENDTRY.

*---------------------------------------------------------------------*
FORM new_rknum CHANGING cv_rknum TYPE ztexa00040-rknum
                        cv_ok    TYPE abap_bool.
  DATA lv_n TYPE n LENGTH 8.
  cv_ok = abap_false.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING nr_range_nr = '01'
              object      = 'ZEX_RKNUM'
    IMPORTING number      = lv_n
    EXCEPTIONS OTHERS     = 1.
  IF sy-subrc <> 0.
    RETURN.                                    " 호출부에서 오류 처리 (잡 취소 방지)
  ENDIF.
  cv_rknum = |RK{ lv_n }|.
  cv_ok = abap_true.
ENDFORM.

FORM insert_snapshot USING    us_out TYPE ty_out
                     CHANGING cv_ok  TYPE abap_bool.
  DATA ls_new TYPE ztexa00040.
  ls_new-rknum = us_out-rknum.
  ls_new-ebeln = us_out-ebeln.
  ls_new-ebelp = us_out-ebelp.
  ls_new-pldat = us_out-eindt.
  ls_new-dlday = us_out-dlday.
  ls_new-rkgrd = us_out-rkgrd.
  ls_new-crdat = sy-datum.
  ls_new-ernam = sy-uname.        " ZSADMIN_1 (SE11 확인 완료)
  ls_new-erdat = sy-datum.
  ls_new-erzet = sy-uzeit.
  INSERT ztexa00040 FROM @ls_new.
  cv_ok = xsdbool( sy-subrc = 0 ).
ENDFORM.

FORM set_col USING io_cols TYPE REF TO cl_salv_columns_table
                   iv_name TYPE lvc_fname
                   iv_text TYPE scrtext_l.
  TRY.
      DATA(lo_col) = io_cols->get_column( iv_name ).
      lo_col->set_long_text( iv_text ).
      lo_col->set_medium_text( CONV scrtext_m( iv_text ) ).
      lo_col->set_short_text( CONV scrtext_s( iv_text ) ).
    CATCH cx_salv_not_found.
  ENDTRY.
ENDFORM.
