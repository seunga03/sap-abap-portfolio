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
  IF go_con IS NOT BOUND.
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

    CREATE OBJECT go_splitter
      EXPORTING
        parent            = go_con
        rows              = 2
        columns           = 1
      EXCEPTIONS
        cntl_error        = 1
        cntl_system_error = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE a099.
    ENDIF.
    go_top_container = go_splitter->get_container(
      row    = 1
      column = 1 ).

    go_bottom_container = go_splitter->get_container(
      row    = 2
      column = 1 ).

    CREATE OBJECT go_top_alv
      EXPORTING
        i_parent          = go_top_container
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
      MESSAGE a099.
    ENDIF.
    CREATE OBJECT go_bottom_alv
      EXPORTING
        i_parent          = go_bottom_container
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
      MESSAGE a099.
    ENDIF.


  ELSE.
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
  gs_layo_top-cwidth_opt = 'X'.

  gs_layo_bot-zebra = 'X'.
  gs_layo_bot-sel_mode = 'A'.
  gs_layo_bot-cwidth_opt = 'X'.
  gs_layo_bot-excp_fname = 'LIGHT'.
  gs_layo_bot-excp_led = 'X'.
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
      i_structure_name       = 'ZSMMA00040'
    CHANGING
      ct_fieldcat            = gt_top_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.


  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = 'ZSMMA00047'
    CHANGING
      ct_fieldcat            = gt_bottom_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
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
  go_top_alv->set_table_for_first_display(
    EXPORTING
      is_layout       = gs_layo_top
      i_save          = 'A'
    CHANGING
      it_outtab       = gt_top
      it_fieldcatalog = gt_top_fcat ).

  go_bottom_alv->set_table_for_first_display(
    EXPORTING
      is_layout       = gs_layo_bot
      i_save          = 'A'
    CHANGING
      it_outtab       = gt_bottom
      it_fieldcatalog = gt_bottom_fcat ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_TREE_CONTAINER
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_tree_container .



  CREATE OBJECT go_con_tree
    EXPORTING
      container_name              = 'CUSTOM_TREE'
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

  PERFORM zz_create_tree.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_NODE_EVENT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_node_event .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form BUILD_NODE_TABLE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_node_table .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_f4_excel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_f4_excel.

  DATA:
    lt_file        TYPE filetable,
    ls_file        TYPE file_table,
    lv_rc          TYPE i,
    lv_user_action TYPE i.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title      = '엑셀 파일 선택'
      default_extension = 'xlsx'
      file_filter       = 'Excel Workbook (*.xlsx)|*.xlsx|'
      multiselection    = abap_false
    CHANGING
      file_table        = lt_file
      rc                = lv_rc
      user_action       = lv_user_action
    EXCEPTIONS
      OTHERS            = 1 ).

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "취소 버튼을 누른 경우
  IF lv_user_action
       <> cl_gui_frontend_services=>action_ok.
    RETURN.
  ENDIF.

  READ TABLE lt_file INTO ls_file INDEX 1.

  IF sy-subrc = 0.
    pa_file = ls_file-filename.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_create_tree
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_create_tree .
  DATA: ls_hierarchy_header TYPE treev_hhdr.
  DATA: lt_node_table TYPE treev_ntab.
  DATA: lt_item_table TYPE item_table_type.

  ls_hierarchy_header-heading = '자재 / 구매오더'.
  ls_hierarchy_header-width = 30.

  CREATE OBJECT go_tree
    EXPORTING
      parent                      = go_con_tree
      node_selection_mode         = cl_gui_column_tree=>node_sel_mode_single
      item_selection              = 'X'                 " Can Individual Items be Selected?
      hierarchy_column_name       = 'HEADTEXT'                 " Name of the Column in Hierarchy Area
      hierarchy_header            = ls_hierarchy_header                " Hierarchy Header
    EXCEPTIONS
      lifetime_error              = 1
      cntl_system_error           = 2
      create_error                = 3
      failed                      = 4
      illegal_node_selection_mode = 5
      OTHERS                      = 6.
  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'ACISS'
      width       = 20
      header_text = '실제 지급량'.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'ACUSE'
      width       = 20
      header_text = '실제 사용량'.



*  PERFORM build_node_and_item_table USING lt_node_table lt_item_table.
  PERFORM zz_set_column_tree.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_node_and_item_table
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> NODE_TABLE
*&      --> ITEM_TABLE
*&---------------------------------------------------------------------*
FORM build_node_and_item_table
  USING    pt_node_table TYPE treev_ntab
           pt_item_table TYPE item_table_type.

  DATA: ls_node       TYPE treev_node,
        ls_item       TYPE mtreeitm,
        ls_all        TYPE zsmma00047,
        lt_bottom     TYPE TABLE OF zsmma00047,
        lv_parent_key TYPE tv_nodekey,
        lv_give_qty   TYPE zsmma00042-aciss,
        lv_use_qty    TYPE zsmma00042-acuse,
        lv_seq        TYPE n LENGTH 4.

  MOVE-CORRESPONDING gt_bottom TO lt_bottom.

  SORT lt_bottom BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_bottom COMPARING matnr.

  LOOP AT lt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).

    ADD 1 TO lv_seq.
    lv_parent_key = lv_seq.

    "자재 부모 노드
    CLEAR ls_node.
    ls_node-node_key = lv_parent_key.
    ls_node-isfolder = 'X'.
    ls_node-expander = 'X'.

    APPEND ls_node TO pt_node_table.

    "자재별 지급량 / 사용량 합계
    CLEAR: lv_give_qty, lv_use_qty.

    LOOP AT gt_bottom INTO ls_all
         WHERE matnr = <ls_bottom>-matnr.

      ADD ls_all-aciss TO lv_give_qty.
      ADD ls_all-acuse TO lv_use_qty.

    ENDLOOP.

    "자재번호
    CLEAR ls_item.
    ls_item-node_key  = lv_parent_key.
    ls_item-item_name = 'HEADTEXT'.
    ls_item-class     = cl_gui_column_tree=>item_class_text.
    ls_item-text      = <ls_bottom>-matnr.

    APPEND ls_item TO pt_item_table.

    "자재별 지급량
    CLEAR ls_item.
    ls_item-node_key  = lv_parent_key.
    ls_item-item_name = 'ACISS'.
    ls_item-class     = cl_gui_column_tree=>item_class_text.

    WRITE lv_give_qty TO ls_item-text.
    CONDENSE ls_item-text.

    APPEND ls_item TO pt_item_table.

    "자재별 사용량
    CLEAR ls_item.
    ls_item-node_key  = lv_parent_key.
    ls_item-item_name = 'ACUSE'.
    ls_item-class     = cl_gui_column_tree=>item_class_text.

    WRITE lv_use_qty TO ls_item-text.
    CONDENSE ls_item-text.

    APPEND ls_item TO pt_item_table.

    "같은 자재의 PO 자식 노드
    LOOP AT gt_bottom INTO ls_all
         WHERE matnr = <ls_bottom>-matnr.

      ADD 1 TO lv_seq.

      CLEAR ls_node.
      ls_node-node_key  = lv_seq.
      ls_node-relatkey  = lv_parent_key.
      ls_node-relatship = cl_gui_column_tree=>relat_last_child.

      APPEND ls_node TO pt_node_table.

      "PO 번호 / 품목
      CLEAR ls_item.
      ls_item-node_key  = lv_seq.
      ls_item-item_name = 'HEADTEXT'.
      ls_item-class     = cl_gui_column_tree=>item_class_text.

      CONCATENATE ls_all-ebeln ls_all-ebelp
             INTO ls_item-text
             SEPARATED BY '-'.

      APPEND ls_item TO pt_item_table.

      "PO별 지급량
      CLEAR ls_item.
      ls_item-node_key  = lv_seq.
      ls_item-item_name = 'ACISS'.
      ls_item-class     = cl_gui_column_tree=>item_class_text.

      WRITE ls_all-aciss TO ls_item-text.
      CONDENSE ls_item-text.

      APPEND ls_item TO pt_item_table.

      "PO별 사용량
      CLEAR ls_item.
      ls_item-node_key  = lv_seq.
      ls_item-item_name = 'ACUSE'.
      ls_item-class     = cl_gui_column_tree=>item_class_text.

      WRITE ls_all-acuse TO ls_item-text.
      CONDENSE ls_item-text.

      APPEND ls_item TO pt_item_table.

    ENDLOOP.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_data.
  DATA : lt_alsmex TYPE gty_alsmex_tab.
  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
    EXPORTING
      filename                = pa_file
      i_begin_col             = 1
      i_begin_row             = 2
      i_end_col               = 22
      i_end_row               = 1000
    TABLES
      intern                  = lt_alsmex
    EXCEPTIONS
      inconsistent_parameters = 1
      upload_ole              = 2
      OTHERS                  = 3.
  IF sy-subrc <> 0.
    MESSAGE e059.
  ENDIF.

  PERFORM zz_set_excel_data USING lt_alsmex.
  PERFORM zz_get_extra_data.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_excel_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_ALSMEX
