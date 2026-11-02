*&---------------------------------------------------------------------*
*& Include          ZLCMA00020_I01
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  gv_okcode = ok_code.
  CLEAR ok_code.

  CASE gv_okcode.
    WHEN 'BACK' OR 'CANC'.
      PERFORM free_alv.
      LEAVE TO SCREEN 0.                       " 선택화면으로
    WHEN 'EXIT'.
      PERFORM free_alv.
      LEAVE PROGRAM.
    WHEN 'CREATE'.
      PERFORM open_detail USING gc_mode_create space.
    WHEN 'CHANGE'.
      PERFORM change_selected.
    WHEN 'DELETE'.
      PERFORM delete_selected.
    WHEN 'REFRESH'.
      PERFORM select_data.
  ENDCASE.
ENDMODULE.

MODULE user_command_0200 INPUT.
  gv_okcode = ok_code.
  CLEAR ok_code.

  " 라디오 → 필드 반영
  gs_0200-trdyn = COND #( WHEN gv_rb_n = 'X' THEN 'N' ELSE 'Y' ).
  IF gs_0200-trdyn = 'Y'.
    CLEAR gs_0200-inrsn.
  ENDIF.

  CASE gv_okcode.
    WHEN 'SAVE'.
      PERFORM save_vendor.
    WHEN 'BACK' OR 'CANC' OR 'EXIT'.
      PERFORM close_detail.
    WHEN 'TRDY'.
      " 라디오 클릭 → PBO에서 비활성사유 입력 가능 여부만 다시 계산
  ENDCASE.
ENDMODULE.

MODULE f4_zterm INPUT.
  PERFORM f4_zterm.
ENDMODULE.
MODULE f4_land1 INPUT.
  PERFORM f4_land1.
ENDMODULE.

MODULE f4_regio INPUT.
  PERFORM f4_regio.
ENDMODULE.
