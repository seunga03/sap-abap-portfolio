*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_TOP
*&---------------------------------------------------------------------*

REPORT zlmma00010_1 MESSAGE-ID zmsga.

TABLES: ztmma00021, ztmma00070, ztcma00030,
        ztmma00050, ztmma00060, ztmma00080, ztmma00090.

*----------------------------------------------------------------------*
* Global Data
*----------------------------------------------------------------------*
DATA: ok_code TYPE sy-ucomm.

DATA: go_cont TYPE REF TO cl_gui_custom_container,
      go_grid TYPE REF TO cl_gui_alv_grid.

DATA: gt_fcat     TYPE lvc_t_fcat,
      gs_fcat     TYPE lvc_s_fcat,
      gs_layo     TYPE lvc_s_layo,
      gv_fcat_pos TYPE lvc_s_fcat-col_pos.

*----------------------------------------------------------------------*
* Shortage Result
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_shortage,
         srtno     TYPE ztmma00030-srtno,

         fcsno     TYPE ztmma00021-fcsno,
         matnr     TYPE ztmma00021-matnr,
         maktx     TYPE ztcma00020-maktx,
         werks     TYPE ztmma00070-werks,
         meins     TYPE ztmma00021-meins,

         pstat     TYPE ztmma00030-pstat,
         banfn     TYPE ztmma00030-banfn,

         reqty     TYPE ztmma00021-final_reqty,

         stqty     TYPE ztmma00070-stqty,
         rsqty     TYPE ztmma00070-rsqty,
         qisty     TYPE ztmma00070-qisty,

         inqty     TYPE ztmma00060-menge,

         eisbe     TYPE ztcma00030-eisbe,
         beskz     TYPE ztcma00030-beskz,
         plifz     TYPE ztcma00030-plifz,
         bstmi     TYPE ztcma00030-bstmi,

         avqty     TYPE ztmma00021-final_reqty,
         shiqty    TYPE ztmma00021-final_reqty,

         open_pr_qty TYPE ztmma00040-rqty,

         pr_target TYPE abap_bool,
         pr_status TYPE char10,
       END OF ty_shortage.

DATA: gt_shortage TYPE STANDARD TABLE OF ty_shortage,
      gs_shortage TYPE ty_shortage.

""" BOM 전개 후 신규 저장할 자재소요 상세
DATA gt_req_new TYPE STANDARD TABLE OF ztmma00021.

""" 전체 실행 성공 여부
DATA gv_run_ok TYPE abap_bool.

*----------------------------------------------------------------------*
* 지급자재 계산 결과
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_component,
         banfn     TYPE ztmma00040-banfn,
         bnfpo     TYPE ztmma00040-bnfpo,
         fg_matnr  TYPE ztmma00040-matnr,
         fg_werks  TYPE ztmma00040-werks,
         stlnr     TYPE ztcma00120-stlnr,
         stlkn     TYPE ztcma00130-stlkn,
         matnr     TYPE ztcma00130-idnrk,
         werks     TYPE ztcma00030-werks,
         reqty     TYPE ztmma00030-reqty,
         meins     TYPE ztcma00130-meins,

         stqty  TYPE ztmma00070-stqty,
         rsqty  TYPE ztmma00070-rsqty,
         qisty  TYPE ztmma00070-qisty,
         inqty  TYPE ztmma00060-menge,
         eisbe  TYPE ztcma00030-eisbe,
         avqty  TYPE ztmma00030-avqty,
         shiqty TYPE ztmma00030-shiqty,
       END OF ty_component.

DATA gt_component TYPE STANDARD TABLE OF ty_component.


*----------------------------------------------------------------------*
*& 지급자재별 통합 소요량
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_comp_total,
         matnr       TYPE ztcma00130-idnrk,
         werks       TYPE ztcma00030-werks,
         meins       TYPE ztcma00130-meins,
         reqty       TYPE ztmma00030-reqty,
         stqty       TYPE ztmma00070-stqty,
         rsqty       TYPE ztmma00070-rsqty,
         qisty       TYPE ztmma00070-qisty,
         inqty       TYPE ztmma00060-menge,
         eisbe       TYPE ztcma00030-eisbe,
         avqty       TYPE ztmma00030-avqty,
         shiqty      TYPE ztmma00030-shiqty,
         open_pr_qty TYPE ztmma00040-rqty,
       END OF ty_comp_total.

