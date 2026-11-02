*&---------------------------------------------------------------------*
*& Include          ZRDPA00023_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form zz_get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_get_data.

  CLEAR gt_display.

  "--------------------------------------------------
  " 수요예측 Header / Item 통합 조회
  "--------------------------------------------------
  SELECT a~fcsno,
         a~werks,
         a~fcdat,
         a~tcdat,
         a~bsdat,
         a~hmons,
         a~cstat,
         a~activ,
         a~cuser,
         a~cdate,
         a~ctime,
         a~iteno,
         a~matnr,
         a~soqty,
         a~giqty,
         a~gapqty,
         a~opqty,
         a~aiqty,
         a~adqty,
         a~fiqty,
         a~meins,
         a~rdate,
         a~aistat,
         a~aidat,
         a~aitim,
         a~aireason,
         b~maktx
    FROM zvdpa00010 AS a
    LEFT OUTER JOIN ztcma00020 AS b
      ON b~matnr = a~matnr
   WHERE a~fcsno IN @so_fcsno
     AND a~werks IN @so_werks
     AND a~fcdat IN @so_fcdat
     AND a~matnr IN @so_matnr
     AND ( @pa_only = @space
           OR a~activ = @abap_true )
    INTO CORRESPONDING FIELDS OF TABLE @gt_display.

  "--------------------------------------------------
  " 최신 수요예측순 정렬
  "--------------------------------------------------
  SORT gt_display BY fcdat DESCENDING
                     fcsno DESCENDING
                     iteno ASCENDING.

  "--------------------------------------------------
  " ALV Hotspot 텍스트 설정
  "--------------------------------------------------
  LOOP AT gt_display ASSIGNING FIELD-SYMBOL(<ls_disp>).

    IF <ls_disp>-aireason IS NOT INITIAL.
      <ls_disp>-reason_link = '예측 근거 보기'.
    ENDIF.

    <ls_disp>-hist_link = '월별 실적 보기'.
    <ls_disp>-fact_link = '외부요인 보기'.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_set_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_set_fcat.
  CLEAR gt_fcat.

  PERFORM zz_add_fcat USING 'FCSNO'       '예측번호'     1.
  PERFORM zz_add_fcat USING 'ITENO'       '품목'         2.
  PERFORM zz_add_fcat USING 'WERKS'       '플랜트'       3.
  PERFORM zz_add_fcat USING 'FCDAT'       '예측시작일'   4.
  PERFORM zz_add_fcat USING 'TCDAT'       '예측종료일'   5.
  PERFORM zz_add_fcat USING 'BSDAT'       '기준일'       6.
  PERFORM zz_add_fcat USING 'HMONS'       '분석개월'     7.
  PERFORM zz_add_fcat USING 'CSTAT'       '확정상태'     8.
  PERFORM zz_add_fcat USING 'ACTIV'       '활성'         9.
  PERFORM zz_add_fcat USING 'MATNR'       '자재번호'     10.
  PERFORM zz_add_fcat USING 'MAKTX'       '자재명'       11.
  PERFORM zz_add_fcat USING 'SOQTY'       '과거 SO'      12.
  PERFORM zz_add_fcat USING 'GIQTY'       '과거 GI'      13.
  PERFORM zz_add_fcat USING 'GAPQTY'      'SO-GI'        14.
  PERFORM zz_add_fcat USING 'OPQTY'       '미완료 SO'     15.
  PERFORM zz_add_fcat USING 'AIQTY'       'AI 예측수량'   16.
  PERFORM zz_add_fcat USING 'REASON_LINK' 'AI 예측사유'   17.
  PERFORM zz_add_fcat USING 'ADQTY'       '조정수량'     18.
  PERFORM zz_add_fcat USING 'FIQTY'       '최종수량'     19.
  PERFORM zz_add_fcat USING 'MEINS'       '단위'         20.
  PERFORM zz_add_fcat USING 'RDATE'       '필요일자'     21.
  PERFORM zz_add_fcat USING 'AISTAT'      'AI 상태'      22.
  PERFORM zz_add_fcat USING 'AIDAT'       'AI 실행일'    23.
  PERFORM zz_add_fcat USING 'AITIM'       'AI 실행시각'  24.
  PERFORM zz_add_fcat USING 'CUSER'       '확정자'       25.
  PERFORM zz_add_fcat USING 'CDATE'       '확정일'       26.
  PERFORM zz_add_fcat USING 'CTIME'       '확정시각'     27.
  PERFORM zz_add_fcat USING 'HIST_LINK'   '과거 실적'    28.
  PERFORM zz_add_fcat USING 'FACT_LINK'   '외부요인'     29.

  LOOP AT gt_fcat ASSIGNING FIELD-SYMBOL(<ls_cat>).
    CASE <ls_cat>-fieldname.
      WHEN 'FCSNO' OR 'ITENO' OR 'MATNR'.
        <ls_cat>-key = abap_true.
      WHEN 'REASON_LINK' OR 'HIST_LINK' OR 'FACT_LINK'.
        <ls_cat>-hotspot = abap_true.
        <ls_cat>-outputlen = 18.
      WHEN 'SOQTY' OR 'GIQTY' OR 'GAPQTY' OR 'OPQTY'
        OR 'AIQTY' OR 'ADQTY' OR 'FIQTY'.
        <ls_cat>-qfieldname = 'MEINS'.
        <ls_cat>-ref_table = 'ZTMMA00020'.
        <ls_cat>-ref_field = <ls_cat>-fieldname.
    ENDCASE.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_add_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&      --> P_15
