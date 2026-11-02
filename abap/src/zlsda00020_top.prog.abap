"&---------------------------------------------------------------------*
"& Include          ZLSDA00020_TOP
"&---------------------------------------------------------------------*


"---------------------------------------------------------------------*
" TABLES
"---------------------------------------------------------------------*
TABLES:
  icon,

  ztsda00010,        " 판매오더 Header
  ztsda00020,        " 판매오더 Item

  ztsda00030,        " Delivery Header
  ztsda00040,        " Delivery Item

  ztcma00020,        " 자재 Master
  ztcma00050,        " 고객 Master

  ztmma00070.        " 재고 현황


"---------------------------------------------------------------------*
" Local Class
"---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION DEFERRED.


"---------------------------------------------------------------------*
" OK CODE
"---------------------------------------------------------------------*
DATA:
  gv_okcode TYPE sy-ucomm.


"***********************************************************************
" 조회 조건
"***********************************************************************
DATA:
  gv_s_vbeln TYPE ztsda00010-vbeln,   " 판매오더번호
  gv_s_kunnr TYPE ztsda00010-kunnr,   " 고객번호
  gv_s_reqfr TYPE ztsda00020-reqdt,   " 요청납기일 From
  gv_s_reqto TYPE ztsda00020-reqdt.   " 요청납기일 To


"---------------------------------------------------------------------*
" 조회 범위
"---------------------------------------------------------------------*
DATA:
  rb_target TYPE c LENGTH 1 VALUE 'X', " 출고 대상만
  rb_all    TYPE c LENGTH 1.           " 전체


"***********************************************************************
" 상단 ALV - 출고 대상 판매오더
"***********************************************************************
TYPES:
  BEGIN OF ty_so,

    sel         TYPE char1,                 " 선택
    no          TYPE i,                     " No
    status      TYPE icon_d,                " 상태

    vbeln       TYPE ztsda00010-vbeln,      " SO 번호
    kunnr       TYPE ztsda00010-kunnr,      " 고객번호
    name1       TYPE ztcma00050-name1,      " 고객명

    item_cnt    TYPE i,                     " Item 수
    reqdt       TYPE ztsda00020-reqdt,      " 대표 요청납기일

    ready_yn    TYPE char1,                 " 출고가능 여부
    ship_status TYPE char20,                " 출고가능 / 출고대기
    result_text TYPE char100,               " 판정내용

    erdat       TYPE ztsda00010-erdat,      " 생성일 (정렬용)
    erzet       TYPE ztsda00010-erzet,      " 생성시간 (정렬용)

  END OF ty_so.


DATA:
  gs_so TYPE ty_so,
  gt_so TYPE STANDARD TABLE OF ty_so.


"---------------------------------------------------------------------*
" 상단 ALV Object
" Custom Control : CC_SO
"---------------------------------------------------------------------*
DATA:
  go_so_container TYPE REF TO cl_gui_custom_container,
  go_so_grid      TYPE REF TO cl_gui_alv_grid.

DATA:
  gt_so_fcat TYPE lvc_t_fcat,
  gs_so_fcat TYPE lvc_s_fcat,
  gs_so_layo TYPE lvc_s_layo.


"***********************************************************************
" 하단 ALV - 출고문서
"***********************************************************************
TYPES:
  BEGIN OF ty_de,

    sel         TYPE char1,                  " 선택
    no          TYPE i,                      " No
    status      TYPE icon_d,                 " 상태 아이콘

    vbeln       TYPE ztsda00030-vbeln,       " 출고문서번호
    so_vbeln    TYPE ztsda00010-vbeln,       " 판매오더번호

    kunnr       TYPE ztsda00030-kunnr,       " 고객번호
    name1       TYPE ztcma00050-name1,       " 고객명

    vstel       TYPE ztsda00030-vstel,       " 출하지점
    kunwe       TYPE ztsda00030-kunwe,       " 배송처번호

    tddat       TYPE ztsda00030-tddat,       " 출하예정일

    dlvst       TYPE ztsda00030-dlvst,       " 출고문서상태
    gista       TYPE ztsda00030-gista,       " GI 상태

    ship_status TYPE char20,                 " 미출하 / 출하완료

    acgdt       TYPE ztsda00030-acgdt,       " 실제출하일
    row_color   TYPE c LENGTH 4,              " 행 강조색

  END OF ty_de.


"---------------------------------------------------------------------*
" 이번 화면에서 방금 생성된 Delivery 번호
"---------------------------------------------------------------------*
DATA:
  gt_new_delivery TYPE STANDARD TABLE OF ztsda00030-vbeln.


DATA:
  gs_de TYPE ty_de,
  gt_de TYPE STANDARD TABLE OF ty_de.


"---------------------------------------------------------------------*
" 하단 ALV Object
" Custom Control : CC_DE
"---------------------------------------------------------------------*
DATA:
  go_de_container TYPE REF TO cl_gui_custom_container,
  go_de_grid      TYPE REF TO cl_gui_alv_grid.

DATA:
  gt_de_fcat TYPE lvc_t_fcat,
  gs_de_fcat TYPE lvc_s_fcat,
  gs_de_layo TYPE lvc_s_layo.


"***********************************************************************
" Event Handler
"***********************************************************************
DATA:
  go_event_handler TYPE REF TO lcl_event_handler.


"***********************************************************************
" Screen 0200 - 출고문서 Item 상세
"***********************************************************************

