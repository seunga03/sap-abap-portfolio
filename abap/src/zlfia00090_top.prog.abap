*&---------------------------------------------------------------------*
*& Include ZLFIA00090_TOP                           - Report ZLFIA00090
*&---------------------------------------------------------------------*
REPORT zlfia00090.

TABLES: ztfia00010, sscrfields.

CONSTANTS: gc_pass TYPE ztfia00010-mstat VALUE 'PASS',
           gc_hold TYPE ztfia00010-mstat VALUE 'HOLD',
           gc_qrej TYPE ztfia00010-mstat VALUE 'QREJ',
           gc_canc TYPE ztfia00010-mstat VALUE 'CANC'.   " 송장 취소 (거래처 귀책 반려 정리)

CONSTANTS: gc_rsn_price  TYPE ztfia00030-aprsn VALUE '0010',   " 반제사유: 단가차이 합의
           gc_clsta_part TYPE ztcma00110-clsta VALUE '0020',   " 지급상태: 부분 (⚠️ 유진 코드 확인)
           gc_clsta_done TYPE ztcma00110-clsta VALUE '0030'.   " 지급상태: 완결

CONSTANTS: gc_tgpgm     TYPE ztexa00060-tgpgm VALUE 'FI02',   " 유진 후속 요청: FI 프로그램 ID
           gc_act_aprc  TYPE ztexa00060-acttp VALUE 'APRC',   " AP 금액 재산정 → 재검증
           gc_act_reis  TYPE ztexa00060-acttp VALUE 'REIS',   " Invoice 재발행 요청 → 송장 취소
           gc_act_stlr  TYPE ztexa00060-acttp VALUE 'STLR'.   " 차이정산요청 → 단가차이 조정

DATA gt_req TYPE ztt_exreq.                                   " FI01 앞 대기 요청

*--- 0100: 재검증 대상 목록
DATA: BEGIN OF gw_list.
        INCLUDE TYPE zsfia00070.
DATA:   sel     TYPE c LENGTH 1,                 " 선택 (PASS 예상만 가능)
        expst   TYPE ztfia00010-mstat,           " 예상판정 (미리보기)
        reason  TYPE c LENGTH 120,               " 판정 내용 / 남은 원인
        celltab TYPE lvc_t_styl,                 " 셀별 입력 잠금
        adjam   TYPE ztfia00030-apcam,           " 조정예상액 (HOLD 라인 단가차 × 수량)
        rqnum   TYPE ztexa00060-rqnum,           " 요청번호 (숨김)
        acttg   TYPE ztexa00060-acttp,           " 조치코드 (숨김)
        reqtx   TYPE c LENGTH 20,                " 요청 (화면: 재검증 / 송장 취소 / 단가차이 조정)
      END OF gw_list.
DATA gt_list LIKE TABLE OF gw_list.

DATA: go_cont_reg TYPE REF TO cl_gui_custom_container,
      go_alv_reg  TYPE REF TO cl_gui_alv_grid,
      gt_fcat_reg TYPE lvc_t_fcat,
      gs_layo_reg TYPE lvc_s_layo.

*--- 0200: 결과 (상단 헤더 / 하단 PO라인)
DATA: BEGIN OF gw_res.
        INCLUDE TYPE zsfia00070.
DATA:   oldst TYPE ztfia00010-mstat,             " 재검증 전 상태
        msg   TYPE c LENGTH 100,                 " 처리 결과
      END OF gw_res.
DATA gt_res LIKE TABLE OF gw_res.

DATA: BEGIN OF gw_item.
        INCLUDE TYPE zsfia00071.
DATA: END OF gw_item.
DATA: gt_item     LIKE TABLE OF gw_item,         " 하단 표시용
      gt_item_all LIKE TABLE OF gw_item.         " 처리한 송장 전체 라인

DATA: go_cont   TYPE REF TO cl_gui_custom_container,
      go_split  TYPE REF TO cl_gui_splitter_container,
      go_top    TYPE REF TO cl_gui_container,
      go_bottom TYPE REF TO cl_gui_container,
      go_alv1   TYPE REF TO cl_gui_alv_grid,
      go_alv2   TYPE REF TO cl_gui_alv_grid.
DATA: gt_fcat1 TYPE lvc_t_fcat,
      gt_fcat2 TYPE lvc_t_fcat.

DATA: ok_code  TYPE sy-ucomm,
      gv_ucomm TYPE sy-ucomm.
