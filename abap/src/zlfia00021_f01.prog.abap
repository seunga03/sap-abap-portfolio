*&---------------------------------------------------------------------*
*& Include          ZLFIA00020_F01
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
  CREATE OBJECT go_cont_reg
    EXPORTING
      container_name = 'CON_AREA_REG'.
  CREATE OBJECT go_alv_reg
    EXPORTING
      i_parent = go_cont_reg.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  " 구조에서 자동 생성
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name = 'ZSFIA00020'
    CHANGING
      ct_fieldcat      = gt_fcat_reg.

  " 선택·지급액만 편집 가능, LIFNR 숨김
  LOOP AT gt_fcat_reg INTO gs_fcat_reg.
    CASE gs_fcat_reg-fieldname.
      WHEN 'SEL'.
        gs_fcat_reg-edit     = 'X'.
        gs_fcat_reg-checkbox = 'X'.
        gs_fcat_reg-coltext  = '선택'.
      WHEN 'PAYAM'.
        gs_fcat_reg-edit     = 'X'.
        gs_fcat_reg-coltext  = '지급액'.
      WHEN 'OPENBAL'.
        gs_fcat_reg-coltext  = '잔액'.
      WHEN 'LIFNR'.
        gs_fcat_reg-no_out   = 'X'.
    ENDCASE.
    MODIFY gt_fcat_reg FROM gs_fcat_reg.
  ENDLOOP.

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
  CALL METHOD go_alv_reg->set_table_for_first_display
    EXPORTING
*     i_buffer_active  =
*     i_bypassing_buffer            =
*     i_consistency_check           =
      i_structure_name = 'ZSFIA00020'
*     is_variant       =
*     i_save           =
*     i_default        =
*     is_layout        =
*     is_print         =
*     it_special_groups             =
*     it_toolbar_excluding          =
*     it_hyperlink     =
*     it_alv_graphics  =
*     it_except_qinfo  =
*     ir_salv_adapter  =
    CHANGING
      it_outtab        = gt_apreg
      it_fieldcatalog  = gt_fcat_reg
    EXCEPTIONS
      OTHERS           = 1.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_dummy
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data_dummy.
  CLEAR gw_apreg.
  gw_apreg-lifnr   = 'V0001'.
  gw_apreg-name1   = 'A정밀'.
  gw_apreg-apnum   = 'AP0001'.
  gw_apreg-ivnum   = 'IV0001'.
  gw_apreg-duedt   = sy-datum.
  gw_apreg-dmbtr   = 1000.     " 화면에 100,000 원으로 표시됨 (KRW)
  gw_apreg-rcpbt   = 0.
  gw_apreg-openbal = 1000.     " 화면에 100,000 원으로 표시됨
  gw_apreg-sel     = ''.
  gw_apreg-payam   = 0.
  gw_apreg-waers   = 'KRW'.
  APPEND gw_apreg TO gt_apreg.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_object_0200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object_0200 .
  CREATE OBJECT go_cont
    EXPORTING
      container_name = 'CON_AREA'.

  go_split  = NEW #( parent = go_cont rows = 2 columns = 1 ).
  go_top    = go_split->get_container( row = 1 column = 1 ).
  go_bottom = go_split->get_container( row = 2 column = 1 ).

  CREATE OBJECT go_alv1 EXPORTING i_parent = go_top.
  CREATE OBJECT go_alv2 EXPORTING i_parent = go_bottom.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_0200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_0200 .
  CALL METHOD go_alv1->set_table_for_first_display
    EXPORTING
      i_structure_name = 'ZSFIA00010'
    CHANGING
      it_outtab        = gt_head
    EXCEPTIONS
      OTHERS           = 1.

  CALL METHOD go_alv2->set_table_for_first_display
    EXPORTING
      i_structure_name = 'ZSFIA00011'
    CHANGING
      it_outtab        = gt_item
    EXCEPTIONS
      OTHERS           = 1.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_dummy_0200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_dummy_0200 .
  CLEAR: gt_head, gt_item.

* 상단: 지급 1건 (총 160,000원)
  CLEAR gw_head.
  gw_head-paynr = 'PAY0001'.
  gw_head-name1 = 'A정밀'.
  gw_head-paydt = p_paydt.        " 선택화면 지급일
  gw_head-payam = 1600.           " 160,000원
  gw_head-payac = p_payac.        " 선택화면 출금계좌
  gw_head-waers = 'KRW'.
  APPEND gw_head TO gt_head.

* 하단: 반제 2줄 (합계 = 상단 지급액 160,000)
  CLEAR gw_item.
  gw_item-paynr   = 'PAY0001'.
  gw_item-apnum   = 'AP0001'.
  gw_item-dmbtr   = 1000.         " 채무 100,000
  gw_item-apcam   = 1000.         " 반제 100,000 (전액)
  gw_item-openbal = 0.            " 잔액 0
  gw_item-clsta   = 'C'.          " 완결 ← 도메인 값에 맞게
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item.

  CLEAR gw_item.
  gw_item-paynr   = 'PAY0001'.
  gw_item-apnum   = 'AP0002'.
  gw_item-dmbtr   = 1000.         " 채무 100,000
  gw_item-apcam   = 600.          " 반제 60,000 (부분)
  gw_item-openbal = 400.          " 잔액 40,000
  gw_item-clsta   = 'P'.          " 부분반제 ← 도메인 값에 맞게
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item.


ENDFORM.
