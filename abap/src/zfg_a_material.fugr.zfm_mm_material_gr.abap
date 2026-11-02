FUNCTION zfm_mm_material_gr.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(PURCHASE_HEADER) TYPE  ZTTMMA00050 OPTIONAL
*"     REFERENCE(PURCHASE_ITEM) TYPE  ZTTMMA00060 OPTIONAL
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  "아이템, 헤더 들어옴. mengi_i 들어오니깐 자재 이동문서랑 자재이동문서 헤더만 만듦.



  DATA : lt_080 TYPE TABLE OF ztmma00080,
         lt_090 TYPE TABLE OF ztmma00090.

  DATA : lv_mblnr TYPE mblnr.
  DATA : lv_zeile TYPE n LENGTH 5.

  DATA : lt_070    TYPE TABLE OF ztmma00070,
         lt_ret    TYPE TABLE OF bapiret2,
         ls_return TYPE bapiret2.


  LOOP AT purchase_item ASSIGNING FIELD-SYMBOL(<ls_item>).
    APPEND INITIAL LINE TO lt_090 ASSIGNING FIELD-SYMBOL(<ls_090>).
    <ls_090>-werks = <ls_item>-werks.
    <ls_090>-lgort = <ls_item>-lgort.
    <ls_090>-matnr = <ls_item>-matnr.
    <ls_090>-ebeln = <ls_item>-ebeln.
    <ls_090>-ebelp = <ls_item>-ebelp.
    <ls_090>-menge = <ls_item>-menge_i.
    <ls_090>-meins = <ls_item>-meins.
    <ls_090>-bwart = '101'.
    <ls_090>-ernam = sy-uname.
    <ls_090>-erdat = sy-datum.
    <ls_090>-erzet = sy-uzeit.
  ENDLOOP.

  LOOP AT purchase_header ASSIGNING FIELD-SYMBOL(<ls_header>).

    CLEAR : lv_mblnr, lv_zeile.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr             = '01'
        object                  = 'ZMM_MBLNR'
        quantity                = '1'
        toyear                  = sy-datum+0(4)
      IMPORTING
        number                  = lv_mblnr
      EXCEPTIONS
        interval_not_found      = 1
        number_range_not_intern = 2
        object_not_found        = 3
        quantity_is_0           = 4
        quantity_is_not_1       = 5
        interval_overflow       = 6
        buffer_overflow         = 7
        OTHERS                  = 8.
    "채번 실패 시 빈 문서번호로 저장되지 않도록 중단
    IF sy-subrc <> 0.
      CLEAR ls_return.
      ls_return-type    = 'E'.
      ls_return-message = TEXT-t07.
      APPEND ls_return TO et_return.
      RETURN.
    ENDIF.
    APPEND INITIAL LINE TO lt_080 ASSIGNING FIELD-SYMBOL(<ls_080>).
    <ls_080>-mblnr = lv_mblnr.
    <ls_080>-mjahr = sy-datum+0(4).
    <ls_080>-bldat = sy-datum.
    <ls_080>-budat = sy-datum.
    <ls_080>-usnam = sy-uname.
    <ls_080>-ernam = sy-uname.
    <ls_080>-erdat = sy-datum.
    <ls_080>-erzet = sy-uzeit.

    LOOP AT lt_090 ASSIGNING <ls_090> WHERE ebeln = <ls_header>-ebeln.
      lv_zeile = lv_zeile + 10.
      <ls_090>-mblnr = lv_mblnr.
      <ls_090>-mjahr = sy-datum+0(4).
      <ls_090>-zeile = lv_zeile.
    ENDLOOP.
  ENDLOOP.




  CALL FUNCTION 'ZFM_MM_MATERIAL_STOCK'
    EXPORTING
      move_material  = lt_090
    IMPORTING
      material_stock = lt_070
    TABLES
      et_return      = lt_ret.

  et_return[] = lt_ret[].
  LOOP AT lt_ret ASSIGNING FIELD-SYMBOL(<ls_gr_error>)
    WHERE type = 'E' OR type = 'A' OR type = 'X'.
*    lv_error = abap_true.
*    ROLLBACK WORK.
    MESSAGE <ls_gr_error>-message TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDLOOP.

  MODIFY ztmma00080 FROM TABLE lt_080.
  IF sy-subrc <> 0.
    CLEAR ls_return.
    ls_return-type    = 'E'.
*    ls_return-message = '자재 이동 헤더가 생성되지 않았습니다.'.
    ls_return-message = TEXT-t07.
    APPEND ls_return TO et_return.
    RETURN.
  ENDIF.

  MODIFY ztmma00090 FROM TABLE lt_090.
  IF sy-subrc <> 0.
    CLEAR ls_return.
    ls_return-type    = 'E'.
*    ls_return-message = '자재 이동 아이템이 생성되지 않았습니다.'.
    ls_return-message = TEXT-t08.
    APPEND ls_return TO et_return.
    RETURN.
  ENDIF.

ENDFUNCTION.
