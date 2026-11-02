*&---------------------------------------------------------------------*
*& Include ZLFIA00011_TOP                           - Report ZLFIA00011
*&---------------------------------------------------------------------*
REPORT zlfia00020.

INCLUDE <icon>.

TABLES: ztcma00110.
TABLES: sscrfields.

DATA: BEGIN OF gw_apreg.
        INCLUDE TYPE zsfia00020.
DATA:   hdico   TYPE icon_d,            " 홀드 아이콘
        celltab TYPE lvc_t_styl,        " 셀별 입력 잠금
      END OF gw_apreg.
DATA gt_apreg LIKE TABLE OF gw_apreg.

DATA: go_cont_reg TYPE REF TO cl_gui_custom_container,
      go_alv_reg  TYPE REF TO cl_gui_alv_grid.

DATA: gt_fcat_reg TYPE lvc_t_fcat,
      gs_fcat_reg TYPE lvc_s_fcat.

DATA ok_code TYPE sy-ucomm.
*&---------------------------------------------------------------------*
DATA: BEGIN OF gw_head.
        INCLUDE TYPE zsfia00010.
DATA: END OF gw_head.
DATA gt_head LIKE TABLE OF gw_head.

DATA: BEGIN OF gw_item.
        INCLUDE TYPE zsfia00011.
DATA: END OF gw_item.
DATA gt_item LIKE TABLE OF gw_item.

DATA: go_cont   TYPE REF TO cl_gui_custom_container,
      go_split  TYPE REF TO cl_gui_splitter_container,
      go_top    TYPE REF TO cl_gui_container,
      go_bottom TYPE REF TO cl_gui_container,
      go_alv1   TYPE REF TO cl_gui_alv_grid,   " 상단 지급건
      go_alv2   TYPE REF TO cl_gui_alv_grid.   " 하단 반제상세
