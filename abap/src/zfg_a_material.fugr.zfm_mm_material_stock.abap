FUNCTION zfm_mm_material_stock.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(MOVE_MATERIAL) TYPE  ZTTMMA00090
*"  EXPORTING
*"     REFERENCE(MATERIAL_STOCK) TYPE  ZTTMMA00070
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
  DEFINE append_error.
    CLEAR ls_return.
    ls_return-type    = 'E'.
    ls_return-message = &1.
    APPEND ls_return TO et_return.
  END-OF-DEFINITION.

  DATA : lt_move_key LIKE move_material.
  DATA : ls_return TYPE bapiret2.
  DATA : lt_so_stock TYPE zttmma00150.
  DATA : lt_so_move TYPE zttmma00090.
  DATA : lt_po_stock TYPE zttmma00090.
  DATA : lt_160      TYPE zttmma00160.
  DATA : lt_new_move TYPE zttmma00090.
  DATA : lt_new_head TYPE TABLE OF ztmma00080.
  DATA lt_050 TYPE zttmma00050.
  DATA lt_050_lock TYPE zttmma00050.
  DATA: lt_reserve_save  TYPE TABLE OF ztmma00160,
        lt_po_head_save  TYPE TABLE OF ztmma00050,
        lt_new_move_save TYPE TABLE OF ztmma00090,
        lt_stock_save    TYPE TABLE OF ztmma00070.

  DATA : lv_lock TYPE abap_bool.

  CLEAR material_stock.
  lt_move_key = move_material.
  SORT lt_move_key BY matnr werks lgort.

  DELETE ADJACENT DUPLICATES FROM lt_move_key
    COMPARING matnr werks lgort.

  IF lt_move_key IS INITIAL.
    RETURN.
  ENDIF.

*&----------------------------------------------------------------
*& 10/23일 수정본
*&----------------------------------------------------------------

