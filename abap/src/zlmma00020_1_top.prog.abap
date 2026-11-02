*&---------------------------------------------------------------------*
*& Include ZLMMA00010_TOP                           - Report ZLMMA00010
*&---------------------------------------------------------------------*


TYPES: BEGIN OF ty_tree_map,
         node_key  TYPE tv_nodekey,
         node_type TYPE c LENGTH 1, "M: 자재 폴더 / V: 공급업체
         matnr     TYPE matnr,
         lifnr     TYPE lifnr,
       END OF ty_tree_map.


TYPES: BEGIN OF ty_po_seq,
         ebeln TYPE ebeln,
         ebelp TYPE ebelp,
       END OF ty_po_seq.

TYPES: BEGIN OF ty_f4_vendor,
         lifnr TYPE lifnr,
         name1 TYPE zsmma00045-name1,
         netpr TYPE zsmma00045-netpr,
         waers TYPE zsmma00045-waers,
         plifz TYPE zsmma00045-plifz,
         tscor TYPE zsmma00045-tscor,
         qscor TYPE zsmma00045-qscor,
         dscor TYPE zsmma00045-dscor,
         pscor TYPE zsmma00045-pscor,
         grade TYPE zsmma00045-grade,
       END OF ty_f4_vendor.
TYPES ty_t_bom_move_head TYPE STANDARD TABLE OF ztmma00080
                       WITH DEFAULT KEY.
TYPES ty_t_bom_pr TYPE STANDARD TABLE OF ztmma00040
                 WITH DEFAULT KEY.

DATA : ok_code TYPE sy-ucomm. ""OK CODE

"" 화면 오브젝트
DATA : go_con TYPE REF TO cl_gui_custom_container.
DATA : go_split_main TYPE REF TO cl_gui_splitter_container,
       go_split_popr TYPE REF TO cl_gui_splitter_container.

DATA : go_con_left TYPE REF TO cl_gui_container,
       go_con_pr   TYPE REF TO cl_gui_container,
       go_con_po   TYPE REF TO cl_gui_container,
       go_con_tree TYPE REF TO cl_gui_container.

DATA : go_tree            TYPE REF TO cl_gui_column_tree,
       gt_tree_map        TYPE HASHED TABLE OF ty_tree_map
                               WITH UNIQUE KEY node_key.

DATA : go_alv_pr TYPE REF TO cl_gui_alv_grid.
DATA : go_alv_po TYPE REF TO cl_gui_alv_grid.



"" 필드 카탈로그 및 레이아웃
DATA : gt_fcat_pr TYPE lvc_t_fcat,
       gt_fcat_po TYPE lvc_t_fcat.

DATA : gs_layo_pr TYPE lvc_s_layo,
       gs_layo_po TYPE lvc_s_layo.


DATA : gt_pr  TYPE TABLE OF zsmma00043 WITH NON-UNIQUE SORTED KEY idx01 COMPONENTS banfn bnfpo, "pr 구조
       gt_pr_show TYPE TABLE OF zsmma00043,
       gt_po  TYPE TABLE OF zsmma00044, "po 구조
*       gt_po_show TYPE TABLE OF zsmma00044,
       gt_lifnr   TYPE TABLE OF zsmma00045 WITH NON-UNIQUE SORTED KEY idx01 COMPONENTS lifnr. "공급업체-자재

DATA : gt_pr_save TYPE TABLE OF zsmma00043.

"" 200번 화면
DATA: go_con_history  TYPE REF TO cl_gui_custom_container,
      go_alv_history  TYPE REF TO cl_gui_alv_grid,
      gt_history      TYPE TABLE OF zsmma00046,
      gt_fcat_history TYPE lvc_t_fcat,
      gs_layo_history TYPE lvc_s_layo.

DATA gt_exclude_po TYPE ui_functions.

DATA : gv_offset TYPE i.
TABLES : zsmma00100.
