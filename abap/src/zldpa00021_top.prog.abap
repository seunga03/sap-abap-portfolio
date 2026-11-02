*&---------------------------------------------------------------------*
*& Include          ZLDPA00021_TOP
*&---------------------------------------------------------------------*

REPORT zldpa00021 MESSAGE-ID zmsga.

TABLES: ztmma00010, ztmma00020, ztcma00170, ztcma00180.

CLASS: lcl_event_receiver DEFINITION DEFERRED.

*---------------------------------------------------------------------*
* Global Data
*---------------------------------------------------------------------*
DATA: ok_code TYPE sy-ucomm.

*** Prototype 상태
DATA: gv_ai_done TYPE abap_bool,
      gv_confirm TYPE abap_bool.

*** Forecast Period
DATA: gv_hmons     TYPE ztmma00010-hmons,
      gv_fc_from   TYPE ztmma00010-fcdat,
      gv_fc_to     TYPE ztmma00010-tcdat,
      gv_hist_from TYPE sy-datum,
      gv_hist_to   TYPE sy-datum.

DATA: gv_has_data TYPE abap_bool.

*** AI 예측사유 팝업
DATA: gv_reason_matnr TYPE ztmma00020-matnr,
      gv_reason_maktx TYPE ztcma00020-maktx,
      gv_reason_aiqty TYPE ztmma00020-aiqty,
      gv_reason_meins TYPE ztmma00020-meins,
      gv_reason       TYPE string.

*** AI 실행일시 및 영업일수
DATA: gv_ai_date  TYPE sy-datum,
      gv_ai_time  TYPE sy-uzeit,
      gt_workdays TYPE HASHED TABLE OF ztcma00160 WITH UNIQUE KEY werks perio.

*---------------------------------------------------------------------*
* ALV
*---------------------------------------------------------------------*
DATA: go_cont TYPE REF TO cl_gui_custom_container,
      go_grid TYPE REF TO cl_gui_alv_grid.

DATA: gt_fcat TYPE lvc_t_fcat,
      gs_fcat TYPE lvc_s_fcat,
      gs_layo TYPE lvc_s_layo.

DATA: go_reason_cont TYPE REF TO cl_gui_custom_container,
      go_reason_edit TYPE REF TO cl_gui_textedit.

DATA: go_event TYPE REF TO lcl_event_receiver.

*---------------------------------------------------------------------*
* Forecast Output
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_forecast,
         iteno        TYPE ztmma00020-iteno,
         matnr        TYPE ztmma00020-matnr,
         maktx        TYPE ztcma00020-maktx,
         soqty        TYPE ztmma00020-soqty,
         giqty        TYPE ztmma00020-giqty,
         gapqty       TYPE ztmma00020-gapqty,
         opqty        TYPE ztmma00020-opqty,
         cur_open_qty TYPE ztmma00020-opqty,
         overdue_qty  TYPE ztmma00020-opqty,
         meins        TYPE ztmma00020-meins,

         """ DP00 외부요인
         plan_rate    TYPE ztcma00170-change_rate,
         plan_dir     TYPE ztcma00170-change_dir,
         event_type   TYPE ztcma00180-event_type,
         impact_dir   TYPE ztcma00180-impact_dir,
         impact_rate  TYPE ztcma00180-impact_rate,

         """ 외부요인 건수
         plan_count   TYPE i,
         event_count  TYPE i,

         """ AI 결과
         aiqty        TYPE ztmma00020-aiqty,
         aireason     TYPE ztmma00020-aireason,
         reason_link  TYPE char20,

         """ 사용자 보정 / 최종값
         adqty        TYPE ztmma00020-adqty,
         fiqty        TYPE ztmma00020-fiqty,
         rdate        TYPE ztmma00020-rdate,

         aistat       TYPE ztmma00020-aistat,
         aistat_text  TYPE ztcma00080-cdnam,
       END OF ty_forecast.

DATA: gt_forecast TYPE STANDARD TABLE OF ty_forecast,
      gs_forecast TYPE ty_forecast.

*---------------------------------------------------------------------*
* History Detail
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_history,
         matnr  TYPE ztmma00022-matnr,
         perio  TYPE ztmma00022-perio,
         soqty  TYPE ztmma00022-soqty,
         giqty  TYPE ztmma00022-giqty,
         gapqty TYPE ztmma00022-gapqty,
         meins  TYPE ztmma00022-meins,
       END OF ty_history.

DATA: gt_history TYPE STANDARD TABLE OF ty_history,
      gs_history TYPE ty_history.

