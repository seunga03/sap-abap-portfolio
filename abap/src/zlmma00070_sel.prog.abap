*&---------------------------------------------------------------------*
*& Include          ZLMMA00070_SEL
*&---------------------------------------------------------------------*
TABLES : ztcma00060.
SELECTION-SCREEN BEGIN OF BLOCK bl2 WITH FRAME TITLE TEXT-b02.
  SELECTION-SCREEN BEGIN OF LINE.

    PARAMETERS pa_mm03 RADIOBUTTON GROUP rb1.
    SELECTION-SCREEN COMMENT 3(14) TEXT-r03 FOR FIELD pa_mm03.

    PARAMETERS pa_mm04 RADIOBUTTON GROUP rb1.
    SELECTION-SCREEN COMMENT 22(14) TEXT-r04 FOR FIELD pa_mm04.

  SELECTION-SCREEN END OF LINE.

  SELECT-OPTIONS so_erdat FOR ztcma00060-erdat OBLIGATORY.
SELECTION-SCREEN END OF BLOCK bl2.
