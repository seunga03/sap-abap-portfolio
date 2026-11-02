*&---------------------------------------------------------------------*
*& Include ZLFIA00070_TOP                           - Module Pool      ZLFIA00070
*&---------------------------------------------------------------------*
REPORT zlfia00070.

TABLES: ztfia00010, sscrfields.

DATA: BEGIN OF gw_head.
        INCLUDE TYPE zsfia00070.
DATA:   stico TYPE icon_d,                 " 상태 아이콘
        adjbt TYPE ztcma00110-adjbt,       " 조정액
        netbt TYPE ztcma00110-dmbtr,       " 확정채무 (청구액 - 조정액)
      END OF gw_head.
DATA gt_head LIKE TABLE OF gw_head.

DATA: BEGIN OF gw_item.
        INCLUDE TYPE zsfia00071.
DATA: END OF gw_item.
DATA gt_item     LIKE TABLE OF gw_item.

DATA: go_cont   TYPE REF TO cl_gui_custom_container,
      go_split  TYPE REF TO cl_gui_splitter_container,
      go_top    TYPE REF TO cl_gui_container,
      go_bottom TYPE REF TO cl_gui_container,
      go_alv1   TYPE REF TO cl_gui_alv_grid,   " 상단 송장 헤더
      go_alv2   TYPE REF TO cl_gui_alv_grid.   " 하단 PO라인 상세

DATA: gt_fcat1 TYPE lvc_t_fcat,
      gt_fcat2 TYPE lvc_t_fcat.

DATA: go_cc  TYPE REF TO cl_gui_custom_container,   " KPI 패널 자리
      go_kpi TYPE REF TO zcl_cm_kpi_html.            " 유진 공용 KPI 클래스

DATA ok_code TYPE sy-ucomm.
