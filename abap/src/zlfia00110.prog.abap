*&---------------------------------------------------------------------*
*& Report ZLFIA00110 : 기한별 미결 채권·채무 분석 (CDS ZV_FI_OPEN_*)
*&---------------------------------------------------------------------*
REPORT zlfia00110.

INCLUDE zlfia00110_top.     " 전역 데이터
INCLUDE zlfia00110_sel.     " 조회 조건 (서브스크린 0110)
INCLUDE zlfia00110_c01.     " 이벤트 클래스 (ALV 더블클릭)
INCLUDE zlfia00110_f01.     " FORM
INCLUDE zlfia00110_o01.     " PBO
INCLUDE zlfia00110_i01.     " PAI
INCLUDE zlfia00110_e01.     " 이벤트