DATA gt_comp_total TYPE SORTED TABLE OF ty_comp_total
                   WITH UNIQUE KEY matnr werks meins.

*----------------------------------------------------------------------*
*& 지급자재 부족량 저장 데이터 구성
*----------------------------------------------------------------------*
DATA: gt_comp_short_save TYPE STANDARD TABLE OF ztmma00030,
      gt_comp_source_save TYPE STANDARD TABLE OF ztmma00031.

* 아직 ZTMMA00031에 저장되지 않은 신규 출처
DATA gt_comp_new TYPE STANDARD TABLE OF ty_component.

*----------------------------------------------------------------------*
* 메인 화면 탭 관리
*----------------------------------------------------------------------*
CONTROLS tab_main TYPE TABSTRIP.

DATA: gv_dynnr TYPE sy-dynnr VALUE '0110'.

*----------------------------------------------------------------------*
* PR 생성 처리 상태
*----------------------------------------------------------------------*
DATA: gv_preview_ready TYPE abap_bool,
      gv_pr_confirmed  TYPE abap_bool.

*----------------------------------------------------------------------*
* PR 생성 예정/결과
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_pr_preview,
         mark       TYPE abap_bool,
         reqtyp     TYPE ztmma00030-reqtyp,
         srtno      TYPE ztmma00030-srtno,
         fcsno      TYPE ztmma00030-fcsno,
         matnr      TYPE ztmma00030-matnr,
         maktx      TYPE ztcma00020-maktx,
         werks      TYPE ztmma00030-werks,
         meins      TYPE ztmma00030-meins,
         reqty      TYPE ztmma00030-reqty,
         shiqty     TYPE ztmma00030-shiqty,
         ptype      TYPE ztmma00040-ptype,
         banfn      TYPE ztmma00040-banfn,
         bnfpo      TYPE ztmma00040-bnfpo,
         result     TYPE char20,
       END OF ty_pr_preview.

DATA: gt_pr_preview TYPE STANDARD TABLE OF ty_pr_preview,
      gs_pr_preview TYPE ty_pr_preview.

*----------------------------------------------------------------------*
* KPI HTML
*----------------------------------------------------------------------*
DATA: go_kpi_cont TYPE REF TO cl_gui_custom_container,
      go_kpi      TYPE REF TO zcl_cm_kpi_html.

*----------------------------------------------------------------------*
* 지급자재 ALV
*----------------------------------------------------------------------*
DATA: go_comp_cont TYPE REF TO cl_gui_custom_container,
      go_comp_grid TYPE REF TO cl_gui_alv_grid.

DATA: gt_comp_display TYPE STANDARD TABLE OF ty_comp_total,
      gt_comp_fcat    TYPE lvc_t_fcat,
      gs_comp_layo    TYPE lvc_s_layo.

*----------------------------------------------------------------------*
* 지급자재 사전 Preview
*----------------------------------------------------------------------*
DATA gt_comp_preview TYPE SORTED TABLE OF ty_comp_total
                     WITH UNIQUE KEY matnr werks meins.

*----------------------------------------------------------------------*
* 0130 PR 생성 예정/결과 ALV
*----------------------------------------------------------------------*
DATA: go_pr_cont TYPE REF TO cl_gui_custom_container,
      go_pr_grid TYPE REF TO cl_gui_alv_grid.

DATA: gt_pr_fcat TYPE lvc_t_fcat,
      gs_pr_layo TYPE lvc_s_layo.

*----------------------------------------------------------------------*
* PR 생성 대상 선택
*----------------------------------------------------------------------*
DATA: gt_pr_selected TYPE STANDARD TABLE OF ty_pr_preview,
      gv_selected_cnt TYPE i.
