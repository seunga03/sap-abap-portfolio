*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form zz_get_requirement_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_requirement_data .

  CLEAR gt_shortage.

  SELECT a~fcsno,
         a~matnr,
         a~meins,
         SUM( a~final_reqty ) AS reqty
    FROM ztmma00021 AS a
    INNER JOIN ztmma00010 AS b
      ON b~fcsno = a~fcsno
   WHERE b~werks = @pa_werks
     AND b~cstat = '0020'
     AND b~activ = @abap_true
     AND a~bom_level = '00'
     AND a~fcsno IN @so_fcsno
     AND a~matnr IN @so_matnr
   GROUP BY
         a~fcsno,
         a~matnr,
         a~meins
    INTO CORRESPONDING FIELDS OF TABLE @gt_shortage.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_stock_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_stock_data .

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs_shortage>).

    SELECT SUM( stqty ) AS stqty,
           SUM( rsqty ) AS rsqty,
           SUM( qisty ) AS qisty
      FROM ztmma00070
     WHERE matnr = @<fs_shortage>-matnr
       AND werks = @pa_werks
      INTO ( @<fs_shortage>-stqty,
             @<fs_shortage>-rsqty,
             @<fs_shortage>-qisty ).

    <fs_shortage>-werks = pa_werks.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_material_info
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_material_info .

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs_shortage>).

    SELECT SINGLE eisbe, beskz, plifz, bstmi
      FROM ztcma00030
     WHERE matnr = @<fs_shortage>-matnr
       AND werks = @pa_werks
       AND actyn = @zlea_y
      INTO ( @<fs_shortage>-eisbe,
             @<fs_shortage>-beskz,
             @<fs_shortage>-plifz,
             @<fs_shortage>-bstmi ).

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_incoming_qty
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_incoming_qty .

  DATA:
    lv_po_qty TYPE ztmma00060-menge,
    lv_gr_qty TYPE ztmma00090-menge.

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs_shortage>).

    CLEAR:
      <fs_shortage>-inqty,
      lv_po_qty,
      lv_gr_qty.

    """ 해당 자재/플랜트의 PO 수량
    SELECT SUM( menge )
      FROM ztmma00060
     WHERE matnr = @<fs_shortage>-matnr
       AND werks = @<fs_shortage>-werks
      INTO @lv_po_qty.

    """ 해당 PO에 대해 이미 GR된 수량
    SELECT SUM( c~menge )
      FROM ztmma00060 AS b
     INNER JOIN ztmma00090 AS c
        ON c~ebeln = b~ebeln
       AND c~ebelp = b~ebelp
     WHERE b~matnr = @<fs_shortage>-matnr
       AND b~werks = @<fs_shortage>-werks
       AND c~bwart = '101' " 취소/완료된 PO 제외해야 함
      INTO @lv_gr_qty.

    """ 입고예정량 = PO - GR
    <fs_shortage>-inqty = lv_po_qty - lv_gr_qty.

    IF <fs_shortage>-inqty < 0.
      <fs_shortage>-inqty = 0.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_calc_shortage
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_calc_shortage .

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs_shortage>).

    """ 예상가용수량 (STQTY는 이미 예약재고가 제외된 가용재고)
    <fs_shortage>-avqty = <fs_shortage>-stqty + <fs_shortage>-inqty.

    """ 추가 부족수량: 이미 확보한 유효 미전환 PR도 공급으로 간주
    """ 같은 예측기간의 기존 PR 조정은 zz_reconcile_forecast_pr에서 선처리
    <fs_shortage>-shiqty =
        <fs_shortage>-reqty + <fs_shortage>-eisbe
      - <fs_shortage>-avqty - <fs_shortage>-open_pr_qty.

    """ 부족하지 않으면 0
    IF <fs_shortage>-shiqty < 0.
      <fs_shortage>-shiqty = 0.
    ENDIF.

    """ PR 생성 대상
    IF <fs_shortage>-shiqty > 0.
      <fs_shortage>-pr_target = abap_true.
      <fs_shortage>-pr_status = '생성대기'.
    ELSE.
      <fs_shortage>-pr_target = abap_false.
      CLEAR <fs_shortage>-pr_status.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_field_catalog
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_field_catalog .

  CLEAR: gt_fcat, gv_fcat_pos.

  """ 기본정보
  PERFORM zz_exe_add_fcat USING 'SRTNO' '부족량번호'.

  PERFORM zz_exe_add_fcat USING 'FCSNO' '예측번호'.
  PERFORM zz_exe_add_fcat USING 'MATNR' '자재번호'.
  PERFORM zz_exe_add_fcat USING 'MAKTX' '자재명'.
  PERFORM zz_exe_add_fcat USING 'WERKS' '플랜트'.
  PERFORM zz_exe_add_fcat USING 'MEINS' '단위'.

  """ 수요
  PERFORM zz_exe_add_fcat USING 'REQTY' '소요수량'.

  """ 재고
  PERFORM zz_exe_add_fcat USING 'STQTY' '현재고'.
  PERFORM zz_exe_add_fcat USING 'RSQTY' '예약수량'.
  PERFORM zz_exe_add_fcat USING 'QISTY' '검사재고'.

  """ 입고 / 안전재고
  PERFORM zz_exe_add_fcat USING 'INQTY' '입고예정량'.
  PERFORM zz_exe_add_fcat USING 'EISBE' '안전재고'.

  """ 계산결과
  PERFORM zz_exe_add_fcat USING 'AVQTY'  '예상가용수량'.
  PERFORM zz_exe_add_fcat USING 'OPEN_PR_QTY' '기존 PR 공급량'.
  PERFORM zz_exe_add_fcat USING 'SHIQTY' '추가 부족수량'.

  """ 조달정보
  PERFORM zz_exe_add_fcat USING 'BESKZ' '조달유형'.
  PERFORM zz_exe_add_fcat USING 'PLIFZ' '계획납기일수'.
  PERFORM zz_exe_add_fcat USING 'BSTMI' '최소 Lot'.

  """ PR
*  PERFORM zz_exe_add_fcat USING 'PR_TARGET' 'PR 대상'.
  PERFORM zz_exe_add_fcat USING 'PR_STATUS' '구매요청문서 처리결과'.
  PERFORM zz_exe_add_fcat USING 'BANFN' '구매요청문서번호'.
  PERFORM zz_exe_add_fcat USING 'PSTAT' '처리상태'.

  LOOP AT gt_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).
    CASE <fs_fcat>-fieldname.
      WHEN 'FCSNO' OR 'MATNR'.
        <fs_fcat>-key = abap_true.
      WHEN 'REQTY' OR 'STQTY' OR 'RSQTY' OR 'QISTY'
        OR 'INQTY' OR 'EISBE' OR 'AVQTY'
        OR 'OPEN_PR_QTY'
        OR 'SHIQTY' OR 'BSTMI'.
        <fs_fcat>-qfieldname = 'MEINS'.
    ENDCASE.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_layout .

  CLEAR gs_layo.
  gs_layo-zebra      = abap_true.
  gs_layo-cwidth_opt = abap_true.
  gs_layo-sel_mode   = 'A'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_add_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&---------------------------------------------------------------------*
FORM zz_exe_add_fcat USING pv_field TYPE lvc_fname
                           pv_text  TYPE lvc_txt.

  CLEAR gs_fcat.
  gv_fcat_pos       = gv_fcat_pos + 1.
  gs_fcat-fieldname = pv_field.
  gs_fcat-coltext   = pv_text.
  gs_fcat-scrtext_l = pv_text.
  gs_fcat-scrtext_m = pv_text.
  gs_fcat-scrtext_s = pv_text.
  gs_fcat-reptext   = pv_text.
  gs_fcat-col_pos   = gv_fcat_pos.
  APPEND gs_fcat TO gt_fcat.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_material_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_material_text .

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs_shortage>).

    SELECT SINGLE maktx
      FROM ztcma00020
     WHERE matnr = @<fs_shortage>-matnr
      INTO @<fs_shortage>-maktx.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_create_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_create_pr .
  DATA: lt_rows     TYPE lvc_t_row,
        lt_request  TYPE zttmma00010,
        ls_request  TYPE zsmma00010,
        ls_short_db TYPE ztmma00030,
        lv_error    TYPE abap_bool,
        lv_created  TYPE i,
        lv_skipped  TYPE i,
        lv_message  TYPE string.

  FIELD-SYMBOLS <fs_shortage> TYPE ty_shortage.

  IF go_grid IS NOT BOUND.
    MESSAGE 'ALV 객체가 생성되지 않았습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  go_grid->get_selected_rows( IMPORTING et_index_rows = lt_rows ).
  IF lt_rows IS INITIAL.
    MESSAGE '구매요청문서 생성 대상을 선택해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_shortage ASSIGNING <fs_shortage> INDEX ls_row-index.
    IF sy-subrc <> 0 OR <fs_shortage>-srtno IS INITIAL.
      CONTINUE.
    ENDIF.
    CLEAR ls_short_db.
    SELECT SINGLE * FROM ztmma00030
      WHERE srtno = @<fs_shortage>-srtno
      INTO @ls_short_db.
    IF sy-subrc <> 0
       OR ls_short_db-fcsno <> <fs_shortage>-fcsno
       OR ls_short_db-matnr <> <fs_shortage>-matnr
       OR ls_short_db-werks <> <fs_shortage>-werks
       OR ls_short_db-reqtyp <> '0010'.
      MESSAGE '선택행과 부족량 DB 정보가 일치하지 않습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    IF ls_short_db-pstat <> '0010' OR ls_short_db-banfn IS NOT INITIAL
       OR ls_short_db-shiqty <= 0.
      CONTINUE.
    ENDIF.
    IF ls_short_db-shiqty <> <fs_shortage>-shiqty.
      MESSAGE '부족수량이 변경되었습니다. 다시 조회해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    CLEAR ls_request.
    ls_request-srtyp = '0010'.
    ls_request-srdoc = ls_short_db-srtno.
    APPEND ls_request TO lt_request.
  ENDLOOP.

  IF lt_request IS INITIAL.
    MESSAGE '신규 구매요청문서 생성 대상이 없습니다.' TYPE 'S'.
    RETURN.
  ENDIF.

  PERFORM zz_exe_pr_request
    USING lt_request abap_false
    CHANGING lv_error lv_created lv_skipped lv_message.

  IF lv_error = abap_true.
    MESSAGE lv_message TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " DB 기준 ALV 처리결과 갱신
  LOOP AT gt_shortage ASSIGNING <fs_shortage>.
    CLEAR ls_short_db.
    SELECT SINGLE * FROM ztmma00030
      WHERE srtno = @<fs_shortage>-srtno
      INTO @ls_short_db.
    IF sy-subrc = 0.
      <fs_shortage>-pstat = ls_short_db-pstat.
      <fs_shortage>-banfn = ls_short_db-banfn.
      IF ls_short_db-banfn IS NOT INITIAL.
        <fs_shortage>-pr_target = abap_false.
        <fs_shortage>-pr_status = '생성완료'.
      ENDIF.
    ENDIF.
  ENDLOOP.
  go_grid->refresh_table_display( ).
  MESSAGE |구매요청문서 신규 { lv_created }건, 제외 { lv_skipped }건| TYPE 'S'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_save_shortage
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_exe_save_shortage  CHANGING pv_error TYPE abap_bool.

  DATA: ls_save     TYPE ztmma00030,
        ls_existing TYPE ztmma00030,
        lv_srtno    TYPE ztmma00030-srtno.

  CLEAR pv_error.

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs_shortage>).

    CLEAR: ls_save, ls_existing, lv_srtno.

    """ 기존 부족량 결과 조회
    SELECT SINGLE *
      FROM ztmma00030
     WHERE fcsno  = @<fs_shortage>-fcsno
       AND matnr  = @<fs_shortage>-matnr
       AND werks  = @<fs_shortage>-werks
       AND reqtyp = '0010'
      INTO @ls_existing.

    IF sy-subrc = 0.

      """ 기존 SRTNO 유지
      lv_srtno = ls_existing-srtno.

      IF ls_existing-pstat <> '0010' OR ls_existing-banfn IS NOT INITIAL.

        """ PR 처리된 건은 변경하지 않음
        <fs_shortage>-srtno = lv_srtno.
        <fs_shortage>-pstat = ls_existing-pstat.
        <fs_shortage>-banfn = ls_existing-banfn.
        <fs_shortage>-pr_target = abap_false.
        <fs_shortage>-pr_status = '처리완료'.

        CONTINUE.

      ENDIF.

    ELSE.

      """ 신규 SRTNO 발급
      PERFORM zz_get_next_srtno CHANGING lv_srtno pv_error.

      IF pv_error = abap_true.
        RETURN.
      ENDIF.

    ENDIF.

    """ 최신 계산 결과 구성
    ls_save-mandt  = sy-mandt.
    ls_save-srtno  = lv_srtno.
    ls_save-fcsno  = <fs_shortage>-fcsno.
    ls_save-matnr  = <fs_shortage>-matnr.
    ls_save-werks  = <fs_shortage>-werks.

    ls_save-reqty  = <fs_shortage>-reqty.
    ls_save-stqty  = <fs_shortage>-stqty.
    ls_save-rsqty  = <fs_shortage>-rsqty.
    ls_save-inqty  = <fs_shortage>-inqty.
    ls_save-qisty  = <fs_shortage>-qisty.
    ls_save-sfqty  = <fs_shortage>-eisbe.
    ls_save-avqty  = <fs_shortage>-avqty.
    ls_save-shiqty = <fs_shortage>-shiqty.
    ls_save-meins  = <fs_shortage>-meins.
    ls_save-caldt  = sy-datum.

    ls_save-reqtyp = '0010'.
    ls_save-pstat  = '0010'.

    CLEAR: ls_save-iteno,
           ls_save-detno,
           ls_save-banfn,
           ls_save-bnfpo.

    <fs_shortage>-srtno = lv_srtno.
    <fs_shortage>-pstat = '0010'.

    IF <fs_shortage>-shiqty > 0.
      <fs_shortage>-pr_target = abap_true.
      <fs_shortage>-pr_status = '생성대기'.
    ELSE.
      <fs_shortage>-pr_target = abap_false.
      CLEAR <fs_shortage>-pr_status.
    ENDIF.

    """ 신규 INSERT / 기존 UPDATE
    TRY.

        IF ls_existing-srtno IS NOT INITIAL.

          UPDATE ztmma00030
             SET reqty  = @ls_save-reqty,
                 stqty  = @ls_save-stqty,
                 rsqty  = @ls_save-rsqty,
                 inqty  = @ls_save-inqty,
                 qisty  = @ls_save-qisty,
                 sfqty  = @ls_save-sfqty,
                 avqty  = @ls_save-avqty,
                 shiqty = @ls_save-shiqty,
                 meins  = @ls_save-meins,
                 caldt  = @ls_save-caldt,
                 aenam  = @sy-uname,
                 aedat  = @sy-datum,
                 aezet  = @sy-uzeit
           WHERE srtno = @lv_srtno
             AND pstat = '0010'
             AND banfn = @space.

        ELSE.

          ls_save-ernam = sy-uname.
          ls_save-erdat = sy-datum.
          ls_save-erzet = sy-uzeit.

          INSERT ztmma00030 FROM @ls_save.

        ENDIF.

        IF sy-subrc <> 0.
          pv_error = abap_true.
          RETURN.
        ENDIF.

      CATCH cx_sy_open_sql_db INTO DATA(lx_sql).

        pv_error = abap_true.
        MESSAGE lx_sql->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.

    ENDTRY.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_next_srtno
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_SRTNO
*&      <-- PV_ERROR
*&---------------------------------------------------------------------*
FORM zz_get_next_srtno  CHANGING pv_srtno TYPE ztmma00030-srtno
                                 pv_error TYPE abap_bool.

  CLEAR: pv_srtno, pv_error.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'ZMM_SRTNO'
    IMPORTING
      number                  = pv_srtno
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0 OR pv_srtno IS INITIAL.
    pv_error = abap_true.
    MESSAGE 'SRTNO 채번에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_build_requirement
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_exe_build_requirement  CHANGING pv_error TYPE abap_bool.

  TYPES: BEGIN OF ty_fc,
           fcsno TYPE ztmma00020-fcsno,
           iteno TYPE ztmma00020-iteno,
           matnr TYPE ztmma00020-matnr,
           fiqty TYPE ztmma00020-fiqty,
           meins TYPE ztmma00020-meins,
           fcdat TYPE ztmma00010-fcdat,
         END OF ty_fc.

  DATA: lt_fc    TYPE STANDARD TABLE OF ty_fc,
        ls_det   TYPE ztmma00021,
        lv_detno TYPE i,
        lv_srtno TYPE ztmma00030-srtno.

  CLEAR: pv_error, gt_req_new.

  """ 확정 및 활성 Forecast 조회
  SELECT b~fcsno,
         b~iteno,
         b~matnr,
         b~fiqty,
         b~meins,
         a~fcdat
    FROM ztmma00010 AS a
    INNER JOIN ztmma00020 AS b
      ON b~fcsno = a~fcsno
   WHERE a~werks = @pa_werks
     AND a~cstat = '0020'
     AND a~activ = @abap_true
     AND b~fcsno IN @so_fcsno
     AND b~matnr IN @so_matnr
    INTO CORRESPONDING FIELDS OF TABLE @lt_fc.

  IF lt_fc IS INITIAL.
    pv_error = abap_true.
    MESSAGE '확정된 수요예측 대상이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  """ 기존 상세 삭제 후 신규 BOM Snapshot 생성
  LOOP AT lt_fc INTO DATA(ls_fc).

    CLEAR lv_srtno.

    """ PR 생성된 Forecast는 BOM Snapshot 유지
    SELECT SINGLE srtno
      FROM ztmma00030
     WHERE fcsno  = @ls_fc-fcsno
       AND matnr  = @ls_fc-matnr
       AND werks  = @pa_werks
       AND reqtyp = '0010'
       AND ( pstat <> '0010' OR banfn <> @space )
      INTO @lv_srtno.

    IF sy-subrc = 0.
      """ 기존 상세 유지, 재전개하지 않음
      CONTINUE.
    ENDIF.

    """ PR 미생성 Forecast만 상세 재생성
    DELETE FROM ztmma00021 WHERE fcsno = @ls_fc-fcsno AND iteno = @ls_fc-iteno.

    CLEAR: ls_det, lv_detno.

    """ Level 00: Forecast 자재
    lv_detno = 1.

    ls_det-mandt        = sy-mandt.
    ls_det-fcsno        = ls_fc-fcsno.
    ls_det-iteno        = ls_fc-iteno.
    ls_det-detno        = lv_detno.
    ls_det-parent_matnr = ls_fc-matnr.
    ls_det-matnr        = ls_fc-matnr.
    ls_det-bom_level    = '00'.
    ls_det-parent_reqty = ls_fc-fiqty.
    ls_det-parent_meins = ls_fc-meins.
    ls_det-std_reqty    = ls_fc-fiqty.
    ls_det-final_reqty  = ls_fc-fiqty.
    ls_det-meins        = ls_fc-meins.

    ls_det-ernam = sy-uname.
    ls_det-erdat = sy-datum.
    ls_det-erzet = sy-uzeit.

    APPEND ls_det TO gt_req_new.

    """ 하위 BOM 전개
    PERFORM zz_exe_explode_bom
      USING ls_fc-fcsno ls_fc-iteno ls_fc-matnr ls_fc-fiqty ls_fc-meins ls_fc-fcdat 1
      CHANGING lv_detno pv_error.

    IF pv_error = abap_true.
      RETURN.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_explode_bom
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LS_FC_FCSNO
*&      --> LS_FC_ITENO
*&      --> LS_FC_MATNR
*&      --> LS_FC_FIQTY
*&      --> LS_FC_MEINS
*&      --> LS_FC_FCDAT
*&      --> P_1
*&      <-- LV_DETNO
*&      <-- PV_ERROR
*&---------------------------------------------------------------------*
FORM zz_exe_explode_bom  USING    pv_fcsno TYPE ztmma00021-fcsno
                                  pv_iteno TYPE ztmma00021-iteno
                                  pv_matnr TYPE ztmma00021-matnr
                                  pv_qty   TYPE ztmma00021-final_reqty
                                  pv_meins TYPE ztmma00021-meins
                                  pv_date  TYPE ztmma00010-fcdat
                                  pv_level TYPE i
                         CHANGING pv_detno TYPE i
                                  pv_error TYPE abap_bool.

  DATA: lt_head  TYPE STANDARD TABLE OF ztcma00120,
        ls_head  TYPE ztcma00120,
        lt_item  TYPE STANDARD TABLE OF ztcma00130,
        ls_det   TYPE ztmma00021,
        lv_qty   TYPE ztmma00021-final_reqty,
        lv_meins TYPE ztmma00021-meins,
        lv_next  TYPE i.

  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  """ 과도한 계층 또는 순환 BOM 차단
  IF pv_level > 10.
    pv_error = abap_true.
    MESSAGE 'BOM 전개 깊이가 10단계를 초과했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  """ 해당 자재의 사용 가능한 유효 BOM
  SELECT *
    FROM ztcma00120
   WHERE matnr    = @pv_matnr
     AND werks    = @pa_werks
     AND stlst    = '01'
     AND datuv   <= @pv_date
     AND valid_to >= @pv_date
    INTO TABLE @lt_head.

  """ 유효 BOM이 없으면 최하위 자재
  IF lt_head IS INITIAL.
    RETURN.
  ENDIF.

  IF lines( lt_head ) > 1.
    pv_error = abap_true.
    MESSAGE |유효 BOM 중복: { pv_matnr }| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE lt_head INTO ls_head INDEX 1.

  IF ls_head-bmeng <= 0.
    pv_error = abap_true.
    MESSAGE |BOM 기준수량 오류: { pv_matnr }| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF ls_head-bmein <> pv_meins.
    pv_error = abap_true.
    MESSAGE |BOM 기준단위 불일치: { pv_matnr }| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  """ 직접 구성품 조회
  SELECT *
    FROM ztcma00130
   WHERE stlnr = @ls_head-stlnr
    INTO TABLE @lt_item.

  IF lt_item IS INITIAL.
    pv_error = abap_true.
    MESSAGE |BOM 구성품이 없습니다: { pv_matnr }| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT lt_item BY stlkn.

  LOOP AT lt_item INTO DATA(ls_item).

    """ 구성품 자재 마스터 검증
    CLEAR lv_meins.

    SELECT SINGLE meins
      FROM ztcma00020
     WHERE matnr = @ls_item-idnrk
      INTO @lv_meins.

    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE |구성품 자재 마스터 없음: { ls_item-idnrk }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF lv_meins <> ls_item-meins.
      pv_error = abap_true.
      MESSAGE |구성품 수량단위 불일치: { ls_item-idnrk }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    """ 구성품 소요량
    lv_qty = pv_qty * ls_item-menge / ls_head-bmeng.

    pv_detno = pv_detno + 1.

    IF pv_detno > 99999.
      pv_error = abap_true.
      MESSAGE '자재소요 상세번호 한도를 초과했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CLEAR ls_det.

    ls_det-mandt        = sy-mandt.
    ls_det-fcsno        = pv_fcsno.
    ls_det-iteno        = pv_iteno.
    ls_det-detno        = pv_detno.
    ls_det-parent_matnr = pv_matnr.
    ls_det-matnr        = ls_item-idnrk.
    ls_det-bom_level    = pv_level.
    ls_det-stlnr        = ls_head-stlnr.
    ls_det-stlkn        = ls_item-stlkn.
    ls_det-parent_reqty = pv_qty.
    ls_det-parent_meins = pv_meins.
    ls_det-bmeng        = ls_head-bmeng.
    ls_det-bmein        = ls_head-bmein.
    ls_det-bom_menge    = ls_item-menge.
    ls_det-std_reqty    = lv_qty.
    ls_det-final_reqty  = lv_qty.
    ls_det-meins        = ls_item-meins.
    ls_det-ernam        = sy-uname.
    ls_det-erdat        = sy-datum.
    ls_det-erzet        = sy-uzeit.

    APPEND ls_det TO gt_req_new.

    """ 하위 구성품에 BOM이 있으면 추가 전개
    lv_next = pv_level + 1.

    PERFORM zz_exe_explode_bom
      USING pv_fcsno pv_iteno ls_item-idnrk lv_qty ls_item-meins pv_date lv_next
      CHANGING pv_detno pv_error.

    IF pv_error = abap_true.
      RETURN.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_save_requirement
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_exe_save_requirement  CHANGING pv_error TYPE abap_bool.

  CLEAR pv_error.

  IF gt_req_new IS INITIAL.
    RETURN.
  ENDIF.

  TRY.

      INSERT ztmma00021 FROM TABLE gt_req_new.

      IF sy-subrc <> 0.
        pv_error = abap_true.
      ENDIF.

    CATCH cx_sy_open_sql_db INTO DATA(lx_sql).

      pv_error = abap_true.
      MESSAGE lx_sql->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.

  ENDTRY.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_get_component_werks
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_component_werks   USING    pv_matnr    TYPE ztcma00030-matnr
                                       pv_fg_werks TYPE ztcma00030-werks
                              CHANGING pv_werks    TYPE ztcma00030-werks
                                       pv_error    TYPE abap_bool.

  CLEAR: pv_werks, pv_error.

  " 완제품의 플랜트에 구성품이 등록되어 있는지 확인
  SELECT SINGLE werks
    FROM ztcma00030
   WHERE matnr = @pv_matnr
     AND werks = @pv_fg_werks
     AND actyn = 'Y'
    INTO @pv_werks.

  IF sy-subrc <> 0.

    pv_error = abap_true.

    MESSAGE |구성품 { pv_matnr }의 플랜트 { pv_fg_werks } 관리정보가 없습니다.| TYPE 'S' DISPLAY LIKE 'E'.

    RETURN.

  ENDIF.


ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_get_component_bom
*&---------------------------------------------------------------------*
*& 외주 PR 기준 직접 지급자재 소요량 산출
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_component_bom USING    pv_banfn TYPE ztmma00040-banfn
                                   pv_bnfpo TYPE ztmma00040-bnfpo
                          CHANGING pv_error TYPE abap_bool.

  DATA: ls_pr        TYPE ztmma00040,
        lt_bom_head  TYPE STANDARD TABLE OF ztcma00120,
        ls_bom_head  TYPE ztcma00120,
        lt_bom_item  TYPE STANDARD TABLE OF ztcma00130,
        ls_component TYPE ty_component,
        lv_werks     TYPE ztcma00030-werks,
        lv_meins     TYPE ztcma00020-meins.

  CLEAR: pv_error.

  """ 외주 PR 조회
  SELECT SINGLE *
    FROM ztmma00040
   WHERE banfn = @pv_banfn
     AND bnfpo = @pv_bnfpo
    INTO @ls_pr.

  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE '외주 구매요청문서가 존재하지 않습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  """ 외주 PR만 처리
  IF ls_pr-ptype <> '0020'.
    pv_error = abap_true.
    MESSAGE '외주 구매요청문서 유형이 아닙니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF ls_pr-rqty <= 0.
    pv_error = abap_true.
    MESSAGE '외주 구매요청문서 수량이 올바르지 않습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  """ FG의 유효 BOM 조회
  SELECT *
    FROM ztcma00120
   WHERE matnr    = @ls_pr-matnr
     AND werks    = @ls_pr-werks
     AND stlst    = '01'
     AND datuv   <= @sy-datum
     AND valid_to >= @sy-datum
    INTO TABLE @lt_bom_head.

  IF lines( lt_bom_head ) <> 1.
    pv_error = abap_true.
    MESSAGE '외주 구매요청문서의 유효 BOM이 없거나 중복됩니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  READ TABLE lt_bom_head INTO ls_bom_head INDEX 1.

  IF ls_bom_head-bmeng <= 0
     OR ls_bom_head-bmein <> ls_pr-meins.
    pv_error = abap_true.
    MESSAGE 'BOM 기준수량 또는 단위를 확인해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  """ 직접 구성품 조회
  SELECT *
    FROM ztcma00130
   WHERE stlnr = @ls_bom_head-stlnr
    INTO TABLE @lt_bom_item.

  IF lt_bom_item IS INITIAL.
    pv_error = abap_true.
    MESSAGE '외주 BOM 구성품이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT lt_bom_item BY stlkn.

  """ 지급자재 수량 및 플랜트 결정
  LOOP AT lt_bom_item INTO DATA(ls_bom_item).

    CLEAR: ls_component, lv_werks, lv_meins.

    SELECT SINGLE meins
      FROM ztcma00020
     WHERE matnr = @ls_bom_item-idnrk
      INTO @lv_meins.

    IF sy-subrc <> 0
       OR lv_meins <> ls_bom_item-meins.
      pv_error = abap_true.
      MESSAGE |구성품 마스터 또는 단위 오류: { ls_bom_item-idnrk }| TYPE 'S' DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.

    PERFORM zz_get_component_werks USING ls_bom_item-idnrk ls_pr-werks CHANGING lv_werks pv_error.

    IF pv_error = abap_true.
      EXIT.
    ENDIF.

    ls_component-banfn    = ls_pr-banfn.
    ls_component-bnfpo    = ls_pr-bnfpo.
    ls_component-fg_matnr = ls_pr-matnr.
    ls_component-fg_werks = ls_pr-werks.
    ls_component-stlnr    = ls_bom_head-stlnr.
    ls_component-stlkn    = ls_bom_item-stlkn.
    ls_component-matnr    = ls_bom_item-idnrk.
    ls_component-werks    = lv_werks.
    ls_component-meins    = ls_bom_item-meins.

    """ 지급 필요량 = 외주 PR 수량 × BOM 구성수량 / 기준수량
    ls_component-reqty = ls_pr-rqty * ls_bom_item-menge / ls_bom_head-bmeng.

    APPEND ls_component TO gt_component.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_get_component_shortage
