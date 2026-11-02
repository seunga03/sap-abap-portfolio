*----------------------------------------------------------------------*
***INCLUDE LZFGFIA00020F01.
*----------------------------------------------------------------------*
FORM set_audit.
  DATA: lv_index TYPE sy-tabix,
        ls_view  TYPE zvfia00010.

  LOOP AT total.
    CHECK <action> = neuer_eintrag OR <action> = aendern.

    READ TABLE extract WITH KEY <vim_xtotal_key>.
    IF sy-subrc = 0.
      lv_index = sy-tabix.
    ELSE.
      CLEAR lv_index.
    ENDIF.

    ls_view = <vim_total_struc>.
    IF <action> = neuer_eintrag.                 " 새로 추가
      ls_view-ernam = sy-uname.
      ls_view-erdat = sy-datum.
      ls_view-erzet = sy-uzeit.
    ELSE.                                        " 수정
      ls_view-aenam = sy-uname.
      ls_view-aedat = sy-datum.
      ls_view-aezet = sy-uzeit.
    ENDIF.
    <vim_total_struc> = ls_view.
    MODIFY total.

    CHECK lv_index > 0.
    extract = total.
    MODIFY extract INDEX lv_index.
  ENDLOOP.

  sy-subrc = 0.
ENDFORM.
