*&---------------------------------------------------------------------*
*& Report ZLMMA00010
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZLMMA00030 MESSAGE-ID ZMSGA.

* TCODE 30 입고 생성
* TCODE 31 입고 조회

INCLUDE ZLMMA00030_TOP.
INCLUDE ZLMMA00030_K01.
INCLUDE ZLMMA00030_SEL.
INCLUDE ZLMMA00030_O01.
INCLUDE ZLMMA00030_I01.
INCLUDE ZLMMA00030_F01.
INCLUDE ZLMMA00030_E01.

*&---------------------------------------------------------------------*
*& INITIALIZATION.
*&---------------------------------------------------------------------*
INITIALIZATION.
  APPEND VALUE #(
    sign   = 'I'
    option = 'BT'
    low    = sy-datum - 30
    high   = sy-datum
  ) TO so_eindt.
*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN OUTPUT.        PBO.
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN.               PAI.
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.
*&---------------------------------------------------------------------*
*& START-OF-SELECTION.
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM zz_get_data.
*&---------------------------------------------------------------------*
*& END-OF-SELECTION.
*&---------------------------------------------------------------------*
END-OF-SELECTION.
  IF sy-batch = 0.
    DATA(lv_count) = lines( gt_alv_top ).
    IF lv_count = 0.
      MESSAGE s040 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    CALL SCREEN 100.
  ELSE.

ENDIF.
