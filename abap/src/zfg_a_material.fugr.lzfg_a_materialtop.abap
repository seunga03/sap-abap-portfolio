FUNCTION-POOL ZFG_A_MATERIAL.               "MESSAGE-ID ..
  DEFINE append_error.
    CLEAR ls_return.
    ls_return-type    = 'E'.
    ls_return-message = &1.
    APPEND ls_return TO et_return.
  END-OF-DEFINITION.
* INCLUDE LZFG_A_MATERIALD...                " Local class definition

  TYPES ty_bom_return TYPE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY.
  CONSTANTS gc_bom_external TYPE ztcma00040-beskz VALUE 'F'.
