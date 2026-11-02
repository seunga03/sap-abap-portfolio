*&---------------------------------------------------------------------*
*& Form zz_get_so_stock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_so_stock USING VALUE(pt_move_item) TYPE zttmma00090
                  CHANGING pt_so_stock         TYPE zttmma00150.

  DELETE pt_move_item WHERE bwart <> '322'
                         AND bwart <> '651'
                         AND bwart <> '652'.

  DELETE pt_move_item WHERE vbeln_so IS INITIAL.
*                         OR posnr    IS INITIAL.

  SORT pt_move_item BY vbeln_so posnr.
  DELETE ADJACENT DUPLICATES FROM pt_move_item COMPARING vbeln_so posnr.

  IF pt_move_item IS NOT INITIAL.
    SELECT vbeln, posnr, matnr, werks, lgort,
           ordqt, avlqt, sumqt, meins, ernam,
           erdat, erzet, aenam, aedat, aezet
      FROM ztmma00150
      FOR ALL ENTRIES IN @pt_move_item
      WHERE vbeln = @pt_move_item-vbeln_so
        AND posnr = @pt_move_item-posnr
      INTO CORRESPONDING FIELDS OF TABLE @pt_so_stock.
  ENDIF.
ENDFORM.

**--------------------------------------------------------------------*
** BOM 전체 키를 먼저 수집한다. 계산 재귀에서는 SELECT하지 않는다.
**--------------------------------------------------------------------*
*FORM zz_bom_read_data
*  USING    it_root        TYPE zttmma00061
*  CHANGING ct_bom_head    TYPE zttcma00120
*           ct_bom_item    TYPE zttcma00130
*           ct_stock       TYPE zttmma00070
*           ct_stock_total TYPE zttmma00071
*           ct_condition   TYPE zttcma00040
*           ct_return      TYPE ty_bom_return.
*
*  TYPES: BEGIN OF ty_key,
*           matnr TYPE matnr,
*           werks TYPE werks_d,
*         END OF ty_key,
*         BEGIN OF ty_bom_key,
*           stlnr TYPE ztcma00120-stlnr,
*         END OF ty_bom_key.
*
*  DATA: lt_scan       TYPE SORTED TABLE OF ty_key
*                       WITH UNIQUE KEY matnr werks,
*        lt_next       LIKE lt_scan,
*        lt_all        LIKE lt_scan,
*        lt_bom_seen   TYPE SORTED TABLE OF ty_bom_key
*                       WITH UNIQUE KEY stlnr,
*        lt_bom_new    LIKE lt_bom_seen,
*        lt_head_batch TYPE zttcma00120,
*        lt_item_batch TYPE zttcma00130.
*
*  CLEAR: ct_bom_head, ct_bom_item, ct_stock,
*         ct_stock_total, ct_condition.
*
*  IF it_root IS INITIAL.
*    RETURN.
*  ENDIF.
*
** 동일 PO 품목을 다시 실행해 기존 예약과 PR을 중복 생성하지 않는다.
*  SELECT *
*    FROM ztmma00160
*    INTO TABLE @DATA(lt_existing)
*    FOR ALL ENTRIES IN @it_root
*    WHERE ebeln = @it_root-ebeln
*      AND ebelp = @it_root-ebelp.
*
*  IF lt_existing IS NOT INITIAL.
*    APPEND VALUE #( type = 'E'
*      message = '이미 BOM 예약정보가 있는 PO 품목입니다. 중복 실행할 수 없습니다.' )
*      TO ct_return.
*    RETURN.
*  ENDIF.
*
*  LOOP AT it_root ASSIGNING FIELD-SYMBOL(<ls_root>).
*    INSERT VALUE #( matnr = <ls_root>-matnr
*                    werks = <ls_root>-werks ) INTO TABLE lt_scan.
*  ENDLOOP.
*
** 조회 단계에서만 계층별 일괄 조회한다. 방문한 자재와 BOM은 다시 조회하지 않는다.
*  WHILE lt_scan IS NOT INITIAL.
*    INSERT LINES OF lt_scan INTO TABLE lt_all.
*    CLEAR: lt_next, lt_bom_new, lt_head_batch, lt_item_batch.
*
*    SELECT *
*      FROM ztcma00120
*      INTO CORRESPONDING FIELDS OF TABLE @lt_head_batch
*      FOR ALL ENTRIES IN @lt_scan
*      WHERE matnr = @lt_scan-matnr
*        AND werks = @lt_scan-werks
*        AND stlst = '01'.
*
*    APPEND LINES OF lt_head_batch TO ct_bom_head.
*
*    LOOP AT lt_head_batch ASSIGNING FIELD-SYMBOL(<ls_head>).
*      READ TABLE lt_bom_seen WITH TABLE KEY stlnr = <ls_head>-stlnr
*        TRANSPORTING NO FIELDS.
*      IF sy-subrc <> 0.
*        INSERT VALUE #( stlnr = <ls_head>-stlnr ) INTO TABLE lt_bom_new.
*        INSERT VALUE #( stlnr = <ls_head>-stlnr ) INTO TABLE lt_bom_seen.
*      ENDIF.
*    ENDLOOP.
*
*    IF lt_bom_new IS NOT INITIAL.
*      SELECT *
*        FROM ztcma00130
*        INTO CORRESPONDING FIELDS OF TABLE @lt_item_batch
*        FOR ALL ENTRIES IN @lt_bom_new
*        WHERE stlnr = @lt_bom_new-stlnr.
*      APPEND LINES OF lt_item_batch TO ct_bom_item.
*    ENDIF.
*
*    LOOP AT lt_head_batch ASSIGNING <ls_head>.
*      LOOP AT ct_bom_item ASSIGNING FIELD-SYMBOL(<ls_bom_item>)
*        WHERE stlnr = <ls_head>-stlnr.
*
*        READ TABLE lt_all WITH TABLE KEY
*          matnr = <ls_bom_item>-idnrk
*          werks = <ls_head>-werks
*          TRANSPORTING NO FIELDS.
*        IF sy-subrc <> 0.
*          INSERT VALUE #( matnr = <ls_bom_item>-idnrk
*                          werks = <ls_head>-werks ) INTO TABLE lt_next.
*        ENDIF.
*      ENDLOOP.
*    ENDLOOP.
*
*    lt_scan = lt_next.
*  ENDWHILE.
*
*  SORT ct_bom_head BY matnr werks stlnr.
*  SORT ct_bom_item BY stlnr idnrk.
*
** 활성 BOM이 여러 개면 임의의 첫 BOM으로 발주하지 않는다.
*  DATA(lt_unique_head) = ct_bom_head.
*  DELETE ADJACENT DUPLICATES FROM lt_unique_head COMPARING matnr werks.
*  IF lines( lt_unique_head ) <> lines( ct_bom_head ).
*    APPEND VALUE #( type = 'E'
*      message = '같은 자재와 플랜트에 활성 BOM이 여러 개입니다. 선택 기준이 필요합니다.' )
*      TO ct_return.
*    RETURN.
*  ENDIF.
*
*  IF lt_all IS NOT INITIAL.
*    SELECT *
*      FROM ztmma00070
*      INTO CORRESPONDING FIELDS OF TABLE @ct_stock
*      FOR ALL ENTRIES IN @lt_all
*      WHERE matnr = @lt_all-matnr
*        AND werks = @lt_all-werks.
*
*    SELECT *
*      FROM ztcma00040
*      INTO CORRESPONDING FIELDS OF TABLE @ct_condition
*      FOR ALL ENTRIES IN @lt_all
*      WHERE matnr = @lt_all-matnr
*        AND actyn = 'Y'
*        AND valfr <= @sy-datum
*        AND valto >= @sy-datum.
*  ENDIF.
*
*  SORT ct_stock BY matnr werks lgort.
*  LOOP AT ct_stock ASSIGNING FIELD-SYMBOL(<ls_stock>).
*    READ TABLE ct_stock_total ASSIGNING FIELD-SYMBOL(<ls_total>)
*      WITH KEY matnr = <ls_stock>-matnr werks = <ls_stock>-werks.
*    IF sy-subrc = 0.
*      <ls_total>-stqty += <ls_stock>-stqty.
*    ELSE.
*      APPEND VALUE #( matnr = <ls_stock>-matnr
*                      werks = <ls_stock>-werks
*                      stqty = <ls_stock>-stqty ) TO ct_stock_total.
*    ENDIF.
*  ENDLOOP.
*
*ENDFORM.

