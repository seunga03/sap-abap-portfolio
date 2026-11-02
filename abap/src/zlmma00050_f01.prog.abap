*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_F01
*&---------------------------------------------------------------------*
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
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  CREATE OBJECT go_splitter
    EXPORTING
      parent  = go_con
      rows    = 2
      columns = 1.

  go_top = go_splitter->get_container(
                  row    = 1
                  column = 1 ).

  go_bot = go_splitter->get_container(
                  row    = 2
                  column = 1 ).

  CREATE OBJECT go_alv_top
    EXPORTING
      i_parent          = go_top
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.

  CREATE OBJECT go_alv_bot
    EXPORTING
      i_parent          = go_bot
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
*& Form set_event_handler
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_event_handler .
  SET HANDLER lcl_event_handler=>on_toolbar_top FOR go_alv_top.
  SET HANDLER lcl_event_handler=>on_toolbar_bot FOR go_alv_bot.

  SET HANDLER lcl_event_handler=>on_user_command FOR go_alv_top.
  SET HANDLER lcl_event_handler=>on_user_command FOR go_alv_bot.
  SET HANDLER lcl_event_handler=>on_data_changed FOR go_alv_bot.
*  SET HANDLER lcl_event_handler=>on_double_click FOR go_alv_bot.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_variant
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_variant .

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
  gs_layo_top-zebra = 'X'.
  gs_layo_top-sel_mode = 'A'.
*  gs_layo_top-cwidth_opt = 'X'.

  gs_layo_bot-zebra = 'X'.
  gs_layo_bot-sel_mode = 'A'.
*  gs_layo_bot-cwidth_opt = 'X'.
*  gs_layo_bot-edit = 'X'.

  go_alv_bot->register_edit_event(
  EXPORTING
    i_event_id = cl_gui_alv_grid=>mc_evt_modified ).

  PERFORM exclude_toolbar_bot.
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
*     I_BUFFER_ACTIVE        =
      i_structure_name       = 'ZSMMA00050'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     = 'X'
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = gt_fcat_top
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        =
      i_structure_name       = 'ZSMMA00050'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     = 'X'
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = gt_fcat_bot
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  PERFORM zz_set_fcat_detail.
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
  CALL METHOD go_alv_top->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layo_top
    CHANGING
      it_outtab                     = gt_alv_top
      it_fieldcatalog               = gt_fcat_top
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.

  CALL METHOD go_alv_bot->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layo_bot
      it_toolbar_excluding          = gt_exclude_bot
    CHANGING
      it_outtab                     = gt_alv_bot
      it_fieldcatalog               = gt_fcat_bot
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
*& Form zz_get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_data .

  REFRESH : gt_alv_bot, gt_alv_top.
  SELECT a~mblnr, a~mjahr, a~bldat, a~budat, a~usnam,
         b~zeile, b~ebeln, b~ebelp, b~matnr, b~werks,
         b~lgort, b~menge, b~meins, b~bwart,
         c~maktx,
         d~name1 AS wname,
         e~lgobe AS name1
    FROM ztmma00080 AS a

   INNER JOIN ztmma00090 AS b
      ON b~mblnr = a~mblnr
     AND b~mjahr = a~mjahr

    LEFT OUTER JOIN ztcma00020 AS c
      ON c~matnr = b~matnr

    LEFT OUTER JOIN ztcma00140 AS d
      ON d~werks = b~werks

    LEFT OUTER JOIN ztcma00150 AS e
      ON e~werks = b~werks
     AND e~lgort = b~lgort

   WHERE a~mblnr IN @s_mblnr
     AND a~mjahr IN @s_mjahr
     AND a~budat IN @s_budat
     AND b~ebeln IN @s_ebeln
     AND b~matnr IN @s_matnr
     AND b~werks IN @s_werks
     AND b~lgort IN @s_lgort
     AND b~bwart = '101'
     AND NOT EXISTS (
         SELECT *
           FROM ztmma00120 AS qm_head
          INNER JOIN ztmma00130 AS qm_item
             ON qm_item~inspn = qm_head~inspn
          WHERE qm_head~mblnr = b~mblnr
            AND qm_head~mjahr = b~mjahr
            AND qm_item~gritm = b~zeile
     )
   ORDER BY a~mblnr, a~mjahr ASCENDING
    INTO CORRESPONDING FIELDS OF TABLE @gt_alv_top.
