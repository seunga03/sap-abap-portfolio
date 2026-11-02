*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.

  PARAMETERS: pa_werks TYPE ztmma00070-werks OBLIGATORY.

  SELECT-OPTIONS: so_fcsno FOR ztmma00021-fcsno,
                  so_matnr FOR ztmma00021-matnr.

SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-b02.

  PARAMETERS: rb_calc RADIOBUTTON GROUP md1 DEFAULT 'X', " 부족량 산출 및 조회
              rb_auto RADIOBUTTON GROUP md1.             " 부족량 산출 + FG PR + 지급자재 PR 자동생성

SELECTION-SCREEN END OF BLOCK b02.
