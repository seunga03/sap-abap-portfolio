*&---------------------------------------------------------------------*
*& Include          ZLSDA00010_TOP
*&---------------------------------------------------------------------*

TYPE-POOLS:
  icon,
  ole2.


*---------------------------------------------------------------------*
* TABLES
*---------------------------------------------------------------------*
TABLES:
  sscrfields,

  ztsda00010,
  ztsda00020,

  ztcma00020,
  ztcma00040,
  ztcma00050,
  ztcma00060,

  ztcma00140,
  ztcma00150,

  ztmma00070.


*---------------------------------------------------------------------*
* Local Class
*---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION DEFERRED.


*---------------------------------------------------------------------*
* OK CODE
*---------------------------------------------------------------------*
DATA:
  gv_okcode TYPE sy-ucomm.


*---------------------------------------------------------------------*
* Selection Screen Function Code
*---------------------------------------------------------------------*
CONSTANTS:
  gc_ucomm_refresh  TYPE sy-ucomm VALUE 'FC01',
  gc_ucomm_template TYPE sy-ucomm VALUE 'FC02',
  gc_ucomm_result   TYPE sy-ucomm VALUE 'FC03',
  gc_ucomm_so       TYPE sy-ucomm VALUE 'FC04'.

*---------------------------------------------------------------------*
* 주문 검증결과 ABAP Memory
*---------------------------------------------------------------------*
CONSTANTS:
  gc_mem_valid TYPE char30 VALUE 'ZSD01_VALID_RESULT'.


*---------------------------------------------------------------------*
* [추가] 방금 생성한 판매오더 ABAP Memory
* CALL TRANSACTION으로 다른 화면(SD02~04)에 갔다 와도 유지됨
*---------------------------------------------------------------------*
CONSTANTS:
  gc_mem_new_so TYPE char30 VALUE 'ZSD01_NEW_SO'.

DATA:
  gt_new_so TYPE STANDARD TABLE OF ztsda00010-vbeln WITH DEFAULT KEY.


*---------------------------------------------------------------------*
* SO 생성 완료 여부
*---------------------------------------------------------------------*
DATA:
  gv_so_created TYPE abap_bool.


*---------------------------------------------------------------------*
* Excel Raw Data
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_excel_raw,

    row_no TYPE i,

    kunnr  TYPE ztsda00010-kunnr,
    name1  TYPE ztcma00050-name1,

    matnr  TYPE ztsda00020-matnr,
    maktx  TYPE ztcma00020-maktx,

    kwmeng TYPE ztsda00020-kwmeng,
    meins  TYPE ztsda00020-meins,

    reqdt  TYPE ztsda00020-reqdt,
    waers  TYPE ztsda00010-waers,

  END OF ty_excel_raw.


DATA:
  gs_excel_raw TYPE ty_excel_raw,
  gt_excel_raw TYPE STANDARD TABLE OF ty_excel_raw.



************************************************************************
* Screen 0100 - 주문 검증 결과
************************************************************************

*---------------------------------------------------------------------*
* 검증결과 Type
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_valid_result,

*---------------------------------------------------------------------*
* 상태
*---------------------------------------------------------------------*
    status       TYPE icon_d,
    row_color    TYPE char4,
    cell_color   TYPE lvc_t_scol,
    row_no       TYPE i,

    basic_ok     TYPE char1,
    order_ok     TYPE char1,
    created_yn   TYPE char1,

*---------------------------------------------------------------------*
* 고객 / 판매정보
*---------------------------------------------------------------------*
    kunnr        TYPE ztsda00010-kunnr,
    name1        TYPE ztcma00050-name1,

    vkorg        TYPE ztsda00010-vkorg,
    vtweg        TYPE ztsda00010-vtweg,

*---------------------------------------------------------------------*
* Item 정보
*---------------------------------------------------------------------*
    matnr        TYPE ztsda00020-matnr,
    maktx        TYPE ztcma00020-maktx,

    werks        TYPE ztsda00020-werks,
    lgort        TYPE ztsda00020-lgort,

    kwmeng       TYPE ztsda00020-kwmeng,
    meins        TYPE ztsda00020-meins,

    reqdt        TYPE ztsda00020-reqdt,

