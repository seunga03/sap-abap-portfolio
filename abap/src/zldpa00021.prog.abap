*&---------------------------------------------------------------------*
*& Program  : ZLDPA00021
*& Tcode    : -
*& Title    : AI 수요예측 생성
*&---------------------------------------------------------------------*
*& Description
*& - 선택한 플랜트의 활성 관리 자재 중 수요 발생 근거가 존재하는 자재를 대상으로 다음 달 수요를 AI로 예측
*& - 과거 SO/GI 실적, 미완료 SO, 확정 고객 생산계획 및 고객 이벤트 정보를 AI 분석 입력으로 활용
*& - AI 결과를 조회하고 담당자가 조정수량을 검토
*& - 사용자 확정 시 Header/Item/History/Factor 저장
*& - 기존 동일 기간 활성 Forecast는 비활성화
*&---------------------------------------------------------------------*
*& Author   : 이승아
*& Created  : 2026.09.30
*&---------------------------------------------------------------------*
*& Change History
*& Date        Author        Description
*&-----------  ------------  -------------------------------------------
*& 2026.09.30  이승아           최초 생성
*&---------------------------------------------------------------------*

INCLUDE zldpa00021_top. " Global Data
INCLUDE zldpa00021_k01. " Class for Event Handler
INCLUDE zldpa00021_sel. " Selection Screen

INCLUDE zldpa00021_o01. " PBO Modules
INCLUDE zldpa00021_i01. " PAI Modules
INCLUDE zldpa00021_f01. " FORM Routines

INCLUDE zldpa00021_e01. " Report Events
