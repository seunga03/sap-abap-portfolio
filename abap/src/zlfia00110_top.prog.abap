*&---------------------------------------------------------------------*
*& Include          ZLFIA00110_TOP
*&---------------------------------------------------------------------*

" 건별 (CDS ZV_FI_OPEN_AGING 한 줄 + 화면용 칸)
TYPES: BEGIN OF ty_item,
         dtype   TYPE c LENGTH 2,          " AP / AR (내부 코드)
         dttxt   TYPE c LENGTH 12,         " 채무 / 채권
         docno   TYPE c LENGTH 10,         " 채무·채권번호
         refno   TYPE c LENGTH 10,         " 송장·청구번호
         partner TYPE c LENGTH 10,         " 공급업체·고객
         name1   TYPE ztcma00010-name1,    " 거래처명
         duedt   TYPE ztcma00110-duedt,    " 지급·수금기한
         waers   TYPE waers,
         dmbtr   TYPE dmbtr,               " 금액
         clrbt   TYPE dmbtr,               " 반제누계 (지급·수금)
         adjbt   TYPE dmbtr,               " 조정누계
         openbal TYPE dmbtr,               " 잔액
         ovdays  TYPE i,                   " +연체일 / -남은일
         ovtxt   TYPE c LENGTH 20,         " 연체 n일 / n일 남음 (화면용)
         bucket  TYPE c LENGTH 1,          " 0 완결 / 1 연체 / 2 7일 / 3 30일 / 4 30일 초과
         bktxt   TYPE c LENGTH 20,         " 구간 이름
         stico   TYPE icon_d,              " 신호등
       END OF ty_item.

" 만기 구간별 (CDS ZV_FI_OPEN_SUM 을 채무/채권 옆으로 펼친 것)
TYPES: BEGIN OF ty_sum,
         bucket TYPE c LENGTH 1,           " 1~4 / T 합계
         bktxt  TYPE c LENGTH 20,
         waers  TYPE waers,
         apcnt  TYPE i,                    " 채무 건수
         apbal  TYPE dmbtr,                " 미지급 채무
         arcnt  TYPE i,                    " 채권 건수
         arbal  TYPE dmbtr,                " 미수 채권
         netbal TYPE dmbtr,                " 미수 채권 - 미지급 채무 (계산용)
         nettxt TYPE c LENGTH 30,          " 순액 (화면용, +/- 앞에)
         rowcol TYPE c LENGTH 4,           " 줄 색 (합계 줄)
       END OF ty_sum.

DATA: gt_all    TYPE STANDARD TABLE OF ty_item,   " CDS 전체 (KPI용)
      gt_item   TYPE STANDARD TABLE OF ty_item,   " 아래 ALV (완결 제외 + 구분)
      gw_item   TYPE ty_item,
      gt_sum    TYPE STANDARD TABLE OF ty_sum,    " 위 ALV
      gw_sum    TYPE ty_sum,
      gv_bucket TYPE c LENGTH 1,                  " 더블클릭으로 고른 구간
      gv_cnt    TYPE i,
      ok_code   TYPE sy-ucomm.

DATA: go_con    TYPE REF TO cl_gui_custom_container,
      go_split  TYPE REF TO cl_gui_splitter_container,
      go_c_kpi  TYPE REF TO cl_gui_container,
      go_c_sum  TYPE REF TO cl_gui_container,
      go_c_item TYPE REF TO cl_gui_container,
      go_kpi    TYPE REF TO zcl_cm_kpi_html,
      go_alv1   TYPE REF TO cl_gui_alv_grid,
      go_alv2   TYPE REF TO cl_gui_alv_grid.