*--------------------------------------------------------------------*
* 공급업체 선정 정책. 향후 선정 기준 변경은 이 FORM에서 처리한다.
*--------------------------------------------------------------------*
*FORM zz_bom_select_vendor CHANGING ct_condition TYPE zttcma00040.
*
** 현재 정책: 우선순위, 업체번호 순 첫 조건. 같은 업체는 최신 유효시작일 우선.
*  SORT ct_condition BY matnr priok lifnr valfr DESCENDING.
*  DELETE ADJACENT DUPLICATES FROM ct_condition COMPARING matnr.
*
** 계산과 PO 생성은 이 동일한 선정 결과를 사용한다.
*ENDFORM.

*--------------------------------------------------------------------*
* 순환 BOM을 저장 전에 검출한다. 다른 분기에서 자재가 반복되는 것은 허용한다.
*--------------------------------------------------------------------*
*FORM zz_bom_check_path
*  USING    iv_matnr    TYPE matnr
*           iv_werks    TYPE werks_d
*           it_head     TYPE zttcma00120
*           it_item     TYPE zttcma00130
*           it_path     TYPE zttmma00061
*  CHANGING ct_return   TYPE ty_bom_return.
*
*  READ TABLE it_path WITH KEY matnr = iv_matnr werks = iv_werks
*    TRANSPORTING NO FIELDS.
*  IF sy-subrc = 0.
*    APPEND VALUE #( type = 'E'
*      message = |순환 BOM이 있습니다: { iv_matnr } / { iv_werks }| )
*      TO ct_return.
*    RETURN.
*  ENDIF.
*
*  READ TABLE it_head ASSIGNING FIELD-SYMBOL(<ls_head>)
*    WITH KEY matnr = iv_matnr werks = iv_werks BINARY SEARCH.
*  IF sy-subrc <> 0.
*    RETURN.
*  ENDIF.
*
*  DATA(lt_path) = it_path.
*  APPEND VALUE #( matnr = iv_matnr werks = iv_werks ) TO lt_path.
*
*  LOOP AT it_item ASSIGNING FIELD-SYMBOL(<ls_item>)
*    WHERE stlnr = <ls_head>-stlnr.
*    PERFORM zz_bom_check_path
*      USING <ls_item>-idnrk iv_werks it_head it_item lt_path
*      CHANGING ct_return.
*    IF line_exists( ct_return[ type = 'E' ] ).
*      RETURN.
*    ENDIF.
*  ENDLOOP.
*
*ENDFORM.

