*&---------------------------------------------------------------------*
*& Include          ZLDPA00011_U_TOP
*&---------------------------------------------------------------------*

REPORT zldpa00011_u MESSAGE-ID zmsga.

INCLUDE <icon>.

*----------------------------------------------------------------------*
* DATA Declare
*----------------------------------------------------------------------*
DATA: ok_code TYPE sy-ucomm.

*** 화면용 변수
DATA: gv_name1 TYPE ztcma00050-name1,
      gv_ttext TYPE c LENGTH 10,
      gv_itext TYPE c LENGTH 10.

DATA: gv_ftype TYPE char10,
      gv_fname TYPE c LENGTH 255,
      gv_rtype TYPE c LENGTH 1.

*** 문서번호
DATA: gv_colno TYPE zde_colno,
      gv_plnno TYPE zde_plnno,
      gv_evtno TYPE zde_evtno.

*** Text Editor
DATA: go_text_container TYPE REF TO cl_gui_custom_container,
      go_text_editor    TYPE REF TO cl_gui_textedit.

*---------------------------------------------------------------------*
* [추가] 편집기 안내문
*  - Text Editor가 비어 있을 때(파일도 안 올리고 직접 입력도 안 한 상태)
*    보여줄 안내 문구이다.
*  - 이 SAP GUI Text Editor는 웹페이지의 회색 placeholder처럼
*    글자를 흐리게 보여주는 기능이 없다. 그래서 이 문자열은 그냥
*    보통 검은 글씨로 편집기에 들어가며, 사용자가 지우지 않고
*    그대로 둘 수도 있다.
*  - 그래서 AI 추출 전에 zz_exe_ai_analytics 에서 편집기 내용이
*    이 안내문과 똑같은지 다시 확인하여, 안내문 그대로면
*    "원문이 없다"로 처리한다 (F01의 수정 부분 참고).
*---------------------------------------------------------------------*
DATA: gv_editor_hint TYPE char255 VALUE
  '원문을 여기에 붙여넣거나, 첫 화면에서 파일을 업로드한 뒤 [AI 추출] 버튼을 눌러 주세요.'.

*** 원문 영역 Subscreen
DATA gv_source_dynnr TYPE sy-dynnr VALUE '0140'.

*** PDF Viewer
DATA: go_pdf_container TYPE REF TO cl_gui_custom_container,
      go_pdf_viewer    TYPE REF TO cl_gui_html_viewer.

DATA: gv_pdf_url    TYPE c LENGTH 255,
      gv_pdf_loaded TYPE abap_bool.

DATA: gt_text TYPE STANDARD TABLE OF char255,
      gv_text TYPE char255.
DATA: gv_raw_text TYPE string.

*** PDF Binary
DATA: gt_binary      TYPE solix_tab,
      gv_file_length TYPE i.

*** Subscreen
DATA: gv_dynnr TYPE sy-dynnr VALUE '0110'.

DATA: gv_plan_mark  TYPE c LENGTH 1,
      gv_event_mark TYPE c LENGTH 1.

*----------------------------------------------------------------------*
* Table Control & Tabstrip
*----------------------------------------------------------------------*
CONTROLS: tab_main TYPE TABSTRIP.
CONTROLS: tc_plan  TYPE TABLEVIEW USING SCREEN 0110.
CONTROLS: tc_event TYPE TABLEVIEW USING SCREEN 0120.

*----------------------------------------------------------------------*
* 생산계획 Preview
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_plan,
         mark        TYPE c LENGTH 1,
         matnr       TYPE ztcma00170-matnr,
         maktx       TYPE ztcma00020-maktx,
         perio       TYPE ztcma00170-perio,
         plan_qty    TYPE ztcma00170-plan_qty,
         meins       TYPE ztcma00170-meins,
         change_dir  TYPE ztcma00170-change_dir,
         change_name TYPE ztcma00080-cdnam,
         change_rate TYPE ztcma00170-change_rate,
         raw_text    TYPE ztcma00170-raw_text,
       END OF ty_plan.

DATA: gt_plan TYPE STANDARD TABLE OF ty_plan,
      gs_plan TYPE ty_plan.

*----------------------------------------------------------------------*
* Event Preview
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_event,
         mark        TYPE c LENGTH 1,
         matnr       TYPE ztcma00180-matnr,
         maktx       TYPE ztcma00020-maktx,
         event_type  TYPE ztcma00180-event_type,
         event_name  TYPE ztcma00080-cdnam,
         valid_from  TYPE ztcma00180-valid_from,
         valid_to    TYPE ztcma00180-valid_to,
         impact_dir  TYPE ztcma00180-impact_dir,
         impact_rate TYPE ztcma00180-impact_rate,
         impact_name TYPE ztcma00080-cdnam,
         event_text  TYPE ztcma00180-event_text,
       END OF ty_event.

DATA: gt_event TYPE STANDARD TABLE OF ty_event,
      gs_event TYPE ty_event.

*----------------------------------------------------------------------*
* AI 분석용 마스터 데이터
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_ai_material,
         matnr TYPE ztcma00020-matnr,
         maktx TYPE ztcma00020-maktx,
       END OF ty_ai_material.

TYPES: BEGIN OF ty_ai_code,
         cdgrp TYPE ztcma00080-cdgrp,
         cdval TYPE ztcma00080-cdval,
         cdnam TYPE ztcma00080-cdnam,
         cddsc TYPE ztcma00080-cddsc,
       END OF ty_ai_code.

DATA: gt_ai_material TYPE STANDARD TABLE OF ty_ai_material,
      gt_ai_code     TYPE STANDARD TABLE OF ty_ai_code.

*----------------------------------------------------------------------*
* AI 분석 결과 Validation
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_validation,
         status_icon TYPE icon_d,    " 오류 아이콘
         data_type   TYPE char30,    " Preview 구분
         row_no      TYPE i,         " 행 번호
         fieldname   TYPE char30,    " 오류 필드명
         message     TYPE char255,   " 오류 사유
       END OF ty_validation.

DATA: gt_validation TYPE STANDARD TABLE OF ty_validation,
      gs_validation TYPE ty_validation.

*----------------------------------------------------------------------*
* Validation ALV - Screen 0200
*----------------------------------------------------------------------*
DATA: go_val_cont TYPE REF TO cl_gui_custom_container,
      go_val_grid TYPE REF TO cl_gui_alv_grid.

DATA: gt_val_fcat TYPE lvc_t_fcat,
      gs_val_layo TYPE lvc_s_layo.

*----------------------------------------------------------------------*
* Table Control Toolbar
*----------------------------------------------------------------------*
DATA: go_plan_tcont  TYPE REF TO cl_gui_custom_container,
      go_event_tcont TYPE REF TO cl_gui_custom_container.

DATA: go_plan_toolbar  TYPE REF TO cl_gui_toolbar,
      go_event_toolbar TYPE REF TO cl_gui_toolbar.
