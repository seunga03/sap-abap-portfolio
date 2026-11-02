*&---------------------------------------------------------------------*
*& Include          ZLFIA00080_E01
*&---------------------------------------------------------------------*
LOAD-OF-PROGRAM.

INITIALIZATION.
  DATA ls_btn TYPE smp_dyntxt.

  CLEAR ls_btn.
  ls_btn-icon_id   = icon_pdf.             " PDF 아이콘
  ls_btn-icon_text = 'PDF 송장 읽기'.
  ls_btn-quickinfo = 'AI로 송장 PDF 자동 입력'.
  sscrfields-functxt_01 = ls_btn.

  CLEAR ls_btn.
  ls_btn-icon_id   = icon_check.           " 체크 아이콘
  ls_btn-icon_text = '구매송장 재검증/취소'.
  ls_btn-quickinfo = '보류/반려 구매송장 관리'.
  sscrfields-functxt_02 = ls_btn.

  CLEAR ls_btn.
  ls_btn-icon_id   =  icon_display.            " 목록 아이콘
  ls_btn-icon_text = '구매송장 조회'.
  ls_btn-quickinfo = '구매송장 조회 프로그램으로 이동'.   " 마우스 올리면 뜨는 설명
  sscrfields-functxt_03 = ls_btn.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_ebeln.
  PERFORM f4_ebeln.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN 'FC01'.
      PERFORM read_pdf_invoice.                 " PDF → AI → 선택화면 자동 입력
    WHEN 'FC02'.
      SUBMIT zlfia00090
      VIA SELECTION-SCREEN.
    WHEN 'FC03'.
      SUBMIT zlfia00070
  VIA SELECTION-SCREEN.
    WHEN 'ONLI'.
      PERFORM check_selection.
  ENDCASE.

AT SELECTION-SCREEN OUTPUT.
  PERFORM get_vendor_name.
  PERFORM set_required.

START-OF-SELECTION.
  PERFORM free_controls.                    " 두 번째 실행 대비 초기화
  PERFORM get_po_data.
  IF gv_ai_ebeln <> p_ebeln.               " PDF와 다른 PO면 PDF 안 보여줌
    CLEAR gv_pdf_x.
  ENDIF.
  CLEAR: gt_ai_line, gv_ai_ebeln.
  CALL SCREEN 0100.
  CLEAR gv_pdf_x.
