*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_K01
*&---------------------------------------------------------------------*
CLASS lcl_mm_po_issue DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_column_id es_row_no.
ENDCLASS.

CLASS lcl_mm_po_issue IMPLEMENTATION.
  METHOD on_hotspot_click.
    DATA : lv_ebeln TYPE ztmma00060-ebeln,
           lv_ebelp TYPE ztmma00060-ebelp.

    IF e_column_id-fieldname <> 'EBELN'
       AND e_column_id-fieldname <> 'EBELP'.
      RETURN.
    ENDIF.

    IF es_row_no-row_id <= 0.
      RETURN.
    ENDIF.

    READ TABLE gt_top ASSIGNING FIELD-SYMBOL(<ls_top>)
      INDEX es_row_no-row_id.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    lv_ebeln = <ls_top>-ebeln.
    lv_ebelp = <ls_top>-ebelp.

    PERFORM zz_get_issue_data USING lv_ebeln lv_ebelp.
  ENDMETHOD.
ENDCLASS.
