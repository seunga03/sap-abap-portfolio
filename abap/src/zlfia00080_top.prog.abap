*&---------------------------------------------------------------------*
*& Include          ZLFIA00080_TOP
*&---------------------------------------------------------------------*
REPORT zlfia00080.

INCLUDE <icon>.
TABLES: sscrfields.

DATA: go_dock_sel TYPE REF TO cl_gui_docking_container,   " 선택화면 오른쪽 PDF 영역
      go_html_sel TYPE REF TO cl_gui_html_viewer.

*--- 대사상태 코드 (공통코드 MSTAT)
CONSTANTS: gc_wait TYPE ztfia00010-mstat VALUE space,
           gc_pass TYPE ztfia00010-mstat VALUE 'PASS',
           gc_hold TYPE ztfia00010-mstat VALUE 'HOLD',
           gc_qrej TYPE ztfia00010-mstat VALUE 'QREJ'.

*--- 0100 편집 ALV
DATA: BEGIN OF gw_ivreg.
        INCLUDE TYPE zsfia00080.
DATA: END OF gw_ivreg.
DATA gt_ivreg LIKE TABLE OF gw_ivreg.

DATA: go_cont_reg TYPE REF TO cl_gui_custom_container,
      go_alv_reg  TYPE REF TO cl_gui_alv_grid.
DATA: gt_fcat_reg TYPE lvc_t_fcat,
      gs_fcat_reg TYPE lvc_s_fcat.

*--- PO 정보 / 0100 상단 표시용 (스크린 필드)
DATA: gv_lifnr  TYPE ztmma00050-lifnr,
      gv_name1  TYPE ztcma00010-name1,
      gv_waers  TYPE ztmma00060-waers,
      gv_factor TYPE i,                         " 내부값↔원 단위 계수 (KRW = 100)
      gv_lsum   TYPE p LENGTH 13 DECIMALS 0,    " 라인 합계 (원)
      gv_diff   TYPE p LENGTH 13 DECIMALS 0.    " 입력총액 - 라인합계

DATA: gv_total_t TYPE c LENGTH 20,   " 화면 표시용: 입력 총액
      gv_lsum_t  TYPE c LENGTH 20,   " 화면 표시용: 라인 합계
      gv_diff_t  TYPE c LENGTH 20.   " 화면 표시용: 차이

*--- 0200 결과 Split
DATA: BEGIN OF gw_head.
        INCLUDE TYPE zsfia00070.
DATA: END OF gw_head.
DATA gt_head LIKE TABLE OF gw_head.

DATA: BEGIN OF gw_item.
        INCLUDE TYPE zsfia00071.
DATA:   light TYPE c LENGTH 1,             " 신호등 (1 빨강 / 2 노랑 / 3 초록)
        mstxt TYPE c LENGTH 20,            " 라인 판정 (한글)
      END OF gw_item.
DATA gt_item LIKE TABLE OF gw_item.

DATA: go_cont TYPE REF TO cl_gui_custom_container,
*      go_split  TYPE REF TO cl_gui_splitter_container,
*      go_top    TYPE REF TO cl_gui_container,
*      go_bottom TYPE REF TO cl_gui_container,
*      go_alv1   TYPE REF TO cl_gui_alv_grid,   " 상단 송장 헤더
      go_alv2 TYPE REF TO cl_gui_alv_grid.   " 하단 PO라인 판정
DATA: "gt_fcat1 TYPE lvc_t_fcat,
      gt_fcat2 TYPE lvc_t_fcat.

DATA: gv_wrbtr_t TYPE c LENGTH 20,             " 화면 표시용: 총청구금액
      gv_icon    TYPE icon_d,                  " 화면 표시용: 판정 신호등
      gv_mstxt   TYPE c LENGTH 20.             " 화면 표시용: 판정 내용

*--- 제어용
DATA: ok_code    TYPE sy-ucomm,
      gv_ucomm   TYPE sy-ucomm,
      gv_ok      TYPE c LENGTH 1,
      gv_saving  TYPE c LENGTH 1,      " 저장 중이면 X (이벤트에서 REFR 안 쏘게)
      gv_holdmsg TYPE string,          " 홀드 함수 미연결 안내
      gs_btn     TYPE smp_dyntxt.      " 선택화면 툴바 버튼 (아이콘 + 글자)

*─ Gemini 설정 (발표 끝나면 AI Studio에서 키 삭제)
CONSTANTS: gc_ai_key   TYPE string VALUE 'AQ.Ab8RN6Iwy7sTOIGx33itlrZUS9s8Gno4XjTvpppbWKc72gsYKQ',
           gc_ai_model TYPE string VALUE 'gemini-3-flash-preview'.

*─ PDF 송장 읽기 (AI)
TYPES: BEGIN OF ty_ai_item,                 " AI 응답 라인 (문자로 받고 나중에 변환)
         matnr TYPE string,
         menge TYPE string,
         netpr TYPE string,
       END OF ty_ai_item,
       ty_t_ai_item TYPE STANDARD TABLE OF ty_ai_item WITH DEFAULT KEY,
       BEGIN OF ty_ai,                      " AI 응답 헤더
         ebeln TYPE string,
         xblnr TYPE string,
         bldat TYPE string,
         total TYPE string,
         items TYPE ty_t_ai_item,
       END OF ty_ai,
       BEGIN OF ty_ai_line,                 " 0100 화면에 반영할 라인
         matnr TYPE ztmma00060-matnr,
         menge TYPE ztfia00020-menge,
         netpr TYPE p LENGTH 13 DECIMALS 0, " 원 단위
       END OF ty_ai_line.

DATA: gt_ai_line  TYPE TABLE OF ty_ai_line,
      gv_ai_ebeln TYPE ztfia00010-ebeln.     " PDF에서 읽은 PO (다른 PO로 바꾸면 무시)

*─ 0100 PDF 미리보기
DATA: gv_pdf_x     TYPE xstring,                        " PDF 읽기로 올린 파일
      go_split_reg TYPE REF TO cl_gui_splitter_container,
      go_left_reg  TYPE REF TO cl_gui_container,
      go_right_reg TYPE REF TO cl_gui_container,
      go_html      TYPE REF TO cl_gui_html_viewer.
