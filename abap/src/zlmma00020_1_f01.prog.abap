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
*  SELECT *
*    FROM ztmma00040 AS pr
*    INNER JOIN ztcma00020 AS mat
*      ON mat~matnr = pr~matnr
*    INNER JOIN ztcma00140 AS wer
*      ON wer~werks = pr~werks
*    INNER JOIN ztcma00150 AS lgo
*      ON lgo~lgort = pr~lgort
*     AND lgo~werks = pr~werks
*    INTO CORRESPONDING FIELDS OF TABLE @gt_pr
*    WHERE pr~banfn IN @so_banfn
*      AND pr~matnr IN @so_matnr
*      AND pr~werks IN @so_werks
*      AND pr~lgort IN @so_lgort
*      AND pr~rdate IN @so_rdate
*      AND pr~ndate IN @so_ndate
*      AND pr~astat = '0020'  "승인완료
*      AND pr~pstat = '0030' "PO 생성 전
*    ORDER BY banfn DESCENDING.
  SELECT *
    FROM zvmma00010
    INTO CORRESPONDING FIELDS OF TABLE @gt_pr
    WHERE banfn IN @so_banfn
      AND matnr IN @so_matnr
      AND werks IN @so_werks
      AND lgort IN @so_lgort
      AND rdate IN @so_rdate
      AND ndate IN @so_ndate
      AND astat = '0020'  "승인완료
      AND pstat = '0030'  "PO 생성 전
    ORDER BY banfn DESCENDING.
  gt_pr_show = gt_pr.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_po
*&---------------------------------------------------------------------*
*& 장바구니 생성
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
    MESSAGE s109 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  ""입고 추가 버튼 CRPO 클릭 시에 선택된 행들의 공급 업체 설정 및 장바구니 추가
  "종합점수 우선, 동점이면 우선순위 숫자가 작은 업체
  "SO 참조 건은 납기 가능 업체만 후보
  LOOP AT lt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).
    CLEAR: ls_best_candidate, lv_arrival_date.
    READ TABLE gt_pr ASSIGNING FIELD-SYMBOL(<ls_pr>) INDEX <ls_selected>-index.
    IF sy-subrc = 0.
    ELSE.
      CONTINUE.
    ENDIF.

    LOOP AT gt_lifnr ASSIGNING FIELD-SYMBOL(<ls_candidate>)
      WHERE matnr = <ls_pr>-matnr.

*      IF <ls_pr>-srdoc IS NOT INITIAL. "" 10-28 수정 본.
      IF <ls_pr>-ndate IS NOT INITIAL.

        lv_arrival_date = sy-datum + <ls_candidate>-plifz.

        IF lv_arrival_date > <ls_pr>-ndate.
          CONTINUE.
        ENDIF.

      ENDIF.

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
    APPEND INITIAL LINE TO gt_po ASSIGNING FIELD-SYMBOL(<ls_po>).

    MOVE-CORRESPONDING <ls_pr> TO <ls_po>.

    <ls_po>-lifnr = ls_best_candidate-lifnr.
    <ls_po>-netpr = ls_best_candidate-netpr.
    <ls_po>-waers = ls_best_candidate-waers.
    <ls_po>-plifz = ls_best_candidate-plifz.
    <ls_po>-bstmi = ls_best_candidate-bstmi.
    <ls_po>-meins = ls_best_candidate-meins.
    <ls_po>-wname = <ls_pr>-name1.
    <ls_po>-lname = ls_best_candidate-name1.



    "상단 PR ALV에서만 제거
    DELETE gt_pr_show WHERE banfn = <ls_pr>-banfn
                        AND bnfpo = <ls_pr>-bnfpo.

    lv_move_count = lv_move_count + 1.

  ENDLOOP.


  IF lv_move_count > 0.
    MESSAGE s108 WITH lv_move_count.
  ENDIF.

  IF lv_fail_count > 0.
    MESSAGE s107 WITH lv_fail_count DISPLAY LIKE 'E'.
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

  DATA lt_pr LIKE gt_pr.

  lt_pr = gt_pr.

  SORT lt_pr BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_pr COMPARING matnr.

  CLEAR gt_lifnr.

  IF lt_pr IS NOT INITIAL.

    SELECT vm~matnr, mat~maktx, vm~lifnr, ven~name1, vm~valfr,
           vm~valto, vm~beskz, vm~priok, vm~netpr, vm~waers,
           vm~plifz, vm~bstmi, vm~meins, vm~actyn, vm~inrsn,
           ven~trdyn, ev~vevno, ev~datab, ev~datbi, ev~dscor, ev~qscor,
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
        AND ven~trdyn = 'Y'
      INTO CORRESPONDING FIELDS OF TABLE @gt_lifnr.

  ENDIF.
