*&---------------------------------------------------------------------*
*& Include          ZLMMA00010_SEL
*&---------------------------------------------------------------------*
TABLES: ztmma00040.

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS:
    so_banfn FOR ztmma00040-banfn,  "구매요청번호
    so_matnr FOR ztmma00040-matnr,  "자재
    so_werks FOR ztmma00040-werks,  "플랜트
    so_lgort FOR ztmma00040-lgort,  "저장위치
    so_rdate FOR ztmma00040-rdate,  "요청일자
    so_ndate FOR ztmma00040-ndate.  "필요일자

SELECTION-SCREEN END OF BLOCK bl1.
