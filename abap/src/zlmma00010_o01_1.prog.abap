*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_O01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module CLEAR_OK_CODE OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE clear_ok_code OUTPUT.

  CLEAR ok_code.

ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  SET PF-STATUS 'G0100'.
  SET TITLEBAR 'T0100'.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module DISPLAY_KPI OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_kpi OUTPUT.

  IF go_kpi_cont IS NOT BOUND.

    CREATE OBJECT go_kpi_cont
      EXPORTING
        container_name = 'CC_KPI'.

    CREATE OBJECT go_kpi
      EXPORTING
        io_parent = go_kpi_cont.

  ENDIF.

  PERFORM zz_exe_show_kpi.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module DISPLAY_FG_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_fg_alv OUTPUT.

  IF go_cont IS NOT BOUND.

    " 현재 서브스크린의 Custom Control에 연결
    CREATE OBJECT go_cont
      EXPORTING
        container_name = 'CC_FG'.

    " FG ALV 생성
    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_cont.

    " 기존 Field Catalog 및 Layout 재사용
    PERFORM zz_set_field_catalog.
    PERFORM zz_set_layout.

    " 최초 ALV 출력
    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layo
      CHANGING
        it_outtab       = gt_shortage
        it_fieldcatalog = gt_fcat.

  ELSE.

    " 탭 재진입 시 기존 ALV 갱신
    IF go_grid IS BOUND.
      go_grid->refresh_table_display( ).
    ENDIF.

  ENDIF.


ENDMODULE.

*&---------------------------------------------------------------------*
*& Module DISPLAY_COMP_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_comp_alv OUTPUT.

  " 최신 지급자재 집계 결과를 ALV용 테이블에 반영
  PERFORM zz_set_comp_display.

  IF go_comp_cont IS NOT BOUND.

    " 0120 서브스크린의 Custom Control
    CREATE OBJECT go_comp_cont
      EXPORTING
        container_name = 'CC_COMP'.

    CREATE OBJECT go_comp_grid
      EXPORTING
        i_parent = go_comp_cont.

    " Field Catalog 및 Layout
    PERFORM zz_set_comp_fcat.
    PERFORM zz_set_comp_layout.

    " 최초 ALV 출력
    CALL METHOD go_comp_grid->set_table_for_first_display
      EXPORTING
        is_layout       = gs_comp_layo
      CHANGING
        it_outtab       = gt_comp_display
        it_fieldcatalog = gt_comp_fcat.

  ELSE.

    " 탭 재진입 시 갱신
    IF go_comp_grid IS BOUND.
      go_comp_grid->refresh_table_display( ).
    ENDIF.

  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module DISPLAY_PR_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE display_pr_alv OUTPUT.

  IF go_pr_cont IS NOT BOUND.

    CREATE OBJECT go_pr_cont
      EXPORTING
        container_name = 'CC_PR'.

    CREATE OBJECT go_pr_grid
      EXPORTING
        i_parent = go_pr_cont.

    PERFORM zz_set_pr_fcat.
    PERFORM zz_set_pr_layout.

    CALL METHOD go_pr_grid->set_table_for_first_display
      EXPORTING
        is_layout       = gs_pr_layo
      CHANGING
        it_outtab       = gt_pr_preview
        it_fieldcatalog = gt_pr_fcat.

  ELSE.

    IF go_pr_grid IS BOUND.
      go_pr_grid->refresh_table_display( ).
    ENDIF.

  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module SET_TAB_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_tab_0100 OUTPUT.

  CASE gv_dynnr.

    WHEN '0110'.
      tab_main-activetab = 'FG'.

    WHEN '0120'.
      tab_main-activetab = 'COMP'.

    WHEN '0130'.
      tab_main-activetab = 'PRRS'.

    WHEN OTHERS.
      gv_dynnr = '0110'.
      tab_main-activetab = 'FG'.

  ENDCASE.

ENDMODULE.
