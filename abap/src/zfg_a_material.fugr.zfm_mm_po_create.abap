FUNCTION zfm_mm_po_create.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(PURCHASE_ITEM) TYPE  ZTTMMA00044
*"     REFERENCE(PURCHASE_REQ) TYPE  ZTTMMA00043
*"  EXPORTING
*"     REFERENCE(ET_MMA00050) TYPE  ZTTMMA00050
*"     REFERENCE(ET_MMA00060) TYPE  ZTTMMA00061
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------

  TYPES: BEGIN OF ty_po_seq,
           ebeln TYPE ebeln,
           ebelp TYPE ebelp,
         END OF ty_po_seq.

  DATA: lt_mma00050 TYPE TABLE OF ztmma00050
                       WITH NON-UNIQUE SORTED KEY idx01
                       COMPONENTS lifnr,
        lt_mma00060 TYPE TABLE OF ztmma00060,
        lt_po_seq   TYPE HASHED TABLE OF ty_po_seq
                       WITH UNIQUE KEY ebeln,
        ls_po_seq   TYPE ty_po_seq,
        lt_pr_key   TYPE SORTED TABLE OF ztmma00040
                      WITH UNIQUE KEY banfn bnfpo,
        lt_pr_save  TYPE HASHED TABLE OF ztmma00040
                      WITH UNIQUE KEY banfn bnfpo.

  DATA : ls_return TYPE bapiret2.
  IF purchase_item IS INITIAL.
    append_error TEXT-t31.
*    APPEND VALUE #( type = 'E' message = 'PO 생성 대상이 없습니다.' )
*      TO et_return.
    RETURN.
  ENDIF.

  LOOP AT purchase_item ASSIGNING FIELD-SYMBOL(<ls_alv_po>).

    READ TABLE lt_mma00050 ASSIGNING FIELD-SYMBOL(<ls_mma00050>) WITH TABLE KEY idx01
      COMPONENTS lifnr = <ls_alv_po>-lifnr.

    IF sy-subrc <> 0.

      INSERT INITIAL LINE INTO TABLE lt_mma00050
        ASSIGNING <ls_mma00050>.

      <ls_mma00050>-lifnr = <ls_alv_po>-lifnr.

      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING
          nr_range_nr = '01'
          object      = 'ZMM_EBELN'
        IMPORTING
          number      = <ls_mma00050>-ebeln
        EXCEPTIONS
          OTHERS      = 8.

      IF sy-subrc <> 0.
*        APPEND VALUE #( type = 'E' message = 'PO 번호 채번에 실패했습니다.' )
*          TO et_return.
        append_error TEXT-t32.
        RETURN.
      ENDIF.

      <ls_mma00050>-bedat = sy-datum.
      <ls_mma00050>-ekgrp = <ls_alv_po>-ekgrp.
      <ls_mma00050>-pstat = '0010'.
      <ls_mma00050>-ernam = sy-uname.
      <ls_mma00050>-erdat = sy-datum.
      <ls_mma00050>-erzet = sy-uzeit.

    ENDIF.

    READ TABLE lt_po_seq INTO ls_po_seq
      WITH TABLE KEY ebeln = <ls_mma00050>-ebeln.

    IF sy-subrc <> 0.
      ls_po_seq = VALUE #(
        ebeln = <ls_mma00050>-ebeln
        ebelp = 10
      ).
      INSERT ls_po_seq INTO TABLE lt_po_seq.
    ELSE.
      ls_po_seq-ebelp += 10.
      MODIFY TABLE lt_po_seq FROM ls_po_seq.
    ENDIF.

    APPEND INITIAL LINE TO lt_mma00060
      ASSIGNING FIELD-SYMBOL(<ls_mma00060>).

    <ls_mma00060>-ebeln = <ls_mma00050>-ebeln.
    <ls_mma00060>-ebelp = ls_po_seq-ebelp.
    <ls_mma00060>-matnr = <ls_alv_po>-matnr.
    <ls_mma00060>-werks = <ls_alv_po>-werks.
    <ls_mma00060>-lgort = <ls_alv_po>-lgort.
    <ls_mma00060>-menge = <ls_alv_po>-rqty.
    <ls_mma00060>-meins = <ls_alv_po>-meins.
    <ls_mma00060>-netpr = <ls_alv_po>-netpr.
    <ls_mma00060>-waers = <ls_alv_po>-waers.
    <ls_mma00060>-eindt = sy-datum + <ls_alv_po>-plifz.
    <ls_mma00060>-banfn = <ls_alv_po>-banfn.
    <ls_mma00060>-bnfpo = <ls_alv_po>-bnfpo.
    <ls_mma00060>-ptype = <ls_alv_po>-ptype.
    <ls_mma00060>-ernam = sy-uname.
    <ls_mma00060>-erdat = sy-datum.
    <ls_mma00060>-erzet = sy-uzeit.

    INSERT VALUE #(
      banfn = <ls_alv_po>-banfn
      bnfpo = <ls_alv_po>-bnfpo
    ) INTO TABLE lt_pr_key.

  ENDLOOP.

  MOVE-CORRESPONDING purchase_req TO lt_pr_save.
  MODIFY ztmma00040 FROM TABLE lt_pr_save.
  IF sy-subrc <> 0.
    append_error TEXT-t35.
    RETURN.
  ENDIF.


  MODIFY ztmma00050 FROM TABLE lt_mma00050.
  IF sy-subrc <> 0.
*    APPEND VALUE #( type = 'E' message = 'PO 헤더 저장에 실패했습니다.' )
*      TO et_return.
    append_error TEXT-t33.
    RETURN.
  ENDIF.

  MODIFY ztmma00060 FROM TABLE lt_mma00060.
  IF sy-subrc <> 0.
*    APPEND VALUE #( type = 'E' message = 'PO 품목 저장에 실패했습니다.' )
*      TO et_return.
    append_error TEXT-t34.
    RETURN.
  ENDIF.
  et_mma00050 = lt_mma00050.
  et_mma00060 = lt_mma00060.
ENDFUNCTION.
