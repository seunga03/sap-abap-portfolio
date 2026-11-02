"&---------------------------------------------------------------------*
" ===== ZLSDA00050_3_TOP.txt =====
"& Include          ZLSDA00050_TOP
"&---------------------------------------------------------------------*
"---------------------------------------------------------------------*
" Type Pool
"---------------------------------------------------------------------*
TYPE-POOLS: icon.
"---------------------------------------------------------------------*
" TABLES
"---------------------------------------------------------------------*
TABLES:

  ztcma00050.        " 고객 Master
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
" 조회 조건 (화면 0100 상단)
"***********************************************************************
DATA:

  gv_s_kunfr TYPE ztcma00050-kunnr,     " 고객번호 From

  gv_s_kunto TYPE ztcma00050-kunnr,     " 고객번호 To

  gv_s_namfr TYPE ztcma00050-name1,     " 고객명 From (표시)

  gv_s_namto TYPE ztcma00050-name1.     " 고객명 To (표시)
"---------------------------------------------------------------------*
" 고객 상태
"---------------------------------------------------------------------*
DATA:

  rb_all  TYPE c LENGTH 1 VALUE 'X',    " 전체

  rb_norm TYPE c LENGTH 1,              " 거래 가능

  rb_blck TYPE c LENGTH 1,              " 거래 정지

  rb_clos TYPE c LENGTH 1.              " 거래 종료
"***********************************************************************
" 고객 ALV
"***********************************************************************
TYPES:

  BEGIN OF ty_cust,

    status     TYPE icon_d,                 " 상태 Icon

    kunnr      TYPE ztcma00050-kunnr,       " 고객번호

    adrcde     TYPE ztcma00050-adrcde,      " 배송처번호

    name1      TYPE ztcma00050-name1,       " 고객명

    land1      TYPE ztcma00050-land1,       " 국가

    landx      TYPE t005t-landx,            " 국가명

    addr1      TYPE ztcma00050-addr1,       " 주소

    telf1      TYPE ztcma00050-telf1,       " 전화번호

    smail      TYPE ztcma00050-smail,       " 이메일

    zterm      TYPE ztcma00050-zterm,       " 지급조건

    waers      TYPE ztcma00050-waers,       " 통화

    trdyn      TYPE ztcma00050-trdyn,       " 거래가능여부

    blkyn      TYPE ztcma00050-blkyn,       " 거래정지여부

    actyn      TYPE ztcma00050-actyn,       " 사용여부

    stat_txt   TYPE c LENGTH 10,            " 고객 상태 (거래 가능/정지/종료)

    inrsn      TYPE ztcma00050-inrsn,       " 특이사항

    erdat      TYPE ztcma00050-erdat,       " 생성일

    erzet      TYPE ztcma00050-erzet,       " 생성시간

    ernam      TYPE ztcma00050-ernam,       " 생성자

    aedat      TYPE ztcma00050-aedat,       " 변경일

    aezet      TYPE ztcma00050-aezet,       " 변경시간

    aenam      TYPE ztcma00050-aenam,       " 변경자

    line_color TYPE char4,                  " 행 색상

  END OF ty_cust.
DATA:

  gt_cust TYPE TABLE OF ty_cust,

  gs_cust TYPE ty_cust.
"---------------------------------------------------------------------*
" ALV 객체
"---------------------------------------------------------------------*
DATA:

  go_cont    TYPE REF TO cl_gui_custom_container,

  go_grid    TYPE REF TO cl_gui_alv_grid,

  go_handler TYPE REF TO lcl_event_handler.
DATA:

  gt_fcat TYPE lvc_t_fcat,

  gs_fcat TYPE lvc_s_fcat,

  gs_layo TYPE lvc_s_layo,

  gt_sort TYPE lvc_t_sort,

  gt_excl TYPE ui_functions.
"&---------------------------------------------------------------------*
