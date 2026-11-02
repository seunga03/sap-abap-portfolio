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
      i_structure_name = 'ZSFIA00050'
    CHANGING
      ct_fieldcat      = gt_fcat_reg.

  " 선택·수금액만 편집 가능, KUNNR 숨김
  LOOP AT gt_fcat_reg INTO gs_fcat_reg.
    CASE gs_fcat_reg-fieldname.
      WHEN 'SEL'.
        gs_fcat_reg-edit     = 'X'.
        gs_fcat_reg-checkbox = 'X'.
        gs_fcat_reg-coltext  = '선택'.
      WHEN 'RCPAM'.
        gs_fcat_reg-edit     = 'X'.
        gs_fcat_reg-coltext  = '수금액'.
      WHEN 'OPENBAL'.
        gs_fcat_reg-coltext  = '잔액'.
      WHEN 'KUNNR'.
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
      i_structure_name = 'ZSFIA00050'
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
      it_outtab        = gt_arreg
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
  CLEAR gw_arreg.
  gw_arreg-kunnr   = 'C001'.
  gw_arreg-name1   = '(주)G반도체'.
  gw_arreg-arnum   = 'AR0011'.
  gw_arreg-bilno   = 'BL0001'.
  gw_arreg-duedt   = sy-datum.
  gw_arreg-dmbtr   = 2000.     " 화면에 200,000 원으로 표시됨 (KRW)
  gw_arreg-rcpbt   = 0.
  gw_arreg-openbal = 2000.     " 화면에 200,000 원으로 표시됨
  gw_arreg-sel     = ''.
  gw_arreg-rcpam   = 0.
  gw_arreg-waers   = 'KRW'.
  APPEND gw_arreg TO gt_arreg.

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
      i_structure_name = 'ZSFIA00040'     " ← AR 조회 헤더 구조체명으로
    CHANGING
      it_outtab        = gt_head
    EXCEPTIONS
      OTHERS           = 1.

  CALL METHOD go_alv2->set_table_for_first_display
    EXPORTING
      i_structure_name = 'ZSFIA00041'     " ← AR 조회 아이템 구조체명으로
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

* 상단: 수금 1건 (총 280,000원)
  CLEAR gw_head.
  gw_head-rcpnr = 'RCP0001'.
  gw_head-name1 = '(주)G반도체'.
  gw_head-rcpdt = p_rcpdt.        " 선택화면 수금일
  gw_head-rcpam = 2800.           " 280,000원
  gw_head-rcpac = p_rcpac.        " 선택화면 입금계좌
  gw_head-waers = 'KRW'.
  APPEND gw_head TO gt_head.

* 하단: 반제 2줄 (합계 = 상단 수금액 280,000)
  CLEAR gw_item.
  gw_item-rcpnr   = 'RCP0001'.
  gw_item-arnum   = 'AR0011'.
  gw_item-dmbtr   = 2000.         " 채권 200,000
  gw_item-arcam   = 2000.         " 반제 200,000 (전액)
  gw_item-openbal = 0.            " 잔액 0
  gw_item-clsta   = '0030'.       " 완결
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item.

  CLEAR gw_item.
  gw_item-rcpnr   = 'RCP0001'.
  gw_item-arnum   = 'AR0012'.
  gw_item-dmbtr   = 1000.         " 채권 100,000
  gw_item-arcam   = 800.          " 반제 80,000 (부분)
  gw_item-openbal = 200.          " 잔액 20,000
  gw_item-clsta   = '0020'.       " 부분수금
  gw_item-waers   = 'KRW'.
  APPEND gw_item TO gt_item.


ENDFORM.
