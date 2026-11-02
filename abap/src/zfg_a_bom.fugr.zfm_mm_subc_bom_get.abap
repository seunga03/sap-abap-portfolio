FUNCTION zfm_mm_subc_bom_get.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_EBELN) TYPE  ZTMMA00060-EBELN
*"     REFERENCE(IV_EBELP) TYPE  ZTMMA00060-EBELP
*"     REFERENCE(IV_KEYDATE) TYPE  SY-DATUM OPTIONAL
*"  EXPORTING
*"     REFERENCE(ET_COMPONENT) TYPE  ZTTMMA00030
*"     REFERENCE(ET_RETURN) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------

  " BOM 전개 대기열의 한 건
  TYPES: BEGIN OF ty_node,
           matnr TYPE ztcma00120-matnr,
           werks TYPE ztcma00120-werks,
           meins TYPE ztcma00120-bmein,
           qty   TYPE decfloat34,
           path  TYPE string,
         END OF ty_node.

  DATA: ls_po        TYPE ztmma00060,
        ls_head      TYPE ztcma00120,
        lt_head      TYPE STANDARD TABLE OF ztcma00120,
        lt_item      TYPE STANDARD TABLE OF ztcma00130,
        lt_queue     TYPE STANDARD TABLE OF ty_node
                       WITH EMPTY KEY,
        ls_node      TYPE ty_node,
        ls_child     TYPE ty_node,
        ls_component TYPE zsmma00025,
        ls_return    TYPE bapiret2,
        lv_date      TYPE sy-datum,
        lv_head_idx  TYPE i,
        lv_child_qty TYPE decfloat34,
        lv_marker    TYPE string.

  CLEAR: et_component, et_return.

  "--------------------------------------------------
  " 입력값 확인
  "--------------------------------------------------
  IF iv_ebeln IS INITIAL OR iv_ebelp IS INITIAL.
    ls_return-type = 'E'.
    ls_return-message = 'PO 번호 또는 품목번호가 없습니다.'.
    APPEND ls_return TO et_return.
    RETURN.
  ENDIF.

  "--------------------------------------------------
  " PO 품목 조회
  "--------------------------------------------------
  SELECT SINGLE *
    FROM ztmma00060
    WHERE ebeln = @iv_ebeln
      AND ebelp = @iv_ebelp
    INTO @ls_po.

  IF sy-subrc <> 0.
    ls_return-type = 'E'.
    ls_return-message = 'PO 품목이 존재하지 않습니다.'.
    APPEND ls_return TO et_return.
    RETURN.
  ENDIF.

  IF ls_po-matnr IS INITIAL
     OR ls_po-werks IS INITIAL
     OR ls_po-meins IS INITIAL
     OR ls_po-menge <= 0.

    ls_return-type = 'E'.
    ls_return-message = 'PO의 자재, 플랜트 또는 수량이 올바르지 않습니다.'.
    APPEND ls_return TO et_return.
    RETURN.
  ENDIF.

  "--------------------------------------------------
  " BOM 유효성 기준일 결정
  " 기본: PO 생성일
  " 선택: IV_KEYDATE가 있으면 전달일 사용
  "--------------------------------------------------
  lv_date = iv_keydate.

  IF lv_date IS INITIAL.

    SELECT SINGLE erdat
      FROM ztmma00050
      WHERE ebeln = @iv_ebeln
      INTO @lv_date.

    IF sy-subrc <> 0 OR lv_date IS INITIAL.
      ls_return-type = 'E'.
      ls_return-message = 'PO 생성일을 확인할 수 없습니다.'.
      APPEND ls_return TO et_return.
      RETURN.
    ENDIF.

  ENDIF.

  "--------------------------------------------------
  " 최상위 자재를 BFS 큐에 등록
  "--------------------------------------------------
  APPEND VALUE ty_node(
    matnr = ls_po-matnr
    werks = ls_po-werks
    meins = ls_po-meins
    qty   = ls_po-menge
    path  = |/{ ls_po-matnr }/|
  ) TO lt_queue.

  lv_head_idx = 1.

  "--------------------------------------------------
  " 큐를 이용해 다단계 BOM 전개
  "--------------------------------------------------
  WHILE lv_head_idx <= lines( lt_queue ).

    CLEAR ls_node.

    READ TABLE lt_queue INTO ls_node INDEX lv_head_idx.

    lv_head_idx = lv_head_idx + 1.

    IF sy-subrc <> 0.
      EXIT.
    ENDIF.

    CLEAR: lt_head, lt_item, ls_head.

    " 현재 노드에 유효한 BOM이 있는지 확인
    SELECT *
      FROM ztcma00120
      WHERE matnr = @ls_node-matnr
        AND werks = @ls_node-werks
        AND stlst = '01'
        AND datuv <= @lv_date
        AND valid_to >= @lv_date
      INTO TABLE @lt_head.

