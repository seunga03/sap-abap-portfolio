*&---------------------------------------------------------------------*
*& Include          ZLDPA00021_K01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& ALV Hotspot 이벤트 처리 클래스
*&---------------------------------------------------------------------*
CLASS lcl_event_receiver DEFINITION.
  PUBLIC SECTION.
    METHODS handle_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
ENDCLASS.

*&---------------------------------------------------------------------*
*& 선언부
*&---------------------------------------------------------------------*
CLASS lcl_event_receiver IMPLEMENTATION.

  METHOD handle_hotspot_click.

    """ 예측사유 컬럼 클릭 여부 확인
    CHECK e_column_id-fieldname = 'REASON_LINK'.

    """ 클릭한 ALV 행 조회
    READ TABLE gt_forecast INTO DATA(ls_forecast)
      INDEX e_row_id-index.

    CHECK sy-subrc = 0.
    CHECK ls_forecast-aireason IS NOT INITIAL.

    """ 팝업에 표시할 데이터 전달
    gv_reason_matnr = ls_forecast-matnr.
    gv_reason_maktx = ls_forecast-maktx.
    gv_reason_aiqty = ls_forecast-aiqty.
    gv_reason_meins = ls_forecast-meins.
    gv_reason       = ls_forecast-aireason.

    """ 예측 근거 팝업 호출
    CALL SCREEN 0200 STARTING AT 15 5 ENDING AT 110 22.

  ENDMETHOD.

ENDCLASS.
