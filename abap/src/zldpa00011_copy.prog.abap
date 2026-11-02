*&---------------------------------------------------------------------*
*& Program  : ZLDPA00011
*& Tcode    : -
*& Title    : 고객 수요정보 신규등록
*&---------------------------------------------------------------------*
*& Description
*& - 고객에게 받은 생산계획/Event 원문 또는 파일을 AI로 구조화하고
*&   담당자가 검토·보정하여 저장하는 Transaction 프로그램
*&---------------------------------------------------------------------*
*& Author   : 이승아
*& Created  : 2026.09.28
*&---------------------------------------------------------------------*
*& Change History
*& Date        Author        Description
*&-----------  ------------  -------------------------------------------
*& 2026.09.28  이승아           최초 생성
*& 2026.10.30  박현민           가이드 pdf 추가
*&---------------------------------------------------------------------*

INCLUDE ZLDPA00011_TOP_U.
*INCLUDE zldpa00011_top. " Global Data
INCLUDE ZLDPA00011_K01_U.
*INCLUDE zldpa00011_k01. " Class for Event Handler
INCLUDE ZLDPA00011_SEL_U.
*INCLUDE zldpa00011_sel. " Selection Screen

INCLUDE ZLDPA00011_O01_U.
*INCLUDE zldpa00011_o01. " PBO-Modules
INCLUDE ZLDPA00011_I01_U.
*INCLUDE zldpa00011_i01. " PAI-Modules
INCLUDE ZLDPA00011_F01_U.
*INCLUDE zldpa00011_f01. " FORM-Routines

INCLUDE ZLDPA00011_E01_U.
*INCLUDE zldpa00011_e01. " Report Events

INCLUDE zldpa00011_u_gde.