*--------------------------------------------------------------------*
* 같은 부모 PO 품목에서 반복 사용한 자재를 합친다.
* 동일 창고 예약행은 합산하고 동일 부족자재는 PR 한 품목으로 합친다.
**--------------------------------------------------------------------*
*FORM zz_bom_merge_result
*  CHANGING ct_pr      TYPE zttmma00040
*           ct_reserve TYPE zttmma00160
*           ct_return  TYPE ty_bom_return.
*
*  DATA(lt_pr) = ct_pr.
*  DATA(lt_reserve) = ct_reserve.
*  CLEAR: ct_pr, ct_reserve.
*
*  LOOP AT lt_reserve ASSIGNING FIELD-SYMBOL(<ls_source>).
*    READ TABLE ct_reserve ASSIGNING FIELD-SYMBOL(<ls_target>)
*      WITH KEY ebeln = <ls_source>-ebeln
*               ebelp = <ls_source>-ebelp
*               matnr = <ls_source>-matnr
*               werks = <ls_source>-werks
*               lgort = <ls_source>-lgort.
*
*    IF sy-subrc = 0.
*      <ls_target>-reqty += <ls_source>-reqty.
*      <ls_target>-rsqty += <ls_source>-rsqty.
*
*      IF <ls_source>-banfn IS NOT INITIAL.
*        READ TABLE ct_pr ASSIGNING FIELD-SYMBOL(<ls_pr>)
*          WITH KEY banfn = <ls_target>-banfn bnfpo = <ls_target>-bnfpo.
*        IF sy-subrc <> 0.
*          APPEND VALUE #( type = 'E'
*            message = '합산할 구매요청 품목을 찾을 수 없습니다.' ) TO ct_return.
*          RETURN.
*        ENDIF.
*        <ls_pr>-rqty += <ls_source>-reqty.
*      ENDIF.
*    ELSE.
*      APPEND <ls_source> TO ct_reserve.
*      IF <ls_source>-banfn IS NOT INITIAL.
*        READ TABLE lt_pr ASSIGNING FIELD-SYMBOL(<ls_source_pr>)
*          WITH KEY banfn = <ls_source>-banfn bnfpo = <ls_source>-bnfpo.
*        IF sy-subrc <> 0.
*          APPEND VALUE #( type = 'E'
*            message = '예약 추적정보에 연결된 구매요청이 없습니다.' ) TO ct_return.
*          RETURN.
*        ENDIF.
*        APPEND <ls_source_pr> TO ct_pr.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.
*
*ENDFORM.