*---------------------------------------------------------------------*
* 재고 / 조달
*---------------------------------------------------------------------*
    stqty        TYPE ztmma00070-stqty,
    rsqty        TYPE ztmma00070-rsqty,

    avqty        TYPE ztmma00070-stqty,
    shiqty       TYPE ztmma00070-stqty,

    lifnr        TYPE ztcma00040-lifnr,
    plifz        TYPE ztcma00040-plifz,

    expdt        TYPE sy-datum,

    procure_need TYPE char1,

*---------------------------------------------------------------------*
* 판매조건 / 금액
*---------------------------------------------------------------------*
    netpr        TYPE ztsda00020-netpr,
    disrt        TYPE ztsda00020-disrt,
    disam        TYPE ztsda00020-disam,

    netam        TYPE ztsda00020-netam,

    taxrt        TYPE ztsda00020-taxrt,
    taxam        TYPE ztsda00020-taxam,

    totam        TYPE ztsda00020-totam,

    waers        TYPE ztsda00010-waers,

*---------------------------------------------------------------------*
* 검증 메시지
*---------------------------------------------------------------------*
    error_field  TYPE char50,
    result_text  TYPE char200,

*---------------------------------------------------------------------*
* 기생성 SO 경고 (동일 주문이 이미 있어도 생성은 허용)
*---------------------------------------------------------------------*
    dup_vbeln    TYPE ztsda00010-vbeln,

  END OF ty_valid_result.


DATA:
  gs_valid_result TYPE ty_valid_result,
  gt_valid_result TYPE STANDARD TABLE OF ty_valid_result.


*---------------------------------------------------------------------*
* 검증 건수
*---------------------------------------------------------------------*
DATA:
  gv_total_cnt   TYPE i,
  gv_success_cnt TYPE i,
  gv_procure_cnt TYPE i,
  gv_error_cnt   TYPE i.


*---------------------------------------------------------------------*
* 검증결과 ALV
*---------------------------------------------------------------------*
DATA:
  go_valid_container TYPE REF TO cl_gui_custom_container,
  go_valid_grid      TYPE REF TO cl_gui_alv_grid.

DATA:
  gt_valid_fcat TYPE lvc_t_fcat,
  gs_valid_fcat TYPE lvc_s_fcat,
  gs_valid_layo TYPE lvc_s_layo.



************************************************************************
* Screen 0200 - 판매오더 관리
************************************************************************

*---------------------------------------------------------------------*
* 조회조건
*---------------------------------------------------------------------*
DATA:
  gv_so_vbeln    TYPE ztsda00010-vbeln,
  gv_so_kunnr    TYPE ztsda00010-kunnr,
  gv_so_audat_fr TYPE ztsda00010-audat,
  gv_so_audat_to TYPE ztsda00010-audat.

*---------------------------------------------------------------------*
* 조회 여부 (X: [검색]을 누른 상태 / 공백: 방금 생성한 오더만 표시)
*---------------------------------------------------------------------*
DATA:
  gv_so_searched TYPE abap_bool.


*---------------------------------------------------------------------*
* 판매오더 Header Type
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_so_list,

    no        TYPE i,

    vbeln     TYPE ztsda00010-vbeln,
    sosta_t   TYPE char20,
    kunnr     TYPE ztsda00010-kunnr,
    name1     TYPE ztcma00050-name1,

    audat     TYPE ztsda00010-audat,

    itm_cnt   TYPE i,
    reqdt     TYPE ztsda00020-reqdt,
    proc_t    TYPE char20,
    plifz     TYPE ztcma00040-plifz,

    waers     TYPE ztsda00010-waers,
    totam     TYPE ztsda00010-totam,

