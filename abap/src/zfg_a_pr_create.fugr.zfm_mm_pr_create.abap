FUNCTION zfm_mm_pr_create.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IT_PR_REQUEST) TYPE  ZTTMMA00010
*"     REFERENCE(IV_LOCK_HELD) TYPE  ABAP_BOOL OPTIONAL
*"  EXPORTING
*"     REFERENCE(ET_PR_RESULT) TYPE  ZTTMMA00020
*"     REFERENCE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------

  CONSTANTS: lc_fc     TYPE ztmma00040-srtyp VALUE '0010',
             lc_so     TYPE ztmma00040-srtyp VALUE '0020',
             lc_comp   TYPE ztmma00040-srtyp VALUE '0030',
             lc_normal TYPE ztmma00040-ptype VALUE '0010',
             lc_subcon TYPE ztmma00040-ptype VALUE '0020'.

  DATA: ls_req     TYPE zsmma00010,
        ls_result  TYPE zsmma00020,
        ls_return  TYPE bapiret2,
        ls_pr      TYPE ztmma00040,
        ls_old_pr  TYPE ztmma00040,
        ls_short   TYPE ztmma00030,
        ls_reserve TYPE ztmma00150,
        ls_bom     TYPE ztcma00120,
        lv_matnr   TYPE ztmma00040-matnr,
        lv_werks   TYPE ztmma00040-werks,
        lv_lgort   TYPE ztmma00040-lgort,
        lv_meins   TYPE ztmma00040-meins,
        lv_qty     TYPE ztmma00040-rqty,
        lv_ndate   TYPE ztmma00040-ndate,
        lv_banfn   TYPE ztmma00040-banfn,
        lv_bnfpo   TYPE ztmma00040-bnfpo,
        lv_mtart   TYPE ztcma00020-mtart,
        lv_beskz   TYPE ztcma00030-beskz,
        lv_bom_cnt TYPE i,
        lv_error   TYPE abap_bool.

  " SO 공급량 계획: 기존 SO를 먼저 고려, 이번 요청 SO에만 신규 PR 배정
  TYPES: BEGIN OF ty_so_key,
           vbeln TYPE ztmma00150-vbeln,
           posnr TYPE ztmma00150-posnr,
         END OF ty_so_key,
         BEGIN OF ty_so_plan,
           vbeln   TYPE ztmma00150-vbeln,
           posnr   TYPE ztmma00150-posnr,
           new_qty TYPE ztmma00040-rqty,
         END OF ty_so_plan,
         BEGIN OF ty_supply,
           matnr   TYPE ztmma00150-matnr,
           werks   TYPE ztmma00150-werks,
           meins   TYPE ztmma00150-meins,
           balance TYPE ztmma00040-rqty,
         END OF ty_supply.

  DATA: lt_so_requested TYPE HASHED TABLE OF ty_so_key WITH UNIQUE KEY vbeln posnr,
        lt_so_plan      TYPE HASHED TABLE OF ty_so_plan WITH UNIQUE KEY vbeln posnr,
        lt_supply       TYPE HASHED TABLE OF ty_supply WITH UNIQUE KEY matnr werks meins,
        lt_so_all       TYPE STANDARD TABLE OF ztmma00150,
        ls_supply       TYPE ty_supply,
        ls_plan         TYPE ty_so_plan,
        lv_so_demand    TYPE ztmma00040-rqty,     " SO 미충족 수요
        lv_avail        TYPE ztmma00070-stqty,    " 현재 공통 가용재고
        lv_owned_pr     TYPE ztmma00040-rqty,     " 해당 SO에 귀속된 기존 미완료 PR 공급량
        lv_uncovered    TYPE ztmma00040-rqty,     " 기존 조달을 제외하고 남은 수요
        lv_alloc        TYPE ztmma00040-rqty,     " 공통 STQTY에서 배정할 수량
        lv_already      TYPE ztmma00040-banfn,    " 해당 SO의 기존 PR 존재 여부
        lv_reqdt        TYPE ztsda00020-reqdt.

  CLEAR: et_pr_result, et_return.

  " --------------------------------------------------------------
  " 동일 PR 자원의 동시 산출/생성을 차단하는 전체 테이블 논리 잠금.
  " 추가 DDIC 잠금 객체 없이 적용하기 위해 ZTMMA00040 전체를 잠금.
  " 중요: 실제 DB UPDATE/INSERT를 차단하는 락이 아닌 협력적 SAP 잠금.
  " 모든 PR 생성 경로가 같은 FM을 경유해야 동시 실행 방지 효과가 있음.
  " _SCOPE = '1' : 호출 측이 COMMIT/ROLLBACK 후 DEQUEUE_E_TABLE 호출 필수.
  " --------------------------------------------------------------
  IF it_pr_request IS NOT INITIAL AND iv_lock_held <> abap_true.
    CALL FUNCTION 'ENQUEUE_E_TABLE'
      EXPORTING
        mode_rstable   = 'E'
        tabname        = 'ZTMMA00040'
        varkey         = space
        _scope         = '1'
        _wait          = space
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.

    IF sy-subrc <> 0.
      lv_error = abap_true.
      " 호출 측의 건수 일치 검증을 위해 모든 요청에 오류 결과 반환
      LOOP AT it_pr_request INTO ls_req.
        CLEAR: ls_result, ls_return.
        MOVE-CORRESPONDING ls_req TO ls_result.
        ls_result-result = 'ERROR'.
        ls_return-type = 'E'.
        ls_return-message = 'PR 생성 잠금을 획득하지 못했습니다. 다른 처리 종료 후 재시도해 주세요.'.
        APPEND ls_result TO et_pr_result.
        APPEND ls_return TO et_return.
      ENDLOOP.
      RETURN.
    ENDIF.
  ENDIF.

  " --------------------------------------------------------------
  " SO 요청의 배정계획만 미리 산출(INSERT 없음)
  " SO 품목을 오래된 순서로 처리. 기존 SO도 공급을 소비한다고 판단.
  " 실제로 새로운 PR을 만드는 대상은 IT_PR_REQUEST에 포함된 SO뿐.
  " --------------------------------------------------------------
  LOOP AT it_pr_request INTO DATA(ls_so_req)
       WHERE srtyp = lc_so.
    INSERT VALUE ty_so_key( vbeln = ls_so_req-srdoc
                            posnr = ls_so_req-sritm )
      INTO TABLE lt_so_requested.
  ENDLOOP.

  IF lt_so_requested IS NOT INITIAL.

    " 모든 SO를 생성일시 기준으로 조회
    SELECT *
      FROM ztmma00150
      INTO TABLE @lt_so_all.

    SORT lt_so_all BY erdat erzet vbeln posnr.

    LOOP AT lt_so_all INTO DATA(ls_so_row).

      "--------------------------------------------------
      " 자재/플랜트별 공통 가용재고 최초 조회
      "--------------------------------------------------
      READ TABLE lt_supply INTO ls_supply
        WITH TABLE KEY matnr = ls_so_row-matnr
                       werks = ls_so_row-werks
                       meins = ls_so_row-meins.

      IF sy-subrc <> 0.

        CLEAR: ls_supply, lv_avail.

        ls_supply-matnr = ls_so_row-matnr.
        ls_supply-werks = ls_so_row-werks.
        ls_supply-meins = ls_so_row-meins.

        " STQTY는 예약 차감 후 가용재고
        SELECT SUM( stqty )
          FROM ztmma00070
          WHERE matnr = @ls_so_row-matnr
            AND werks = @ls_so_row-werks
          INTO @lv_avail.

        ls_supply-balance = lv_avail.

        INSERT ls_supply INTO TABLE lt_supply.

      ENDIF.

      "--------------------------------------------------
      " SO 미충족 수요 계산
      "--------------------------------------------------
      lv_so_demand = ls_so_row-ordqt
                   - ls_so_row-sumqt
                   - ls_so_row-avlqt.

      IF lv_so_demand < 0.
        lv_so_demand = 0.
      ENDIF.

      "--------------------------------------------------
      " 해당 SO의 기존 조달 공급량 조회
      "--------------------------------------------------
      CLEAR lv_owned_pr.

      SELECT SUM( rqty )
        FROM ztmma00040
        WHERE srtyp = @lc_so
          AND srdoc = @ls_so_row-vbeln
          AND sritm = @ls_so_row-posnr
          AND matnr = @ls_so_row-matnr
          AND werks = @ls_so_row-werks
          AND meins = @ls_so_row-meins
          AND pstat <> '0050'
          AND pstat <> '0090'
        INTO @lv_owned_pr.

      "--------------------------------------------------
      " SO 전용 조달을 먼저 반영
      "--------------------------------------------------
      lv_uncovered = lv_so_demand - lv_owned_pr.

      IF lv_uncovered < 0.
        lv_uncovered = 0.
      ENDIF.

      "--------------------------------------------------
      " 남은 수요에 공통 STQTY FIFO 배정
      "--------------------------------------------------
      CLEAR lv_alloc.

      IF ls_supply-balance > 0
         AND lv_uncovered > 0.

        lv_alloc = lv_uncovered.

        IF lv_alloc > ls_supply-balance.
          lv_alloc = ls_supply-balance.
        ENDIF.

        ls_supply-balance =
          ls_supply-balance - lv_alloc.

        lv_uncovered = lv_uncovered - lv_alloc.

      ENDIF.

      "--------------------------------------------------
      " 이번 FM 호출 대상 SO만 생성계획 작성
      "--------------------------------------------------
      READ TABLE lt_so_requested
        TRANSPORTING NO FIELDS
        WITH TABLE KEY vbeln = ls_so_row-vbeln
                       posnr = ls_so_row-posnr.

      IF sy-subrc = 0.

        CLEAR: ls_plan, lv_already.

        ls_plan-vbeln = ls_so_row-vbeln.
        ls_plan-posnr = ls_so_row-posnr.

        " 취소되지 않은 기존 SO PR 확인
        SELECT SINGLE banfn
          FROM ztmma00040
          WHERE srtyp = @lc_so
            AND srdoc = @ls_so_row-vbeln
            AND sritm = @ls_so_row-posnr
            AND pstat <> '0090'
          INTO @lv_already.

        " 기존 PR이 없는 SO에만 신규 PR 배정
        IF sy-subrc <> 0 AND lv_uncovered > 0.

          ls_plan-new_qty = lv_uncovered.

        ENDIF.

        INSERT ls_plan INTO TABLE lt_so_plan.

      ENDIF.

      "--------------------------------------------------
      " FIFO 배정 후 공통 재고 잔량 저장
      "--------------------------------------------------
      MODIFY TABLE lt_supply FROM ls_supply.

    ENDLOOP.

  ENDIF.


  LOOP AT it_pr_request INTO ls_req.

    CLEAR: ls_result, ls_return, ls_pr,
         ls_old_pr, ls_short, ls_reserve,
         ls_bom, lv_matnr, lv_werks,
         lv_lgort, lv_meins, lv_qty,
         lv_ndate, lv_banfn, lv_bnfpo,
         lv_mtart, lv_beskz, lv_bom_cnt,
         lv_reqdt, lv_error.

    MOVE-CORRESPONDING ls_req TO ls_result.

    "----------------------------------------------
    " 요청값 검증
    "----------------------------------------------
    IF ls_req-srtyp <> lc_fc AND ls_req-srtyp <> lc_so AND ls_req-srtyp <> lc_comp.

      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = '올바르지 않은 PR 생성 출처입니다.'.

    ELSEIF ls_req-srdoc IS INITIAL.

      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = '원본문서번호가 없습니다.'.

    ELSEIF ls_req-srtyp = lc_so
       AND ls_req-sritm IS INITIAL.

      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = 'SO 품목번호가 없습니다.'.

    ENDIF.

    IF ls_result-result = 'ERROR'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.
    ENDIF.

    "----------------------------------------------
    " Forecast / SO 출처별 수요 조회
    "----------------------------------------------
    CASE ls_req-srtyp.

