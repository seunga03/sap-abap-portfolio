*&---------------------------------------------------------------------*
*& Include ZLFIA00011_TOP                           - Report ZLFIA00011
*&---------------------------------------------------------------------*
REPORT zlfia00050.

TABLES: ztcma00100.
TABLES: sscrfields.

DATA: BEGIN OF gw_arreg.
        INCLUDE TYPE zsfia00050.
DATA: END OF gw_arreg.
DATA gt_arreg LIKE TABLE OF gw_arreg.

DATA: go_cont_reg TYPE REF TO cl_gui_custom_container,
      go_alv_reg  TYPE REF TO cl_gui_alv_grid.

DATA: gt_fcat_reg TYPE lvc_t_fcat,
      gs_fcat_reg TYPE lvc_s_fcat.

DATA ok_code TYPE sy-ucomm.
*&---------------------------------------------------------------------*
DATA: BEGIN OF gw_head.
        INCLUDE TYPE zsfia00040.      " ← AR 조회 헤더 구조체명으로
DATA: END OF gw_head.
DATA gt_head LIKE TABLE OF gw_head.

DATA: BEGIN OF gw_item.
        INCLUDE TYPE zsfia00041.      " ← AR 조회 아이템 구조체명으로
DATA: END OF gw_item.
DATA gt_item LIKE TABLE OF gw_item.

DATA: go_cont   TYPE REF TO cl_gui_custom_container,
      go_split  TYPE REF TO cl_gui_splitter_container,
      go_top    TYPE REF TO cl_gui_container,
      go_bottom TYPE REF TO cl_gui_container,
      go_alv1   TYPE REF TO cl_gui_alv_grid,   " 상단 수금건
      go_alv2   TYPE REF TO cl_gui_alv_grid.   " 하단 반제상세