*    " 하위 BOM이 없는 경우 전개 종료
*    IF lt_head IS INITIAL.
*
*      " 최상위 PO 자재에 BOM이 없다면 오류
*      IF lv_head_idx = 2.
*        ls_return-type = 'E'.
*        ls_return-message = '최상위 자재의 유효 BOM이 없습니다.'.
*        APPEND ls_return TO et_return.
*        CLEAR et_component.
*        RETURN.
*      ENDIF.
*
*      " 하위 BOM이 없는 자재는 이미
*      " 부모 BOM Item 처리 시 결과에 등록되어 있음
*      CONTINUE.
*
*    ENDIF.

    " 하위 BOM이 없는 경우 전개 종료
    IF lt_head IS INITIAL.

      " 최상위 PO 자재에 BOM이 없는 경우 정상 반환
      IF lv_head_idx = 2.
        CLEAR ls_return.
        ls_return-type = 'S'.
        ls_return-message = '해당 PO 품목에 유효한 BOM이 없습니다.'.
        APPEND ls_return TO et_return.
        " 구성자재가 없으므로 ET_COMPONENT는 빈 테이블
        CLEAR et_component.
        RETURN.
      ENDIF.

      " 하위 BOM이 없는 구성품은 말단 자재이므로
      " 부모 BOM 처리 시 등록한 결과를 유지
      CONTINUE.

    ENDIF.

    " BOM이 두 개 이상이면 임의 선택하지 않음
    IF lines( lt_head ) <> 1.
      ls_return-type = 'E'.
      ls_return-message = '유효 BOM이 중복됩니다.'.
      APPEND ls_return TO et_return.
      CLEAR et_component.
      RETURN.
    ENDIF.

    READ TABLE lt_head INTO ls_head INDEX 1.

    " BOM 기준 단위와 현재 수량 단위 검사
    IF ls_head-bmeng <= 0 OR ls_head-bmein <> ls_node-meins.

      ls_return-type = 'E'.
      ls_return-message = 'BOM 기준수량 또는 단위가 올바르지 않습니다.'.
      APPEND ls_return TO et_return.
      CLEAR et_component.
      RETURN.

    ENDIF.

    "--------------------------------------------------
    " 현재 BOM 구성품 조회
    "--------------------------------------------------
    SELECT *
      FROM ztcma00130
     WHERE stlnr = @ls_head-stlnr
      INTO TABLE @lt_item.

    IF lt_item IS INITIAL.
      ls_return-type = 'E'.
      ls_return-message = 'BOM에 구성품이 없습니다.'.
      APPEND ls_return TO et_return.
      CLEAR et_component.
      RETURN.
    ENDIF.


    "--------------------------------------------------
    " BOM 구성품 소요수량 계산 및 결과 등록
    "--------------------------------------------------
    LOOP AT lt_item INTO DATA(ls_item).

      " 구성품 필수값 검증
      IF ls_item-idnrk IS INITIAL OR ls_item-meins IS INITIAL OR ls_item-menge <= 0.
        ls_return-type = 'E'.
        ls_return-message = 'BOM 구성품 정보가 올바르지 않습니다.'.
        APPEND ls_return TO et_return.
        CLEAR et_component.
        RETURN.
      ENDIF.

      " 순환 BOM 탐지
      lv_marker = |/{ ls_item-idnrk }/|.

      IF ls_node-path CS lv_marker.
        ls_return-type = 'E'.
        ls_return-message = '순환 BOM이 발견되었습니다.'.
        APPEND ls_return TO et_return.
        CLEAR et_component.
        RETURN.
      ENDIF.

      " 부모 필요량 × 구성품 수량 / BOM 기준수량
      lv_child_qty = ls_node-qty * ls_item-menge / ls_head-bmeng.

      IF lv_child_qty <= 0.
        ls_return-type = 'E'.
        ls_return-message = '계산된 구성품 필요수량이 올바르지 않습니다.'.
        APPEND ls_return TO et_return.
        CLEAR et_component.
        RETURN.
      ENDIF.

      "--------------------------------------------------
      " 전체 구성자재를 ET_COMPONENT에 저장
      " 중간 구성품 + 최하위 자재 모두 포함
      "--------------------------------------------------
      READ TABLE et_component ASSIGNING FIELD-SYMBOL(<ls_component>)
        WITH KEY matnr = ls_item-idnrk
                 werks = ls_node-werks
                 meins = ls_item-meins.

      IF sy-subrc = 0.

        " 동일 구성자재가 다른 경로에 존재하면 합산
        <ls_component>-reqty = <ls_component>-reqty + lv_child_qty.

      ELSE.

        CLEAR ls_component.
        ls_component-ebeln    = ls_po-ebeln.
        ls_component-ebelp    = ls_po-ebelp.
        ls_component-fg_matnr = ls_po-matnr.
        ls_component-stlnr    = ls_head-stlnr.
        ls_component-stlkn    = ls_item-stlkn.
        ls_component-matnr    = ls_item-idnrk.
        ls_component-werks    = ls_node-werks.
        ls_component-reqty    = lv_child_qty.
        ls_component-meins    = ls_item-meins.
        APPEND ls_component TO et_component.

      ENDIF.

      "--------------------------------------------------
      " 하위 BOM 존재 여부 확인을 위한 큐 등록
      "--------------------------------------------------
      CLEAR ls_child.
      ls_child-matnr = ls_item-idnrk.
      ls_child-werks = ls_node-werks.
      ls_child-meins = ls_item-meins.
      ls_child-qty   = lv_child_qty.
      ls_child-path  = |{ ls_node-path }{ ls_item-idnrk }/|.
      APPEND ls_child TO lt_queue.

    ENDLOOP.


  ENDWHILE.

  "--------------------------------------------------
  " 성공 결과 반환
  "--------------------------------------------------
  IF et_component IS INITIAL.
    ls_return-type = 'E'.
    ls_return-message = 'BOM 구성자재가 없습니다.'.
    APPEND ls_return TO et_return.
    RETURN.
  ENDIF.

  CLEAR ls_return.
  ls_return-type = 'S'.
  ls_return-message = '다단계 BOM 전체 구성자재 조회가 완료되었습니다.'.
  APPEND ls_return TO et_return.

ENDFUNCTION.