*      WHEN lc_fc.
*
*        SELECT SINGLE *
*          FROM ztmma00030
*         WHERE srtno = @ls_req-srdoc
*          INTO @ls_short.
*
*        IF sy-subrc <> 0.
*          lv_error = abap_true.
*          ls_return-message = '부족량 산출 결과가 없습니다.'.
*        ELSE.
*          lv_matnr = ls_short-matnr.
*          lv_werks = ls_short-werks.
*          lv_meins = ls_short-meins.
*          lv_qty   = ls_short-shiqty.
*        ENDIF.


      WHEN lc_fc OR lc_comp.

        SELECT SINGLE *
          FROM ztmma00030
         WHERE srtno = @ls_req-srdoc
          INTO @ls_short.

        IF sy-subrc <> 0.

          lv_error = abap_true.
          ls_return-message = '부족량 산출 결과가 없습니다.'.

        ELSEIF ( ls_req-srtyp = lc_fc AND ls_short-reqtyp <> '0010' )
            OR ( ls_req-srtyp = lc_comp AND ls_short-reqtyp <> '0020' ).

          lv_error = abap_true.
          ls_return-message = 'PR 생성 출처와 부족량 유형이 일치하지 않습니다.'.

        ELSEIF ls_short-pstat <> '0010' OR ls_short-banfn IS NOT INITIAL.

          lv_error = abap_true.
          ls_return-message = '이미 처리된 부족량으로 신규 PR을 생성할 수 없습니다.'.

        ELSE.

          lv_matnr = ls_short-matnr.
          lv_werks = ls_short-werks.
          lv_meins = ls_short-meins.
          lv_qty   = ls_short-shiqty.

        ENDIF.


      WHEN lc_so.

        " 요청된 SO 품목의 현재 예약정보
        SELECT SINGLE *
          FROM ztmma00150
         WHERE vbeln = @ls_req-srdoc
           AND posnr = @ls_req-sritm
          INTO @ls_reserve.

        IF sy-subrc <> 0.
          lv_error = abap_true.
          ls_return-message = 'SO 예약정보가 없습니다.'.
        ELSEIF ls_reserve-matnr IS INITIAL
            OR ls_reserve-werks IS INITIAL
            OR ls_reserve-meins IS INITIAL
            OR ls_reserve-ordqt < 0
            OR ls_reserve-sumqt < 0
            OR ls_reserve-avlqt < 0
            OR ls_reserve-sumqt + ls_reserve-avlqt > ls_reserve-ordqt.
          lv_error = abap_true.
          ls_return-message = 'SO 예약정보의 자재/수량이 올바르지 않습니다.'.
        ELSE.
          lv_matnr = ls_reserve-matnr.
          lv_werks = ls_reserve-werks.
          lv_lgort = ls_reserve-lgort.
          lv_meins = ls_reserve-meins.

          " SO 품목 요청납기일 조회
          SELECT SINGLE reqdt
            FROM ztsda00020
           WHERE vbeln = @ls_req-srdoc
             AND posnr = @ls_req-sritm
            INTO @lv_reqdt.

          IF sy-subrc <> 0 OR lv_reqdt IS INITIAL.
            lv_error = abap_true.
            ls_return-message = 'SO 요청납기일을 확인할 수 없습니다.'.
          ENDIF.

          " 기존 SO를 먼저 고려한 공급 차감 결과(사전 계산)
          READ TABLE lt_so_plan INTO DATA(ls_so_plan)
            WITH TABLE KEY vbeln = ls_req-srdoc
                           posnr = ls_req-sritm.
          IF sy-subrc <> 0.
            lv_error = abap_true.
            ls_return-message = 'SO 부족수량 사전 계산에 실패했습니다.'.
          ELSE.
            lv_qty = ls_so_plan-new_qty.
          ENDIF.
        ENDIF.
    ENDCASE.

    IF lv_error = abap_true.
      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.
    ENDIF.

    ls_result-matnr = lv_matnr.
    ls_result-meins = lv_meins.

    " 비활성/취소된 Forecast의 부족량으로 신규 PR 생성 금지
    IF ls_req-srtyp = lc_fc.
      SELECT SINGLE fcsno FROM ztmma00010
        WHERE fcsno = @ls_short-fcsno
          AND cstat = '0020'
          AND activ = @abap_true
        INTO @DATA(lv_active_fcsno).
      IF sy-subrc <> 0 OR ls_short-pstat <> '0010'.
        ls_result-result = 'SKIPPED'.
        ls_return-type = 'W'.
        ls_return-message = '비활성 Forecast 또는 처리 불가 부족량입니다.'.
        APPEND ls_result TO et_pr_result.
        APPEND ls_return TO et_return.
        CONTINUE.
      ENDIF.
    ENDIF.

    "----------------------------------------------
    " 기존 동일 원본문서 PR 확인
    "----------------------------------------------
    IF ls_req-srtyp = lc_so.

      " SO PR: 취소된 PR은 중복 검사에서 제외
      SELECT SINGLE *
        FROM ztmma00040
       WHERE srtyp = @ls_req-srtyp
         AND srdoc = @ls_req-srdoc
         AND sritm = @ls_req-sritm
         AND pstat <> '0090'
        INTO @ls_old_pr.

    ELSE.

      " Forecast / 지급자재: 기존 중복 방지 정책 유지
      SELECT SINGLE *
        FROM ztmma00040
       WHERE srtyp = @ls_req-srtyp
         AND srdoc = @ls_req-srdoc
         AND sritm = @ls_req-sritm
        INTO @ls_old_pr.

    ENDIF.

    IF sy-subrc = 0.

      ls_result-banfn  = ls_old_pr-banfn.
      ls_result-bnfpo  = ls_old_pr-bnfpo.
      ls_result-matnr  = ls_old_pr-matnr.
      ls_result-rqty   = ls_old_pr-rqty.
      ls_result-meins  = ls_old_pr-meins.
      ls_result-result = 'EXISTING'.

      ls_return-type = 'W'.
      ls_return-message = '기존 PR이 존재하여 신규 생성을 보류했습니다.'.

      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.

    ENDIF.

    "----------------------------------------------
    " 신규 조달 필요수량 검사
    "----------------------------------------------
    IF lv_qty <= 0.

      ls_result-result = 'SKIPPED'.
      ls_return-type = 'S'.
      ls_return-message = '추가 조달 필요수량이 없어 PR을 생성하지 않았습니다.'.

      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.

    ENDIF.

    "----------------------------------------------
    " 자재 및 조달유형 확인
    "----------------------------------------------
    SELECT SINGLE mtart
      FROM ztcma00020
     WHERE matnr = @lv_matnr
      INTO @lv_mtart.

    IF sy-subrc <> 0.
      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = '자재 마스터가 존재하지 않습니다.'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.
    ENDIF.

    SELECT SINGLE beskz
      FROM ztcma00030
     WHERE matnr = @lv_matnr
       AND werks = @lv_werks
       AND actyn = 'Y'
      INTO @lv_beskz.

    IF sy-subrc <> 0.
      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = '자재 플랜트 관리정보가 없습니다.'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.
    ENDIF.

    " 조달 대상 여부
    IF lv_beskz = space.
      ls_result-result = 'SKIPPED'.
      ls_return-type = 'W'.
      ls_return-message = '조달하지 않는 자재입니다.'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.
    ENDIF.

    " 외주 판단: 사용 가능한 BOM 존재 여부
    SELECT COUNT( * )
      FROM ztcma00120
     WHERE matnr    = @lv_matnr
       AND werks    = @lv_werks
       AND stlst    = '01'
       AND datuv   <= @sy-datum
       AND valid_to >= @sy-datum
      INTO @lv_bom_cnt.

    IF lv_bom_cnt > 1.
      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = '유효 BOM이 중복됩니다.'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.
    ENDIF.

