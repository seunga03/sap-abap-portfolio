REPORT zsdcm01_dashboard.

INCLUDE zsdcm01_dashboard_top.

SELECT *
  FROM zv_sd_dashboard
  INTO TABLE @gt_data
  WHERE SoNumber IN @s_vbeln
    AND Customer IN @s_kunnr.

TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = go_alv
      CHANGING  t_table      = gt_data ).
  CATCH cx_salv_msg.
ENDTRY.

DATA: lo_cols TYPE REF TO cl_salv_columns_table,
      lo_col  TYPE REF TO cl_salv_column.

lo_cols = go_alv->get_columns( ).
lo_cols->set_optimize( abap_true ).

TRY.
    lo_col = lo_cols->get_column( 'SONUMBER' ).
    lo_col->set_short_text( '판매문서' ).
    lo_col->set_medium_text( '판매문서번호' ).
    lo_col->set_long_text( '판매문서번호' ).

    lo_col = lo_cols->get_column( 'ORDERDATE' ).
    lo_col->set_short_text( '주문일' ).
    lo_col->set_medium_text( '주문일자' ).
    lo_col->set_long_text( '주문일자' ).

    lo_col = lo_cols->get_column( 'CUSTOMER' ).
    lo_col->set_short_text( '고객' ).
    lo_col->set_medium_text( '고객번호' ).
    lo_col->set_long_text( '고객번호' ).

    lo_col = lo_cols->get_column( 'SOSTATUS' ).
    lo_col->set_short_text( '상태' ).
    lo_col->set_medium_text( 'SO상태' ).
    lo_col->set_long_text( 'SO상태' ).

    lo_col = lo_cols->get_column( 'PROGRESSSTEP' ).
    lo_col->set_short_text( '진행' ).
    lo_col->set_medium_text( '진행단계' ).
    lo_col->set_long_text( '진행단계' ).

    lo_col = lo_cols->get_column( 'CRITICALITY' ).
    lo_col->set_visible( abap_false ).
  CATCH cx_salv_not_found.
ENDTRY.

DATA: lo_display TYPE REF TO cl_salv_display_settings.
lo_display = go_alv->get_display_settings( ).
lo_display->set_list_header( 'SD 대시보드 - CM01' ).
lo_display->set_striped_pattern( abap_true ).

DATA: lv_total TYPE i,
      lv_so    TYPE i,
      lv_do    TYPE i,
      lv_gi    TYPE i,
      lv_bi    TYPE i.

lv_total = lines( gt_data ).

LOOP AT gt_data INTO DATA(ls_row).
  CASE ls_row-sostatus.
    WHEN 'SO'.
      lv_so = lv_so + 1.
    WHEN 'DO'.
      lv_do = lv_do + 1.
    WHEN 'GI'.
      lv_gi = lv_gi + 1.
    WHEN 'BI'.
      lv_bi = lv_bi + 1.
  ENDCASE.
ENDLOOP.

DATA(lo_grid) = NEW cl_salv_form_layout_grid( ).

lo_grid->create_header_information( row    = 1
                                    column = 1
                                    text   = 'SD 판매현황 요약' ).

lo_grid->create_label( row     = 2
                       column  = 1
                       colspan = 10
                       text    = |전체 { lv_total }건  /  SO { lv_so }건  /  DO { lv_do }건  /  GI { lv_gi }건  /  BI { lv_bi }건| ).

go_alv->set_top_of_list( lo_grid ).

go_alv->display( ).
