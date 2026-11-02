*&---------------------------------------------------------------------*
*& Report ZLMMA00070
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*

INCLUDE zlmma00070_top.
INCLUDE zlmma00070_k01.
INCLUDE zlmma00070_sel.
INCLUDE zlmma00070_o01.
INCLUDE zlmma00070_i01.
INCLUDE zlmma00070_f01.

INITIALIZATION.
  APPEND VALUE #(
    sign   = 'I'
    option = 'BT'
    low    = sy-datum - 30
    high   = sy-datum
  ) TO so_erdat.

START-OF-SELECTION.
  IF sy-batch IS INITIAL.
    PERFORM zz_get_data.
  ENDIF.

END-OF-SELECTION.
  IF sy-batch = 0.
    DATA(lv_count) = lines( gt_exreq ).
    IF lv_count = 0.
      MESSAGE s040 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    CALL SCREEN 100.
  ELSE.

ENDIF.
