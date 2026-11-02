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

  " ─ 상단: 지급건 ─
  ls-fieldname = 'PAYNR'. ls-coltext = '지급번호'.   APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'LIFNR'. ls-coltext = '공급업체'.   APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'NAME1'. ls-coltext = '공급업체명'. APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'PAYDT'. ls-coltext = '지급일'.     APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'PAYAM'. ls-coltext = '지급금액'. ls-cfieldname = 'WAERS'. APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'WAERS'. ls-coltext = '통화'.       APPEND ls TO gt_fcat1. CLEAR ls.
  ls-fieldname = 'PAYAC'. ls-coltext = '출금계좌'.   APPEND ls TO gt_fcat1. CLEAR ls.

  " ─ 하단: 반제상세 ─
  ls-fieldname = 'PAYNR'.   ls-coltext = '지급번호'.   APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'APNUM'.   ls-coltext = '채무번호'.   APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'DMBTR'.   ls-coltext = '채무액'.     ls-cfieldname = 'WAERS'. APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'APCAM'.   ls-coltext = '반제액'.     ls-cfieldname = 'WAERS'. APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'OPENBAL'. ls-coltext = '반제후잔액'. ls-cfieldname = 'WAERS'. APPEND ls TO gt_fcat2. CLEAR ls.
  ls-fieldname = 'CLSTA'.   ls-coltext = '지급상태'.   APPEND ls TO gt_fcat2. CLEAR ls.
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
      i_structure_name              = 'ZSFIA00010'
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
      i_structure_name              = 'ZSFIA00011'
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

  " 상단 지급건
  gw_head-paynr = 'PAY0001'. gw_head-lifnr = 'V001'. gw_head-name1 = '(주)A정밀'.
  gw_head-paydt = '20260920'. gw_head-payam = 4280. gw_head-waers = 'KRW'. gw_head-payac = 'BK01'.   " 428,000
  APPEND gw_head TO gt_head.
  gw_head-paynr = 'PAY0002'. gw_head-lifnr = 'V002'. gw_head-name1 = '(주)B정밀'.
  gw_head-paydt = '20260922'. gw_head-payam = 1500. gw_head-waers = 'KRW'. gw_head-payac = 'BK01'.   " 150,000
  APPEND gw_head TO gt_head.

  " ── PAY0001 (A정밀 428,000) 에 딸린 반제 ──
  gw_item-paynr   = 'PAY0001'. gw_item-apnum = 'AP0013'.
  gw_item-dmbtr   = 3280.      gw_item-apcam = 3280.     " 328,000 / 328,000
  gw_item-openbal = 0.         gw_item-clsta = '0030'.   " 완결
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item. CLEAR gw_item.

  gw_item-paynr   = 'PAY0001'. gw_item-apnum = 'AP0014'.
  gw_item-dmbtr   = 1500.      gw_item-apcam = 1000.     " 150,000 / 100,000
  gw_item-openbal = 500.       gw_item-clsta = '0020'.   " 50,000 부분반제
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item. CLEAR gw_item.

  " ── PAY0002 (B정밀 150,000) 에 딸린 반제 ──
  gw_item-paynr   = 'PAY0002'. gw_item-apnum = 'AP0021'.
  gw_item-dmbtr   = 1000.      gw_item-apcam = 1000.     " 100,000 / 100,000
  gw_item-openbal = 0.         gw_item-clsta = '0030'.   " 완결
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item. CLEAR gw_item.

  gw_item-paynr   = 'PAY0002'. gw_item-apnum = 'AP0022'.
  gw_item-dmbtr   = 800.       gw_item-apcam = 500.      " 80,000 / 50,000
  gw_item-openbal = 300.       gw_item-clsta = '0020'.   " 30,000 부분반제
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item. CLEAR gw_item.

* ▼ 나중에 실제 SELECT (WAERS도 같이 가져오기)
*  SELECT p~paynr p~lifnr cm~name1 p~paydt p~payam p~waers p~payac
*    INTO CORRESPONDING FIELDS OF TABLE @gt_head
*    FROM ztfia00050 AS p
*    LEFT JOIN ztcma00010 AS cm ON cm~lifnr = p~lifnr
*    WHERE p~lifnr IN @s_lifnr AND p~paynr IN @s_paynr
*      AND p~paydt IN @s_paydt
*      AND ( @p_payac = '' OR p~payac = @p_payac ).
ENDFORM.