*  SELECT a~mblnr, a~mjahr, a~bldat, a~budat, a~usnam,
*       b~zeile, b~ebeln, b~ebelp, b~matnr, b~werks,
*       b~lgort, b~menge, b~meins, b~bwart
*  FROM ztmma00080 AS a
* INNER JOIN ztmma00090 AS b
*    ON b~mblnr = a~mblnr
*   AND b~mjahr = a~mjahr
* WHERE a~mblnr IN @s_mblnr
*   AND a~mjahr IN @s_mjahr
*   AND a~budat IN @s_budat
*   AND b~ebeln IN @s_ebeln
*   AND b~matnr IN @s_matnr
*   AND b~werks IN @s_werks
*   AND b~lgort IN @s_lgort
*   AND b~bwart = '101'
*  AND NOT EXISTS (
*    SELECT *
*      FROM ztmma00120 AS qm_head
*      INNER JOIN ztmma00130 AS qm_item
*        ON qm_item~inspn = qm_head~inspn
*     WHERE qm_head~mblnr = b~mblnr
*       AND qm_head~mjahr = b~mjahr
*       AND qm_item~gritm = b~zeile
*  )
*  ORDER BY a~mblnr, a~mjahr ASCENDING
*  INTO CORRESPONDING FIELDS OF TABLE @gt_alv_top.

  SELECT cdval
    FROM ztcma00080
    INTO TABLE gt_cdval
    WHERE cdgrp = 'INSPE'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_qm
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_qm .
  DATA: lt_selected   TYPE lvc_t_row,
        lv_move_count TYPE i,
        lv_fail_count TYPE i.

  go_alv_top->get_selected_rows(
    IMPORTING
      et_index_rows = lt_selected
  ).

  IF lt_selected IS INITIAL.
    MESSAGE s119 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT lt_selected BY index DESCENDING.

  LOOP AT lt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).

    READ TABLE gt_alv_top ASSIGNING FIELD-SYMBOL(<ls_top>)
      INDEX <ls_selected>-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    "PO 장바구니 행 생성
    APPEND INITIAL LINE TO gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_bot>).

    MOVE-CORRESPONDING <ls_top> TO <ls_bot>.
    "상단 PR ALV에서만 제거
    <ls_bot>-pasqt = <ls_bot>-menge.
    DELETE gt_alv_top INDEX <ls_selected>-index.

    lv_move_count = lv_move_count + 1.

  ENDLOOP.

  SORT gt_alv_bot BY mblnr DESCENDING mjahr DESCENDING.
  IF lv_move_count > 0.
    MESSAGE s144 WITH lv_move_counT.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form delete_qm
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM delete_qm .
  DATA: lt_selected    TYPE lvc_t_row,
        lv_gr_save_idx TYPE sy-tabix,
        lv_move_count  TYPE i.

  go_alv_bot->get_selected_rows(
    IMPORTING
      et_index_rows = lt_selected
  ).

  IF lt_selected IS INITIAL.
    MESSAGE s121 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "PO 장바구니 행 삭제 시 INDEX 밀림 방지
  SORT lt_selected BY index DESCENDING.

  LOOP AT lt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).

    READ TABLE gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_alv_bot>)
      INDEX <ls_selected>-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.


    APPEND INITIAL LINE TO gt_alv_top ASSIGNING FIELD-SYMBOL(<ls_alv_top>).

    MOVE-CORRESPONDING <ls_alv_bot> TO <ls_alv_top>.


    "하단 PO 장바구니에서 제거
    DELETE gt_alv_bot INDEX <ls_selected>-index.

    lv_move_count = lv_move_count + 1.

  ENDLOOP.
  SORT gt_alv_top BY mblnr zeile.

  MESSAGE s145 WITH lv_move_count.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_fcat_detail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_fcat_detail .
  LOOP AT gt_fcat_top ASSIGNING FIELD-SYMBOL(<ls_fcat_top>).
    CASE <ls_fcat_top>-fieldname.
      WHEN 'MBLNR'.
        <ls_fcat_top>-outputlen = '5'.
      WHEN 'MJAHR'.
        <ls_fcat_top>-outputlen = '2'.
        <ls_fcat_top>-coltext   = '자재 연도'.
      WHEN 'ZEILE'.
        <ls_fcat_top>-outputlen = '3'.
      WHEN 'WERKS'.
        <ls_fcat_top>-outputlen = '4'.
      WHEN 'WNAME'.
        <ls_fcat_top>-outputlen = '4'.
      WHEN 'LGORT'.
        <ls_fcat_top>-outputlen = '4'.
      WHEN 'NAME1'.
        <ls_fcat_top>-outputlen = '4'.
      WHEN 'MATNR'.
        <ls_fcat_top>-outputlen = '10'.
      WHEN 'MAKTX'.
        <ls_fcat_top>-outputlen = '10'.
      WHEN 'BLDAT'.
        <ls_fcat_top>-outputlen = '5'.
      WHEN 'BUDAT'.
        <ls_fcat_top>-outputlen = '5'.
      WHEN 'USNAM'.
        <ls_fcat_top>-outputlen = '5'.
      WHEN 'EBELN'.
        <ls_fcat_top>-outputlen = '5'.
      WHEN 'EBELP'.
        <ls_fcat_top>-outputlen = '2'.
      WHEN 'MENGE'.
        <ls_fcat_top>-outputlen = '2'.
      WHEN 'INSQT'.
        <ls_fcat_top>-no_out = 'X'.
      WHEN 'PASQT'.
        <ls_fcat_top>-no_out = 'X'.
      WHEN 'FAIQT'.
        <ls_fcat_top>-no_out = 'X'.
      WHEN 'BWART'.
        <ls_fcat_top>-no_out = 'X'.
      WHEN 'RESLT'.
        <ls_fcat_top>-no_out = 'X'.
      WHEN 'DEFCD'.
        <ls_fcat_top>-no_out = 'X'.
      WHEN 'DEFTX'.
        <ls_fcat_top>-no_out = 'X'.
    ENDCASE.
  ENDLOOP.

  LOOP AT gt_fcat_bot ASSIGNING FIELD-SYMBOL(<ls_fcat_bot>).
    CASE <ls_fcat_bot>-fieldname.
      WHEN 'MBLNR'.
        <ls_fcat_bot>-outputlen = '5'.
      WHEN 'MJAHR'.
        <ls_fcat_bot>-outputlen = '2'.
        <ls_fcat_bot>-coltext   = '자재 연도'.
      WHEN 'WNAME'.
        <ls_fcat_bot>-outputlen = '4'.
      WHEN 'ZEILE'.
        <ls_fcat_bot>-outputlen = '3'.
      WHEN 'BLDAT'.
        <ls_fcat_bot>-outputlen = '5'.
      WHEN 'NAME1'.
        <ls_fcat_bot>-outputlen = '4'.
      WHEN 'BUDAT'.
        <ls_fcat_bot>-outputlen = '5'.
      WHEN 'USNAM'.
        <ls_fcat_bot>-outputlen = '5'.
      WHEN 'MATNR'.
        <ls_fcat_bot>-outputlen = '10'.
      WHEN 'MAKTX'.
        <ls_fcat_bot>-outputlen = '10'.
      WHEN 'MENGE'.
        <ls_fcat_bot>-outputlen = '3'.
        <ls_fcat_bot>-coltext = TEXT-t06.
      WHEN 'RESLT'.
        <ls_fcat_bot>-outputlen = '2'.
        <ls_fcat_bot>-no_out = 'X'.
      WHEN 'BWART'.
        <ls_fcat_bot>-no_out = 'X'.
      WHEN 'PASQT'.
        <ls_fcat_bot>-edit = 'X'.
        <ls_fcat_bot>-outputlen = '2'.
      WHEN 'FAIQT'.
        <ls_fcat_bot>-no_out = 'X'.
      WHEN 'INSQT'.
        <ls_fcat_bot>-no_out = 'X'.
      WHEN 'EBELN'.
        <ls_fcat_bot>-no_out = 'X'.
      WHEN 'EBELP'.
        <ls_fcat_bot>-no_out = 'X'.
      WHEN 'DEFCD'.
        <ls_fcat_bot>-edit = 'X'.
        <ls_fcat_bot>-f4availabl = 'X'.
        <ls_fcat_bot>-ref_table = 'ZSMMA00050'.
        <ls_fcat_bot>-ref_field = 'DEFCD'.
        <ls_fcat_bot>-outputlen = '2'.
      WHEN 'DEFTX'.
        <ls_fcat_bot>-edit = 'X'.
        <ls_fcat_bot>-outputlen = '20'.

    ENDCASE.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_exe_qm
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_qm .
  DATA : lt_qm TYPE zttmma00131.
  DATA : lt_return TYPE TABLE OF bapiret2.
  DATA : lt_in_head TYPE zttmma00120,
         lt_in_item TYPE zttmma00130.

  DATA : lv_error TYPE abap_bool.
  DATA : lv_lock  TYPE sy-subrc.
  go_alv_bot->check_changed_data( ).

  LOOP AT gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_alv_bot>).
    IF <ls_alv_bot>-menge = <ls_alv_bot>-pasqt AND <ls_alv_bot>-defcd IS NOT INITIAL.
      MESSAGE s143 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    IF <ls_alv_bot>-pasqt <> <ls_alv_bot>-menge  AND <ls_alv_bot>-defcd IS INITIAL.
      MESSAGE s142 WITH <ls_alv_bot>-mblnr DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    APPEND VALUE #(
    mblnr = <ls_alv_bot>-mblnr
    mjahr = <ls_alv_bot>-mjahr
    gritm = <ls_alv_bot>-zeile
    faiqt = <lS_alv_bot>-menge - <ls_alv_bot>-pasqt
    defcd = <ls_alv_bot>-defcd
    deftx = <ls_alv_bot>-deftx
    meins = <ls_alv_bot>-meins
    matnr = <ls_alv_bot>-matnr
    insqt = <ls_alv_bot>-menge
    pasqt = <ls_alv_bot>-pasqt
    werks = <ls_alv_bot>-werks
    lgort = <ls_alv_bot>-lgort
    reslt = <ls_alv_bot>-reslt
    ebeln = <ls_alv_bot>-ebeln
    ebelp = <ls_alv_bot>-ebelp
    ) TO lt_qm.

  ENDLOOP.
  PERFORM zz_enqueue_lock USING lt_qm CHANGING lv_lock.

  CASE lv_lock.
    WHEN '1'.
      MESSAGE s139 DISPLAY LIKE 'E'.
      RETURN.
  ENDCASE.

  CALL FUNCTION 'ZFM_MM_INSPECTION_RESULT'
    EXPORTING
      result_input      = lt_qm
    IMPORTING
      inspection_header = lt_in_head
      inspection_item   = lt_in_item
