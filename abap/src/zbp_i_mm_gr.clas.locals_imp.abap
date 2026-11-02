CLASS lhc_Gr DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Gr RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ Gr RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Gr.

    METHODS CreateGr FOR MODIFY
      IMPORTING keys FOR ACTION Gr~CreateGr.

ENDCLASS.
CLASS lhc_Gr IMPLEMENTATION.

  METHOD get_global_authorizations.
    "현재는 입고 컨펌 액션을 허용
    IF requested_authorizations-%action-CreateGr = if_abap_behv=>mk-on.
      result-%action-CreateGr = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD CreateGr.
    DATA lt_header TYPE zttmma00050.
    DATA lt_item   TYPE zttmma00060.
    DATA lt_return TYPE TABLE OF bapiret2.

    READ TABLE keys ASSIGNING FIELD-SYMBOL(<ls_key>) INDEX 1.
    IF sy-subrc <> 0.
      INSERT new_message_with_text(
        severity = if_abap_behv_message=>severity-error
        text     = '입고 요청이 없습니다.'
      ) INTO TABLE reported-%other.
      RETURN.
    ENDIF.

    IF <ls_key>-%param-_Item IS INITIAL.
      APPEND VALUE #( %cid = <ls_key>-%cid ) TO failed-Gr.

      INSERT new_message_with_text(
        severity = if_abap_behv_message=>severity-error
        text     = '입고할 바코드 품목이 없습니다.'
      ) INTO TABLE reported-%other.
      RETURN.
    ENDIF.

    LOOP AT <ls_key>-%param-_Item ASSIGNING FIELD-SYMBOL(<ls_scan>).

      IF <ls_scan>-Bwart <> '101'.
        APPEND VALUE #( %cid = <ls_key>-%cid ) TO failed-Gr.

        INSERT new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = '입고 이동유형은 101만 가능합니다.'
        ) INTO TABLE reported-%other.
        RETURN.
      ENDIF.

      APPEND CORRESPONDING #(
        <ls_scan>
        MAPPING menge_i = mengei
      ) TO lt_item.

      APPEND VALUE #(
        ebeln = <ls_scan>-Ebeln
      ) TO lt_header.

    ENDLOOP.

    SORT lt_header BY ebeln.
    DELETE ADJACENT DUPLICATES FROM lt_header COMPARING ebeln.

    CALL FUNCTION 'ZFM_MM_MATERIAL_GR'
      EXPORTING
        purchase_header = lt_header
        purchase_item   = lt_item
      TABLES
        et_return       = lt_return.

    IF line_exists( lt_return[ type = 'E' ] )
    OR line_exists( lt_return[ type = 'A' ] )
    OR line_exists( lt_return[ type = 'X' ] ).

      APPEND VALUE #( %cid = <ls_key>-%cid ) TO failed-Gr.

      LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ls_return>)
        WHERE type CA 'AEX'.

        INSERT new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = <ls_return>-message
        ) INTO TABLE reported-%other.

      ENDLOOP.

      RETURN.
    ENDIF.

    INSERT new_message_with_text(
      severity = if_abap_behv_message=>severity-success
      text     = '입고 완료'
    ) INTO TABLE reported-%other.

  ENDMETHOD.

ENDCLASS.
*CLASS lhc_Gr IMPLEMENTATION.
*
*  METHOD get_global_authorizations.
*  ENDMETHOD.
*
*  METHOD read.
*  ENDMETHOD.
*
*  METHOD lock.
*  ENDMETHOD.
*
*  METHOD CreateGr.
*  ENDMETHOD.
*
*ENDCLASS.
*
*CLASS lsc_ZI_MM_GR DEFINITION INHERITING FROM cl_abap_behavior_saver.
*  PROTECTED SECTION.
*
*    METHODS finalize REDEFINITION.
*
*    METHODS check_before_save REDEFINITION.
*
*    METHODS save REDEFINITION.
*
*    METHODS cleanup REDEFINITION.
*
*    METHODS cleanup_finalize REDEFINITION.
*
*ENDCLASS.
*
*CLASS lsc_ZI_MM_GR IMPLEMENTATION.
*
*  METHOD finalize.
*  ENDMETHOD.
*
*  METHOD check_before_save.
*  ENDMETHOD.
*
*  METHOD save.
*  ENDMETHOD.
*
*  METHOD cleanup.
*  ENDMETHOD.
*
*  METHOD cleanup_finalize.
*  ENDMETHOD.
*
*ENDCLASS.
