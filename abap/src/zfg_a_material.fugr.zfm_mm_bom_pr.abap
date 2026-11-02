FUNCTION zfm_mm_bom_pr.
*" IMPORTING PURCHASE_HEAD TYPE ZTTMMA00050
*"           PURCHASE_ITEM TYPE ZTTMMA00061
*" EXPORTING PURCHASE_ORDER   TYPE ZTTMMA00061
*"           PURCHASE_RESERVE TYPE ZTTMMA00160
*"           STOCK            TYPE ZTTMMA00070
*" TABLES ET_RETURN STRUCTURE BAPIRET2

  TYPES: BEGIN OF ty_material_key,
           matnr TYPE matnr,
           werks TYPE werks_d,
         END OF ty_material_key.
  DATA: lt_component TYPE zttmma00030,
        lt_return TYPE bapiret2_t,
        lt_key TYPE SORTED TABLE OF ty_material_key
          WITH UNIQUE KEY matnr werks,
        lt_stock TYPE zttmma00070,
        lt_bom_head TYPE zttcma00120,
        lt_bom_item TYPE zttcma00130,
        lt_condition TYPE zttcma00040,
        lt_order TYPE zttmma00061,
        lt_reserve TYPE zttmma00160,
        lt_order_temp TYPE zttmma00061,
        lt_reserve_temp TYPE zttmma00160,
        lv_ebeln TYPE ebeln,
        lv_ebelp TYPE ebelp,
        lv_error TYPE abap_bool.

  CLEAR: purchase_order, purchase_reserve, stock.

  "기존 전체 전개 FM으로 순환/단위/기준수량을 검증하고 조회키를 모은다.
  LOOP AT purchase_item ASSIGNING FIELD-SYMBOL(<ls_root>)
    WHERE ptype = '0020'.
    INSERT VALUE #( matnr = <ls_root>-matnr werks = <ls_root>-werks )
      INTO TABLE lt_key.
    CLEAR: lt_component, lt_return.
    CALL FUNCTION 'ZFM_MM_SUBC_BOM_GET'
      EXPORTING iv_ebeln = <ls_root>-ebeln iv_ebelp = <ls_root>-ebelp
      IMPORTING et_component = lt_component et_return = lt_return.
    APPEND LINES OF lt_return TO et_return.
    IF line_exists( lt_return[ type = 'E' ] )
       OR line_exists( lt_return[ type = 'A' ] )
       OR line_exists( lt_return[ type = 'X' ] ).
      RETURN.
    ENDIF.
    LOOP AT lt_component ASSIGNING FIELD-SYMBOL(<ls_component>).
      INSERT VALUE #( matnr = <ls_component>-matnr
                      werks = <ls_component>-werks ) INTO TABLE lt_key.
    ENDLOOP.
  ENDLOOP.
  IF lt_key IS INITIAL.
    RETURN.
  ENDIF.

  "본 호출은 당일 신규 생성한 PO를 대상으로 하므로 당일 유효 BOM으로 통일한다.
  SELECT * FROM ztcma00120
    FOR ALL ENTRIES IN @lt_key
    WHERE matnr = @lt_key-matnr AND werks = @lt_key-werks
      AND stlst = '01' AND datuv <= @sy-datum AND valid_to >= @sy-datum
    INTO TABLE @lt_bom_head.
  SORT lt_bom_head BY matnr werks stlnr.
  DATA(lt_unique) = lt_bom_head.
  DELETE ADJACENT DUPLICATES FROM lt_unique COMPARING matnr werks.
  IF lines( lt_unique ) <> lines( lt_bom_head ).
    APPEND VALUE #( type = 'E' message = TEXT-t37 ) TO et_return.
    RETURN.
  ENDIF.
  IF lt_bom_head IS NOT INITIAL.
    SELECT * FROM ztcma00130
      FOR ALL ENTRIES IN @lt_bom_head
      WHERE stlnr = @lt_bom_head-stlnr
      INTO TABLE @lt_bom_item.
  ENDIF.
  SELECT * FROM ztmma00070
    FOR ALL ENTRIES IN @lt_key
    WHERE matnr = @lt_key-matnr AND werks = @lt_key-werks
    INTO TABLE @lt_stock.
  SELECT * FROM ztcma00040
    FOR ALL ENTRIES IN @lt_key
    WHERE matnr = @lt_key-matnr AND actyn = 'Y'
      AND valfr <= @sy-datum AND valto >= @sy-datum
    INTO TABLE @lt_condition.
  SORT lt_stock BY matnr werks lgort.
  SORT lt_condition BY matnr priok lifnr.

  LOOP AT purchase_item ASSIGNING <ls_root> WHERE ptype = '0020'.
    READ TABLE lt_bom_head ASSIGNING FIELD-SYMBOL(<ls_head>)
      WITH KEY matnr = <ls_root>-matnr werks = <ls_root>-werks.
    IF sy-subrc <> 0 OR <ls_root>-menge <= 0.
      APPEND VALUE #( type = 'E' message = TEXT-t37 ) TO et_return.
      RETURN.
    ENDIF.
    IF <ls_head>-bmeng <= 0 OR <ls_head>-bmein <> <ls_root>-meins.
      APPEND VALUE #( type = 'E' message = TEXT-t37 ) TO et_return.
      RETURN.
    ENDIF.
    READ TABLE lt_bom_item WITH KEY stlnr = <ls_head>-stlnr
      TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      APPEND VALUE #( type = 'E' message = TEXT-t37 ) TO et_return.
      RETURN.
    ENDIF.

    CLEAR: lv_ebeln, lv_ebelp.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING nr_range_nr = '01' object = 'ZMM_EBELN'
      IMPORTING number = lv_ebeln
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      APPEND VALUE #( type = 'E' message = TEXT-t37 ) TO et_return.
      RETURN.
    ENDIF.

    LOOP AT lt_bom_item ASSIGNING FIELD-SYMBOL(<ls_item>)
      WHERE stlnr = <ls_head>-stlnr.
      IF <ls_item>-idnrk IS INITIAL
         OR <ls_item>-meins IS INITIAL OR <ls_item>-menge <= 0.
        APPEND VALUE #( type = 'E' message = TEXT-t37 ) TO et_return.
        RETURN.
      ENDIF.
      lv_ebelp += 10.
      "전체 전개 FM처럼 BOM 기준수량으로 나눠 과다한 필요수량을 방지한다.
      DATA(ls_component_item) = VALUE zsmma00060(
        matnr = <ls_item>-idnrk werks = <ls_root>-werks
        lgort = <ls_root>-lgort
        menge = CONV decfloat34( <ls_root>-menge )
                * <ls_item>-menge / <ls_head>-bmeng
        meins = <ls_item>-meins ).
      CLEAR: lt_order_temp, lt_reserve_temp, lv_error.
      CALL FUNCTION 'ZFM_MM_BOM_CAL'
        EXPORTING
          bom_head = lt_bom_head bom_item = lt_bom_item
          purchase_item = ls_component_item
          iv_ebeln = <ls_root>-ebeln iv_ebelp = <ls_root>-ebelp
          procure_cond = lt_condition my_ebeln = lv_ebeln my_ebelp = lv_ebelp
        IMPORTING
          purchase_order = lt_order_temp purchase_reserve = lt_reserve_temp
        TABLES et_return = et_return
        CHANGING stock_detail = lt_stock cv_error = lv_error.
      IF lv_error = abap_true.
        RETURN.
      ENDIF.
      LOOP AT lt_order_temp ASSIGNING FIELD-SYMBOL(<ls_order>).
        <ls_order>-banfn = <ls_root>-banfn.
        <ls_order>-bnfpo = <ls_root>-bnfpo.
      ENDLOOP.
      LOOP AT lt_reserve_temp ASSIGNING FIELD-SYMBOL(<ls_reserve>).
        <ls_reserve>-banfn = <ls_root>-banfn.
        <ls_reserve>-bnfpo = <ls_root>-bnfpo.
      ENDLOOP.
      APPEND LINES OF lt_order_temp TO lt_order.
      APPEND LINES OF lt_reserve_temp TO lt_reserve.
    ENDLOOP.
  ENDLOOP.
  purchase_order = lt_order.
  purchase_reserve = lt_reserve.
  "계산 결과는 참조용이다. DB 재고 저장은 653/654/지급 처리 결과만 사용한다.
  stock = lt_stock.
