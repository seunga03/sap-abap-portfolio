*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_object
*&---------------------------------------------------------------------*
*& ALV 그리기
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_object .
  CREATE OBJECT go_con
    EXPORTING
      container_name              = 'CUSTOM_CON'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.
  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.

  CREATE OBJECT go_splitter
    EXPORTING
      parent  = go_con
      rows    = 2
      columns = 1.

  go_con_top = go_splitter->get_container(
                  row    = 1
                  column = 1 ).

  go_con_bot = go_splitter->get_container(
                  row    = 2
                  column = 1 ).
  """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  CREATE OBJECT go_alv_top
    EXPORTING
      i_parent          = go_con_top
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.

  CREATE OBJECT go_alv_bot
    EXPORTING
      i_parent          = go_con_bot
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_event_handler
*&---------------------------------------------------------------------*
*& 이벤트 핸들러 등록
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_event_handler .
  SET HANDLER lcl_event_handler=>on_data_changed FOR go_alv_bot.
  SET HANDLER lcl_event_handler=>on_toolbar_bot FOR go_alv_bot.
  SET HANDLER lcl_event_handler=>on_user_command FOR go_alv_bot.
  go_alv_bot->register_edit_event(
    EXPORTING
      i_event_id = cl_gui_alv_grid=>mc_evt_modified
  ).

  SET HANDLER lcl_event_handler=>on_toolbar FOR go_alv_top.
  SET HANDLER lcl_event_handler=>on_user_command FOR go_alv_top.
  PERFORM exclude_toolbar_bot.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_variant
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_variant .

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout
*&---------------------------------------------------------------------*
*& ALV layout 등록
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout .
  gs_layo_top-zebra = 'X'.
  gs_layo_top-sel_mode = 'A'.
*  gs_layo_top-cwidth_opt = 'X'.

  gs_layo_bot-zebra = 'X'.
  gs_layo_bot-sel_mode = 'A'.
*  gs_layo_bot-cwidth_opt = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog
*&---------------------------------------------------------------------*
*& 기본 필드카탈로그 세팅
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog .
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        =
      i_structure_name       = 'ZSMMA00030'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     = 'X'
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = gt_fcat_top
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        =
      i_structure_name       = 'ZSMMA00030'
*     I_CLIENT_NEVER_DISPLAY = 'X'
*     I_BYPASSING_BUFFER     = 'X'
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = gt_fcat_bot
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  PERFORM zz_set_gr_fcat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& ALV 출력
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  CALL METHOD go_alv_top->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layo_top
    CHANGING
      it_outtab                     = gt_alv_top
      it_fieldcatalog               = gt_fcat_top
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.

  CALL METHOD go_alv_bot->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layo_bot
      it_toolbar_excluding          = gt_exclude_bot
    CHANGING
      it_outtab                     = gt_alv_bot
      it_fieldcatalog               = gt_fcat_bot
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE a099.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_data
*&---------------------------------------------------------------------*
*& 기본 데이터 얻기
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_data .

  DATA : lt_quantity TYPE TABLE OF gty_move.

  REFRESH : gt_040, gt_alv_bot, gt_alv_top, gt_header, gt_item, gt_quantity.
  ""구매오더에 대해서 자재 이름, 공장 이름, 창고 이름 등등 가져옴.
  SELECT a~ebeln, a~lifnr, c~name1 AS lname, a~bedat,
         a~bukrs, a~ekorg, a~ekgrp, b~ebelp, b~matnr,
         d~maktx, b~werks, e~name1 AS wname, b~lgort,
         b~menge, b~meins, b~netpr, b~waers, b~eindt,
         b~banfn, b~bnfpo, b~ptype
    FROM ztmma00050 AS a
    INNER JOIN ztmma00060 AS b
      ON a~ebeln = b~ebeln
    INNER JOIN ztcma00010 AS c
      ON a~lifnr = c~lifnr
    INNER JOIN ztcma00020 AS d
      ON b~matnr = d~matnr
    INNER JOIN ztcma00140 AS e
      ON b~werks = e~werks
    WHERE ( a~pstat = '0010' OR a~pstat = '0030' )
      AND a~ekorg IN @so_ekorg
      AND a~ekgrp IN @so_ekgrp
      AND a~bedat IN @so_bedat
      AND b~ebeln IN @so_ebeln
      AND b~matnr IN @so_matnr
      AND b~werks IN @so_werks
      AND b~lgort IN @so_lgort
      AND b~eindt IN @so_eindt
      AND b~banfn IN @so_banfn
*      AND b~eindt < @sy-datum "10-22 추가
      AND ( @pa_ptype IS INITIAL
            OR b~ptype = @pa_ptype )
    INTO CORRESPONDING FIELDS OF TABLE @gt_alv_top.


  ""전체 입고된 po에 대해서는 삭제
  MOVE-CORRESPONDING gt_alv_top TO lt_quantity.
  SORT lt_quantity BY ebeln ebelp.
  DELETE ADJACENT DUPLICATES FROM lt_quantity COMPARING ebeln ebelp.

  IF lt_quantity IS NOT INITIAL.
    SELECT mblnr, mjahr, zeile, ebeln, ebelp, menge, meins
      FROM ztmma00090
      INTO CORRESPONDING FIELDS OF TABLE @gt_quantity
      FOR ALL ENTRIES IN @lt_quantity
      WHERE ebeln = @lt_quantity-ebeln
      AND ebelp = @lt_quantity-ebelp
      AND bwart = '101'.
  ENDIF.

  PERFORM zz_set_data.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_gr_fcat
*&---------------------------------------------------------------------*
*& 특정 필드카탈로그 수정
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_gr_fcat .

  LOOP AT gt_fcat_top ASSIGNING FIELD-SYMBOL(<ls_fcat_top>).
    CASE <ls_fcat_top>-fieldname.
      WHEN 'MENGE_I'.
        <ls_fcat_top>-no_out = 'X'.
      WHEN 'PSTAT'.
        <ls_fcat_top>-no_out = 'X'.
      WHEN 'EINDT'.
      WHEN 'PTYPE'.
        <ls_fcat_top>-no_out = 'X'.
      WHEN 'GRMEN'.
        <ls_fcat_top>-coltext = TEXT-t04.
    ENDCASE.
  ENDLOOP.

  LOOP AT gt_fcat_bot ASSIGNING FIELD-SYMBOL(<ls_fcat_bot>).
    CASE <ls_fcat_bot>-fieldname.
      WHEN 'MENGE_I'.
        <ls_fcat_bot>-edit = 'X'.
      WHEN 'PSTAT'.
        <ls_fcat_bot>-no_out = 'X'.
      WHEN 'EINDT'.
*        <ls_fcat_bot>-coltext = '예정 납기일'.
      WHEN 'MENGE'.
        <ls_fcat_bot>-no_out = 'X'.
      WHEN 'GRMEN'.
        <ls_fcat_bot>-coltext = TEXT-t05.
    ENDCASE.
  ENDLOOP.
  PERFORM zz_set_catalog_length.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_make_gr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_make_gr .
  DATA : lv_error TYPE abap_bool.
  DATA : lt_return TYPE TABLE OF bapiret2.
  CALL FUNCTION 'ZFM_MM_MATERIAL_GR'
    EXPORTING
      purchase_header = gt_header
      purchase_item   = gt_item
    TABLES
      et_return       = lt_return.

  LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ls_gr_error>)
    WHERE type = 'E' OR type = 'A' OR type = 'X'.
    MESSAGE <ls_gr_error>-message TYPE 'S' DISPLAY LIKE 'E'.
    ROLLBACK WORK.
    CALL FUNCTION 'DEQUEUE_ALL'.
    PERFORM zz_get_data.
    go_alv_top->refresh_table_display( ).
    go_alv_bot->refresh_table_display( ).
    RETURN.
  ENDLOOP.
  MESSAGE s000.
  COMMIT WORK.
  CALL FUNCTION 'DEQUEUE_ALL'.
  PERFORM zz_get_data.
  go_alv_top->refresh_table_display( ).
  go_alv_bot->refresh_table_display( ).



ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_make_header
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_make_header .
  REFRESH : gt_header, gt_item.
  go_alv_bot->check_changed_data( ).
  LOOP AT gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_alv>).
    READ TABLE gt_header WITH KEY ebeln = <ls_alv>-ebeln TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      APPEND INITIAL LINE TO gt_header ASSIGNING FIELD-SYMBOL(<ls_header>).
      <ls_header>-ebeln = <ls_alv>-ebeln.
      <ls_header>-lifnr = <ls_alv>-lifnr.
      <ls_header>-bedat = <ls_alv>-bedat.
      <ls_header>-bukrs = <ls_alv>-bukrs.
      <ls_header>-ekorg = <ls_alv>-ekorg.
      <ls_header>-ekgrp = <ls_alv>-ekgrp.
      <ls_header>-pstat = <ls_alv>-pstat.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_make_item
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_make_item CHANGING pv_answer.
  LOOP AT gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_alv>).
    IF <ls_alv>-menge_i = 0.
      MESSAGE s020 WITH TEXT-t07 DISPLAY LIKE 'E'.
      pv_answer = abap_true.
      RETURN.
    ENDIF.
    APPEND INITIAL LINE TO gt_item ASSIGNING FIELD-SYMBOL(<ls_item>).

    <ls_item>-ebeln = <ls_alv>-ebeln.
    <ls_item>-ebelp = <ls_alv>-ebelp.
    <ls_item>-matnr = <ls_alv>-matnr.
    <ls_item>-werks = <ls_alv>-werks.
    <ls_item>-lgort = <ls_alv>-lgort.
    <ls_item>-menge = <ls_alv>-menge.
    <ls_item>-menge_i = <ls_alv>-menge_i.
    <ls_item>-meins = <ls_alv>-meins.

    <ls_item>-netpr = <ls_alv>-netpr.
    <ls_item>-waers = <ls_alv>-waers.
    <ls_item>-eindt = <ls_alv>-eindt.
    <ls_item>-banfn = <ls_alv>-banfn.
    <ls_item>-bnfpo = <ls_alv>-bnfpo.
    <ls_item>-ptype = <ls_alv>-ptype.

  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_gr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_gr .
  DATA: lt_selected   TYPE lvc_t_row,
        lv_move_count TYPE i,
        lv_fail_count TYPE i.

  go_alv_top->get_selected_rows(
    IMPORTING
      et_index_rows = lt_selected
  ).

  IF lt_selected IS INITIAL.
    MESSAGE s110 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "삭제할 행의 INDEX 밀림 방지
  SORT lt_selected BY index DESCENDING.

  LOOP AT lt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).

    READ TABLE gt_alv_top ASSIGNING FIELD-SYMBOL(<ls_top>)
      INDEX <ls_selected>-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    "PO 장바구니 행 생성
    APPEND INITIAL LINE TO gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_bot>).

    MOVE-CORRESPONDING <ls_top> TO <ls_bot>.
    <ls_bot>-grmen = <ls_top>-menge - <ls_top>-grmen.
    <ls_bot>-menge_i = <ls_bot>-grmen.
    "상단 PR ALV에서만 제거
    DELETE gt_alv_top INDEX <ls_selected>-index.

    lv_move_count = lv_move_count + 1.

  ENDLOOP.


  IF lv_move_count > 0.
    MESSAGE s111 WITH lv_move_count.
  ENDIF.

  IF lv_fail_count > 0.
    MESSAGE s112 WITH lv_fail_count DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form delete_gr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM delete_gr .
  DATA: lt_selected    TYPE lvc_t_row,
        lv_gr_save_idx TYPE sy-tabix,
        lv_move_count  TYPE i.

  go_alv_bot->get_selected_rows(
    IMPORTING
      et_index_rows = lt_selected
  ).

  IF lt_selected IS INITIAL.
    MESSAGE s113 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "PO 장바구니 행 삭제 시 INDEX 밀림 방지
  SORT lt_selected BY index DESCENDING.

  LOOP AT lt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).

    READ TABLE gt_alv_bot ASSIGNING FIELD-SYMBOL(<ls_alv_bot>)
      INDEX <ls_selected>-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.


    APPEND INITIAL LINE TO gt_alv_top ASSIGNING FIELD-SYMBOL(<ls_alv_top>).

    MOVE-CORRESPONDING <ls_alv_bot> TO <ls_alv_top>.


    "하단 PO 장바구니에서 제거
    DELETE gt_alv_bot INDEX <ls_selected>-index.

    lv_move_count = lv_move_count + 1.

  ENDLOOP.
  SORT gt_alv_top BY ebeln ebelp.
  MESSAGE s114 WITH lv_move_count.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_data .

  DATA : lt_quantity TYPE TABLE OF gty_move.
*READ TABLE gt_alv_pr WITH KEY idx01 COMPONENTS banfn = <ls_alv_po>-banfn
*                                               bnfpo = <ls_alv_po>-bnfpo TRANSPORTING NO FIELDS
  LOOP AT gt_quantity ASSIGNING FIELD-SYMBOL(<ls_quantity>).
    READ TABLE lt_quantity ASSIGNING FIELD-SYMBOL(<ls_q>) WITH KEY ebeln = <ls_quantity>-ebeln
                                                                   ebelp = <ls_quantity>-ebelp.
    IF sy-subrc <> 0.
      APPEND INITIAL LINE TO lt_quantity ASSIGNING FIELD-SYMBOL(<ls_qu>).
      <ls_qu>-ebeln = <ls_quantity>-ebeln.
      <ls_qu>-ebelp = <ls_quantity>-ebelp.
      <ls_qu>-menge = <ls_quantity>-menge.
      <ls_qu>-meins = <ls_quantity>-meins.
    ELSE.
      <ls_q>-menge += <ls_quantity>-menge.
    ENDIF.
  ENDLOOP.

  LOOP AT gt_alv_top ASSIGNING FIELD-SYMBOL(<ls_alv_top>).
    READ TABLE lt_quantity ASSIGNING FIELD-SYMBOL(<ls_qua>) WITH KEY ebeln = <ls_alv_top>-ebeln
                                                                     ebelp = <ls_alv_top>-ebelp.
    IF sy-subrc = 0.
      <ls_alv_top>-grmen = <ls_qua>-menge.
    ENDIF.

    IF <ls_alv_top>-grmen >= <ls_alv_top>-menge.
      DELETE gt_alv_top.
    ENDIF.
  ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form exclude_toolbar_bot
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM exclude_toolbar_bot .
  CLEAR gt_exclude_bot.

  "아래 ALV에만 뜨는 편집용 표준 버튼 제거
  APPEND cl_gui_alv_grid=>mc_fc_refresh           TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy          TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row      TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut           TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste         TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo          TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row    TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row    TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row    TO gt_exclude_bot.
  APPEND cl_gui_alv_grid=>mc_fc_loc_move_row      TO gt_exclude_bot.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_catalog_length
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_catalog_length .
  LOOP AT gt_fcat_top ASSIGNING FIELD-SYMBOL(<ls_fcat_top>).

    CASE <ls_fcat_top>-fieldname.
      WHEN 'EBELN'.
        <ls_fcat_top>-outputlen = 5.
      WHEN 'EBELP'.
        <ls_fcat_top>-outputlen = 2.
      WHEN 'LIFNR'.
        <ls_fcat_top>-outputlen = 6.
      WHEN 'LNAME'.
        <ls_fcat_top>-outputlen = 6.
      WHEN 'MATNR'.
        <ls_fcat_top>-outputlen = 10.
      WHEN 'MAKTX'.
        <ls_fcat_top>-outputlen = 10.
      WHEN 'WERKS'.
        <ls_fcat_top>-outputlen = 2.
      WHEN 'WNAME'.
        <ls_fcat_top>-outputlen = 4.
      WHEN 'LGORT'.
        <ls_fcat_top>-outputlen = 2.
      WHEN 'MENGE'.
        <ls_fcat_top>-outputlen = 4.
      WHEN 'GRMEN'.
        <ls_fcat_top>-outputlen = 4.
      WHEN 'MENGE_I'.
        <ls_fcat_top>-outputlen = 4.
      WHEN 'MEINS'.
        <ls_fcat_top>-coltext   = TEXT-t08.
        <ls_fcat_top>-outputlen = 2.
      WHEN 'NETPR'.
        <ls_fcat_top>-outputlen = 6.
      WHEN 'WAERS'.
        <ls_fcat_top>-outputlen = 2.
      WHEN 'EINDT'.
        <ls_fcat_top>-outputlen = 4.
      WHEN 'BEDAT'.
        <ls_fcat_top>-outputlen = 4.
      WHEN 'BUKRS'.
        <ls_fcat_top>-outputlen = 2.
        <ls_fcat_top>-no_out    = 'X'.
      WHEN 'EKORG'.
        <ls_fcat_top>-outputlen = 2.
        <ls_fcat_top>-no_out    = 'X'.
      WHEN 'EKGRP'.
        <ls_fcat_top>-outputlen = 2.
        <ls_fcat_top>-no_out    = 'X'.
      WHEN 'PSTAT'.
        <ls_fcat_top>-outputlen = 2.
      WHEN 'BANFN'.
        <ls_fcat_top>-outputlen = 2.
      WHEN 'BNFPO'.
        <ls_fcat_top>-outputlen = 1.
      WHEN 'PTYPE'.
        <ls_fcat_top>-outputlen = 2.
    ENDCASE.

  ENDLOOP.


  LOOP AT gt_fcat_bot ASSIGNING FIELD-SYMBOL(<ls_fcat_bot>).

    CASE <ls_fcat_bot>-fieldname.
      WHEN 'EBELN'.
        <ls_fcat_bot>-outputlen = 5.
      WHEN 'EBELP'.
        <ls_fcat_bot>-outputlen = 2.
      WHEN 'LIFNR'.
        <ls_fcat_bot>-outputlen = 6.
      WHEN 'LNAME'.
        <ls_fcat_bot>-outputlen = 6.
      WHEN 'MATNR'.
        <ls_fcat_bot>-outputlen = 10.
      WHEN 'MAKTX'.
        <ls_fcat_bot>-outputlen = 10.
      WHEN 'WERKS'.
        <ls_fcat_bot>-outputlen = 2.
      WHEN 'WNAME'.
        <ls_fcat_bot>-outputlen = 4.
      WHEN 'LGORT'.
        <ls_fcat_bot>-outputlen = 2.
      WHEN 'MENGE'.
        <ls_fcat_bot>-outputlen = 4.
      WHEN 'GRMEN'.
        <ls_fcat_bot>-outputlen = 4.
      WHEN 'MENGE_I'.
        <ls_fcat_bot>-outputlen = 4.
      WHEN 'MEINS'.
        <ls_fcat_bot>-outputlen = 2.
        <ls_fcat_bot>-coltext   = TEXT-t08.
      WHEN 'NETPR'.
        <ls_fcat_bot>-outputlen = 6.
      WHEN 'WAERS'.
        <ls_fcat_bot>-outputlen = 2.
      WHEN 'EINDT'.
        <ls_fcat_bot>-outputlen = 4.
      WHEN 'BEDAT'.
        <ls_fcat_bot>-outputlen = 4.
      WHEN 'BUKRS'.
        <ls_fcat_bot>-outputlen = 2.
        <ls_fcat_bot>-no_out    = 'X'.
      WHEN 'EKORG'.
        <ls_fcat_bot>-outputlen = 2.
        <ls_fcat_bot>-no_out    = 'X'.
      WHEN 'EKGRP'.
        <ls_fcat_bot>-outputlen = 2.
        <ls_fcat_bot>-no_out    = 'X'.
      WHEN 'PSTAT'.
        <ls_fcat_bot>-outputlen = 2.
      WHEN 'BANFN'.
        <ls_fcat_bot>-outputlen = 2.
      WHEN 'BNFPO'.
        <ls_fcat_bot>-outputlen = 1.
      WHEN 'PTYPE'.
        <ls_fcat_bot>-outputlen = 2.
    ENDCASE.

  ENDLOOP.
ENDFORM.
