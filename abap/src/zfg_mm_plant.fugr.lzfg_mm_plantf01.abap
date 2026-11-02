*----------------------------------------------------------------------*
***INCLUDE LZFG_MM_PLANTF01.
*----------------------------------------------------------------------*
FORM set_create_info.

  "플랜트 신규 생성 이력
  zvmma00040-erdat = sy-datum.
  zvmma00040-erzet = sy-uzeit.
  zvmma00040-ernam = sy-uname.

ENDFORM.

FORM set_CHANGE_info.

  "플랜트 신규 생성 이력
  zvmma00040-AEdat = sy-datum.
  zvmma00040-AEzet = sy-uzeit.
  zvmma00040-AEnam = sy-uname.

ENDFORM.