*&---------------------------------------------------------------------*
FORM zz_set_excel_data USING pt_alsmex TYPE gty_alsmex_tab.
  DATA : lt_dfies           TYPE TABLE OF dfies,
         lv_value           TYPE alsmex_tabline-value,
         lv_function_name   TYPE rs38l_fnam,
         lv_amount_internal TYPE wmto_s-amount.

  DATA : lv_currency       TYPE tcurc-waers,
         lv_amount_display TYPE wmto_s-amount.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname   = 'ZSMMA00042'
    TABLES
      dfies_tab = lt_dfies.

  LOOP AT pt_alsmex ASSIGNING FIELD-SYMBOL(<ls_alsmex>).
    CLEAR lv_value.
    lv_value = <ls_alsmex>-value.

    ASSIGN COMPONENT <ls_alsmex>-col OF STRUCTURE gs_excel TO FIELD-SYMBOL(<fs_field>).
    READ TABLE lt_dfies ASSIGNING FIELD-SYMBOL(<ls_dfies>) INDEX <ls_alsmex>-col.
    TRY.
        IF sy-subrc EQ 0.
          CASE <ls_dfies>-inttype.
            WHEN 'P'.
              REPLACE ALL OCCURRENCES OF ',' IN <ls_alsmex>-value WITH space.
              CONDENSE lv_value NO-GAPS.
            WHEN 'D'.
              REPLACE ALL OCCURRENCES OF '-' IN <ls_alsmex>-value WITH space.
              REPLACE ALL OCCURRENCES OF '.' IN <ls_alsmex>-value WITH space.
              REPLACE ALL OCCURRENCES OF '/' IN <ls_alsmex>-value WITH space.
              CONDENSE lv_value NO-GAPS.
          ENDCASE.
          IF <ls_dfies>-convexit IS NOT INITIAL.
            DATA(function_name) = 'CONVERSION_EXIT_' && <ls_dfies>-convexit && '_INPUT'.
            CALL FUNCTION function_name
              EXPORTING
                input  = <ls_alsmex>-value
              IMPORTING
                output = <fs_field>.
          ELSE.
            <fs_field> = lv_value.
          ENDIF.
        ENDIF.
      CATCH cx_sy_conversion_error.
        CLEAR <fs_field>.
    ENDTRY.
    AT END OF row.
      APPEND gs_excel TO gt_excel.
      CLEAR gs_excel.

    ENDAT.
  ENDLOOP.
  MOVE-CORRESPONDING gt_excel TO gt_bottom.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_extra_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_extra_data .

  DATA lt_item_key TYPE HASHED TABLE OF ty_po_key WITH UNIQUE KEY ebeln ebelp.
  DATA : lv_ebeln TYPE ebeln.

  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
    INSERT VALUE #(
      ebeln = <ls_bottom>-ebeln
      ebelp = <ls_bottom>-ebelp
    ) INTO TABLE lt_item_key.
  ENDLOOP.

  IF lt_item_key IS NOT INITIAL.
    SELECT *
      FROM ztmma00060
      FOR ALL ENTRIES IN @lt_item_key
      WHERE ebeln = @lt_item_key-ebeln
        AND ebelp = @lt_item_key-ebelp
      INTO CORRESPONDING FIELDS OF TABLE @gt_top.
  ENDIF.

  READ TABLE gt_top INTO lv_ebeln INDEX 1.

  SELECT SINGLE lifnr
    FROM ztmma00050
    WHERE ebeln = @lv_ebeln
    INTO @DATA(lv_lifnr).

  SELECT SINGLE a~dscor, a~qscor, a~pscor, a~tscor, a~grade, a~lifnr, b~name1
    FROM ztmma00100 AS a
    INNER JOIN ztcma00010 AS b
    ON a~lifnr = b~lifnr
    WHERE a~lifnr = @lv_lifnr
      AND a~datab <= @sy-datum
      AND a~datbi >= @sy-datum
    INTO CORRESPONDING FIELDS OF @zsmma00041.

  PERFORM zz_set_light.
  PERFORM zz_set_column_tree.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_bom
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_bom.

  SELECT *
    FROM ztcma00120
    WHERE stlst    = '01'
      AND datuv    <= @sy-datum
      AND valid_to >= @sy-datum
    INTO TABLE @gt_bom_head.

  IF gt_bom_head IS NOT INITIAL.
    SELECT *
      FROM ztcma00130
      FOR ALL ENTRIES IN @gt_bom_head
      WHERE stlnr = @gt_bom_head-stlnr
      INTO TABLE @gt_bom_item.
  ENDIF.

  SORT gt_bom_head BY matnr werks stlnr.
  SORT gt_bom_item BY stlnr stlkn.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_bom_bfs
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_bom_bfs .
  DATA: lt_queue TYPE STANDARD TABLE OF ty_bom_req WITH EMPTY KEY,
        lv_head  TYPE i VALUE 1.
  DATA lv_child_qty TYPE ztcma00130-menge.

  LOOP AT gt_top ASSIGNING FIELD-SYMBOL(<ls_top>). "po 물품 돌면서 bom 전개
    APPEND INITIAL LINE TO lt_queue ASSIGNING FIELD-SYMBOL(<ls_queue>). "po에 따른 matnr 큐에 삽입
    <ls_queue>-ebeln = <ls_top>-ebeln.
    <ls_queue>-ebelp = <ls_top>-ebelp.
    <ls_queue>-matnr = <ls_top>-matnr.
    <ls_queue>-werks = <ls_top>-werks.
    <ls_queue>-meins = <ls_top>-meins.
    <ls_queue>-menge = <ls_top>-menge.
    <ls_queue>-lv_level = lv_head.

    WHILE lv_head <= lines( lt_queue ). "큐가 빌 때까지
      READ TABLE lt_queue ASSIGNING FIELD-SYMBOL(<ls_queue_1>) INDEX lv_head. "큐 읽기.
      lv_head += 1.

      "헤드에 해당 물품이 없으면 마지막
      READ TABLE gt_bom_head ASSIGNING FIELD-SYMBOL(<ls_head>) WITH KEY matnr = <ls_queue_1>-matnr
                                                                       werks = <ls_queue_1>-werks.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      "아이템 돌면서 해당 자재 모두 큐에 넣음.
      LOOP AT gt_bom_item ASSIGNING FIELD-SYMBOL(<ls_item>) WHERE stlnr = <ls_head>-stlnr.

        lv_child_qty = <ls_queue_1>-menge * <ls_item>-menge / <ls_head>-bmeng.

        READ TABLE gt_bom_req ASSIGNING FIELD-SYMBOL(<ls_bom_req>) WITH KEY ebeln = <ls_queue_1>-ebeln
                                                                            ebelp = <ls_queue_1>-ebelp
                                                                            matnr = <ls_item>-idnrk
                                                                            werks = <ls_queue_1>-werks
                                                                            meins = <ls_item>-meins.
        IF sy-subrc = 0.
          <ls_bom_req>-menge += lv_child_qty.
        ELSE.
          INSERT VALUE #(
            ebeln = <ls_queue_1>-ebeln
            ebelp = <ls_queue_1>-ebelp
            matnr = <ls_item>-idnrk
            werks = <ls_queue>-werks
            menge = lv_child_qty
            meins = <ls_item>-meins
          ) INTO TABLE gt_bom_req.
        ENDIF.

        APPEND INITIAL LINE TO lt_queue ASSIGNING FIELD-SYMBOL(<ls_q>).
        <ls_q>-ebeln = <ls_queue_1>-ebeln.
        <ls_q>-ebelp = <ls_queue_1>-ebelp.
        <ls_q>-matnr = <ls_item>-idnrk.
        <ls_q>-werks = <ls_queue_1>-werks.
        <ls_q>-meins = <ls_item>-meins.
        <ls_q>-menge = lv_child_qty.
        <ls_q>-lv_level = lv_head.

      ENDLOOP.
    ENDWHILE.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_column_tree
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_column_tree.

  DATA: lt_node_table TYPE treev_ntab,
        lt_item_table TYPE item_table_type.

  IF go_tree IS NOT BOUND.
    RETURN.
  ENDIF.

  "재조회 또는 엑셀 재업로드 시 기존 트리 제거
  CALL METHOD go_tree->delete_all_nodes.

  PERFORM build_node_and_item_table
    USING lt_node_table lt_item_table.

  IF lt_node_table IS INITIAL.
    CALL METHOD cl_gui_cfw=>flush.
    RETURN.
  ENDIF.

  CALL METHOD go_tree->add_nodes_and_items
    EXPORTING
      node_table                = lt_node_table
      item_table                = lt_item_table
      item_table_structure_name = 'MTREEITM'
    EXCEPTIONS
      failed                    = 1
      cntl_system_error         = 2
      OTHERS                    = 3.

  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.

  "자재 부모 노드 펼치기
  CALL METHOD go_tree->expand_root_nodes
    EXPORTING
      level_count = 1.

  CALL METHOD cl_gui_cfw=>flush.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_light
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_light .
  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
    IF <ls_bottom>-aciss = <ls_bottom>-acuse.
      <ls_bottom>-light = '3'.
    ELSE.
      <ls_bottom>-light = '1'.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_make_docu
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_make_docu .

  DATA: lt_110        TYPE TABLE OF ztmma00110,
        lv_cevno      TYPE zde_ceval,
        lt_return     TYPE TABLE OF bapiret2,
        lt_revalid    TYPE ty_t_revalid,
        lt_done_rqnum TYPE SORTED TABLE OF ztexa00060-rqnum
                        WITH UNIQUE KEY table_line,
        lt_created    TYPE SORTED TABLE OF ty_revalid
                        WITH UNIQUE KEY ebeln ebelp.

  PERFORM zz_get_revalid CHANGING lt_revalid.

  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).

    CLEAR: lv_cevno, lt_return.

    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr = '01'
        object      = 'ZMM_CEVNO'
      IMPORTING
        number      = lv_cevno.

    APPEND INITIAL LINE TO lt_110 ASSIGNING FIELD-SYMBOL(<ls_110>).
    MOVE-CORRESPONDING <ls_bottom> TO <ls_110>.

    <ls_110>-cevno = lv_cevno.
    <ls_110>-cfdat = sy-datum.
    <ls_110>-cfusr = sy-uname.
    <ls_110>-ernam = sy-uname.
    <ls_110>-erdat = sy-datum.
    <ls_110>-erzet = sy-uzeit.

    LOOP AT lt_revalid ASSIGNING FIELD-SYMBOL(<ls_revalid>)
      WHERE ebeln = <ls_bottom>-ebeln
        AND ebelp = <ls_bottom>-ebelp.

      INSERT <ls_revalid>-rqnum INTO TABLE lt_done_rqnum.

    ENDLOOP.

    IF <ls_bottom>-light = '1'.

      <ls_110>-rcsts = '0010'.

      IF NOT line_exists( lt_revalid[
        ebeln = <ls_bottom>-ebeln
        ebelp = <ls_bottom>-ebelp ] ).

        READ TABLE lt_created TRANSPORTING NO FIELDS
          WITH KEY ebeln = <ls_bottom>-ebeln
                   ebelp = <ls_bottom>-ebelp.

        IF sy-subrc <> 0.

          CALL FUNCTION 'ZCM_EXC_CREATE'
            EXPORTING
              iv_srtyp  = 'SUBC'
              iv_srnum  = lv_cevno
              iv_sritm  = 00000
              iv_owgrp  = 'MM'
              iv_extyp  = 'PROC'
            IMPORTING
              et_return = lt_return.

          IF line_exists( lt_return[ type = 'E' ] )
          OR line_exists( lt_return[ type = 'A' ] )
          OR line_exists( lt_return[ type = 'X' ] ).

            ROLLBACK WORK.
            MESSAGE s100 WITH '예외 요청 생성에 실패했습니다'
              DISPLAY LIKE 'E'.
            RETURN.

          ENDIF.

          INSERT VALUE #(
            ebeln = <ls_bottom>-ebeln
            ebelp = <ls_bottom>-ebelp
          ) INTO TABLE lt_created.

        ENDIF.

      ENDIF.

    ELSE.
      <ls_110>-rcsts = '0020'.
    ENDIF.

  ENDLOOP.

  MODIFY ztmma00110 FROM TABLE lt_110.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE s100 WITH '검수 문서 저장에 실패했습니다'
      DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_done_rqnum ASSIGNING FIELD-SYMBOL(<lv_rqnum>).

    CLEAR lt_return.

    CALL FUNCTION 'ZCM_EXC_REQ_DONE'
      EXPORTING
        iv_rqnum = <lv_rqnum>
        iv_rstxt = '재평가 완료'
      IMPORTING
        et_return = lt_return.

    IF line_exists( lt_return[ type = 'E' ] )
    OR line_exists( lt_return[ type = 'A' ] )
    OR line_exists( lt_return[ type = 'X' ] ).

      ROLLBACK WORK.
      MESSAGE s100 WITH '재검증 요청 완료 처리에 실패했습니다'
        DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

  ENDLOOP.

  COMMIT WORK.

  MESSAGE s070.
  gv_check = abap_true.

ENDFORM.

*FORM zz_make_docu .
*
*  DATA: lt_110        TYPE TABLE OF ztmma00110,
*        lv_cevno      TYPE zde_ceval,
*        lv_srnum      TYPE ztexa00010-srnum,
*        lt_return     TYPE TABLE OF bapiret2,
*        lt_revalid    TYPE ty_t_revalid,
*        lt_done_rqnum TYPE SORTED TABLE OF ztexa00060-rqnum
*                        WITH UNIQUE KEY table_line,
*        lt_created    TYPE SORTED TABLE OF ty_revalid
*                        WITH UNIQUE KEY ebeln ebelp.
*
*  PERFORM zz_get_revalid CHANGING lt_revalid.
*
*  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
*
*    CLEAR: lv_cevno, lv_srnum, lt_return.
*
*    CALL FUNCTION 'NUMBER_GET_NEXT'
*      EXPORTING
*        nr_range_nr = '01'
*        object      = 'ZMM_CEVNO'
*      IMPORTING
*        number      = lv_cevno.
*
*    APPEND INITIAL LINE TO lt_110 ASSIGNING FIELD-SYMBOL(<ls_110>).
*    MOVE-CORRESPONDING <ls_bottom> TO <ls_110>.
*
*    <ls_110>-cevno = lv_cevno.
*    <ls_110>-cfdat = sy-datum.
*    <ls_110>-cfusr = sy-uname.
*    <ls_110>-ernam = sy-uname.
*    <ls_110>-erdat = sy-datum.
*    <ls_110>-erzet = sy-uzeit.
*
*    IF <ls_bottom>-light = '1'.
*
*      <ls_110>-rcsts = '0010'.
*
*      "기존 재검증 요청에 연결된 PO/품목인지 확인
*      READ TABLE lt_revalid ASSIGNING FIELD-SYMBOL(<ls_revalid>)
*        WITH KEY ebeln = <ls_bottom>-ebeln
*                 ebelp = <ls_bottom>-ebelp.
*
*      IF sy-subrc = 0.
*
*        "기존 요청은 신규 생성하지 않고 완료 처리 대상으로만 저장
*        INSERT <ls_revalid>-rqnum INTO TABLE lt_done_rqnum.
*
*      ELSE.
*
*        "이번 실행에서 동일 PO/품목 예외를 이미 생성했는지 확인
*        READ TABLE lt_created TRANSPORTING NO FIELDS
*          WITH KEY ebeln = <ls_bottom>-ebeln
*                   ebelp = <ls_bottom>-ebelp.
*
*        IF sy-subrc <> 0.
*
*          lv_srnum = lv_cevno.
*
*          CALL FUNCTION 'ZCM_EXC_CREATE'
*            EXPORTING
*              iv_srtyp  = 'SUBC'
*              iv_srnum  = lv_srnum
*              iv_sritm  = 00000
*              iv_owgrp  = 'MM'
*              iv_extyp  = 'PROC'
*            IMPORTING
*              et_return = lt_return.
*
*          READ TABLE lt_return WITH KEY type = 'E'
*            TRANSPORTING NO FIELDS.
*
*          IF sy-subrc = 0.
*            ROLLBACK WORK.
*            MESSAGE s100 WITH '예외 요청 생성에 실패했습니다'
*              DISPLAY LIKE 'E'.
*            RETURN.
*          ENDIF.
*
*          INSERT VALUE #(
*            ebeln = <ls_bottom>-ebeln
*            ebelp = <ls_bottom>-ebelp
*          ) INTO TABLE lt_created.
*
*        ENDIF.
*      ENDIF.
*
*    ELSE.
*      <ls_110>-rcsts = '0020'.
*    ENDIF.
*
*  ENDLOOP.
*
*  MODIFY ztmma00110 FROM TABLE lt_110.
*
*  IF sy-subrc <> 0.
*    ROLLBACK WORK.
*    MESSAGE s100 WITH '검수 문서 저장에 실패했습니다'
*      DISPLAY LIKE 'E'.
*    RETURN.
*  ENDIF.
*
*  LOOP AT lt_done_rqnum ASSIGNING FIELD-SYMBOL(<lv_rqnum>).
*
*    CLEAR lt_return.
*
*    CALL FUNCTION 'ZCM_EXC_REQ_DONE'
*      EXPORTING
*        iv_rqnum  = <lv_rqnum>
*        iv_rstxt  = '재평가 완료'
*      IMPORTING
*        et_return = lt_return.
*
*    READ TABLE lt_return WITH KEY type = 'E'
*      TRANSPORTING NO FIELDS.
*
*    IF sy-subrc = 0.
*      ROLLBACK WORK.
*      MESSAGE s100 WITH '재검증 요청 완료 처리에 실패했습니다'
*        DISPLAY LIKE 'E'.
*      RETURN.
*    ENDIF.
*
*  ENDLOOP.
*
*  COMMIT WORK.
*
*  MESSAGE s070.
*  gv_check = abap_true.
*
*ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_revalid
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_revalid CHANGING pt_revalid TYPE ty_t_revalid.

  DATA: lt_return    TYPE TABLE OF bapiret2,
        lt_exreq_key TYPE ztt_exreq,
        lt_exreq     TYPE ztt_exreq.

  CLEAR pt_revalid.

  CALL FUNCTION 'ZCM_EXC_REQ_GET'
    EXPORTING
      iv_tgpgm  = 'MM04'
    IMPORTING
      et_req    = lt_exreq
      et_return = lt_return.

  READ TABLE lt_return WITH KEY type = 'E'
    TRANSPORTING NO FIELDS.

  IF sy-subrc = 0.
    MESSAGE s100 WITH '재검증 요청 목록 조회에 실패했습니다'
      DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_exreq ASSIGNING FIELD-SYMBOL(<ls_exreq>)
       WHERE srtyp = 'SUBC'
       AND acttp = 'RCHK'. ""10-16 추가

    APPEND VALUE #(
      srnum = <ls_exreq>-srnum
      rqnum = <ls_exreq>-rqnum
    ) TO lt_exreq_key.

  ENDLOOP.

  IF lt_exreq_key IS INITIAL.
    RETURN.
  ENDIF.

  SORT lt_exreq_key BY srnum rqnum.
  DELETE ADJACENT DUPLICATES FROM lt_exreq_key COMPARING srnum rqnum.

  SELECT cevno, ebeln, ebelp
    FROM ztmma00110
    FOR ALL ENTRIES IN @lt_exreq_key
    WHERE cevno = @lt_exreq_key-srnum
    INTO TABLE @DATA(lt_old_docu).

  LOOP AT lt_old_docu ASSIGNING FIELD-SYMBOL(<ls_old_docu>).

    LOOP AT lt_exreq_key ASSIGNING FIELD-SYMBOL(<ls_exreq_key>)
         WHERE srnum = <ls_old_docu>-cevno.

      INSERT VALUE #(
        ebeln = <ls_old_docu>-ebeln
        ebelp = <ls_old_docu>-ebelp
        srnum = <ls_exreq_key>-srnum
        rqnum = <ls_exreq_key>-rqnum
      ) INTO TABLE pt_revalid.

    ENDLOOP.

  ENDLOOP.

