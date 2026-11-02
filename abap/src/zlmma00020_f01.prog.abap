*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form zz_get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_data .
  SELECT *
    FROM ztmma00040 AS pr
    INNER JOIN ztcma00020 AS mat
      ON mat~matnr = pr~matnr
    INNER JOIN ztcma00140 AS wer
      ON wer~werks = pr~werks
    INNER JOIN ztcma00150 AS lgo
      ON lgo~lgort = pr~lgort
     AND lgo~werks = pr~werks
    INTO CORRESPONDING FIELDS OF TABLE @gt_alv_pr
    WHERE pr~banfn IN @so_banfn
      AND pr~matnr IN @so_matnr
      AND pr~werks IN @so_werks
      AND pr~lgort IN @so_lgort
      AND pr~rdate IN @so_rdate
      AND pr~ndate IN @so_ndate
      AND pr~astat = '0020'  "승인완료
      AND pr~pstat = '0030'. "PO 생성 전


ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_po .

  DATA: lt_selected       TYPE lvc_t_row,
        ls_best_candidate TYPE zsmma00045,
        lv_arrival_date   TYPE datum,
        lv_move_count     TYPE i,
        lv_fail_count     TYPE i.

  go_alv_pr->get_selected_rows(
    IMPORTING
      et_index_rows = lt_selected
  ).

  IF lt_selected IS INITIAL.
    MESSAGE 'PO 생성할 구매요청을 선택하세요.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "삭제할 행의 INDEX 밀림 방지
  SORT lt_selected BY index DESCENDING.

  LOOP AT lt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).

    READ TABLE gt_alv_pr ASSIGNING FIELD-SYMBOL(<ls_pr>)
      INDEX <ls_selected>-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    CLEAR: ls_best_candidate,
           lv_arrival_date.

    LOOP AT gt_lifnr ASSIGNING FIELD-SYMBOL(<ls_candidate>)
      WHERE matnr = <ls_pr>-matnr.

      "SO 참조 건은 납기 가능 업체만 후보
      IF <ls_pr>-srdoc IS NOT INITIAL.

        lv_arrival_date = sy-datum + <ls_candidate>-plifz.

        IF lv_arrival_date > <ls_pr>-ndate.
          CONTINUE.
        ENDIF.

      ENDIF.

      "종합점수 우선, 동점이면 우선순위 숫자가 작은 업체
      IF ls_best_candidate-lifnr IS INITIAL
      OR <ls_candidate>-tscor > ls_best_candidate-tscor
      OR ( <ls_candidate>-tscor = ls_best_candidate-tscor
       AND <ls_candidate>-priok < ls_best_candidate-priok ).

        ls_best_candidate = <ls_candidate>.

      ENDIF.

    ENDLOOP.

    IF ls_best_candidate-lifnr IS INITIAL.
      lv_fail_count = lv_fail_count + 1.
      CONTINUE.
    ENDIF.

    "PO 장바구니 행 생성
    APPEND INITIAL LINE TO gt_alv_po
      ASSIGNING FIELD-SYMBOL(<ls_po>).

    MOVE-CORRESPONDING <ls_pr> TO <ls_po>.

    <ls_po>-lifnr = ls_best_candidate-lifnr.
    <ls_po>-netpr = ls_best_candidate-netpr.
    <ls_po>-waers = ls_best_candidate-waers.
    <ls_po>-plifz = ls_best_candidate-plifz.
    <ls_po>-bstmi = ls_best_candidate-bstmi.
    <ls_po>-meins = ls_best_candidate-meins.
    <ls_po>-wname = <ls_pr>-name1.
    <ls_po>-lname = ls_best_candidate-name1.

    "발주 확정 시 한 번에 MODIFY 할 PR 원본 보관
    APPEND INITIAL LINE TO gt_pr_save
      ASSIGNING FIELD-SYMBOL(<ls_pr_save>).

    MOVE-CORRESPONDING <ls_pr> TO <ls_pr_save>.

    "상단 PR ALV에서만 제거
    DELETE gt_alv_pr INDEX <ls_selected>-index.

    lv_move_count = lv_move_count + 1.

  ENDLOOP.


  IF lv_move_count > 0.
    MESSAGE |{ lv_move_count }건을 PO 생성 대상으로 이동했습니다.|
      TYPE 'S'.
  ENDIF.

  IF lv_fail_count > 0.
    MESSAGE |{ lv_fail_count }건은 납기 가능한 공급업체가 없어 PR 목록에 남았습니다.|
      TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_lifnr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_lifnr .

  DATA lt_pr LIKE gt_alv_pr.

  lt_pr = gt_alv_pr.

  SORT lt_pr BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_pr COMPARING matnr.

  CLEAR gt_lifnr.

  IF lt_pr IS NOT INITIAL.

    SELECT vm~matnr, mat~maktx, vm~lifnr, ven~name1, vm~valfr,
           vm~valto, vm~beskz, vm~priok, vm~netpr, vm~waers,
           vm~plifz, vm~bstmi, vm~meins, vm~actyn, vm~inrsn,
           ev~vevno, ev~datab, ev~datbi, ev~dscor, ev~qscor,
           ev~pscor, ev~tscor, ev~grade, ev~znote
      FROM ztcma00040 AS vm
      INNER JOIN ztcma00010 AS ven
        ON ven~lifnr = vm~lifnr
      INNER JOIN ztcma00020 AS mat
        ON mat~matnr = vm~matnr
      LEFT OUTER JOIN ztmma00100 AS ev
        ON  ev~lifnr = vm~lifnr
        AND ev~datab <= @sy-datum
        AND ev~datbi >= @sy-datum
      FOR ALL ENTRIES IN @lt_pr
      WHERE vm~matnr = @lt_pr-matnr
        AND vm~actyn = 'Y'
        AND vm~valfr <= @sy-datum
        AND vm~valto >= @sy-datum
      INTO CORRESPONDING FIELDS OF TABLE @gt_lifnr.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_tree_column
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_tree_column .

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'NETPR'
      width       = 16
      header_text = '계약단가'.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'WAERS'
      width       = 5
      header_text = '통화'.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'PLIFZ'
      width       = 6
      header_text = '납기일'.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'TSCOR'
      width       = 7
      header_text = '종합점수'.

  CALL METHOD go_tree->add_column
    EXPORTING
      name        = 'GRADE'
      width       = 4
      header_text = '등급'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_vendor_tree
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_vendor_tree .

  DATA: lt_node       TYPE treev_ntab,
        ls_node       TYPE treev_node,
        lt_item       TYPE STANDARD TABLE OF mtreeitm,
        ls_candidate  TYPE zsmma00045,
        lv_prev_matnr TYPE matnr,
        lv_root_key   TYPE tv_nodekey,
        lv_child_key  TYPE tv_nodekey,
        lv_node_count TYPE i,
        lv_netpr_text TYPE c LENGTH 20.

  CLEAR gt_tree_map.

  SORT gt_lifnr BY matnr lifnr.

  LOOP AT gt_lifnr INTO ls_candidate.

    "자재별 부모 노드
    IF lv_prev_matnr <> ls_candidate-matnr.

      lv_node_count = lv_node_count + 1.
      lv_root_key = |MAT{ lv_node_count }|.

      CLEAR ls_node.
      ls_node-node_key  = lv_root_key.
      ls_node-relatship = cl_gui_column_tree=>relat_last_sibling.
      ls_node-isfolder  = 'X'.
      APPEND ls_node TO lt_node.

      APPEND VALUE mtreeitm(
        node_key  = lv_root_key
        item_name = 'HEADTEXT'
        class     = cl_gui_column_tree=>item_class_text
        text      = |{ ls_candidate-matnr } { ls_candidate-maktx }|
      ) TO lt_item.

      lv_prev_matnr = ls_candidate-matnr.

    ENDIF.

    "공급업체 자식 노드
    lv_node_count = lv_node_count + 1.
    lv_child_key = |VEN{ lv_node_count }|.

    "트리 노드와 공급업체 번호 연결
    INSERT VALUE ty_tree_map(
      node_key = lv_child_key
      node_type = 'V'
      matnr     = ls_candidate-matnr
      lifnr    = ls_candidate-lifnr
    ) INTO TABLE gt_tree_map.

    CLEAR ls_node.
    ls_node-node_key  = lv_child_key.
    ls_node-relatkey  = lv_root_key.
    ls_node-relatship = cl_gui_column_tree=>relat_last_child.
    APPEND ls_node TO lt_node.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'HEADTEXT'
      class     = cl_gui_column_tree=>item_class_text
      text      = ls_candidate-name1
    ) TO lt_item.

    CLEAR lv_netpr_text.

    WRITE ls_candidate-netpr TO lv_netpr_text
      CURRENCY ls_candidate-waers.

    CONDENSE lv_netpr_text.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'NETPR'
      class     = cl_gui_column_tree=>item_class_text
      text      = lv_netpr_text
    ) TO lt_item.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'WAERS'
      class     = cl_gui_column_tree=>item_class_text
      text      = ls_candidate-waers
    ) TO lt_item.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'PLIFZ'
      class     = cl_gui_column_tree=>item_class_text
      text      = |{ ls_candidate-plifz }일|
    ) TO lt_item.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'TSCOR'
      class     = cl_gui_column_tree=>item_class_text
      text      = ls_candidate-tscor
    ) TO lt_item.

    APPEND VALUE mtreeitm(
      node_key  = lv_child_key
      item_name = 'GRADE'
      class     = cl_gui_column_tree=>item_class_text
      text      = ls_candidate-grade
    ) TO lt_item.

  ENDLOOP.

  CALL METHOD go_tree->add_nodes_and_items
    EXPORTING
      node_table                = lt_node
      item_table                = lt_item
      item_table_structure_name = 'MTREEITM'.

  CALL METHOD go_tree->expand_root_nodes.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_create_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_create_po .
  DATA : lt_mma00050 TYPE TABLE OF ztmma00050 WITH NON-UNIQUE SORTED KEY
            idx01 COMPONENTS lifnr,
         lt_mma00060 TYPE TABLE OF ztmma00060 WITH NON-UNIQUE SORTED KEY
            idx01 COMPONENTS ebeln,
         lt_po_seq   TYPE HASHED TABLE OF ty_po_seq WITH UNIQUE KEY ebeln,
         ls_po_seq   TYPE ty_po_seq.

  DATA : lt_pr_save TYPE TABLE OF ztmma00040.
  DATA : lv_error TYPE abap_bool.


  LOOP AT gt_alv_po ASSIGNING FIELD-SYMBOL(<ls_alv_po>).
    READ TABLE lt_mma00050 ASSIGNING FIELD-SYMBOL(<ls_mma00050>)
      WITH TABLE KEY idx01
      COMPONENTS lifnr = <ls_alv_po>-lifnr.

    IF sy-subrc <> 0.

      APPEND INITIAL LINE TO lt_mma00050
        ASSIGNING <ls_mma00050>.

      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING
          nr_range_nr = '01'
          object      = 'ZMM_EBELN'
        IMPORTING
          number      = <ls_mma00050>-ebeln
        EXCEPTIONS
          OTHERS      = 8.

      IF sy-subrc <> 0.
        MESSAGE e311.
      ENDIF.

      "신규 공급업체일 때만 헤더 세팅
      PERFORM zz_set_po_header USING <ls_alv_po>
                               CHANGING <ls_mma00050>.

    ENDIF.
    APPEND INITIAL LINE TO lt_mma00060 ASSIGNING FIELD-SYMBOL(<ls_mma00060>).


    READ TABLE lt_po_seq INTO ls_po_seq WITH TABLE KEY ebeln = <ls_mma00050>-ebeln.

    IF sy-subrc <> 0.
      ls_po_seq-ebeln = <ls_mma00050>-ebeln.
      ls_po_seq-ebelp = 10.
      INSERT ls_po_seq INTO TABLE lt_po_seq.
    ELSE.
      ls_po_seq-ebeln = <ls_mma00050>-ebeln.
      ls_po_seq-ebelp = ls_po_seq-ebelp + 10.
      MODIFY TABLE lt_po_seq FROM ls_po_seq.
    ENDIF.

    PERFORM zz_set_po_item   USING <ls_alv_po>
                                   <ls_mma00050>
                                   ls_po_seq-ebelp
                          CHANGING <ls_mma00060>.



  ENDLOOP.

  PERFORM zz_set_pr_statu.
  MOVE-CORRESPONDING gt_pr_save TO lt_pr_save.
  MODIFY ztmma00050 FROM TABLE lt_mma00050.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    RETURN.
  ENDIF.
  MODIFY ztmma00060 FROM TABLE lt_mma00060.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    RETURN.
  ENDIF.
  MODIFY ztmma00040 FROM TABLE lt_pr_save.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    RETURN.
  ELSE.
    COMMIT WORK.
    PERFORM zz_get_all_data.
    go_alv_pr->refresh_table_display( ).
    go_alv_po->refresh_table_display( ).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_po_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- <LS_MMA00050>
