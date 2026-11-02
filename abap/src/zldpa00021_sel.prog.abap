*&---------------------------------------------------------------------*
*& Include          ZLDPA00021_SEL
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* AI 수요예측 생성 안내
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-b02.

  SELECTION-SCREEN COMMENT /1(79) TEXT-i01.
  SELECTION-SCREEN COMMENT /1(79) TEXT-i02.
  SELECTION-SCREEN COMMENT /1(79) TEXT-i03.
  SELECTION-SCREEN COMMENT /1(79) TEXT-i04.

SELECTION-SCREEN END OF BLOCK b02.

*----------------------------------------------------------------------*
* 예측 조건
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.

  PARAMETERS: pa_werks TYPE ztmma00010-werks OBLIGATORY,
              pa_bsdat TYPE ztmma00010-bsdat DEFAULT sy-datum OBLIGATORY.

  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN COMMENT 1(30) TEXT-h01.

    SELECTION-SCREEN POSITION 33.
    PARAMETERS rb_06 RADIOBUTTON GROUP hm DEFAULT 'X'.
    SELECTION-SCREEN COMMENT 36(8) TEXT-h06 FOR FIELD rb_06.

    SELECTION-SCREEN POSITION 48.
    PARAMETERS rb_12 RADIOBUTTON GROUP hm.
    SELECTION-SCREEN COMMENT 51(8) TEXT-h12 FOR FIELD rb_12.

    SELECTION-SCREEN POSITION 63.
    PARAMETERS rb_24 RADIOBUTTON GROUP hm.
    SELECTION-SCREEN COMMENT 66(8) TEXT-h24 FOR FIELD rb_24.

  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b01.
