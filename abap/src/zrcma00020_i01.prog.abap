*&---------------------------------------------------------------------*
*& Include          ZRCMA00020_I01
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  gv_okcode = ok_code.
  CLEAR ok_code.

  CASE gv_okcode.
     WHEN 'BACK' OR 'CANC'.
      IF go_cont_0200 IS BOUND.
        go_cont_0200->free( ).
      ENDIF.
      FREE: go_grid_0200, go_cont_0200.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      IF go_cont_0200 IS BOUND.
        go_cont_0200->free( ).
      ENDIF.
      FREE: go_grid_0200, go_cont_0200.
      PERFORM free_alv.                            " 0100 ALV도 해제
      LEAVE PROGRAM.
    WHEN 'STAT'.
      IF gt_list IS INITIAL. MESSAGE s018. RETURN. ENDIF.
      gv_spmon = sy-datum(6).           " 0100에서 들어올 때는 항상 현재 월부터
      PERFORM build_stat.
      IF gt_stat IS INITIAL.
        RETURN.                         " s042는 build_stat에서 이미 출력 → 0100에 머묾
      ENDIF.
      CALL SCREEN 0200.
  ENDCASE.
ENDMODULE.

MODULE user_command_0200 INPUT.
  gv_okcode = ok_code.
  CLEAR ok_code.

  CASE gv_okcode.
    WHEN 'BACK' OR 'CANC' OR 'EXIT'.
      IF go_cont_0200 IS BOUND.
        go_cont_0200->free( ).
      ENDIF.
      FREE: go_grid_0200, go_cont_0200.
      LEAVE TO SCREEN 0.                           " → 0100
    WHEN 'SEARCH' OR 'GRP' OR space.               " [조회] / 라디오 전환 / Enter
      PERFORM refresh_stat_0200.
  ENDCASE.
ENDMODULE.