*    IF lv_bom_cnt = 1.
*      ls_pr-ptype = lc_subcon.
*    ELSEIF lv_mtart = 'FERT'.
*      " 프로젝트 정책: FG는 외주 조달
*      ls_result-result = 'ERROR'.
*      ls_return-type = 'E'.
*      ls_return-message = '완제품의 유효 외주 BOM이 없습니다.'.
*      APPEND ls_result TO et_pr_result.
*      APPEND ls_return TO et_return.
*      CONTINUE.
*    ELSEIF lv_beskz = 'F'.
*      ls_pr-ptype = lc_normal.
*    ELSE.
*      ls_result-result = 'ERROR'.
*      ls_return-type = 'E'.
*      ls_return-message = '자재의 구매유형을 결정할 수 없습니다.'.
*      APPEND ls_result TO et_pr_result.
*      APPEND ls_return TO et_return.
*      CONTINUE.
*    ENDIF.


    " 지급자재 부족분은 BOM 존재 여부와 관계없이 일반 PR
    IF ls_req-srtyp = lc_comp.

      IF lv_beskz = 'F'.
        ls_pr-ptype = lc_normal.
      ELSE.
        ls_result-result = 'ERROR'.
        ls_return-type = 'E'.
        ls_return-message = '지급자재의 외부 구매유형을 확인해 주세요.'.
        APPEND ls_result TO et_pr_result.
        APPEND ls_return TO et_return.
        CONTINUE.
      ENDIF.

    ELSEIF lv_bom_cnt = 1.

      ls_pr-ptype = lc_subcon.

    ELSEIF lv_mtart = 'FERT'.

      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = '완제품의 유효 외주 BOM이 없습니다.'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.

    ELSEIF lv_beskz = 'F'.

      ls_pr-ptype = lc_normal.

    ELSE.

      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = '자재의 구매유형을 결정할 수 없습니다.'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.

    ENDIF.


    "----------------------------------------------
    " PR 번호 채번
    "----------------------------------------------
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr = '01'
        object      = 'ZMM_BANFN'
      IMPORTING
        number      = lv_banfn
      EXCEPTIONS
        OTHERS      = 1.

    IF sy-subrc <> 0 OR lv_banfn IS INITIAL.
      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = 'PR 번호 채번에 실패했습니다.'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.
    ENDIF.

    lv_bnfpo = '00010'.

    "----------------------------------------------
    " PR 생성 데이터 구성
    "----------------------------------------------
    ls_pr-mandt = sy-mandt.
    ls_pr-banfn = lv_banfn.
    ls_pr-bnfpo = lv_bnfpo.

    ls_pr-matnr = lv_matnr.
    ls_pr-werks = lv_werks.
    ls_pr-lgort = lv_lgort.

    ls_pr-prtyp = '0010'.  " 일반 요청
    ls_pr-srtyp = ls_req-srtyp.
    ls_pr-srdoc = ls_req-srdoc.
    ls_pr-sritm = ls_req-sritm.

    ls_pr-ruser = sy-uname.
    ls_pr-rdate = sy-datum.
    ls_pr-rqty  = lv_qty.
    ls_pr-meins = lv_meins.

    IF ls_req-srtyp = lc_so.
      ls_pr-ndate = lv_reqdt.
    ELSE.
      ls_pr-ndate = sy-datum.
    ENDIF.

    " 필요일은 출처별 확정 정책 연결 전 임시값
