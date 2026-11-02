*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_SEL
*&---------------------------------------------------------------------*
TABLES : ztmma00050, ztmma00060.



SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS : so_ekorg FOR ztmma00050-ekorg,
                   so_ekgrp FOR ztmma00050-ekgrp,
                   so_bedat FOR ztmma00050-bedat.
SELECTION-SCREEN END OF BLOCK bl1.

SELECTION-SCREEN BEGIN OF BLOCK bl2 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS : so_ebeln FOR ztmma00060-ebeln,
                   so_matnr FOR ztmma00060-matnr,
                   so_werks FOR ztmma00060-werks,
                   so_lgort FOR ztmma00060-lgort,
                   so_eindt FOR ztmma00060-eindt OBLIGATORY,
                   so_banfn FOR ztmma00060-banfn.
  PARAMETERS : pa_ptype TYPE ztmma00060-ptype.
SELECTION-SCREEN END OF BLOCK bl2.
