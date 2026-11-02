*&---------------------------------------------------------------------*
*& Include          ZLFIA00050_TOP
*&---------------------------------------------------------------------*
REPORT zlfia00050.

INCLUDE <icon>.

TABLES: ztcma00100.

CONSTANTS: gc_clsta_open TYPE ztcma00100-clsta VALUE '0010',   " 미수
           gc_clsta_part TYPE ztcma00100-clsta VALUE '0020',   " 부분수금
           gc_clsta_done TYPE ztcma00100-clsta VALUE '0030'.   " 수금완료

*--- 상단: 채권 목록
DATA: BEGIN OF gw_arreg.
        INCLUDE TYPE zsfia00050.          " KUNNR NAME1 ARNUM BILNO DUEDT DMBTR RCPBT OPENBAL SEL WAERS
DATA:   adjbt   TYPE ztcma00100-adjbt,    " 조정누계
        celltab TYPE lvc_t_styl,          " 잔액 0 줄 체크 잠금
        ddtxt   TYPE c LENGTH 10,         " 기한 (연체 n일 / 오늘 / D-n)
        rowcol  TYPE c LENGTH 4,          " 행 색 (C600 연체 / C700 7일 이내)
      END OF gw_arreg.
DATA gt_arreg LIKE TABLE OF gw_arreg.

*--- 하단: 수금 목록
DATA: BEGIN OF gw_rcp.
        INCLUDE TYPE zsfia00041.          " RCPNR ARNUM DMBTR ARCAM(수금액) OPENBAL(수금 후 잔액) CLSTA WAERS
DATA:   kunnr   TYPE ztcma00100-kunnr,
        name1   TYPE ztcma00050-name1,
        bilno   TYPE ztcma00100-bilno,
        balbf   TYPE ztcma00100-dmbtr,    " 수금 전 잔액
        sttxt   TYPE c LENGTH 10,         " 수금상태 (미수/부분수금/수금완료)
        stico   TYPE icon_d,              " 결과 아이콘
        msg     TYPE c LENGTH 60,         " 결과
        celltab TYPE lvc_t_styl,          " 수금 끝난 행 잠금
      END OF gw_rcp.
DATA gt_rcp LIKE TABLE OF gw_rcp.

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
      gt_sort2   TYPE lvc_t_sort,
      gt_exclude TYPE ui_functions.

DATA: ok_code  TYPE sy-ucomm,
      gv_ucomm TYPE sy-ucomm.

DATA gv_sumon TYPE abap_bool.                     " 아래 수금 목록 고객별 합계 켜짐 여부
