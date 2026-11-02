FUNCTION zfm_mm_material_gi.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(GI_INPUT) TYPE  ZTTMMA00132
*"  EXPORTING
*"     REFERENCE(GI_MATERIAL) TYPE  ZTTMMA00090
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
*  DEFINE append_error.
*    CLEAR ls_return.
*    ls_return-type    = 'E'.
*    ls_return-message = &1.
*    APPEND ls_return TO et_return.
*  END-OF-DEFINITION.

  DATA : lt_gi       LIKE gi_input.
  DATA : lt_mat_head TYPE TABLE OF ztmma00080.
  DATA : lt_mat_item TYPE zttmma00090.
  DATA : lt_stock    TYPE zttmma00070.
  DATA : lt_return   TYPE TABLE OF bapiret2.
  DATA : ls_return   TYPE bapiret2.
  DATA : lv_mblnr    TYPE ztmma00090-mblnr.
  DATA : lv_zeile    TYPE ztmma00090-zeile.
  DATA : lv_prev_vl  TYPE zsmma00132-vbeln_vl.

  CLEAR gi_material.

  IF gi_input IS INITIAL.
*    append_error '출고 입력 정보가 없습니다.'.
    append_error TEXT-t01.
    RETURN.
  ENDIF.

  lt_gi = gi_input.
  SORT lt_gi BY vbeln_vl posnr_d.

  "자재 이동 문서 만들기 (651 출고) - 납품(배송)별로 헤더 1건
  LOOP AT lt_gi ASSIGNING FIELD-SYMBOL(<ls_gi>).

    IF <ls_gi>-giqty <= 0.
*      append_error '출고수량은 0보다 커야 합니다.'.
      append_error TEXT-t02.
      RETURN.
    ENDIF.

    "납품이 바뀌면 새 자재문서 헤더
    IF sy-tabix = 1 OR <ls_gi>-vbeln_vl <> lv_prev_vl.

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
*        append_error '자재 이동 문서 채번 오류.'.
        append_error TEXT-t03.
        RETURN.
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

      lv_prev_vl = <ls_gi>-vbeln_vl.
      CLEAR lv_zeile.

    ENDIF.

    lv_zeile += 10.

    APPEND VALUE #(
      mblnr    = lv_mblnr
      mjahr    = sy-datum+0(4)
      zeile    = lv_zeile
      werks    = <ls_gi>-werks
      lgort    = <ls_gi>-lgort
      matnr    = <ls_gi>-matnr
      menge    = <ls_gi>-giqty
      meins    = <ls_gi>-meins
      bwart    = '651'
      vbeln_so = <ls_gi>-vbeln
      posnr    = <ls_gi>-posnr_s
      vbeln    = <ls_gi>-vbeln_vl
      vbelp    = <ls_gi>-posnr_d
      ernam    = sy-uname
      erdat    = sy-datum
      erzet    = sy-uzeit
    ) TO lt_mat_item.

  ENDLOOP.

  "재고(70) / SO 예약재고 현황(150) 갱신은 STOCK FM에서 처리
  CALL FUNCTION 'ZFM_MM_MATERIAL_STOCK'
    EXPORTING
      move_material  = lt_mat_item
    IMPORTING
      material_stock = lt_stock
    TABLES
      et_return      = lt_return.

  READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    APPEND LINES OF lt_return TO et_return.
    RETURN.
  ENDIF.

  MODIFY ztmma00080 FROM TABLE lt_mat_head.
  IF sy-subrc <> 0.
*    append_error '자재 이동 문서 생성 오류.'.
    append_error TEXT-t04.
    RETURN.
  ENDIF.

  MODIFY ztmma00090 FROM TABLE lt_mat_item.
  IF sy-subrc <> 0.
*    append_error '자재 이동 문서 생성 오류.'.
    append_error TEXT-t04.
    RETURN.
  ENDIF.

  gi_material = lt_mat_item.

  CLEAR ls_return.
  ls_return-type    = 'S'.
*  ls_return-message = '출고 처리가 완료되었습니다.'.
  ls_return-message = TEXT-t05.
  APPEND ls_return TO et_return.

ENDFUNCTION.
