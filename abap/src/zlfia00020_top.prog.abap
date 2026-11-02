*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_TOP
*&---------------------------------------------------------------------*
REPORT zlfia00020.

INCLUDE <icon>.

TABLES: ztcma00110.

CONSTANTS: gc_clsta_open TYPE ztcma00110-clsta VALUE '0010',   " 미지급
           gc_clsta_part TYPE ztcma00110-clsta VALUE '0020',   " 부분지급
           gc_clsta_done TYPE ztcma00110-clsta VALUE '0030'.   " 지급완료

*--- 상단: 지급 대상 채무
DATA: BEGIN OF gw_apreg.
        INCLUDE TYPE zsfia00020.          " RCPBT = 지급누계로 사용
DATA:   adjbt   TYPE ztcma00110-adjbt,    " 조정누계
        hdico   TYPE icon_d,              " 홀드 아이콘
        celltab TYPE lvc_t_styl,          " 체크 잠금
        ddtxt   TYPE c LENGTH 10,         " 기한 (연체 n일 / 오늘 / D-n)
        rowcol  TYPE c LENGTH 4,          " 행 색 (C600 연체 / C700 7일 이내)
      END OF gw_apreg.
DATA gt_apreg LIKE TABLE OF gw_apreg.

*--- 하단: 이번 지급
DATA: BEGIN OF gw_pay.
        INCLUDE TYPE zsfia00011.          " PAYNR APNUM DMBTR APCAM(지급액) OPENBAL(지급 후 잔액) CLSTA WAERS
DATA:   lifnr   TYPE ztcma00110-lifnr,
        name1   TYPE ztcma00010-name1,
        ivnum   TYPE ztcma00110-ivnum,
        balbf   TYPE ztcma00110-dmbtr,    " 지급 전 잔액
        sttxt   TYPE c LENGTH 10,         " 지급상태 (미지급/부분지급/지급완료)
        stico   TYPE icon_d,              " 결과 아이콘
        msg     TYPE c LENGTH 60,         " 결과
        celltab TYPE lvc_t_styl,          " 지급 끝난 행 잠금
      END OF gw_pay.
DATA gt_pay LIKE TABLE OF gw_pay.

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

DATA gv_sumon TYPE abap_bool.                     " 아래 지급 목록 공급업체별 합계 켜짐 여부
