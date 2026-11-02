*&---------------------------------------------------------------------*
*& Include          ZRDPA00023_SEL
*&---------------------------------------------------------------------*

**** 조회조건
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: so_fcsno FOR ztmma00010-fcsno,
                  so_werks FOR ztmma00010-werks,
                  so_fcdat FOR ztmma00010-fcdat,
                  so_matnr FOR ztmma00020-matnr.
  PARAMETERS pa_only AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b01.