*&---------------------------------------------------------------------*
FORM zz_set_po_header    USING ps_alv_po   TYPE zsmma00044
                      CHANGING ps_mma00050 TYPE ztmma00050.

  ps_mma00050-lifnr = ps_alv_po-lifnr.
  ps_mma00050-bedat = sy-datum.
*  ps_mma00050-ekorg = .
*  ps_mma00050-bukrs = .
  ps_mma00050-ekgrp = ps_alv_po-ekgrp.
  ps_mma00050-pstat = '0010'.

  ps_mma00050-ernam = sy-uname.
  ps_mma00050-erdat = sy-datum.
  ps_mma00050-erzet = sy-uzeit.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_po_item
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> <LS_ALV_PO>
*&      <-- <LS_MMA00050>
*&---------------------------------------------------------------------*
FORM zz_set_po_item  USING    ps_alv_po   TYPE zsmma00044
                              ps_mma00050 TYPE ztmma00050
                              pv_ebelp    TYPE ebelp
                     CHANGING ps_mma00060 TYPE ztmma00060.


  READ TABLE gt_lifnr ASSIGNING FIELD-SYMBOL(<ls_lifnr>)
    WITH TABLE KEY idx01 COMPONENTS lifnr = ps_mma00050-lifnr.

  ps_mma00060-ebeln = ps_mma00050-ebeln.
  ps_mma00060-ebelp = pv_ebelp.
  ps_mma00060-matnr = ps_alv_po-matnr.
  ps_mma00060-werks = ps_alv_po-werks.
  ps_mma00060-lgort = ps_alv_po-lgort.
  ps_mma00060-menge = ps_alv_po-rqty.
  ps_mma00060-meins = ps_alv_po-meins.
  ps_mma00060-netpr = ps_alv_po-netpr.
  ps_mma00060-waers = ps_alv_po-waers.
  ps_mma00060-eindt = <ls_lifnr>-plifz + sy-datum.
  ps_mma00060-banfn = ps_alv_po-banfn.
  ps_mma00060-bnfpo = ps_alv_po-bnfpo.
  ps_mma00060-ptype = ps_alv_po-ptype.

  ps_mma00060-ernam = sy-uname.
  ps_mma00060-erdat = sy-datum.
  ps_mma00060-erzet = sy-uzeit.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_set_pr_statu
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_pr_statu .
  LOOP AT gt_pr_save ASSIGNING FIELD-SYMBOL(<ls_pr_save>).
    <ls_pr_save>-pstat = '0040'.
    <ls_pr_save>-aenam = sy-uname.
    <ls_pr_save>-aedat = sy-datum.
    <ls_pr_save>-aezet = sy-uzeit.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form delete_po
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM delete_po .

  DATA: lt_selected    TYPE lvc_t_row,
        lv_pr_save_idx TYPE sy-tabix,
        lv_move_count  TYPE i.

  go_alv_po->get_selected_rows(
    IMPORTING
      et_index_rows = lt_selected
  ).

  IF lt_selected IS INITIAL.
    MESSAGE '삭제할 PO 생성 대상을 선택하세요.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "PO 장바구니 행 삭제 시 INDEX 밀림 방지
  SORT lt_selected BY index DESCENDING.

  LOOP AT lt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).

    READ TABLE gt_alv_po ASSIGNING FIELD-SYMBOL(<ls_alv_po>)
      INDEX <ls_selected>-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    "장바구니로 내릴 때 보관한 원본 PR 찾기
    READ TABLE gt_pr_save ASSIGNING FIELD-SYMBOL(<ls_pr_save>)
      WITH KEY banfn = <ls_alv_po>-banfn
               bnfpo = <ls_alv_po>-bnfpo.

    IF sy-subrc = 0.

      lv_pr_save_idx = sy-tabix.

      "이미 상단에 있지 않을 때만 복귀
      READ TABLE gt_alv_pr WITH KEY idx01 COMPONENTS banfn = <ls_alv_po>-banfn
                                                     bnfpo = <ls_alv_po>-bnfpo TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.

        APPEND INITIAL LINE TO gt_alv_pr
          ASSIGNING FIELD-SYMBOL(<ls_alv_pr>).

        MOVE-CORRESPONDING <ls_pr_save> TO <ls_alv_pr>.

      ENDIF.

      "발주 확정 시 MODIFY할 대상에서도 제외
      DELETE gt_pr_save INDEX lv_pr_save_idx.

    ENDIF.

    "하단 PO 장바구니에서 제거
    DELETE gt_alv_po INDEX <ls_selected>-index.

    lv_move_count = lv_move_count + 1.

  ENDLOOP.

  MESSAGE |{ lv_move_count }건을 PR 목록으로 되돌렸습니다.|
    TYPE 'S'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form register_tree_event
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM register_tree_event .

  DATA: lt_events TYPE cntl_simple_events,
        ls_event  TYPE cntl_simple_event.

  CLEAR ls_event.

  ls_event-eventid = cl_gui_column_tree=>eventid_item_double_click.
  APPEND ls_event TO lt_events.

  go_tree->set_registered_events(
    EXPORTING
      events = lt_events
  ).

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_show_vendor_history
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_TREE_MAP_LIFNR
*&---------------------------------------------------------------------*
FORM zz_show_vendor_history
  USING pv_matnr TYPE matnr
        pv_lifnr TYPE lifnr.

  CLEAR gt_history.

  SELECT a~lifnr,
         a~ebeln,
         b~ebelp,
         a~bedat,
         a~bukrs,
         a~ekorg,
         a~ekgrp,
         b~matnr,
         mat~maktx,
         b~werks,
         wer~name1 AS wname,
         b~lgort,
         lgo~lgobe AS lname,
         b~menge,
         b~meins,
         b~netpr,
         b~waers
    FROM ztmma00050 AS a
    INNER JOIN ztmma00060 AS b
      ON b~ebeln = a~ebeln
    INNER JOIN ztcma00020 AS mat
      ON mat~matnr = b~matnr
    INNER JOIN ztcma00140 AS wer
      ON wer~werks = b~werks
    INNER JOIN ztcma00150 AS lgo
      ON lgo~werks = b~werks
     AND lgo~lgort = b~lgort
    WHERE a~lifnr = @pv_lifnr
      AND b~matnr = @pv_matnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_history.

  IF gt_history IS INITIAL.
    MESSAGE '해당 공급업체의 해당 자재 거래 이력이 없습니다.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL SCREEN 200 STARTING AT 5 5.

