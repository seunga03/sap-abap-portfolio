*&---------------------------------------------------------------------*
*& Include          ZLMMA00070_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form zz_get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_data .
  DATA lt_exreq TYPE ztt_exreq.
  DATA lt_return TYPE TABLE OF bapiret2.
  DATA lv_cnt TYPE i.

  CLEAR gv_error.

  IF pa_mm03 = 'X'.
    CALL FUNCTION 'ZCM_EXC_REQ_GET'
      EXPORTING
        iv_tgpgm  = 'MM03'
      IMPORTING
        et_req    = gt_exreq
        et_return = lt_return.

  ELSEIF pa_mm04 = 'X'.
    CALL FUNCTION 'ZCM_EXC_REQ_GET'
      EXPORTING
        iv_tgpgm  = 'MM04'
      IMPORTING
        et_req    = gt_exreq
        et_return = lt_return.
  ENDIF.

  DELETE gt_exreq WHERE erdat NOT IN so_erdat.

  lv_cnt = lines( gt_exreq ).
  IF lv_cnt <> 0.
    MESSAGE s126 WITH lv_cnt.
  ELSE.
    MESSAGE S127 DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object .
  CREATE OBJECT go_con
    EXPORTING
      container_name              = 'CUSTOM_CON'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.
  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.

  CREATE OBJECT go_alv
    EXPORTING
      i_parent          = go_con
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  CALL METHOD go_alv->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layo
      it_toolbar_excluding          = gt_exclude
    CHANGING
      it_outtab                     = gt_exreq
      it_fieldcatalog               = gt_fcat
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZTEXA00060'
    CHANGING
      ct_fieldcat      = gt_fcat.

  LOOP AT gt_fcat ASSIGNING FIELD-SYMBOL(<ls_fcat>).
    CASE <ls_fcat>-fieldname.
      WHEN 'RSTXT'.
        <ls_fcat>-edit = 'X'.
    ENDCASE.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout .
  gs_layo-zebra = 'X'.
  gs_layo-sel_mode = 'A'.
  gs_layo-cwidth_opt = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_inspection_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_inspection_data USING pt_selected TYPE ztt_exreq.

  DATA : lt_inspection TYPE TABLE OF gty_inspection.

  SELECT a~inspn, a~inspp, a~gritm, a~matnr, a~faiqt,
         a~meins, b~mblnr, b~mjahr, b~insdt, b~insby
    FROM ztmma00130 AS a
    INNER JOIN ztmma00120 AS b
    ON a~inspn = b~inspn
    FOR ALL ENTRIES IN @pt_selected
    WHERE a~inspn = @pt_selected-srnum
      AND a~inspp = @pt_selected-sritm
    INTO CORRESPONDING FIELDS OF TABLE @lt_inspection.

  SORT lt_inspection BY mblnr mjahr gritm.
  DELETE ADJACENT DUPLICATES FROM lt_inspection COMPARING mblnr mjahr gritm.


  SELECT mblnr, mjahr, zeile, werks, lgort,
         matnr, ebeln, ebelp, vbeln, vbelp,
         vbeln_so, posnr, menge, meins, bwart
    FROM ztmma00090
    INTO CORRESPONDING FIELDS OF TABLE @gt_mat_move
    FOR ALL ENTRIES IN @lt_inspection
    WHERE mblnr = @lt_inspection-mblnr
      AND mjahr = @lt_inspection-mjahr
      AND zeile = @lt_inspection-gritm.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_selected_row
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_selected_row CHANGING pv_error.
  DATA lt_row TYPE lvc_t_row.

  go_alv->get_selected_rows(
    IMPORTING
      et_index_rows = lt_row ).

  IF lt_row IS INITIAL.
    MESSAGE S128 DISPLAY LIKE 'E'.
    pv_error = abap_true.
    RETURN.
  ENDIF.

  LOOP AT lt_row INTO DATA(ls_row).

    READ TABLE gt_exreq ASSIGNING FIELD-SYMBOL(<ls_alv>) INDEX ls_row-index.

    IF sy-subrc = 0.
      APPEND INITIAL LINE TO gt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).
      MOVE-CORRESPONDING <ls_alv> TO <ls_selected>.
    ENDIF.

  ENDLOOP.

  SORT gt_selected BY srnum sritm.
  DELETE ADJACENT DUPLICATES FROM gt_selected COMPARING srnum sritm.

  PERFORM zz_get_inspection_data USING gt_selected.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_make_document
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_make_document .
  DATA lv_mblnr TYPE mblnr.
  DATA : lt_080 TYPE TABLE OF ztmma00080,
         lt_090 TYPE TABLE OF ztmma00090.

  DATA : lv_zeile TYPE zde_mblpo.
  DATA : lt_return TYPE TABLE OF  bapiret2.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZMM_MBLNR'
      toyear      = sy-datum+0(4)
    IMPORTING
      number      = lv_mblnr
    EXCEPTIONS
      OTHERS      = 1.

  APPEND VALUE #(
    mblnr = lv_mblnr
    mjahr = sy-datum+0(4)
    bldat = sy-datum
    budat = sy-datum
    usnam = sy-uname
    ernam = sy-uname
    erdat = sy-datum
    erzet = sy-uzeit
  ) TO lt_080.

  LOOP AT gt_mat_move ASSIGNING FIELD-SYMBOL(<ls_mat_move>).
    lv_zeile += 10.
    APPEND VALUE #(
      mblnr = lv_mblnr
      mjahr = sy-datum+0(4)
      zeile = lv_zeile
      werks = <ls_mat_move>-werks
      lgort = <ls_mat_move>-lgort
      matnr = <ls_mat_move>-matnr
      ebeln = <ls_mat_move>-ebeln
      ebelp = <ls_mat_move>-ebelp
      menge = <ls_mat_move>-menge
      meins = <ls_mat_move>-meins
      vbeln = <ls_mat_move>-vbeln
      vbelp = <ls_mat_move>-vbelp
      vbeln_so = <ls_mat_move>-vbeln_so
      posnr = <ls_mat_move>-posnr
      bwart = '122'
      ernam = sy-uname
      erdat = sy-datum
      erzet = sy-uzeit
    ) TO lt_090.
  ENDLOOP.

  MODIFY ztmma00080 FROM TABLE lt_080.
  IF sy-subrc <> 0.
    MESSAGE s129 DISPLAY LIKE 'E'.
    gv_error = abap_true.
    RETURN.
  ENDIF.

  MODIFY ztmma00090 FROM TABLE lt_090.
  IF sy-subrc <> 0.
    MESSAGE s129 DISPLAY LIKE 'E'.
    gv_error = abap_true.
    RETURN.
  ENDIF.

  LOOP AT gt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).
    CALL FUNCTION 'ZCM_EXC_REQ_DONE'
      EXPORTING
        iv_rqnum  = <ls_selected>-rqnum
        iv_rstxt  = <ls_selected>-rstxt
      IMPORTING
*       EV_EXNUM  =
        et_return = lt_return.

  ENDLOOP.
  READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    gv_error = abap_true.
    ROLLBACK WORK.
  ELSE.
    COMMIT WORK.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form exclude_toolbar
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM exclude_toolbar.
  CLEAR gt_exclude.

  "아래 ALV에만 뜨는 편집용 표준 버튼 제거
  APPEND cl_gui_alv_grid=>mc_fc_refresh           TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy          TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row      TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut           TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste         TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo          TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row    TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row    TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row    TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_move_row      TO gt_exclude.
ENDFORM.
