*&---------------------------------------------------------------------*
*& Program  : ZRDPA00023
*& Tcode    : -
*& Title    : [TTEOKIP-DP] AI 수요예측 조회
*&---------------------------------------------------------------------*
*& Description
*& - 수요예측 Header/Item 데이터를 조회하여 AI 수요예측 결과를
*&   ALV 형태로 제공하는 조회 프로그램
*& - 예측번호, 플랜트, 예측기준일, 자재번호를 조회조건으로 제공
*& - 과거 SO/GI 실적, 미완료 SO, AI 예측수량, 조정수량,
*&   최종수량 및 필요일자 등의 수요예측 상세정보를 조회
*&---------------------------------------------------------------------*
*& Author   : 이승아
*& Created  : 2026.10.01
*&---------------------------------------------------------------------*
*& Change History
*& Date        Author        Description
*&-----------  ------------  -------------------------------------------
*& 2026.10.01  이승아           최초 생성
*&---------------------------------------------------------------------*

INCLUDE zrdpa00023_top. " Global Data
INCLUDE zrdpa00023_k01. " Class for Event Handler
INCLUDE zrdpa00023_sel. " Selection Screen

INCLUDE zrdpa00023_o01. " PBO-Modules
INCLUDE zrdpa00023_i01. " PAI-Modules
INCLUDE zrdpa00023_f01. " FORM-Routines

INCLUDE zrdpa00023_e01. " Report Events
