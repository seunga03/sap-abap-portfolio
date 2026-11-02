FUNCTION zfm_mm_material_reserve.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(SALES_HEADER) TYPE  ZTTSDA00010 OPTIONAL
*"     REFERENCE(SALES_ITEM) TYPE  ZTTSDA00020 OPTIONAL
*"  EXPORTING
*"     REFERENCE(RESERVE_MATERIAL) TYPE  ZTTMMA00090
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  DATA: lt_mma080       TYPE TABLE OF ztmma00080,
        lt_mma090       TYPE TABLE OF ztmma00090,
        lt_stock        TYPE zttmma00070,
        lt_update_stock TYPE zttmma00070,
        lt_stock_key    LIKE sales_item,
        lt_return       TYPE TABLE OF bapiret2.

  DATA: ls_return       TYPE bapiret2,
        lv_zeile        TYPE ztmma00090-zeile,
        lv_number       TYPE ztmma00080-mblnr,
        lv_reserve_qty  TYPE ztmma00090-menge,
        lv_has_shortage TYPE abap_bool,
        lv_head_created TYPE abap_bool.

  CLEAR reserve_material.

*--------------------------------------------------------------------*
* 1. 입력값 검증
*--------------------------------------------------------------------*
  IF sales_header IS INITIAL OR sales_item IS INITIAL.
*    CLEAR ls_return.
*    ls_return-type    = 'E'.
**    ls_return-message = '판매오더 헤더 또는 아이템 정보가 없습니다.'.
*    ls_return-message = TEXT-t09.
*    APPEND ls_return TO et_return.
    append_error TEXT-t09.
    RETURN.
  ENDIF.

  LOOP AT sales_item ASSIGNING FIELD-SYMBOL(<ls_so_item>).

    IF <ls_so_item>-kwmeng <= 0.
      CLEAR ls_return.
*      ls_return-type    = 'E'.
**      ls_return-message = '주문수량은 0보다 커야 합니다.'.
*      ls_return-message = TEXT-t10.
*      APPEND ls_return TO et_return.
      append_error TEXT-t10.
      RETURN.
    ENDIF.

    READ TABLE sales_header TRANSPORTING NO FIELDS
      WITH KEY vbeln = <ls_so_item>-vbeln.

    IF sy-subrc <> 0.
*      CLEAR ls_return.
*      ls_return-type    = 'E'.
**      ls_return-message = '판매오더 헤더와 아이템 정보가 일치하지 않습니다.'.
*      ls_return-message = TEXT-t11.
*      APPEND ls_return TO et_return.
      append_error TEXT-t11.
      RETURN.
    ENDIF.

  ENDLOOP.

*--------------------------------------------------------------------*
* 2. 예약 대상 재고 조회
*--------------------------------------------------------------------*
  lt_stock_key = sales_item.

  SORT lt_stock_key BY matnr werks lgort.
  DELETE ADJACENT DUPLICATES FROM lt_stock_key
    COMPARING matnr werks lgort.

  SELECT *
    FROM ztmma00070
    INTO CORRESPONDING FIELDS OF TABLE @lt_stock
    FOR ALL ENTRIES IN @lt_stock_key
    WHERE matnr = @lt_stock_key-matnr
      AND werks = @lt_stock_key-werks
      AND lgort = @lt_stock_key-lgort.

*--------------------------------------------------------------------*
* 3. SO별 예약 자재이동문서 생성
*--------------------------------------------------------------------*
  LOOP AT sales_header ASSIGNING FIELD-SYMBOL(<ls_so_header>).

    READ TABLE sales_item TRANSPORTING NO FIELDS
      WITH KEY vbeln = <ls_so_header>-vbeln.

    IF sy-subrc <> 0.
*      CLEAR ls_return.
*      ls_return-type    = 'E'.
**      ls_return-message = '판매오더에 예약할 아이템이 없습니다.'.
*      ls_return-message = TEXT-t12.
*      APPEND ls_return TO et_return.
      append_error TEXT-t12.
      RETURN.
    ENDIF.

    CLEAR: lv_zeile,
           lv_number,
           lv_head_created.

    LOOP AT sales_item ASSIGNING <ls_so_item>
      WHERE vbeln = <ls_so_header>-vbeln.

      READ TABLE lt_stock ASSIGNING FIELD-SYMBOL(<ls_stock>)
        WITH KEY matnr = <ls_so_item>-matnr
                 werks = <ls_so_item>-werks
                 lgort = <ls_so_item>-lgort.

      IF sy-subrc <> 0.
*        CLEAR ls_return.
*        ls_return-type    = 'E'.
**        ls_return-message = '재고 현황이 없습니다. 재고 초기등록을 먼저 진행하세요.'.
*        ls_return-message = TEXT-t13.
*        APPEND ls_return TO et_return.
        append_error TEXT-t13.
        RETURN.
      ENDIF.

*     예약수량 = MIN(가용재고, 주문수량)
      IF <ls_stock>-stqty >= <ls_so_item>-kwmeng.
        lv_reserve_qty = <ls_so_item>-kwmeng.
      ELSE.
        lv_reserve_qty = <ls_stock>-stqty.
      ENDIF.

