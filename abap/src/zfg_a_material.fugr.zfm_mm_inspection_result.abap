FUNCTION zfm_mm_inspection_result .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(RESULT_INPUT) TYPE  ZTTMMA00131
*"  EXPORTING
*"     REFERENCE(INSPECTION_HEADER) TYPE  ZTTMMA00120
*"     REFERENCE(INSPECTION_ITEM) TYPE  ZTTMMA00130
*"     REFERENCE(RESULT_MATERIAL) TYPE  ZTTMMA00090
*"     REFERENCE(MATERIAL_STOCK) TYPE  ZTTMMA00070
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
*  DEFINE append_error.
*    CLEAR ls_return.
*    ls_return-type    = 'E'.
*    ls_return-message = &1.
*    APPEND ls_return TO et_return.
*  END-OF-DEFINITION.

  TYPES : BEGIN OF ty_get_po,
            ebeln TYPE ztmma00060-ebeln,
            ebelp TYPE ztmma00060-ebelp,
          END OF ty_get_po.

  DATA : lv_inspn TYPE ztmma00120-inspn.
  DATA : lv_inspp TYPE ztmma00130-inspp.
  DATA : lt_mat_item TYPE zttmma00090.
  DATA : lt_mat_head TYPE TABLE OF ztmma00080.
  DATA : lv_zeile TYPE ztmma00090-zeile.
  DATA : lv_mblnr TYPE ztmma00090-mblnr.
  DATA : lt_stock TYPE zttmma00070.
  DATA : ls_return TYPE bapiret2.
  DATA : lt_return TYPE TABLE OF bapiret2.

  DATA : lv_vbeln_so TYPE ztmma00090-vbeln_so,
         lv_posnr    TYPE ztmma00090-posnr.

  DATA : lt_po TYPE SORTED TABLE OF ty_get_po WITH UNIQUE KEY ebeln ebelp.
  DATA : lv_bwart TYPE bwart.
  "품질 검사 헤더 만들기"
  LOOP AT result_input ASSIGNING FIELD-SYMBOL(<ls_result>).
    READ TABLE inspection_header ASSIGNING FIELD-SYMBOL(<ls_header>) WITH KEY mblnr = <ls_result>-mblnr
                                                                              mjahr = <ls_result>-mjahr.
    CLEAR : lv_inspn.
    IF sy-subrc <> 0.
      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING
          nr_range_nr = '01'
          object      = 'ZMM_INSPN'
        IMPORTING
          number      = lv_inspn.
      APPEND VALUE #(
        inspn = lv_inspn
        mblnr = <ls_result>-mblnr
        mjahr = <ls_result>-mjahr
        insdt = sy-datum
        insby = sy-uname
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit
      ) TO inspection_header.
    ELSE.

    ENDIF.

    INSERT VALUE #(
      ebeln = <ls_result>-ebeln
      ebelp = <ls_result>-ebelp
    ) INTO TABLE lt_po.
  ENDLOOP.

  "품질 검사 아이템 만들기"
  LOOP AT inspection_header ASSIGNING FIELD-SYMBOL(<ls_header_1>).
    lv_inspp = 10.
    LOOP AT result_input ASSIGNING FIELD-SYMBOL(<ls_result_1>) WHERE mblnr = <ls_header_1>-mblnr
                                                               AND mjahr = <ls_header_1>-mjahr.

      APPEND VALUE #(
        inspn = <ls_header_1>-inspn
        inspp = lv_inspp
        matnr = <ls_result_1>-matnr
        gritm = <ls_result_1>-gritm
        insqt = <ls_result_1>-insqt
        pasqt = <ls_result_1>-pasqt
        faiqt = <ls_result_1>-faiqt
        meins = <ls_result_1>-meins
        reslt = <ls_result_1>-reslt
        defcd = <ls_result_1>-defcd
        deftx = <ls_result_1>-deftx
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit
      ) TO inspection_item.

      lv_inspp += 10.
    ENDLOOP.
  ENDLOOP.

  IF lt_po IS NOT INITIAL.
    SELECT ebeln, ebelp, banfn, bnfpo, ptype
      FROM ztmma00060
      FOR ALL ENTRIES IN @lt_po
      WHERE ebeln = @lt_po-ebeln
        AND ebelp = @lt_po-ebelp
      INTO TABLE @DATA(lt_po_item).
  ENDIF.


  "" SO 생성건인지 확인
  IF lt_po_item IS NOT INITIAL.
    SELECT banfn, bnfpo, srtyp, srdoc, sritm
      FROM ztmma00040
      FOR ALL ENTRIES IN @lt_po_item
      WHERE banfn = @lt_po_item-banfn
        AND bnfpo = @lt_po_item-bnfpo
      INTO TABLE @DATA(lt_pr).
  ENDIF.

  "자재 이동 문서 만들기
  LOOP AT result_input ASSIGNING FIELD-SYMBOL(<ls_result_2>).
    CLEAR : lv_vbeln_so, lv_posnr.
    lv_bwart = '321'.
    lv_zeile = 0.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr = '01'
        object      = 'ZMM_MBLNR'
        toyear      = sy-datum+0(4)
      IMPORTING
        number      = lv_mblnr.

    READ TABLE lt_po_item ASSIGNING FIELD-SYMBOL(<ls_po_item>) WITH KEY ebeln = <ls_result_2>-ebeln
                                                                        ebelp = <ls_result_2>-ebelp.
    IF sy-subrc = 0.
      IF <ls_po_item>-ptype = '0030'.
        lv_bwart = '654'.
      ENDIF.

      READ TABLE lt_pr ASSIGNING FIELD-SYMBOL(<ls_pr>) WITH KEY banfn = <ls_po_item>-banfn
                                                                bnfpo = <ls_po_item>-bnfpo
                                                                srtyp = '0020'.
      IF sy-subrc = 0.
        lv_bwart = '322'.
        lv_vbeln_so = <ls_pr>-srdoc.
        lv_posnr = <ls_pr>-sritm.
      ENDIF.

    ENDIF.

    IF <ls_result_2>-pasqt > 0.
      lv_zeile += 10.
      APPEND VALUE #(
        mblnr = lv_mblnr
        mjahr = sy-datum+0(4)
        zeile = lv_zeile
        werks = <ls_result_2>-werks
        lgort = <ls_result_2>-lgort
        matnr = <ls_result_2>-matnr
        ebeln = <ls_result_2>-ebeln
        ebelp = <ls_result_2>-ebelp
        menge = <ls_result_2>-pasqt
        meins = <ls_result_2>-meins
        bwart = lv_bwart "바로 예약 재고로 변경
        posnr = lv_posnr
        vbeln_so = lv_vbeln_so
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit
      ) TO lt_mat_item.
    ENDIF.
    IF <ls_result_2>-faiqt > 0.
      lv_zeile += 10.
      APPEND VALUE #(
        mblnr = lv_mblnr
        mjahr = sy-datum+0(4)
        zeile = lv_zeile
        werks = <ls_result_2>-werks
        lgort = <ls_result_2>-lgort
        matnr = <ls_result_2>-matnr
        ebeln = <ls_result_2>-ebeln
        ebelp = <ls_result_2>-ebelp
        menge = <ls_result_2>-faiqt
        meins = <ls_result_2>-meins
        bwart = '650'
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit
      ) TO lt_mat_item.
    ENDIF.
    APPEND VALUE #(
      mblnr = lv_mblnr
      mjahr = sy-datum+0(4)
      bldat = sy-datum
      budat = sy-datum
      usnam = sy-uname
      ernam = sy-uname
      erdat = sy-datum
      erzet = sy-uzeit
    ) TO lt_mat_head.


  ENDLOOP.

  CALL FUNCTION 'ZFM_MM_PR_TRACKING'
    EXPORTING
      material_item = lt_mat_item
    TABLES
      et_return     = lt_return.

  READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