*--------------------------------------------------------------------*
* 선정된 거래조건과 부모 PO 구매그룹으로 기존 PO 생성 FM 입력을 구성한다.
*--------------------------------------------------------------------*
*FORM zz_bom_build_po_input
*  USING    it_pr        TYPE zttmma00040
*           it_reserve   TYPE zttmma00160
*           it_head      TYPE zttmma00050
*           it_condition TYPE zttcma00040
*  CHANGING ct_candidate TYPE zttmma00044
*           ct_return    TYPE ty_bom_return.
*
*  CLEAR ct_candidate.
*
*  LOOP AT it_pr ASSIGNING FIELD-SYMBOL(<ls_pr>).
*    READ TABLE it_condition ASSIGNING FIELD-SYMBOL(<ls_condition>)
*      WITH KEY matnr = <ls_pr>-matnr BINARY SEARCH.
*    IF sy-subrc <> 0.
*      APPEND VALUE #( type = 'E'
*        message = |유효한 공급업체 조건이 없습니다: { <ls_pr>-matnr }| )
*        TO ct_return.
*      RETURN.
*    ENDIF.
*
** 단위환산 없이 서로 다른 단위의 수량과 단가를 조합하지 않는다.
*    IF <ls_condition>-meins <> <ls_pr>-meins.
*      APPEND VALUE #( type = 'E'
*        message = |거래조건 단위와 PR 단위가 다릅니다: { <ls_pr>-matnr }| )
*        TO ct_return.
*      RETURN.
*    ENDIF.
*
*    READ TABLE it_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>)
*      WITH KEY banfn = <ls_pr>-banfn bnfpo = <ls_pr>-bnfpo.
*    IF sy-subrc <> 0.
*      APPEND VALUE #( type = 'E'
*        message = '생성 구매요청의 부모 PO 연결정보가 없습니다.' ) TO ct_return.
*      RETURN.
*    ENDIF.
*
*    READ TABLE it_head ASSIGNING FIELD-SYMBOL(<ls_head>)
*      WITH KEY ebeln = <ls_reserve>-ebeln BINARY SEARCH.
*    IF sy-subrc <> 0.
*      APPEND VALUE #( type = 'E'
*        message = '부모 외주 PO 헤더를 찾을 수 없습니다.' ) TO ct_return.
*      RETURN.
*    ENDIF.
*
*    APPEND VALUE #(
*      lifnr = <ls_condition>-lifnr
*      ekgrp = <ls_head>-ekgrp
*      matnr = <ls_pr>-matnr
*      werks = <ls_pr>-werks
*      lgort = <ls_pr>-lgort
*      rqty  = <ls_pr>-rqty
*      meins = <ls_pr>-meins
*      netpr = <ls_condition>-netpr
*      waers = <ls_condition>-waers
*      plifz = <ls_condition>-plifz
*      banfn = <ls_pr>-banfn
*      bnfpo = <ls_pr>-bnfpo
*      ptype = <ls_pr>-ptype
*    ) TO ct_candidate.
*  ENDLOOP.
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_po_stock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_PO_STOCK
*&---------------------------------------------------------------------*
FORM zz_get_po_stock
  USING    pt_po_stock    TYPE zttmma00090
  CHANGING pt_160         TYPE zttmma00160
           pt_parent_lock TYPE zttmma00050
           pv_lock        TYPE abap_bool.

  DATA(lt_key) = pt_po_stock.
  CLEAR pt_160.
  "653은 생성 직후 확보, 654는 검사 후 확보이며 두 경로 모두 지급을 판정한다.
  DELETE lt_key WHERE bwart <> '653' AND bwart <> '654'.
  DELETE lt_key WHERE ebeln IS INITIAL OR ebelp IS INITIAL.
  SORT lt_key BY ebeln ebelp.
  DELETE ADJACENT DUPLICATES FROM lt_key COMPARING ebeln ebelp.
  IF lt_key IS INITIAL.
    RETURN.
  ENDIF.

  "현재 처리한 하위 PO에서 부모 PO를 먼저 찾는다.
  SELECT * FROM ztmma00160
    FOR ALL ENTRIES IN @lt_key
    WHERE ebeln = @lt_key-ebeln AND ebelp = @lt_key-ebelp
    INTO TABLE @DATA(lt_link).
  DELETE lt_link WHERE c_ebeln IS INITIAL.
  SORT lt_link BY c_ebeln.
  DELETE ADJACENT DUPLICATES FROM lt_link COMPARING c_ebeln.
  IF lt_link IS INITIAL.
    RETURN.
  ENDIF.
  LOOP AT lt_link ASSIGNING FIELD-SYMBOL(<ls_link>).

    CALL FUNCTION 'ENQUEUE_EZ_PO_STOCK_ALL'
      EXPORTING
        mode_ztmma00050 = 'E'
        mandt           = sy-mandt
        ebeln           = <ls_link>-c_ebeln
        _scope          = '1'
        _wait           = ' '
      EXCEPTIONS
        foreign_lock    = 1
        system_failure  = 2
        OTHERS          = 3.

    IF sy-subrc <> 0.
      pv_lock = abap_true.
      RETURN.
    ENDIF.

    "락을 실제로 확보한 부모 PO 기록
    APPEND VALUE #(
      ebeln = <ls_link>-c_ebeln
    ) TO pt_parent_lock.

  ENDLOOP.
  "부모 품목의 형제 구성자재와 같은 헤더의 다른 품목도 함께 가져온다.
  "그래야 일부 품목만 확보됐는데 PO 헤더를 해제하는 일을 막을 수 있다.
  SELECT * FROM ztmma00160
    FOR ALL ENTRIES IN @lt_link
    WHERE c_ebeln = @lt_link-c_ebeln
    INTO CORRESPONDING FIELDS OF TABLE @pt_160.