*&---------------------------------------------------------------------*
*& 지급자재별 재고 및 부족량 계산
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_component_shortage CHANGING pv_error TYPE abap_bool.

  DATA: lv_po_qty TYPE ztmma00060-menge,
        lv_gr_qty TYPE ztmma00090-menge.

  CLEAR pv_error.

  LOOP AT gt_component ASSIGNING FIELD-SYMBOL(<fs_comp>).

    CLEAR: <fs_comp>-stqty, <fs_comp>-rsqty, <fs_comp>-qisty, <fs_comp>-inqty,
           <fs_comp>-eisbe, <fs_comp>-avqty, <fs_comp>-shiqty, lv_po_qty, lv_gr_qty.

    """ 지급자재 재고 조회
    SELECT SUM( stqty ),
           SUM( rsqty ),
           SUM( qisty )
      FROM ztmma00070
     WHERE matnr = @<fs_comp>-matnr
       AND werks = @<fs_comp>-werks
      INTO ( @<fs_comp>-stqty,
             @<fs_comp>-rsqty,
             @<fs_comp>-qisty ).

    """ 안전재고 조회
    SELECT SINGLE eisbe
      FROM ztcma00030
     WHERE matnr = @<fs_comp>-matnr
       AND werks = @<fs_comp>-werks
       AND actyn = @zlea_y
      INTO @<fs_comp>-eisbe.

    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE |지급자재 플랜트 정보 없음: { <fs_comp>-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    """ PO 수량 조회
    SELECT SUM( menge )
      FROM ztmma00060
     WHERE matnr = @<fs_comp>-matnr
       AND werks = @<fs_comp>-werks
      INTO @lv_po_qty.

    """ 기존 GR 수량 조회
    SELECT SUM( c~menge )
      FROM ztmma00060 AS b
      INNER JOIN ztmma00090 AS c
        ON c~ebeln = b~ebeln
       AND c~ebelp = b~ebelp
     WHERE b~matnr = @<fs_comp>-matnr
       AND b~werks = @<fs_comp>-werks
       AND c~bwart = '101'
      INTO @lv_gr_qty.

    """ 입고예정량
    <fs_comp>-inqty = lv_po_qty - lv_gr_qty.

    IF <fs_comp>-inqty < 0.
      <fs_comp>-inqty = 0.
    ENDIF.

    """ 예상 가용수량
    <fs_comp>-avqty = <fs_comp>-stqty + <fs_comp>-inqty.

    """ 지급자재 부족수량
    <fs_comp>-shiqty = <fs_comp>-reqty + <fs_comp>-eisbe - <fs_comp>-avqty.

    IF <fs_comp>-shiqty < 0.
      <fs_comp>-shiqty = 0.
    ENDIF.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_collect_component
*&---------------------------------------------------------------------*
*& 외주 PR별 지급자재 필요량을 자재/플랜트 단위로 합산
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_collect_component.

  CLEAR gt_comp_total.

  LOOP AT gt_component INTO DATA(ls_component).

    READ TABLE gt_comp_total ASSIGNING FIELD-SYMBOL(<fs_total>)
      WITH TABLE KEY matnr = ls_component-matnr
                     werks = ls_component-werks
                     meins = ls_component-meins.

    IF sy-subrc = 0.

      """ 기존 집계 수량에 추가
      <fs_total>-reqty = <fs_total>-reqty + ls_component-reqty.

    ELSE.

      """ 새로운 자재/플랜트 집계행 생성
      INSERT VALUE ty_comp_total(
        matnr = ls_component-matnr
        werks = ls_component-werks
        meins = ls_component-meins
        reqty = ls_component-reqty
      ) INTO TABLE gt_comp_total.

    ENDIF.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_get_component_targets
*&---------------------------------------------------------------------*
*& Forecast에서 생성된 외주 PR의 지급자재 소요량 통합
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_component_targets CHANGING pv_error TYPE abap_bool.

  TYPES: BEGIN OF ty_pr_target,
           banfn TYPE ztmma00040-banfn,
           bnfpo TYPE ztmma00040-bnfpo,
         END OF ty_pr_target.

  DATA: lt_pr_target TYPE STANDARD TABLE OF ty_pr_target,
        lv_error     TYPE abap_bool.

  CLEAR: pv_error, gt_component, gt_comp_total.

  " 현재 선택된 활성 Forecast와 같은 기간의 유효 외주 PR 조회
  SELECT DISTINCT
         a~banfn,
         a~bnfpo
    FROM ztmma00040 AS a
   INNER JOIN ztmma00030 AS b
      ON b~srtno = a~srdoc
   INNER JOIN ztmma00010 AS h
      ON h~fcsno = b~fcsno
   WHERE a~srtyp = '0010'
     AND a~ptype = '0020'
     AND a~pstat <> '0090'
     AND a~werks = @pa_werks
     AND b~reqtyp = '0010'
     AND b~matnr IN @so_matnr
     AND b~banfn = a~banfn
     AND b~bnfpo = a~bnfpo
     AND EXISTS (
       SELECT *
         FROM ztmma00010 AS cur
        WHERE cur~fcsno IN @so_fcsno
          AND cur~werks = h~werks
          AND cur~fcdat = h~fcdat
          AND cur~tcdat = h~tcdat
          AND cur~cstat = '0020'
          AND cur~activ = @abap_true
     )
    INTO TABLE @lt_pr_target.

  IF lt_pr_target IS INITIAL.
    RETURN.
  ENDIF.

  SORT lt_pr_target BY banfn bnfpo.
  DELETE ADJACENT DUPLICATES FROM lt_pr_target
    COMPARING banfn bnfpo.

  " 외주 PR별 지급자재 소요량 추출
  LOOP AT lt_pr_target INTO DATA(ls_pr_target).

    CLEAR lv_error.

    PERFORM zz_get_component_bom
      USING ls_pr_target-banfn
            ls_pr_target-bnfpo
      CHANGING lv_error.

    IF lv_error = abap_true.
      pv_error = abap_true.
      EXIT.
    ENDIF.

  ENDLOOP.

  IF pv_error = abap_true.
    CLEAR: gt_component, gt_comp_total.
    RETURN.
  ENDIF.

  " 자재/플랜트/단위별 지급자재 수요 합산
  PERFORM zz_exe_collect_component.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_get_total_shortage
*&---------------------------------------------------------------------*
*& 통합 지급자재 부족수량 계산
*&---------------------------------------------------------------------*
FORM zz_get_total_shortage
  CHANGING pv_error TYPE abap_bool.

  DATA: lv_po_qty   TYPE ztmma00060-menge,
        lv_gr_qty   TYPE ztmma00090-menge,
        lv_open_qty TYPE ztmma00040-rqty.

  CLEAR pv_error.

  LOOP AT gt_comp_total ASSIGNING FIELD-SYMBOL(<fs_total>).

    CLEAR: <fs_total>-stqty, <fs_total>-rsqty, <fs_total>-qisty, <fs_total>-inqty,
           <fs_total>-eisbe, <fs_total>-avqty, <fs_total>-shiqty, lv_po_qty, lv_gr_qty,
           <fs_total>-open_pr_qty, lv_open_qty.

    """ 지급자재 플랜트의 재고 조회
    SELECT SUM( stqty ),
           SUM( rsqty ),
           SUM( qisty )
      FROM ztmma00070
     WHERE matnr = @<fs_total>-matnr
       AND werks = @<fs_total>-werks
      INTO ( @<fs_total>-stqty,
             @<fs_total>-rsqty,
             @<fs_total>-qisty ).

    """ 안전재고 조회
    SELECT SINGLE eisbe
      FROM ztcma00030
     WHERE matnr = @<fs_total>-matnr
       AND werks = @<fs_total>-werks
       AND actyn = @zlea_y
      INTO @<fs_total>-eisbe.

    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE |지급자재 관리정보 없음: { <fs_total>-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    """ PO 수량 조회
    SELECT SUM( menge )
      FROM ztmma00060
     WHERE matnr = @<fs_total>-matnr
       AND werks = @<fs_total>-werks
      INTO @lv_po_qty.

    """ 입고 완료수량 조회
    SELECT SUM( c~menge )
      FROM ztmma00060 AS b
      INNER JOIN ztmma00090 AS c
        ON c~ebeln = b~ebeln
       AND c~ebelp = b~ebelp
     WHERE b~matnr = @<fs_total>-matnr
       AND b~werks = @<fs_total>-werks
       AND c~bwart = '101'
      INTO @lv_gr_qty.

    """ 입고예정량
    <fs_total>-inqty = lv_po_qty - lv_gr_qty.

    IF <fs_total>-inqty < 0.
      <fs_total>-inqty = 0.
    ENDIF.

    " PO로 전환되지 않은 일반 PR 잔량 조회
    PERFORM zz_get_open_pr USING <fs_total>-matnr <fs_total>-werks <fs_total>-meins
      CHANGING lv_open_qty pv_error.

    IF pv_error = abap_true.
      RETURN.
    ENDIF.

    <fs_total>-open_pr_qty = lv_open_qty.

    """ 예상 가용수량
    <fs_total>-avqty = <fs_total>-stqty + <fs_total>-inqty.

    """ 통합 부족수량
    <fs_total>-shiqty = <fs_total>-reqty + <fs_total>-eisbe - <fs_total>-avqty - <fs_total>-open_pr_qty.

    IF <fs_total>-shiqty < 0.
      <fs_total>-shiqty = 0.
    ENDIF.


  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_exe_check_component
*&---------------------------------------------------------------------*
*& 기존 지급자재 수요 출처의 중복 저장 여부 검사
*&---------------------------------------------------------------------*
FORM zz_exe_check_component CHANGING pv_error TYPE abap_bool.

  DATA: ls_source TYPE ztmma00031.

  CLEAR pv_error.

  LOOP AT gt_component INTO DATA(ls_component).

    CLEAR ls_source.

    SELECT SINGLE *
      FROM ztmma00031
      WHERE banfn = @ls_component-banfn
        AND bnfpo = @ls_component-bnfpo
        AND stlnr = @ls_component-stlnr
        AND stlkn = @ls_component-stlkn
      INTO @ls_source.

    IF sy-subrc = 0.

      pv_error = abap_true.
      MESSAGE |이미 저장된 지급자재 출처입니다: { ls_component-banfn }/{ ls_component-bnfpo }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_component_save
*&---------------------------------------------------------------------*
*& 지급자재 통합 부족량 및 출처 상세 저장 데이터 구성
*&---------------------------------------------------------------------*
FORM zz_set_component_save CHANGING pv_error TYPE abap_bool.

  DATA: ls_short    TYPE ztmma00030,
        ls_source   TYPE ztmma00031,
        lt_existing TYPE STANDARD TABLE OF ztmma00030,
        lv_srtno    TYPE ztmma00030-srtno,
        lv_new_cnt  TYPE i.

  CLEAR: pv_error, gt_comp_short_save, gt_comp_source_save.

  LOOP AT gt_comp_total INTO DATA(ls_total).

    CLEAR: ls_short, lv_srtno, lv_new_cnt, lt_existing.

    " 해당 자재/플랜트의 신규 출처가 있는지 확인
    LOOP AT gt_comp_new TRANSPORTING NO FIELDS WHERE matnr = ls_total-matnr
      AND werks = ls_total-werks AND meins = ls_total-meins.
      lv_new_cnt = lv_new_cnt + 1.
    ENDLOOP.

    IF lv_new_cnt = 0.
      CONTINUE.
    ENDIF.

    " 일반 PR이 생성되지 않은 기존 부족량 검색
    SELECT *
      FROM ztmma00030
     WHERE matnr  = @ls_total-matnr
       AND werks  = @ls_total-werks
       AND meins  = @ls_total-meins
       AND reqtyp = '0020'
       AND pstat  = '0010'
       AND banfn  = @space
      INTO TABLE @lt_existing.

    IF lines( lt_existing ) > 1.
      pv_error = abap_true.
      MESSAGE |미처리 부족량이 중복됩니다: { ls_total-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF lt_existing IS NOT INITIAL.

      " 기존 미처리 SRTNO 재사용
      READ TABLE lt_existing INTO ls_short INDEX 1.
      lv_srtno = ls_short-srtno.

    ELSE.

      " 신규 부족량번호 발급
      PERFORM zz_get_next_srtno CHANGING lv_srtno pv_error.

      IF pv_error = abap_true.
        RETURN.
      ENDIF.

      CLEAR ls_short.
      ls_short-mandt = sy-mandt.
      ls_short-srtno = lv_srtno.
      ls_short-ernam = sy-uname.
      ls_short-erdat = sy-datum.
      ls_short-erzet = sy-uzeit.

    ENDIF.

    " 전체 지급수요 기준 최신 계산 결과
    ls_short-matnr  = ls_total-matnr.
    ls_short-werks  = ls_total-werks.
    ls_short-reqty  = ls_total-reqty.
    ls_short-stqty  = ls_total-stqty.
    ls_short-rsqty  = ls_total-rsqty.
    ls_short-qisty  = ls_total-qisty.
    ls_short-inqty  = ls_total-inqty.
    ls_short-sfqty  = ls_total-eisbe.
    ls_short-avqty  = ls_total-avqty.
    ls_short-shiqty = ls_total-shiqty.
    ls_short-meins  = ls_total-meins.
    ls_short-caldt  = sy-datum.
    ls_short-reqtyp = '0020'.
    ls_short-pstat  = '0010'.
    APPEND ls_short TO gt_comp_short_save.

    " 신규 출처만 저장 데이터에 추가
    LOOP AT gt_comp_new INTO DATA(ls_comp) WHERE matnr = ls_total-matnr
      AND werks = ls_total-werks AND meins = ls_total-meins.

      CLEAR ls_source.
      ls_source-mandt = sy-mandt.
      ls_source-srtno = lv_srtno.
      ls_source-banfn = ls_comp-banfn.
      ls_source-bnfpo = ls_comp-bnfpo.
      ls_source-stlnr = ls_comp-stlnr.
      ls_source-stlkn = ls_comp-stlkn.
      ls_source-matnr = ls_comp-matnr.
      ls_source-werks = ls_comp-werks.
      ls_source-reqty = ls_comp-reqty.
      ls_source-meins = ls_comp-meins.
      ls_source-ernam = sy-uname.
      ls_source-erdat = sy-datum.
      ls_source-erzet = sy-uzeit.
      APPEND ls_source TO gt_comp_source_save.

    ENDLOOP.

  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_exe_save_component
*&---------------------------------------------------------------------*
*& 지급자재 부족량 및 출처 상세 DB 저장
*& COMMIT / ROLLBACK은 호출 프로그램에서 처리
*&---------------------------------------------------------------------*
FORM zz_exe_save_component CHANGING pv_error TYPE abap_bool.

  DATA: ls_db      TYPE ztmma00030,
        lv_src_cnt TYPE i.

  CLEAR pv_error.

  IF gt_comp_short_save IS INITIAL AND gt_comp_source_save IS INITIAL.
    RETURN.
  ENDIF.

  IF gt_comp_short_save IS INITIAL OR gt_comp_source_save IS INITIAL.
    pv_error = abap_true.
    RETURN.
  ENDIF.

  TRY.

      " 통합 부족량 저장
      LOOP AT gt_comp_short_save INTO DATA(ls_short).

        CLEAR ls_db.

        SELECT SINGLE *
          FROM ztmma00030
         WHERE srtno = @ls_short-srtno
          INTO @ls_db.

        IF sy-subrc = 0.

          " 이미 PR이 생성된 부족량은 수정 금지
          IF ls_db-reqtyp <> '0020' OR ls_db-pstat <> '0010' OR ls_db-banfn IS NOT INITIAL.
            pv_error = abap_true.
            RETURN.
          ENDIF.

          UPDATE ztmma00030
             SET reqty  = @ls_short-reqty,
                 stqty  = @ls_short-stqty,
                 rsqty  = @ls_short-rsqty,
                 qisty  = @ls_short-qisty,
                 inqty  = @ls_short-inqty,
                 sfqty  = @ls_short-sfqty,
                 avqty  = @ls_short-avqty,
                 shiqty = @ls_short-shiqty,
                 caldt  = @ls_short-caldt,
                 aenam  = @sy-uname,
                 aedat  = @sy-datum,
                 aezet  = @sy-uzeit
           WHERE srtno  = @ls_short-srtno
             AND reqtyp = '0020'
             AND pstat  = '0010'
             AND banfn  = @space.

        ELSE.

          INSERT ztmma00030 FROM @ls_short.

        ENDIF.

        IF sy-subrc <> 0 OR sy-dbcnt <> 1.
          pv_error = abap_true.
          RETURN.
        ENDIF.

      ENDLOOP.

      " 신규 지급자재 출처 저장
      lv_src_cnt = lines( gt_comp_source_save ).

      INSERT ztmma00031 FROM TABLE @gt_comp_source_save.

      IF sy-subrc <> 0 OR sy-dbcnt <> lv_src_cnt.
        pv_error = abap_true.
        RETURN.
      ENDIF.

    CATCH cx_sy_open_sql_db INTO DATA(lx_sql).

      pv_error = abap_true.
      MESSAGE lx_sql->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.

  ENDTRY.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_exe_filter_new
*&---------------------------------------------------------------------*
*& 기존에 저장된 지급자재 출처를 제외하고 신규 출처만 유지
*&---------------------------------------------------------------------*
FORM zz_exe_filter_new CHANGING pv_error TYPE abap_bool.

  DATA: lt_new_component TYPE STANDARD TABLE OF ty_component,
        ls_source        TYPE ztmma00031.

  CLEAR pv_error.

  LOOP AT gt_component INTO DATA(ls_comp).

    CLEAR ls_source.

    SELECT SINGLE *
      FROM ztmma00031
     WHERE banfn = @ls_comp-banfn
       AND bnfpo = @ls_comp-bnfpo
       AND stlnr = @ls_comp-stlnr
       AND stlkn = @ls_comp-stlkn
      INTO @ls_source.

    IF sy-subrc = 0.

      " 기존 출처가 변경됐는지 검사
      IF ls_source-matnr <> ls_comp-matnr
         OR ls_source-werks <> ls_comp-werks
         OR ls_source-meins <> ls_comp-meins
         OR ls_source-reqty <> ls_comp-reqty.

        pv_error = abap_true.
        MESSAGE '기존 지급자재 출처 정보가 변경되었습니다.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.

      ENDIF.

      CONTINUE.

    ENDIF.

    APPEND ls_comp TO lt_new_component.

  ENDLOOP.

  " GT_COMPONENT 및 GT_COMP_TOTAL은 변경하지 않음
  " 신규 출처 목록은 별도로 보관
  gt_comp_new = lt_new_component.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_get_open_pr
*&---------------------------------------------------------------------*
*& 일반 PR 중 아직 PO로 전환되지 않은 수량 계산
*&---------------------------------------------------------------------*
FORM zz_get_open_pr USING    pv_matnr TYPE ztmma00040-matnr
                             pv_werks TYPE ztmma00040-werks
                             pv_meins TYPE ztmma00040-meins
                    CHANGING pv_open_qty TYPE ztmma00040-rqty
                             pv_error    TYPE abap_bool.

  DATA: lt_pr     TYPE STANDARD TABLE OF ztmma00040,
        lv_po_qty TYPE ztmma00060-menge,
        lv_remain TYPE ztmma00040-rqty.

  CLEAR: pv_open_qty, pv_error.

  " 해당 자재/플랜트의 일반 PR 조회
  SELECT *
    FROM ztmma00040
   WHERE matnr = @pv_matnr
     AND werks = @pv_werks
     AND meins = @pv_meins
     AND ptype = '0010'
     AND pstat <> '0090'
    INTO TABLE @lt_pr.

  " 각 PR의 PO 전환수량 계산
  LOOP AT lt_pr INTO DATA(ls_pr).

    CLEAR: lv_po_qty, lv_remain.

    SELECT SUM( menge )
      FROM ztmma00060
     WHERE banfn = @ls_pr-banfn
       AND bnfpo = @ls_pr-bnfpo
      INTO @lv_po_qty.

    " PR 수량 - PO 전환수량
    lv_remain = ls_pr-rqty - lv_po_qty.

    IF lv_remain < 0.
      pv_error = abap_true.
      MESSAGE |구매요청문서의 구매오더 전환수량이 요청수량을 초과했습니다: { ls_pr-banfn }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 미전환 잔량 합산
    pv_open_qty = pv_open_qty + lv_remain.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_process_component
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_exe_process_component  CHANGING pv_error TYPE abap_bool.

  CLEAR: pv_error, gt_comp_new, gt_comp_short_save, gt_comp_source_save.

  " 외주 PR에서 지급자재 소요량 추출
  PERFORM zz_get_component_targets CHANGING pv_error.

  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  IF gt_component IS INITIAL.
    RETURN.
  ENDIF.

  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  " 기존/신규 출처 분리
  PERFORM zz_exe_filter_new CHANGING pv_error.

  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  " 신규 출처가 없으면 저장하지 않음
  IF gt_comp_new IS INITIAL.
    RETURN.
  ENDIF.

  " 전체 수요 기준 부족량 계산
  PERFORM zz_get_total_shortage CHANGING pv_error.

  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  " 저장 데이터 구성
  PERFORM zz_set_component_save CHANGING pv_error.

  IF pv_error = abap_true.
    RETURN.
  ENDIF.

  " 부족량/출처 DB 저장
  PERFORM zz_exe_save_component CHANGING pv_error.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_create_component_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_exe_create_component_pr CHANGING pv_error TYPE abap_bool.

  DATA: lt_request TYPE zttmma00010,
        lv_created TYPE i,
        lv_skipped TYPE i,
        lv_message TYPE string.

  CLEAR pv_error.

  PERFORM zz_get_component_pr CHANGING lt_request.

  IF lt_request IS INITIAL.
    MESSAGE '생성할 지급자재 일반 구매요청문서가 없습니다.' TYPE 'S'.
    RETURN.
  ENDIF.

  PERFORM zz_exe_pr_request
    USING lt_request abap_false
    CHANGING pv_error
             lv_created
             lv_skipped
             lv_message.

  IF pv_error = abap_true.
    MESSAGE lv_message TYPE 'S' DISPLAY LIKE 'E'.
  ELSE.
    MESSAGE |지급자재 구매요청문서 신규 { lv_created }건, 제외 { lv_skipped }건| TYPE 'S'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM ZZ_GET_BATCH_PR_REQUEST
*& 화면(ALV) 없이, 부족량 DB 기준 Forecast PR 생성대상 구성
*&---------------------------------------------------------------------*
FORM zz_get_batch_pr_request CHANGING pt_request TYPE zttmma00010.
  DATA ls_request TYPE zsmma00010.
  CLEAR pt_request.

  SELECT a~srtno
    FROM ztmma00030 AS a
    INNER JOIN ztmma00010 AS b ON b~fcsno = a~fcsno
   WHERE a~reqtyp = '0010'
     AND b~cstat = '0020'
     AND b~activ = @abap_true
     AND a~werks  = @pa_werks
     AND a~fcsno  IN @so_fcsno
     AND a~matnr  IN @so_matnr
     AND a~pstat  = '0010'
     AND a~banfn  = @space
     AND a~shiqty > 0
    INTO TABLE @DATA(lt_srtno).

  LOOP AT lt_srtno INTO DATA(ls_srtno).
    CLEAR ls_request.
    ls_request-srtyp = '0010'.
    ls_request-srdoc = ls_srtno-srtno.
    APPEND ls_request TO pt_request.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM zz_exe_pr_request
*& 수동/배치 공통 처리. FM은 COMMIT하지 않고, 호출 측에서 확정 및 잠금 해제.
*& ENQUEUE_E_TABLE: ZTMMA00040 / VARKEY=SPACE / SCOPE=1
*&---------------------------------------------------------------------*
FORM zz_exe_pr_request
  USING    pt_request     TYPE zttmma00010
           pv_external_luw TYPE abap_bool
  CHANGING pv_error       TYPE abap_bool
           pv_created     TYPE i
           pv_skipped     TYPE i
           pv_message     TYPE string.

  DATA: lt_result TYPE zttmma00020,
        lt_return TYPE bapiret2_t.

  CLEAR: pv_error, pv_created, pv_skipped, pv_message.

  IF pt_request IS INITIAL.
    RETURN.
  ENDIF.

  """ 공통 PR 생성 FM 호출
  CALL FUNCTION 'ZFM_MM_PR_CREATE'
    EXPORTING
      it_pr_request = pt_request
      iv_lock_held  = pv_external_luw
    IMPORTING
      et_pr_result  = lt_result
      et_return     = lt_return.

  """ 반환 오류 확인
  LOOP AT lt_return INTO DATA(ls_return).

    IF ls_return-type = zlea_e OR ls_return-type = zlea_a OR ls_return-type = zlea_x.
      pv_error   = abap_true.
      pv_message = ls_return-message.
      EXIT.
    ENDIF.

  ENDLOOP.

  """ 요청과 결과 건수 검증
  IF pv_error = abap_false.
    IF lines( lt_result ) <> lines( pt_request ).
      pv_error = abap_true.
      pv_message = '구매요청문서 생성 요청과 결과 건수가 일치하지 않습니다.'.
    ENDIF.
  ENDIF.

  """ 개별 처리결과 검증
  IF pv_error = abap_false.

    LOOP AT lt_result INTO DATA(ls_result).

      CASE ls_result-result.

        WHEN 'CREATED'.
          pv_created = pv_created + 1.

        WHEN 'EXISTING' OR 'SKIPPED'.
          pv_skipped = pv_skipped + 1.

        WHEN OTHERS.
          pv_error = abap_true.
          pv_message = '구매요청문서 생성 결과에 오류가 있습니다.'.
          EXIT.

      ENDCASE.

    ENDLOOP.

  ENDIF.

  """ 전체 오류 메시지 보완
  IF pv_error = abap_true AND pv_message IS INITIAL.
    pv_message = '구매요청문서 처리 실패'.
  ENDIF.

  """ 외부 LUW: 상위 FORM에서 트랜잭션 처리
  IF pv_external_luw = abap_true.
    RETURN.
  ENDIF.

  """ 개별 호출: 현재 FORM에서 트랜잭션 처리
  IF pv_error = abap_true.

    ROLLBACK WORK.

  ELSE.

    COMMIT WORK AND WAIT.

    IF sy-subrc <> 0.
      pv_error = abap_true.
      pv_message = '구매요청문서 저장 COMMIT 결과를 확인해 주세요.'.
    ENDIF.

  ENDIF.

  """ 수동 호출 시 PR 테이블 잠금 해제
  CALL FUNCTION 'DEQUEUE_E_TABLE'
    EXPORTING
      mode_rstable = 'E'
      tabname      = 'ZTMMA00040'
      varkey       = space
      _scope       = '1'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form 1000_onli
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM 1000_onli.

  DATA lv_error TYPE abap_bool.

  CLEAR: gv_run_ok,
         gv_preview_ready,
         gv_pr_confirmed,
         gt_shortage,
         gt_component,
         gt_comp_total,
         gt_comp_preview,
         gt_comp_display,
         gt_pr_preview.

  " 1. 기존 Forecast BOM Snapshot 조회
  PERFORM zz_get_requirement_data.

  IF gt_shortage IS INITIAL.
    MESSAGE '조회할 수요예측 자재소요 데이터가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 2. FG 기본정보와 수급정보 조회
  PERFORM zz_get_material_text.
  PERFORM zz_get_stock_data.
  PERFORM zz_get_material_info.
  PERFORM zz_get_incoming_qty.

  " 3. 기존 부족량 문서 연결정보 조회
  PERFORM zz_get_fg_document.

  " 4. 기본 부족수량 계산
  PERFORM zz_exe_calc_shortage.

  " 5. 기존 PR 공급량을 읽고 부족량 재계산
  "    DB 수정 없음
  PERFORM zz_exe_refresh_result.

  " 6. 기존 외주 PR의 구성품 소요량 조회
  PERFORM zz_get_component_targets
    CHANGING lv_error.

  IF lv_error = abap_true.
    RETURN.
  ENDIF.

  " 7. 기존 외주 PR 지급자재 부족량 계산
  IF gt_comp_total IS NOT INITIAL.

    PERFORM zz_get_total_shortage
      CHANGING lv_error.

    IF lv_error = abap_true.
      RETURN.
    ENDIF.

  ENDIF.

  " 8. 아직 PR 미생성 FG의 지급자재 Preview
  PERFORM zz_build_comp_preview
    CHANGING lv_error.

  IF lv_error = abap_true.
    RETURN.
  ENDIF.

  " 9. 통합 지급자재 부족량 계산
  PERFORM zz_calc_comp_preview
    CHANGING lv_error.

  IF lv_error = abap_true.
    RETURN.
  ENDIF.

  " FG 및 지급자재 PR 생성 후보 구성
  PERFORM zz_build_pr_preview.

  gv_preview_ready = abap_true.
  gv_run_ok = abap_true.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_exe_check_prpo
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_check_prpo USING    pv_banfn TYPE ztmma00040-banfn
                                 pv_bnfpo TYPE ztmma00040-bnfpo
                        CHANGING pv_has_po TYPE abap_bool.

  DATA lv_ebeln TYPE ztmma00060-ebeln.

  CLEAR pv_has_po.

  SELECT SINGLE ebeln
    FROM ztmma00060
   WHERE banfn = @pv_banfn
     AND bnfpo = @pv_bnfpo
    INTO @lv_ebeln.

  IF sy-subrc = 0.
    pv_has_po = abap_true.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& Form zz_get_fg_dependent
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_fg_dependent USING    pv_banfn  TYPE ztmma00040-banfn
                                    pv_bnfpo  TYPE ztmma00040-bnfpo
                           CHANGING pv_locked TYPE abap_bool.

  DATA lv_banfn TYPE ztmma00031-banfn.

  CLEAR: pv_locked, lv_banfn.

  SELECT SINGLE banfn
    FROM ztmma00031
   WHERE banfn = @pv_banfn
     AND bnfpo = @pv_bnfpo
    INTO @lv_banfn.

  IF sy-subrc = 0.
    pv_locked = abap_true.
  ELSE.
    pv_locked = abap_false.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_reconcile_forecast_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_reconcile_forecast_pr CHANGING pv_error TYPE abap_bool.

  TYPES: BEGIN OF ty_pr,
           banfn TYPE ztmma00040-banfn,
           bnfpo TYPE ztmma00040-bnfpo,
           rqty  TYPE ztmma00040-rqty,
           astat TYPE ztmma00040-astat,
           pstat TYPE ztmma00040-pstat,
         END OF ty_pr.

  DATA: lt_pr       TYPE STANDARD TABLE OF ty_pr,
        ls_pr       TYPE ty_pr,
        lv_has_po   TYPE abap_bool,
        lv_dep      TYPE abap_bool,
        lv_locked   TYPE ztmma00040-rqty,
        lv_other    TYPE ztmma00040-rqty,
        lt_all_pr   TYPE STANDARD TABLE OF ztmma00040,
        lv_po_sum   TYPE ztmma00060-menge,
        lv_remain   TYPE ztmma00040-rqty,
        lv_target   TYPE ztmma00040-rqty,
        lv_alloc    TYPE ztmma00040-rqty,
        lv_assign   TYPE ztmma00040-rqty,
        lv_target_1 TYPE ztmma00040-rqty,
        lv_excess   TYPE ztmma00040-rqty.

  CLEAR pv_error.

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs>).

    CLEAR: lt_pr, lt_all_pr, lv_locked, lv_other, lv_target, lv_alloc, lv_target_1.

    " 최신 예측의 기간 조회
    SELECT SINGLE fcdat, tcdat
      FROM ztmma00010
     WHERE fcsno = @<fs>-fcsno
      INTO (@DATA(lv_fcdat), @DATA(lv_tcdat)).

    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.

    " 같은 예측기간에 생성된 과거/현재 Forecast PR에 한정
    SELECT p~banfn, p~bnfpo, p~rqty, p~astat, p~pstat
      FROM ztmma00040 AS p
     INNER JOIN ztmma00030 AS sh ON sh~srtno = p~srdoc
     INNER JOIN ztmma00010 AS oh ON oh~fcsno = sh~fcsno
     WHERE p~srtyp = '0010'
       AND p~matnr = @<fs>-matnr
       AND p~werks = @<fs>-werks
       AND p~meins = @<fs>-meins
       AND p~pstat <> '0050'
       AND p~pstat <> '0090'
       AND sh~reqtyp = '0010'
       AND oh~werks = @<fs>-werks
       AND oh~fcdat = @lv_fcdat
       AND oh~tcdat = @lv_tcdat
      INTO TABLE @lt_pr.

    SORT lt_pr BY banfn bnfpo.

    " 별도 출처의 PR은 FG 공급량 계산에서만 사용; 직접 수정하지 않음
    LOOP AT lt_pr INTO ls_pr.

      PERFORM zz_exe_check_prpo USING ls_pr-banfn ls_pr-bnfpo CHANGING lv_has_po.
      PERFORM zz_get_fg_dependent USING ls_pr-banfn ls_pr-bnfpo CHANGING lv_dep.

      IF lv_has_po = abap_true OR lv_dep = abap_true.

        " PO가 있으면 PO 미입고분은 INQTY에서 이미 반영: 이중차감 방지
        IF lv_has_po = abap_false.
          lv_locked = lv_locked + ls_pr-rqty.
        ENDIF.

      ENDIF.

    ENDLOOP.

    " 다른 출처의 공급수량 조회
    CLEAR lt_all_pr.

    SELECT p~*
      FROM ztmma00040 AS p
     WHERE p~matnr = @<fs>-matnr
       AND p~werks = @<fs>-werks
       AND p~meins = @<fs>-meins
       AND p~pstat <> '0090'
       AND p~pstat <> '0050'
       AND p~srtyp = '0010'
       AND EXISTS (
          SELECT *
            FROM ztmma00030 AS s
           INNER JOIN ztmma00010 AS h
              ON h~fcsno = s~fcsno
           WHERE s~srtno = p~srdoc
             AND h~fcdat = @lv_fcdat
             AND h~tcdat = @lv_tcdat
             AND h~werks = @<fs>-werks
        )
      INTO TABLE @lt_all_pr.

    LOOP AT lt_all_pr INTO DATA(ls_all_pr).

      READ TABLE lt_pr TRANSPORTING NO FIELDS
        WITH KEY banfn = ls_all_pr-banfn bnfpo = ls_all_pr-bnfpo.

      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      CLEAR lv_po_sum.

      SELECT SUM( menge )
        FROM ztmma00060
       WHERE banfn = @ls_all_pr-banfn AND bnfpo = @ls_all_pr-bnfpo
        INTO @lv_po_sum.

      lv_remain = ls_all_pr-rqty - lv_po_sum.

      IF lv_remain < 0.
        pv_error = abap_true.
        MESSAGE '구매요청문서/구매오더 수량이 불일치합니다.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      lv_other = lv_other + lv_remain.

    ENDLOOP.

    " 현재고, PO 미입고, 잠긴 PR 및 다른 유효 PR의 미전환량 차감
    lv_target = <fs>-reqty + <fs>-eisbe
              - <fs>-stqty - <fs>-inqty - lv_locked - lv_other.

    IF lv_target < 0.
      lv_target = 0.
    ENDIF.

    lv_target_1 = lv_target.

    " PO/지급자재 PR 미연결 FG PR만 수정 또는 취소.
    LOOP AT lt_pr INTO ls_pr.

      PERFORM zz_exe_check_prpo USING ls_pr-banfn ls_pr-bnfpo CHANGING lv_has_po.
      PERFORM zz_get_fg_dependent USING ls_pr-banfn ls_pr-bnfpo CHANGING lv_dep.

      IF lv_has_po = abap_true OR lv_dep = abap_true.
        CONTINUE.
      ENDIF.

      lv_assign = lv_target_1.

      IF lv_assign > 0.

        IF ls_pr-rqty <> lv_assign.

          " 실제 수량이 변경된 경우에만 재승인 처리
          UPDATE ztmma00040
             SET rqty  = @lv_assign,
                 astat = '0010'
           WHERE banfn = @ls_pr-banfn
             AND bnfpo = @ls_pr-bnfpo
             AND pstat = @ls_pr-pstat
             AND rqty  = @ls_pr-rqty.

          IF sy-subrc <> 0 OR sy-dbcnt <> 1.
            pv_error = abap_true.
            MESSAGE '구매요청문서 수량 변경에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
            RETURN.
          ENDIF.

        ENDIF.

      ELSE.

        " 필요한 조달수량이 0이면 PR 취소
        UPDATE ztmma00040
           SET pstat = '0090', astat = '0010'
         WHERE banfn = @ls_pr-banfn
           AND bnfpo = @ls_pr-bnfpo
           AND pstat = @ls_pr-pstat
           AND rqty  = @ls_pr-rqty.

        IF sy-subrc <> 0 OR sy-dbcnt <> 1.
          pv_error = abap_true.
          MESSAGE '구매요청문서 취소에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

      ENDIF.

      " 첫 번째 조정 가능 PR에 필요량 배정
      " 나머지 조정 가능 PR은 취소 대상
      lv_target_1 = 0.

    ENDLOOP.

    " 전체 유효 PR의 미전환 공급량 합계 (PO로 전환된 수량은 제외)
    CLEAR <fs>-open_pr_qty.

    " 다른 출처의 공급수량 조회
    CLEAR lt_all_pr.

    SELECT p~*
      FROM ztmma00040 AS p
      WHERE p~matnr = @<fs>-matnr
        AND p~werks = @<fs>-werks
        AND p~meins = @<fs>-meins
        AND p~pstat <> '0090'
        AND p~pstat <> '0050'
        AND p~srtyp = '0010'
        AND EXISTS (
          SELECT *
            FROM ztmma00030 AS s
            INNER JOIN ztmma00010 AS h
              ON h~fcsno = s~fcsno
            WHERE s~srtno = p~srdoc
              AND h~fcdat = @lv_fcdat
              AND h~tcdat = @lv_tcdat
              AND h~werks = @<fs>-werks
        )
      INTO TABLE @lt_all_pr.

    LOOP AT lt_all_pr INTO ls_all_pr.

      CLEAR lv_po_sum.

      SELECT SUM( menge )
        FROM ztmma00060
       WHERE banfn = @ls_all_pr-banfn
         AND bnfpo = @ls_all_pr-bnfpo
        INTO @lv_po_sum.

      lv_remain = ls_all_pr-rqty - lv_po_sum.

      IF lv_remain < 0.
        pv_error = abap_true.
        MESSAGE '구매요청문서/구매오더 전환수량이 요청수량을 초과합니다.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      <fs>-open_pr_qty = <fs>-open_pr_qty + lv_remain.

    ENDLOOP.

    " 기존 공급량이 최신 수요보다 많은지 확인
    CLEAR lv_excess.

    lv_excess = <fs>-stqty + <fs>-inqty + lv_locked + lv_other - <fs>-reqty - <fs>-eisbe.

    IF lv_excess > 0 AND lv_locked > 0.

      IF sy-batch = abap_true.
        WRITE: / '초과 조달 경고', '자재:', <fs>-matnr, '초과수량:', lv_excess, '단위:', <fs>-meins.
      ELSE.
        MESSAGE |{ <fs>-matnr }: 기존 조달 유지, 초과 예상 { lv_excess } { <fs>-meins }| TYPE 'S' DISPLAY LIKE 'W'.
      ENDIF.

    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_lock_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LV_ERROR
*&---------------------------------------------------------------------*
FORM zz_exe_lock_pr  CHANGING pv_error TYPE abap_bool.

  CLEAR pv_error.

  CALL FUNCTION 'ENQUEUE_E_TABLE'
    EXPORTING
      mode_rstable   = 'E'
      tabname        = 'ZTMMA00040'
      varkey         = space
      _scope         = '1'
      _wait          = space
    EXCEPTIONS
      foreign_lock   = 1
      system_failure = 2
      OTHERS         = 3.

  IF sy-subrc <> 0.
    pv_error = abap_true.

    MESSAGE '다른 사용자가 구매요청문서를 처리 중입니다. 잠시 후 다시 실행해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_unlock_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_unlock_pr .

  CALL FUNCTION 'DEQUEUE_E_TABLE'
    EXPORTING
      mode_rstable = 'E'
      tabname      = 'ZTMMA00040'
      varkey       = space
      _scope       = '1'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_get_component_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      <-- LT_REQUEST
*&---------------------------------------------------------------------*
FORM zz_get_component_pr  CHANGING pt_request TYPE zttmma00010.

  DATA ls_request TYPE zsmma00010.

  CLEAR pt_request.

  SELECT DISTINCT c~srtno
    FROM ztmma00030 AS c
    INNER JOIN ztmma00031 AS d
      ON d~srtno = c~srtno
    INNER JOIN ztmma00040 AS p
      ON p~banfn = d~banfn
     AND p~bnfpo = d~bnfpo
    INNER JOIN ztmma00030 AS f
      ON f~srtno = p~srdoc
   WHERE c~reqtyp = '0020'
     AND c~shiqty > 0
     AND c~banfn = @space
     AND c~pstat = '0010'
     AND p~srtyp = '0010'
     AND p~ptype = '0020'
     AND p~pstat <> '0090'
     AND p~werks = @pa_werks
     AND f~reqtyp = '0010'
     AND f~fcsno IN @so_fcsno
     AND f~matnr IN @so_matnr
    INTO TABLE @DATA(lt_srtno).

  LOOP AT lt_srtno INTO DATA(ls_srtno).

    CLEAR ls_request.
    ls_request-srtyp = '0030'.
    ls_request-srdoc = ls_srtno-srtno.

    APPEND ls_request TO pt_request.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_refresh_result
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_refresh_result .

  DATA: lt_pr     TYPE STANDARD TABLE OF ztmma00040,
        lv_fcdat  TYPE ztmma00010-fcdat,
        lv_tcdat  TYPE ztmma00010-tcdat,
        lv_po_qty TYPE ztmma00060-menge,
        lv_remain TYPE ztmma00040-rqty,
        ls_short  TYPE ztmma00030.

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs>).

    CLEAR: lv_fcdat, lv_tcdat, lt_pr,
           ls_short, <fs>-open_pr_qty.

    " 현재 Forecast 기간 조회
    SELECT SINGLE fcdat, tcdat
      FROM ztmma00010
      WHERE fcsno = @<fs>-fcsno
      INTO ( @lv_fcdat, @lv_tcdat ).

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    " 동일 Forecast 기간의 유효 FG PR 조회
    SELECT p~*
      FROM ztmma00040 AS p
      WHERE p~matnr = @<fs>-matnr
        AND p~werks = @<fs>-werks
        AND p~meins = @<fs>-meins
        AND p~srtyp = '0010'
        AND p~pstat <> '0050'
        AND p~pstat <> '0090'
        AND EXISTS (
          SELECT *
            FROM ztmma00030 AS s
            INNER JOIN ztmma00010 AS h
              ON h~fcsno = s~fcsno
           WHERE s~srtno = p~srdoc
             AND h~fcdat = @lv_fcdat
             AND h~tcdat = @lv_tcdat
             AND h~werks = @<fs>-werks
        )
      INTO TABLE @lt_pr.

    LOOP AT lt_pr INTO DATA(ls_pr).

      CLEAR: lv_po_qty, lv_remain.

      SELECT SUM( menge )
        FROM ztmma00060
        WHERE banfn = @ls_pr-banfn
          AND bnfpo = @ls_pr-bnfpo
        INTO @lv_po_qty.

      lv_remain = ls_pr-rqty - lv_po_qty.

      IF lv_remain > 0.
        <fs>-open_pr_qty =
          <fs>-open_pr_qty + lv_remain.
      ENDIF.

    ENDLOOP.

    " 최신 공급량 기준 추가 부족수량 재계산
    <fs>-shiqty =
        <fs>-reqty
      + <fs>-eisbe
      - <fs>-avqty
      - <fs>-open_pr_qty.

    IF <fs>-shiqty < 0.
      <fs>-shiqty = 0.
    ENDIF.

    " 현재 부족량 문서의 PR 연결상태 조회
    SELECT SINGLE *
      FROM ztmma00030
      WHERE srtno = @<fs>-srtno
      INTO @ls_short.

    IF sy-subrc = 0.

      <fs>-banfn = ls_short-banfn.
      <fs>-pstat = ls_short-pstat.

    ENDIF.

    IF <fs>-shiqty = 0.

      <fs>-pr_target = abap_false.
      <fs>-pr_status = '처리완료'.

    ELSE.

      <fs>-pr_target = abap_true.
      <fs>-pr_status = '생성대기'.

    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_auto_rollback
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_auto_rollback .

  ROLLBACK WORK.
  PERFORM zz_exe_unlock_pr.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form zz_exe_show_kpi
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_show_kpi .

  DATA: lt_widget      TYPE zcl_cm_kpi_html=>tt_widget,
        lv_fg_cnt      TYPE i,
        lv_comp_cnt    TYPE i,
        lv_pr_cnt      TYPE i,
        lv_created_cnt TYPE i,
        lv_fg_txt      TYPE string,
        lv_comp_txt    TYPE string,
        lv_pr_txt      TYPE string,
        lv_created_txt TYPE string.

  CLEAR: lt_widget,
         lv_fg_cnt,
         lv_comp_cnt,
         lv_pr_cnt,
         lv_created_cnt.

  " 1. FG 부족 대상
  LOOP AT gt_shortage INTO DATA(ls_shortage)
    WHERE shiqty > 0.

    lv_fg_cnt = lv_fg_cnt + 1.

  ENDLOOP.

  " 2. 지급자재 부족 대상
  LOOP AT gt_comp_preview INTO DATA(ls_comp)
    WHERE shiqty > 0.

    lv_comp_cnt = lv_comp_cnt + 1.

  ENDLOOP.

  " 3. PR 생성 후보 및 생성 완료
  LOOP AT gt_pr_preview INTO DATA(ls_pr).

    CASE ls_pr-result.

      WHEN '생성후보' OR '출처확정전' OR '출처검증전'.

        lv_pr_cnt = lv_pr_cnt + 1.

      WHEN '생성완료'.

        lv_created_cnt = lv_created_cnt + 1.

    ENDCASE.

  ENDLOOP.

  " 4. KPI 표시 문자열
  lv_fg_txt      = |{ lv_fg_cnt }건|.
  lv_comp_txt    = |{ lv_comp_cnt }건|.
  lv_pr_txt      = |{ lv_pr_cnt }건|.
  lv_created_txt = |{ lv_created_cnt }건|.

  " FG 부족 대상
  APPEND zcl_cm_kpi_html=>w_card(
    iv_label = '완제품 부족 대상'
    iv_value = lv_fg_txt
    iv_sub   = '완제품 부족량 조회'
    iv_color = 'B' ) TO lt_widget.

  " 지급자재 부족
  APPEND zcl_cm_kpi_html=>w_card(
    iv_label = '지급자재 부족'
    iv_value = lv_comp_txt
    iv_sub   = 'BOM 구성품 부족량'
    iv_color = 'Y' ) TO lt_widget.

  " PR 생성 후보
  APPEND zcl_cm_kpi_html=>w_card(
    iv_label = '구매요청문서 생성 후보'
    iv_value = lv_pr_txt
    iv_sub   = '완제품 및 지급자재 검토 대상'
    iv_color = 'N' ) TO lt_widget.

  " PR 생성 완료
  APPEND zcl_cm_kpi_html=>w_card(
    iv_label = '구매요청문서 생성 완료'
    iv_value = lv_created_txt
    iv_sub   = '조회 대상 구매요청 생성 완료'
    iv_color = 'G' ) TO lt_widget.

  " HTML 갱신
  go_kpi->show_widgets(
    it_widget = lt_widget
    iv_title = |부족량 및 구매요청문서 생성 현황 - 플랜트 { pa_werks }| ).


ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_SET_COMP_FCAT
*&---------------------------------------------------------------------*
FORM zz_set_comp_fcat.

  DATA: ls_fcat TYPE lvc_s_fcat,
        lv_pos  TYPE i.

  CLEAR: gt_comp_fcat, lv_pos.

  DEFINE add_comp_field.

    CLEAR ls_fcat.

    lv_pos = lv_pos + 1.

    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-scrtext_l = &2.
    ls_fcat-scrtext_m = &2.
    ls_fcat-scrtext_s = &2.
    ls_fcat-reptext   = &2.
    ls_fcat-col_pos   = lv_pos.

    APPEND ls_fcat TO gt_comp_fcat.

  END-OF-DEFINITION.

  " 자재 기본정보
  add_comp_field 'MATNR'       '지급자재번호'.
  add_comp_field 'WERKS'       '플랜트'.
  add_comp_field 'MEINS'       '단위'.

  " 지급자재 소요량
  add_comp_field 'REQTY'       '지급 필요량'.

  " 재고 및 공급
  add_comp_field 'STQTY'       '현재고'.
  add_comp_field 'RSQTY'       '예약수량'.
  add_comp_field 'QISTY'       '검사재고'.
  add_comp_field 'INQTY'       '입고예정량'.
  add_comp_field 'EISBE'       '안전재고'.

  " 부족량 계산
  add_comp_field 'AVQTY'       '예상가용수량'.
  add_comp_field 'OPEN_PR_QTY' '기존 구매요청 공급량'.
  add_comp_field 'SHIQTY'      '추가 부족수량'.

  " Key 및 수량 단위 연결
  LOOP AT gt_comp_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).

    CASE <fs_fcat>-fieldname.

      WHEN 'MATNR' OR 'WERKS'.
        <fs_fcat>-key = abap_true.

      WHEN 'REQTY' OR 'STQTY' OR 'RSQTY'
        OR 'QISTY' OR 'INQTY' OR 'EISBE'
        OR 'AVQTY' OR 'OPEN_PR_QTY' OR 'SHIQTY'.

        <fs_fcat>-qfieldname = 'MEINS'.

    ENDCASE.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_SET_COMP_LAYOUT