*    append_error TEXT-e04.
    et_return[] = lt_return[].
    RETURN.
  ENDIF.

  CALL FUNCTION 'ZFM_MM_MATERIAL_STOCK'
    EXPORTING
      move_material  = lt_mat_item
    IMPORTING
      material_stock = lt_stock
    TABLES
      et_return      = lt_return.

  READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
*  return.
  IF sy-subrc = 0.
    et_return[] = lt_return[].
*    append_error TEXT-e01.
    RETURN.
  ENDIF.
  IF line_exists( lt_return[ type = 'E' ] )
     OR line_exists( lt_return[ type = 'A' ] )
     OR line_exists( lt_return[ type = 'X' ] ).
    APPEND LINES OF lt_return TO et_return.
    RETURN.
  ENDIF.

  MODIFY ztmma00080 FROM TABLE lt_mat_head.
  IF sy-subrc <> 0.
    append_error TEXT-e02.
    RETURN.
  ENDIF.

  MODIFY ztmma00090 FROM TABLE lt_mat_item.
  IF sy-subrc <> 0.
    append_error TEXT-e02.
    RETURN.
  ENDIF.

  MODIFY ztmma00120 FROM TABLE inspection_header.
  IF sy-subrc <> 0.
    append_error TEXT-e03.
    RETURN.
  ENDIF.

  MODIFY ztmma00130 FROM TABLE inspection_item.
  IF sy-subrc <> 0.
    append_error TEXT-e03.
    RETURN.
  ENDIF.

ENDFUNCTION.