*     예약 가능한 수량이 있으면 652 자재이동문서 생성
      IF lv_reserve_qty > 0.

        IF lv_head_created IS INITIAL.

          CALL FUNCTION 'NUMBER_GET_NEXT'
            EXPORTING
              nr_range_nr             = '01'
              object                  = 'ZMM_MBLNR'
              quantity                = '1'
              toyear                  = sy-datum+0(4)
            IMPORTING
              number                  = lv_number
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
*            CLEAR ls_return.
*            ls_return-type    = 'E'.
**            ls_return-message = '예약 자재이동문서 채번 오류.'.
*            ls_return-message = TEXT-t14.
*            APPEND ls_return TO et_return.
            append_error TEXT-t14.
            RETURN.
          ENDIF.

          APPEND INITIAL LINE TO lt_mma080 ASSIGNING FIELD-SYMBOL(<ls_mma080>).

          <ls_mma080>-mblnr = lv_number.
          <ls_mma080>-mjahr = sy-datum+0(4).
          <ls_mma080>-bldat = sy-datum.
          <ls_mma080>-budat = sy-datum.
          <ls_mma080>-usnam = sy-uname.
          <ls_mma080>-erdat = sy-datum.
          <ls_mma080>-erzet = sy-uzeit.
          <ls_mma080>-ernam = sy-uname.

          lv_head_created = abap_true.

        ENDIF.

        ADD 10 TO lv_zeile.

        APPEND INITIAL LINE TO lt_mma090 ASSIGNING FIELD-SYMBOL(<ls_mma090>).

        <ls_mma090>-mblnr = lv_number.
        <ls_mma090>-mjahr = sy-datum+0(4).
        <ls_mma090>-zeile = lv_zeile.
        <ls_mma090>-vbeln_so = <ls_so_item>-vbeln.
        <ls_mma090>-posnr = <ls_so_item>-posnr.
        <ls_mma090>-matnr = <ls_so_item>-matnr.
        <ls_mma090>-werks = <ls_so_item>-werks.
        <ls_mma090>-lgort = <ls_so_item>-lgort.
        <ls_mma090>-menge = lv_reserve_qty.
        <ls_mma090>-meins = <ls_so_item>-meins.
        <ls_mma090>-bwart = '652'.
        <ls_mma090>-erdat = sy-datum.
        <ls_mma090>-erzet = sy-uzeit.
        <ls_mma090>-ernam = sy-uname.

*       같은 호출 안에서 동일 재고를 중복 예약하지 않도록 가용재고 차감
        <ls_stock>-stqty -= lv_reserve_qty.

      ENDIF.

*     부족수량이 있으면 W 반환
      IF lv_reserve_qty < <ls_so_item>-kwmeng.
        lv_has_shortage = abap_true.

        CLEAR ls_return.
        ls_return-type    = 'W'.
        ls_return-message = |{ <ls_so_item>-vbeln }  { <ls_so_item>-posnr }의 예약수량이 부족합니다.|.
        APPEND ls_return TO et_return.
      ENDIF.

    ENDLOOP.

  ENDLOOP.

*--------------------------------------------------------------------*
* 4. 전량 미예약이면 문서와 재고 저장 없이 W만 반환
*--------------------------------------------------------------------*
  IF lt_mma090 IS INITIAL.
    RETURN.
  ENDIF.

*--------------------------------------------------------------------*
* 5. 재고 변경안 계산
*    STOCK FM에 652 로직을 추가하면 STQTY 감소, RSQTY 증가 처리됨
*--------------------------------------------------------------------*
  CALL FUNCTION 'ZFM_MM_MATERIAL_STOCK'
    EXPORTING
      move_material  = lt_mma090
    IMPORTING
      material_stock = lt_update_stock
    TABLES
      et_return      = lt_return.

  READ TABLE lt_return TRANSPORTING NO FIELDS
    WITH KEY type = 'E'.

  IF sy-subrc = 0.
    APPEND LINES OF lt_return TO et_return.
    RETURN.
  ENDIF.

*--------------------------------------------------------------------*
* 6. 자재이동문서 및 재고 저장
*--------------------------------------------------------------------*
  MODIFY ztmma00080 FROM TABLE lt_mma080.
  IF sy-subrc <> 0.
*    CLEAR ls_return.
*    ls_return-type    = 'E'.
**    ls_return-message = '예약 자재이동문서 헤더 저장 실패.'.
*    ls_return-message = TEXT-t15.
*    APPEND ls_return TO et_return.
    append_error TEXT-t15.
    RETURN.
  ENDIF.

  MODIFY ztmma00090 FROM TABLE lt_mma090.
  IF sy-subrc <> 0.
*    CLEAR ls_return.
*    ls_return-type    = 'E'.
**    ls_return-message = '예약 자재이동문서 아이템 저장 실패.'.
*    ls_return-message = TEXT-t16.
*    APPEND ls_return TO et_return.
    append_error TEXT-t16.
    RETURN.
  ENDIF.

*--------------------------------------------------------------------*
* 7. SD에 실제 예약된 652 자재이동 아이템 반환
*--------------------------------------------------------------------*
  reserve_material = lt_mma090.

  IF lv_has_shortage IS INITIAL.
*    CLEAR ls_return.
*    ls_return-type    = 'S'.
**    ls_return-message = '판매오더 재고 예약이 완료되었습니다.'.
*    ls_return-message = TEXT-t17.
*    APPEND ls_return TO et_return.
        CLEAR ls_return.
    ls_return-type    = 'S'.
    ls_return-message = TEXT-t17.
    APPEND ls_return TO et_return.
  ENDIF.

ENDFUNCTION.
