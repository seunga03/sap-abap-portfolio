*&---------------------------------------------------------------------*
*& Include          ZRFIA00010_TOP
*&---------------------------------------------------------------------*

TABLES: sscrfields.

TYPES: BEGIN OF ty_list,
         sel      TYPE c LENGTH 1,     " 체크박스
         pr_icon  TYPE icon_d,         " 출력상태
         dctyp    TYPE c LENGTH 2,     " AP / AR
         clrnr    TYPE c LENGTH 10,    " 반제번호
         clrsq    TYPE n LENGTH 3,     " 순번
         orgnr    TYPE c LENGTH 10,    " 원천번호 (AP/AR번호)
         partn    TYPE c LENGTH 10,    " 거래처
         partn_nm TYPE name1_gp,       " 거래처명
         dmbtr    TYPE wrbtr,          " 원금액
         clram    TYPE wrbtr,          " 반제액
         openam   TYPE wrbtr,          " 잔액
         cumam    TYPE wrbtr,          " 반제누계 (헤더 기준: 지급/수금 + 조정)
         clrdt    TYPE datum,          " 반제일
         waers    TYPE waers,
         rsn_nm   TYPE c LENGTH 20,    " 반제사유
         paynr    TYPE c LENGTH 10,    " 지급/수금번호
         stat_nm  TYPE c LENGTH 10,    " 상태
         pr_cnt   TYPE i,              " 출력횟수
         rowcolor TYPE c LENGTH 4,
       END OF ty_list.

TYPES: BEGIN OF ty_hist,
         prnum TYPE c LENGTH 10,       " 출력번호
         dctyp TYPE c LENGTH 10,       " 문서유형
         dcnum TYPE c LENGTH 10,       " 반제번호
         fmtyp TYPE c LENGTH 12,       " 서류종류
         prtms TYPE c LENGTH 16,       " 출력일시
         uname TYPE syuname,           " 출력자
       END OF ty_hist.

TYPES: tt_clrnr TYPE STANDARD TABLE OF ty_list-clrnr WITH EMPTY KEY.

DATA: gt_list TYPE STANDARD TABLE OF ty_list,
      gt_hist TYPE STANDARD TABLE OF ty_hist.

*--- 선택화면 참조용
DATA: gv_clrdt TYPE datum,
      gv_lifnr TYPE lifnr,
      gv_kunnr TYPE kunnr,
      gv_clrnr TYPE ty_list-clrnr,
      gv_orgnr TYPE ty_list-orgnr.

*--- 공통
DATA: ok_code   TYPE sy-ucomm,
      gv_okcode TYPE sy-ucomm,
      gt_excl   TYPE STANDARD TABLE OF sy-ucomm.

*--- SCR 0100
CLASS lcl_event_handler DEFINITION DEFERRED.
DATA: go_cont_0100 TYPE REF TO cl_gui_custom_container,
      go_grid_0100 TYPE REF TO cl_gui_alv_grid,
      go_handler   TYPE REF TO lcl_event_handler,
      gt_fcat_0100 TYPE lvc_t_fcat.

*--- SCR 0200 (화면 필드: Get from Program → GS_0200)
DATA: gs_0200 TYPE ty_list.

*--- SCR 0300
DATA: go_cont_0300 TYPE REF TO cl_gui_custom_container,
      go_grid_0300 TYPE REF TO cl_gui_alv_grid,
      gt_fcat_0300 TYPE lvc_t_fcat.

*--- SCR 0200 금액 표시용 (통화 반영 문자 필드)
DATA: gv_dmbtr_c  TYPE char20,
      gv_clram_c  TYPE char20,
      gv_openam_c TYPE char20.

DATA gv_dtl_open TYPE abap_bool.          " 상세조건 펼침 여부

*--- KPI 패널
DATA: go_cont_kpi  TYPE REF TO cl_gui_custom_container,
      go_kpi       TYPE REF TO zcl_cm_kpi_html,
      gv_kpi_dirty TYPE abap_bool.