*     RESULT_MATERIAL   =
*     MATERIAL_STOCK    =
    TABLES
      et_return         = lt_return.

  LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ls_qm_error>)
    WHERE type = 'E' OR type = 'A' OR type = 'X'.
    lv_error = abap_true.
*    ROLLBACK WORK.
    MESSAGE <ls_qm_error>-message TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDLOOP.
  IF lv_error IS INITIAL.
    PERFORM zz_exe_exception USING lt_in_item
                          CHANGING lv_error.

  ENDIF.

  IF lv_error IS NOT INITIAL.
    ROLLBACK WORK.
*    PERFORM zz_dequeue_lock USING lt_qm.
*    PERFORM zz_dequeue_pr.
    lv_error = abap_true.
  ELSE.
    COMMIT WORK.
*    PERFORM zz_dequeue_lock USING lt_qm.
*    PERFORM zz_dequeue_pr.
    MESSAGE s138.
  ENDIF.
  CALL FUNCTION 'DEQUEUE_ALL'.

  IF lv_error IS INITIAL.
    PERFORM zz_get_data.
    go_alv_top->refresh_table_display( ).
    go_alv_bot->refresh_table_display( ).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_exe_exception
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_exception USING pt_in_item TYPE zttmma00130
                   CHANGING pv_error.

  DATA : lv_srnum TYPE ztexa00010-srnum,
         lv_sritm TYPE ztexa00010-sritm.

  DATA : lt_return TYPE TABLE OF bapiret2.

  LOOP AT pt_in_item ASSIGNING FIELD-SYMBOL(<ls_in_item>) WHERE faiqt > 0.
    CLEAR : lv_srnum, lv_sritm.

    lv_srnum = <ls_in_item>-inspn.
    lv_sritm = <ls_in_item>-inspp.

    CALL FUNCTION 'ZCM_EXC_CREATE'
      EXPORTING
        iv_srtyp  = 'QM'
        iv_srnum  = lv_srnum
        iv_sritm  = lv_sritm
        iv_owgrp  = 'MM'
        iv_extyp  = 'QUAL'
      IMPORTING
        et_return = lt_return.

    READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.

    READ TABLE lt_return WITH KEY type = 'A' TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.

    READ TABLE lt_return WITH KEY type = 'X' TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.

  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_deftx_click
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_deftx_click USING pv_index TYPE lvc_index
                     CHANGING pv_error.
  CLEAR : pv_error, gv_note_row.
  go_alv_bot->check_changed_data( ).

  READ TABLE gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_bot>) INDEX pv_index.
  IF <ls_bot>-defcd IS INITIAL.
    MESSAGE s123 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE gt_cdval WITH KEY table_line = <ls_bot>-defcd TRANSPORTING NO FIELDS.

  IF sy-subrc <> 0.
    MESSAGE s124 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  gv_note_row = pv_index.
  REFRESH gt_note_text.
  CLEAR gt_note_text.
  IF <ls_bot>-deftx IS NOT INITIAL.
    SPLIT <ls_bot>-deftx
      AT cl_abap_char_utilities=>newline
      INTO TABLE gt_note_text.
  ENDIF.

  CALL SCREEN 0200 STARTING AT 20 5." ENDING AT 110 25.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_free_ltext_control
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_free_ltext_control.

  IF go_textedit IS BOUND.
    go_textedit->free( ).
    FREE go_textedit.
  ENDIF.

  IF go_note_con IS BOUND.
    go_note_con->free( ).
    FREE go_note_con.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form exclude_toolbar_bot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM exclude_toolbar_bot .
  CLEAR gt_exclude_bot.

  "아래 ALV에만 뜨는 편집용 표준 버튼 제거
  APPEND cl_gui_alv_grid=>mc_fc_refresh           TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy          TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row      TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut           TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste         TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo          TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row    TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row    TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row    TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_move_row      TO gt_exclude_bot.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_enqueue_lock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_enqueue_lock USING pt_qm   TYPE zttmma00131
                  CHANGING pv_lock TYPE sy-subrc.
  LOOP AT pt_qm ASSIGNING FIELD-SYMBOL(<ls_qm>).
    CALL FUNCTION 'ENQUEUE_EZ_MAT_MOVE'
      EXPORTING
        mode_ztmma00090 = 'E'
        mandt           = sy-mandt
        mblnr           = <ls_qm>-mblnr
        mjahr           = <ls_qm>-mjahr
        zeile           = <ls_qm>-gritm