ENDFORM.

*FORM zz_get_po_stock  USING    pt_po_stock TYPE zttmma00090
*                   CHANGING    pt_160      TYPE zttmma00160.
*
*  DATA : lt_090 TYPE zttmma00090.
*  lt_090 = pt_po_stock.
*
*  SORT lt_090 BY ebeln ebelp.
*  DELETE ADJACENT DUPLICATES FROM lt_090 COMPARING ebeln ebelp.
*
*  SELECT *
*    FROM ztmma00160
*    INTO CORRESPONDING FIELDS OF TABLE @pt_160
*    FOR ALL ENTRIES IN @lt_090
*    WHERE ebeln = @lt_090-ebeln
*      AND ebelp = @lt_090-ebelp.
*
*ENDFORM.
FORM zz_bom_release
  CHANGING ct_reserve   TYPE zttmma00160
           ct_stock     TYPE zttmma00070
           ct_move_head TYPE STANDARD TABLE
           ct_move_item TYPE zttmma00090
           ct_po_head   TYPE zttmma00050
           ct_return    TYPE bapiret2_t.

  TYPES: BEGIN OF ty_parent,
           ebeln TYPE ebeln,
           ebelp TYPE ebelp,
         END OF ty_parent.
  DATA: lt_parent  TYPE SORTED TABLE OF ty_parent
          WITH UNIQUE KEY ebeln ebelp,
        lv_full    TYPE abap_bool,
        lv_pending TYPE abap_bool,
        lv_issued  TYPE abap_bool,
        lv_mblnr   TYPE mblnr,
        lv_zeile   TYPE ztmma00090-zeile.

  IF ct_reserve IS INITIAL.
    RETURN.
  ENDIF.

  LOOP AT ct_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>).
    "공란은 기존 미지급 데이터로 취급하며 수량과 상태를 별개로 검사한다.
    IF <ls_reserve>-c_ebeln IS INITIAL
       OR <ls_reserve>-c_ebelp IS INITIAL
       OR <ls_reserve>-reqty <= 0
       OR <ls_reserve>-rsqty < 0
       OR <ls_reserve>-rsqty > <ls_reserve>-reqty
       OR ( <ls_reserve>-rstat IS NOT INITIAL
            AND <ls_reserve>-rstat <> '0010'
            AND <ls_reserve>-rstat <> '0020' ).
      APPEND VALUE #( type = 'E' message = TEXT-t38 ) TO ct_return.
      RETURN.
    ENDIF.
    INSERT VALUE #( ebeln = <ls_reserve>-c_ebeln
                    ebelp = <ls_reserve>-c_ebelp ) INTO TABLE lt_parent.
  ENDLOOP.

  "헤더는 한 번에 읽고 이미 0040인 헤더만 지급 완료 후 해제한다.
  SELECT * FROM ztmma00050
    FOR ALL ENTRIES IN @lt_parent
    WHERE ebeln = @lt_parent-ebeln
    INTO TABLE @DATA(lt_head).

  LOOP AT lt_parent ASSIGNING FIELD-SYMBOL(<ls_parent>).
    IF NOT line_exists( lt_head[ ebeln = <ls_parent>-ebeln ] ).
      APPEND VALUE #( type = 'E' message = TEXT-t38 ) TO ct_return.
      RETURN.
    ENDIF.

    lv_full = abap_true.
    CLEAR: lv_pending, lv_issued.
    LOOP AT ct_reserve ASSIGNING <ls_reserve>
      WHERE c_ebeln = <ls_parent>-ebeln AND c_ebelp = <ls_parent>-ebelp.
      IF <ls_reserve>-rstat = '0020'.
        lv_issued = abap_true.
      ELSE.
        lv_pending = abap_true.
      ENDIF.
      IF <ls_reserve>-reqty <> <ls_reserve>-rsqty.
        lv_full = abap_false.
      ENDIF.
    ENDLOOP.

    "한 부모 품목은 일괄 지급하므로 일부 행만 지급완료인 불일치는 중단한다.
    IF lv_issued = abap_true AND lv_pending = abap_true.
      APPEND VALUE #( type = 'E' message = TEXT-t38 ) TO ct_return.
      RETURN.
    ENDIF.
    IF lv_full = abap_false OR lv_pending = abap_false.
      CONTINUE.
    ENDIF.

    CLEAR: lv_mblnr, lv_zeile.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr = '01'
        object      = 'ZMM_MBLNR'
        toyear      = sy-datum+0(4)
      IMPORTING
        number      = lv_mblnr
      EXCEPTIONS
        OTHERS      = 1.
    IF sy-subrc <> 0.
      APPEND VALUE #( type = 'E' message = TEXT-t30 ) TO ct_return.
      RETURN.
    ENDIF.

    APPEND VALUE ztmma00080(
      mblnr = lv_mblnr mjahr = sy-datum+0(4)
      bldat = sy-datum budat = sy-datum usnam = sy-uname
      ernam = sy-uname erdat = sy-datum erzet = sy-uzeit
    ) TO ct_move_head.

    LOOP AT ct_reserve ASSIGNING <ls_reserve>
      WHERE c_ebeln = <ls_parent>-ebeln AND c_ebelp = <ls_parent>-ebelp.

      READ TABLE ct_stock ASSIGNING FIELD-SYMBOL(<ls_stock>)
        WITH KEY matnr = <ls_reserve>-matnr
                 werks = <ls_reserve>-werks lgort = <ls_reserve>-lgort.
      IF sy-subrc <> 0.
        APPEND VALUE #( type = 'E' message = TEXT-t18 ) TO ct_return.
        RETURN.
      ENDIF.
      IF <ls_stock>-meins <> <ls_reserve>-meins
         OR <ls_stock>-rsqty < <ls_reserve>-reqty.
        APPEND VALUE #( type = 'E' message = TEXT-t19 ) TO ct_return.
        RETURN.
      ENDIF.

      "실제로 지급하는 자재/창고/전체 필요수량을 재고와 문서에 동일하게 반영한다.
      <ls_stock>-rsqty -= <ls_reserve>-reqty.
      <ls_stock>-aenam = sy-uname.
      <ls_stock>-aedat = sy-datum.
      <ls_stock>-aezet = sy-uzeit.
      lv_zeile += 10.
      APPEND VALUE #(
        mblnr = lv_mblnr mjahr = sy-datum+0(4) zeile = lv_zeile
        matnr = <ls_reserve>-matnr werks = <ls_reserve>-werks
        lgort = <ls_reserve>-lgort
        ebeln = <ls_parent>-ebeln ebelp = <ls_parent>-ebelp
        menge = <ls_reserve>-reqty meins = <ls_reserve>-meins
        bwart = '655'
        ernam = sy-uname erdat = sy-datum erzet = sy-uzeit
      ) TO ct_move_item.

      "확보 수량은 이력으로 유지하고 지급완료 상태로 재지급을 차단한다.
      <ls_reserve>-rstat = '0020'.
      <ls_reserve>-aenam = sy-uname.
      <ls_reserve>-aedat = sy-datum.
      <ls_reserve>-aezet = sy-uzeit.
    ENDLOOP.
  ENDLOOP.

  LOOP AT lt_head ASSIGNING FIELD-SYMBOL(<ls_head>) WHERE pstat = '0040'.
    CLEAR lv_pending.
    LOOP AT ct_reserve ASSIGNING <ls_reserve>
      WHERE c_ebeln = <ls_head>-ebeln.
      IF <ls_reserve>-rstat <> '0020'.
        lv_pending = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF lv_pending = abap_false.
      <ls_head>-pstat = '0030'.
      <ls_head>-aenam = sy-uname.
      <ls_head>-aedat = sy-datum.
      <ls_head>-aezet = sy-uzeit.
      APPEND CORRESPONDING #( <ls_head> ) TO ct_po_head.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_lock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> MOVE_MATERIAL
