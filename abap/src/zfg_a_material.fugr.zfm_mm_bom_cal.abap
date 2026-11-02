FUNCTION zfm_mm_bom_cal.
*" IMPORTING BOM_HEAD       TYPE ZTTCMA00120
*"           BOM_ITEM       TYPE ZTTCMA00130
*"           PURCHASE_ITEM  TYPE ZSMMA00060
*"           IV_EBELP       TYPE EBELP
*"           IV_EBELN       TYPE EBELN
*"           PROCURE_COND   TYPE ZTTCMA00040
*"           MY_EBELN       TYPE EBELN
*"           MY_EBELP       TYPE EBELP
*" EXPORTING PURCHASE_ORDER   TYPE ZTTMMA00061
*"           PURCHASE_RESERVE TYPE ZTTMMA00160
*" TABLES    ET_RETURN STRUCTURE BAPIRET2
*" CHANGING  STOCK_DETAIL TYPE ZTTMMA00070
*"           CV_ERROR     TYPE ABAP_BOOL

  DATA: lv_remaining   TYPE decfloat34,
        lv_child_ebeln TYPE ebeln,
        lv_child_ebelp TYPE ebelp,
        lt_sub_order   TYPE zttmma00061,
        lt_sub_reserve TYPE zttmma00160.

  CLEAR: purchase_order, purchase_reserve.
  "재귀 하위에서 발생한 오류를 상위 호출이 지우지 않도록 유지한다.
  IF cv_error = abap_true.
    RETURN.
  ENDIF.

  "입고받을 창고의 재고 초기등록이 없는 자재는 기존 정책대로 중단한다.
  IF purchase_item-menge <= 0
     OR purchase_item-meins IS INITIAL
     OR NOT line_exists( stock_detail[
       matnr = purchase_item-matnr
       werks = purchase_item-werks
       lgort = purchase_item-lgort ] ).
    APPEND VALUE #( type = 'E' message = TEXT-t38 ) TO et_return.
    cv_error = abap_true.
    RETURN.
  ENDIF.

  lv_remaining = purchase_item-menge.

  "상세재고는 호출부의 MATNR/WERKS/LGORT 정렬 순서대로 확보한다.
  "여기서는 계산용 내부테이블만 바꾸며 실제 재고 저장은 기존 재고 FM이 한다.
  LOOP AT stock_detail ASSIGNING FIELD-SYMBOL(<ls_stock>)
    WHERE matnr = purchase_item-matnr
      AND werks = purchase_item-werks
      AND stqty > 0.

    IF <ls_stock>-meins <> purchase_item-meins.
      APPEND VALUE #( type = 'E' message = TEXT-t38 ) TO et_return.
      cv_error = abap_true.
      RETURN.
    ENDIF.

    DATA(lv_allocate) = CONV decfloat34( <ls_stock>-stqty ).
    IF lv_allocate > lv_remaining.
      lv_allocate = lv_remaining.
    ENDIF.

    APPEND VALUE #(
      ebeln = my_ebeln ebelp = my_ebelp
      matnr = purchase_item-matnr
      werks = <ls_stock>-werks lgort = <ls_stock>-lgort
      reqty = lv_allocate rsqty = lv_allocate
      meins = purchase_item-meins
      c_ebeln = iv_ebeln c_ebelp = iv_ebelp
      rstat = '0010'
      erdat = sy-datum erzet = sy-uzeit ernam = sy-uname
    ) TO purchase_reserve.

    <ls_stock>-stqty -= lv_allocate.
    <ls_stock>-rsqty += lv_allocate.
    lv_remaining -= lv_allocate.

    IF lv_remaining = 0.
      EXIT.
    ENDIF.
  ENDLOOP.

  "재고만으로 충족한 자재는 추가 PO와 하위 BOM을 만들지 않는다.
  IF lv_remaining = 0.
    RETURN.
  ENDIF.

  "부족한 수량만 기존 BOM 구매 유형 0030으로 생성한다.
  APPEND VALUE #(
    ebeln = my_ebeln ebelp = my_ebelp
    matnr = purchase_item-matnr werks = purchase_item-werks
    lgort = purchase_item-lgort menge = lv_remaining
    meins = purchase_item-meins ptype = '0030'
    erdat = sy-datum erzet = sy-uzeit ernam = sy-uname
  ) TO purchase_order.

  READ TABLE purchase_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>)
    WITH KEY ebeln = my_ebeln ebelp = my_ebelp
             matnr = purchase_item-matnr
             werks = purchase_item-werks
             lgort = purchase_item-lgort
             c_ebeln = iv_ebeln c_ebelp = iv_ebelp.
  IF sy-subrc = 0.
    "동일 창고 행에 이미 확보한 양이 있으면 필요수량에 부족분만 더한다.
    <ls_reserve>-reqty += lv_remaining.
  ELSE.
    APPEND VALUE #(
      ebeln = my_ebeln ebelp = my_ebelp
      matnr = purchase_item-matnr werks = purchase_item-werks
      lgort = purchase_item-lgort
      reqty = lv_remaining rsqty = 0
      meins = purchase_item-meins
      c_ebeln = iv_ebeln c_ebelp = iv_ebelp
      rstat = '0010'
      erdat = sy-datum erzet = sy-uzeit ernam = sy-uname
    ) TO purchase_reserve.
  ENDIF.

  READ TABLE bom_head ASSIGNING FIELD-SYMBOL(<ls_head>)
    WITH KEY matnr = purchase_item-matnr werks = purchase_item-werks.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "전체 전개 FM과 같은 기준수량/단위로 부족분의 직접 구성자재를 계산한다.
  IF <ls_head>-bmeng <= 0
     OR <ls_head>-bmein <> purchase_item-meins.
    APPEND VALUE #( type = 'E' message = TEXT-t38 ) TO et_return.
    cv_error = abap_true.
    RETURN.
  ENDIF.

  READ TABLE bom_item WITH KEY stlnr = <ls_head>-stlnr
    TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'E' message = TEXT-t38 ) TO et_return.
    cv_error = abap_true.
    RETURN.
  ENDIF.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZMM_EBELN'
    IMPORTING
      number      = lv_child_ebeln
    EXCEPTIONS
      OTHERS      = 1.
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'E' message = TEXT-t38 ) TO et_return.
    cv_error = abap_true.
    RETURN.
  ENDIF.

  LOOP AT bom_item ASSIGNING FIELD-SYMBOL(<ls_item>)
    WHERE stlnr = <ls_head>-stlnr.
    IF <ls_item>-idnrk IS INITIAL
       OR <ls_item>-meins IS INITIAL OR <ls_item>-menge <= 0.
      APPEND VALUE #( type = 'E' message = TEXT-t38 ) TO et_return.
      cv_error = abap_true.
      RETURN.
    ENDIF.

    lv_child_ebelp += 10.
    DATA(ls_child) = VALUE zsmma00060(
      matnr = <ls_item>-idnrk werks = purchase_item-werks
      lgort = purchase_item-lgort
      menge = lv_remaining * <ls_item>-menge / <ls_head>-bmeng
      meins = <ls_item>-meins ).

    CLEAR: lt_sub_order, lt_sub_reserve.
    CALL FUNCTION 'ZFM_MM_BOM_CAL'
      EXPORTING
        bom_head         = bom_head
        bom_item         = bom_item
        purchase_item    = ls_child
        iv_ebeln         = my_ebeln
        iv_ebelp         = my_ebelp
        procure_cond     = procure_cond
        my_ebeln         = lv_child_ebeln
        my_ebelp         = lv_child_ebelp
      IMPORTING
        purchase_order   = lt_sub_order
        purchase_reserve = lt_sub_reserve
      TABLES
        et_return        = et_return
      CHANGING
        stock_detail     = stock_detail
        cv_error         = cv_error.
    IF cv_error = abap_true.
      RETURN.
    ENDIF.
    APPEND LINES OF lt_sub_order TO purchase_order.
    APPEND LINES OF lt_sub_reserve TO purchase_reserve.
  ENDLOOP.
