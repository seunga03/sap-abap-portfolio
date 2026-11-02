FUNCTION zfm_mm_subc_reserve.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(PURCHASE_RESERVE) TYPE  ZTTMMA00160
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  DATA: lt_reserve TYPE zttmma00160,
        lt_header  TYPE STANDARD TABLE OF ztmma00080,
        lt_item    TYPE zttmma00090,
        lt_item_db TYPE STANDARD TABLE OF ztmma00090,
        lt_return  TYPE STANDARD TABLE OF bapiret2,
        lv_parent  TYPE ebeln,
        lv_mblnr   TYPE ztmma00080-mblnr,
        lv_mjahr   TYPE ztmma00080-mjahr,
        lv_toyear  TYPE inri-toyear,
        lv_zeile   TYPE ztmma00090-zeile.

*--------------------------------------------------------------------*
* 1. 기존 창고에서 실제 확보한 예약분만 문서화한다.
*--------------------------------------------------------------------*
  LOOP AT purchase_reserve ASSIGNING FIELD-SYMBOL(<ls_source>)
    WHERE rsqty > 0.
    IF <ls_source>-lgort IS INITIAL
       OR <ls_source>-ebeln IS INITIAL
       OR <ls_source>-ebelp IS INITIAL.
      APPEND VALUE #( type = 'E'
        message = '외주 예약에 부모 PO 품목 또는 실제 창고 정보가 없습니다.' )
        TO et_return.
      RETURN.
    ENDIF.
    APPEND <ls_source> TO lt_reserve.
  ENDLOOP.

  IF lt_reserve IS INITIAL.
    RETURN.
  ENDIF.

  SORT lt_reserve BY ebeln ebelp matnr werks lgort.
  lv_mjahr = sy-datum+0(4).
  lv_toyear = lv_mjahr.

*--------------------------------------------------------------------*
* 2. 부모 PO별 자재문서 헤더와 아이템 생성
*--------------------------------------------------------------------*
  LOOP AT lt_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>).
    IF lv_parent <> <ls_reserve>-ebeln.
      CLEAR: lv_mblnr, lv_zeile.

      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING
          nr_range_nr = '01'
          object      = 'ZMM_MBLNR'
          toyear      = lv_toyear
        IMPORTING
          number      = lv_mblnr
        EXCEPTIONS
          OTHERS      = 8.
      IF sy-subrc <> 0.
        APPEND VALUE #( type = 'E'
          message = '외주 예약 자재문서 번호 채번에 실패했습니다.' ) TO et_return.
        RETURN.
      ENDIF.

      APPEND VALUE #(
        mandt = sy-mandt
        mblnr = lv_mblnr
        mjahr = lv_mjahr
        bldat = sy-datum
        budat = sy-datum
        usnam = sy-uname
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit
      ) TO lt_header.
      lv_parent = <ls_reserve>-ebeln.
    ENDIF.

    IF lv_zeile > 99989.
      APPEND VALUE #( type = 'E'
        message = '자재문서 품목번호 범위를 초과했습니다.' ) TO et_return.
      RETURN.
    ENDIF.
    lv_zeile += 10.

    APPEND VALUE #(
      mblnr = lv_mblnr
      mjahr = lv_mjahr
      zeile = lv_zeile
      ebeln = <ls_reserve>-ebeln
      ebelp = <ls_reserve>-ebelp
      matnr = <ls_reserve>-matnr
      werks = <ls_reserve>-werks
      lgort = <ls_reserve>-lgort
      menge = <ls_reserve>-rsqty
      meins = <ls_reserve>-meins
      bwart = '653'
      ernam = sy-uname
      erdat = sy-datum
      erzet = sy-uzeit
    ) TO lt_item.
  ENDLOOP.

*--------------------------------------------------------------------*
* 3. 자재이동 문서 저장
*--------------------------------------------------------------------*
  MODIFY ztmma00080 FROM TABLE lt_header.
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'E'
      message = '외주 예약 자재문서 헤더 저장에 실패했습니다.' ) TO et_return.
    RETURN.
  ENDIF.

  MOVE-CORRESPONDING lt_item TO lt_item_db.
  MODIFY ztmma00090 FROM TABLE lt_item_db.
  IF sy-subrc <> 0.
    APPEND VALUE #( type = 'E'
      message = '외주 예약 자재문서 아이템 저장에 실패했습니다.' ) TO et_return.
    RETURN.
  ENDIF.

*--------------------------------------------------------------------*
* 4. 실제 재고 변경은 기존 재고 FM에서만 처리한다.
*--------------------------------------------------------------------*
  CALL FUNCTION 'ZFM_MM_MATERIAL_STOCK'
    EXPORTING
      move_material = lt_item
    TABLES
      et_return     = lt_return.

  APPEND LINES OF lt_return TO et_return.
  IF line_exists( lt_return[ type = 'E' ] )
     OR line_exists( lt_return[ type = 'A' ] ).
    RETURN.
  ENDIF.

* 여기서 COMMIT/ROLLBACK하지 않는다. 전체 PR/PO 처리와 같은 LUW다.
ENDFUNCTION.