*&      <-- LV_LOCK
*&---------------------------------------------------------------------*
FORM zz_set_lock  USING    pt_move_material TYPE zttmma00090
                  CHANGING pv_lock TYPE abap_bool.
  DATA : lt_lock TYPE zttmma00090.
  DATA : lt_so_lock TYPE zttmma00090.
  DATA : lt_po_lock TYPE zttmma00090.
  lt_lock = pt_move_material.
  SORT lt_lock BY matnr werks lgort.
  DELETE ADJACENT DUPLICATES FROM lt_lock COMPARING matnr werks lgort.

  LOOP AT lt_lock ASSIGNING FIELD-SYMBOL(<ls_lock>).
    CALL FUNCTION 'ENQUEUE_EZ_STOCK'
      EXPORTING
        mode_ztmma00070 = 'E'
        mandt           = sy-mandt
        matnr           = <ls_lock>-matnr
        werks           = <ls_lock>-werks
        lgort           = <ls_lock>-lgort
*       X_MATNR         = ' '
*       X_WERKS         = ' '
*       X_LGORT         = ' '
        _scope          = '1'
*       _WAIT           = ' '
*       _COLLECT        = ' '
      EXCEPTIONS
        foreign_lock    = 1
        system_failure  = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      pv_lock = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.
  CHECK pv_lock IS INITIAL.
  lt_so_lock = pt_move_material.
  DELETE lt_so_lock WHERE vbeln_so IS INITIAL.
  SORT lt_so_lock BY vbeln_so posnr.
  DELETE ADJACENT DUPLICATES FROM lt_so_lock COMPARING vbeln_so posnr.
  IF lt_so_lock IS NOT INITIAL.
    LOOP AT lt_so_lock ASSIGNING FIELD-SYMBOL(<ls_so_stock>).
      CALL FUNCTION 'ENQUEUE_EZ_SO_STOCK'
        EXPORTING
          mode_ztmma00150 = 'E'
          mandt           = sy-mandt
          vbeln           = <ls_so_stock>-vbeln_so
          posnr           = <ls_so_stock>-posnr
