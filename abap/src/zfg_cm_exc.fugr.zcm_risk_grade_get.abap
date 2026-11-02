FUNCTION ZCM_RISK_GRADE_GET.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_DLDAY) TYPE  I
*"  EXPORTING
*"     REFERENCE(EV_GRADE) TYPE  CHAR10
*"     REFERENCE(EV_COLOR) TYPE  CHAR4
*"----------------------------------------------------------------------
  CLEAR: ev_grade, ev_color.

  IF iv_dlday <= 0.
    ev_grade = 'NORMAL'.
  ELSEIF iv_dlday <= 4.
    ev_grade = 'WARNING'.
    ev_color = 'C310'.
  ELSE.
    ev_grade = 'CRITICAL'.
    ev_color = 'C610'.
  ENDIF.
  ENDFUNCTION.
