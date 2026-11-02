*&---------------------------------------------------------------------*
*& Include          ZLSDA00040_TOP
*&---------------------------------------------------------------------*

TYPE-POOLS: icon.

TABLES:
  ztsda00010,
  ztsda00020,
  ztsda00030,
  ztsda00040,
  ztsda00050,
  ztsda00060,
  ztcma00050.


*---------------------------------------------------------------------*
* Local Class
*---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION DEFERRED.


*---------------------------------------------------------------------*
* OK Code
*---------------------------------------------------------------------*
DATA:
  gv_okcode TYPE sy-ucomm.


*---------------------------------------------------------------------*
* 조회조건
*---------------------------------------------------------------------*
DATA:
  gv_s_vbeln TYPE ztsda00030-vbeln,
  gv_s_kunnr TYPE ztsda00030-kunnr,
  gv_s_acgfr TYPE ztsda00030-acgdt,
  gv_s_acgto TYPE ztsda00030-acgdt.

DATA:
  rb_pending TYPE c LENGTH 1 VALUE 'X',
  rb_all     TYPE c LENGTH 1.


*---------------------------------------------------------------------*
* 청구 대상 출고문서
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_target,

    sel          TYPE c LENGTH 1,
    no           TYPE i,
    status       TYPE icon_d,

    bill_status  TYPE char20,

    vbeln        TYPE ztsda00030-vbeln,
    vgbel        TYPE char30,                " 판매오더번호 (여러 건이면 '외 n건')
    kunnr        TYPE ztsda00030-kunnr,
    name1        TYPE ztcma00050-name1,

    acgdt        TYPE ztsda00030-acgdt,

    bill_amount  TYPE ztsda00050-totam,
    waers        TYPE ztsda00050-waers,

    result_text  TYPE char100,

    ready_yn     TYPE c LENGTH 1,

  END OF ty_target.


DATA:
  gt_target TYPE STANDARD TABLE OF ty_target,
  gs_target TYPE ty_target.


*---------------------------------------------------------------------*
* 청구문서 정보
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_bill,

    sel          TYPE c LENGTH 1,          " [추가] 선택 (AR 생성 / 청구 취소)
    no           TYPE i,
    status       TYPE icon_d,

    bill_status  TYPE char20,

    bilno        TYPE ztsda00050-bilno,
    vleln        TYPE ztsda00060-vleln,      " 출고문서번호
    vgbel        TYPE char30,                " 판매오더번호
    kunnr        TYPE ztsda00050-kunnr,
    name1        TYPE ztcma00050-name1,

    bildt        TYPE ztsda00050-bildt,

    netam        TYPE ztsda00050-netam,
    taxam        TYPE ztsda00050-taxam,
    totam        TYPE ztsda00050-totam,
    waers        TYPE ztsda00050-waers,

    bilst        TYPE ztsda00050-bilst,
    aryno        TYPE ztsda00050-aryno,

    row_color    TYPE c LENGTH 4,          " [추가] 방금 생성한 청구 강조

  END OF ty_bill.


DATA:
  gt_bill TYPE STANDARD TABLE OF ty_bill,
  gs_bill TYPE ty_bill.


*---------------------------------------------------------------------*
* 상단 ALV
*---------------------------------------------------------------------*
DATA:
  go_target_container TYPE REF TO cl_gui_custom_container,
  go_target_grid      TYPE REF TO cl_gui_alv_grid,

  gt_target_fcat      TYPE lvc_t_fcat,
  gs_target_fcat      TYPE lvc_s_fcat,

  gs_target_layout    TYPE lvc_s_layo.


*---------------------------------------------------------------------*
* 하단 ALV
*---------------------------------------------------------------------*
DATA:
  go_bill_container TYPE REF TO cl_gui_custom_container,
  go_bill_grid      TYPE REF TO cl_gui_alv_grid,

  gt_bill_fcat      TYPE lvc_t_fcat,
  gs_bill_fcat      TYPE lvc_s_fcat,

  gs_bill_layout    TYPE lvc_s_layo.


*---------------------------------------------------------------------*
* Event Handler
*---------------------------------------------------------------------*
DATA:
  go_event_handler TYPE REF TO lcl_event_handler.



************************************************************************
* [추가] 공용 Type / 변수
************************************************************************

*---------------------------------------------------------------------*
* 고객명 조회용 (ZTCMA00050 키가 KUNNR + ADRCDE라 고객번호별 1건)
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_cust,
    kunnr TYPE ztcma00050-kunnr,
    name1 TYPE ztcma00050-name1,
  END OF ty_cust,

  tt_cust TYPE SORTED TABLE OF ty_cust WITH UNIQUE KEY kunnr.


*---------------------------------------------------------------------*
* 연결 SO 번호 목록
*---------------------------------------------------------------------*
TYPES:
  tt_vgbel TYPE STANDARD TABLE OF ztsda00040-vgbel WITH DEFAULT KEY.


*---------------------------------------------------------------------*
* 방금 생성한 청구문서 (하단 노란색 강조)
*---------------------------------------------------------------------*
DATA:
  gt_new_bill TYPE STANDARD TABLE OF ztsda00050-bilno WITH DEFAULT KEY.


*---------------------------------------------------------------------*
* 하단 ALV 조회모드 (A = 전체 / P = AR 미생성)
*---------------------------------------------------------------------*
DATA:
  gv_bill_mode TYPE c LENGTH 1 VALUE 'A'.


*---------------------------------------------------------------------*
* ALV 표준 편집 버튼 숨김
*---------------------------------------------------------------------*
DATA:
  gt_exclude TYPE ui_functions.
