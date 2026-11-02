*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_SEL
*&---------------------------------------------------------------------*
TABLES : ztmma00080, ztmma00090.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t02.

  SELECT-OPTIONS:
    s_mblnr FOR ztmma00080-mblnr, "자재이동문서
    s_mjahr FOR ztmma00080-mjahr, "회계연도
    s_budat FOR ztmma00080-budat OBLIGATORY, "전기일자
    s_ebeln FOR ztmma00090-ebeln, "구매오더
    s_matnr FOR ztmma00090-matnr, "자재
    s_werks FOR ztmma00090-werks, "플랜트
    s_lgort FOR ztmma00090-lgort. "저장위치

SELECTION-SCREEN END OF BLOCK b1.
