*----------------------------------------------------------------------*
***INCLUDE LZFG_MM_SLOCF01.
*----------------------------------------------------------------------*
FORM SET_CREATE_INFO.
  zvmma00050-erdat = sy-datum.
  zvmma00050-erzet = sy-uzeit.
  zvmma00050-ernam = sy-uname.
ENDFORM.

FORM SET_CHANGE_INFO.
  zvmma00050-aedat = sy-datum.
  zvmma00050-aezet = sy-uzeit.
  zvmma00050-aenam = sy-uname.
ENDFORM.
