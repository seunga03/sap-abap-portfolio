*&---------------------------------------------------------------------*
*& Include ZLCMA00020_TOP                           - Report ZLCMA00020
*&---------------------------------------------------------------------*
TABLES: sscrfields.

TYPES: BEGIN OF ty_vendor,
         lifnr     TYPE ztcma00010-lifnr,
         name1     TYPE ztcma00010-name1,
         land1     TYPE ztcma00010-land1,
         regio     TYPE ztcma00010-regio,
         telf1     TYPE ztcma00010-telf1,
         zterm     TYPE ztcma00010-zterm,
         trdyn     TYPE ztcma00010-trdyn,
         inrsn     TYPE ztcma00010-inrsn,    " * 거래불가 사유
         erdat     TYPE ztcma00010-erdat,    " * 등록일
         land_txt  TYPE char20,              " 국가 텍스트
         regio_txt TYPE char20,              " 지역 텍스트
         zterm_txt TYPE char30,              " 지급조건 텍스트
         rowcolor  TYPE char4,               " 거래불가(N) 행 회색
       END OF ty_vendor.

CONSTANTS: gc_mode_create  TYPE c VALUE 'C',
           gc_mode_change  TYPE c VALUE 'U',
           gc_mode_display TYPE c VALUE 'R'.

*--- 선택화면 참조용
DATA: gv_lifnr TYPE ztcma00010-lifnr,
      gv_name1 TYPE ztcma00010-name1.

*--- 공통
DATA: ok_code   TYPE sy-ucomm,             " Screen 0100/0200 OK 필드
      gv_okcode TYPE sy-ucomm,
      gt_excl   TYPE STANDARD TABLE OF sy-ucomm.

*--- SCR 0100 (ALV)
CLASS lcl_event_handler DEFINITION DEFERRED.
DATA: gt_vendor    TYPE STANDARD TABLE OF ty_vendor,
      go_container TYPE REF TO cl_gui_custom_container,
      go_grid      TYPE REF TO cl_gui_alv_grid,
      go_handler   TYPE REF TO lcl_event_handler,
      gt_fcat      TYPE lvc_t_fcat,
      gs_layout    TYPE lvc_s_layo.
DATA: go_cont_kpi  TYPE REF TO cl_gui_custom_container,
      go_kpi       TYPE REF TO zcl_cm_kpi_html,
      gv_kpi_dirty TYPE abap_bool.

*--- SCR 0200 (상세) : Screen Painter에서 '프로그램에서 가져오기'로 GS_0200 사용
DATA: gs_0200     TYPE ztcma00010,
      gs_0200_org TYPE ztcma00010,         " 변경 여부 비교용
      gv_mode     TYPE c,                  " C 생성 / U 변경 / R 조회
      gv_rb_y     TYPE c VALUE 'X',        " 거래가능 Y 라디오
      gv_rb_n     TYPE c.                  " 거래가능 N 라디오
