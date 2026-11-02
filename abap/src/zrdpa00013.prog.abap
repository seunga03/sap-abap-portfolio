*&---------------------------------------------------------------------*
*& Program  : ZRDPA00013
*& Tcode    : -
*& Title    : 고객 수요정보 조회
*&---------------------------------------------------------------------*
*& Description
*& - 고객에게 받은 생산계획/Event 원문 또는 파일을 AI로 구조화하고
*&   담당자가 검토·보정하여 저장하는 Transaction 프로그램
*&---------------------------------------------------------------------*
*& Author   : 이승아
*& Created  : 2026.09.30
*&---------------------------------------------------------------------*
*& Change History
*& Date        Author        Description
*&-----------  ------------  -------------------------------------------
*& 2026.09.30  이승아           최초 생성
*&---------------------------------------------------------------------*

INCLUDE zrdpa00013_top. " Global Data
INCLUDE zrdpa00013_k01. " Class for Event Handler
INCLUDE zrdpa00013_sel. " Selection Screen

INCLUDE zrdpa00013_o01. " PBO-Modules
INCLUDE zrdpa00013_i01. " PAI-Modules
INCLUDE zrdpa00013_f01. " FORM-Routines

INCLUDE zrdpa00013_e01. " Report Events