ENDFUNCTION.
*FUNCTION zfm_mm_bom_pr.
**"----------------------------------------------------------------------
**"*"Local Interface:
**"  IMPORTING
**"     REFERENCE(PURCHASE_HEAD) TYPE  ZTTMMA00050
**"     REFERENCE(PURCHASE_ITEM) TYPE  ZTTMMA00061
**"  EXPORTING
**"     REFERENCE(PURCHASE_ORDER) TYPE  ZTTMMA00061
**"     REFERENCE(PURCHASE_RESERVE) TYPE  ZTTMMA00160
**"     REFERENCE(STOCK) TYPE  ZTTMMA00070
**"  TABLES
**"      ET_RETURN STRUCTURE  BAPIRET2
**"----------------------------------------------------------------------
*  TYPES : BEGIN OF ty_material_key,
*            matnr TYPE matnr,
*            werks TYPE werks_d,
*          END OF ty_material_key.
*
**  TYPES : BEGIN OF ty_stock_quantity,
**            matnr TYPE matnr,
**            werks TYPE werks_d,
**            stqty TYPE zde_stqty,
**          END OF ty_stock_quantity.
*
*  DATA : lt_component TYPE zttmma00030.
*  DATA : lt_return TYPE TABLE OF bapiret2,
*         ls_return LIKE LINE OF lt_return.
*
*  DATA : lt_mat_key TYPE TABLE OF ty_material_key.
*  DATA : lt_stock TYPE TABLE OF ztmma00070.
*  DATA : lt_stock_quantity TYPE zttmma00071.
*  DATA : lt_bom_head TYPE TABLE OF ztcma00120,
*         lt_bom_item TYPE TABLE OF ztcma00130.
*
*  DATA : lt_pr_temp TYPE zttmma00040.
*  DATA : lt_purchase_order TYPE zttmma00061.
*  DATA : lt_procure_cond TYPE TABLE OF ztcma00040.
*  DATA : lv_ebeln TYPE ebeln,
*         lv_ebelp TYPE ebelp.
*
*  "전체 예약 결과와 호출별 임시 결과
*  DATA: lt_purchase_reserve TYPE zttmma00160,
*        lt_order_temp       TYPE zttmma00061,
*        lt_reserve_temp     TYPE zttmma00160,
*        lv_error            TYPE abap_bool.
*
**--------------------------------------------------------------------*
** 1. BOM 가져오기 ""WHERE 절 26일 추가
**--------------------------------------------------------------------*
*  LOOP AT purchase_item ASSIGNING FIELD-SYMBOL(<ls_item>) WHERE ptype = '0020'.
*    CLEAR: lt_component, lt_return.
*    APPEND VALUE #(
*      matnr = <ls_item>-matnr
*      werks = <ls_item>-werks
*    ) TO lt_mat_key.
*
*    CALL FUNCTION 'ZFM_MM_SUBC_BOM_GET'
*      EXPORTING
*        iv_ebeln     = <ls_item>-ebeln
*        iv_ebelp     = <ls_item>-ebelp
**       IV_KEYDATE   =
*      IMPORTING
*        et_component = lt_component
*        et_return    = lt_return.
*
*    READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
*    IF sy-subrc = 0.
*      append_error TEXT-t37.
*      RETURN.
*    ENDIF.
*
*    LOOP AT lt_component ASSIGNING FIELD-SYMBOL(<ls_component>).
*      APPEND VALUE #(
*        matnr = <ls_component>-matnr
*        werks = <ls_component>-werks
*      ) TO lt_mat_key.
*    ENDLOOP.
*
*  ENDLOOP.
*
*  SORT lt_mat_key BY matnr werks.
*  DELETE ADJACENT DUPLICATES FROM lt_mat_key COMPARING matnr werks.
*
*  IF lt_mat_key IS NOT INITIAL.
*    SELECT *
*      FROM ztcma00120
*      INTO CORRESPONDING FIELDS OF TABLE @lt_bom_head
*      FOR ALL ENTRIES IN @lt_mat_key
*      WHERE matnr = @lt_mat_key-matnr
*        AND werks = @lt_mat_key-werks
*        AND stlst = '01'.
*  ENDIF.
*
*  SORT lt_bom_head BY stlnr matnr werks.
*  DELETE ADJACENT DUPLICATES FROM lt_bom_head COMPARING stlnr matnr werks.
*
*  IF lt_bom_head IS NOT INITIAL.
*    SELECT *
*      FROM ztcma00130
*      INTO CORRESPONDING FIELDS OF TABLE @lt_bom_item
*      FOR ALL ENTRIES IN @lt_bom_head
*     WHERE stlnr = @lt_bom_head-stlnr.
*  ENDIF.
**--------------------------------------------------------------------*
** 1. 자재 가져오기
**--------------------------------------------------------------------*
*  IF lt_mat_key IS NOT INITIAL.
*    SELECT *
*      FROM ztmma00070
*      INTO CORRESPONDING FIELDS OF TABLE @lt_stock
*    FOR ALL ENTRIES IN @lt_mat_key
*      WHERE matnr = @lt_mat_key-matnr
*        AND werks = @lt_mat_key-werks.
*
*    SELECT *
*      FROM ztcma00040
*      INTO TABLE @lt_procure_cond
*       FOR ALL ENTRIES IN @lt_mat_key
*     WHERE matnr = @lt_mat_key-matnr
*       AND actyn = 'Y'
*       AND valfr <= @sy-datum
*       AND valto >= @sy-datum.
*  ENDIF.
*
*  LOOP AT lt_stock ASSIGNING FIELD-SYMBOL(<ls_stock_cal>).
*    READ TABLE lt_stock_quantity ASSIGNING FIELD-SYMBOL(<ls_stock_quantity>) WITH KEY matnr = <ls_stock_cal>-matnr
*                                                                                      werks = <ls_stock_cal>-werks.
*
*    IF sy-subrc = 0.
*      <ls_stock_quantity>-stqty += <ls_stock_cal>-stqty.
*    ELSE.
*      APPEND VALUE #(
*        matnr = <ls_stock_cal>-matnr
*        werks = <ls_stock_cal>-werks
*        stqty = <ls_stock_cal>-stqty
*      ) TO lt_stock_quantity.
*    ENDIF.
*
*  ENDLOOP.
*
**--------------------------------------------------------------------*
** 1. 자재 계산
**--------------------------------------------------------------------*
*
*  SORT lt_bom_head BY matnr werks.
*  SORT lt_procure_cond BY matnr priok lifnr.
*
*  "창고 순서대로 재고를 확보하기 위해 정렬
*  SORT lt_stock BY matnr werks lgort.
*
*  LOOP AT purchase_item ASSIGNING FIELD-SYMBOL(<ls_purchase_item>)
*    WHERE ptype = '0020'.
*
*    "이미 생성한 외주 PO의 직접 구성자재를 찾기 위해 BOM 조회
*    READ TABLE lt_bom_head ASSIGNING FIELD-SYMBOL(<ls_bom_head>)
*      WITH KEY matnr = <ls_purchase_item>-matnr
*               werks = <ls_purchase_item>-werks.
*
*    IF sy-subrc <> 0.
*      append_error TEXT-t37.
*      RETURN.
*    ENDIF.
*
*    "상위 PO 품목별로 하위 PO 번호와 품목 순번 초기화
*    CLEAR: lv_ebeln, lv_ebelp.
*
*    CALL FUNCTION 'NUMBER_GET_NEXT'
*      EXPORTING
*        nr_range_nr = '01'
*        object      = 'ZMM_EBELN'
*      IMPORTING
*        number      = lv_ebeln
*      EXCEPTIONS
*        OTHERS      = 1.
*
*    IF sy-subrc <> 0.
*      append_error TEXT-t37.
*      RETURN.
*    ENDIF.
*
*    LOOP AT lt_bom_item ASSIGNING FIELD-SYMBOL(<ls_bom_item>)
*      WHERE stlnr = <ls_bom_head>-stlnr.
*
*      lv_ebelp += 10.
*
*      "CAL의 입력 타입에 맞춰 직접 구성자재의 필요수량 구성
*      DATA(ls_component_item) = VALUE zsmma00060(
*        matnr = <ls_bom_item>-idnrk
*        werks = <ls_purchase_item>-werks
*        lgort = <ls_purchase_item>-lgort
*        menge = <ls_purchase_item>-menge * <ls_bom_item>-menge
*        meins = <ls_bom_item>-meins
*      ).
*
*      "이전 구성자재의 반환 결과가 섞이지 않도록 초기화
*      CLEAR: lt_order_temp, lt_reserve_temp, lv_error.
*
*      CALL FUNCTION 'ZFM_MM_BOM_CAL'
*        EXPORTING
*          bom_head         = lt_bom_head
*          bom_item         = lt_bom_item
*          purchase_item    = ls_component_item
*          iv_ebeln         = <ls_purchase_item>-ebeln
*          iv_ebelp         = <ls_purchase_item>-ebelp
*          procure_cond     = lt_procure_cond
*          my_ebeln         = lv_ebeln
*          my_ebelp         = lv_ebelp
*        IMPORTING
*          purchase_order   = lt_order_temp
*          purchase_reserve = lt_reserve_temp
*        TABLES
*          et_return        = et_return
*        CHANGING
*          stock_detail     = lt_stock
*          cv_error         = lv_error.
*
*      "하위 계산 실패 시 전체 처리를 저장 전에 중단
*      IF lv_error = abap_true.
*        append_error TEXT-t37.
*        RETURN.
*      ENDIF.
*
*      "성공한 구성자재의 추가 PO와 예약 결과 누적
*      LOOP AT lt_order_temp ASSIGNING FIELD-SYMBOL(<ls_order_temp>).
*        <ls_order_temp>-banfn = <ls_purchase_item>-banfn.
*        <ls_order_temp>-bnfpo = <ls_purchase_item>-bnfpo.
*      ENDLOOP.
*
*      "이번 호출에서 생성된 예약행에만 원본 PR 키 연결
*      LOOP AT lt_reserve_temp ASSIGNING FIELD-SYMBOL(<ls_reserve_temp>).
*        <ls_reserve_temp>-banfn = <ls_purchase_item>-banfn.
*        <ls_reserve_temp>-bnfpo = <ls_purchase_item>-bnfpo.
*      ENDLOOP.
*
*      APPEND LINES OF lt_order_temp TO lt_purchase_order.
*      APPEND LINES OF lt_reserve_temp TO lt_purchase_reserve.
*
*    ENDLOOP.
*
*  ENDLOOP.
*
*  purchase_order   = lt_purchase_order.
*  purchase_reserve = lt_purchase_reserve.
*  stock            = lt_stock.
*
*ENDFUNCTION.
