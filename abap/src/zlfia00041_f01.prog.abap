*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_object
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object .

  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'CON_AREA'.

  go_split = NEW #( parent = go_cont rows = 2 columns = 1 ).
  go_top    = go_split->get_container( row = 1 column = 1 ).
  go_bottom = go_split->get_container( row = 2 column = 1 ).

  CREATE OBJECT go_alv1 EXPORTING i_parent = go_top.
  CREATE OBJECT go_alv2 EXPORTING i_parent = go_bottom.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_evt_handler
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_evt_handler .
  SET HANDLER: lcl_handler=>on_double_click         FOR go_alv1.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog.
  DATA ls TYPE lvc_s_fcat.
  CLEAR: gt_fcat1, gt_fcat2.

  " ─ 상단: 수금건 ─
  ls-fieldname = 'RCPNR'. ls-coltext = '수금번호'.   APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'KUNNR'. ls-coltext = '고객'.       APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'NAME1'. ls-coltext = '고객명'.     APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'RCPDT'. ls-coltext = '수금일'.     APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'RCPAM'. ls-coltext = '수금금액'. ls-cfieldname = 'WAERS'. APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'WAERS'. ls-coltext = '통화'.       APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'RCPAC'. ls-coltext = '입금계좌'.   APPEND ls TO gt_fcat1. CLEAR ls.

  " ─ 하단: 반제상세 ─
  ls-fieldname = 'RCPNR'.   ls-coltext = '수금번호'.   APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'ARNUM'.   ls-coltext = '채권번호'.   APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'DMBTR'.   ls-coltext = '채권액'.     ls-cfieldname = 'WAERS'. APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'ARCAM'.   ls-coltext = '반제액'.     ls-cfieldname = 'WAERS'. APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'OPENBAL'. ls-coltext = '반제후잔액'. ls-cfieldname = 'WAERS'. APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'CLSTA'.   ls-coltext = '회수상태'.   APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'WAERS'.   ls-coltext = '통화'.       APPEND ls TO gt_fcat2. CLEAR ls.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .

*── 상단: 지급건
  CALL METHOD go_alv1->set_table_for_first_display
    EXPORTING
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
      i_structure_name              = 'ZSFIA00040'
*     is_variant                    =
*     i_save                        =
*     i_default                     =
*     is_layout                     =
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_head
      it_fieldcatalog               = gt_fcat1
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.

  IF sy-subrc <> 0.
    MESSAGE a018(zmsga).
  ENDIF.


*── 하단: 반제상세
  CALL METHOD go_alv2->set_table_for_first_display
    EXPORTING
*     i_buffer_active               =
*     i_bypassing_buffer            =
*     i_consistency_check           =
      i_structure_name              = 'ZSFIA00041'
*     is_variant                    =
*     i_save                        =
*     i_default                     =
*     is_layout                     =
*     is_print                      =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink                  =
*     it_alv_graphics               =
*     it_except_qinfo               =
*     ir_salv_adapter               =
    CHANGING
      it_outtab                     = gt_item
      it_fieldcatalog               = gt_fcat2
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.

  IF sy-subrc <> 0.
    MESSAGE a018(zmsga).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data_dummy.
  CLEAR: gt_head, gt_item.

  " 상단 수금건
  gw_head-rcpnr = 'RCP0001'. gw_head-kunnr = 'C001'. gw_head-name1 = '(주)G반도체'.
  gw_head-rcpdt = '20260920'. gw_head-rcpam = 5000. gw_head-waers = 'KRW'. gw_head-rcpac = 'BK01'.   " 500,000
  APPEND gw_head TO gt_head.
  gw_head-rcpnr = 'RCP0002'. gw_head-kunnr = 'C002'. gw_head-name1 = '(주)H전자'.
  gw_head-rcpdt = '20260922'. gw_head-rcpam = 1500. gw_head-waers = 'KRW'. gw_head-rcpac = 'BK01'.   " 150,000
  APPEND gw_head TO gt_head.

  " ── RCP0001 (G반도체 500,000) 에 딸린 반제 ──
  gw_item-rcpnr   = 'RCP0001'. gw_item-arnum = 'AR0011'.
  gw_item-dmbtr   = 2000.      gw_item-arcam = 2000.     " 200,000 / 200,000
  gw_item-openbal = 0.         gw_item-clsta = '0030'.   " 완결
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item. CLEAR gw_item.

  gw_item-rcpnr   = 'RCP0001'. gw_item-arnum = 'AR0012'.
  gw_item-dmbtr   = 1000.      gw_item-arcam = 800.      " 100,000 / 80,000
  gw_item-openbal = 200.       gw_item-clsta = '0020'.   " 20,000 부분수금
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item. CLEAR gw_item.

  gw_item-rcpnr   = 'RCP0001'. gw_item-arnum = 'AR0013'.
  gw_item-dmbtr   = 2200.      gw_item-arcam = 2200.     " 220,000 / 220,000
  gw_item-openbal = 0.         gw_item-clsta = '0030'.   " 완결
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item. CLEAR gw_item.

  " ── RCP0002 (H전자 150,000) 에 딸린 반제 ──
  gw_item-rcpnr   = 'RCP0002'. gw_item-arnum = 'AR0021'.
  gw_item-dmbtr   = 1000.      gw_item-arcam = 1000.     " 100,000 / 100,000
  gw_item-openbal = 0.         gw_item-clsta = '0030'.   " 완결
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item. CLEAR gw_item.

  gw_item-rcpnr   = 'RCP0002'. gw_item-arnum = 'AR0022'.
  gw_item-dmbtr   = 800.       gw_item-arcam = 500.      " 80,000 / 50,000
  gw_item-openbal = 300.       gw_item-clsta = '0020'.   " 30,000 부분수금
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item. CLEAR gw_item.

* ▼ 나중에 실제 SELECT (WAERS도 같이 가져오기)
*  SELECT r~rcpnr r~kunnr cm~name1 r~rcpdt r~rcpam r~waers r~rcpac
*    INTO CORRESPONDING FIELDS OF TABLE @gt_head
*    FROM ztfia00060 AS r
*    LEFT JOIN ztcma000xx AS cm ON cm~kunnr = r~kunnr     " ← 고객 마스터 테이블명으로
*    WHERE r~kunnr IN @s_kunnr AND r~rcpnr IN @s_rcpnr
*      AND r~rcpdt IN @s_rcpdt
*      AND ( @p_rcpac = '' OR r~rcpac = @p_rcpac ).
ENDFORM.
