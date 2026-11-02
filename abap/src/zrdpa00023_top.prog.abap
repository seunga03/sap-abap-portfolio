*&---------------------------------------------------------------------*
*& Include          ZRDPA00023_TOP
*&---------------------------------------------------------------------*

REPORT zrdpa00023 MESSAGE-ID zmsga.

TABLES: ztmma00010, ztmma00020.
CLASS lcl_event_receiver DEFINITION DEFERRED.

DATA: ok_code     TYPE sy-ucomm,
      go_cont     TYPE REF TO cl_gui_custom_container,
      go_grid     TYPE REF TO cl_gui_alv_grid,
      go_event    TYPE REF TO lcl_event_receiver,
      gt_fcat     TYPE lvc_t_fcat,
      gs_layo     TYPE lvc_s_layo,
      gv_has_data TYPE abap_bool.

DATA: go_reason_cont  TYPE REF TO cl_gui_custom_container,
      go_reason_edit  TYPE REF TO cl_gui_textedit,
      gv_reason       TYPE string,
      gv_reason_title TYPE string.

TYPES: BEGIN OF ty_display,
         fcsno       TYPE ztmma00010-fcsno,
         iteno       TYPE ztmma00020-iteno,
         werks       TYPE ztmma00010-werks,
         fcdat       TYPE ztmma00010-fcdat,
         tcdat       TYPE ztmma00010-tcdat,
         bsdat       TYPE ztmma00010-bsdat,
         hmons       TYPE ztmma00010-hmons,
         cstat       TYPE ztmma00010-cstat,
         activ       TYPE ztmma00010-activ,
         cuser       TYPE ztmma00010-cuser,
         cdate       TYPE ztmma00010-cdate,
         ctime       TYPE ztmma00010-ctime,
         matnr       TYPE ztmma00020-matnr,
         maktx       TYPE ztcma00020-maktx,
         soqty       TYPE ztmma00020-soqty,
         giqty       TYPE ztmma00020-giqty,
         gapqty      TYPE ztmma00020-gapqty,
         opqty       TYPE ztmma00020-opqty,
         aiqty       TYPE ztmma00020-aiqty,
         adqty       TYPE ztmma00020-adqty,
         fiqty       TYPE ztmma00020-fiqty,
         meins       TYPE ztmma00020-meins,
         rdate       TYPE ztmma00020-rdate,
         aistat      TYPE ztmma00020-aistat,
         aidat       TYPE ztmma00020-aidat,
         aitim       TYPE ztmma00020-aitim,
         aireason    TYPE ztmma00020-aireason,
         reason_link TYPE char20,
         hist_link   TYPE char20,
         fact_link   TYPE char20,
       END OF ty_display.
DATA gt_display TYPE STANDARD TABLE OF ty_display WITH EMPTY KEY.

TYPES: BEGIN OF ty_history_view,
         perio  TYPE ztmma00022-perio,
         matnr  TYPE ztmma00022-matnr,
         soqty  TYPE ztmma00022-soqty,
         giqty  TYPE ztmma00022-giqty,
         gapqty TYPE ztmma00022-gapqty,
         wrkdy  TYPE ztmma00022-wrkdy,
         meins  TYPE ztmma00022-meins,
       END OF ty_history_view.

TYPES: BEGIN OF ty_factor_view,
         factor_no   TYPE ztmma00023-factor_no,
         factor_type TYPE ztmma00023-factor_type,
         kunnr       TYPE ztmma00023-kunnr,
         refno       TYPE ztmma00023-refno,
         source      TYPE ztmma00023-source,
         asof_date   TYPE ztmma00023-asof_date,
         valid_from  TYPE ztmma00023-valid_from,
         valid_to    TYPE ztmma00023-valid_to,
         num_value   TYPE ztmma00023-num_value,
         value_unit  TYPE ztmma00023-value_unit,
         text_value  TYPE ztmma00023-text_value,
       END OF ty_factor_view.