*  PERFORM zz_get_so_stock USING move_material
*                       CHANGING lt_so_stock.
  LOOP AT move_material ASSIGNING FIELD-SYMBOL(<ls_so_move>).
    IF <ls_so_move>-bwart = '651' OR <ls_so_move>-bwart = '652' OR <ls_so_move>-bwart = '322'.
      APPEND <ls_so_move> TO lt_so_move.
    ELSEIF <ls_so_move>-bwart = '654' OR <ls_so_move>-bwart = '653'.
      APPEND <ls_so_move> TO lt_po_stock.
    ENDIF.
  ENDLOOP.

  PERFORM zz_set_lock USING move_material
                   CHANGING lv_lock.
  IF lv_lock IS NOT INITIAL.
    append_error TEXT-t39.  "락 오류 메시지인지 확인
    RETURN.
  ENDIF.

  IF lt_so_move IS NOT INITIAL.
    PERFORM zz_get_so_stock USING lt_so_move
                           CHANGING lt_so_stock.
  ENDIF.

  IF lt_po_stock IS NOT INITIAL.
    PERFORM zz_get_po_stock USING lt_po_stock
                         CHANGING lt_160
                                  lt_050_lock
                                  lv_lock.
  ENDIF.


  IF lv_lock IS NOT INITIAL.

  ENDIF.
  "지급 시 함께 차감할 형제 구성자재/다른 창고 재고까지 조회키에 포함한다.
  LOOP AT lt_160 ASSIGNING FIELD-SYMBOL(<ls_stock_key>).
    APPEND VALUE #(
      matnr = <ls_stock_key>-matnr werks = <ls_stock_key>-werks
      lgort = <ls_stock_key>-lgort
    ) TO lt_move_key.
  ENDLOOP.
  SORT lt_move_key BY matnr werks lgort.
  DELETE ADJACENT DUPLICATES FROM lt_move_key COMPARING matnr werks lgort.

  SELECT * FROM ztmma00070
    FOR ALL ENTRIES IN @lt_move_key
    WHERE matnr = @lt_move_key-matnr
      AND werks = @lt_move_key-werks AND lgort = @lt_move_key-lgort
    INTO CORRESPONDING FIELDS OF TABLE @material_stock.

  LOOP AT move_material ASSIGNING FIELD-SYMBOL(<ls_move_material>).

    READ TABLE material_stock ASSIGNING FIELD-SYMBOL(<ls_material_stock>)
      WITH KEY matnr = <ls_move_material>-matnr
               werks = <ls_move_material>-werks
               lgort = <ls_move_material>-lgort.
    IF sy-subrc <> 0.
      append_error TEXT-t18.

      RETURN.
    ENDIF.
    IF <ls_move_material>-menge <= 0
       OR <ls_move_material>-meins <> <ls_material_stock>-meins.
      append_error TEXT-t38.
      RETURN.
    ENDIF.
    CASE <ls_move_material>-bwart.
      WHEN '654'. "BOM 검사 합격분: 검사대기 -> 예약
        IF <ls_material_stock>-qisty < <ls_move_material>-menge.
          append_error TEXT-t25.
          RETURN.
        ENDIF.
        READ TABLE lt_160 ASSIGNING FIELD-SYMBOL(<ls_160_654>)
          WITH KEY ebeln = <ls_move_material>-ebeln
                   ebelp = <ls_move_material>-ebelp
                   matnr = <ls_move_material>-matnr
                   werks = <ls_move_material>-werks
                   lgort = <ls_move_material>-lgort.
        IF sy-subrc <> 0.
          append_error TEXT-t38.
          RETURN.
        ENDIF.
        IF <ls_160_654>-rstat = '0020'
           OR <ls_160_654>-meins <> <ls_move_material>-meins
           OR <ls_160_654>-rsqty + <ls_move_material>-menge
                > <ls_160_654>-reqty.
          append_error TEXT-t38.
          RETURN.
        ENDIF.
        <ls_material_stock>-qisty -= <ls_move_material>-menge.
        <ls_material_stock>-rsqty += <ls_move_material>-menge.
        <ls_material_stock>-aenam = sy-uname.
        <ls_material_stock>-aedat = sy-datum.
        <ls_material_stock>-aezet = sy-uzeit.
        <ls_160_654>-rsqty += <ls_move_material>-menge.
        <ls_160_654>-rstat = '0010'.
        <ls_160_654>-aenam = sy-uname.
        <ls_160_654>-aedat = sy-datum.
        <ls_160_654>-aezet = sy-uzeit.

      WHEN '101'. "입고
        <ls_material_stock>-qisty += <ls_move_material>-menge.
        <ls_material_stock>-aenam = sy-uname.
        <ls_material_stock>-aedat = sy-datum.
        <ls_material_stock>-aezet = sy-uzeit.

      WHEN '651'. "출고는 무조건 예약재고를 통해서 출고
        "GI FM에서 예약 재고 묶어서 출고하면 될듯 함.
        "자재이동문서 읽고 sd 물량 다 있으면 출고임.
        IF <ls_material_stock>-rsqty < <ls_move_material>-menge.
*          append_error '예약 재고가 부족합니다.'.
          append_error TEXT-t19.
          RETURN.
        ENDIF.
        READ TABLE lt_so_stock WITH KEY vbeln = <ls_move_material>-vbeln_so
                                        posnr = <ls_move_material>-posnr
                                        ASSIGNING FIELD-SYMBOL(<ls_so_stock_651>).
        IF sy-subrc <> 0.
*          append_error '판매오더 예약재고 현황이 없습니다.'.
          append_error TEXT-t20.
          RETURN.
        ENDIF.
        IF <ls_material_stock>-rsqty < <ls_move_material>-menge
        OR <ls_so_stock_651>-avlqt < <ls_move_material>-menge.
