*&---------------------------------------------------------------------*
*& Include          ZRCMA00020_TOP
*&---------------------------------------------------------------------*

TABLES: sscrfields.

TYPES: BEGIN OF ty_list,
         ebeln    TYPE ebeln,        " PO
         ebelp    TYPE ebelp,        " Item
         matnr    TYPE matnr,        " 자재
         matkl    TYPE matkl,        " 자재군
         lifnr    TYPE lifnr,        " 공급업체
         name1    TYPE name1_gp,     " 공급업체명
         eindt    TYPE eindt,        " 예정입고일
         dlday    TYPE i,            " 지연일수 = 오늘 - 예정입고일
         rkgrd    TYPE char10,       " 위험등급
         exflg    TYPE char4,        " Exception 있음/-
         rowcolor TYPE char4,
       END OF ty_list.

TYPES: BEGIN OF ty_stat,
         grpky     TYPE char40,                  " 공급업체명 또는 자재군
         delay_cnt TYPE i,                       " 지연건수
         avg_dlday TYPE p LENGTH 8 DECIMALS 1,   " 평균지연일수
         crit_cnt  TYPE i,                       " CRITICAL건수
       END OF ty_stat.

TYPES: BEGIN OF ty_range,
         grade TYPE char10,     " NORMAL / WARNING / CRITICAL
         numfr TYPE i,          " 지연일수 From
         numto TYPE i,          " 지연일수 To
         color TYPE char4,      " 행 색상
       END OF ty_range.
DATA gt_range TYPE STANDARD TABLE OF ty_range WITH EMPTY KEY.

DATA: gt_list TYPE STANDARD TABLE OF ty_list,
      gt_stat TYPE STANDARD TABLE OF ty_stat.

*--- 선택화면 참조용
DATA: gv_werks TYPE werks_d,
      gv_lifnr TYPE lifnr,
      gv_matkl TYPE matkl.

*--- 공통
DATA: ok_code   TYPE sy-ucomm,
      gv_okcode TYPE sy-ucomm.

*--- SCR 0100
DATA: go_cont_0100 TYPE REF TO cl_gui_custom_container,
      go_grid_0100 TYPE REF TO cl_gui_alv_grid,
      gt_fcat_0100 TYPE lvc_t_fcat.

*--- SCR 0200 (화면 필드)
DATA: go_cont_0200 TYPE REF TO cl_gui_custom_container,
      go_grid_0200 TYPE REF TO cl_gui_alv_grid,
      gt_fcat_0200 TYPE lvc_t_fcat,
      gv_spmon     TYPE spmon,          " 집계 기준월 YYYYMM
      gv_rb_ven    TYPE c VALUE 'X',    " 공급업체별
      gv_rb_mat    TYPE c.              " 자재군별
*--- KPI 패널
DATA: go_cont_kpi  TYPE REF TO cl_gui_custom_container,
      go_kpi       TYPE REF TO zcl_cm_kpi_html,
      gv_kpi_dirty TYPE abap_bool.
