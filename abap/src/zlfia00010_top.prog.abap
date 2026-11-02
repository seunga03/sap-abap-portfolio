*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_TOP
*&---------------------------------------------------------------------*
REPORT zlfia00010.

TABLES: ztfia00050, sscrfields.

CONSTANTS: gc_clsta_open TYPE ztcma00110-clsta VALUE '0010',   " 미지급
           gc_clsta_part TYPE ztcma00110-clsta VALUE '0020',   " 부분지급
           gc_clsta_done TYPE ztcma00110-clsta VALUE '0030'.   " 지급완료

*--- 위: 지급 내역 (지급번호 1건 = 통장 이체 1건)
DATA: BEGIN OF gw_head.
        INCLUDE TYPE zsfia00010.          " PAYNR LIFNR NAME1 PAYDT PAYAM WAERS PAYAC
DATA:   banka TYPE ztfia00070-banka,      " 은행
        bankn TYPE ztfia00070-bankn,      " 계좌번호
        apcnt TYPE i,                     " 채무 건수
      END OF gw_head.
DATA gt_head LIKE TABLE OF gw_head.

*--- 아래: 더블클릭한 지급의 반제 내역
DATA: BEGIN OF gw_item.
        INCLUDE TYPE zsfia00011.          " PAYNR APNUM DMBTR APCAM OPENBAL(현재 잔액) CLSTA WAERS
DATA:   apcnr  TYPE ztfia00030-apcnr,     " 반제번호
        apcsq  TYPE ztfia00030-apcsq,     " 순번
        ivnum  TYPE ztcma00110-ivnum,     " 송장번호
        befbal TYPE ztcma00110-dmbtr,     " 지급 전 잔액 (그 당시)
        aftbal TYPE ztcma00110-dmbtr,     " 지급 후 잔액 (그 당시)
        sttxt  TYPE c LENGTH 10,          " 현재 상태 (미지급/부분지급/지급완료)
      END OF gw_item.
DATA gt_item LIKE TABLE OF gw_item.

*--- ALV
DATA: go_cont   TYPE REF TO cl_gui_custom_container,
      go_split  TYPE REF TO cl_gui_splitter_container,
      go_top    TYPE REF TO cl_gui_container,
      go_bottom TYPE REF TO cl_gui_container,
      go_alv1   TYPE REF TO cl_gui_alv_grid,
      go_alv2   TYPE REF TO cl_gui_alv_grid.

DATA: gt_fcat1   TYPE lvc_t_fcat,
      gt_fcat2   TYPE lvc_t_fcat,
      gs_layout1 TYPE lvc_s_layo,
      gs_layout2 TYPE lvc_s_layo,
      gt_sort1   TYPE lvc_t_sort.

DATA: ok_code   TYPE sy-ucomm,
      gv_ucomm  TYPE sy-ucomm,
      gv_recent TYPE c LENGTH 1.          " X = 조건 없이 최근 10건
