*&---------------------------------------------------------------------*
*& Report ztest_kpi_v2
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ztest_kpi_v2.

DATA: go_dlg TYPE REF TO cl_gui_dialogbox_container,
      go_kpi TYPE REF TO zcl_cm_kpi_html,
      gt_w   TYPE zcl_cm_kpi_html=>tt_widget.

START-OF-SELECTION.
  CREATE OBJECT go_dlg
    EXPORTING width = 900 height = 330 top = 40 left = 40
              caption = 'KPI v2 테스트'.
  CREATE OBJECT go_kpi EXPORTING io_parent = go_dlg.

  APPEND zcl_cm_kpi_html=>w_card( iv_label = '미결' iv_value = '12건' iv_sub = '처리 필요' iv_color = 'R' ) TO gt_w.
  APPEND zcl_cm_kpi_html=>w_card( iv_label = '종료' iv_value = '30건' iv_color = 'G' ) TO gt_w.
  APPEND zcl_cm_kpi_html=>w_donut( iv_title = '상태 비율'
           it_item = VALUE #( ( label = '정상' value = 8 color = 'G' )
                              ( label = '보류' value = 3 color = 'Y' )
                              ( label = '반려' value = 1 color = 'R' ) ) ) TO gt_w.
  APPEND zcl_cm_kpi_html=>w_hbar( iv_title = '출처별 건수'
           it_item = VALUE #( ( label = 'SUBC' value = 5 )
                              ( label = 'QM'   value = 3 )
                              ( label = 'INVC' value = 7 ) ) ) TO gt_w.
  APPEND zcl_cm_kpi_html=>w_trend( iv_title = '월별 추이'
           it_item = VALUE #( ( label = '7월' value = 4 ) ( label = '8월' value = 9 )
                              ( label = '9월' value = 6 ) ( label = '10월' value = 12 ) ) ) TO gt_w.
  APPEND zcl_cm_kpi_html=>w_table( iv_title = '상위 2건'
           it_head = VALUE #( ( `번호` ) ( `유형` ) ( `일수` ) )
           it_row  = VALUE #( ( cells = VALUE #( ( `EX01` ) ( `SUBC` ) ( `5` ) ) )
                              ( cells = VALUE #( ( `EX02` ) ( `QM` )   ( `3` ) ) ) ) ) TO gt_w.
  APPEND zcl_cm_kpi_html=>w_progress( iv_label = '처리율' iv_pct = 71 iv_text = '30 / 42' iv_color = 'G' ) TO gt_w.

  go_kpi->show_widgets( it_widget = gt_w iv_title = 'KPI v2 테스트' iv_foot = '임시 테스트 화면' ).
  cl_gui_cfw=>flush( ).
  WRITE: / '아래는 일반 리스트 영역'.
