*&---------------------------------------------------------------------*
*& Include          ZLSDA00010_SCR
*&---------------------------------------------------------------------*


*---------------------------------------------------------------------*
* Application Toolbar Navigation용
*---------------------------------------------------------------------*
PARAMETERS:
  p_nav TYPE abap_bool NO-DISPLAY.


*---------------------------------------------------------------------*
* 자동표시 값 (화면에는 숨기고, 아래 COMMENT 글자로만 표시)
*---------------------------------------------------------------------*
PARAMETERS:
  p_name1 TYPE ztcma00050-name1 NO-DISPLAY,
  p_maktx TYPE ztcma00020-maktx NO-DISPLAY.


*---------------------------------------------------------------------*
* Selection Screen Function Key
*---------------------------------------------------------------------*
SELECTION-SCREEN FUNCTION KEY 1.   " 입력값 초기화
SELECTION-SCREEN FUNCTION KEY 2.   " 템플릿 다운로드
SELECTION-SCREEN FUNCTION KEY 3.   " 기존 검증결과 보기
SELECTION-SCREEN FUNCTION KEY 4.   " 판매오더 조회 화면


*---------------------------------------------------------------------*
* 입력 방식
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01
  WITH FRAME TITLE TEXT-001.

  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN POSITION 3.

    PARAMETERS:
      p_single RADIOBUTTON GROUP rg1
               USER-COMMAND mode.

    SELECTION-SCREEN COMMENT 5(12) TEXT-r01
      FOR FIELD p_single.

    SELECTION-SCREEN POSITION 22.

    PARAMETERS:
      p_excel RADIOBUTTON GROUP rg1.

    SELECTION-SCREEN COMMENT 24(12) TEXT-r02
      FOR FIELD p_excel.

  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b01.


*---------------------------------------------------------------------*
* 주문 정보
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b02
  WITH FRAME TITLE TEXT-002.


*---------------------------------------------------------------------*
* 고객번호 / 고객명
*---------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN POSITION 3.

    SELECTION-SCREEN COMMENT 3(10) TEXT-p01
      FOR FIELD p_kunnr.

    SELECTION-SCREEN POSITION 15.

    PARAMETERS:
      p_kunnr TYPE ztsda00010-kunnr
              VISIBLE LENGTH 10
              MODIF ID sin.

    SELECTION-SCREEN COMMENT 28(30) gv_tnam MODIF ID dsp.

  SELECTION-SCREEN END OF LINE.


*---------------------------------------------------------------------*
* 자재번호 / 자재명
*---------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN POSITION 3.

    SELECTION-SCREEN COMMENT 3(10) TEXT-p02
      FOR FIELD p_matnr.

    SELECTION-SCREEN POSITION 15.

    PARAMETERS:
      p_matnr TYPE ztsda00020-matnr
              VISIBLE LENGTH 13
              MODIF ID sin.

    SELECTION-SCREEN COMMENT 31(30) gv_tmak MODIF ID dsp.

  SELECTION-SCREEN END OF LINE.


*---------------------------------------------------------------------*
* 주문수량 / 단위
*---------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN POSITION 3.

    SELECTION-SCREEN COMMENT 3(10) TEXT-p03
      FOR FIELD p_kmeng.

    SELECTION-SCREEN POSITION 15.

    PARAMETERS:
      p_kmeng TYPE ztsda00020-kwmeng
              VISIBLE LENGTH 9
              MODIF ID sin.

    SELECTION-SCREEN COMMENT (5) gv_meins.

  SELECTION-SCREEN END OF LINE.


*---------------------------------------------------------------------*
* 요청납기일
*---------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN POSITION 3.

    SELECTION-SCREEN COMMENT 3(10) TEXT-p04
      FOR FIELD p_reqfr.

    SELECTION-SCREEN POSITION 15.

    PARAMETERS:
      p_reqfr TYPE ztsda00020-reqdt
              MODIF ID sin.

    SELECTION-SCREEN COMMENT (2) TEXT-t01.

    PARAMETERS:
      p_reqto TYPE ztsda00020-reqdt
              MODIF ID sin.

  SELECTION-SCREEN END OF LINE.


*---------------------------------------------------------------------*
* 플랜트
*---------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN POSITION 3.

    SELECTION-SCREEN COMMENT 3(10) TEXT-p05
      FOR FIELD p_werks.

    SELECTION-SCREEN POSITION 15.

    PARAMETERS:
      p_werks TYPE ztsda00020-werks
              VISIBLE LENGTH 4
              MODIF ID dsp.

  SELECTION-SCREEN END OF LINE.


*---------------------------------------------------------------------*
* 저장위치
*---------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN POSITION 3.

    SELECTION-SCREEN COMMENT 3(10) TEXT-p06
      FOR FIELD p_lgort.

    SELECTION-SCREEN POSITION 15.

    PARAMETERS:
      p_lgort TYPE ztsda00020-lgort
              VISIBLE LENGTH 4
              MODIF ID dsp.

  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b02.


*---------------------------------------------------------------------*
* Excel Upload
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b03
  WITH FRAME TITLE TEXT-003.

  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN POSITION 3.

    SELECTION-SCREEN COMMENT 3(12) TEXT-p07
      FOR FIELD p_file.

    SELECTION-SCREEN POSITION 15.

    PARAMETERS:
      p_file TYPE rlgrap-filename
             VISIBLE LENGTH 42
             MODIF ID exl.

  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b03.