*         X_VBELN         = ' '
*         X_POSNR         = ' '
          _scope          = '1'
*         _WAIT           = ' '
*         _COLLECT        = ' '
        EXCEPTIONS
          foreign_lock    = 1
          system_failure  = 2
          OTHERS          = 3.
      IF sy-subrc <> 0.
        pv_lock = abap_true.
        EXIT.
      ENDIF.

    ENDLOOP.
  ENDIF.
  CHECK pv_lock IS INITIAL.
  lt_po_lock = pt_move_material.
  DELETE lt_po_lock WHERE ebeln IS INITIAL.
  SORT lt_po_lock BY ebeln ebelp.
  DELETE ADJACENT DUPLICATES FROM lt_po_lock COMPARING ebeln ebelp.


  LOOP AT lt_po_lock ASSIGNING FIELD-SYMBOL(<ls_po_stock>).
    CALL FUNCTION 'ENQUEUE_EZ_PO_STOCK'
      EXPORTING
        mode_ztmma00160 = 'E'
        mandt           = sy-mandt
        ebeln           = <ls_po_stock>-ebeln
        ebelp           = <ls_po_stock>-ebelp
*       X_EBELN         = ' '
*       X_EBELP         = ' '
*       X_MATNR         = ' '
*       X_WERKS         = ' '
*       X_LGORT         = ' '
        _scope          = '1'
