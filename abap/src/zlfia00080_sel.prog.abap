*&---------------------------------------------------------------------*
*& Include          ZLFIA00080_SEL
*&---------------------------------------------------------------------*

  " OBLIGATORY를 쓰지 않음: 쓰면 빈 화면에서 [메뉴로] 버튼이 필수입력 체크에 막힘
  " → 필수 체크는 check_selection (실행 버튼/F8 때만)에서 직접 함
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(33) TEXT-l01 FOR FIELD p_ebeln.   " PO번호
    PARAMETERS p_ebeln TYPE ztfia00010-ebeln.                     " PO번호 (F4)
    SELECTION-SCREEN COMMENT 50(40) gv_vname.                     " 공급업체명 (자동 표시)
  SELECTION-SCREEN END OF LINE.

  PARAMETERS: p_xblnr TYPE ztfia00010-xblnr,                  " 거래처 송장번호
              p_bldat TYPE ztfia00010-bldat,                  " 인보이스 발행일
              p_budat TYPE ztfia00010-budat DEFAULT sy-datum, " AP 인식일
              p_total TYPE p LENGTH 13 DECIMALS 0.            " 인보이스 총액 (원 단위, KRW 전제)

  SELECTION-SCREEN FUNCTION KEY 1.
  SELECTION-SCREEN FUNCTION KEY 2.
  SELECTION-SCREEN FUNCTION KEY 3.