*          append_error '판매오더 예약재고가 부족합니다.'.
          append_error TEXT-t21.
          RETURN.
        ENDIF.
        <ls_material_stock>-rsqty -= <ls_move_material>-menge.
        <ls_material_stock>-aenam = sy-uname.
        <ls_material_stock>-aedat = sy-datum.
        <ls_material_stock>-aezet = sy-uzeit.

        <ls_so_stock_651>-sumqt += <ls_move_material>-menge.
        <ls_so_stock_651>-avlqt -= <ls_move_material>-menge.
        <ls_so_stock_651>-aenam = sy-uname.
        <ls_so_stock_651>-aedat = sy-datum.
        <ls_so_stock_651>-aezet = sy-uzeit.
      WHEN '653'. "BOM 확보: 가용 -> 예약
        "신규 160을 먼저 저장한 생성 FORM과 한 세트로 적용한다.
        READ TABLE lt_160 ASSIGNING FIELD-SYMBOL(<ls_160_653>)
          WITH KEY ebeln = <ls_move_material>-ebeln
                   ebelp = <ls_move_material>-ebelp
                   matnr = <ls_move_material>-matnr
                   werks = <ls_move_material>-werks
                   lgort = <ls_move_material>-lgort.
        IF sy-subrc <> 0.
          append_error TEXT-t38.
          RETURN.
        ENDIF.
        IF <ls_160_653>-rstat = '0020'
           OR <ls_160_653>-meins <> <ls_move_material>-meins
           OR <ls_move_material>-menge <> <ls_160_653>-rsqty.
          append_error TEXT-t38.
          RETURN.
        ENDIF.
        IF <ls_material_stock>-stqty < <ls_move_material>-menge.
          append_error TEXT-t22.
          RETURN.
        ENDIF.

        <ls_material_stock>-stqty -= <ls_move_material>-menge.
        <ls_material_stock>-rsqty += <ls_move_material>-menge.
        <ls_material_stock>-aenam = sy-uname.
        <ls_material_stock>-aedat = sy-datum.
        <ls_material_stock>-aezet = sy-uzeit.
      WHEN '652'. "예약 재고 증가
        IF <ls_material_stock>-stqty < <ls_move_material>-menge.
*          append_error '현재고 수량이 부족합니다.'.
          append_error TEXT-t22.
          RETURN.
        ENDIF.

        READ TABLE lt_so_stock WITH KEY vbeln = <ls_move_material>-vbeln_so
                                posnr = <ls_move_material>-posnr
                                ASSIGNING FIELD-SYMBOL(<ls_so_stock_652>).
        IF sy-subrc <> 0.
*          append_error '판매오더 예약재고 현황이 없습니다.'.
          append_error TEXT-t23.
          RETURN.

        ENDIF.
        <ls_material_stock>-rsqty += <ls_move_material>-menge.
        <ls_material_stock>-stqty -= <ls_move_material>-menge.
        <ls_material_stock>-aenam = sy-uname.
        <ls_material_stock>-aedat = sy-datum.
        <ls_material_stock>-aezet = sy-uzeit.

        <ls_so_stock_652>-avlqt += <ls_move_material>-menge.
        <ls_so_stock_652>-aenam = sy-uname.
        <ls_so_stock_652>-aedat = sy-datum.
        <ls_so_stock_652>-aezet = sy-uzeit.

      WHEN '650'. "반품, 환불

        IF <ls_material_stock>-qisty < <ls_move_material>-menge.
*          append_error '검사대기 재고 수량이 부족합니다.'.
          append_error TEXT-t24.
          RETURN.
        ENDIF.

        <ls_material_stock>-qisty -= <ls_move_material>-menge.
        <ls_material_stock>-aenam = sy-uname.
        <ls_material_stock>-aedat = sy-datum.
        <ls_material_stock>-aezet = sy-uzeit.

      WHEN '321'.
        IF <ls_material_stock>-qisty < <ls_move_material>-menge.
*          append_error '검사대기 재고 수량이 부족합니다.'.
          append_error TEXT-t25.
          RETURN.
        ENDIF.

        <ls_material_stock>-qisty -= <ls_move_material>-menge.
        <ls_material_stock>-stqty += <ls_move_material>-menge.
        <ls_material_stock>-aenam = sy-uname.
        <ls_material_stock>-aedat = sy-datum.
        <ls_material_stock>-aezet = sy-uzeit.
      WHEN '322'. "SO 기반 PR - 검사 합격분 바로 예약 재고로
        IF <ls_material_stock>-qisty < <ls_move_material>-menge.