*  SORT gt_lifnr BY tscor DESCENDING.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_create_po
*&---------------------------------------------------------------------*
*& text
*& 10-22 일 수정 PR 수정 부분을 ZFM_MM_PO_CREATE로 이관.
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_create_po .
  DATA : lt_return  TYPE TABLE OF bapiret2.
*         lt_pr_save TYPE TABLE OF ztmma00040.
  DATA : lt_mma00050 TYPE zttmma00050,
         lt_mma00060 TYPE zttmma00061.
  DATA : lv_error    TYPE abap_bool.
  PERFORM zz_set_pr_statu.
  CALL FUNCTION 'ZFM_MM_PO_CREATE'
    EXPORTING
      purchase_item = gt_po
      purchase_req  = gt_pr_save
    IMPORTING
      et_mma00050   = lt_mma00050
      et_mma00060   = lt_mma00060
    TABLES
      et_return     = lt_return.

*  READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
*  IF sy-subrc = 0.
*    ROLLBACK WORK.
*    MESSAGE s063 DISPLAY LIKE 'E'.
*    RETURN.
*  ENDIF.
  LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ls_return>) WHERE type = 'E' OR type = 'A' OR type = 'X'.
    ROLLBACK WORK.
    MESSAGE <ls_return>-message TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDLOOP.

  PERFORM zz_get_bom_data USING lt_mma00050
                                lt_mma00060
                       CHANGING lv_error.
  IF lv_error IS NOT INITIAL.
    ROLLBACK WORK.
    RETURN.
  ENDIF.

  COMMIT WORK.
  PERFORM zz_get_all_data.
  go_alv_pr->refresh_table_display( ).
  go_alv_po->refresh_table_display( ).
