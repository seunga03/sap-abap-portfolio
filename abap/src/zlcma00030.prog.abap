*&---------------------------------------------------------------------*
*& Report ZLCMA00030
*&---------------------------------------------------------------------*
*& CM06 AI 연결 설정 관리 (ZTEXA00070 CRUD)
*& 작성자: 이유진
*&---------------------------------------------------------------------*
REPORT zlcma00030.

TYPES: BEGIN OF ty_out,
         keyid  TYPE ztexa00070-keyid,
         model  TYPE ztexa00070-model,
         apikey TYPE c LENGTH 20,          " 마스킹 표시용
       END OF ty_out.

CONSTANTS gc_mask TYPE c LENGTH 4 VALUE '****'.

DATA: gt_out   TYPE STANDARD TABLE OF ty_out,
      gs_row   TYPE ztexa00070,
      gv_exist TYPE abap_bool.

*--- 선택화면 --------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  PARAMETERS: p_disp RADIOBUTTON GROUP g1 DEFAULT 'X' USER-COMMAND mode,
              p_crt  RADIOBUTTON GROUP g1,
              p_chg  RADIOBUTTON GROUP g1,
              p_del  RADIOBUTTON GROUP g1.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.
  PARAMETERS: p_keyid  TYPE ztexa00070-keyid,
              p_model  TYPE ztexa00070-model  LOWER CASE MODIF ID inp,
              p_apikey TYPE ztexa00070-apikey LOWER CASE MODIF ID pwd.
SELECTION-SCREEN END OF BLOCK b2.

*--- 모드별 입력칸 제어, API 키는 입력 시 가림 ----------------------------*
AT SELECTION-SCREEN OUTPUT.
  SET PF-STATUS 'SEL1000'.
  LOOP AT SCREEN.
    IF screen-group1 = 'INP' OR screen-group1 = 'PWD'.
      IF p_crt = abap_true OR p_chg = abap_true.
        screen-input = 1.
      ELSE.
        screen-input = 0.
      ENDIF.
      IF screen-name = 'P_APIKEY'.      "
        screen-invisible = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

*--- 입력 검증 (실행 시) -----------------------------------------------*
AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      PERFORM confirm_leave.
      RETURN.
  ENDCASE.

  IF sy-ucomm <> 'ONLI'.
    RETURN.
  ENDIF.

  TRANSLATE p_keyid TO UPPER CASE.

  IF p_disp = abap_false AND p_keyid IS INITIAL.
    MESSAGE '설정 ID를 입력하세요.' TYPE 'E'.
  ENDIF.

  CLEAR gv_exist.
  IF p_keyid IS NOT INITIAL.
    SELECT SINGLE @abap_true FROM ztexa00070
      WHERE keyid = @p_keyid
      INTO @gv_exist.
  ENDIF.

  IF p_crt = abap_true.
    IF p_model IS INITIAL OR p_apikey IS INITIAL.
      MESSAGE '모델과 API 키를 모두 입력하세요.' TYPE 'E'.
    ENDIF.
    IF gv_exist = abap_true.
      MESSAGE '이미 존재하는 설정 ID입니다.' TYPE 'E'.
    ENDIF.
  ELSEIF p_chg = abap_true.
    IF gv_exist = abap_false.
      MESSAGE '존재하지 않는 설정 ID입니다.' TYPE 'E'.
    ENDIF.
    IF p_model IS INITIAL AND p_apikey IS INITIAL.
      MESSAGE '변경할 모델 또는 API 키를 입력하세요.' TYPE 'E'.
    ENDIF.
  ELSEIF p_del = abap_true.
    IF gv_exist = abap_false.
      MESSAGE '존재하지 않는 설정 ID입니다.' TYPE 'E'.
    ENDIF.
  ENDIF.

*--- 실행 ------------------------------------------------------------*
START-OF-SELECTION.
  CASE abap_true.
    WHEN p_disp. PERFORM display_data.
    WHEN p_crt.  PERFORM create_data.
    WHEN p_chg.  PERFORM change_data.
    WHEN p_del.  PERFORM delete_data.
  ENDCASE.

*&---------------------------------------------------------------------*
FORM mask_key USING    iv_key  TYPE ztexa00070-apikey
              CHANGING cv_mask TYPE ty_out-apikey.
  DATA lv_len TYPE i.
  lv_len = strlen( iv_key ).
  IF lv_len > 4.
    cv_mask = |{ gc_mask }{ substring( val = iv_key off = lv_len - 4 len = 4 ) }|.
  ELSE.
    cv_mask = gc_mask.
  ENDIF.
ENDFORM.