*       _WAIT           = ' '
*       _COLLECT        = ' '
      EXCEPTIONS
        foreign_lock    = 1
        system_failure  = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      pv_lock = abap_true.
      EXIT.
    ENDIF.
  ENDLOOP.

  IF pv_lock IS NOT INITIAL.
    PERFORM zz_set_dequeue USING pt_move_material.


  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_dequeue
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_dequeue USING pt_move_material    TYPE zttmma00090.
  DATA : lt_lock TYPE zttmma00090.
  DATA : lt_so_lock TYPE zttmma00090.
  DATA : lt_po_lock TYPE zttmma00090.

  lt_lock = pt_move_material.
  SORT lt_lock BY matnr werks lgort.
  DELETE ADJACENT DUPLICATES FROM lt_lock COMPARING matnr werks lgort.
  LOOP AT lt_lock ASSIGNING FIELD-SYMBOL(<ls_lock>).
    CALL FUNCTION 'DEQUEUE_EZ_STOCK'
      EXPORTING
        mode_ztmma00070 = 'E'
        mandt           = sy-mandt
        matnr           = <ls_lock>-matnr
        werks           = <ls_lock>-werks
        lgort           = <ls_lock>-lgort
*       X_MATNR         = ' '
*       X_WERKS         = ' '
*       X_LGORT         = ' '
        _scope          = '1'
*       _SYNCHRON       = ' '
*       _COLLECT        = ' '
      .
  ENDLOOP.

  lt_po_lock = pt_move_material.
  DELETE lt_po_lock WHERE ebeln IS INITIAL.
  SORT lt_po_lock BY ebeln ebelp.
  DELETE ADJACENT DUPLICATES FROM lt_po_lock COMPARING ebeln ebelp.
  LOOP AT lt_po_lock ASSIGNING FIELD-SYMBOL(<ls_po_lock>).
    CALL FUNCTION 'DEQUEUE_EZ_PO_STOCK'
      EXPORTING
        mode_ztmma00160 = 'E'
        mandt           = sy-mandt
        ebeln           = <ls_po_lock>-ebeln
        ebelp           = <ls_po_lock>-ebelp
*       X_EBELN         = ' '
*       X_EBELP         = ' '
        _scope          = '1'
*       _WAIT           = ' '
*       _COLLECT        = ' '
*     EXCEPTIONS
*       FOREIGN_LOCK    = 1
*       SYSTEM_FAILURE  = 2
*       OTHERS          = 3
      .
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ENDLOOP.

  lt_so_lock = pt_move_material.
  DELETE lt_so_lock WHERE vbeln_so IS INITIAL.
  SORT lt_so_lock BY vbeln_so posnr.
  DELETE ADJACENT DUPLICATES FROM lt_so_lock COMPARING vbeln_so posnr.
  LOOP AT lt_so_lock ASSIGNING FIELD-SYMBOL(<ls_so_stock>).
    CALL FUNCTION 'DEQUEUE_EZ_SO_STOCK'
      EXPORTING
        mode_ztmma00150 = 'E'
        mandt           = sy-mandt
        vbeln           = <ls_so_stock>-vbeln_so
        posnr           = <ls_so_stock>-posnr
*       X_VBELN         = ' '
*       X_POSNR         = ' '
        _scope          = '1'
*       _SYNCHRON       = ' '
*       _COLLECT        = ' '
      .

  ENDLOOP.
ENDFORM.
