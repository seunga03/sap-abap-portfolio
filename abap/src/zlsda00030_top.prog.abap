"& Include          ZLSDA00030_TOP
"&---------------------------------------------------------------------*


"---------------------------------------------------------------------*
" Type Pool
"---------------------------------------------------------------------*
TYPE-POOLS: icon.


"---------------------------------------------------------------------*
" TABLES
"---------------------------------------------------------------------*
TABLES:
  ztsda00010,        " 판매오더 Header
  ztsda00020,        " 판매오더 Item
  ztsda00030,        " 출고문서 Header
  ztsda00040,        " 출고문서 Item
  ztcma00050,        " 고객 Master
  ztmma00070.        " 재고


"---------------------------------------------------------------------*
" Local Class
"---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION DEFERRED.


"---------------------------------------------------------------------*
" OK Code
"---------------------------------------------------------------------*
DATA:
  gv_okcode TYPE sy-ucomm.


"***********************************************************************
" 조회 조건
"***********************************************************************
DATA:
  gv_s_vbeln TYPE ztsda00030-vbeln,   " 출고문서번호
  gv_s_kunnr TYPE ztsda00030-kunnr,   " 고객번호
  gv_s_tdfr  TYPE ztsda00030-tddat,   " 출하예정일 From
  gv_s_tdto  TYPE ztsda00030-tddat.   " 출하예정일 To


"---------------------------------------------------------------------*
" 조회 범위
"---------------------------------------------------------------------*
DATA:
  rb_pending TYPE c LENGTH 1 VALUE 'X',   " 미출하만
  rb_all     TYPE c LENGTH 1.             " 전체


"***********************************************************************
" 상단 ALV - 출하 대상 출고문서
"***********************************************************************
TYPES:
  BEGIN OF ty_ship,

    sel         TYPE char1,                 " 선택
    no          TYPE i,                     " No
    status      TYPE icon_d,                " 상태 Icon

    vbeln       TYPE ztsda00030-vbeln,      " 출고문서번호
    so_vbeln    TYPE ztsda00010-vbeln,      " 원본 판매오더번호 (SD02와 동일)
    kunnr       TYPE ztsda00030-kunnr,      " 고객번호
    name1       TYPE ztcma00050-name1,      " 고객명

    vstel       TYPE ztsda00030-vstel,      " 출하지점
    tddat       TYPE ztsda00030-tddat,      " 출하예정일

    dlvst       TYPE ztsda00030-dlvst,      " 출고문서상태 - 내부값
    gista       TYPE ztsda00030-gista,      " 출하상태 - 내부값

    ship_status TYPE char20,                " 사용자 표시용 출하상태

    ready_yn    TYPE char1,                 " 처리 가능 여부 - 내부값
    result_text TYPE char100,               " 판정내용

    erdat       TYPE ztsda00030-erdat,      " 생성일 (최신순 정렬용)
    erzet       TYPE ztsda00030-erzet,      " 생성시간 (최신순 정렬용)
    row_color   TYPE c LENGTH 4,            " 행 강조색 (방금 생성된 문서)

  END OF ty_ship.


DATA:
  gs_ship TYPE ty_ship,
  gt_ship TYPE STANDARD TABLE OF ty_ship.


"---------------------------------------------------------------------*
" 상단 ALV Object
"---------------------------------------------------------------------*
DATA:
  go_ship_container TYPE REF TO cl_gui_custom_container,
  go_ship_grid      TYPE REF TO cl_gui_alv_grid,

  gt_ship_fcat      TYPE lvc_t_fcat,
  gs_ship_fcat      TYPE lvc_s_fcat,
  gs_ship_layo      TYPE lvc_s_layo.


"***********************************************************************
" 하단 ALV - 출하 완료 내역
"***********************************************************************
TYPES:
  BEGIN OF ty_hist,

    sel         TYPE char1,                 " [추가] 선택 (출하 취소용)
    no          TYPE i,
    status      TYPE icon_d,                " [추가] 상태 Icon

    vbeln       TYPE ztsda00030-vbeln,
    so_vbeln    TYPE ztsda00010-vbeln,      " 원본 판매오더번호 (상단 ALV와 동일)
    kunnr       TYPE ztsda00030-kunnr,
    name1       TYPE ztcma00050-name1,

    vstel       TYPE ztsda00030-vstel,
    tddat       TYPE ztsda00030-tddat,

    gista       TYPE ztsda00030-gista,      " 내부값
    ship_status TYPE char20,                " 사용자 표시용

    acgdt       TYPE ztsda00030-acgdt,      " 실제출하일

    row_color   TYPE c LENGTH 4,            " [추가] 방금 출하한 문서 강조

  END OF ty_hist.


DATA:
  gs_hist TYPE ty_hist,
  gt_hist TYPE STANDARD TABLE OF ty_hist.


"---------------------------------------------------------------------*
" 하단 ALV Object
"---------------------------------------------------------------------*
DATA:
  go_hist_container TYPE REF TO cl_gui_custom_container,
  go_hist_grid      TYPE REF TO cl_gui_alv_grid,

  gt_hist_fcat      TYPE lvc_t_fcat,
  gs_hist_fcat      TYPE lvc_s_fcat,
  gs_hist_layo      TYPE lvc_s_layo.


"***********************************************************************
" Event Handler
"***********************************************************************
DATA:
  go_event_handler TYPE REF TO lcl_event_handler.



"***********************************************************************
" [추가] 공용 Type / 변수
"***********************************************************************

"---------------------------------------------------------------------*
" 고객명 조회용 (ZTCMA00050 키가 KUNNR + ADRCDE라 고객번호별 1건)
"---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_cust,
    kunnr TYPE ztcma00050-kunnr,
    name1 TYPE ztcma00050-name1,
  END OF ty_cust,

  tt_cust TYPE SORTED TABLE OF ty_cust WITH UNIQUE KEY kunnr.


"---------------------------------------------------------------------*
" 자재/플랜트/저장위치별 출고수량 집계용
"---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_stock_req,
    matnr TYPE ztsda00040-matnr,
    werks TYPE ztsda00040-werks,
    lgort TYPE ztsda00040-lgort,
    reqty TYPE ztsda00040-lfimg,
  END OF ty_stock_req.


"---------------------------------------------------------------------*
" 연결 SO 번호 목록
"---------------------------------------------------------------------*
TYPES:
  tt_vgbel TYPE STANDARD TABLE OF ztsda00040-vgbel WITH DEFAULT KEY.


"---------------------------------------------------------------------*
" 방금 출하 처리한 출고문서 (하단 노란색 강조)
"---------------------------------------------------------------------*
DATA:
  gt_new_gi TYPE STANDARD TABLE OF ztsda00030-vbeln WITH DEFAULT KEY.


"---------------------------------------------------------------------*
" SD02에서 방금 생성한 출고문서번호 (SAP 메모리로 전달받음)
" → 상단 출하 대상 ALV에서 노란색 + 맨 위로 표시
"---------------------------------------------------------------------*
DATA:
  gt_new_dl TYPE STANDARD TABLE OF ztsda00030-vbeln WITH DEFAULT KEY.


"---------------------------------------------------------------------*
" ALV 표준 편집 버튼 숨김
"---------------------------------------------------------------------*
DATA:
  gt_exclude TYPE ui_functions.

"&---------------------------------------------------------------------*