*  ENDIF.

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

  CLEAR gt_pr_save.

  LOOP AT gt_po ASSIGNING FIELD-SYMBOL(<ls_po>).

    READ TABLE gt_pr ASSIGNING FIELD-SYMBOL(<ls_pr>) WITH KEY banfn = <ls_po>-banfn
                                                              bnfpo = <ls_po>-bnfpo.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    APPEND INITIAL LINE TO gt_pr_save ASSIGNING FIELD-SYMBOL(<ls_pr_save>).

    MOVE-CORRESPONDING <ls_pr> TO <ls_pr_save>.

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
    MESSAGE s105 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "PO 장바구니 행 삭제 시 INDEX 밀림 방지
  SORT lt_selected BY index DESCENDING.

  LOOP AT lt_selected ASSIGNING FIELD-SYMBOL(<ls_selected>).

    READ TABLE gt_po ASSIGNING FIELD-SYMBOL(<ls_alv_po>)
      INDEX <ls_selected>-index.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    "장바구니로 내릴 때 보관한 원본 PR 찾기
    READ TABLE gt_pr WITH KEY banfn = <ls_alv_po>-banfn
                              bnfpo = <ls_alv_po>-bnfpo ASSIGNING FIELD-SYMBOL(<ls_pr>).
    IF sy-subrc = 0.
      APPEND INITIAL LINE TO gt_pr_show ASSIGNING FIELD-SYMBOL(<ls_pr_show>).
      MOVE-CORRESPONDING <ls_pr> TO <ls_pr_show>.
    ELSE.
      CONTINUE.
    ENDIF.
    lv_move_count = lv_move_count + 1.

    DELETE gt_po WHERE banfn = <ls_alv_po>-banfn
                   AND bnfpo = <ls_alv_po>-bnfpo.

  ENDLOOP.

  SORT gt_pr_show BY banfn DESCENDING.
  MESSAGE s104 WITH lv_move_count DISPLAY LIKE 'E'.
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
FORM zz_show_vendor_history USING pv_matnr TYPE matnr
                                  pv_lifnr TYPE lifnr.

  CLEAR : gt_history, gv_offset.

  SELECT a~lifnr, a~ebeln, b~ebelp, a~bedat, a~bukrs,
         a~ekorg, a~ekgrp, b~matnr, mat~maktx, b~werks,
         wer~name1 AS wname, b~lgort, lgo~lgobe AS lname,
         b~menge, b~meins, b~netpr, b~waers
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
    ORDER BY a~bedat DESCENDING,
             a~ebeln DESCENDING,
             b~ebelp DESCENDING
    INTO CORRESPONDING FIELDS OF TABLE @gt_history
    UP TO 20 ROWS
    OFFSET @gv_offset.

  SELECT SINGLE a~lifnr, a~datab, a~dscor, a~qscor, a~pscor,
                a~tscor, a~grade, a~znote, b~name1
    FROM ztmma00100 AS a
    INNER JOIN ztcma00010 AS b
      ON a~lifnr = b~lifnr
    WHERE a~lifnr = @pv_lifnr
      AND a~datab <= @sy-datum
      AND a~datbi >= @sy-datum
    INTO CORRESPONDING FIELDS OF @zsmma00100.

  IF gt_history IS INITIAL.
    MESSAGE s103 DISPLAY LIKE 'E'.
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

    LOOP AT gt_fcat_history ASSIGNING FIELD-SYMBOL(<ls_fcat_history>).
      CASE <ls_fcat_history>-fieldname.
        WHEN 'LIFNR'.  "공급업체 번호
          <ls_fcat_history>-no_out = 'X'.
        WHEN 'EBELN'.  "구매오더 번호
          <ls_fcat_history>-outputlen = 3.
        WHEN 'EBELP'.  "구매오더 품목 번호
          <ls_fcat_history>-outputlen = 2.
        WHEN 'BEDAT'.  "구매오더일
          <ls_fcat_history>-outputlen = 4.
        WHEN 'BUKRS'.  "회사 코드
          <ls_fcat_history>-no_out = 'X'.
          <ls_fcat_history>-outputlen = 4.
        WHEN 'EKORG'.  "구매 조직
          <ls_fcat_history>-no_out = 'X'.
        WHEN 'EKGRP'.  "구매 그룹
          <ls_fcat_history>-no_out = 'X'.
        WHEN 'MATNR'.  "자재 번호
          <ls_fcat_history>-outputlen = 8.
        WHEN 'MAKTX'.  "자재 내역
          <ls_fcat_history>-outputlen = 8.
        WHEN 'WERKS'.  "플랜트
          <ls_fcat_history>-outputlen = 3.
        WHEN 'WNAME'.  "플랜트 이름
          <ls_fcat_history>-outputlen = 3.
        WHEN 'LGORT'.  "저장 위치
          <ls_fcat_history>-outputlen = 3.
        WHEN 'LNAME'.  "공급업체 이름
          <ls_fcat_history>-outputlen = 3.
        WHEN 'MENGE'.  "수량
          <ls_fcat_history>-outputlen = 2.
        WHEN 'MEINS'.  "기본 단위
          <ls_fcat_history>-outputlen = 2.
        WHEN 'NETPR'.  "단가
          <ls_fcat_history>-outputlen = 4.
        WHEN 'WAERS'.  "통화 키
          <ls_fcat_history>-outputlen = 2.
      ENDCASE.
    ENDLOOP.


*    gs_layo_history-cwidth_opt = 'X'.
    SET HANDLER lcl_event_handler=>on_toolbar_history FOR go_alv_history.
    SET HANDLER lcl_event_handler=>on_user_command    FOR go_alv_history.
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
  REFRESH : gt_pr, gt_po, gt_lifnr, gt_pr_save, gt_history, gt_pr_show.

*  IF go_tree IS BOUND.
*    CALL METHOD go_tree->delete_all_nodes.
*
*    "여기에 기존 트리 노드 생성 FORM 호출
*  ENDIF.
  PERFORM zz_get_data.
  PERFORM zz_get_lifnr.
  IF go_tree IS BOUND.

    "기존 노드 삭제
    CALL METHOD go_tree->delete_all_nodes.

    "조회한 데이터로 노드 다시 생성
    PERFORM build_vendor_tree.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form make_lifnr_f4