ENDFUNCTION.
*FUNCTION zfm_mm_bom_cal .
**"----------------------------------------------------------------------
**"*"Local Interface:
**"  IMPORTING
**"     REFERENCE(BOM_HEAD) TYPE  ZTTCMA00120
**"     REFERENCE(BOM_ITEM) TYPE  ZTTCMA00130
**"     REFERENCE(PURCHASE_ITEM) TYPE  ZSMMA00060
**"     REFERENCE(IV_EBELP) TYPE  EBELP
**"     REFERENCE(IV_EBELN) TYPE  EBELN
**"     REFERENCE(PROCURE_COND) TYPE  ZTTCMA00040
**"     REFERENCE(MY_EBELN) TYPE  EBELN
**"     REFERENCE(MY_EBELP) TYPE  EBELP
**"  EXPORTING
**"     REFERENCE(PURCHASE_ORDER) TYPE  ZTTMMA00061
**"     REFERENCE(PURCHASE_RESERVE) TYPE  ZTTMMA00160
**"  TABLES
**"      ET_RETURN STRUCTURE  BAPIRET2
**"  CHANGING
**"     REFERENCE(STOCK_DETAIL) TYPE  ZTTMMA00070
**"     REFERENCE(CV_ERROR) TYPE  ABAP_BOOL
**"----------------------------------------------------------------------
**  DATA : lv_ebeln TYPE ebeln.
**  DATA : lv_ebelp TYPE ebelp VALUE 10.
*  DATA : lv_lgort_stqty TYPE ztmma00070-stqty,
*         lv_reserve_qty TYPE ztmma00070-stqty.
*
*  DATA: lt_sub_order   TYPE zttmma00061,
*        lt_sub_reserve TYPE zttmma00160.
*  DATA : lv_child_ebeln TYPE ebeln.
*  DATA : lv_child_ebelp TYPE ebelp.
**  CALL FUNCTION 'NUMBER_GET_NEXT'
**    EXPORTING
**      nr_range_nr = '01'
**      object      = 'ZMM_EBELN'
**    IMPORTING
**      number      = lv_ebeln.
**  IF sy-subrc <> 0.
**    "에러 코드
**  ENDIF.
*  lv_lgort_stqty = purchase_item-menge.
*  READ TABLE stock_detail WITH KEY matnr = purchase_item-matnr
*                                   werks = purchase_item-werks
*                                   lgort = purchase_item-lgort TRANSPORTING NO FIELDS.
*  IF sy-subrc <> 0.
*    cv_error = abap_true.
*    RETURN.
*  ENDIF.
*
*  lv_lgort_stqty = purchase_item-menge.
*  LOOP AT stock_detail ASSIGNING FIELD-SYMBOL(<ls_stock_detail>) WHERE matnr = purchase_item-matnr
*                                                                   AND werks = purchase_item-werks
*                                                                   AND stqty > 0.
*
*    IF <ls_stock_detail>-stqty >= lv_lgort_stqty.
*      APPEND VALUE #(
*        ebeln   = my_ebeln
*        ebelp   = my_ebelp
*        matnr   = purchase_item-matnr
*        werks   = <ls_stock_detail>-werks
*        lgort   = <ls_stock_detail>-lgort
*        reqty   = lv_lgort_stqty
*        rsqty   = lv_lgort_stqty
*        meins   = purchase_item-meins
*        c_ebeln = iv_ebeln
*        c_ebelp = iv_ebelp
*        erdat = sy-datum
*        erzet = sy-uzeit
*        ernam = sy-uname
*      ) TO purchase_reserve.
*
*      "현재 창고에서 남은 수량을 모두 충당했으므로 종료
*      <ls_stock_detail>-stqty -= lv_lgort_stqty.
*      <ls_stock_detail>-rsqty += lv_lgort_stqty.
*      CLEAR lv_lgort_stqty.
*      EXIT.
*    ELSE.
*      APPEND VALUE #(
*        ebeln   = my_ebeln
*        ebelp   = my_ebelp
*        matnr   = purchase_item-matnr
*        werks   = <ls_stock_detail>-werks
*        lgort   = <ls_stock_detail>-lgort
*        reqty   = <ls_stock_detail>-stqty
*        rsqty   = <ls_stock_detail>-stqty
*        meins   = purchase_item-meins
*        c_ebeln = iv_ebeln
*        c_ebelp = iv_ebelp
*        erdat = sy-datum
*        erzet = sy-uzeit
*        ernam = sy-uname
*      ) TO purchase_reserve.
*      "현재 창고 재고를 전부 사용하고 부족분은 다음 창고에서 충당
*      <ls_stock_detail>-rsqty += <ls_stock_detail>-stqty.
*      lv_lgort_stqty -= <ls_stock_detail>-stqty.
*      CLEAR <ls_stock_detail>-stqty.
*    ENDIF.
*  ENDLOOP.
*
*  "공급 업체는 무조건 첫번째로 할거임. 일단은
*  IF lv_lgort_stqty > 0.
*    APPEND VALUE #(
*      ebeln   = my_ebeln
*      ebelp   = my_ebelp
*      matnr = purchase_item-matnr
*      werks = purchase_item-werks
*      lgort = purchase_item-lgort
*      menge = lv_lgort_stqty
*      meins = purchase_item-meins
**      netpr =
**      waers =
**      eindt =
*      "현재 자재에 BOM이 있으면 외주, 없으면 일반 구매
**      ptype = COND #(
**        WHEN line_exists(
**          bom_head[ matnr = purchase_item-matnr
**                    werks = purchase_item-werks ]
**        )
**        THEN '0020'
**        ELSE '0010'
**      )
*      ptype = '0030'
*      erdat = sy-datum
*      erzet = sy-uzeit
*      ernam = sy-uname
*    ) TO purchase_order.
*    "같은 PO 품목과 자재, 창고의 기존 예약행 확인
*    READ TABLE purchase_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>)
*      WITH KEY ebeln   = my_ebeln
*               ebelp   = my_ebelp
*               matnr   = purchase_item-matnr
*               werks   = purchase_item-werks
*               lgort   = purchase_item-lgort
*               c_ebeln = iv_ebeln
*               c_ebelp = iv_ebelp.
*
*    IF sy-subrc = 0.
*
*      "확보 수량은 유지하고 부족 수량만 필요량에 추가
*      <ls_reserve>-reqty += lv_lgort_stqty.
*
*    ELSE.
*
*      "해당 창고의 예약행이 없으면 미확보 수량으로 신규 생성
*      APPEND VALUE #(
*        ebeln   = my_ebeln
*        ebelp   = my_ebelp
*        matnr   = purchase_item-matnr
*        werks   = purchase_item-werks
*        lgort   = purchase_item-lgort
*        reqty   = lv_lgort_stqty
*        rsqty   = 0
*        meins   = purchase_item-meins
*        c_ebeln = iv_ebeln
*        c_ebelp = iv_ebelp
*        erdat   = sy-datum
*        erzet   = sy-uzeit
*        ernam   = sy-uname
*      ) TO purchase_reserve.
*
*    ENDIF.
**    APPEND VALUE #(
**      ebeln   = my_ebeln
**      ebelp   = my_ebelp
**      matnr   = purchase_item-matnr
**      werks   = purchase_item-werks
**      lgort   = purchase_item-lgort
**      reqty   = lv_lgort_stqty
**      rsqty   = 0
**      meins   = purchase_item-meins
**      c_ebeln = iv_ebeln
**      c_ebelp = iv_ebelp
**      erdat   = sy-datum
**      erzet   = sy-uzeit
**      ernam   = sy-uname
**    ) TO purchase_reserve.
*
*  ELSE.
*    RETURN.
*  ENDIF.
*
*
*  READ TABLE bom_head ASSIGNING FIELD-SYMBOL(<ls_head>) WITH KEY matnr = purchase_item-matnr
*                                                                 werks = purchase_item-werks.
*
*  IF sy-subrc <> 0.
*    RETURN.
*  ENDIF.
*
*  CALL FUNCTION 'NUMBER_GET_NEXT'
*    EXPORTING
*      nr_range_nr = '01'
*      object      = 'ZMM_EBELN'
*    IMPORTING
*      number      = lv_child_ebeln
*    EXCEPTIONS
*      OTHERS      = 1.
*  IF sy-subrc <> 0.
*    cv_error = abap_true.
*    RETURN.   " 필요하면 et_return에 에러 메시지 추가
*  ENDIF.
*
*  LOOP AT bom_item ASSIGNING FIELD-SYMBOL(<ls_item>) WHERE stlnr = <ls_head>-stlnr.
*    lv_child_ebelp += 10.
*    DATA(ls_purchase_item) = VALUE zsmma00060(
*    matnr = <ls_item>-idnrk
*    werks = purchase_item-werks
*    lgort = purchase_item-lgort
*    menge = lv_lgort_stqty * <ls_item>-menge
*    meins = <ls_item>-meins
*  ).
*    CLEAR: lt_sub_order, lt_sub_reserve.
*    CALL FUNCTION 'ZFM_MM_BOM_CAL'
*      EXPORTING
*        bom_head         = bom_head
*        bom_item         = bom_item
*        purchase_item    = ls_purchase_item
*        iv_ebelp         = my_ebelp
*        iv_ebeln         = my_ebeln
*        procure_cond     = procure_cond
*        my_ebeln         = lv_child_ebeln
*        my_ebelp         = lv_child_ebelp
*      IMPORTING
*        purchase_order   = lt_sub_order
*        purchase_reserve = lt_sub_reserve
*      TABLES
*        et_return        = et_return
*      CHANGING
*        stock_detail     = stock_detail
*        cv_error         = cv_error.
*
*    IF cv_error = abap_true.
*      RETURN.
*    ENDIF.
**        cv_bnfpo         = cv_bnfpo.
*    APPEND LINES OF lt_sub_order   TO purchase_order.
*    APPEND LINES OF lt_sub_reserve TO purchase_reserve.
*  ENDLOOP.
*ENDFUNCTION.
*
*
**  IF sy-subrc = 0.
**
**    "해당 BOM의 직접 구성자재 전체를 대상으로 재귀 처리
**    LOOP AT bom_item ASSIGNING FIELD-SYMBOL(<ls_item>) WHERE stlnr = <ls_head>-stlnr.
**
**      "하위 필요 수량 = lv_lgort_stqty * <ls_item>-menge
**      "하위 자재 = <ls_item>-idnrk
**      "직계 부모 = lv_ebeln / lv_ebelp
**      "여기에 재귀 호출 후 PO와 예약 결과 누적
**
**    ENDLOOP.
**
**  ENDIF.
*
*
*
*
*
**
**  채번 후에 아이템 넣을 때만 bnfpo 를 증가
**  160번 생성된 자재에 대해 BOM ITEM 구함.
**  구매목록 번호 채번 및 만들고 같은 CALL FUNCTION ZFM_MM_BOM_CAL, 채번 번호 같이 PO에 생성 유형 BOM으로 박아서 채번해서 넘김..
**  160번에도 PO 번호 업데이트
**  점점 자재는 줄고 구매요청은 쌓임.
**  나중에 구매요청 돌면서 ZTMMA00160에 다 쌓였으면 지급정지 풀고 자재 내보낼거임.
