*&---------------------------------------------------------------------*
*& Include          ZRDPA00023_K01
*&---------------------------------------------------------------------*
CLASS lcl_event_receiver DEFINITION.
  PUBLIC SECTION.
    METHODS handle_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
ENDCLASS.

CLASS lcl_event_receiver IMPLEMENTATION.
  METHOD handle_hotspot_click.
    READ TABLE gt_display INTO DATA(ls_row) INDEX e_row_id-index.
    CHECK sy-subrc = 0.

    CASE e_column_id-fieldname.
      WHEN 'REASON_LINK'.
        IF ls_row-aireason IS NOT INITIAL.
          gv_reason = ls_row-aireason.
          gv_reason_title = |{ ls_row-matnr } - AI 예측사유|.
          CALL SCREEN 0200 STARTING AT 12 4 ENDING AT 110 22.
        ENDIF.
      WHEN 'HIST_LINK'.
        PERFORM zz_show_history USING ls_row-fcsno ls_row-iteno.
      WHEN 'FACT_LINK'.
        PERFORM zz_show_factor USING ls_row-fcsno ls_row-iteno.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