*---------------------------------------------------------------------*
* [추가] 정렬 / 강조용 (화면에는 표시하지 않음)
*---------------------------------------------------------------------*
    erdat     TYPE ztsda00010-erdat,
    erzet     TYPE ztsda00010-erzet,
    row_color TYPE char4,

  END OF ty_so_list.


DATA:
  gs_so_list TYPE ty_so_list,
  gt_so_list TYPE STANDARD TABLE OF ty_so_list.


*---------------------------------------------------------------------*
* 판매오더 Header ALV
*---------------------------------------------------------------------*
DATA:
  go_so_container TYPE REF TO cl_gui_custom_container,
  go_so_grid      TYPE REF TO cl_gui_alv_grid.

DATA:
  gt_so_fcat TYPE lvc_t_fcat,
  gs_so_fcat TYPE lvc_s_fcat,
  gs_so_layo TYPE lvc_s_layo.


*---------------------------------------------------------------------*
* 판매오더 Item Type
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_so_detail,

    kunnr  TYPE ztsda00010-kunnr,
    name1  TYPE ztcma00050-name1,

    posnr  TYPE ztsda00020-posnr,

    matnr  TYPE ztsda00020-matnr,
    maktx  TYPE ztcma00020-maktx,

    werks  TYPE ztsda00020-werks,
    lgort  TYPE ztsda00020-lgort,

    kwmeng TYPE ztsda00020-kwmeng,
    meins  TYPE ztsda00020-meins,

    reqdt  TYPE ztsda00020-reqdt,
    itmst  TYPE ztsda00020-itmst,

    netpr  TYPE ztsda00020-netpr,
    disrt  TYPE ztsda00020-disrt,
    disam  TYPE ztsda00020-disam,

    netam  TYPE ztsda00020-netam,

    taxrt  TYPE ztsda00020-taxrt,
    taxam  TYPE ztsda00020-taxam,

    totam  TYPE ztsda00020-totam,
    waers  TYPE ztsda00010-waers,
    cell_color TYPE lvc_t_scol,

  END OF ty_so_detail.


DATA:
  gs_so_detail TYPE ty_so_detail,
  gt_so_detail TYPE STANDARD TABLE OF ty_so_detail.


*---------------------------------------------------------------------*
* 판매오더 Item ALV
*---------------------------------------------------------------------*
DATA:
  go_so_detail_container TYPE REF TO cl_gui_custom_container,
  go_so_detail_grid      TYPE REF TO cl_gui_alv_grid.

DATA:
  gt_so_detail_fcat TYPE lvc_t_fcat,
  gs_so_detail_fcat TYPE lvc_s_fcat,
  gs_so_detail_layo TYPE lvc_s_layo.


*---------------------------------------------------------------------*
* ALV Event Handler
*---------------------------------------------------------------------*
DATA:
  go_event_handler TYPE REF TO lcl_event_handler.


DATA: go_kpi_cc TYPE REF TO cl_gui_custom_container,
      go_kpi    TYPE REF TO zcl_cm_kpi_html.


*---------------------------------------------------------------------*
* ALV 표준 툴바 숨김 (SD02~04와 동일)
*---------------------------------------------------------------------*
DATA:
  gt_exclude TYPE ui_functions.


************************************************************************
* 판매오더 상세 팝업 (Screen 0300)
* Custom Control : CC_SO_POP
************************************************************************
DATA:
  gv_so_vbeln_pop     TYPE ztsda00010-vbeln,
  gt_so_pop           TYPE STANDARD TABLE OF ty_so_detail,
  go_so_pop_container TYPE REF TO cl_gui_custom_container,
  go_so_pop_grid      TYPE REF TO cl_gui_alv_grid,
  gs_so_pop_layo      TYPE lvc_s_layo.


*---------------------------------------------------------------------*
* 주문등록 화면 - 자재 변경 감지용 (글자 표시 변수는 SCR의 COMMENT가 자동 선언)
*---------------------------------------------------------------------*
DATA:
  gv_last_matnr TYPE ztsda00020-matnr.