ENDFORM.

** 655 외주 정합성 검사 수정본
** 기존 gt_top / gt_bottom / ALV / 트리 / 저장 FORM 유지.
** 신규 전역 선언, DDIC 필드, 텍스트 심볼, 보조 FORM 없음.
** gt_bom_req는 PO 자재의 직접 하위 BOM만 보관.
** 655 문서는 외주를 맡긴 PO의 EBELN/EBELP로 누적 조회.
** 실제 지급량은 PO/품목/구성자재/플랜트/창고/단위별 합산.
** 신호등 정상 조건: 655 실제 지급량 = 엑셀 ACISS = 엑셀 ACUSE.
** 엑셀 수량 원본 유지. 트리는 기존대로 엑셀 ACISS/ACUSE 표시.
** 취소/반품 이동유형은 정의되지 않아 655만 집계.
** SAP에서 활성화 및 실제 데이터 실행 확인 필요.
*
**&---------------------------------------------------------------------*
**& Include          ZLMMA00010_F01
**&---------------------------------------------------------------------*
**&---------------------------------------------------------------------*
**& Form create_object
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM create_object .
*  IF go_con IS NOT BOUND.
*    CREATE OBJECT go_con
*      EXPORTING
*        container_name              = 'CUSTOM_CON'
*      EXCEPTIONS
*        cntl_error                  = 1
*        cntl_system_error           = 2
*        create_error                = 3
*        lifetime_error              = 4
*        lifetime_dynpro_dynpro_link = 5
*        OTHERS                      = 6.
*    IF sy-subrc <> 0.
*      MESSAGE a099.
*    ENDIF.
*
*    CREATE OBJECT go_splitter
*      EXPORTING
*        parent            = go_con
*        rows              = 2
*        columns           = 1
*      EXCEPTIONS
*        cntl_error        = 1
*        cntl_system_error = 2
*        OTHERS            = 3.
*    IF sy-subrc <> 0.
*      MESSAGE a099.
*    ENDIF.
*    go_top_container = go_splitter->get_container(
*      row    = 1
*      column = 1 ).
*
*    go_bottom_container = go_splitter->get_container(
*      row    = 2
*      column = 1 ).
*
*    CREATE OBJECT go_top_alv
*      EXPORTING
*        i_parent          = go_top_container
*      EXCEPTIONS
*        error_cntl_create = 1
*        error_cntl_init   = 2
*        error_cntl_link   = 3
*        error_dp_create   = 4
*        OTHERS            = 5.
*    IF sy-subrc <> 0.
*      MESSAGE a099.
*    ENDIF.
*    CREATE OBJECT go_bottom_alv
*      EXPORTING
*        i_parent          = go_bottom_container
*      EXCEPTIONS
*        error_cntl_create = 1
*        error_cntl_init   = 2
*        error_cntl_link   = 3
*        error_dp_create   = 4
*        OTHERS            = 5.
*    IF sy-subrc <> 0.
*      MESSAGE a099.
*    ENDIF.
*
*
*  ELSE.
*  ENDIF.
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form set_event_handler
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM set_event_handler .
*
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form set_alv_variant
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM set_alv_variant .
*
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form set_alv_layout
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM set_alv_layout .
*  gs_layo_top-zebra = 'X'.
*  gs_layo_top-sel_mode = 'A'.
*  gs_layo_top-cwidth_opt = 'X'.
*
*  gs_layo_bot-zebra = 'X'.
*  gs_layo_bot-sel_mode = 'A'.
*  gs_layo_bot-cwidth_opt = 'X'.
*  gs_layo_bot-excp_fname = 'LIGHT'.
*  gs_layo_bot-excp_led = 'X'.
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form set_field_catalog
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM set_field_catalog .
*  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
*    EXPORTING
*      i_structure_name       = 'ZSMMA00040'
*    CHANGING
*      ct_fieldcat            = gt_top_fcat
*    EXCEPTIONS
*      inconsistent_interface = 1
*      program_error          = 2
*      OTHERS                 = 3.
*
*
*  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
*    EXPORTING
*      i_structure_name       = 'ZSMMA00047'
*    CHANGING
*      ct_fieldcat            = gt_bottom_fcat
*    EXCEPTIONS
*      inconsistent_interface = 1
*      program_error          = 2
*      OTHERS                 = 3.
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form display_alv
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM display_alv .
*  go_top_alv->set_table_for_first_display(
*    EXPORTING
*      is_layout       = gs_layo_top
*      i_save          = 'A'
*    CHANGING
*      it_outtab       = gt_top
*      it_fieldcatalog = gt_top_fcat ).
*
*  go_bottom_alv->set_table_for_first_display(
*    EXPORTING
*      is_layout       = gs_layo_bot
*      i_save          = 'A'
*    CHANGING
*      it_outtab       = gt_bottom
*      it_fieldcatalog = gt_bottom_fcat ).
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form CREATE_TREE_CONTAINER
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM create_tree_container .
*
*
*
*  CREATE OBJECT go_con_tree
*    EXPORTING
*      container_name              = 'CUSTOM_TREE'
*    EXCEPTIONS
*      cntl_error                  = 1
*      cntl_system_error           = 2
*      create_error                = 3
*      lifetime_error              = 4
*      lifetime_dynpro_dynpro_link = 5
*      OTHERS                      = 6.
*  IF sy-subrc <> 0.
*    MESSAGE a099.
*  ENDIF.
*
*  PERFORM zz_create_tree.
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form CREATE_NODE_EVENT
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM create_node_event .
*
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form BUILD_NODE_TABLE
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM build_node_table .
*
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form zz_f4_excel
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_f4_excel.
*
*  DATA:
*    lt_file        TYPE filetable,
*    ls_file        TYPE file_table,
*    lv_rc          TYPE i,
*    lv_user_action TYPE i.
*
*  cl_gui_frontend_services=>file_open_dialog(
*    EXPORTING
*      window_title      = CONV string( TEXT-t03 )
*      default_extension = 'xlsx'
*      file_filter       = 'Excel Workbook (*.xlsx)|*.xlsx|'
*      multiselection    = abap_false
*    CHANGING
*      file_table        = lt_file
*      rc                = lv_rc
*      user_action       = lv_user_action
*    EXCEPTIONS
*      OTHERS            = 1 ).
*
*  IF sy-subrc <> 0.
*    RETURN.
*  ENDIF.
*
*  "취소 버튼을 누른 경우
*  IF lv_user_action
*       <> cl_gui_frontend_services=>action_ok.
*    RETURN.
*  ENDIF.
*
*  READ TABLE lt_file INTO ls_file INDEX 1.
*
*  IF sy-subrc = 0.
*    pa_file = ls_file-filename.
*  ENDIF.
*
*ENDFORM.
*
**&---------------------------------------------------------------------*
**& Form zz_create_tree
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_create_tree .
*  DATA: ls_hierarchy_header TYPE treev_hhdr.
*  DATA: lt_node_table TYPE treev_ntab.
*  DATA: lt_item_table TYPE item_table_type.
*
*  ls_hierarchy_header-heading = TEXT-t04.
*  ls_hierarchy_header-width = 30.
*
*  CREATE OBJECT go_tree
*    EXPORTING
*      parent                      = go_con_tree
*      node_selection_mode         = cl_gui_column_tree=>node_sel_mode_single
*      item_selection              = 'X'                 " Can Individual Items be Selected?
*      hierarchy_column_name       = 'HEADTEXT'                 " Name of the Column in Hierarchy Area
*      hierarchy_header            = ls_hierarchy_header                " Hierarchy Header
*    EXCEPTIONS
*      lifetime_error              = 1
*      cntl_system_error           = 2
*      create_error                = 3
*      failed                      = 4
*      illegal_node_selection_mode = 5
*      OTHERS                      = 6.
*  IF sy-subrc <> 0.
*    MESSAGE a099.
*  ENDIF.
*
*  CALL METHOD go_tree->add_column
*    EXPORTING
*      name        = 'ACISS'
*      width       = 20
*      header_text = TEXT-t05.
*
*  CALL METHOD go_tree->add_column
*    EXPORTING
*      name        = 'ACUSE'
*      width       = 20
*      header_text = TEXT-t06.
*
*
*
**  PERFORM build_node_and_item_table USING lt_node_table lt_item_table.
*  PERFORM zz_set_column_tree.
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form build_node_and_item_table
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**&      --> NODE_TABLE
**&      --> ITEM_TABLE
**&---------------------------------------------------------------------*
*FORM build_node_and_item_table
*  USING    pt_node_table TYPE treev_ntab
*           pt_item_table TYPE item_table_type.
*
*  DATA: ls_node       TYPE treev_node,
*        ls_item       TYPE mtreeitm,
*        ls_all        TYPE zsmma00047,
*        lt_bottom     TYPE TABLE OF zsmma00047,
*        lv_parent_key TYPE tv_nodekey,
*        lv_give_qty   TYPE zsmma00042-aciss,
*        lv_use_qty    TYPE zsmma00042-acuse,
*        lv_seq        TYPE n LENGTH 4.
*
*  MOVE-CORRESPONDING gt_bottom TO lt_bottom.
*
*  SORT lt_bottom BY matnr.
*  DELETE ADJACENT DUPLICATES FROM lt_bottom COMPARING matnr.
*
*  LOOP AT lt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
*
*    ADD 1 TO lv_seq.
*    lv_parent_key = lv_seq.
*
*    "자재 부모 노드
*    CLEAR ls_node.
*    ls_node-node_key = lv_parent_key.
*    ls_node-isfolder = 'X'.
*    ls_node-expander = 'X'.
*
*    APPEND ls_node TO pt_node_table.
*
*    "자재별 지급량 / 사용량 합계
*    CLEAR: lv_give_qty, lv_use_qty.
*
*    LOOP AT gt_bottom INTO ls_all
*         WHERE matnr = <ls_bottom>-matnr.
*
*      ADD ls_all-aciss TO lv_give_qty.
*      ADD ls_all-acuse TO lv_use_qty.
*
*    ENDLOOP.
*
*    "자재번호
*    CLEAR ls_item.
*    ls_item-node_key  = lv_parent_key.
*    ls_item-item_name = 'HEADTEXT'.
*    ls_item-class     = cl_gui_column_tree=>item_class_text.
*    ls_item-text      = <ls_bottom>-matnr.
*
*    APPEND ls_item TO pt_item_table.
*
*    "자재별 지급량
*    CLEAR ls_item.
*    ls_item-node_key  = lv_parent_key.
*    ls_item-item_name = 'ACISS'.
*    ls_item-class     = cl_gui_column_tree=>item_class_text.
*
*    WRITE lv_give_qty TO ls_item-text.
*    CONDENSE ls_item-text.
*
*    APPEND ls_item TO pt_item_table.
*
*    "자재별 사용량
*    CLEAR ls_item.
*    ls_item-node_key  = lv_parent_key.
*    ls_item-item_name = 'ACUSE'.
*    ls_item-class     = cl_gui_column_tree=>item_class_text.
*
*    WRITE lv_use_qty TO ls_item-text.
*    CONDENSE ls_item-text.
*
*    APPEND ls_item TO pt_item_table.
*
*    "같은 자재의 PO 자식 노드
*    LOOP AT gt_bottom INTO ls_all
*         WHERE matnr = <ls_bottom>-matnr.
*
*      ADD 1 TO lv_seq.
*
*      CLEAR ls_node.
*      ls_node-node_key  = lv_seq.
*      ls_node-relatkey  = lv_parent_key.
*      ls_node-relatship = cl_gui_column_tree=>relat_last_child.
*
*      APPEND ls_node TO pt_node_table.
*
*      "PO 번호 / 품목
*      CLEAR ls_item.
*      ls_item-node_key  = lv_seq.
*      ls_item-item_name = 'HEADTEXT'.
*      ls_item-class     = cl_gui_column_tree=>item_class_text.
*
*      CONCATENATE ls_all-ebeln ls_all-ebelp
*             INTO ls_item-text
*             SEPARATED BY '-'.
*
*      APPEND ls_item TO pt_item_table.
*
*      "PO별 지급량
*      CLEAR ls_item.
*      ls_item-node_key  = lv_seq.
*      ls_item-item_name = 'ACISS'.
*      ls_item-class     = cl_gui_column_tree=>item_class_text.
*
*      WRITE ls_all-aciss TO ls_item-text.
*      CONDENSE ls_item-text.
*
*      APPEND ls_item TO pt_item_table.
*
*      "PO별 사용량
*      CLEAR ls_item.
*      ls_item-node_key  = lv_seq.
*      ls_item-item_name = 'ACUSE'.
*      ls_item-class     = cl_gui_column_tree=>item_class_text.
*
*      WRITE ls_all-acuse TO ls_item-text.
*      CONDENSE ls_item-text.
*
*      APPEND ls_item TO pt_item_table.
*
*    ENDLOOP.
*
*  ENDLOOP.
*
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form zz_get_data
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_get_data.
*  DATA : lt_alsmex TYPE gty_alsmex_tab.
*
*  CLEAR : gt_excel, gs_excel, gt_bottom, gt_top,
*          gt_bom_head, gt_bom_item, gt_bom_req,
*          zsmma00041, gv_check.
*
*  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
*    EXPORTING
*      filename                = pa_file
*      i_begin_col             = 1
*      i_begin_row             = 2
*      i_end_col               = 11
*      i_end_row               = 1000
*    TABLES
*      intern                  = lt_alsmex
*    EXCEPTIONS
*      inconsistent_parameters = 1
*      upload_ole              = 2
*      OTHERS                  = 3.
*  IF sy-subrc <> 0.
*    MESSAGE e059.
*  ENDIF.
*
*  SORT lt_alsmex BY row col.
*
*  PERFORM zz_set_excel_data USING lt_alsmex.
*  PERFORM zz_get_extra_data.
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form zz_set_excel_data
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**&      --> LT_ALSMEX
**&---------------------------------------------------------------------*
*FORM zz_set_excel_data USING pt_alsmex TYPE gty_alsmex_tab.
*  DATA : lt_dfies         TYPE TABLE OF dfies,
*         lv_value         TYPE alsmex_tabline-value,
*         lv_function_name TYPE rs38l_fnam.
*
*  FIELD-SYMBOLS : <fs_field> TYPE any.
*
*  CLEAR : gt_excel, gs_excel, gt_bottom.
*
*  CALL FUNCTION 'DDIF_FIELDINFO_GET'
*    EXPORTING
*      tabname   = 'ZSMMA00042'
*    TABLES
*      dfies_tab = lt_dfies
*    EXCEPTIONS
*      OTHERS    = 1.
*  IF sy-subrc <> 0.
*    MESSAGE e059.
*  ENDIF.
*
*  LOOP AT pt_alsmex ASSIGNING FIELD-SYMBOL(<ls_alsmex>).
*    lv_value = <ls_alsmex>-value.
*
*    UNASSIGN <fs_field>.
*    ASSIGN COMPONENT <ls_alsmex>-col OF STRUCTURE gs_excel
*      TO <fs_field>.
*    IF sy-subrc <> 0.
*      MESSAGE e059.
*    ENDIF.
*
*    READ TABLE lt_dfies ASSIGNING FIELD-SYMBOL(<ls_dfies>)
*      INDEX <ls_alsmex>-col.
*    IF sy-subrc <> 0.
*      MESSAGE e059.
*    ENDIF.
*
*    TRY.
*        IF lv_value IS INITIAL.
*          CLEAR <fs_field>.
*        ELSE.
*          CASE <ls_dfies>-inttype.
*            WHEN 'P'.
*              REPLACE ALL OCCURRENCES OF ',' IN lv_value WITH space.
*              CONDENSE lv_value NO-GAPS.
*            WHEN 'D'.
*              REPLACE ALL OCCURRENCES OF '-' IN lv_value WITH space.
*              REPLACE ALL OCCURRENCES OF '.' IN lv_value WITH space.
*              REPLACE ALL OCCURRENCES OF '/' IN lv_value WITH space.
*              CONDENSE lv_value NO-GAPS.
*          ENDCASE.
*
*          IF <ls_dfies>-convexit IS NOT INITIAL.
*            lv_function_name = 'CONVERSION_EXIT_' &&
*                               <ls_dfies>-convexit && '_INPUT'.
*            CALL FUNCTION lv_function_name
*              EXPORTING
*                input  = lv_value
*              IMPORTING
*                output = <fs_field>
*              EXCEPTIONS
*                OTHERS = 1.
*            IF sy-subrc <> 0.
*              CLEAR : gt_excel, gs_excel, gt_bottom.
*              MESSAGE e059.
*            ENDIF.
*          ELSE.
*            <fs_field> = lv_value.
*          ENDIF.
*        ENDIF.
*      CATCH cx_sy_conversion_error.
*        CLEAR : gt_excel, gs_excel, gt_bottom.
*        MESSAGE e059.
*    ENDTRY.
*
*    AT END OF row.
*      IF gs_excel IS NOT INITIAL.
*        APPEND gs_excel TO gt_excel.
*      ENDIF.
*      CLEAR gs_excel.
*    ENDAT.
*  ENDLOOP.
*
*  MOVE-CORRESPONDING gt_excel TO gt_bottom.
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form zz_get_extra_data
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_get_extra_data.
*  DATA : lt_item_key TYPE HASHED TABLE OF ty_po_key
*                          WITH UNIQUE KEY ebeln ebelp,
*         lt_po_head  TYPE TABLE OF ztmma00050,
*         lv_lifnr    TYPE ztmma00050-lifnr,
*         lv_same     TYPE abap_bool.
*
*  CLEAR : gt_top, zsmma00041.
*
*  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
*    INSERT VALUE #(
*      ebeln = <ls_bottom>-ebeln
*      ebelp = <ls_bottom>-ebelp
*    ) INTO TABLE lt_item_key.
*  ENDLOOP.
*
*  IF lt_item_key IS NOT INITIAL.
*    SELECT *
*      FROM ztmma00060
*      FOR ALL ENTRIES IN @lt_item_key
*      WHERE ebeln = @lt_item_key-ebeln
*        AND ebelp = @lt_item_key-ebelp
*      INTO CORRESPONDING FIELDS OF TABLE @gt_top.
*
*    SELECT *
*      FROM ztmma00050
*      FOR ALL ENTRIES IN @lt_item_key
*      WHERE ebeln = @lt_item_key-ebeln
*      INTO TABLE @lt_po_head.
*  ENDIF.
*
*  "단일 공급업체 표시 영역이므로 공급업체가 동일한 경우만 표시
*  lv_same = abap_true.
*  LOOP AT lt_po_head ASSIGNING FIELD-SYMBOL(<ls_po_head>).
*    IF sy-tabix = 1.
*      lv_lifnr = <ls_po_head>-lifnr.
*    ELSEIF lv_lifnr <> <ls_po_head>-lifnr.
*      lv_same = abap_false.
*      EXIT.
*    ENDIF.
*  ENDLOOP.
*
*  IF lv_same = abap_true AND lv_lifnr IS NOT INITIAL.
*    SELECT SINGLE a~dscor, a~qscor, a~pscor, a~tscor, a~grade,
*                  a~lifnr, b~name1
*      FROM ztmma00100 AS a
*      INNER JOIN ztcma00010 AS b
*        ON a~lifnr = b~lifnr
*      WHERE a~lifnr = @lv_lifnr
*        AND a~datab <= @sy-datum
*        AND a~datbi >= @sy-datum
*      INTO CORRESPONDING FIELDS OF @zsmma00041.
*  ENDIF.
*
*  PERFORM zz_get_bom.
*  PERFORM zz_get_bom_bfs.
*  PERFORM zz_set_light.
*  PERFORM zz_set_column_tree.
*ENDFORM.
*
**&---------------------------------------------------------------------*
**& Form zz_get_bom
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_get_bom.
*  CLEAR : gt_bom_head, gt_bom_item, gt_bom_req.
*
*  IF gt_top IS INITIAL.
*    RETURN.
*  ENDIF.
*
*  SELECT *
*    FROM ztcma00120
*    FOR ALL ENTRIES IN @gt_top
*    WHERE matnr    = @gt_top-matnr
*      AND werks    = @gt_top-werks
*      AND stlst    = '01'
*      AND datuv    <= @sy-datum
*      AND valid_to >= @sy-datum
*    INTO TABLE @gt_bom_head.
*
*  IF gt_bom_head IS NOT INITIAL.
*    SELECT *
*      FROM ztcma00130
*      FOR ALL ENTRIES IN @gt_bom_head
*      WHERE stlnr = @gt_bom_head-stlnr
*      INTO TABLE @gt_bom_item.
*  ENDIF.
*
*  SORT gt_bom_head BY matnr werks stlnr.
*  SORT gt_bom_item BY stlnr stlkn.
*ENDFORM.
*
**&---------------------------------------------------------------------*
**& Form zz_get_bom_bfs
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_get_bom_bfs.
*  DATA : lv_count     TYPE i,
*         lv_stlnr     TYPE ztcma00120-stlnr,
*         lv_bmeng     TYPE ztcma00120-bmeng,
*         lv_po_qty    TYPE decfloat34,
*         lv_item_qty  TYPE decfloat34,
*         lv_base_qty  TYPE decfloat34,
*         lv_child_qty TYPE decfloat34.
*
*  CLEAR gt_bom_req.
*
*  "기존 FORM 이름 유지, 구매오더 자재의 직접 하위만 확인
*  LOOP AT gt_top ASSIGNING FIELD-SYMBOL(<ls_top>).
*    CLEAR : lv_count, lv_stlnr, lv_bmeng.
*
*    LOOP AT gt_bom_head ASSIGNING FIELD-SYMBOL(<ls_head>)
*      WHERE matnr = <ls_top>-matnr
*        AND werks = <ls_top>-werks.
*      lv_count += 1.
*      lv_stlnr = <ls_head>-stlnr.
*      lv_bmeng = <ls_head>-bmeng.
*    ENDLOOP.
*
*    IF lv_count <> 1 OR lv_bmeng <= 0 OR <ls_top>-menge <= 0.
*      CONTINUE.
*    ENDIF.
*
*    LOOP AT gt_bom_item ASSIGNING FIELD-SYMBOL(<ls_item>)
*      WHERE stlnr = lv_stlnr.
*      IF <ls_item>-menge <= 0 OR <ls_item>-idnrk IS INITIAL
*         OR <ls_item>-meins IS INITIAL.
*        CONTINUE.
*      ENDIF.
*
*      lv_po_qty = <ls_top>-menge.
*      lv_item_qty = <ls_item>-menge.
*      lv_base_qty = lv_bmeng.
*      lv_child_qty = lv_po_qty * lv_item_qty / lv_base_qty.
*
*      READ TABLE gt_bom_req ASSIGNING FIELD-SYMBOL(<ls_bom_req>)
*        WITH KEY ebeln = <ls_top>-ebeln
*                 ebelp = <ls_top>-ebelp
*                 matnr = <ls_item>-idnrk
*                 werks = <ls_top>-werks
*                 meins = <ls_item>-meins.
*      IF sy-subrc = 0.
*        <ls_bom_req>-menge += lv_child_qty.
*      ELSE.
*        INSERT VALUE #(
*          ebeln = <ls_top>-ebeln
*          ebelp = <ls_top>-ebelp
*          matnr = <ls_item>-idnrk
*          werks = <ls_top>-werks
*          menge = lv_child_qty
*          meins = <ls_item>-meins
*        ) INTO TABLE gt_bom_req.
*      ENDIF.
*    ENDLOOP.
*  ENDLOOP.
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form zz_set_column_tree
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_set_column_tree.
*
*  DATA: lt_node_table TYPE treev_ntab,
*        lt_item_table TYPE item_table_type.
*
*  IF go_tree IS NOT BOUND.
*    RETURN.
*  ENDIF.
*
*  "재조회 또는 엑셀 재업로드 시 기존 트리 제거
*  CALL METHOD go_tree->delete_all_nodes.
*
*  PERFORM build_node_and_item_table
*    USING lt_node_table lt_item_table.
*
*  IF lt_node_table IS INITIAL.
*    CALL METHOD cl_gui_cfw=>flush.
*    RETURN.
*  ENDIF.
*
*  CALL METHOD go_tree->add_nodes_and_items
*    EXPORTING
*      node_table                = lt_node_table
*      item_table                = lt_item_table
*      item_table_structure_name = 'MTREEITM'
*    EXCEPTIONS
*      failed                    = 1
*      cntl_system_error         = 2
*      OTHERS                    = 3.
*
*  IF sy-subrc <> 0.
*    MESSAGE a099.
*  ENDIF.
*
*  "자재 부모 노드 펼치기
*  CALL METHOD go_tree->expand_root_nodes
*    EXPORTING
*      level_count = 1.
*
*  CALL METHOD cl_gui_cfw=>flush.
*
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form zz_set_light
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_set_light.
*  TYPES : BEGIN OF ty_issue,
*            ebeln TYPE ztmma00090-ebeln,
*            ebelp TYPE ztmma00090-ebelp,
*            matnr TYPE ztmma00090-matnr,
*            werks TYPE ztmma00090-werks,
*            lgort TYPE ztmma00090-lgort,
*            meins TYPE ztmma00090-meins,
*            menge TYPE ztmma00090-menge,
*          END OF ty_issue.
*
*  TYPES : BEGIN OF ty_excel_key,
*            ebeln TYPE ztmma00090-ebeln,
*            ebelp TYPE ztmma00090-ebelp,
*            matnr TYPE ztmma00090-matnr,
*            werks TYPE ztmma00090-werks,
*            lgort TYPE ztmma00090-lgort,
*            meins TYPE ztmma00090-meins,
*            count TYPE i,
*          END OF ty_excel_key.
*
*  DATA : lt_item_key TYPE HASHED TABLE OF ty_po_key
*                          WITH UNIQUE KEY ebeln ebelp,
*         lt_doc      TYPE TABLE OF ztmma00090,
*         lt_issue    TYPE HASHED TABLE OF ty_issue
*                          WITH UNIQUE KEY ebeln ebelp matnr werks lgort meins,
*         lt_excel_key TYPE HASHED TABLE OF ty_excel_key
*                          WITH UNIQUE KEY ebeln ebelp matnr werks lgort meins,
*         ls_issue     TYPE ty_issue,
*         ls_excel_key TYPE ty_excel_key,
*         lv_error     TYPE abap_bool.
*
*  "엑셀 지급량/사용량은 원본 유지, 실제 지급량은 655에서 별도 집계
*  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
*    <ls_bottom>-light = '1'.
*
*    INSERT VALUE #(
*      ebeln = <ls_bottom>-ebeln
*      ebelp = <ls_bottom>-ebelp
*    ) INTO TABLE lt_item_key.
*
*    CLEAR ls_excel_key.
*    MOVE-CORRESPONDING <ls_bottom> TO ls_excel_key.
*    ls_excel_key-count = 1.
*    COLLECT ls_excel_key INTO lt_excel_key.
*  ENDLOOP.
*
*  IF lt_item_key IS INITIAL.
*    RETURN.
*  ENDIF.
*
*  "문서 키를 포함한 전체 행 조회로 서로 다른 출고문서의 중복 제거 방지
*  SELECT *
*    FROM ztmma00090
*    FOR ALL ENTRIES IN @lt_item_key
*    WHERE ebeln = @lt_item_key-ebeln
*      AND ebelp = @lt_item_key-ebelp
*      AND bwart = '655'
*    INTO TABLE @lt_doc.
*
*  LOOP AT lt_doc ASSIGNING FIELD-SYMBOL(<ls_doc>).
*    CLEAR ls_issue.
*    MOVE-CORRESPONDING <ls_doc> TO ls_issue.
*    COLLECT ls_issue INTO lt_issue.
*  ENDLOOP.
*
*  LOOP AT gt_bottom ASSIGNING <ls_bottom>.
*    IF <ls_bottom>-ebeln IS INITIAL OR <ls_bottom>-ebelp IS INITIAL
*       OR <ls_bottom>-matnr IS INITIAL OR <ls_bottom>-werks IS INITIAL
*       OR <ls_bottom>-lgort IS INITIAL OR <ls_bottom>-meins IS INITIAL.
*      CONTINUE.
*    ENDIF.
*
*    IF <ls_bottom>-pliss < 0 OR <ls_bottom>-aciss < 0
*       OR <ls_bottom>-pluse < 0 OR <ls_bottom>-acuse < 0.
*      CONTINUE.
*    ENDIF.
*
*    READ TABLE lt_excel_key ASSIGNING FIELD-SYMBOL(<ls_excel_key>)
*      WITH TABLE KEY ebeln = <ls_bottom>-ebeln
*                     ebelp = <ls_bottom>-ebelp
*                     matnr = <ls_bottom>-matnr
*                     werks = <ls_bottom>-werks
*                     lgort = <ls_bottom>-lgort
*                     meins = <ls_bottom>-meins.
*    IF sy-subrc <> 0.
*      CONTINUE.
*    ENDIF.
*    IF <ls_excel_key>-count <> 1.
*      CONTINUE.
*    ENDIF.
*
*    "BOM의 바로 아래 구성자재와 단위가 맞는지 확인
*    READ TABLE gt_bom_req TRANSPORTING NO FIELDS
*      WITH KEY ebeln = <ls_bottom>-ebeln
*               ebelp = <ls_bottom>-ebelp
*               matnr = <ls_bottom>-matnr
*               meins = <ls_bottom>-meins.
*    IF sy-subrc <> 0.
*      CONTINUE.
*    ENDIF.
*
*    READ TABLE lt_issue ASSIGNING FIELD-SYMBOL(<ls_issue>)
*      WITH TABLE KEY ebeln = <ls_bottom>-ebeln
*                     ebelp = <ls_bottom>-ebelp
*                     matnr = <ls_bottom>-matnr
*                     werks = <ls_bottom>-werks
*                     lgort = <ls_bottom>-lgort
*                     meins = <ls_bottom>-meins.
*    IF sy-subrc <> 0.
*      CONTINUE.
*    ENDIF.
*
*    "문서가 없거나 실제 지급량이 0인 경우 정상으로 판정하지 않음
*    IF <ls_issue>-menge <= 0.
*      CONTINUE.
*    ENDIF.
*
*    "분할 지급 허용, PO 기준 BOM 소요량과 실제 지급량은 별도 기준
*    IF <ls_issue>-menge = <ls_bottom>-aciss
*       AND <ls_issue>-menge = <ls_bottom>-acuse.
*      <ls_bottom>-light = '3'.
*    ENDIF.
*  ENDLOOP.
*
*  "실제 출고된 자재가 엑셀에서 빠지거나 직접 BOM 밖이면 PO 품목 전체 실패
*  LOOP AT lt_issue ASSIGNING <ls_issue>.
*    CLEAR lv_error.
*
*    READ TABLE lt_excel_key TRANSPORTING NO FIELDS
*      WITH TABLE KEY ebeln = <ls_issue>-ebeln
*                     ebelp = <ls_issue>-ebelp
*                     matnr = <ls_issue>-matnr
*                     werks = <ls_issue>-werks
*                     lgort = <ls_issue>-lgort
*                     meins = <ls_issue>-meins.
*    IF sy-subrc <> 0.
*      lv_error = abap_true.
*    ENDIF.
*
*    READ TABLE gt_bom_req TRANSPORTING NO FIELDS
*      WITH KEY ebeln = <ls_issue>-ebeln
*               ebelp = <ls_issue>-ebelp
*               matnr = <ls_issue>-matnr
*               meins = <ls_issue>-meins.
*    IF sy-subrc <> 0.
*      lv_error = abap_true.
*    ENDIF.
*
*    IF lv_error = abap_true.
*      LOOP AT gt_bottom ASSIGNING <ls_bottom>
*        WHERE ebeln = <ls_issue>-ebeln
*          AND ebelp = <ls_issue>-ebelp.
*        <ls_bottom>-light = '1'.
*      ENDLOOP.
*    ENDIF.
*  ENDLOOP.
*
*  "655는 양수 지급 문서만 유효하므로 비정상 원문서도 따로 검사
*  LOOP AT lt_doc ASSIGNING <ls_doc> WHERE menge <= 0.
*    LOOP AT gt_bottom ASSIGNING <ls_bottom>
*      WHERE ebeln = <ls_doc>-ebeln
*        AND ebelp = <ls_doc>-ebelp.
*      <ls_bottom>-light = '1'.
*    ENDLOOP.
*  ENDLOOP.
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form zz_make_docu
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_make_docu .
*
*  DATA: lt_110        TYPE TABLE OF ztmma00110,
*        lv_cevno      TYPE zde_ceval,
*        lt_return     TYPE TABLE OF bapiret2,
*        lt_revalid    TYPE ty_t_revalid,
*        lt_done_rqnum TYPE SORTED TABLE OF ztexa00060-rqnum
*                        WITH UNIQUE KEY table_line,
*        lt_created    TYPE SORTED TABLE OF ty_revalid
*                        WITH UNIQUE KEY ebeln ebelp.
*
*  PERFORM zz_get_revalid CHANGING lt_revalid.
*
*  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
*
*    CLEAR: lv_cevno, lt_return.
*
*    CALL FUNCTION 'NUMBER_GET_NEXT'
*      EXPORTING
*        nr_range_nr = '01'
*        object      = 'ZMM_CEVNO'
*      IMPORTING
*        number      = lv_cevno.
*
*    APPEND INITIAL LINE TO lt_110 ASSIGNING FIELD-SYMBOL(<ls_110>).
*    MOVE-CORRESPONDING <ls_bottom> TO <ls_110>.
*
*    <ls_110>-cevno = lv_cevno.
*    <ls_110>-cfdat = sy-datum.
*    <ls_110>-cfusr = sy-uname.
*    <ls_110>-ernam = sy-uname.
*    <ls_110>-erdat = sy-datum.
*    <ls_110>-erzet = sy-uzeit.
*
*    LOOP AT lt_revalid ASSIGNING FIELD-SYMBOL(<ls_revalid>)
*      WHERE ebeln = <ls_bottom>-ebeln
*        AND ebelp = <ls_bottom>-ebelp.
*
*      INSERT <ls_revalid>-rqnum INTO TABLE lt_done_rqnum.
*
*    ENDLOOP.
*
*    IF <ls_bottom>-light = '1'.
*
*      <ls_110>-rcsts = '0010'.
*
*      IF NOT line_exists( lt_revalid[
*        ebeln = <ls_bottom>-ebeln
*        ebelp = <ls_bottom>-ebelp ] ).
*
*        READ TABLE lt_created TRANSPORTING NO FIELDS
*          WITH KEY ebeln = <ls_bottom>-ebeln
*                   ebelp = <ls_bottom>-ebelp.
*
*        IF sy-subrc <> 0.
*
*          CALL FUNCTION 'ZCM_EXC_CREATE'
*            EXPORTING
*              iv_srtyp  = 'SUBC'
*              iv_srnum  = lv_cevno
*              iv_sritm  = 00000
*              iv_owgrp  = 'MM'
*              iv_extyp  = 'PROC'
*            IMPORTING
*              et_return = lt_return.
*
*          IF line_exists( lt_return[ type = 'E' ] )
*          OR line_exists( lt_return[ type = 'A' ] )
*          OR line_exists( lt_return[ type = 'X' ] ).
*
*            ROLLBACK WORK.
*            MESSAGE s115 DISPLAY LIKE 'E'.
*            RETURN.
*
*          ENDIF.
*
*          INSERT VALUE #(
*            ebeln = <ls_bottom>-ebeln
*            ebelp = <ls_bottom>-ebelp
*          ) INTO TABLE lt_created.
*
*        ENDIF.
*
*      ENDIF.
*
*    ELSE.
*      <ls_110>-rcsts = '0020'.
*    ENDIF.
*
*  ENDLOOP.
*
*  MODIFY ztmma00110 FROM TABLE lt_110.
*
*  IF sy-subrc <> 0.
*    ROLLBACK WORK.
*    MESSAGE s116 DISPLAY LIKE 'E'.
*    RETURN.
*  ENDIF.
*
*  LOOP AT lt_done_rqnum ASSIGNING FIELD-SYMBOL(<lv_rqnum>).
*
*    CLEAR lt_return.
*
*    CALL FUNCTION 'ZCM_EXC_REQ_DONE'
*      EXPORTING
*        iv_rqnum  = <lv_rqnum>
*        iv_rstxt  = TEXT-t07
*      IMPORTING
*        et_return = lt_return.
*
*    IF line_exists( lt_return[ type = 'E' ] )
*    OR line_exists( lt_return[ type = 'A' ] )
*    OR line_exists( lt_return[ type = 'X' ] ).
*
*      ROLLBACK WORK.
*      MESSAGE S118 DISPLAY LIKE 'E'.
*      RETURN.
*
*    ENDIF.
*
*  ENDLOOP.
*
*  COMMIT WORK.
*
*  MESSAGE s070.
*  gv_check = abap_true.
*
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form zz_get_revalid
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM zz_get_revalid CHANGING pt_revalid TYPE ty_t_revalid.
*
*  DATA: lt_return    TYPE TABLE OF bapiret2,
*        lt_exreq_key TYPE ztt_exreq,
*        lt_exreq     TYPE ztt_exreq.
*
*  CLEAR pt_revalid.
*
*  CALL FUNCTION 'ZCM_EXC_REQ_GET'
*    EXPORTING
*      iv_tgpgm  = 'MM04'
*    IMPORTING
*      et_req    = lt_exreq
*      et_return = lt_return.
*
*  READ TABLE lt_return WITH KEY type = 'E'
*    TRANSPORTING NO FIELDS.
*
*  IF sy-subrc = 0.
*    MESSAGE s117  DISPLAY LIKE 'E'.
*    RETURN.
*  ENDIF.
*
*  LOOP AT lt_exreq ASSIGNING FIELD-SYMBOL(<ls_exreq>)
*       WHERE srtyp = 'SUBC'
*       AND acttp = 'RCHK'. ""10-16 추가
*
*    APPEND VALUE #(
*      srnum = <ls_exreq>-srnum
*      rqnum = <ls_exreq>-rqnum
*    ) TO lt_exreq_key.
*
*  ENDLOOP.
*
*  IF lt_exreq_key IS INITIAL.
*    RETURN.
*  ENDIF.
*
*  SORT lt_exreq_key BY srnum rqnum.
*  DELETE ADJACENT DUPLICATES FROM lt_exreq_key COMPARING srnum rqnum.
*
*  SELECT cevno, ebeln, ebelp
*    FROM ztmma00110
*    FOR ALL ENTRIES IN @lt_exreq_key
*    WHERE cevno = @lt_exreq_key-srnum
*    INTO TABLE @DATA(lt_old_docu).
*
*  LOOP AT lt_old_docu ASSIGNING FIELD-SYMBOL(<ls_old_docu>).
*
*    LOOP AT lt_exreq_key ASSIGNING FIELD-SYMBOL(<ls_exreq_key>)
*         WHERE srnum = <ls_old_docu>-cevno.
*
*      INSERT VALUE #(
*        ebeln = <ls_old_docu>-ebeln
*        ebelp = <ls_old_docu>-ebelp
*        srnum = <ls_exreq_key>-srnum
*        rqnum = <ls_exreq_key>-rqnum
*      ) INTO TABLE pt_revalid.
*
*    ENDLOOP.
*
*  ENDLOOP.
*
*ENDFORM.
**&---------------------------------------------------------------------*
**& Form show_kpi_0100
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
*FORM show_kpi_0100 .
*  DATA(lv_fail) = 0.
*  DATA(lv_success) = 0.
*  CONSTANTS lc_chart TYPE zcl_cm_kpi_html=>ty_ctype VALUE 'D'.
*
*  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
*    IF <ls_bottom>-light = 1.
*      lv_fail += 1.
*    ELSEIF <ls_bottom>-light = 3.
*      lv_success += 1.
*    ENDIF.
*  ENDLOOP.
*
*  DATA(lv_total) = lines( gt_bottom ).
*
*  DATA(lv_pct) = COND i( WHEN lv_total > 0 THEN lv_success * 100 / lv_total ELSE 0 ).
*
*  DATA(lt_card) = VALUE zcl_cm_kpi_html=>tt_card(
*    ( label = |{ TEXT-t20 }|
*      value = replace(
*                val  = CONV string( TEXT-t22 )
*                sub  = '&1'
*                with = |{ lv_success }| )
*      sub   = |{ TEXT-t23 }|
*      color = 'B' )
*
*    ( label = |{ TEXT-t21 }|
*      value = replace(
*                val  = CONV string( TEXT-t22 )
*                sub  = '&1'
*                with = |{ lv_fail }| )
*      sub   = |{ TEXT-t24 }|
*      color = 'R' ) ).
*
*  DATA(lt_item) = VALUE zcl_cm_kpi_html=>tt_item(
*    ( label = |{ TEXT-t23 }| value = lv_success color = 'G' )
*    ( label = |{ TEXT-t24 }| value = lv_fail    color = 'R' ) ).
*
*  go_kpi->show_summary(
*    iv_title        = |{ TEXT-t25 }|
*    iv_chart_type   = lc_chart
*    iv_chart_title  = |{ TEXT-t26 }|
*    it_chart_item   = lt_item
*    iv_chart_center = replace(
*                        val  = CONV string( TEXT-t27 )
*                        sub  = '&1'
*                        with = |{ lv_pct }| )
*    it_card         = lt_card ).
*
**  DATA(lt_card) = VALUE zcl_cm_kpi_html=>tt_card(
**  ( label = '성공'       value = |{ lv_success }곳|  sub = '외주정합성 성공' color = 'B' )
**  ( label = '실패'       value = |{ lv_fail }곳|     sub = '외주정합성 실패'      color = 'R' )
**  ).
**
**  DATA(lt_item) = VALUE zcl_cm_kpi_html=>tt_item(
**    ( label = '외주정합성 성공' value = lv_success   color = 'G' )
**    ( label = '외주정합성 실패' value = lv_fail color = 'R' ) ).
**
**  go_kpi->show_summary(
**    iv_title        = '외주정합성 검사 통과 비율을 확인합니다'
**    iv_chart_type   = lc_chart
**    iv_chart_title  = '합격 비율'
**    it_chart_item   = lt_item
**    iv_chart_center = |{ lv_pct }%|
**    it_card         = lt_card ).
*
*ENDFORM.
**
***&---------------------------------------------------------------------*
***& Include          ZLMMA00010_F01
***&---------------------------------------------------------------------*
***&---------------------------------------------------------------------*
***& Form create_object
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM create_object .
**  IF go_con IS NOT BOUND.
**    CREATE OBJECT go_con
**      EXPORTING
**        container_name              = 'CUSTOM_CON'
**      EXCEPTIONS
**        cntl_error                  = 1
**        cntl_system_error           = 2
**        create_error                = 3
**        lifetime_error              = 4
**        lifetime_dynpro_dynpro_link = 5
**        OTHERS                      = 6.
**    IF sy-subrc <> 0.
**      MESSAGE a099.
**    ENDIF.
**
**    CREATE OBJECT go_splitter
**      EXPORTING
**        parent            = go_con
**        rows              = 2
**        columns           = 1
**      EXCEPTIONS
**        cntl_error        = 1
**        cntl_system_error = 2
**        OTHERS            = 3.
**    IF sy-subrc <> 0.
**      MESSAGE a099.
**    ENDIF.
**    go_top_container = go_splitter->get_container(
**      row    = 1
**      column = 1 ).
**
**    go_bottom_container = go_splitter->get_container(
**      row    = 2
**      column = 1 ).
**
**    CREATE OBJECT go_top_alv
**      EXPORTING
**        i_parent          = go_top_container
**      EXCEPTIONS
**        error_cntl_create = 1
**        error_cntl_init   = 2
**        error_cntl_link   = 3
**        error_dp_create   = 4
**        OTHERS            = 5.
**    IF sy-subrc <> 0.
**      MESSAGE a099.
**    ENDIF.
**    CREATE OBJECT go_bottom_alv
**      EXPORTING
**        i_parent          = go_bottom_container
**      EXCEPTIONS
**        error_cntl_create = 1
**        error_cntl_init   = 2
**        error_cntl_link   = 3
**        error_dp_create   = 4
**        OTHERS            = 5.
**    IF sy-subrc <> 0.
**      MESSAGE a099.
**    ENDIF.
**
**
**  ELSE.
**  ENDIF.
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form set_event_handler
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM set_event_handler .
**
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form set_alv_variant
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM set_alv_variant .
**
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form set_alv_layout
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM set_alv_layout .
**  gs_layo_top-zebra = 'X'.
**  gs_layo_top-sel_mode = 'A'.
**  gs_layo_top-cwidth_opt = 'X'.
**
**  gs_layo_bot-zebra = 'X'.
**  gs_layo_bot-sel_mode = 'A'.
**  gs_layo_bot-cwidth_opt = 'X'.
**  gs_layo_bot-excp_fname = 'LIGHT'.
**  gs_layo_bot-excp_led = 'X'.
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form set_field_catalog
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM set_field_catalog .
**  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
**    EXPORTING
**      i_structure_name       = 'ZSMMA00040'
**    CHANGING
**      ct_fieldcat            = gt_top_fcat
**    EXCEPTIONS
**      inconsistent_interface = 1
**      program_error          = 2
**      OTHERS                 = 3.
**
**
**  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
**    EXPORTING
**      i_structure_name       = 'ZSMMA00047'
**    CHANGING
**      ct_fieldcat            = gt_bottom_fcat
**    EXCEPTIONS
**      inconsistent_interface = 1
**      program_error          = 2
**      OTHERS                 = 3.
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form display_alv
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM display_alv .
**  go_top_alv->set_table_for_first_display(
**    EXPORTING
**      is_layout       = gs_layo_top
**      i_save          = 'A'
**    CHANGING
**      it_outtab       = gt_top
**      it_fieldcatalog = gt_top_fcat ).
**
**  go_bottom_alv->set_table_for_first_display(
**    EXPORTING
**      is_layout       = gs_layo_bot
**      i_save          = 'A'
**    CHANGING
**      it_outtab       = gt_bottom
**      it_fieldcatalog = gt_bottom_fcat ).
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form CREATE_TREE_CONTAINER
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM create_tree_container .
**
**
**
**  CREATE OBJECT go_con_tree
**    EXPORTING
**      container_name              = 'CUSTOM_TREE'
**    EXCEPTIONS
**      cntl_error                  = 1
**      cntl_system_error           = 2
**      create_error                = 3
**      lifetime_error              = 4
**      lifetime_dynpro_dynpro_link = 5
**      OTHERS                      = 6.
**  IF sy-subrc <> 0.
**    MESSAGE a099.
**  ENDIF.
**
**  PERFORM zz_create_tree.
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form CREATE_NODE_EVENT
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM create_node_event .
**
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form BUILD_NODE_TABLE
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM build_node_table .
**
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form zz_f4_excel
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_f4_excel.
**
**  DATA:
**    lt_file        TYPE filetable,
**    ls_file        TYPE file_table,
**    lv_rc          TYPE i,
**    lv_user_action TYPE i.
**
**  cl_gui_frontend_services=>file_open_dialog(
**    EXPORTING
**      window_title      = CONV string( TEXT-t03 )
**      default_extension = 'xlsx'
**      file_filter       = 'Excel Workbook (*.xlsx)|*.xlsx|'
**      multiselection    = abap_false
**    CHANGING
**      file_table        = lt_file
**      rc                = lv_rc
**      user_action       = lv_user_action
**    EXCEPTIONS
**      OTHERS            = 1 ).
**
**  IF sy-subrc <> 0.
**    RETURN.
**  ENDIF.
**
**  "취소 버튼을 누른 경우
**  IF lv_user_action
**       <> cl_gui_frontend_services=>action_ok.
**    RETURN.
**  ENDIF.
**
**  READ TABLE lt_file INTO ls_file INDEX 1.
**
**  IF sy-subrc = 0.
**    pa_file = ls_file-filename.
**  ENDIF.
**
**ENDFORM.
**
***&---------------------------------------------------------------------*
***& Form zz_create_tree
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_create_tree .
**  DATA: ls_hierarchy_header TYPE treev_hhdr.
**  DATA: lt_node_table TYPE treev_ntab.
**  DATA: lt_item_table TYPE item_table_type.
**
**  ls_hierarchy_header-heading = TEXT-t04.
**  ls_hierarchy_header-width = 30.
**
**  CREATE OBJECT go_tree
**    EXPORTING
**      parent                      = go_con_tree
**      node_selection_mode         = cl_gui_column_tree=>node_sel_mode_single
**      item_selection              = 'X'                 " Can Individual Items be Selected?
**      hierarchy_column_name       = 'HEADTEXT'                 " Name of the Column in Hierarchy Area
**      hierarchy_header            = ls_hierarchy_header                " Hierarchy Header
**    EXCEPTIONS
**      lifetime_error              = 1
**      cntl_system_error           = 2
**      create_error                = 3
**      failed                      = 4
**      illegal_node_selection_mode = 5
**      OTHERS                      = 6.
**  IF sy-subrc <> 0.
**    MESSAGE a099.
**  ENDIF.
**
**  CALL METHOD go_tree->add_column
**    EXPORTING
**      name        = 'ACISS'
**      width       = 20
**      header_text = TEXT-t05.
**
**  CALL METHOD go_tree->add_column
**    EXPORTING
**      name        = 'ACUSE'
**      width       = 20
**      header_text = TEXT-t06.
**
**
**
***  PERFORM build_node_and_item_table USING lt_node_table lt_item_table.
**  PERFORM zz_set_column_tree.
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form build_node_and_item_table
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***&      --> NODE_TABLE
***&      --> ITEM_TABLE
***&---------------------------------------------------------------------*
**FORM build_node_and_item_table
**  USING    pt_node_table TYPE treev_ntab
**           pt_item_table TYPE item_table_type.
**
**  DATA: ls_node       TYPE treev_node,
**        ls_item       TYPE mtreeitm,
**        ls_all        TYPE zsmma00047,
**        lt_bottom     TYPE TABLE OF zsmma00047,
**        lv_parent_key TYPE tv_nodekey,
**        lv_give_qty   TYPE zsmma00042-aciss,
**        lv_use_qty    TYPE zsmma00042-acuse,
**        lv_seq        TYPE n LENGTH 4.
**
**  MOVE-CORRESPONDING gt_bottom TO lt_bottom.
**
**  SORT lt_bottom BY matnr.
**  DELETE ADJACENT DUPLICATES FROM lt_bottom COMPARING matnr.
**
**  LOOP AT lt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
**
**    ADD 1 TO lv_seq.
**    lv_parent_key = lv_seq.
**
**    "자재 부모 노드
**    CLEAR ls_node.
**    ls_node-node_key = lv_parent_key.
**    ls_node-isfolder = 'X'.
**    ls_node-expander = 'X'.
**
**    APPEND ls_node TO pt_node_table.
**
**    "자재별 지급량 / 사용량 합계
**    CLEAR: lv_give_qty, lv_use_qty.
**
**    LOOP AT gt_bottom INTO ls_all
**         WHERE matnr = <ls_bottom>-matnr.
**
**      ADD ls_all-aciss TO lv_give_qty.
**      ADD ls_all-acuse TO lv_use_qty.
**
**    ENDLOOP.
**
**    "자재번호
**    CLEAR ls_item.
**    ls_item-node_key  = lv_parent_key.
**    ls_item-item_name = 'HEADTEXT'.
**    ls_item-class     = cl_gui_column_tree=>item_class_text.
**    ls_item-text      = <ls_bottom>-matnr.
**
**    APPEND ls_item TO pt_item_table.
**
**    "자재별 지급량
**    CLEAR ls_item.
**    ls_item-node_key  = lv_parent_key.
**    ls_item-item_name = 'ACISS'.
**    ls_item-class     = cl_gui_column_tree=>item_class_text.
**
**    WRITE lv_give_qty TO ls_item-text.
**    CONDENSE ls_item-text.
**
**    APPEND ls_item TO pt_item_table.
**
**    "자재별 사용량
**    CLEAR ls_item.
**    ls_item-node_key  = lv_parent_key.
**    ls_item-item_name = 'ACUSE'.
**    ls_item-class     = cl_gui_column_tree=>item_class_text.
**
**    WRITE lv_use_qty TO ls_item-text.
**    CONDENSE ls_item-text.
**
**    APPEND ls_item TO pt_item_table.
**
**    "같은 자재의 PO 자식 노드
**    LOOP AT gt_bottom INTO ls_all
**         WHERE matnr = <ls_bottom>-matnr.
**
**      ADD 1 TO lv_seq.
**
**      CLEAR ls_node.
**      ls_node-node_key  = lv_seq.
**      ls_node-relatkey  = lv_parent_key.
**      ls_node-relatship = cl_gui_column_tree=>relat_last_child.
**
**      APPEND ls_node TO pt_node_table.
**
**      "PO 번호 / 품목
**      CLEAR ls_item.
**      ls_item-node_key  = lv_seq.
**      ls_item-item_name = 'HEADTEXT'.
**      ls_item-class     = cl_gui_column_tree=>item_class_text.
**
**      CONCATENATE ls_all-ebeln ls_all-ebelp
**             INTO ls_item-text
**             SEPARATED BY '-'.
**
**      APPEND ls_item TO pt_item_table.
**
**      "PO별 지급량
**      CLEAR ls_item.
**      ls_item-node_key  = lv_seq.
**      ls_item-item_name = 'ACISS'.
**      ls_item-class     = cl_gui_column_tree=>item_class_text.
**
**      WRITE ls_all-aciss TO ls_item-text.
**      CONDENSE ls_item-text.
**
**      APPEND ls_item TO pt_item_table.
**
**      "PO별 사용량
**      CLEAR ls_item.
**      ls_item-node_key  = lv_seq.
**      ls_item-item_name = 'ACUSE'.
**      ls_item-class     = cl_gui_column_tree=>item_class_text.
**
**      WRITE ls_all-acuse TO ls_item-text.
**      CONDENSE ls_item-text.
**
**      APPEND ls_item TO pt_item_table.
**
**    ENDLOOP.
**
**  ENDLOOP.
**
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form zz_get_data
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_get_data.
**  DATA : lt_alsmex TYPE gty_alsmex_tab.
**  CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
**    EXPORTING
**      filename                = pa_file
**      i_begin_col             = 1
**      i_begin_row             = 2
**      i_end_col               = 22
**      i_end_row               = 1000
**    TABLES
**      intern                  = lt_alsmex
**    EXCEPTIONS
**      inconsistent_parameters = 1
**      upload_ole              = 2
**      OTHERS                  = 3.
**  IF sy-subrc <> 0.
**    MESSAGE e059.
**  ENDIF.
**
**  PERFORM zz_set_excel_data USING lt_alsmex.
**  PERFORM zz_get_extra_data.
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form zz_set_excel_data
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***&      --> LT_ALSMEX
***&---------------------------------------------------------------------*
**FORM zz_set_excel_data USING pt_alsmex TYPE gty_alsmex_tab.
**  DATA : lt_dfies           TYPE TABLE OF dfies,
**         lv_value           TYPE alsmex_tabline-value,
**         lv_function_name   TYPE rs38l_fnam,
**         lv_amount_internal TYPE wmto_s-amount.
**
**  DATA : lv_currency       TYPE tcurc-waers,
**         lv_amount_display TYPE wmto_s-amount.
**
**  CALL FUNCTION 'DDIF_FIELDINFO_GET'
**    EXPORTING
**      tabname   = 'ZSMMA00042'
**    TABLES
**      dfies_tab = lt_dfies.
**
**  LOOP AT pt_alsmex ASSIGNING FIELD-SYMBOL(<ls_alsmex>).
**    CLEAR lv_value.
**    lv_value = <ls_alsmex>-value.
**
**    ASSIGN COMPONENT <ls_alsmex>-col OF STRUCTURE gs_excel TO FIELD-SYMBOL(<fs_field>).
**    READ TABLE lt_dfies ASSIGNING FIELD-SYMBOL(<ls_dfies>) INDEX <ls_alsmex>-col.
**    TRY.
**        IF sy-subrc EQ 0.
**          CASE <ls_dfies>-inttype.
**            WHEN 'P'.
**              REPLACE ALL OCCURRENCES OF ',' IN <ls_alsmex>-value WITH space.
**              CONDENSE lv_value NO-GAPS.
**            WHEN 'D'.
**              REPLACE ALL OCCURRENCES OF '-' IN <ls_alsmex>-value WITH space.
**              REPLACE ALL OCCURRENCES OF '.' IN <ls_alsmex>-value WITH space.
**              REPLACE ALL OCCURRENCES OF '/' IN <ls_alsmex>-value WITH space.
**              CONDENSE lv_value NO-GAPS.
**          ENDCASE.
**          IF <ls_dfies>-convexit IS NOT INITIAL.
**            DATA(function_name) = 'CONVERSION_EXIT_' && <ls_dfies>-convexit && '_INPUT'.
**            CALL FUNCTION function_name
**              EXPORTING
**                input  = <ls_alsmex>-value
**              IMPORTING
**                output = <fs_field>.
**          ELSE.
**            <fs_field> = lv_value.
**          ENDIF.
**        ENDIF.
**      CATCH cx_sy_conversion_error.
**        CLEAR <fs_field>.
**    ENDTRY.
**    AT END OF row.
**      APPEND gs_excel TO gt_excel.
**      CLEAR gs_excel.
**
**    ENDAT.
**  ENDLOOP.
**  MOVE-CORRESPONDING gt_excel TO gt_bottom.
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form zz_get_extra_data
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_get_extra_data .
**
**  DATA lt_item_key TYPE HASHED TABLE OF ty_po_key WITH UNIQUE KEY ebeln ebelp.
**  DATA : lv_ebeln TYPE ebeln.
**
**  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
**    INSERT VALUE #(
**      ebeln = <ls_bottom>-ebeln
**      ebelp = <ls_bottom>-ebelp
**    ) INTO TABLE lt_item_key.
**  ENDLOOP.
**
**  IF lt_item_key IS NOT INITIAL.
**    SELECT *
**      FROM ztmma00060
**      FOR ALL ENTRIES IN @lt_item_key
**      WHERE ebeln = @lt_item_key-ebeln
**        AND ebelp = @lt_item_key-ebelp
**      INTO CORRESPONDING FIELDS OF TABLE @gt_top.
**  ENDIF.
**
**  READ TABLE gt_top INTO lv_ebeln INDEX 1.
**
**  SELECT SINGLE lifnr
**    FROM ztmma00050
**    WHERE ebeln = @lv_ebeln
**    INTO @DATA(lv_lifnr).
**
**  SELECT SINGLE a~dscor, a~qscor, a~pscor, a~tscor, a~grade, a~lifnr, b~name1
**    FROM ztmma00100 AS a
**    INNER JOIN ztcma00010 AS b
**    ON a~lifnr = b~lifnr
**    WHERE a~lifnr = @lv_lifnr
**      AND a~datab <= @sy-datum
**      AND a~datbi >= @sy-datum
**    INTO CORRESPONDING FIELDS OF @zsmma00041.
**
**  PERFORM zz_set_light.
**  PERFORM zz_set_column_tree.
**
**ENDFORM.
**
***&---------------------------------------------------------------------*
***& Form zz_get_bom
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_get_bom.
**
**  SELECT *
**    FROM ztcma00120
**    WHERE stlst    = '01'
**      AND datuv    <= @sy-datum
**      AND valid_to >= @sy-datum
**    INTO TABLE @gt_bom_head.
**
**  IF gt_bom_head IS NOT INITIAL.
**    SELECT *
**      FROM ztcma00130
**      FOR ALL ENTRIES IN @gt_bom_head
**      WHERE stlnr = @gt_bom_head-stlnr
**      INTO TABLE @gt_bom_item.
**  ENDIF.
**
**  SORT gt_bom_head BY matnr werks stlnr.
**  SORT gt_bom_item BY stlnr stlkn.
**
**ENDFORM.
**
***&---------------------------------------------------------------------*
***& Form zz_get_bom_bfs
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_get_bom_bfs .
**  DATA: lt_queue TYPE STANDARD TABLE OF ty_bom_req WITH EMPTY KEY,
**        lv_head  TYPE i VALUE 1.
**  DATA lv_child_qty TYPE ztcma00130-menge.
**
**  LOOP AT gt_top ASSIGNING FIELD-SYMBOL(<ls_top>). "po 물품 돌면서 bom 전개
**    APPEND INITIAL LINE TO lt_queue ASSIGNING FIELD-SYMBOL(<ls_queue>). "po에 따른 matnr 큐에 삽입
**    <ls_queue>-ebeln = <ls_top>-ebeln.
**    <ls_queue>-ebelp = <ls_top>-ebelp.
**    <ls_queue>-matnr = <ls_top>-matnr.
**    <ls_queue>-werks = <ls_top>-werks.
**    <ls_queue>-meins = <ls_top>-meins.
**    <ls_queue>-menge = <ls_top>-menge.
**    <ls_queue>-lv_level = lv_head.
**
**    WHILE lv_head <= lines( lt_queue ). "큐가 빌 때까지
**      READ TABLE lt_queue ASSIGNING FIELD-SYMBOL(<ls_queue_1>) INDEX lv_head. "큐 읽기.
**      lv_head += 1.
**
**      "헤드에 해당 물품이 없으면 마지막
**      READ TABLE gt_bom_head ASSIGNING FIELD-SYMBOL(<ls_head>) WITH KEY matnr = <ls_queue_1>-matnr
**                                                                       werks = <ls_queue_1>-werks.
**
**      IF sy-subrc <> 0.
**        CONTINUE.
**      ENDIF.
**      "아이템 돌면서 해당 자재 모두 큐에 넣음.
**      LOOP AT gt_bom_item ASSIGNING FIELD-SYMBOL(<ls_item>) WHERE stlnr = <ls_head>-stlnr.
**
**        lv_child_qty = <ls_queue_1>-menge * <ls_item>-menge / <ls_head>-bmeng.
**
**        READ TABLE gt_bom_req ASSIGNING FIELD-SYMBOL(<ls_bom_req>) WITH KEY ebeln = <ls_queue_1>-ebeln
**                                                                            ebelp = <ls_queue_1>-ebelp
**                                                                            matnr = <ls_item>-idnrk
**                                                                            werks = <ls_queue_1>-werks
**                                                                            meins = <ls_item>-meins.
**        IF sy-subrc = 0.
**          <ls_bom_req>-menge += lv_child_qty.
**        ELSE.
**          INSERT VALUE #(
**            ebeln = <ls_queue_1>-ebeln
**            ebelp = <ls_queue_1>-ebelp
**            matnr = <ls_item>-idnrk
**            werks = <ls_queue>-werks
**            menge = lv_child_qty
**            meins = <ls_item>-meins
**          ) INTO TABLE gt_bom_req.
**        ENDIF.
**
**        APPEND INITIAL LINE TO lt_queue ASSIGNING FIELD-SYMBOL(<ls_q>).
**        <ls_q>-ebeln = <ls_queue_1>-ebeln.
**        <ls_q>-ebelp = <ls_queue_1>-ebelp.
**        <ls_q>-matnr = <ls_item>-idnrk.
**        <ls_q>-werks = <ls_queue_1>-werks.
**        <ls_q>-meins = <ls_item>-meins.
**        <ls_q>-menge = lv_child_qty.
**        <ls_q>-lv_level = lv_head.
**
**      ENDLOOP.
**    ENDWHILE.
**  ENDLOOP.
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form zz_set_column_tree
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_set_column_tree.
**
**  DATA: lt_node_table TYPE treev_ntab,
**        lt_item_table TYPE item_table_type.
**
**  IF go_tree IS NOT BOUND.
**    RETURN.
**  ENDIF.
**
**  "재조회 또는 엑셀 재업로드 시 기존 트리 제거
**  CALL METHOD go_tree->delete_all_nodes.
**
**  PERFORM build_node_and_item_table
**    USING lt_node_table lt_item_table.
**
**  IF lt_node_table IS INITIAL.
**    CALL METHOD cl_gui_cfw=>flush.
**    RETURN.
**  ENDIF.
**
**  CALL METHOD go_tree->add_nodes_and_items
**    EXPORTING
**      node_table                = lt_node_table
**      item_table                = lt_item_table
**      item_table_structure_name = 'MTREEITM'
**    EXCEPTIONS
**      failed                    = 1
**      cntl_system_error         = 2
**      OTHERS                    = 3.
**
**  IF sy-subrc <> 0.
**    MESSAGE a099.
**  ENDIF.
**
**  "자재 부모 노드 펼치기
**  CALL METHOD go_tree->expand_root_nodes
**    EXPORTING
**      level_count = 1.
**
**  CALL METHOD cl_gui_cfw=>flush.
**
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form zz_set_light
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_set_light .
**  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
**    IF <ls_bottom>-aciss = <ls_bottom>-acuse.
**      <ls_bottom>-light = '3'.
**    ELSE.
**      <ls_bottom>-light = '1'.
**    ENDIF.
**  ENDLOOP.
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form zz_make_docu
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_make_docu .
**
**  DATA: lt_110        TYPE TABLE OF ztmma00110,
**        lv_cevno      TYPE zde_ceval,
**        lt_return     TYPE TABLE OF bapiret2,
**        lt_revalid    TYPE ty_t_revalid,
**        lt_done_rqnum TYPE SORTED TABLE OF ztexa00060-rqnum
**                        WITH UNIQUE KEY table_line,
**        lt_created    TYPE SORTED TABLE OF ty_revalid
**                        WITH UNIQUE KEY ebeln ebelp.
**
**  PERFORM zz_get_revalid CHANGING lt_revalid.
**
**  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
**
**    CLEAR: lv_cevno, lt_return.
**
**    CALL FUNCTION 'NUMBER_GET_NEXT'
**      EXPORTING
**        nr_range_nr = '01'
**        object      = 'ZMM_CEVNO'
**      IMPORTING
**        number      = lv_cevno.
**
**    APPEND INITIAL LINE TO lt_110 ASSIGNING FIELD-SYMBOL(<ls_110>).
**    MOVE-CORRESPONDING <ls_bottom> TO <ls_110>.
**
**    <ls_110>-cevno = lv_cevno.
**    <ls_110>-cfdat = sy-datum.
**    <ls_110>-cfusr = sy-uname.
**    <ls_110>-ernam = sy-uname.
**    <ls_110>-erdat = sy-datum.
**    <ls_110>-erzet = sy-uzeit.
**
**    LOOP AT lt_revalid ASSIGNING FIELD-SYMBOL(<ls_revalid>)
**      WHERE ebeln = <ls_bottom>-ebeln
**        AND ebelp = <ls_bottom>-ebelp.
**
**      INSERT <ls_revalid>-rqnum INTO TABLE lt_done_rqnum.
**
**    ENDLOOP.
**
**    IF <ls_bottom>-light = '1'.
**
**      <ls_110>-rcsts = '0010'.
**
**      IF NOT line_exists( lt_revalid[
**        ebeln = <ls_bottom>-ebeln
**        ebelp = <ls_bottom>-ebelp ] ).
**
**        READ TABLE lt_created TRANSPORTING NO FIELDS
**          WITH KEY ebeln = <ls_bottom>-ebeln
**                   ebelp = <ls_bottom>-ebelp.
**
**        IF sy-subrc <> 0.
**
**          CALL FUNCTION 'ZCM_EXC_CREATE'
**            EXPORTING
**              iv_srtyp  = 'SUBC'
**              iv_srnum  = lv_cevno
**              iv_sritm  = 00000
**              iv_owgrp  = 'MM'
**              iv_extyp  = 'PROC'
**            IMPORTING
**              et_return = lt_return.
**
**          IF line_exists( lt_return[ type = 'E' ] )
**          OR line_exists( lt_return[ type = 'A' ] )
**          OR line_exists( lt_return[ type = 'X' ] ).
**
**            ROLLBACK WORK.
**            MESSAGE s115 DISPLAY LIKE 'E'.
**            RETURN.
**
**          ENDIF.
**
**          INSERT VALUE #(
**            ebeln = <ls_bottom>-ebeln
**            ebelp = <ls_bottom>-ebelp
**          ) INTO TABLE lt_created.
**
**        ENDIF.
**
**      ENDIF.
**
**    ELSE.
**      <ls_110>-rcsts = '0020'.
**    ENDIF.
**
**  ENDLOOP.
**
**  MODIFY ztmma00110 FROM TABLE lt_110.
**
**  IF sy-subrc <> 0.
**    ROLLBACK WORK.
**    MESSAGE s116 DISPLAY LIKE 'E'.
**    RETURN.
**  ENDIF.
**
**  LOOP AT lt_done_rqnum ASSIGNING FIELD-SYMBOL(<lv_rqnum>).
**
**    CLEAR lt_return.
**
**    CALL FUNCTION 'ZCM_EXC_REQ_DONE'
**      EXPORTING
**        iv_rqnum  = <lv_rqnum>
**        iv_rstxt  = TEXT-t07
**      IMPORTING
**        et_return = lt_return.
**
**    IF line_exists( lt_return[ type = 'E' ] )
**    OR line_exists( lt_return[ type = 'A' ] )
**    OR line_exists( lt_return[ type = 'X' ] ).
**
**      ROLLBACK WORK.
**      MESSAGE S118 DISPLAY LIKE 'E'.
**      RETURN.
**
**    ENDIF.
**
**  ENDLOOP.
**
**  COMMIT WORK.
**
**  MESSAGE s070.
**  gv_check = abap_true.
**
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form zz_get_revalid
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM zz_get_revalid CHANGING pt_revalid TYPE ty_t_revalid.
**
**  DATA: lt_return    TYPE TABLE OF bapiret2,
**        lt_exreq_key TYPE ztt_exreq,
**        lt_exreq     TYPE ztt_exreq.
**
**  CLEAR pt_revalid.
**
**  CALL FUNCTION 'ZCM_EXC_REQ_GET'
**    EXPORTING
**      iv_tgpgm  = 'MM04'
**    IMPORTING
**      et_req    = lt_exreq
**      et_return = lt_return.
**
**  READ TABLE lt_return WITH KEY type = 'E'
**    TRANSPORTING NO FIELDS.
**
**  IF sy-subrc = 0.
**    MESSAGE s117  DISPLAY LIKE 'E'.
**    RETURN.
**  ENDIF.
**
**  LOOP AT lt_exreq ASSIGNING FIELD-SYMBOL(<ls_exreq>)
**       WHERE srtyp = 'SUBC'
**       AND acttp = 'RCHK'. ""10-16 추가
**
**    APPEND VALUE #(
**      srnum = <ls_exreq>-srnum
**      rqnum = <ls_exreq>-rqnum
**    ) TO lt_exreq_key.
**
**  ENDLOOP.
**
**  IF lt_exreq_key IS INITIAL.
**    RETURN.
**  ENDIF.
**
**  SORT lt_exreq_key BY srnum rqnum.
**  DELETE ADJACENT DUPLICATES FROM lt_exreq_key COMPARING srnum rqnum.
**
**  SELECT cevno, ebeln, ebelp
**    FROM ztmma00110
**    FOR ALL ENTRIES IN @lt_exreq_key
**    WHERE cevno = @lt_exreq_key-srnum
**    INTO TABLE @DATA(lt_old_docu).
**
**  LOOP AT lt_old_docu ASSIGNING FIELD-SYMBOL(<ls_old_docu>).
**
**    LOOP AT lt_exreq_key ASSIGNING FIELD-SYMBOL(<ls_exreq_key>)
**         WHERE srnum = <ls_old_docu>-cevno.
**
**      INSERT VALUE #(
**        ebeln = <ls_old_docu>-ebeln
**        ebelp = <ls_old_docu>-ebelp
**        srnum = <ls_exreq_key>-srnum
**        rqnum = <ls_exreq_key>-rqnum
**      ) INTO TABLE pt_revalid.
**
**    ENDLOOP.
**
**  ENDLOOP.
**
**ENDFORM.
***&---------------------------------------------------------------------*
***& Form show_kpi_0100
***&---------------------------------------------------------------------*
***& text
***&---------------------------------------------------------------------*
***& -->  p1        text
***& <--  p2        text
***&---------------------------------------------------------------------*
**FORM show_kpi_0100 .
**  DATA(lv_fail) = 0.
**  DATA(lv_success) = 0.
**  CONSTANTS lc_chart TYPE zcl_cm_kpi_html=>ty_ctype VALUE 'D'.
**
**  LOOP AT gt_bottom ASSIGNING FIELD-SYMBOL(<ls_bottom>).
**    IF <ls_bottom>-light = 1.
**      lv_fail += 1.
**    ELSEIF <ls_bottom>-light = 3.
**      lv_success += 1.
**    ENDIF.
**  ENDLOOP.
**
**  DATA(lv_total) = lines( gt_bottom ).
**
**  DATA(lv_pct) = COND i( WHEN lv_total > 0 THEN lv_success * 100 / lv_total ELSE 0 ).
**
**  DATA(lt_card) = VALUE zcl_cm_kpi_html=>tt_card(
**    ( label = |{ TEXT-t20 }|
**      value = replace(
**                val  = CONV string( TEXT-t22 )
**                sub  = '&1'
**                with = |{ lv_success }| )
**      sub   = |{ TEXT-t23 }|
**      color = 'B' )
**
**    ( label = |{ TEXT-t21 }|
**      value = replace(
**                val  = CONV string( TEXT-t22 )
**                sub  = '&1'
**                with = |{ lv_fail }| )
**      sub   = |{ TEXT-t24 }|
**      color = 'R' ) ).
**
**  DATA(lt_item) = VALUE zcl_cm_kpi_html=>tt_item(
**    ( label = |{ TEXT-t23 }| value = lv_success color = 'G' )
**    ( label = |{ TEXT-t24 }| value = lv_fail    color = 'R' ) ).
**
**  go_kpi->show_summary(
**    iv_title        = |{ TEXT-t25 }|
**    iv_chart_type   = lc_chart
**    iv_chart_title  = |{ TEXT-t26 }|
**    it_chart_item   = lt_item
**    iv_chart_center = replace(
**                        val  = CONV string( TEXT-t27 )
**                        sub  = '&1'
**                        with = |{ lv_pct }| )
**    it_card         = lt_card ).
**ENDFORM.
