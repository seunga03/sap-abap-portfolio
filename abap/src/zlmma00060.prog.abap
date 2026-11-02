*&---------------------------------------------------------------------*
*& Report ZLMMA00060
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*

INCLUDE zlmma00060_top                          .    " Global Data

* INCLUDE ZLMMA00060_O01                          .  " PBO-Modules
* INCLUDE ZLMMA00060_I01                          .  " PAI-Modules
INCLUDE zlmma00060_f01                          .  " FORM-Routines

START-OF-SELECTION.

  PERFORM zz_set_period.
  PERFORM zz_get_data.

  CHECK gt_lifnr IS NOT INITIAL.

  PERFORM zz_calculate_result.

  CHECK gt_eval IS NOT INITIAL.

  PERFORM zz_save_result.
