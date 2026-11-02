*&---------------------------------------------------------------------*
*& Include          ZRDPA00013_TOP
*&---------------------------------------------------------------------*

REPORT zrdpa00013 MESSAGE-ID zmsga.

TABLES: ztcma00170, ztcma00180.

*----------------------------------------------------------------------*
* DATA Declare
*----------------------------------------------------------------------*
DATA: ok_code     TYPE sy-ucomm,
      gv_has_data TYPE abap_bool.

DATA: go_cont_plan  TYPE REF TO cl_gui_custom_container,
      go_grid_plan  TYPE REF TO cl_gui_alv_grid,
      go_cont_event TYPE REF TO cl_gui_custom_container,
      go_grid_event TYPE REF TO cl_gui_alv_grid.

DATA: gt_plan_fcat  TYPE lvc_t_fcat,
      gt_event_fcat TYPE lvc_t_fcat,
      gs_fcat       TYPE lvc_s_fcat,
      gs_layo       TYPE lvc_s_layo,
      gv_fcat_pos   TYPE lvc_s_fcat-col_pos.

*----------------------------------------------------------------------*
* 생산계획
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_plan,
         plnno        TYPE ztcma00170-plnno,
         iteno        TYPE ztcma00170-iteno,
         colno        TYPE ztcma00170-colno,
         kunnr        TYPE ztcma00170-kunnr,
         matnr        TYPE ztcma00170-matnr,
         maktx        TYPE ztcma00020-maktx,
         perio        TYPE ztcma00170-perio,
         plan_qty     TYPE ztcma00170-plan_qty,
         meins        TYPE ztcma00170-meins,
         change_dir   TYPE ztcma00170-change_dir,
         change_rate  TYPE ztcma00170-change_rate,
         source       TYPE ztcma00170-source,
         collect_date TYPE ztcma00170-collect_date,
         confirm_yn   TYPE ztcma00170-confirm_yn,
         raw_text     TYPE ztcma00170-raw_text,
       END OF ty_plan.

DATA: gt_plan TYPE STANDARD TABLE OF ty_plan,
      gs_plan TYPE ty_plan.

*----------------------------------------------------------------------*
* Event
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_event,
         evtno        TYPE ztcma00180-evtno,
         iteno        TYPE ztcma00180-iteno,
         colno        TYPE ztcma00180-colno,
         kunnr        TYPE ztcma00180-kunnr,
         matnr        TYPE ztcma00180-matnr,
         maktx        TYPE ztcma00020-maktx,
         event_type   TYPE ztcma00180-event_type,
         valid_from   TYPE ztcma00180-valid_from,
         valid_to     TYPE ztcma00180-valid_to,
         impact_dir   TYPE ztcma00180-impact_dir,
         impact_rate  TYPE ztcma00180-impact_rate,
         source       TYPE ztcma00180-source,
         collect_date TYPE ztcma00180-collect_date,
         confirm_yn   TYPE ztcma00180-confirm_yn,
         event_text   TYPE ztcma00180-event_text,
       END OF ty_event.

DATA: gt_event TYPE STANDARD TABLE OF ty_event,
      gs_event TYPE ty_event.