*          append_error '검사대기 재고 수량이 부족합니다.'.
          append_error TEXT-t26.
          RETURN.
        ENDIF.
        READ TABLE lt_so_stock WITH KEY vbeln = <ls_move_material>-vbeln_so
                                        posnr = <ls_move_material>-posnr
                                        ASSIGNING FIELD-SYMBOL(<ls_so_stock>).

        IF sy-subrc <> 0.
*          append_error '판매오더 예약재고 현황이 없습니다.'.
          append_error TEXT-t27.
          RETURN.
        ENDIF.

        <ls_material_stock>-qisty -= <ls_move_material>-menge.
        <ls_material_stock>-rsqty += <ls_move_material>-menge.
        <ls_material_stock>-aenam = sy-uname.
        <ls_material_stock>-aedat = sy-datum.
        <ls_material_stock>-aezet = sy-uzeit.
        <ls_so_stock>-avlqt += <ls_move_material>-menge.
        <ls_so_stock>-aenam = sy-uname.
        <ls_so_stock>-aedat = sy-datum.
        <ls_so_stock>-aezet = sy-uzeit.
      WHEN OTHERS.
        append_error TEXT-t28.
        RETURN.
    ENDCASE.
  ENDLOOP.

  "모든 653/654 확보를 반영한 뒤 부모 품목 전체를 한 번씩 지급 판정한다.
  IF lt_160 IS NOT INITIAL.
    PERFORM zz_bom_release
      CHANGING lt_160 material_stock lt_new_head lt_new_move lt_050 et_return[].
    IF line_exists( et_return[ type = 'E' ] )
       OR line_exists( et_return[ type = 'A' ] )
       OR line_exists( et_return[ type = 'X' ] ).
      RETURN.
    ENDIF.
  ENDIF.

  lt_reserve_save = CORRESPONDING #( lt_160 ).
  lt_po_head_save = CORRESPONDING #( lt_050 ).
  lt_new_move_save = CORRESPONDING #( lt_new_move ).
  lt_stock_save = CORRESPONDING #( material_stock ).

  "저장 실패는 반드시 반환하며 기존 호출부에서 전체 LUW를 ROLLBACK한다.
  IF lt_reserve_save IS NOT INITIAL.
    MODIFY ztmma00160 FROM TABLE lt_reserve_save.
    IF sy-subrc <> 0.
      append_error TEXT-t30.
      RETURN.
    ENDIF.
  ENDIF.
  IF lt_new_head IS NOT INITIAL.
    MODIFY ztmma00080 FROM TABLE lt_new_head.
    IF sy-subrc <> 0.
      append_error TEXT-t30.
      RETURN.
    ENDIF.
  ENDIF.
  IF lt_new_move_save IS NOT INITIAL.
    MODIFY ztmma00090 FROM TABLE lt_new_move_save.
    IF sy-subrc <> 0.
      append_error TEXT-t30.
      RETURN.
    ENDIF.
  ENDIF.
  IF lt_po_head_save IS NOT INITIAL.
    MODIFY ztmma00050 FROM TABLE lt_po_head_save.
    IF sy-subrc <> 0.
      append_error TEXT-t30.
      RETURN.
    ENDIF.
  ENDIF.
  IF lt_so_stock IS NOT INITIAL.
    MODIFY ztmma00150 FROM TABLE lt_so_stock.
    IF sy-subrc <> 0.
      append_error TEXT-t29.
      RETURN.
    ENDIF.
  ENDIF.

  "70 저장은 기존 재고 FM의 이 위치에서 수행한다. 성공 후 외부에서 COMMIT한다.
  MODIFY ztmma00070 FROM TABLE lt_stock_save.
  IF sy-subrc <> 0.
    append_error TEXT-t30.
    RETURN.
  ENDIF.
ENDFUNCTION.