*&---------------------------------------------------------------------*
*& 공급업체 Search help 만들기
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM make_lifnr_f4 USING pv_row_id TYPE lvc_s_roid-row_id.
  DATA: lt_f4_vendor    TYPE STANDARD TABLE OF ty_f4_vendor,
        lt_return       TYPE STANDARD TABLE OF ddshretval,
        ls_return       TYPE ddshretval,
        lv_arrival_date TYPE datum.

  READ TABLE gt_po ASSIGNING FIELD-SYMBOL(<ls_alv_po>) INDEX pv_row_id.

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
    MESSAGE s101 DISPLAY LIKE 'E'.
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

  "선택 행(gt_po)에 최종 반영
  <ls_alv_po>-lifnr = <ls_lifnr>-lifnr.
  <ls_alv_po>-lname = <ls_lifnr>-name1.
  <ls_alv_po>-netpr = <ls_lifnr>-netpr.
  <ls_alv_po>-waers = <ls_lifnr>-waers.
  <ls_alv_po>-plifz = <ls_lifnr>-plifz.
  <ls_alv_po>-bstmi = <ls_lifnr>-bstmi.
  <ls_alv_po>-meins = <ls_lifnr>-meins.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_more
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM show_more_trade_history.
  gv_offset += 20.

  READ TABLE gt_history ASSIGNING FIELD-SYMBOL(<ls_history>) INDEX 1.


  SELECT a~lifnr, a~ebeln, b~ebelp, a~bedat, a~bukrs,
       a~ekorg, a~ekgrp, b~matnr, mat~maktx, b~werks,
       wer~name1 AS wname, b~lgort, lgo~lgobe AS lname,
       b~menge, b~meins, b~netpr, b~waers
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
  WHERE a~lifnr = @<ls_history>-lifnr
    AND b~matnr = @<ls_history>-matnr
  ORDER BY a~bedat DESCENDING,
           a~ebeln DESCENDING,
           b~ebelp DESCENDING
  APPENDING CORRESPONDING FIELDS OF TABLE @gt_history
  UP TO 20 ROWS
  OFFSET @gv_offset.

  IF sy-dbcnt = 0.
    gv_offset -= 20.
    MESSAGE s102 DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_bom_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& BOM 후속 처리: 계산 -> 업체/PO 분리 -> PR -> 이동문서 -> 최종 저장
*&---------------------------------------------------------------------*
FORM zz_get_bom_data
  USING    pt_mma00050 TYPE zttmma00050
           pt_mma00060 TYPE zttmma00061
  CHANGING pv_error TYPE abap_bool.

  DATA: lt_return           TYPE bapiret2_t,
        lt_purchase_head    TYPE zttmma00050,
        lt_purchase_order   TYPE zttmma00061,
        lt_purchase_reserve TYPE zttmma00160,
        lt_purchase_req     TYPE ty_t_bom_pr,
        lt_move_head        TYPE ty_t_bom_move_head,
        lt_move_item        TYPE zttmma00090,
        lt_stock            TYPE zttmma00070,
        lt_head_save        TYPE TABLE OF ztmma00050,
        lt_order_save       TYPE TABLE OF ztmma00060,
        lt_reserve_save     TYPE TABLE OF ztmma00160,
        lt_move_save        TYPE TABLE OF ztmma00090.

  CLEAR pv_error.
  CALL FUNCTION 'ZFM_MM_BOM_PR'
    EXPORTING
      purchase_head    = pt_mma00050
      purchase_item    = pt_mma00060
    IMPORTING
      purchase_order   = lt_purchase_order
      purchase_reserve = lt_purchase_reserve
      stock            = lt_stock
    TABLES
      et_return        = lt_return.
  IF line_exists( lt_return[ type = 'E' ] )
     OR line_exists( lt_return[ type = 'A' ] )
     OR line_exists( lt_return[ type = 'X' ] ).
    LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ls_bom_error>)
      WHERE type = 'E' OR type = 'A' OR type = 'X'.
      MESSAGE <ls_bom_error>-message TYPE 'S' DISPLAY LIKE 'E'.
      EXIT.
    ENDLOOP.
    pv_error = abap_true.
    RETURN.
  ENDIF.

  PERFORM zz_set_lifnr USING pt_mma00050
    CHANGING lt_purchase_order lt_purchase_reserve lt_purchase_head pv_error.
  IF pv_error = abap_true.
    RETURN.
  ENDIF.
  PERFORM zz_set_purchase_req
    CHANGING lt_purchase_order lt_purchase_reserve lt_purchase_req pv_error.
  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  LOOP AT lt_purchase_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>).
    <ls_reserve>-rstat = '0010'.
  ENDLOOP.
  PERFORM zz_set_mat_move USING lt_purchase_reserve
    CHANGING lt_move_head lt_move_item pv_error.
  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  lt_head_save = CORRESPONDING #( lt_purchase_head ).
  lt_order_save = CORRESPONDING #( lt_purchase_order ).
  lt_reserve_save = CORRESPONDING #( lt_purchase_reserve ).
  lt_move_save = CORRESPONDING #( lt_move_item ).

  "재고 FM이 신규 160/부모 PO를 읽을 수 있도록 같은 LUW에서 먼저 저장한다.
  "여기서는 COMMIT하지 않는다. 실패 시 기존 zz_create_po가 전체 ROLLBACK한다.
  IF lt_purchase_req IS NOT INITIAL.
    MODIFY ztmma00040 FROM TABLE lt_purchase_req.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.
  IF lt_head_save IS NOT INITIAL.
    MODIFY ztmma00050 FROM TABLE lt_head_save.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.
  IF lt_order_save IS NOT INITIAL.
    MODIFY ztmma00060 FROM TABLE lt_order_save.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.
  IF lt_reserve_save IS NOT INITIAL.
    MODIFY ztmma00160 FROM TABLE lt_reserve_save.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.
  PERFORM zz_bom_set_hold USING lt_purchase_reserve CHANGING pv_error.
  IF pv_error = abap_true.
    RETURN.
  ENDIF.
  IF lt_move_head IS NOT INITIAL.
    MODIFY ztmma00080 FROM TABLE lt_move_head.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.
  IF lt_move_save IS NOT INITIAL.
    MODIFY ztmma00090 FROM TABLE lt_move_save.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.

  IF lt_move_item IS NOT INITIAL.
    CLEAR: lt_return, lt_stock.
    "실제 재고는 DB 현재값에서 653을 한 번 적용하고 확보 완료분은 이어서 지급한다.
    CALL FUNCTION 'ZFM_MM_MATERIAL_STOCK'
      EXPORTING
        move_material  = lt_move_item
      IMPORTING
        material_stock = lt_stock
      TABLES
        et_return      = lt_return.
    IF line_exists( lt_return[ type = 'E' ] )
       OR line_exists( lt_return[ type = 'A' ] )
       OR line_exists( lt_return[ type = 'X' ] ).
      LOOP AT lt_return ASSIGNING <ls_bom_error>
        WHERE type = 'E' OR type = 'A' OR type = 'X'.
        MESSAGE <ls_bom_error>-message TYPE 'S' DISPLAY LIKE 'E'.
        EXIT.
      ENDLOOP.
      pv_error = abap_true.
      RETURN.
    ENDIF.
    IF lt_stock IS INITIAL.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.
  "160/50/70은 재고 FM의 최신 결과를 유지한다. 계산용 스냅샷으로 다시 저장하지 않는다.
