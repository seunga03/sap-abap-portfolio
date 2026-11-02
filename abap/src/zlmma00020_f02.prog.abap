*&---------------------------------------------------------------------*
*& Include          ZLMMA00020_F02
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
  DATA: ls_hierarchy_header TYPE treev_hhdr.

  CREATE OBJECT go_con
    EXPORTING
      container_name = 'CUSTOM_CON'.

  CREATE OBJECT go_split_main
    EXPORTING
      parent  = go_con
      rows    = 1
      columns = 2.
  go_con_left = go_split_main->get_container(
                  row    = 1
                  column = 1 ).

  go_con_tree = go_split_main->get_container(
                  row    = 1
                  column = 2 ).

  CREATE OBJECT go_split_popr
    EXPORTING
      parent  = go_con_left
      rows    = 2
      columns = 1.

  go_con_pr = go_split_popr->get_container(
                row    = 1
                column = 1 ).

  go_con_po = go_split_popr->get_container(
                row    = 2
                column = 1 ).
  CREATE OBJECT go_alv_pr
    EXPORTING
      i_parent = go_con_pr.

  " 왼쪽 아래 장바구니 ALV
  CREATE OBJECT go_alv_po
    EXPORTING
      i_parent = go_con_po.

  " 오른쪽 공급업체 Tree
  ls_hierarchy_header-heading = '공급업체 후보'.
  ls_hierarchy_header-width   = 20.

  CREATE OBJECT go_tree
    EXPORTING
      parent                = go_con_tree
      node_selection_mode   = cl_gui_column_tree=>node_sel_mode_single
      item_selection        = 'X'
      hierarchy_column_name = 'HEADTEXT'
      hierarchy_header      = ls_hierarchy_header.

  PERFORM set_tree_column.
  PERFORM build_vendor_tree.
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
  SET HANDLER lcl_event_handler=>on_toolbar_pr      FOR go_alv_pr.
  SET HANDLER lcl_event_handler=>on_user_command    FOR go_alv_pr.

  SET HANDLER lcl_event_handler=>on_toolbar_po      FOR go_alv_po.
  SET HANDLER lcl_event_handler=>on_user_command    FOR go_alv_po.
  SET HANDLER lcl_event_handler=>on_f4_po FOR go_alv_po.
  go_alv_po->register_edit_event(
    EXPORTING
      i_event_id = cl_gui_alv_grid=>mc_evt_modified
  ).
  SET HANDLER lcl_event_handler=>on_tree_item_double_click FOR go_tree.
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
  gs_layo_pr-cwidth_opt = 'X'.
  gs_layo_pr-sel_mode = 'A'.



  gs_layo_po-cwidth_opt = 'X'.
*  gs_layo_po-edit       = 'X'.
  PERFORM exclude_toolbar_po.
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
      i_structure_name       = 'ZSMMA00043'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     = 'X'
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = gt_fcat_pr
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        =
      i_structure_name       = 'ZSMMA00044'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     = 'X'
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = gt_fcat_po
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  PERFORM pr_fcat_edit.
  PERFORM po_fcat_edit.
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
  DATA lt_f4 TYPE lvc_t_f4.

  CALL METHOD go_alv_pr->set_table_for_first_display
    EXPORTING
      is_layout       = gs_layo_pr
    CHANGING
      it_outtab       = gt_alv_pr
      it_fieldcatalog = gt_fcat_pr.

  " 왼쪽 아래, PO 장바구니
  CALL METHOD go_alv_po->set_table_for_first_display
    EXPORTING
      is_layout            = gs_layo_po
      it_toolbar_excluding = gt_exclude_po
    CHANGING
      it_outtab            = gt_alv_po
      it_fieldcatalog      = gt_fcat_po.

  APPEND VALUE #(
    fieldname  = 'LIFNR'
    register   = abap_true
    getbefore  = abap_true
    chngeafter = abap_true
  ) TO lt_f4.

  go_alv_po->register_f4_for_fields(
    EXPORTING
      it_f4 = lt_f4
  ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form pr_fcat_edit
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM pr_fcat_edit .
  LOOP AT gt_fcat_pr ASSIGNING FIELD-SYMBOL(<ls_fcat_pr>).
    CASE <ls_fcat_pr>-fieldname.
      WHEN 'SRTYP'.
        <ls_fcat_pr>-no_out = 'X'.
      WHEN 'ASTAT'.
        <ls_fcat_pr>-no_out = 'X'.
      WHEN 'PSTAT'.
        <ls_fcat_pr>-no_out = 'X'.
      WHEN 'ERDAT'.
        <ls_fcat_pr>-no_out = 'X'.
      WHEN 'ERZET'.
        <ls_fcat_pr>-no_out = 'X'.
      WHEN 'ERNAM'.
        <ls_fcat_pr>-no_out = 'X'.
      WHEN 'AEDAT'.
        <ls_fcat_pr>-no_out = 'X'.
      WHEN 'AEZET'.
        <ls_fcat_pr>-no_out = 'X'.
      WHEN 'AENAM'.
        <ls_fcat_pr>-no_out = 'X'.
    ENDCASE.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form po_fcat_edit
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM po_fcat_edit .
  LOOP AT gt_fcat_po ASSIGNING FIELD-SYMBOL(<ls_fcat_po>).
    CASE <ls_fcat_po>-fieldname.
      WHEN 'SRTYP'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'SRDOC'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'SRITM'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'PTYPE'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'AUSER'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'ADATE'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'LIFNR'.
        <ls_fcat_po>-edit = 'X'.
        <ls_fcat_po>-f4availabl = 'X'.
      WHEN 'PSTAT'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'ASTAT'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'ERDAT'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'ERZET'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'ERNAM'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'AEDAT'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'AEZET'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'AENAM'.
        <ls_fcat_po>-no_out = 'X'.
    ENDCASE.
  ENDLOOP.
ENDFORM.

FORM exclude_toolbar_po.

  CLEAR gt_exclude_po.

  "아래 ALV에만 뜨는 편집용 표준 버튼 제거
  APPEND cl_gui_alv_grid=>mc_fc_refresh           TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy          TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row      TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut           TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste         TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo          TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row    TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row    TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row    TO gt_exclude_po.
  APPEND cl_gui_alv_grid=>mc_fc_loc_move_row      TO gt_exclude_po.

ENDFORM.
