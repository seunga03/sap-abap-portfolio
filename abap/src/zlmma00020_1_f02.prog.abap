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

  go_split_main->set_column_width( id = 1 width = 55 ).
  go_split_main->set_column_width( id = 2 width = 45 ).
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
  ls_hierarchy_header-heading = ' 공급업체 후보'.
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



*  gs_layo_po-cwidth_opt = 'X'.
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
      it_outtab       = gt_pr_show
      it_fieldcatalog = gt_fcat_pr.

  " 왼쪽 아래, PO 장바구니
  CALL METHOD go_alv_po->set_table_for_first_display
    EXPORTING
      is_layout            = gs_layo_po
      it_toolbar_excluding = gt_exclude_po
    CHANGING
      it_outtab            = gt_po
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
      WHEN 'PTYPE'.
        <ls_fcat_pr>-no_out = 'X'.
      WHEN 'MEINS'.
        <ls_fcat_pr>-coltext = '단위'.
        <ls_fcat_pr>-outputlen = '2'.
      WHEN 'EKGRP'.
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
      WHEN 'BANFN'.
        <ls_fcat_po>-outputlen = '2'.
      WHEN 'BNFPO'.
        <ls_fcat_po>-outputlen = '1'.
      WHEN 'NETPR'.
        <ls_fcat_po>-outputlen = '6'.
      WHEN 'MAKTX'.
        <ls_fcat_po>-outputlen = '6'.
      WHEN 'MATNR'.
        <ls_fcat_po>-outputlen = '6'.
      WHEN 'SRTYP'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'SRDOC'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'WERKS'.
        <ls_fcat_po>-outputlen = '2'.
      WHEN 'WNAME'.
        <ls_fcat_po>-outputlen = '4'.
      WHEN 'LGORT'.
        <ls_fcat_po>-outputlen = '2'.
      WHEN 'LGOBE'.
        <ls_fcat_po>-outputlen = '4'.
      WHEN 'RUSER'.
        <ls_fcat_po>-outputlen = '4'.
      WHEN 'RDATE'.
        <ls_fcat_po>-outputlen = '4'.
      WHEN 'RQTY'.
        <ls_fcat_po>-outputlen = '2'.
      WHEN 'NDATE'.
        <ls_fcat_po>-outputlen = '4'.
      WHEN 'SRITM'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'PTYPE'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'AUSER'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'WAERS'.
        <ls_fcat_po>-outputlen = '2'.
      WHEN 'ADATE'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'LIFNR'.
        <ls_fcat_po>-edit = 'X'.
        <ls_fcat_po>-f4availabl = 'X'.
        <ls_fcat_po>-outputlen = '6'.
      WHEN 'LNAME'.
        <ls_fcat_po>-outputlen = '6'.
      WHEN 'BSTMI'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'PLIFZ'.
        <ls_fcat_po>-coltext = '납기 소요 기간'.
      WHEN 'PRTYP'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'EKGRP'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'PSTAT'.
        <ls_fcat_po>-no_out = 'X'.
      WHEN 'MEINS'.
        <ls_fcat_po>-coltext = '단위'.
        <ls_fcat_po>-outputlen = '2'.
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
*&---------------------------------------------------------------------*
*& Form set_tree_column
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_tree_column .

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'NETPR'
      width       = 12
      header_text = ' 계약단가'
      alignment   = cl_gui_column_tree=>align_right.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'WAERS'
      width       = 5
      header_text = ' 통화'.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'PLIFZ'
      width       = 6
      header_text = ' 납기일'.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'TSCOR'
      width       = 7
      header_text = ' 종합점수'.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'GRADE'
      width       = 4
      header_text = ' 등급'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_vendor_tree
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_vendor_tree .

  DATA: lt_node       TYPE treev_ntab,
        ls_node       TYPE treev_node,
        lt_item       TYPE STANDARD TABLE OF mtreeitm,
        ls_candidate  TYPE zsmma00045,
        lv_prev_matnr TYPE matnr,
        lv_root_key   TYPE tv_nodekey,
        lv_child_key  TYPE tv_nodekey,
        lv_node_count TYPE i,
        lv_netpr_text TYPE c LENGTH 20.

  CLEAR gt_tree_map.

*  SORT gt_lifnr BY matnr lifnr.
SORT gt_lifnr BY matnr ASCENDING
                 tscor DESCENDING
                 priok ASCENDING.

  LOOP AT gt_lifnr INTO ls_candidate.

    "자재별 부모 노드
    IF lv_prev_matnr <> ls_candidate-matnr.

      lv_node_count = lv_node_count + 1.
      lv_root_key = |MAT{ lv_node_count }|.

      CLEAR ls_node.
      ls_node-node_key  = lv_root_key.
      ls_node-relatship = cl_gui_column_tree=>relat_last_sibling.
      ls_node-isfolder  = 'X'.
      APPEND ls_node TO lt_node.

      APPEND VALUE mtreeitm(
        node_key  = lv_root_key
        item_name = 'HEADTEXT'
        class     = cl_gui_column_tree=>item_class_text
        text      = |{ ls_candidate-matnr } { ls_candidate-maktx }|
      ) TO lt_item.

      lv_prev_matnr = ls_candidate-matnr.

    ENDIF.

    "공급업체 자식 노드
    lv_node_count = lv_node_count + 1.
    lv_child_key = |VEN{ lv_node_count }|.

    "트리 노드와 공급업체 번호 연결
    INSERT VALUE ty_tree_map(
      node_key = lv_child_key
      node_type = 'V'
      matnr     = ls_candidate-matnr
      lifnr    = ls_candidate-lifnr
    ) INTO TABLE gt_tree_map.

    CLEAR ls_node.
    ls_node-node_key  = lv_child_key.
    ls_node-relatkey  = lv_root_key.
    ls_node-relatship = cl_gui_column_tree=>relat_last_child.
    APPEND ls_node TO lt_node.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'HEADTEXT'
      class     = cl_gui_column_tree=>item_class_text
      text      = ls_candidate-name1
    ) TO lt_item.

    CLEAR lv_netpr_text.

    WRITE ls_candidate-netpr TO lv_netpr_text
      CURRENCY ls_candidate-waers RIGHT-JUSTIFIED.

    CONDENSE lv_netpr_text.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'NETPR'
      class     = cl_gui_column_tree=>item_class_text
      text      = lv_netpr_text
    ) TO lt_item.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'WAERS'
      class     = cl_gui_column_tree=>item_class_text
      text      = ls_candidate-waers
    ) TO lt_item.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'PLIFZ'
      class     = cl_gui_column_tree=>item_class_text
      text      = |{ ls_candidate-plifz }일|
    ) TO lt_item.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'TSCOR'
      class     = cl_gui_column_tree=>item_class_text
      text      = ls_candidate-tscor
    ) TO lt_item.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'GRADE'
      class     = cl_gui_column_tree=>item_class_text
      text      = ls_candidate-grade
    ) TO lt_item.

  ENDLOOP.

  CALL METHOD go_tree->add_nodes_and_items
    EXPORTING
      node_table                = lt_node
      item_table                = lt_item
      item_table_structure_name = 'MTREEITM'.

  CALL METHOD go_tree->expand_root_nodes.

ENDFORM.
