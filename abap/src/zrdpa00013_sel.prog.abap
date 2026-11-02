*&---------------------------------------------------------------------*
*& Include          ZRDPA00013_SEL
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* 자료유형
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS rb_plan1 RADIOBUTTON GROUP r1 DEFAULT 'X' USER-COMMAND chg.
    SELECTION-SCREEN COMMENT 5(10) TEXT-pla FOR FIELD rb_plan1.

    PARAMETERS rb_event RADIOBUTTON GROUP r1.
    SELECTION-SCREEN COMMENT 20(10) TEXT-eve FOR FIELD rb_event.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b01.

*----------------------------------------------------------------------*
* 생산계획 Box
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-b02.

  SELECT-OPTIONS: so_kunnr FOR ztcma00170-kunnr MODIF ID b02,
                  so_matnr FOR ztcma00170-matnr MODIF ID b02.
  PARAMETERS:     pa_perio TYPE ztcma00170-perio MODIF ID b02.

SELECTION-SCREEN END OF BLOCK b02.

*----------------------------------------------------------------------*
* Event Box
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-b03.

  SELECT-OPTIONS: so_kunn2 FOR ztcma00180-kunnr MODIF ID b03,
                  so_matn2 FOR ztcma00180-matnr MODIF ID b03.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(31) TEXT-d01 MODIF ID b03.
    PARAMETERS pa_frdat TYPE ztcma00180-valid_from MODIF ID b03.
    SELECTION-SCREEN COMMENT 46(3) TEXT-d02 MODIF ID b03.
    PARAMETERS pa_todat TYPE ztcma00180-valid_to MODIF ID b03.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b03.