FORM display_data.
  DATA: lt_db   TYPE STANDARD TABLE OF ztexa00070,
        ls_out  TYPE ty_out.

  CLEAR gt_out.
  IF p_keyid IS INITIAL.
    SELECT * FROM ztexa00070 INTO TABLE @lt_db ORDER BY keyid.
  ELSE.
    SELECT * FROM ztexa00070 WHERE keyid = @p_keyid INTO TABLE @lt_db.
  ENDIF.

  IF lt_db IS INITIAL.
    MESSAGE '조회된 설정이 없습니다.' TYPE 'S'.
    RETURN.
  ENDIF.

  LOOP AT lt_db INTO DATA(ls_db).
    CLEAR ls_out.
    ls_out-keyid = ls_db-keyid.
    ls_out-model = ls_db-model.
    PERFORM mask_key USING ls_db-apikey CHANGING ls_out-apikey.
    APPEND ls_out TO gt_out.
  ENDLOOP.

  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_alv)
                              CHANGING  t_table      = gt_out ).
      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).
      DATA(lo_cols) = lo_alv->get_columns( ).
      lo_cols->set_optimize( abap_true ).
      lo_cols->get_column( 'KEYID' )->set_short_text( '설정ID' ).
      lo_cols->get_column( 'KEYID' )->set_medium_text( '설정 ID' ).
      lo_cols->get_column( 'KEYID' )->set_long_text( '설정 ID' ).
      lo_cols->get_column( 'MODEL' )->set_short_text( '모델' ).
      lo_cols->get_column( 'MODEL' )->set_medium_text( '모델' ).
      lo_cols->get_column( 'MODEL' )->set_long_text( '모델' ).
      lo_cols->get_column( 'APIKEY' )->set_short_text( 'API키' ).
      lo_cols->get_column( 'APIKEY' )->set_medium_text( 'API 키(마스킹)' ).
      lo_cols->get_column( 'APIKEY' )->set_long_text( 'API 키(마스킹)' ).
      lo_alv->display( ).
    CATCH cx_salv_msg cx_salv_not_found.
      MESSAGE '목록을 표시할 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.
ENDFORM.

FORM create_data.
  CLEAR gs_row.
  gs_row-keyid  = p_keyid.
  gs_row-model  = p_model.
  gs_row-apikey = p_apikey.

  INSERT ztexa00070 FROM @gs_row.
  IF sy-subrc = 0.
    COMMIT WORK.
    CLEAR p_apikey.
    MESSAGE '설정이 등록되었습니다.' TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE '등록에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM change_data.
  SELECT SINGLE * FROM ztexa00070
    WHERE keyid = @p_keyid
    INTO @gs_row.
  IF sy-subrc <> 0.
    MESSAGE '존재하지 않는 설정 ID입니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  IF p_model IS NOT INITIAL.
    gs_row-model = p_model.
  ENDIF.
  IF p_apikey IS NOT INITIAL.
    gs_row-apikey = p_apikey.
  ENDIF.

  UPDATE ztexa00070 FROM @gs_row.
  IF sy-subrc = 0.
    COMMIT WORK.
    CLEAR p_apikey.
    MESSAGE '설정이 수정되었습니다.' TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE '수정에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM delete_data.
  DATA: lv_ans  TYPE c LENGTH 1,
        lv_text TYPE c LENGTH 200.

  lv_text = |설정 ID { p_keyid }을(를) 삭제할까요?|.
  IF p_keyid = 'CM'.
    lv_text = |{ lv_text } (CM03 AI 추천에서 사용 중인 설정입니다)|.
  ENDIF.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = '삭제 확인'
      text_question         = lv_text
      text_button_1         = '삭제'
      text_button_2         = '취소'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_ans
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0 OR lv_ans <> '1'.
    MESSAGE '삭제가 취소되었습니다.' TYPE 'S'.
    RETURN.
  ENDIF.

  DELETE FROM ztexa00070 WHERE keyid = @p_keyid.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE '설정이 삭제되었습니다.' TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE '삭제에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

FORM confirm_leave.
  DATA: lv_dirty TYPE abap_bool,
        lv_ans   TYPE c LENGTH 1.

  " 등록·수정 모드에서 입력한 값이 있으면 '작업 중'으로 본다
  IF ( p_crt = abap_true OR p_chg = abap_true ) AND
     ( p_keyid IS NOT INITIAL OR p_model IS NOT INITIAL OR p_apikey IS NOT INITIAL ).
    lv_dirty = abap_true.
  ENDIF.

  IF lv_dirty = abap_true.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = '나가기 확인'
        text_question         = '입력 중인 내용이 있습니다. 나가시겠습니까? 저장하지 않은 내용은 사라집니다.'
        text_button_1         = '나가기'
        text_button_2         = '계속 입력'
        default_button        = '2'
        display_cancel_button = space
      IMPORTING
        answer                = lv_ans
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF sy-subrc <> 0 OR lv_ans <> '1'.
      RETURN.                        " 화면에 남는다
    ENDIF.
  ENDIF.

  LEAVE PROGRAM.                     " 입력이 없거나 '나가기' → 종료
ENDFORM.