*       X_MBLNR         = ' '
*       X_MJAHR         = ' '
*       X_ZEILE         = ' '
        _scope          = '1'
*       _WAIT           = ' '
*       _COLLECT        = ' '
      EXCEPTIONS
        foreign_lock    = 1
        system_failure  = 2
        OTHERS          = 3.
    pv_lock = sy-subrc.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_dequeue_lock
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_dequeue_lock USING pt_qm TYPE zttmma00131.
  LOOP AT pt_qm ASSIGNING FIELD-SYMBOL(<ls_qm>).
    CALL FUNCTION 'DEQUEUE_EZ_MAT_MOVE'
      EXPORTING
        mode_ztmma00090 = 'E'
        mandt           = sy-mandt
        mblnr           = <ls_qm>-mblnr
        mjahr           = <ls_qm>-mjahr
        zeile           = <ls_qm>-gritm
*       X_MBLNR         = ' '
*       X_MJAHR         = ' '
*       X_ZEILE         = ' '
        _scope          = '1'
*       _WAIT           = ' '
*       _COLLECT        = ' '
      EXCEPTIONS
        foreign_lock    = 1
        system_failure  = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE s087 DISPLAY LIKE 'E'.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_dequeue_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_dequeue_pr .
  CALL FUNCTION 'DEQUEUE_E_TABLE'
    EXPORTING
      mode_rstable = 'E'
      tabname      = 'ZTMMA00040'
      varkey       = space
      _scope       = '1'.
ENDFORM.