*&---------------------------------------------------------------------*
FORM zz_set_comp_layout.

  CLEAR gs_comp_layo.

  gs_comp_layo-zebra      = abap_true.
  gs_comp_layo-cwidth_opt = abap_true.
  gs_comp_layo-sel_mode   = 'A'.
  gs_comp_layo-grid_title = '지급자재별 부족량 현황'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_SET_COMP_DISPLAY
*&---------------------------------------------------------------------*
FORM zz_set_comp_display.

  CLEAR gt_comp_display.

  LOOP AT gt_comp_preview INTO DATA(ls_preview).
    APPEND ls_preview TO gt_comp_display.
  ENDLOOP.


ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_BUILD_COMP_PREVIEW
*&---------------------------------------------------------------------*
FORM zz_build_comp_preview CHANGING pv_error TYPE abap_bool.

  DATA: lt_bom_head TYPE STANDARD TABLE OF ztcma00120,
        lt_bom_item TYPE STANDARD TABLE OF ztcma00130,
        ls_bom_head TYPE ztcma00120,
        lv_werks    TYPE ztcma00030-werks,
        lv_meins    TYPE ztcma00020-meins,
        lv_reqty    TYPE ztmma00030-reqty.

  CLEAR pv_error.

  " 기존 외주 PR 기준 지급자재를 Preview 시작값으로 사용
  CLEAR gt_comp_preview.

  LOOP AT gt_comp_total INTO DATA(ls_existing).
    INSERT ls_existing INTO TABLE gt_comp_preview.
  ENDLOOP.

  " 아직 PR이 연결되지 않은 FG 부족량
  LOOP AT gt_shortage INTO DATA(ls_fg)
    WHERE shiqty > 0
      AND banfn IS INITIAL.

    CLEAR: lt_bom_head, lt_bom_item,
           ls_bom_head.

    " FG의 유효 BOM 조회
    SELECT *
      FROM ztcma00120
     WHERE matnr    = @ls_fg-matnr
       AND werks    = @ls_fg-werks
       AND stlst    = '01'
       AND datuv   <= @sy-datum
       AND valid_to >= @sy-datum
      INTO TABLE @lt_bom_head.

    IF lt_bom_head IS INITIAL.
      pv_error = abap_true.
      MESSAGE |완제품의 유효 외주 BOM이 없습니다: { ls_fg-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 유효 BOM 중복 검사
    IF lines( lt_bom_head ) <> 1.
      pv_error = abap_true.
      MESSAGE |유효 BOM 중복: { ls_fg-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    READ TABLE lt_bom_head INTO ls_bom_head INDEX 1.

    " BOM 기준수량 및 단위 검증
    IF ls_bom_head-bmeng <= 0
       OR ls_bom_head-bmein <> ls_fg-meins.

      pv_error = abap_true.
      MESSAGE |BOM 기준수량 또는 단위 오류: { ls_fg-matnr }|
        TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

    " BOM 직접 구성품 조회
    SELECT *
      FROM ztcma00130
     WHERE stlnr = @ls_bom_head-stlnr
      INTO TABLE @lt_bom_item.

    IF lt_bom_item IS INITIAL.
      pv_error = abap_true.
      MESSAGE |BOM 구성품 없음: { ls_fg-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    LOOP AT lt_bom_item INTO DATA(ls_item).

      CLEAR: lv_werks, lv_meins, lv_reqty.

      " 구성품 자재 마스터의 기준단위 확인
      SELECT SINGLE meins
        FROM ztcma00020
       WHERE matnr = @ls_item-idnrk
        INTO @lv_meins.

      IF sy-subrc <> 0 OR lv_meins <> ls_item-meins.
        pv_error = abap_true.
        MESSAGE |구성품 마스터/단위 오류: { ls_item-idnrk }| TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      " 기존 공통 FORM으로 지급자재 관리 플랜트 확인
      PERFORM zz_get_component_werks USING ls_item-idnrk ls_fg-werks CHANGING lv_werks pv_error.

      IF pv_error = abap_true.
        RETURN.
      ENDIF.

      " 예상 지급 필요량
      lv_reqty = ls_fg-shiqty * ls_item-menge / ls_bom_head-bmeng.

      " 동일 지급자재는 하나의 집계행으로 합산
      READ TABLE gt_comp_preview ASSIGNING FIELD-SYMBOL(<fs_preview>)
        WITH TABLE KEY matnr = ls_item-idnrk
                       werks = lv_werks
                       meins = ls_item-meins.

      IF sy-subrc = 0.

        <fs_preview>-reqty = <fs_preview>-reqty + lv_reqty.

      ELSE.

        INSERT VALUE ty_comp_total(
          matnr = ls_item-idnrk
          werks = lv_werks
          meins = ls_item-meins
          reqty = lv_reqty
        ) INTO TABLE gt_comp_preview.

      ENDIF.

    ENDLOOP.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_CALC_COMP_PREVIEW
*&---------------------------------------------------------------------*
FORM zz_calc_comp_preview CHANGING pv_error TYPE abap_bool.

  DATA: lv_po_qty   TYPE ztmma00060-menge,
        lv_gr_qty   TYPE ztmma00090-menge,
        lv_open_qty TYPE ztmma00040-rqty.

  CLEAR pv_error.

  LOOP AT gt_comp_preview ASSIGNING FIELD-SYMBOL(<fs_comp>).

    CLEAR: lv_po_qty, lv_gr_qty, lv_open_qty,
           <fs_comp>-stqty, <fs_comp>-rsqty, <fs_comp>-qisty,
           <fs_comp>-inqty, <fs_comp>-eisbe, <fs_comp>-avqty,
           <fs_comp>-shiqty, <fs_comp>-open_pr_qty.

    " 재고 정보
    SELECT SUM( stqty ), SUM( rsqty ), SUM( qisty )
      FROM ztmma00070
     WHERE matnr = @<fs_comp>-matnr
       AND werks = @<fs_comp>-werks
      INTO ( @<fs_comp>-stqty, @<fs_comp>-rsqty, @<fs_comp>-qisty ).

    " 안전재고
    SELECT SINGLE eisbe
      FROM ztcma00030
     WHERE matnr = @<fs_comp>-matnr
       AND werks = @<fs_comp>-werks
       AND actyn = @zlea_y
      INTO @<fs_comp>-eisbe.

    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE |지급자재 관리정보 없음: { <fs_comp>-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " PO 수량
    SELECT SUM( menge )
      FROM ztmma00060
     WHERE matnr = @<fs_comp>-matnr
       AND werks = @<fs_comp>-werks
      INTO @lv_po_qty.

    " 기존 입고수량
    SELECT SUM( c~menge )
      FROM ztmma00060 AS b
      INNER JOIN ztmma00090 AS c
        ON c~ebeln = b~ebeln
       AND c~ebelp = b~ebelp
     WHERE b~matnr = @<fs_comp>-matnr
       AND b~werks = @<fs_comp>-werks
       AND c~bwart = '101'
      INTO @lv_gr_qty.

    " 입고예정량
    <fs_comp>-inqty = lv_po_qty - lv_gr_qty.

    IF <fs_comp>-inqty < 0.
      <fs_comp>-inqty = 0.
    ENDIF.

    " 유효 일반 PR 미전환 잔량
    PERFORM zz_get_open_pr USING <fs_comp>-matnr <fs_comp>-werks <fs_comp>-meins
      CHANGING lv_open_qty pv_error.

    IF pv_error = abap_true.
      RETURN.
    ENDIF.

    <fs_comp>-open_pr_qty = lv_open_qty.

    " 예상 가용수량
    <fs_comp>-avqty = <fs_comp>-stqty + <fs_comp>-inqty.

    " 추가 부족수량
    <fs_comp>-shiqty = <fs_comp>-reqty + <fs_comp>-eisbe - <fs_comp>-avqty - <fs_comp>-open_pr_qty.

    IF <fs_comp>-shiqty < 0.
      <fs_comp>-shiqty = 0.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_GET_FG_DOCUMENT
*&---------------------------------------------------------------------*
FORM zz_get_fg_document.

  DATA ls_short TYPE ztmma00030.

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs>).

    CLEAR: ls_short, <fs>-srtno, <fs>-pstat, <fs>-banfn.

    SELECT SINGLE *
      FROM ztmma00030
     WHERE fcsno  = @<fs>-fcsno
       AND matnr  = @<fs>-matnr
       AND werks  = @<fs>-werks
       AND reqtyp = '0010'
      INTO @ls_short.

    IF sy-subrc = 0.
      <fs>-srtno = ls_short-srtno.
      <fs>-pstat = ls_short-pstat.
      <fs>-banfn = ls_short-banfn.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_BUILD_PR_PREVIEW
*&---------------------------------------------------------------------*
FORM zz_build_pr_preview.

  CLEAR gt_pr_preview.

  " 1. FG 부족량: 신규 PR 생성 후보
  LOOP AT gt_shortage INTO DATA(ls_fg).

    CLEAR gs_pr_preview.

    gs_pr_preview-reqtyp = '0010'.
    gs_pr_preview-srtno  = ls_fg-srtno.
    gs_pr_preview-fcsno  = ls_fg-fcsno.
    gs_pr_preview-matnr  = ls_fg-matnr.
    gs_pr_preview-maktx  = ls_fg-maktx.
    gs_pr_preview-werks  = ls_fg-werks.
    gs_pr_preview-meins  = ls_fg-meins.
    gs_pr_preview-reqty  = ls_fg-reqty.
    gs_pr_preview-shiqty = ls_fg-shiqty.
    gs_pr_preview-banfn  = ls_fg-banfn.

    IF ls_fg-banfn IS NOT INITIAL.
      gs_pr_preview-result = '생성완료'.
    ELSEIF ls_fg-srtno IS INITIAL.
      gs_pr_preview-result = '부족량미저장'.
    ELSEIF ls_fg-pstat <> '0010'.
      gs_pr_preview-result = '상태확인필요'.
    ELSE.
      gs_pr_preview-result = '생성후보'.
    ENDIF.

    APPEND gs_pr_preview TO gt_pr_preview.

  ENDLOOP.

  " 2. 출처가 검증된 기존 지급자재 부족량 문서를 먼저 추가
  PERFORM zz_get_comp_pr_documents.

  " 3. DB 저장 문서가 없는 지급자재만 예상 후보로 추가
  LOOP AT gt_comp_preview INTO DATA(ls_comp)
    WHERE shiqty > 0.

    " 동일 자재·플랜트·단위의 저장된 지급자재 후보가 있는지 확인
    READ TABLE gt_pr_preview TRANSPORTING NO FIELDS
      WITH KEY reqtyp = '0020'
               matnr  = ls_comp-matnr
               werks  = ls_comp-werks
               meins  = ls_comp-meins.

    IF sy-subrc = 0.
      CONTINUE.
    ENDIF.

    CLEAR gs_pr_preview.

    gs_pr_preview-reqtyp = '0020'.
    gs_pr_preview-matnr  = ls_comp-matnr.

    SELECT SINGLE maktx
      FROM ztcma00020
      WHERE matnr = @ls_comp-matnr
      INTO @gs_pr_preview-maktx.

    gs_pr_preview-werks  = ls_comp-werks.
    gs_pr_preview-meins  = ls_comp-meins.
    gs_pr_preview-reqty  = ls_comp-reqty.
    gs_pr_preview-shiqty = ls_comp-shiqty.

    gs_pr_preview-result = '출처확정전'.

    APPEND gs_pr_preview TO gt_pr_preview.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_SET_PR_FCAT
*&---------------------------------------------------------------------*
FORM zz_set_pr_fcat.

  DATA: ls_fcat TYPE lvc_s_fcat,
        lv_pos  TYPE i.

  CLEAR: gt_pr_fcat, lv_pos.

  DEFINE add_pr_field.

    CLEAR ls_fcat.
    lv_pos = lv_pos + 1.

    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-scrtext_l = &2.
    ls_fcat-col_pos   = lv_pos.

    APPEND ls_fcat TO gt_pr_fcat.

  END-OF-DEFINITION.

  add_pr_field 'REQTYP' '수요구분'.
  add_pr_field 'MATNR'  '자재번호'.
  add_pr_field 'MAKTX'  '자재명'.
  add_pr_field 'WERKS'  '플랜트'.
  add_pr_field 'MEINS'  '단위'.
  add_pr_field 'REQTY'  '필요수량'.
  add_pr_field 'SHIQTY' '부족수량'.
  add_pr_field 'RESULT' '처리상태'.
  add_pr_field 'FCSNO'  '예측번호'.
  add_pr_field 'SRTNO'  '부족량번호'.
  add_pr_field 'BANFN'  'PR번호'.
  add_pr_field 'BNFPO'  'PR품목'.

  LOOP AT gt_pr_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).

    CASE <fs_fcat>-fieldname.

      WHEN 'MATNR'.
        <fs_fcat>-key = abap_true.

      WHEN 'REQTY' OR 'SHIQTY'.
        <fs_fcat>-qfieldname = 'MEINS'.

    ENDCASE.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_SET_PR_LAYOUT
*&---------------------------------------------------------------------*
FORM zz_set_pr_layout.

  CLEAR gs_pr_layo.

  gs_pr_layo-zebra      = abap_true.
  gs_pr_layo-cwidth_opt = abap_true.
  gs_pr_layo-sel_mode   = 'A'.
  gs_pr_layo-grid_title = '구매요청문서 생성 후보 및 처리결과'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_CONFIRM_PR_SELECTION
*&---------------------------------------------------------------------*
FORM zz_confirm_pr_selection.

  DATA: lt_rows          TYPE lvc_t_roid,
        ls_row           TYPE lvc_s_roid,
        ls_pr            TYPE ty_pr_preview,
        lt_selected      TYPE STANDARD TABLE OF ty_pr_preview,
        lv_count         TYPE i,
        lv_answer        TYPE c LENGTH 1,
        lv_question      TYPE c LENGTH 400,
        lv_matnr         TYPE ztmma00030-matnr,
        lv_selected_type TYPE ztmma00030-reqtyp.

  " 1. ALV 객체 확인
  IF go_pr_grid IS NOT BOUND.
    MESSAGE '구매요청문서 생성 후보 ALV가 준비되지 않았습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 2. 0130 ALV 선택행 가져오기
  CALL METHOD go_pr_grid->get_selected_rows
    IMPORTING
      et_row_no = lt_rows.

  IF lt_rows IS INITIAL.
    MESSAGE '구매요청문서 생성 대상을 선택해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  SORT lt_rows BY row_id.
  DELETE ADJACENT DUPLICATES FROM lt_rows COMPARING row_id.

  " 3. 선택 대상 검증
  LOOP AT lt_rows INTO ls_row.

    CLEAR ls_pr.

    READ TABLE gt_pr_preview INTO ls_pr INDEX ls_row-row_id.

    IF sy-subrc <> 0.
      MESSAGE '선택한 ALV 행을 확인할 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 선택 수요유형 확인
    IF lv_selected_type IS INITIAL.
      lv_selected_type = ls_pr-reqtyp.
    ELSEIF lv_selected_type <> ls_pr-reqtyp.
      MESSAGE '완제품과 지급자재는 함께 생성할 수 없습니다.'
        TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CASE ls_pr-reqtyp.

      WHEN '0010'.

        " 이미 구매요청문서가 생성된 완제품
        IF ls_pr-banfn IS NOT INITIAL.
          MESSAGE |이미 구매요청문서가 생성되었습니다: | &&
                  |{ ls_pr-matnr } (PR: { ls_pr-banfn })|
            TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        " 부족량 문서가 아직 저장되지 않은 경우
        IF ls_pr-result = '부족량미저장'.
          MESSAGE |부족량 문서 저장이 필요합니다: { ls_pr-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        " 기타 생성 불가능 상태
        IF ls_pr-result <> '생성후보'.
          MESSAGE |구매요청문서 생성 조건을 확인해 주세요: { ls_pr-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

      WHEN '0020'.

        " 이미 PR이 생성된 지급자재
        IF ls_pr-banfn IS NOT INITIAL.
          MESSAGE |이미 구매요청문서가 생성되었습니다: | &&
                  |{ ls_pr-matnr } (PR: { ls_pr-banfn })|
            TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        " 아직 부족량/출처 검증이 완료되지 않은 지급자재
        IF ls_pr-result <> '출처검증전' OR ls_pr-srtno IS INITIAL.
          MESSAGE |지급자재 부족량/출처 저장이 필요합니다: { ls_pr-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

      WHEN OTHERS.
        MESSAGE '지원하지 않는 수요유형입니다.' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.

    ENDCASE.

    " 부족수량 확인
    IF ls_pr-shiqty <= 0.
      MESSAGE |부족수량이 없습니다: { ls_pr-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 기존 PR 연결 확인
    IF ls_pr-banfn IS NOT INITIAL.
      MESSAGE |기존 구매요청문서가 연결되어 있습니다: { ls_pr-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    APPEND ls_pr TO lt_selected.

  ENDLOOP.

  " 4. 확인 팝업
  lv_count = lines( lt_selected ).

  IF lv_selected_type = '0010'.
    lv_question =
      |선택한 완제품 { lv_count }건을 구매요청문서 생성 대상으로 확정하시겠습니까?|.
  ELSE.
    lv_question =
      |선택한 지급자재 { lv_count }건을 구매요청문서 생성 대상으로 확정하시겠습니까?|.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '구매요청문서 생성 대상 확인'
      text_question         = lv_question
      text_button_1         = '확인'
      text_button_2         = '취소'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer.

  IF lv_answer <> '1'.
    RETURN.
  ENDIF.

  " 5. 확인된 생성 대상 보관
  CLEAR: gt_pr_selected, gv_selected_cnt.

  gt_pr_selected = lt_selected.
  gv_selected_cnt = lines( gt_pr_selected ).

  " 6. 실제 DB 기준 생성 가능 여부 검증
  DATA lv_error TYPE abap_bool.

  " 지급자재는 별도 생성 로직으로 처리
  IF lv_selected_type = '0020'.
    PERFORM zz_create_selected_comp_pr.
    RETURN.
  ENDIF.

  PERFORM zz_validate_selected_fg CHANGING lv_error.

  IF lv_error = abap_true.
    CLEAR: gt_pr_selected, gv_selected_cnt.
    RETURN.
  ENDIF.

  " 최신 재고 변경 여부 확인
  PERFORM zz_check_selected_fg_stock CHANGING lv_error.

  IF lv_error = abap_true.
    CLEAR: gt_pr_selected, gv_selected_cnt.
    RETURN.
  ENDIF.

  " 선택 FG 검증 완료 후 실제 PR 생성 처리
  PERFORM zz_create_selected_fg_pr.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_CHECK_COMP_PR_TARGET
*&---------------------------------------------------------------------*
FORM zz_check_comp_pr_target
  USING    ps_pr    TYPE ty_pr_preview
  CHANGING pv_valid TYPE abap_bool.

  DATA ls_short TYPE ztmma00030.

  CLEAR pv_valid.

  " 지급자재 수요인지 확인
  IF ps_pr-reqtyp <> '0020'.
    RETURN.
  ENDIF.

  " 출처 부족량 문서번호 확인
  IF ps_pr-srtno IS INITIAL.
    RETURN.
  ENDIF.

  " 실제 부족량 문서 조회
  SELECT SINGLE *
    FROM ztmma00030
    WHERE srtno = @ps_pr-srtno
    INTO @ls_short.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " 지급자재 수요 유형 확인
  IF ls_short-reqtyp <> '0020'.
    RETURN.
  ENDIF.

  " 기존 PR 연결 여부
  IF ls_short-banfn IS NOT INITIAL.
    RETURN.
  ENDIF.

  " 처리 대기 상태 확인
  IF ls_short-pstat <> '0010'.
    RETURN.
  ENDIF.

  " 부족수량 확인
  IF ls_short-shiqty <= 0.
    RETURN.
  ENDIF.

  " 선택 대상과 부족량 문서 일치 확인
  IF ls_short-matnr <> ps_pr-matnr
    OR ls_short-werks <> ps_pr-werks.
    RETURN.
  ENDIF.

  pv_valid = abap_true.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_GET_COMP_PR_DOCUMENTS
*& 기존 지급자재 부족량 문서 조회
*&---------------------------------------------------------------------*
FORM zz_get_comp_pr_documents.

  DATA: lt_short TYPE STANDARD TABLE OF ztmma00030,
        ls_pr    TYPE ty_pr_preview,
        lv_valid TYPE abap_bool.

  SELECT c~*
  FROM ztmma00030 AS c
  WHERE c~reqtyp = '0020'
    AND c~werks  = @pa_werks
*    AND c~pstat  = '0010'
    AND c~pstat IN ( '0010', '0020' )
    AND c~shiqty > 0
    AND EXISTS (
      SELECT *
        FROM ztmma00031 AS s
        INNER JOIN ztmma00040 AS p
          ON p~banfn = s~banfn
         AND p~bnfpo = s~bnfpo
        INNER JOIN ztmma00030 AS f
          ON f~srtno = p~srdoc
        INNER JOIN ztmma00010 AS h
          ON h~fcsno = f~fcsno
        WHERE s~srtno = c~srtno
          AND p~srtyp = '0010'
          AND p~ptype = '0020'
          AND p~pstat <> '0090'
          AND p~werks = @pa_werks
          AND f~reqtyp = '0010'
          AND f~matnr IN @so_matnr
          AND h~werks = @pa_werks
          AND h~cstat = '0020'
          AND h~activ = @abap_true
          AND h~fcsno IN @so_fcsno
    )
  INTO TABLE @lt_short.

  LOOP AT lt_short INTO DATA(ls_short).

    CLEAR: ls_pr, lv_valid.

    ls_pr-reqtyp = ls_short-reqtyp.
    ls_pr-srtno  = ls_short-srtno.
    ls_pr-matnr  = ls_short-matnr.
    ls_pr-werks  = ls_short-werks.
    ls_pr-meins  = ls_short-meins.
    ls_pr-reqty  = ls_short-reqty.
    ls_pr-shiqty = ls_short-shiqty.

    SELECT SINGLE maktx
      FROM ztcma00020
      WHERE matnr = @ls_short-matnr
      INTO @ls_pr-maktx.

    " 1. 이미 PR 생성이 완료된 지급자재
    IF ls_short-pstat = '0020' AND ls_short-banfn IS NOT INITIAL.
      ls_pr-banfn  = ls_short-banfn.
      ls_pr-bnfpo  = ls_short-bnfpo.
      ls_pr-result = '생성완료'.
      APPEND ls_pr TO gt_pr_preview.
      CONTINUE.
    ENDIF.

    " 2. PR 미생성 지급자재만 신규 생성 가능 여부 검증
    PERFORM zz_check_comp_pr_target USING ls_pr CHANGING lv_valid.

    IF lv_valid = abap_true.
      ls_pr-result = '출처검증전'.
      APPEND ls_pr TO gt_pr_preview.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_VALIDATE_SELECTED_FG
*& PR 생성 대상 FG의 DB 상태 검증
*& DB 변경 없음
*&---------------------------------------------------------------------*
FORM zz_validate_selected_fg
  CHANGING pv_error TYPE abap_bool.

  DATA: ls_short    TYPE ztmma00030,
        ls_forecast TYPE ztmma00010,
        ls_current  TYPE ty_shortage.

  CLEAR pv_error.

  " 1. 선택 데이터 존재 확인
  IF gt_pr_selected IS INITIAL.
    pv_error = abap_true.
    MESSAGE '선택된 구매요청문서 생성 대상이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_pr_selected INTO DATA(ls_selected).

    CLEAR: ls_short, ls_forecast, ls_current.

    " 2. FG 수요구분 확인
    IF ls_selected-reqtyp <> '0010'.
      pv_error = abap_true.
      MESSAGE |완제품 수요가 아닙니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 3. 부족량 문서번호 확인
    IF ls_selected-srtno IS INITIAL.
      pv_error = abap_true.
      MESSAGE |부족량 문서가 없습니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 4. 실제 부족량 문서 조회
    SELECT SINGLE *
      FROM ztmma00030
      WHERE srtno = @ls_selected-srtno
      INTO @ls_short.

    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE |부족량 문서를 찾을 수 없습니다: { ls_selected-srtno }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 5. 문서와 선택 대상 일치 여부
    IF ls_short-reqtyp <> '0010'
      OR ls_short-fcsno <> ls_selected-fcsno
      OR ls_short-matnr <> ls_selected-matnr
      OR ls_short-werks <> ls_selected-werks.

      pv_error = abap_true.
      MESSAGE |부족량 문서 정보가 일치하지 않습니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

    " 6. 문서 처리상태
    IF ls_short-pstat <> '0010'.
      pv_error = abap_true.
      MESSAGE |구매요청문서 생성 대기 상태가 아닙니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 7. 기존 PR 연결 확인
    IF ls_short-banfn IS NOT INITIAL.
      pv_error = abap_true.
      MESSAGE |기존 구매요청문서가 연결되어 있습니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 8. DB 부족수량
    IF ls_short-shiqty <= 0.
      pv_error = abap_true.
      MESSAGE |DB 부족수량이 없습니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 9. Forecast 활성/확정 확인
    SELECT SINGLE *
      FROM ztmma00010
      WHERE fcsno = @ls_selected-fcsno
      INTO @ls_forecast.

    IF sy-subrc <> 0 OR ls_forecast-cstat <> '0020' OR ls_forecast-activ <> abap_true.
      pv_error = abap_true.
      MESSAGE |확정된 활성 수요예측이 아닙니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 10. 현재 계산 결과 조회
    READ TABLE gt_shortage INTO ls_current WITH KEY fcsno = ls_selected-fcsno
                                                    matnr = ls_selected-matnr
                                                    werks = ls_selected-werks.

    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE |현재 부족량 계산 결과가 없습니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 11. 선택 당시 수량과 현재 계산수량 비교
    IF ls_selected-shiqty <> ls_current-shiqty.
      pv_error = abap_true.
      MESSAGE |선택 당시와 계산 부족수량이 다릅니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 12. DB 저장 부족수량과 현재 계산수량 비교
    IF ls_short-shiqty <> ls_current-shiqty.
      pv_error = abap_true.
      MESSAGE |DB 부족수량 동기화가 필요합니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 13. 수량 단위 확인
    IF ls_short-meins <> ls_current-meins OR ls_selected-meins <> ls_current-meins.
      pv_error = abap_true.
      MESSAGE |부족량 단위가 일치하지 않습니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_CHECK_SELECTED_FG_STOCK
*& 선택 FG의 현재 재고와 조회 당시 재고 비교
*& DB 변경 없음
*&---------------------------------------------------------------------*
FORM zz_check_selected_fg_stock CHANGING pv_error TYPE abap_bool.

  DATA: ls_stock   TYPE ztmma00070,
        ls_current TYPE ty_shortage.

  CLEAR pv_error.

  IF gt_pr_selected IS INITIAL.
    pv_error = abap_true.
    MESSAGE '검증할 완제품 생성 대상이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  LOOP AT gt_pr_selected INTO DATA(ls_selected).

    CLEAR: ls_stock, ls_current.

    " 1. 선택 자재의 조회 당시 계산 결과
    READ TABLE gt_shortage INTO ls_current WITH KEY fcsno = ls_selected-fcsno
                                                    matnr = ls_selected-matnr
                                                    werks = ls_selected-werks.

    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE |조회 당시 데이터가 없습니다: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " 현재 DB 재고 합계 조회
    SELECT SUM( stqty ) AS stqty, SUM( rsqty ) AS rsqty, SUM( qisty ) AS qisty
      FROM ztmma00070
     WHERE matnr = @ls_selected-matnr
       AND werks = @ls_selected-werks
      INTO ( @ls_stock-stqty, @ls_stock-rsqty, @ls_stock-qisty ).

    " 조회 당시와 현재 재고 비교
    IF ls_stock-stqty <> ls_current-stqty
      OR ls_stock-rsqty <> ls_current-rsqty
      OR ls_stock-qisty <> ls_current-qisty.

      pv_error = abap_true.
      MESSAGE |재고 정보가 변경되었습니다. 다시 조회해 주세요: { ls_selected-matnr }| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.

    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_create_selected_fg_pr
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_create_selected_fg_pr .

  DATA: lt_request TYPE zttmma00010,
        ls_request TYPE zsmma00010,
        ls_short   TYPE ztmma00030,
        ls_pr      TYPE ztmma00040,
        lv_error   TYPE abap_bool,
        lv_created TYPE i,
        lv_skipped TYPE i,
        lv_message TYPE string,
        lv_count   TYPE i.

  CLEAR: lt_request, lv_error, lv_created, lv_skipped, lv_message.

  IF gt_pr_selected IS INITIAL.
    MESSAGE '구매요청문서 생성 대상이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 1. 공통 PR 테이블 잠금
  PERFORM zz_exe_lock_pr CHANGING lv_error.

  IF lv_error = abap_true.
    RETURN.
  ENDIF.

  " 2. 잠금을 획득한 상태에서 DB 재검증
  " 먼저 조회 당시 재고와 현재 재고 비교
  PERFORM zz_check_selected_fg_stock CHANGING lv_error.

  IF lv_error = abap_true.
    PERFORM zz_exe_unlock_pr.
    RETURN.
  ENDIF.

  " 최신 안전재고와 입고예정량 재조회
  PERFORM zz_get_material_info.
  PERFORM zz_get_incoming_qty.

  " 최신 유효 PR 공급량 기준 부족수량 재계산
  PERFORM zz_exe_refresh_result.

  " 갱신된 계산결과와 선택 대상/DB 비교
  PERFORM zz_validate_selected_fg CHANGING lv_error.

  IF lv_error = abap_true.
    PERFORM zz_exe_unlock_pr.
    RETURN.
  ENDIF.

  " 3. 선택한 FG만 요청 테이블에 구성
  LOOP AT gt_pr_selected INTO DATA(ls_selected).

    CLEAR: ls_short, ls_request.

    SELECT SINGLE *
      FROM ztmma00030
      WHERE srtno = @ls_selected-srtno
      INTO @ls_short.

    IF sy-subrc <> 0
       OR ls_short-reqtyp <> '0010'
       OR ls_short-pstat <> '0010'
       OR ls_short-banfn IS NOT INITIAL
       OR ls_short-shiqty <= 0
       OR ls_short-shiqty <> ls_selected-shiqty
       OR ls_short-matnr <> ls_selected-matnr
       OR ls_short-werks <> ls_selected-werks.

      lv_error = abap_true.
      EXIT.

    ENDIF.

    ls_request-srtyp = '0010'.
    ls_request-srdoc = ls_selected-srtno.
    APPEND ls_request TO lt_request.

  ENDLOOP.

  IF lv_error = abap_true
     OR lines( lt_request ) <> lines( gt_pr_selected ).
    PERFORM zz_exe_unlock_pr.
    MESSAGE '구매요청문서 생성 대상 정보가 변경되었습니다. 다시 조회해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 4. 기존 공통 PR 생성 FM 호출
  " abap_true: 외부 FORM에서 COMMIT / ROLLBACK
  PERFORM zz_exe_pr_request USING lt_request abap_true
    CHANGING lv_error lv_created lv_skipped lv_message.

  IF lv_error = abap_true.
    ROLLBACK WORK.
    PERFORM zz_exe_unlock_pr.
    MESSAGE lv_message TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 선택한 모든 요청이 신규 생성되었는지 확인
  lv_count = lines( lt_request ).

  IF lv_created <> lv_count OR lv_skipped <> 0.
    ROLLBACK WORK.
    PERFORM zz_exe_unlock_pr.
    MESSAGE '일부 구매요청문서이 생성되지 않아 전체 처리를 취소했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 5. COMMIT 전에 부족량-PR 연결 확인
  LOOP AT gt_pr_selected INTO ls_selected.

    CLEAR: ls_short, ls_pr.

    SELECT SINGLE *
      FROM ztmma00030
      WHERE srtno = @ls_selected-srtno
      INTO @ls_short.

    IF sy-subrc <> 0 OR ls_short-banfn IS INITIAL.
      lv_error = abap_true.
      EXIT.
    ENDIF.

    SELECT SINGLE *
      FROM ztmma00040
      WHERE banfn = @ls_short-banfn
        AND bnfpo = @ls_short-bnfpo
        AND srtyp = '0010'
        AND srdoc = @ls_selected-srtno
      INTO @ls_pr.

    IF sy-subrc <> 0.
      lv_error = abap_true.
      EXIT.
    ENDIF.

  ENDLOOP.

  IF lv_error = abap_true.
    ROLLBACK WORK.
    PERFORM zz_exe_unlock_pr.
    MESSAGE '생성된 구매요청문서 연결정보를 확인할 수 없어 취소했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 6. FG PR 저장 확정
  COMMIT WORK AND WAIT.

  IF sy-subrc <> 0.
    PERFORM zz_exe_unlock_pr.
    MESSAGE '구매요청문서 저장 결과를 확인해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM zz_exe_unlock_pr.

  " 7. FG PR 생성 결과 반영
  PERFORM zz_refresh_created_fg.

  gv_pr_confirmed = abap_true.

*  CLEAR: gt_pr_selected, gv_selected_cnt.

  " 8. 생성된 외주 PR의 지급자재 출처/부족량 저장
  DATA lv_comp_error TYPE abap_bool.

  PERFORM zz_save_created_component
    CHANGING lv_comp_error.

  IF lv_comp_error = abap_true.
    MESSAGE '완제품 PR은 생성되었으나 지급자재 저장에 실패했습니다. 지급자재 데이터를 재처리해야 합니다.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 9. 최신 조회 데이터 구성
  PERFORM 1000_onli.

  " 방금 생성한 FG PR 결과 반영
  PERFORM zz_refresh_selected_pr_result.

  " 생성 완료 여부 유지
  gv_pr_confirmed = abap_true.

  " 지급자재 표시 데이터 갱신
  IF gv_run_ok = abap_true.

    PERFORM zz_set_comp_display.

    IF go_grid IS BOUND.
      go_grid->refresh_table_display( ).
    ENDIF.

    IF go_comp_grid IS BOUND.
      go_comp_grid->refresh_table_display( ).
    ENDIF.

    IF go_pr_grid IS BOUND.
      go_pr_grid->refresh_table_display( ).
    ENDIF.

  ENDIF.

  " 결과 반영 이후 선택 데이터 초기화
  CLEAR: gt_pr_selected, gv_selected_cnt.

  MESSAGE |완제품 PR { lv_created }건 생성 및 지급자재 부족량 처리가 완료되었습니다.| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_REFRESH_CREATED_FG
*& PR 생성 후 ALV 및 KPI 데이터 갱신
*&---------------------------------------------------------------------*
FORM zz_refresh_created_fg.

  DATA ls_short TYPE ztmma00030.

  LOOP AT gt_pr_preview ASSIGNING FIELD-SYMBOL(<fs_pr>)
    WHERE reqtyp = '0010'.

    CLEAR ls_short.

    SELECT SINGLE *
      FROM ztmma00030
      WHERE srtno = @<fs_pr>-srtno
      INTO @ls_short.

    IF sy-subrc = 0 AND ls_short-banfn IS NOT INITIAL.

      <fs_pr>-banfn = ls_short-banfn.
      <fs_pr>-bnfpo = ls_short-bnfpo.
      <fs_pr>-result = '생성완료'.

    ENDIF.

  ENDLOOP.

  LOOP AT gt_shortage ASSIGNING FIELD-SYMBOL(<fs_fg>).

    CLEAR ls_short.

    SELECT SINGLE *
      FROM ztmma00030
      WHERE srtno = @<fs_fg>-srtno
      INTO @ls_short.

    IF sy-subrc = 0.

      <fs_fg>-banfn = ls_short-banfn.
      <fs_fg>-pstat = ls_short-pstat.

      IF ls_short-banfn IS NOT INITIAL.
        <fs_fg>-pr_target = abap_false.
        <fs_fg>-pr_status = '생성완료'.
      ENDIF.

    ENDIF.

  ENDLOOP.

  IF go_pr_grid IS BOUND.
    go_pr_grid->refresh_table_display( ).
  ENDIF.

  IF go_grid IS BOUND.
    go_grid->refresh_table_display( ).
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_SAVE_CREATED_COMPONENT
*& 외주 PR 생성 이후 지급자재 부족량/출처 저장
*& FG PR과 별도의 LUW로 처리
*&---------------------------------------------------------------------*
FORM zz_save_created_component CHANGING pv_error TYPE abap_bool.

  CLEAR pv_error.

  " 1. 기존 지급자재 처리 로직 실행
  PERFORM zz_exe_process_component CHANGING pv_error.

  IF pv_error = abap_true.
    ROLLBACK WORK.
    RETURN.
  ENDIF.

  " 2. 지급자재 DB 저장 확정
  COMMIT WORK AND WAIT.

  IF sy-subrc <> 0.
    pv_error = abap_true.
    RETURN.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_CREATE_SELECTED_COMP_PR
*& 선택한 지급자재 부족량 기준 일반 PR 생성
*&---------------------------------------------------------------------*
FORM zz_create_selected_comp_pr.

  DATA: lt_request TYPE zttmma00010,
        ls_request TYPE zsmma00010,
        ls_short   TYPE ztmma00030,
        ls_pr      TYPE ztmma00040,
        lv_source  TYPE ztmma00031-srtno,
        lv_error   TYPE abap_bool,
        lv_created TYPE i,
        lv_skipped TYPE i,
        lv_count   TYPE i,
        lv_message TYPE string.

  CLEAR: lt_request, lv_error,
         lv_created, lv_skipped, lv_message.

  IF gt_pr_selected IS INITIAL.
    MESSAGE '선택된 지급자재가 없습니다.'
      TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 1. PR 테이블 잠금
  PERFORM zz_exe_lock_pr CHANGING lv_error.

  IF lv_error = abap_true.
    RETURN.
  ENDIF.

  " 생성 직전 최신 지급자재 수급정보 재계산
  PERFORM zz_calc_comp_preview CHANGING lv_error.

  IF lv_error = abap_true.
    PERFORM zz_exe_unlock_pr.
    RETURN.
  ENDIF.

  " 2. 선택 대상 DB 재검증
  LOOP AT gt_pr_selected INTO DATA(ls_selected).

    CLEAR: ls_short, ls_request, lv_source.

    SELECT SINGLE *
      FROM ztmma00030
      WHERE srtno = @ls_selected-srtno
      INTO @ls_short.

    IF sy-subrc <> 0
       OR ls_short-reqtyp <> '0020'
       OR ls_short-pstat <> '0010'
       OR ls_short-banfn IS NOT INITIAL
       OR ls_short-shiqty <= 0
       OR ls_short-matnr <> ls_selected-matnr
       OR ls_short-werks <> ls_selected-werks
       OR ls_short-meins <> ls_selected-meins
       OR ls_short-shiqty <> ls_selected-shiqty.

      lv_error = abap_true.
      EXIT.

    ENDIF.

    " 현재 계산된 지급자재 부족량 확인
    READ TABLE gt_comp_preview INTO DATA(ls_comp_current)
      WITH TABLE KEY matnr = ls_selected-matnr
                     werks = ls_selected-werks
                     meins = ls_selected-meins.

    IF sy-subrc <> 0.
      lv_error = abap_true.
      EXIT.
    ENDIF.

    " 최신 부족수량과 기존 저장수량 비교
    IF ls_comp_current-shiqty <> ls_short-shiqty
       OR ls_comp_current-shiqty <> ls_selected-shiqty
       OR ls_comp_current-reqty <> ls_short-reqty.

      lv_error = abap_true.
      EXIT.

    ENDIF.

    " 3. 유효한 외주 FG PR 출처 확인
    SELECT SINGLE s~srtno
      FROM ztmma00031 AS s
      INNER JOIN ztmma00040 AS p
        ON p~banfn = s~banfn
       AND p~bnfpo = s~bnfpo
      INNER JOIN ztmma00030 AS f
        ON f~srtno = p~srdoc
      INNER JOIN ztmma00010 AS h
        ON h~fcsno = f~fcsno
      WHERE s~srtno = @ls_short-srtno
        AND p~srtyp = '0010'
        AND p~ptype = '0020'
        AND p~pstat <> '0090'
        AND p~werks = @pa_werks
        AND f~reqtyp = '0010'
        AND f~matnr IN @so_matnr
        AND h~werks = @pa_werks
        AND h~cstat = '0020'
        AND h~activ = @abap_true
        AND h~fcsno IN @so_fcsno
      INTO @lv_source.

    IF sy-subrc <> 0.
      lv_error = abap_true.
      EXIT.
    ENDIF.

    " 4. 지급자재 일반 PR 요청 구성
    ls_request-srtyp = '0030'.
    ls_request-srdoc = ls_short-srtno.
    APPEND ls_request TO lt_request.

  ENDLOOP.

  IF lv_error = abap_true OR lines( lt_request ) <> lines( gt_pr_selected ).
    PERFORM zz_exe_unlock_pr.
    MESSAGE '지급자재 부족량 또는 출처가 변경되었습니다. 다시 조회해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 5. 공통 PR 생성 FM 호출
  " 외부 LUW: 여기서 COMMIT / ROLLBACK 관리
  PERFORM zz_exe_pr_request USING lt_request abap_true
    CHANGING lv_error lv_created lv_skipped lv_message.

  lv_count = lines( lt_request ).

  IF lv_error = abap_true OR lv_created <> lv_count OR lv_skipped <> 0.

    ROLLBACK WORK.
    PERFORM zz_exe_unlock_pr.

    IF lv_message IS INITIAL.
      lv_message = '지급자재 구매요청문서 생성에 실패했습니다.'.
    ENDIF.

    MESSAGE lv_message TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.

  ENDIF.

  " 6. COMMIT 전 실제 PR 연결 확인
  LOOP AT gt_pr_selected INTO ls_selected.

    CLEAR: ls_short, ls_pr.

    SELECT SINGLE *
      FROM ztmma00030
      WHERE srtno = @ls_selected-srtno
      INTO @ls_short.

    IF sy-subrc <> 0 OR ls_short-banfn IS INITIAL.
      lv_error = abap_true.
      EXIT.
    ENDIF.

    SELECT SINGLE *
      FROM ztmma00040
      WHERE banfn = @ls_short-banfn
        AND bnfpo = @ls_short-bnfpo
        AND srtyp = '0030'
        AND srdoc = @ls_selected-srtno
      INTO @ls_pr.

    IF sy-subrc <> 0.
      lv_error = abap_true.
      EXIT.
    ENDIF.

  ENDLOOP.

  IF lv_error = abap_true.
    ROLLBACK WORK.
    PERFORM zz_exe_unlock_pr.
    MESSAGE '생성된 지급자재 PR 연결정보를 확인할 수 없어 취소했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 7. 저장 확정
  COMMIT WORK AND WAIT.

  IF sy-subrc <> 0.
    PERFORM zz_exe_unlock_pr.
    MESSAGE '구매요청문서 COMMIT 결과를 확인해 주세요.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  PERFORM zz_exe_unlock_pr.

*  gv_pr_confirmed = abap_true.
*
*  CLEAR: gt_pr_selected, gv_selected_cnt.

  " 8. 최신 조회 데이터 구성
  PERFORM 1000_onli.

  " 방금 생성한 지급자재 PR 결과 반영
  PERFORM zz_refresh_selected_pr_result.

  gv_pr_confirmed = abap_true.

  IF gv_run_ok = abap_true.

    PERFORM zz_set_comp_display.

    IF go_grid IS BOUND.
      go_grid->refresh_table_display( ).
    ENDIF.

    IF go_comp_grid IS BOUND.
      go_comp_grid->refresh_table_display( ).
    ENDIF.

    IF go_pr_grid IS BOUND.
      go_pr_grid->refresh_table_display( ).
    ENDIF.

  ENDIF.

  " 결과 반영 완료 후 선택 데이터 초기화
  CLEAR: gt_pr_selected, gv_selected_cnt.

  MESSAGE |지급자재 구매요청문서 { lv_created }건이 생성되었습니다.| TYPE 'S'.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form ZZ_REFRESH_SELECTED_PR_RESULT
*& 생성된 PR의 번호와 처리결과를 ALV에 반영
*&---------------------------------------------------------------------*
FORM zz_refresh_selected_pr_result.

  DATA: ls_short TYPE ztmma00030,
        ls_pr    TYPE ty_pr_preview.

  LOOP AT gt_pr_selected INTO DATA(ls_selected).

    CLEAR: ls_short, ls_pr.

    SELECT SINGLE *
      FROM ztmma00030
      WHERE srtno = @ls_selected-srtno
      INTO @ls_short.

    IF sy-subrc <> 0 OR ls_short-banfn IS INITIAL.
      CONTINUE.
    ENDIF.

    READ TABLE gt_pr_preview ASSIGNING FIELD-SYMBOL(<fs_pr>)
      WITH KEY reqtyp = ls_selected-reqtyp
               srtno  = ls_selected-srtno.

    IF sy-subrc = 0.

      <fs_pr>-banfn  = ls_short-banfn.
      <fs_pr>-bnfpo  = ls_short-bnfpo.
      <fs_pr>-result = '생성완료'.

    ELSE.

      ls_pr = ls_selected.

      ls_pr-banfn  = ls_short-banfn.
      ls_pr-bnfpo  = ls_short-bnfpo.
      ls_pr-result = '생성완료'.

      APPEND ls_pr TO gt_pr_preview.

    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_run_batch
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_exe_run_batch .

  DATA: lv_error   TYPE abap_bool,
        lv_created TYPE i,
        lv_skipped TYPE i,
        lv_message TYPE string,
        lt_request TYPE zttmma00010.

  " 1. 확정 수요예측 및 부족량 조회
  PERFORM 1000_onli.

  IF gv_run_ok <> abap_true.
    MESSAGE '배치 부족량 계산에 실패했습니다.' TYPE 'E'.
  ENDIF.

  " 2. FG 부족량 DB 저장
  PERFORM zz_exe_save_shortage CHANGING lv_error.

  IF lv_error = abap_true.
    ROLLBACK WORK.
    MESSAGE 'FG 부족량 저장에 실패했습니다.' TYPE 'E'.
  ENDIF.

  COMMIT WORK AND WAIT.

  IF sy-subrc <> 0.
    MESSAGE 'FG 부족량 저장 결과를 확인해 주세요.' TYPE 'E'.
  ENDIF.

  " 3. FG PR 생성 요청 구성
  PERFORM zz_get_batch_pr_request CHANGING lt_request.

  IF lt_request IS NOT INITIAL.

    PERFORM zz_exe_pr_request
      USING lt_request abap_false
      CHANGING lv_error lv_created lv_skipped lv_message.

    IF lv_error = abap_true.
      MESSAGE lv_message TYPE 'E'.
    ENDIF.

  ENDIF.

  WRITE: / 'FG PR 생성:', lv_created, '제외:', lv_skipped.

  " 4. 외주 PR 기반 지급자재 부족량 및 출처 저장
  CLEAR lv_error.

  PERFORM zz_save_created_component CHANGING lv_error.

  IF lv_error = abap_true.
    MESSAGE '지급자재 부족량/출처 저장에 실패했습니다.' TYPE 'E'.
  ENDIF.

  " 5. 지급자재 PR 생성 대상 구성
  CLEAR: lt_request, lv_created, lv_skipped, lv_message.

  PERFORM zz_get_component_pr CHANGING lt_request.

  IF lt_request IS NOT INITIAL.

    PERFORM zz_exe_pr_request USING lt_request abap_false
      CHANGING lv_error lv_created lv_skipped lv_message.

    IF lv_error = abap_true.
      MESSAGE lv_message TYPE 'E'.
    ENDIF.

  ENDIF.

  WRITE: / '지급자재 PR 생성:', lv_created, '제외:', lv_skipped.
  WRITE: / '배치 처리가 종료되었습니다.'.

ENDFORM.