*    ls_pr-ndate = sy-datum.

    ls_pr-astat = '0020'.
    ls_pr-pstat = '0030'.

    ls_pr-ernam = sy-uname.
    ls_pr-erdat = sy-datum.
    ls_pr-erzet = sy-uzeit.

    "----------------------------------------------
    " PR DB INSERT
    "----------------------------------------------
    TRY.

        INSERT ztmma00040 FROM @ls_pr.

        IF sy-subrc <> 0.
          lv_error = abap_true.
        ENDIF.

      CATCH cx_sy_open_sql_db.
        lv_error = abap_true.

    ENDTRY.

    IF lv_error = abap_true.
      ls_result-result = 'ERROR'.
      ls_return-type = 'E'.
      ls_return-message = 'PR DB 저장에 실패했습니다.'.
      APPEND ls_result TO et_pr_result.
      APPEND ls_return TO et_return.
      CONTINUE.
    ENDIF.

    "----------------------------------------------
    " Forecast 부족량과 PR 연결
    "----------------------------------------------
*    IF ls_req-srtyp = lc_fc.
*
*      UPDATE ztmma00030
*         SET banfn = @lv_banfn,
*             bnfpo = @lv_bnfpo,
*             pstat = '0020'
*       WHERE srtno = @ls_req-srdoc
*         AND pstat = '0010'
*         AND banfn = @space.
*
*      IF sy-dbcnt <> 1.
*        ls_result-result = 'ERROR'.
*        ls_return-type = 'E'.
*        ls_return-message = 'Forecast 부족량의 PR 연결 갱신에 실패했습니다.'.
*        APPEND ls_result TO et_pr_result.
*        APPEND ls_return TO et_return.
*        CONTINUE.
*      ENDIF.
*
*    ENDIF.


    IF ls_req-srtyp = lc_fc OR ls_req-srtyp = lc_comp.

      UPDATE ztmma00030
         SET banfn = @lv_banfn,
             bnfpo = @lv_bnfpo,
             pstat = '0020'
       WHERE srtno  = @ls_req-srdoc
         AND reqtyp = @ls_short-reqtyp
         AND pstat  = '0010'
         AND banfn  = @space
         AND shiqty > 0.

      IF sy-subrc <> 0 OR sy-dbcnt <> 1.
        ls_result-result = 'ERROR'.
        ls_return-type = 'E'.
        ls_return-message = '부족량과 PR 연결 갱신에 실패했습니다.'.
        APPEND ls_result TO et_pr_result.
        APPEND ls_return TO et_return.
        CONTINUE.
      ENDIF.

    ENDIF.


    "----------------------------------------------
    " 성공 결과 반환
    "----------------------------------------------
    ls_result-banfn  = lv_banfn.
    ls_result-bnfpo  = lv_bnfpo.
    ls_result-rqty   = lv_qty.
    ls_result-result = 'CREATED'.

    ls_return-type = 'S'.
    ls_return-message = 'PR이 생성되었습니다.'.

    APPEND ls_result TO et_pr_result.
    APPEND ls_return TO et_return.

  ENDLOOP.

  " COMMIT WORK / ROLLBACK WORK는 호출 측 책임.
  " 호출 측에서 COMMIT/ROLLBACK 후 반드시 다음 잠금을 해제할 것:
  "   CALL FUNCTION 'DEQUEUE_E_TABLE'
  "     EXPORTING tabname = 'ZTMMA00040'
  "               varkey  = space
  "               _scope  = '1'.

ENDFUNCTION.