*---------------------------------------------------------------------*
* Customer Production Plan - AI Input
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_ext_plan,
         plnno        TYPE ztcma00170-plnno,
         iteno        TYPE ztcma00170-iteno,
         colno        TYPE ztcma00170-colno,
         kunnr        TYPE ztcma00170-kunnr,
         matnr        TYPE ztcma00170-matnr,
         perio        TYPE ztcma00170-perio,
         source       TYPE ztcma00170-source,
         plan_qty     TYPE ztcma00170-plan_qty,
         meins        TYPE ztcma00170-meins,
         change_dir   TYPE ztcma00170-change_dir,
         change_rate  TYPE ztcma00170-change_rate,
         collect_date TYPE ztcma00170-collect_date,
       END OF ty_ext_plan.

DATA: gt_ext_plan TYPE STANDARD TABLE OF ty_ext_plan.

*---------------------------------------------------------------------*
* Customer Event - AI Input
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_ext_event,
         evtno        TYPE ztcma00180-evtno,
         iteno        TYPE ztcma00180-iteno,
         colno        TYPE ztcma00180-colno,
         kunnr        TYPE ztcma00180-kunnr,
         matnr        TYPE ztcma00180-matnr,
         event_type   TYPE ztcma00180-event_type,
         valid_from   TYPE ztcma00180-valid_from,
         valid_to     TYPE ztcma00180-valid_to,
         source       TYPE ztcma00180-source,
         impact_dir   TYPE ztcma00180-impact_dir,
         impact_rate  TYPE ztcma00180-impact_rate,
         event_text   TYPE ztcma00180-event_text,
         collect_date TYPE ztcma00180-collect_date,
       END OF ty_ext_event.

DATA: gt_ext_event TYPE STANDARD TABLE OF ty_ext_event.

*---------------------------------------------------------------------*
* AI Forecast Response
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_ai_result,
         matnr    TYPE ztmma00020-matnr,
         aiqty    TYPE ztmma00020-aiqty,
         aireason TYPE string,
       END OF ty_ai_result.
TYPES tt_ai_result TYPE STANDARD TABLE OF ty_ai_result
                   WITH DEFAULT KEY.
TYPES: BEGIN OF ty_ai_response,
         forecasts TYPE tt_ai_result,
       END OF ty_ai_response.

*---------------------------------------------------------------------*
* AI Forecast Input
*---------------------------------------------------------------------*
TYPES tt_forecast TYPE STANDARD TABLE OF ty_forecast WITH DEFAULT KEY.
TYPES tt_history TYPE STANDARD TABLE OF ty_history WITH DEFAULT KEY.
TYPES tt_ext_plan TYPE STANDARD TABLE OF ty_ext_plan WITH DEFAULT KEY.
TYPES tt_ext_event TYPE STANDARD TABLE OF ty_ext_event WITH DEFAULT KEY.

TYPES: BEGIN OF ty_ai_input,
         werks          TYPE ztmma00010-werks,
         base_date      TYPE ztmma00010-bsdat,
         forecast_from  TYPE ztmma00010-fcdat,
         forecast_to    TYPE ztmma00010-tcdat,
         history_months TYPE ztmma00010-hmons,
         forecasts      TYPE tt_forecast,
         history        TYPE tt_history,
         plans          TYPE tt_ext_plan,
         events         TYPE tt_ext_event,
       END OF ty_ai_input.


*---------------------------------------------------------------------*
* 저장용
*---------------------------------------------------------------------*
TYPES: tt_dp21_head TYPE STANDARD TABLE OF ztmma00010 WITH DEFAULT KEY,
       tt_dp21_item TYPE STANDARD TABLE OF ztmma00020 WITH DEFAULT KEY,
       tt_dp21_hist TYPE STANDARD TABLE OF ztmma00022 WITH DEFAULT KEY,
       tt_dp21_fact TYPE STANDARD TABLE OF ztmma00023 WITH DEFAULT KEY.

*---------------------------------------------------------------------*
* 코드 테이블
*---------------------------------------------------------------------*
TYPES: BEGIN OF ty_ai_code,
         cdval TYPE ztcma00080-cdval,
         cdnam TYPE ztcma00080-cdnam,
       END OF ty_ai_code.

DATA gt_ai_code TYPE HASHED TABLE OF ty_ai_code WITH UNIQUE KEY cdval.

*---------------------------------------------------------------------*
* KPI HTML
*---------------------------------------------------------------------*
DATA: go_kpi_cont TYPE REF TO cl_gui_custom_container,
      go_kpi      TYPE REF TO zcl_cm_kpi_html.