ENDFORM.

*&---------------------------------------------------------------------*
*& 공급업체 선정 및 PO 분리, 헤더 구성, 예약행 연결키 변경
*&---------------------------------------------------------------------*
FORM zz_set_lifnr
  USING    pt_origin_head      TYPE zttmma00050
  CHANGING pt_purchase_order   TYPE zttmma00061
           pt_purchase_reserve TYPE zttmma00160
           pt_purchase_head    TYPE zttmma00050
           pv_error            TYPE abap_bool.

  TYPES: BEGIN OF ty_po_map,
           old_ebeln TYPE ebeln,
           ebelp     TYPE ebelp,
           lifnr     TYPE lifnr,
           new_ebeln TYPE ebeln,
         END OF ty_po_map.

  DATA: lt_lifnr_key  TYPE zttmma00061,
        lt_po_map     TYPE TABLE OF ty_po_map,
        lv_new_ebeln  TYPE ebeln,
        lv_parent_po  TYPE ebeln,
        lv_parent_itm TYPE ebelp,
        lv_head_found TYPE abap_bool.

  "앞 단계 오류를 지우지 않고 즉시 중단
  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  "이 출력에는 추가 PO 헤더만 구성한다. 원본 헤더는 입력으로 보존
  CLEAR pt_purchase_head.

  lt_lifnr_key = pt_purchase_order.
  SORT lt_lifnr_key BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_lifnr_key COMPARING matnr.

  "FAE가 빈 테이블로 전체 거래조건을 조회하지 않도록 방지
  IF lt_lifnr_key IS INITIAL.
    RETURN.
  ENDIF.

  SELECT c~matnr, c~lifnr, c~valfr, c~priok, c~netpr,
         c~waers, c~plifz, c~bstmi, c~meins,
         v~datab AS eval_from, v~vevno, v~tscor, v~grade
    FROM ztcma00040 AS c
    INNER JOIN ztmma00100 AS v ON v~lifnr = c~lifnr
    FOR ALL ENTRIES IN @lt_lifnr_key
    WHERE c~matnr = @lt_lifnr_key-matnr
      AND c~actyn = 'Y'
      AND c~valfr <= @sy-datum
      AND c~valto >= @sy-datum
      AND v~datab <= @sy-datum
      AND v~datbi >= @sy-datum
    INTO TABLE @DATA(lt_vendor_best).

  "기간이 겹치는 경우 최근 시작 평가/조건을 우선 사용
  SORT lt_vendor_best BY matnr     ASCENDING
                         lifnr     ASCENDING
                         eval_from DESCENDING
                         vevno     DESCENDING
                         valfr     DESCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_vendor_best COMPARING matnr lifnr.

  "종합점수 우선, 동점은 거래조건 우선순위와 공급업체 번호순
  SORT lt_vendor_best BY matnr ASCENDING
                         tscor DESCENDING
                         priok ASCENDING
                         lifnr ASCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_vendor_best COMPARING matnr.

  "한 원본 PO에서 품목번호가 빠른 업체가 기존 PO 번호를 유지
  SORT pt_purchase_order BY ebeln ebelp.
  DATA(lv_max_depth) = lines( pt_purchase_reserve ) + 1.

  LOOP AT pt_purchase_order ASSIGNING FIELD-SYMBOL(<ls_order>).

    READ TABLE lt_vendor_best ASSIGNING FIELD-SYMBOL(<ls_vendor>)
      WITH KEY matnr = <ls_order>-matnr.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.

    "같은 기존 PO/업체 조합은 이미 배정된 최종 번호 재사용
    READ TABLE lt_po_map ASSIGNING FIELD-SYMBOL(<ls_map>)
      WITH KEY old_ebeln = <ls_order>-ebeln
               lifnr     = <ls_vendor>-lifnr.

    IF sy-subrc = 0.
      lv_new_ebeln = <ls_map>-new_ebeln.
    ELSE.

      "예약행을 아직 수정하지 않았으므로 원래 부모 경로를 추적 가능
      lv_parent_po  = <ls_order>-ebeln.
      lv_parent_itm = <ls_order>-ebelp.
      CLEAR lv_head_found.

      "잘못된 순환 참조가 있더라도 무한 반복하지 않도록 제한
      DO lv_max_depth TIMES.
        READ TABLE pt_origin_head ASSIGNING FIELD-SYMBOL(<ls_origin>)
          WITH KEY ebeln = lv_parent_po.
        IF sy-subrc = 0.
          lv_head_found = abap_true.
          EXIT.
        ENDIF.

        READ TABLE pt_purchase_reserve ASSIGNING FIELD-SYMBOL(<ls_link>)
          WITH KEY ebeln = lv_parent_po
                   ebelp = lv_parent_itm.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        lv_parent_po  = <ls_link>-c_ebeln.
        lv_parent_itm = <ls_link>-c_ebelp.
      ENDDO.

      "조직정보를 추측하지 않고 원본 헤더가 없으면 중단
      IF lv_head_found = abap_false.
        pv_error = abap_true.
        RETURN.
      ENDIF.

      READ TABLE lt_po_map WITH KEY old_ebeln = <ls_order>-ebeln
        TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.
        "첫 업체에는 기존 번호 사용
        lv_new_ebeln = <ls_order>-ebeln.
      ELSE.
        "다른 업체를 위한 PO만 추가 채번
        CLEAR lv_new_ebeln.
        CALL FUNCTION 'NUMBER_GET_NEXT'
          EXPORTING
            nr_range_nr = '01'
            object      = 'ZMM_EBELN'
          IMPORTING
            number      = lv_new_ebeln
          EXCEPTIONS
            OTHERS      = 1.
        IF sy-subrc <> 0.
          pv_error = abap_true.
          RETURN.
        ENDIF.
      ENDIF.

      "조직과 초기 상태는 원본 헤더 기준, 업체는 선정 결과 사용
      APPEND VALUE #(
        ebeln = lv_new_ebeln
        lifnr = <ls_vendor>-lifnr
        bedat = sy-datum
        bukrs = <ls_origin>-bukrs
        ekorg = <ls_origin>-ekorg
        ekgrp = <ls_origin>-ekgrp
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit
      ) TO pt_purchase_head.
    ENDIF.

    "변경 전 키를 보관한 뒤 품목의 PO 번호 변경
    APPEND VALUE #(
      old_ebeln = <ls_order>-ebeln
      ebelp     = <ls_order>-ebelp
      lifnr     = <ls_vendor>-lifnr
      new_ebeln = lv_new_ebeln
    ) TO lt_po_map.

    <ls_order>-ebeln = lv_new_ebeln.
    <ls_order>-netpr = <ls_vendor>-netpr.
    <ls_order>-waers = <ls_vendor>-waers.
    <ls_order>-eindt = sy-datum + <ls_vendor>-plifz.
  ENDLOOP.

  "모든 매핑이 완성된 뒤 예약행의 두 방향 PO 참조를 함께 변경
  LOOP AT pt_purchase_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>).
    READ TABLE lt_po_map ASSIGNING FIELD-SYMBOL(<ls_order_map>)
      WITH KEY old_ebeln = <ls_reserve>-ebeln
               ebelp     = <ls_reserve>-ebelp.
    IF sy-subrc = 0.
      <ls_reserve>-ebeln = <ls_order_map>-new_ebeln.
    ENDIF.

    READ TABLE lt_po_map ASSIGNING FIELD-SYMBOL(<ls_parent_map>)
      WITH KEY old_ebeln = <ls_reserve>-c_ebeln
               ebelp     = <ls_reserve>-c_ebelp.
    IF sy-subrc = 0.
      <ls_reserve>-c_ebeln = <ls_parent_map>-new_ebeln.
    ENDIF.
  ENDLOOP.

  "추가 헤더의 기존 정상값 0030은 유지하고 실제 부족분이 있을 때만 0040으로 한다.
  LOOP AT pt_purchase_head ASSIGNING FIELD-SYMBOL(<ls_head>).
    <ls_head>-pstat = '0030'.
    LOOP AT pt_purchase_reserve ASSIGNING FIELD-SYMBOL(<ls_wait>)
      WHERE c_ebeln = <ls_head>-ebeln.
      IF <ls_wait>-reqty > <ls_wait>-rsqty.
        <ls_head>-pstat = '0040'.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDLOOP.


