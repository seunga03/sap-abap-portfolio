*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.

  PARAMETERS: pa_werks TYPE ztmma00070-werks OBLIGATORY.

  SELECT-OPTIONS: so_fcsno FOR ztmma00021-fcsno,
                  so_matnr FOR ztmma00021-matnr.

SELECTION-SCREEN END OF BLOCK b01.
