*&---------------------------------------------------------------------*
*& Include          ZRDPA00013_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form zz_set_modify_screen
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_modify_screen .

  LOOP AT SCREEN.

    IF screen-group1 = 'B02'.

      IF rb_plan1 = abap_true.
        screen-active = 1.
        screen-input  = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
      MODIFY SCREEN.

    ELSEIF screen-group1 = 'B03'.

      IF rb_event = abap_true.
        screen-active = 1.
        screen-input  = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
      MODIFY SCREEN.

    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_plan_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_plan_fcat .

  CLEAR: gt_plan_fcat, gv_fcat_pos.

  """ 문서정보
  PERFORM zz_exe_add_fcat USING 'PLNNO' '생산계획번호'    CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'ITENO' 'Item'            CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'COLNO' '수집번호'        CHANGING gt_plan_fcat.

  """ 고객 / 자재
  PERFORM zz_exe_add_fcat USING 'KUNNR' '고객번호'        CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'MATNR' '자재번호'        CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'MAKTX' '자재명'          CHANGING gt_plan_fcat.

  """ 생산계획
  PERFORM zz_exe_add_fcat USING 'PERIO' '적용월'          CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'PLAN_QTY' '생산계획수량' CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'MEINS' '단위'            CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'CHANGE_DIR' '증감방향'   CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'CHANGE_RATE' '증감률'    CHANGING gt_plan_fcat.

  """ 수집정보
  PERFORM zz_exe_add_fcat USING 'SOURCE' '자료출처'       CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'COLLECT_DATE' '수집일'   CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'CONFIRM_YN' '확정여부'   CHANGING gt_plan_fcat.
  PERFORM zz_exe_add_fcat USING 'RAW_TEXT' '원문 근거'    CHANGING gt_plan_fcat.

  """ 필드별 속성
  LOOP AT gt_plan_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).

    CASE <fs_fcat>-fieldname.

      WHEN 'PLNNO' OR 'ITENO'.
        <fs_fcat>-key = abap_true.

      WHEN 'PLAN_QTY'.
        <fs_fcat>-qfieldname = 'MEINS'.

      WHEN 'RAW_TEXT'.
        <fs_fcat>-outputlen = 50.

    ENDCASE.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_event_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_event_fcat .

  CLEAR: gt_event_fcat, gv_fcat_pos.

  """ 문서정보
  PERFORM zz_exe_add_fcat USING 'EVTNO' 'Event 번호'       CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'ITENO' 'Item'             CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'COLNO' '수집번호'         CHANGING gt_event_fcat.

  """ 고객 / 자재
  PERFORM zz_exe_add_fcat USING 'KUNNR' '고객번호'         CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'MATNR' '자재번호'         CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'MAKTX' '자재명'           CHANGING gt_event_fcat.

  """ Event
  PERFORM zz_exe_add_fcat USING 'EVENT_TYPE' 'Event 유형'  CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'VALID_FROM' '시작일'      CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'VALID_TO' '종료일'        CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'IMPACT_DIR' '영향방향'    CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'IMPACT_RATE' '영향률'     CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'EVENT_TEXT' 'Event 내용'  CHANGING gt_event_fcat.

  """ 수집정보
  PERFORM zz_exe_add_fcat USING 'SOURCE' '자료출처'        CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'COLLECT_DATE' '수집일'    CHANGING gt_event_fcat.
  PERFORM zz_exe_add_fcat USING 'CONFIRM_YN' '확정여부'    CHANGING gt_event_fcat.

  """ 필드별 속성
  LOOP AT gt_event_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).

    CASE <fs_fcat>-fieldname.

      WHEN 'EVTNO' OR 'ITENO'.
        <fs_fcat>-key = abap_true.

      WHEN 'EVENT_TEXT'.
        <fs_fcat>-outputlen = 50.

    ENDCASE.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_plan_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_plan_data .

  CLEAR gt_plan.

  SELECT a~plnno,
         a~iteno,
         a~colno,
         a~kunnr,
         a~matnr,
         b~maktx,
         a~perio,
         a~plan_qty,
         a~meins,
         a~change_dir,
         a~change_rate,
         a~source,
         a~collect_date,
         a~confirm_yn,
         a~raw_text
    FROM ztcma00170 AS a
    LEFT OUTER JOIN ztcma00020 AS b
      ON b~matnr = a~matnr
    WHERE a~kunnr IN @so_kunnr
      AND a~matnr IN @so_matnr
      AND ( @pa_perio IS INITIAL OR
            a~perio = @pa_perio )
      AND a~delfg = @space
    INTO CORRESPONDING FIELDS OF TABLE @gt_plan.

  SORT gt_plan BY plnno DESCENDING iteno.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_get_event_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_event_data .

  CLEAR gt_event.

  SELECT a~evtno,
         a~iteno,
         a~colno,
         a~kunnr,
         a~matnr,
         b~maktx,
         a~event_type,
         a~valid_from,
         a~valid_to,
         a~impact_dir,
         a~impact_rate,
         a~source,
         a~collect_date,
         a~confirm_yn,
         a~event_text
    FROM ztcma00180 AS a
    LEFT OUTER JOIN ztcma00020 AS b
      ON b~matnr = a~matnr
    WHERE a~kunnr IN @so_kunn2
      AND a~matnr IN @so_matn2
      AND ( @pa_frdat IS INITIAL OR
            a~valid_to >= @pa_frdat )
      AND ( @pa_todat IS INITIAL OR
            a~valid_from <= @pa_todat )
      AND a~delfg = @space
    INTO CORRESPONDING FIELDS OF TABLE @gt_event.

  SORT gt_event BY evtno DESCENDING iteno.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_add_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      <-- GT_PLAN_FCAT
*&---------------------------------------------------------------------*
FORM zz_exe_add_fcat  USING    pv_field TYPE lvc_fname
                               pv_text  TYPE lvc_txt
                      CHANGING pt_fcat  TYPE lvc_t_fcat.

  CLEAR gs_fcat.

  gv_fcat_pos = gv_fcat_pos + 1.

  gs_fcat-fieldname = pv_field.
  gs_fcat-coltext   = pv_text.
  gs_fcat-scrtext_l = pv_text.
  gs_fcat-scrtext_m = pv_text.
  gs_fcat-scrtext_s = pv_text.
  gs_fcat-reptext   = pv_text.
  gs_fcat-col_pos   = gv_fcat_pos.

  APPEND gs_fcat TO pt_fcat.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_free_plan_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_free_plan_alv .

  IF go_grid_plan IS BOUND.
    go_grid_plan->free( ).
    FREE go_grid_plan.
  ENDIF.

  IF go_cont_plan IS BOUND.
    go_cont_plan->free( ).
    FREE go_cont_plan.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_free_event_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_free_event_alv .

  IF go_grid_event IS BOUND.
    go_grid_event->free( ).
    FREE go_grid_event.
  ENDIF.

  IF go_cont_event IS BOUND.
    go_cont_event->free( ).
    FREE go_cont_event.
  ENDIF.

ENDFORM.