ENDFORM.
*&---------------------------------------------------------------------*
*& 최종 PO별 PR 구성 및 PO/예약행에 신규 PR 키 연결
*&---------------------------------------------------------------------*
FORM zz_set_purchase_req
  CHANGING pt_purchase_order   TYPE zttmma00061
           pt_purchase_reserve TYPE zttmma00160
           pt_purchase_req     TYPE ty_t_bom_pr
           pv_error            TYPE abap_bool.

  DATA: lv_ebeln TYPE ebeln,
        lv_banfn TYPE banfn,
        lv_bnfpo TYPE bnfpo.

  IF pv_error = abap_true.
    RETURN.
  ENDIF.
  CLEAR pt_purchase_req.

  SORT pt_purchase_order BY ebeln ebelp.
  LOOP AT pt_purchase_order ASSIGNING FIELD-SYMBOL(<ls_order>).

    IF <ls_order>-ebeln <> lv_ebeln.
      CLEAR: lv_banfn, lv_bnfpo.
      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING
          nr_range_nr = '01'
          object      = 'ZMM_BANFN'
        IMPORTING
          number      = lv_banfn
        EXCEPTIONS
          OTHERS      = 1.
      IF sy-subrc <> 0.
        pv_error = abap_true.
        RETURN.
      ENDIF.
      lv_ebeln = <ls_order>-ebeln.
    ENDIF.

    lv_bnfpo += 10.

    "신규 PR 키를 실제 PO 품목에도 반영
    <ls_order>-banfn = lv_banfn.
    <ls_order>-bnfpo = lv_bnfpo.

    APPEND VALUE #(
      banfn = lv_banfn
      bnfpo = lv_bnfpo
      matnr = <ls_order>-matnr
      werks = <ls_order>-werks
      lgort = <ls_order>-lgort
      prtyp = '0010'
      srtyp = '0030'
      srdoc = <ls_order>-banfn
      sritm = <ls_order>-bnfpo
      ptype = <ls_order>-ptype
      ruser = sy-uname
      rdate = sy-datum
      rqty  = <ls_order>-menge
      meins = <ls_order>-meins
      astat = '0020'
      auser = sy-uname
      adate = sy-datum
      pstat = '0040'
      ernam = sy-uname
      erdat = sy-datum
      erzet = sy-uzeit
    ) TO pt_purchase_req.

    "창고별로 나뉜 동일 PO 품목의 예약행에도 같은 신규 PR 연결
    LOOP AT pt_purchase_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>)
      WHERE ebeln = <ls_order>-ebeln
        AND ebelp = <ls_order>-ebelp.
      <ls_reserve>-banfn = lv_banfn.
      <ls_reserve>-bnfpo = lv_bnfpo.
    ENDLOOP.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& 확보수량이 있는 예약행으로 이동문서 헤더/품목 구성