ENDFORM.
*&---------------------------------------------------------------------*
*& Module DISPLAY_HISTORY_ALV OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
FORM display_history_alv.

  IF go_con_history IS INITIAL.

    CREATE OBJECT go_con_history
      EXPORTING
        container_name = 'CUSTOM_RECORD'.

    CREATE OBJECT go_alv_history
      EXPORTING
        i_parent = go_con_history.

    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name = 'ZSMMA00046'
      CHANGING
        ct_fieldcat      = gt_fcat_history.

    gs_layo_history-cwidth_opt = 'X'.

    go_alv_history->set_table_for_first_display(
      EXPORTING
        is_layout       = gs_layo_history
      CHANGING
        it_outtab       = gt_history
        it_fieldcatalog = gt_fcat_history
    ).

  ELSE.

    go_alv_history->refresh_table_display( ).

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_all_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_all_data .
  REFRESH : gt_alv_pr, gt_alv_po, gt_lifnr, gt_lifnr_v, gt_pr_save, gt_history.

  PERFORM zz_get_data.
  PERFORM zz_get_lifnr.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_lifnr_f4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_lifnr_f4 USING pv_row_id TYPE lvc_s_roid-row_id.
  DATA: lt_f4_vendor    TYPE STANDARD TABLE OF ty_f4_vendor,
        lt_return       TYPE STANDARD TABLE OF ddshretval,
        ls_return       TYPE ddshretval,
        lv_arrival_date TYPE datum.

  READ TABLE gt_alv_po ASSIGNING FIELD-SYMBOL(<ls_alv_po>) INDEX pv_row_id.

  LOOP AT gt_lifnr ASSIGNING FIELD-SYMBOL(<ls_lifnr>)
    WHERE matnr = <ls_alv_po>-matnr.

    lv_arrival_date = sy-datum + <ls_lifnr>-plifz.

    IF <ls_alv_po>-srdoc IS NOT INITIAL AND lv_arrival_date > <ls_alv_po>-ndate.
      CONTINUE.
    ENDIF.

    APPEND INITIAL LINE TO lt_f4_vendor ASSIGNING FIELD-SYMBOL(<ls_f4_vendor>).

    <ls_f4_vendor>-lifnr = <ls_lifnr>-lifnr.
    <ls_f4_vendor>-name1 = <ls_lifnr>-name1.
    <ls_f4_vendor>-netpr = <ls_lifnr>-netpr.
    <ls_f4_vendor>-waers = <ls_lifnr>-waers.
    <ls_f4_vendor>-plifz = <ls_lifnr>-plifz.
    <ls_f4_vendor>-tscor = <ls_lifnr>-tscor.
    <ls_f4_vendor>-qscor = <ls_lifnr>-qscor.
    <ls_f4_vendor>-dscor = <ls_lifnr>-dscor.
    <ls_f4_vendor>-pscor = <ls_lifnr>-pscor.
    <ls_f4_vendor>-grade = <ls_lifnr>-grade.

  ENDLOOP.
  IF lt_f4_vendor IS INITIAL.
    MESSAGE '선택 가능한 공급업체가 없습니다.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield   = 'LIFNR'
      value_org  = 'S'
    TABLES
      value_tab  = lt_f4_vendor
      return_tab = lt_return.

  READ TABLE lt_return INTO ls_return INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "선택한 업체의 원본 거래조건 찾기
  READ TABLE gt_lifnr ASSIGNING <ls_lifnr>
    WITH KEY matnr = <ls_alv_po>-matnr
             lifnr = ls_return-fieldval.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  "선택 행(gt_alv_po)에 최종 반영
  <ls_alv_po>-lifnr = <ls_lifnr>-lifnr.
  <ls_alv_po>-lname = <ls_lifnr>-name1.
  <ls_alv_po>-netpr = <ls_lifnr>-netpr.
  <ls_alv_po>-waers = <ls_lifnr>-waers.
  <ls_alv_po>-plifz = <ls_lifnr>-plifz.
  <ls_alv_po>-bstmi = <ls_lifnr>-bstmi.
  <ls_alv_po>-meins = <ls_lifnr>-meins.
ENDFORM.
