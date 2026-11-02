*&---------------------------------------------------------------------*
*& Include ZLMMA00010_TOP                           - Report ZLMMA00010
*&---------------------------------------------------------------------*

TYPES: BEGIN OF gty_move,
         mblnr  TYPE ztmma00090-mblnr,
         mjahr  TYPE ztmma00090-mjahr,
         zeile  TYPE ztmma00090-zeile,
         ebeln  TYPE ztmma00090-ebeln,
         ebelp  TYPE ztmma00090-ebelp, "M: 자재 폴더 / V: 공급업체
         menge  TYPE ztmma00090-menge,
         meins TYPE ztmma00090-meins,
       END OF gty_move.

DATA : ok_code TYPE sy-ucomm.

DATA : go_con      TYPE REF TO cl_gui_custom_container,
       go_splitter TYPE REF TO cl_gui_splitter_container,
       go_con_top  TYPE REF TO cl_gui_container,
       go_con_bot  TYPE REF TO cl_gui_container,
       go_alv_top  TYPE REF TO cl_gui_alv_grid,
       go_alv_bot  TYPE REF TO cl_gui_alv_grid.

DATA : gs_layo_top TYPE lvc_s_layo,
       gs_layo_bot TYPE lvc_s_layo.

DATA : gt_040      TYPE TABLE OF ztmma00040,
       gt_alv_top  TYPE TABLE OF zsmma00030,
       gt_alv_bot  TYPE TABLE OF zsmma00030,
       gt_fcat_top TYPE lvc_t_fcat,
       gt_fcat_bot TYPE lvc_t_fcat.

DATA : gt_header TYPE zttmma00050,
       gt_item   TYPE zttmma00060.

DATA : gt_quantity TYPE TABLE OF gty_move.
DATA gt_exclude_bot TYPE ui_functions.