*&---------------------------------------------------------------------*
FORM zz_set_mat_move
  USING    pt_purchase_reserve TYPE zttmma00160
  CHANGING pt_move_head        TYPE ty_t_bom_move_head
           pt_move_item        TYPE zttmma00090
           pv_error            TYPE abap_bool.

  DATA: lv_ebeln TYPE ebeln,
        lv_mblnr TYPE mblnr,
        lv_zeile TYPE zde_mblpo.

  IF pv_error = abap_true.
    RETURN.
  ENDIF.
  CLEAR: pt_move_head, pt_move_item.

  SORT pt_purchase_reserve BY ebeln ebelp werks lgort.

  "미확보 수량으로 0수량 이동문서가 만들어지지 않도록 제외
  LOOP AT pt_purchase_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>)
    WHERE rsqty > 0.

    "빈 문서 참조와 필요량을 초과한 예약은 저장 전에 중단
    IF <ls_reserve>-ebeln IS INITIAL
       OR <ls_reserve>-rsqty > <ls_reserve>-reqty.
      pv_error = abap_true.
      RETURN.
    ENDIF.

    IF <ls_reserve>-ebeln <> lv_ebeln.
      CLEAR: lv_mblnr, lv_zeile.
      CALL FUNCTION 'NUMBER_GET_NEXT'
        EXPORTING
          nr_range_nr = '01'
          object      = 'ZMM_MBLNR'
          toyear      = sy-datum+0(4)
        IMPORTING
          number      = lv_mblnr
        EXCEPTIONS
          OTHERS      = 1.
      IF sy-subrc <> 0.
        pv_error = abap_true.
        RETURN.
      ENDIF.

      lv_ebeln = <ls_reserve>-ebeln.

      "채번 시 헤더도 한 번 생성하므로 별도 헤더 집계 LOOP 불필요
      APPEND VALUE #(
        mblnr = lv_mblnr
        mjahr = sy-datum+0(4)
        bldat = sy-datum
        budat = sy-datum
        usnam = sy-uname
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit
      ) TO pt_move_head.
    ENDIF.

    lv_zeile += 10.
    APPEND VALUE #(
      mblnr = lv_mblnr
      mjahr = sy-datum+0(4)
      zeile = lv_zeile
      werks = <ls_reserve>-werks
      lgort = <ls_reserve>-lgort
      matnr = <ls_reserve>-matnr
      ebeln = <ls_reserve>-ebeln
      ebelp = <ls_reserve>-ebelp
      menge = <ls_reserve>-rsqty
      meins = <ls_reserve>-meins
      bwart = '653'
      ernam = sy-uname
      erdat = sy-datum
      erzet = sy-uzeit
    ) TO pt_move_item.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_bom_set_hold
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_PURCHASE_RESERVE
*&      <-- PV_ERROR
*&---------------------------------------------------------------------*
FORM zz_bom_set_hold
  USING    pt_reserve TYPE zttmma00160
  CHANGING pv_error TYPE abap_bool.

  DATA lt_parent TYPE zttmma00160.
  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  "부족한 행의 부모만 정지한다. 충분한 PO의 0010/0030은 그대로 둔다.
  LOOP AT pt_reserve ASSIGNING FIELD-SYMBOL(<ls_reserve>).
    IF <ls_reserve>-reqty > <ls_reserve>-rsqty.
      IF <ls_reserve>-c_ebeln IS INITIAL.
        pv_error = abap_true.
        RETURN.
      ENDIF.
      APPEND <ls_reserve> TO lt_parent.
    ENDIF.
  ENDLOOP.
  IF lt_parent IS INITIAL.
    RETURN.
  ENDIF.
  SORT lt_parent BY c_ebeln.
  DELETE ADJACENT DUPLICATES FROM lt_parent COMPARING c_ebeln.

  SELECT * FROM ztmma00050
    FOR ALL ENTRIES IN @lt_parent
    WHERE ebeln = @lt_parent-c_ebeln
    INTO TABLE @DATA(lt_head).
  LOOP AT lt_parent ASSIGNING FIELD-SYMBOL(<ls_parent>).
    IF NOT line_exists( lt_head[ ebeln = <ls_parent>-c_ebeln ] ).
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDLOOP.
  LOOP AT lt_head ASSIGNING FIELD-SYMBOL(<ls_head>).
    <ls_head>-pstat = '0040'.
    <ls_head>-aenam = sy-uname.
    <ls_head>-aedat = sy-datum.
    <ls_head>-aezet = sy-uzeit.
  ENDLOOP.
  MODIFY ztmma00050 FROM TABLE lt_head.
  IF sy-subrc <> 0.
    pv_error = abap_true.
  ENDIF.
ENDFORM.
