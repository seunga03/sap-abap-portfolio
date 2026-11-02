*&---------------------------------------------------------------------*
*& Include ZLMMA00010_TOP                           - Report ZLMMA00010
*&---------------------------------------------------------------------*
  TYPES : BEGIN OF ty_issue,
            ebeln TYPE ztmma00090-ebeln,
            ebelp TYPE ztmma00090-ebelp,
            matnr TYPE ztmma00090-matnr,
            werks TYPE ztmma00090-werks,
            lgort TYPE ztmma00090-lgort,
            meins TYPE ztmma00090-meins,
            menge TYPE ztmma00090-menge,
          END OF ty_issue.

  TYPES : BEGIN OF ty_excel_key,
            ebeln TYPE ztmma00090-ebeln,
            ebelp TYPE ztmma00090-ebelp,
            matnr TYPE ztmma00090-matnr,
            werks TYPE ztmma00090-werks,
            lgort TYPE ztmma00090-lgort,
            meins TYPE ztmma00090-meins,
            count TYPE i,
          END OF ty_excel_key.
  TYPES: item_table_type LIKE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY.
  TYPES gty_alsmex_tab TYPE TABLE OF alsmex_tabline.
  TABLES : zsmma00041.
  TYPES : BEGIN OF ty_po_key,
            ebeln TYPE ebeln,
            ebelp TYPE ebelp,
          END OF ty_po_key.

  TYPES: BEGIN OF ty_bom_req,
           ebeln    TYPE ebeln,
           ebelp    TYPE ebelp,
           matnr    TYPE ztcma00130-idnrk,
           werks    TYPE ztcma00120-werks,
           menge    TYPE ztcma00130-menge,
           meins    TYPE ztcma00130-meins,
           lv_level TYPE i,
         END OF ty_bom_req.

  TYPES: BEGIN OF ty_revalid,
           ebeln TYPE ztmma00110-ebeln,
           ebelp TYPE ztmma00110-ebelp,
           srnum TYPE ztexa00060-srnum,
           rqnum TYPE ztexa00060-rqnum,
         END OF ty_revalid.

  TYPES ty_t_revalid TYPE STANDARD TABLE OF ty_revalid WITH EMPTY KEY.

  DATA : BEGIN OF gs_node,
           matnr LIKE zsmma00042-matnr,
           aciss LIKE zsmma00042-aciss,
           acuse LIKE zsmma00042-acuse.
  DATA : END OF gs_node.


  DATA : ok_code TYPE sy-ucomm.

  DATA : go_con TYPE REF TO cl_gui_custom_container.
  DATA : go_alv  TYPE REF TO cl_gui_alv_grid.

  DATA : go_con_tree TYPE REF TO cl_gui_custom_container,
         go_tree     TYPE REF TO cl_gui_column_tree.

  DATA : go_splitter TYPE REF TO cl_gui_splitter_container.

  DATA : go_top_container    TYPE REF TO cl_gui_container,
         go_right_container  TYPE REF TO cl_gui_container,
         go_bottom_container TYPE REF TO cl_gui_container.

  DATA : go_top_alv    TYPE REF TO cl_gui_alv_grid,
         go_bottom_alv TYPE REF TO cl_gui_alv_grid.

  DATA : gs_top_layo    TYPE lvc_s_layo,
         gs_bottom_layo TYPE lvc_s_layo.

  DATA : gt_top_fcat    TYPE lvc_t_fcat,
         gt_bottom_fcat TYPE lvc_t_fcat.

  DATA : gt_top    TYPE TABLE OF zsmma00040 WITH NON-UNIQUE SORTED KEY idx01 COMPONENTS matnr,
         gt_bottom TYPE TABLE OF zsmma00047 WITH NON-UNIQUE SORTED KEY idx01 COMPONENTS matnr.

  DATA : gt_node LIKE TABLE OF gs_node.

  DATA : gs_excel TYPE zsmma00042.
  DATA : gt_excel TYPE TABLE OF zsmma00042.

  DATA : gs_lifnr TYPE zsmma00041.

  DATA :gt_bom_head TYPE TABLE OF ztcma00120, "REFRESH X
        gt_bom_item TYPE TABLE OF ztcma00130. "REFRESH X


  DATA gt_bom_req TYPE HASHED TABLE OF ty_bom_req
                  WITH UNIQUE KEY ebeln ebelp matnr werks meins.

  DATA gt_bom_queue TYPE TABLE OF ty_bom_req.

  DATA : gs_layo_top TYPE lvc_s_layo,
         gs_layo_bot TYPE lvc_s_layo.

  DATA : gv_check TYPE abap_bool.

  DATA: go_cont_kpi  TYPE REF TO cl_gui_custom_container,
        go_kpi       TYPE REF TO zcl_cm_kpi_html,
        gv_kpi_dirty TYPE abap_bool.

  TYPES: BEGIN OF ty_sc_key,
           ebeln TYPE ztmma00060-ebeln,
           ebelp TYPE ztmma00060-ebelp,
         END OF ty_sc_key.
  TYPES: BEGIN OF ty_sc_issue,
           ebeln TYPE ztmma00090-ebeln,
           ebelp TYPE ztmma00090-ebelp,
           matnr TYPE ztmma00090-matnr,
           werks TYPE ztmma00090-werks,
           lgort TYPE ztmma00090-lgort,
           meins TYPE ztmma00090-meins,
           qty   TYPE p LENGTH 16 DECIMALS 3,
         END OF ty_sc_issue.
  TYPES: BEGIN OF ty_sc_upload,
           ebeln TYPE ztmma00090-ebeln,
           ebelp TYPE ztmma00090-ebelp,
           matnr TYPE ztmma00090-matnr,
           werks TYPE ztmma00090-werks,
           lgort TYPE ztmma00090-lgort,
           meins TYPE ztmma00090-meins,
           cnt   TYPE i,
         END OF ty_sc_upload.
  TYPES: BEGIN OF ty_sc_error,
           ebeln TYPE ztmma00060-ebeln,
           ebelp TYPE ztmma00060-ebelp,
           text  TYPE string,
         END OF ty_sc_error.
  TYPES: BEGIN OF ty_sc_display.
           INCLUDE TYPE zsmma00047.
  TYPES:     sysiss TYPE p LENGTH 16 DECIMALS 3,
           bomqty TYPE p LENGTH 16 DECIMALS 3,
           chkmsg TYPE c LENGTH 255,
         END OF ty_sc_display.

  DATA: gt_sc_keys    TYPE SORTED TABLE OF ty_sc_key
                           WITH UNIQUE KEY ebeln ebelp,
        gt_sc_po      TYPE STANDARD TABLE OF ztmma00060 WITH EMPTY KEY,
        gt_sc_issue   TYPE SORTED TABLE OF ty_sc_issue
                          WITH UNIQUE KEY ebeln ebelp matnr werks lgort meins,
        gt_sc_upload  TYPE SORTED TABLE OF ty_sc_upload
                         WITH UNIQUE KEY ebeln ebelp matnr werks lgort meins,
        gt_sc_error   TYPE SORTED TABLE OF ty_sc_error
                          WITH UNIQUE KEY ebeln ebelp,
        gt_sc_display TYPE STANDARD TABLE OF ty_sc_display WITH EMPTY KEY,
        gv_sc_invalid TYPE abap_bool.

  DATA : go_top_splitter    TYPE REF TO cl_gui_splitter_container,
         go_po_container    TYPE REF TO cl_gui_container,
         go_issue_container TYPE REF TO cl_gui_container,
         go_issue_alv       TYPE REF TO cl_gui_alv_grid,
         gt_issue           TYPE TABLE OF zsmma00090,
         gt_issue_fcat      TYPE lvc_t_fcat,
         gs_issue_layo      TYPE lvc_s_layo.

  DATA : gt_material type table of ztcma00020,
        gt_plant    type table of ztcma00140,
        gt_storage type table of ztcma00150.
