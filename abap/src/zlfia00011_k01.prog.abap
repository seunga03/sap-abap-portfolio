*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.

ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_double_click.
    READ TABLE gt_head INTO gw_head INDEX es_row_no-row_id.


    CLEAR gt_item.
    SELECT a~paynr a~apnum a~apcam a~waers
           b~dmbtr b~clsta
           b~paybt AS openbal          " ← 일단 반제누계를 받아두고 아래서 잔액 계산
      INTO CORRESPONDING FIELDS OF TABLE gt_item
      FROM ztfia00030 AS a
      INNER JOIN ztcma00110 AS b
        ON a~apnum = b~apnum
      WHERE a~paynr = gw_head-paynr.

    "3) 잔액 = 채무금액 - 반제누계
    LOOP AT gt_item INTO gw_item.
      gw_item-openbal = gw_item-dmbtr - gw_item-openbal.
      MODIFY gt_item FROM gw_item.
    ENDLOOP.

    DATA ls_stable TYPE lvc_s_stbl.
    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    go_alv2->refresh_table_display( is_stable = ls_stable ).
  ENDMETHOD.

ENDCLASS.