"---------------------------------------------------------------------*
" 선택한 출고문서번호
"---------------------------------------------------------------------*
DATA:
  gv_de_vbeln TYPE ztsda00030-vbeln.


"---------------------------------------------------------------------*
" 출고문서 Item 상세 Type
"---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_de_item,

    vbeln TYPE ztsda00040-vbeln,   " 출고문서번호
    posnr TYPE ztsda00040-posnr,   " Delivery Item

    vgbel TYPE ztsda00040-vgbel,   " 원본 SO 번호
    posnv TYPE ztsda00040-posnv,   " 원본 SO Item

    matnr TYPE ztsda00040-matnr,   " 자재번호
    maktx TYPE ztcma00020-maktx,   " 자재명
    werks TYPE ztsda00040-werks,   " Plant
    lgort TYPE ztsda00040-lgort,   " 저장위치

    lfimg TYPE ztsda00040-lfimg,   " 출고수량
    meins TYPE ztsda00040-meins,   " 단위

  END OF ty_de_item.


"---------------------------------------------------------------------*
" 출고문서 Item 상세 Internal Table
"---------------------------------------------------------------------*
DATA:
  gs_de_item TYPE ty_de_item,
  gt_de_item TYPE STANDARD TABLE OF ty_de_item.


"---------------------------------------------------------------------*
" Screen 0200 ALV Object
" Custom Control : CC_DE_ITEM
"---------------------------------------------------------------------*
DATA:
  go_de_item_container TYPE REF TO cl_gui_custom_container,
  go_de_item_grid      TYPE REF TO cl_gui_alv_grid.


"---------------------------------------------------------------------*
" Screen 0200 Field Catalog / Layout
"---------------------------------------------------------------------*
DATA:
  gt_de_item_fcat TYPE lvc_t_fcat,
  gs_de_item_fcat TYPE lvc_s_fcat,
  gs_de_item_layo TYPE lvc_s_layo.


"***********************************************************************
" Screen 0300 - 판매오더 상세정보
"***********************************************************************

"---------------------------------------------------------------------*
" 선택한 판매오더번호
"---------------------------------------------------------------------*
DATA:
  gv_so_vbeln_detail TYPE ztsda00010-vbeln.


"---------------------------------------------------------------------*
" 판매오더 Item 상세 Type
"---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_so_item_detail,

    vbeln  TYPE ztsda00020-vbeln,
    posnr  TYPE ztsda00020-posnr,

    matnr  TYPE ztsda00020-matnr,
    werks  TYPE ztsda00020-werks,
    lgort  TYPE ztsda00020-lgort,

    kwmeng TYPE ztsda00020-kwmeng,
    meins  TYPE ztsda00020-meins,

    reqdt  TYPE ztsda00020-reqdt,

  END OF ty_so_item_detail.


"---------------------------------------------------------------------*
" 판매오더 Item 상세 Internal Table
"---------------------------------------------------------------------*
DATA:
  gs_so_item_detail TYPE ty_so_item_detail,
  gt_so_item_detail TYPE STANDARD TABLE OF ty_so_item_detail.


"---------------------------------------------------------------------*
" Screen 0300 ALV Object
" Custom Control : CC_SO_ITEM
"---------------------------------------------------------------------*
DATA:
  go_so_item_container TYPE REF TO cl_gui_custom_container,
  go_so_item_grid      TYPE REF TO cl_gui_alv_grid.


"---------------------------------------------------------------------*
" Field Catalog / Layout
"---------------------------------------------------------------------*
DATA:
  gt_so_item_fcat TYPE lvc_t_fcat,
  gs_so_item_fcat TYPE lvc_s_fcat,
  gs_so_item_layo TYPE lvc_s_layo.



"***********************************************************************
" [추가] SO Item 테이블 타입 (재고 검사 / Delivery 생성 공용)
"***********************************************************************
TYPES:
  tt_so_item TYPE STANDARD TABLE OF ztsda00020 WITH DEFAULT KEY.


"***********************************************************************
" [추가] 자재/플랜트/저장위치별 필요수량 집계용
"***********************************************************************
TYPES:
  BEGIN OF ty_stock_req,
    matnr TYPE ztsda00020-matnr,
    werks TYPE ztsda00020-werks,
    lgort TYPE ztsda00020-lgort,
    reqty TYPE ztsda00020-kwmeng,
  END OF ty_stock_req.


"***********************************************************************
" [추가] 고객명 조회용
" ZTCMA00050 키가 KUNNR + ADRCDE라서 JOIN하면 행이 중복될 수 있음
" → 고객번호별 1건으로 묶어서 사용
"***********************************************************************
TYPES:
  BEGIN OF ty_cust,
    kunnr TYPE ztcma00050-kunnr,
    name1 TYPE ztcma00050-name1,
  END OF ty_cust,

  tt_cust TYPE SORTED TABLE OF ty_cust WITH UNIQUE KEY kunnr.


"***********************************************************************
" [추가] ALV 표준 편집 버튼 숨김 (행 삽입/삭제/잘라내기 등)
"***********************************************************************
DATA:
  gt_exclude TYPE ui_functions.


"***********************************************************************
" [추가] 하단 ALV 조회모드
" A = 전체 / P = 미출하
" 수정·취소 후 보고 있던 모드 그대로 재조회하기 위해 사용
"***********************************************************************
DATA:
  gv_de_mode TYPE c LENGTH 1 VALUE 'A'.


"&---------------------------------------------------------------------*
