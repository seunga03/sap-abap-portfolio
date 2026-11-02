*&---------------------------------------------------------------------*
*& Include          ZLFIA00070_K01
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS on_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.

    CLASS-METHODS on_item_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_double_click.
    DATA: ls_stable TYPE lvc_s_stbl,
          lv_amt    TYPE c LENGTH 30.

    READ TABLE gt_head INTO gw_head INDEX es_row_no-row_id.
    CHECK sy-subrc = 0.

    CLEAR gt_item.

    " 저장된 송장 라인 그대로 (3WM 재계산 안 함 → 헤더 판정과 항상 같은 기준)
    SELECT ivnum invit ebelp matnr menge meins netpr wrbtr mstat ponpr pasqt cumqt taxcd
      FROM ztfia00020
      INTO CORRESPONDING FIELDS OF TABLE gt_item
      WHERE ivnum = gw_head-ivnum.

    " 통화는 헤더에만 있으므로 헤더 값으로 채움
    gw_item-waers = gw_head-waers.
    MODIFY gt_item FROM gw_item TRANSPORTING waers WHERE waers IS INITIAL.

    " 하단 제목 = 선택한 송장 요약
    WRITE gw_head-totbt TO lv_amt CURRENCY gw_head-waers.   " 총청구금액 (세액 포함)
    CONDENSE lv_amt.
    go_alv2->set_gridtitle(
      CONV lvc_title( |{ gw_head-ivnum } / { gw_head-name1 } / PO { gw_head-ebeln } / { gw_head-mstat } / { lv_amt } { gw_head-waers }| ) ).
    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    go_alv2->refresh_table_display( is_stable = ls_stable ).
  ENDMETHOD.

  METHOD on_item_double_click.
    DATA: lv_judge TYPE ztfia00010-mstat,        " 저장값으로 본 3WM 판정
          lv_jtxt  TYPE c LENGTH 30,             " 'QREJ (수량초과)' 등
          lv_bcls  TYPE string,                  " 배지 색 (p / h / q)
          lv_menge TYPE c LENGTH 25,
          lv_cumqt TYPE c LENGTH 25,
          lv_pasqt TYPE c LENGTH 25,
          lv_netpr TYPE c LENGTH 25,
          lv_ponpr TYPE c LENGTH 25,
          lv_otxt  TYPE c LENGTH 25,             " 초과 수량 글자
          lv_dtxt  TYPE c LENGTH 25,             " 단가 차액 글자
          lv_over  TYPE ztfia00020-menge,        " 누적청구 - 합격누계
          lv_dif   TYPE ztfia00020-netpr,        " 청구단가 - PO단가
          lv_dabs  TYPE ztfia00020-netpr,
          lv_pct   TYPE p LENGTH 8 DECIMALS 1,
          lv_sign  TYPE string,
          lv_cumcl TYPE string,                  " 누적청구 칸 빨강 여부
          lv_netcl TYPE string,                  " 청구단가 칸 빨강 여부
          lv_onote TYPE string,                  " (+20 KG 초과)
          lv_pnote TYPE string,                  " ✓ 일치 / (+60,000 · +5.0%)
          lv_rsn   TYPE string,                  " 판정 근거 문장
          lv_proc  TYPE string,                  " 사람이 처리한 라인 배지
          lv_html  TYPE string.

    READ TABLE gt_item INTO gw_item INDEX es_row_no-row_id.
    CHECK sy-subrc = 0.

    "─ 판정 근거 값이 없으면 (필드 추가 전 등록된 송장)
    IF gw_item-ponpr IS INITIAL AND gw_item-pasqt IS INITIAL AND gw_item-cumqt IS INITIAL.
      MESSAGE s414(zmsga) DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    "─ 저장값으로 판정 재구성 (3WM 규칙과 같음)
    IF gw_item-cumqt > gw_item-pasqt.
      lv_judge = 'QREJ'.  lv_bcls = 'q'.
    ELSEIF gw_item-netpr <> gw_item-ponpr.
      lv_judge = 'HOLD'.  lv_bcls = 'h'.
    ELSE.
      lv_judge = 'PASS'.  lv_bcls = 'p'.
    ENDIF.
    PERFORM mstat_reason USING lv_judge CHANGING lv_jtxt.

    "─ 값 글자로 (단위·통화 형식 그대로)
    WRITE gw_item-menge TO lv_menge UNIT gw_item-meins LEFT-JUSTIFIED.
    WRITE gw_item-cumqt TO lv_cumqt UNIT gw_item-meins LEFT-JUSTIFIED.
    WRITE gw_item-pasqt TO lv_pasqt UNIT gw_item-meins LEFT-JUSTIFIED.
    WRITE gw_item-netpr TO lv_netpr CURRENCY gw_head-waers LEFT-JUSTIFIED.
    WRITE gw_item-ponpr TO lv_ponpr CURRENCY gw_head-waers LEFT-JUSTIFIED.
    CONDENSE: lv_menge, lv_cumqt, lv_pasqt, lv_netpr, lv_ponpr.

    "─ 수량: 누적 청구가 합격을 넘으면 빨강 + 초과량
    IF gw_item-cumqt > gw_item-pasqt.
      lv_over = gw_item-cumqt - gw_item-pasqt.
      WRITE lv_over TO lv_otxt UNIT gw_item-meins LEFT-JUSTIFIED.
      CONDENSE lv_otxt.
      lv_cumcl = 'bad'.
      lv_onote = |<span class="nt">(+{ lv_otxt } { gw_item-meins } 초과)</span>|.
    ENDIF.

    "─ 단가: 다르면 빨강 + 차액·%
    lv_dif = gw_item-netpr - gw_item-ponpr.
    IF lv_dif = 0.
      lv_pnote = |<span class="ok">&#10003; 일치</span>|.
    ELSE.
      lv_dabs = abs( lv_dif ).
      lv_sign = COND #( WHEN lv_dif < 0 THEN '-' ELSE '+' ).
      IF gw_item-ponpr <> 0.
        lv_pct = lv_dabs * 100 / gw_item-ponpr.
      ENDIF.
      WRITE lv_dabs TO lv_dtxt CURRENCY gw_head-waers LEFT-JUSTIFIED.
      CONDENSE lv_dtxt.
      lv_netcl = 'bad'.
      lv_pnote = |<span class="nt">({ lv_sign }{ lv_dtxt } · { lv_sign }{ lv_pct }%)</span>|.
    ENDIF.

    "─ 판정 근거 한 문장
    CASE lv_judge.
      WHEN 'QREJ'.
        lv_rsn = |누적 청구량({ lv_cumqt } { gw_item-meins })이 합격수량 누계({ lv_pasqt } { gw_item-meins })를 넘어 반려되었습니다.|.
      WHEN 'HOLD'.
        lv_rsn = |청구단가({ lv_netpr })가 PO단가({ lv_ponpr })와 달라 보류되었습니다.|.
      WHEN OTHERS.
        lv_rsn = |수량과 단가가 모두 입고·PO 기준과 일치합니다.|.
    ENDCASE.

    "─ 사람이 처리해서 상태가 바뀐 라인만 배지 하나 더
    IF gw_item-mstat <> lv_judge.
      CASE gw_item-mstat.
        WHEN 'PASS'. lv_proc = |<span class="bd g">처리: 조정 반제 &rarr; PASS</span>|.
        WHEN 'CANC'. lv_proc = |<span class="bd g">처리: 송장 취소 (CANC)</span>|.
        WHEN OTHERS. lv_proc = |<span class="bd g">처리: { gw_item-mstat }</span>|.
      ENDCASE.
    ENDIF.

    "─ HTML (홀드 사유 팝업과 같은 디자인)
    lv_html =
      |<html><head><meta charset="utf-8"><style>| &&
      |body\{font-family:'Malgun Gothic',sans-serif;margin:16px;color:#3b4358;font-size:13px\}| &&
      |.hd\{color:#7a8296;margin-bottom:8px\}| &&
      |.bd\{display:inline-block;padding:3px 10px;border-radius:10px;font-weight:bold\}| &&
      |.bd.q\{background:#fdeaea;color:#cf5555\}.bd.h\{background:#fdf3dc;color:#b8860b\}| &&
      |.bd.p\{background:#e6f6ee;color:#2a8a60\}.bd.g\{background:#eef0f4;color:#3b4358;margin-left:6px\}| &&
      |.sec\{margin-top:14px;font-weight:bold;color:#2c3347\}| &&
      |table\{border-collapse:collapse;width:100%;margin:4px 0\}| &&
      |th\{text-align:left;width:110px;color:#7a8296;font-weight:normal;padding:6px 0;border-bottom:1px solid #eceff5\}| &&
      |td\{padding:6px 0;border-bottom:1px solid #eceff5;font-weight:bold\}| &&
      |td.bad\{color:#cf5555\}.nt\{color:#cf5555;font-weight:normal;margin-left:6px\}| &&
      |.ok\{color:#2a8a60;font-weight:normal;margin-left:6px\}| &&
      |.lb\{color:#7a8296;margin:14px 0 4px\}| &&
      |.rs\{background:#f6f7fb;border-radius:8px;padding:10px 12px;line-height:1.5\}| &&
      |</style></head><body>| &&
      |<div class="hd">{ gw_head-ivnum } · 라인 { gw_item-invit ALPHA = OUT } · PO라인 { gw_item-ebelp ALPHA = OUT } · { gw_item-matnr }</div>| &&
      |<span class="bd { lv_bcls }">{ lv_jtxt }</span>{ lv_proc }| &&
      |<div class="sec">수량</div><table>| &&
      |<tr><th>합격수량 누계</th><td>{ lv_pasqt } { gw_item-meins }</td></tr>| &&
      |<tr><th>누적 청구량</th><td class="{ lv_cumcl }">{ lv_cumqt } { gw_item-meins }{ lv_onote }</td></tr>| &&
      |<tr><th>이번 청구량</th><td>{ lv_menge } { gw_item-meins }</td></tr></table>| &&
      |<div class="sec">단가</div><table>| &&
      |<tr><th>PO 단가</th><td>{ lv_ponpr }</td></tr>| &&
      |<tr><th>청구 단가</th><td class="{ lv_netcl }">{ lv_netpr }{ lv_pnote }</td></tr></table>| &&
      |<div class="lb">판정 근거</div><div class="rs">{ lv_rsn }</div>| &&
      |</body></html>|.

    cl_abap_browser=>show_html(
      html_string = lv_html
      title       = '라인 판정 근거'
      size        = cl_abap_browser=>medium
      modal       = abap_true ).
  ENDMETHOD.

ENDCLASS.
