*&---------------------------------------------------------------------*
*& Include          ZLFIA00010_SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  SELECT-OPTIONS: s_kunnr FOR ztfia00060-kunnr,
                  s_rcpnr FOR ztfia00060-rcpnr,
                  s_rcpdt FOR ztfia00060-rcpdt.
  PARAMETERS:     p_rcpac TYPE ztfia00060-rcpac.

 SELECTION-SCREEN FUNCTION KEY 1.

SELECTION-SCREEN END OF BLOCK b1.