*&---------------------------------------------------------------------*
FORM zz_add_fcat USING pv_field TYPE lvc_fname
                       pv_text  TYPE lvc_txtcol
                       pv_pos   TYPE i.
  DATA ls_cat TYPE lvc_s_fcat.
  CLEAR ls_cat.
  ls_cat-fieldname = pv_field.
  ls_cat-coltext = pv_text.
  ls_cat-col_pos = pv_pos.
  APPEND ls_cat TO gt_fcat.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_add_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&---------------------------------------------------------------------*
FORM zz_show_history USING pv_fcsno TYPE ztmma00010-fcsno
                           pv_iteno TYPE ztmma00020-iteno.

  DATA: lt_hist TYPE STANDARD TABLE OF ty_history_view WITH EMPTY KEY,
        lo_salv TYPE REF TO cl_salv_table.

  SELECT perio, matnr, soqty, giqty, gapqty, wrkdy, meins
    FROM ztmma00022
   WHERE fcsno = @pv_fcsno
     AND iteno = @pv_iteno
    ORDER BY perio
    INTO TABLE @lt_hist.

  IF lt_hist IS INITIAL.
    MESSAGE '저장된 월별 실적이 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_salv
        CHANGING t_table = lt_hist ).
      lo_salv->set_screen_popup(
        start_column = 5
        end_column   = 110
        start_line   = 3
        end_line     = 23 ).
      lo_salv->get_columns( )->set_optimize( abap_true ).
      lo_salv->display( ).
    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_add_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> P_
*&      --> P_
*&---------------------------------------------------------------------*
FORM zz_show_factor USING pv_fcsno TYPE ztmma00010-fcsno
                          pv_iteno TYPE ztmma00020-iteno.
  DATA: lt_factor TYPE STANDARD TABLE OF ty_factor_view WITH EMPTY KEY,
        lo_salv TYPE REF TO cl_salv_table.

  SELECT factor_no, factor_type, kunnr, refno, source, asof_date,
         valid_from, valid_to, num_value, value_unit, text_value
    FROM ztmma00023
   WHERE fcsno = @pv_fcsno
     AND iteno = @pv_iteno
    ORDER BY factor_no
    INTO TABLE @lt_factor.

  IF lt_factor IS INITIAL.
    MESSAGE '저장된 외부요인 정보가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_salv
        CHANGING t_table = lt_factor ).
      lo_salv->set_screen_popup(
        start_column = 5
        end_column   = 150
        start_line   = 3
        end_line     = 23 ).
      lo_salv->get_columns( )->set_optimize( abap_true ).
      lo_salv->display( ).
    CATCH cx_salv_msg INTO DATA(lx_salv).
      MESSAGE lx_salv->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form zz_exe_add_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM zz_free_reason.
  IF go_reason_edit IS BOUND.
    go_reason_edit->free( ).
    CLEAR go_reason_edit.
  ENDIF.
  IF go_reason_cont IS BOUND.
    go_reason_cont->free( ).
    CLEAR go_reason_cont.
  ENDIF.
  cl_gui_cfw=>flush( ).
ENDFORM.
