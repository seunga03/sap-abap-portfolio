FUNCTION zfm_mm_pr_tracking.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(MATERIAL_ITEM) TYPE  ZTTMMA00090
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
  DEFINE append_error.
    CLEAR ls_return.
    ls_return-type    = 'E'.
    ls_return-message = &1.
    APPEND ls_return TO et_return.
  END-OF-DEFINITION.

  DATA lt_mat TYPE zttmma00090.
  DATA : lt_060     TYPE TABLE OF ztmma00060,
         lt_060_key TYPE TABLE OF ztmma00060.

  DATA lt_040 TYPE TABLE OF ztmma00040.
  DATA lv_menge TYPE ztmma00040-rqty.
  DATA : ls_return TYPE bapiret2.

  lt_mat = material_item.
  IF lt_mat IS INITIAL.
    RETURN.
  ENDIF.

  SORT lt_mat BY ebeln ebelp.
  DELETE ADJACENT DUPLICATES FROM lt_mat COMPARING ebeln ebelp.

  SELECT ebeln, ebelp, matnr, werks, lgort,
         meins, menge, banfn, bnfpo
    FROM ztmma00060
    INTO CORRESPONDING FIELDS OF TABLE @lt_060
    FOR ALL ENTRIES IN @lt_mat
    WHERE ebeln = @lt_mat-ebeln
      AND ebelp = @lt_mat-ebelp.

  IF lt_060 IS INITIAL.
    RETURN.
  ENDIF.


  lt_060_key = lt_060.
  SORT lt_060_key BY banfn bnfpo.
  DELETE ADJACENT DUPLICATES FROM lt_060_key COMPARING banfn bnfpo.

  SELECT *
    FROM ztmma00040
    INTO CORRESPONDING FIELDS OF TABLE @lt_040
    FOR ALL ENTRIES IN @lt_060_key
    WHERE banfn = @lt_060_key-banfn
      AND bnfpo = @lt_060_key-bnfpo.

  IF lt_040 IS INITIAL.
    RETURN.
  ENDIF.

  CALL FUNCTION 'ENQUEUE_E_TABLE'
    EXPORTING
      mode_rstable   = 'E'
      tabname        = 'ZTMMA00040'
      varkey         = space
      x_tabname      = ' '
      x_varkey       = ' '
      _scope         = '1'
      _wait          = space
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
    append_error TEXT-t39.
    RETURN.
  ENDIF.


  LOOP AT lt_040 ASSIGNING FIELD-SYMBOL(<ls_040>).
    CLEAR lv_menge.
    LOOP AT lt_060 ASSIGNING FIELD-SYMBOL(<ls_060>) WHERE banfn = <ls_040>-banfn
                                                      AND bnfpo = <ls_040>-bnfpo.
      lv_menge += <ls_060>-menge.
    ENDLOOP.
    IF lv_menge = <ls_040>-rqty.
      <ls_040>-pstat = '0050'.
    ENDIF.
  ENDLOOP.

  MODIFY ztmma00040 FROM TABLE lt_040.
  IF sy-subrc <> 0.
*    append_error '재고 저장 오류 발생.'.
    append_error TEXT-t40.
    RETURN.
  ENDIF.
ENDFUNCTION.
