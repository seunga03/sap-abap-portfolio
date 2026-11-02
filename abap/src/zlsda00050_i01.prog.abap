"& Include          ZLSDA00050_I01
"&---------------------------------------------------------------------*


"---------------------------------------------------------------------*
" EXIT_0100
"---------------------------------------------------------------------*
MODULE exit_0100 INPUT.

  CASE sy-ucomm.

    WHEN 'BACK'.
      LEAVE TO SCREEN 0.

    WHEN 'EXIT'
      OR 'CANC'.
      LEAVE PROGRAM.

  ENDCASE.

ENDMODULE.


"---------------------------------------------------------------------*
" USER_COMMAND_0100
"---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  DATA:
    lv_err TYPE c LENGTH 1.

  gv_okcode = sy-ucomm.
  CLEAR sy-ucomm.

  " Enter 포함 모든 동작 : 입력한 고객번호 옆에 고객명 표시
  PERFORM set_cust_names CHANGING lv_err.

  CASE gv_okcode.

    " 조회 / 고객 상태 라디오 클릭 (바로 조회)
    WHEN 'SRCH'
      OR 'RADI'.

      IF lv_err IS INITIAL.
        PERFORM validate_search_condition CHANGING lv_err.
      ENDIF.

      IF lv_err IS INITIAL.
        PERFORM refresh_data.

        IF gt_cust IS INITIAL.
          MESSAGE s230(zmsga) DISPLAY LIKE 'E'.
        ENDIF.
      ENDIF.

    " 입력값 초기화
    WHEN 'CLER'.
      PERFORM clear_search_condition.

      IF gt_cust IS INITIAL.
        MESSAGE s230(zmsga) DISPLAY LIKE 'E'.
      ENDIF.

  ENDCASE.

  CLEAR gv_okcode.

ENDMODULE.


"---------------------------------------------------------------------*
" F4 : 고객번호 From / To
"---------------------------------------------------------------------*
MODULE f4_kunfr INPUT.

  PERFORM f4_customer USING 'GV_S_KUNFR' 'GV_S_NAMFR'.

ENDMODULE.

MODULE f4_kunto INPUT.

  PERFORM f4_customer USING 'GV_S_KUNTO' 'GV_S_NAMTO'.

ENDMODULE.
