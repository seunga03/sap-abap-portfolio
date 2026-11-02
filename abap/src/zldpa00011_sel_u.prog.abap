*&---------------------------------------------------------------------*
*& Include          ZLDPA00011_SEL
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* 프로그램 사용 안내
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b05 WITH FRAME TITLE TEXT-b05.

  SELECTION-SCREEN COMMENT /2(75) TEXT-h01.
  SELECTION-SCREEN COMMENT /2(75) TEXT-h02.

*  SELECTION-SCREEN SKIP.

  SELECTION-SCREEN COMMENT /2(75) gv_htype.
  SELECTION-SCREEN COMMENT /2(75) gv_hinpu.

*  [추가] 사용 가이드(PDF) 다운로드 버튼
  SELECTION-SCREEN PUSHBUTTON /2(34) gv_gbtn USER-COMMAND guid.

SELECTION-SCREEN END OF BLOCK b05.

*----------------------------------------------------------------------*
* 자료 기본정보
*----------------------------------------------------------------------*
*SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
*
*  PARAMETERS: pa_kunnr TYPE ztcma00050-kunnr,
*              pa_coldt TYPE zde_coldate DEFAULT sy-datum,
*              pa_sourc TYPE zde_source.
*
*SELECTION-SCREEN END OF BLOCK b01.
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.

  " 고객번호 및 고객명
  SELECTION-SCREEN BEGIN OF LINE.

    SELECTION-SCREEN COMMENT 1(15) TEXT-k01 FOR FIELD pa_kunnr.

    SELECTION-SCREEN POSITION 33.
    PARAMETERS pa_kunnr TYPE ztcma00050-kunnr.   " [수정] 필수 속성 제거(가이드 버튼이 고객번호 없이 동작). 실행 시 검사는 E01에서 한다

    SELECTION-SCREEN COMMENT 50(30) gv_name2.

  SELECTION-SCREEN END OF LINE.

  " 수집일, 원문출처
  PARAMETERS: pa_coldt TYPE zde_coldate DEFAULT sy-datum,
              pa_sourc TYPE zde_source.

SELECTION-SCREEN END OF BLOCK b01.

*----------------------------------------------------------------------*
* 자료유형 (자동분류 / 생산계획 / Event)
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-b02.

  SELECTION-SCREEN BEGIN OF LINE.
*    PARAMETERS rb_auto1 RADIOBUTTON GROUP r1 DEFAULT 'X'.
    PARAMETERS rb_auto1 RADIOBUTTON GROUP r1 DEFAULT 'X' USER-COMMAND typ.
    SELECTION-SCREEN COMMENT 5(10) TEXT-aut FOR FIELD rb_auto1.

    PARAMETERS rb_plan1 RADIOBUTTON GROUP r1.
    SELECTION-SCREEN COMMENT 20(10) TEXT-pla FOR FIELD rb_plan1.

    PARAMETERS rb_event RADIOBUTTON GROUP r1.
    SELECTION-SCREEN COMMENT 35(10) TEXT-eve FOR FIELD rb_event.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b02.

*----------------------------------------------------------------------*
* 입력방식 (직접입력 / 파일업로드)
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-b03.

  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS rb_direc RADIOBUTTON GROUP r2 DEFAULT 'X' USER-COMMAND chg.
    SELECTION-SCREEN COMMENT 5(10) TEXT-dir FOR FIELD rb_direc.

    PARAMETERS rb_file1 RADIOBUTTON GROUP r2.
    SELECTION-SCREEN COMMENT 20(10) TEXT-fil FOR FIELD rb_file1.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b03.

*----------------------------------------------------------------------*
* 파일업로드
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b04 WITH FRAME TITLE TEXT-b04.

  PARAMETERS pa_file1 LIKE rlgrap-filename MODIF ID fil.

SELECTION-SCREEN END OF BLOCK b04.
