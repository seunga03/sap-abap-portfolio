*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_TOP
*&---------------------------------------------------------------------*
REPORT zlfia00040.

TABLES: ztfia00060.
TABLES: sscrfields.

DATA: BEGIN OF gw_head.
        INCLUDE TYPE zsfia00040.
DATA: END OF gw_head.

DATA: BEGIN OF gw_item.
        INCLUDE TYPE zsfia00041.
DATA: END OF gw_item.

DATA gt_head LIKE TABLE OF gw_head.
DATA gt_item LIKE TABLE OF gw_item.
DATA ls_first like gw_head.

DATA: go_cont   TYPE REF TO cl_gui_custom_container,
      go_split  TYPE REF TO cl_gui_splitter_container,
      go_top    TYPE REF TO cl_gui_container,
      go_bottom TYPE REF TO cl_gui_container,
      go_alv1   TYPE REF TO cl_gui_alv_grid,
      go_alv2   TYPE REF TO cl_gui_alv_grid.

DATA: gt_fcat1 TYPE lvc_t_fcat,
      gt_fcat2 TYPE lvc_t_fcat.

DATA ok_code TYPE sy-ucomm.
