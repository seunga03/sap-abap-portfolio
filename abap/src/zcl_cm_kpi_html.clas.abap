CLASS zcl_cm_kpi_html DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_card,
             label TYPE string,                " 작은 제목
             value TYPE string,                " 큰 숫자
             sub   TYPE string,                " 보조 문구(금액 등)
             color TYPE c LENGTH 1,            " R 빨강 / Y 노랑 / G 초록 / B 파랑 / N 회색
           END OF ty_card,
           tt_card TYPE STANDARD TABLE OF ty_card WITH EMPTY KEY,
           BEGIN OF ty_bar,
             label TYPE string,
             pct   TYPE i,                     " 0~100
             text  TYPE string,
             color TYPE c LENGTH 1,
           END OF ty_bar,
           ty_line TYPE c LENGTH 255,
           tt_html TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.

    " ---- v2 : 위젯 ----
    TYPES: BEGIN OF ty_item,                   " 막대/도넛/추세선 한 항목
             label TYPE string,                " 항목 이름 (추세선은 X축 라벨)
             value TYPE decfloat34,            " 값
             color TYPE c LENGTH 1,            " 비우면 자동 배색
           END OF ty_item,
           tt_item TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,
           BEGIN OF ty_row,
             cells TYPE string_table,
           END OF ty_row,
           tt_row TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,
           BEGIN OF ty_widget,
             kind   TYPE c LENGTH 1,           " C 카드 / B 진행바 / H 가로막대 / D 도넛 / L 추세선 / T 표
             title  TYPE string,
             card   TYPE ty_card,
             cards  TYPE tt_card,
             size   TYPE i,
             cols   TYPE i,
             bar    TYPE ty_bar,
             items  TYPE tt_item,
             head   TYPE string_table,
             rows   TYPE tt_row,
             center TYPE string,               " 도넛 가운데 글자(비우면 합계)
             height TYPE i,                    " 칸 높이(px), 0이면 내용에 맞춤
             nrows  TYPE i,                    " 패널 묶음의 행 수
             cwidth TYPE i,                    " 패널 한 칸의 폭(px)
           END OF ty_widget,
           ty_ctype TYPE c LENGTH 1,           " 차트 종류 D 도넛 / B 막대
           tt_widget TYPE STANDARD TABLE OF ty_widget WITH EMPTY KEY.

    CONSTANTS: c_card  TYPE c LENGTH 1 VALUE 'C',
               c_prog  TYPE c LENGTH 1 VALUE 'B',
               c_hbar  TYPE c LENGTH 1 VALUE 'H',
               c_donut TYPE c LENGTH 1 VALUE 'D',
               c_trend TYPE c LENGTH 1 VALUE 'L',
               c_table TYPE c LENGTH 1 VALUE 'T',
               c_ring  TYPE c LENGTH 1 VALUE 'R',
               c_stack TYPE c LENGTH 1 VALUE 'S',
               c_panels TYPE c LENGTH 1 VALUE 'P',
               c_ct_donut TYPE c LENGTH 1 VALUE 'D',
               c_ct_bar   TYPE c LENGTH 1 VALUE 'B',
               c_def_h  TYPE i VALUE 190.

    CLASS-DATA gv_empty_text TYPE string VALUE `데이터 없음`.   " 값이 없을 때 문구 (필요하면 바꿔 쓰기)

    METHODS constructor IMPORTING io_parent TYPE REF TO cl_gui_container.

    " 기존 방식 (그대로 유지)
    METHODS show IMPORTING it_card  TYPE tt_card
                           iv_title TYPE string OPTIONAL
                           is_bar   TYPE ty_bar OPTIONAL
                           iv_foot  TYPE string OPTIONAL.
    CLASS-METHODS build_html IMPORTING it_card  TYPE tt_card
                                       iv_title TYPE string OPTIONAL
                                       is_bar   TYPE ty_bar OPTIONAL
                                       iv_foot  TYPE string OPTIONAL
                             RETURNING VALUE(rt_html) TYPE tt_html.

    " v2 방식 : 위젯 목록을 넘김
    METHODS show_widgets IMPORTING it_widget TYPE tt_widget
                                   iv_title  TYPE string OPTIONAL
                                   iv_foot   TYPE string OPTIONAL.
    CLASS-METHODS build_html_w IMPORTING it_widget TYPE tt_widget
                                         iv_title  TYPE string OPTIONAL
                                         iv_foot   TYPE string OPTIONAL
                               RETURNING VALUE(rt_html) TYPE tt_html.
    " 컨테이너 높이(px) 추정값 - 컨테이너 높이를 잡을 때 참고
    CLASS-METHODS height_hint IMPORTING it_widget TYPE tt_widget
                                        iv_title  TYPE string OPTIONAL
                                        iv_foot   TYPE string OPTIONAL
                              RETURNING VALUE(rv_px) TYPE i.

    " 위젯 만들기 도우미 (APPEND zcl_cm_kpi_html=>w_card( ... ) TO lt_w.)
    CLASS-METHODS w_card IMPORTING iv_label TYPE string iv_value TYPE string
                                   iv_sub TYPE string OPTIONAL iv_color TYPE ty_card-color OPTIONAL
                         RETURNING VALUE(rs_w) TYPE ty_widget.
    CLASS-METHODS w_progress IMPORTING iv_label TYPE string iv_pct TYPE i
                                       iv_text TYPE string OPTIONAL iv_color TYPE ty_card-color OPTIONAL
                             RETURNING VALUE(rs_w) TYPE ty_widget.
    CLASS-METHODS w_hbar IMPORTING iv_title TYPE string it_item TYPE tt_item
                         RETURNING VALUE(rs_w) TYPE ty_widget.
    CLASS-METHODS w_donut IMPORTING iv_title TYPE string it_item TYPE tt_item
                                    iv_center TYPE string OPTIONAL
                          RETURNING VALUE(rs_w) TYPE ty_widget.
    CLASS-METHODS w_stack IMPORTING it_card TYPE tt_card
                                    iv_cols TYPE i OPTIONAL
                          RETURNING VALUE(rs_w) TYPE ty_widget.
    CLASS-METHODS w_ring IMPORTING iv_title TYPE string it_item TYPE tt_item
                                   iv_center TYPE string OPTIONAL
                                   iv_size TYPE i OPTIONAL
                         RETURNING VALUE(rs_w) TYPE ty_widget.
    CLASS-METHODS w_trend IMPORTING iv_title TYPE string it_item TYPE tt_item
                          RETURNING VALUE(rs_w) TYPE ty_widget.
    CLASS-METHODS w_table IMPORTING iv_title TYPE string it_head TYPE string_table
                                    it_row TYPE tt_row
                          RETURNING VALUE(rs_w) TYPE ty_widget.

    " 요약 화면 한 번에 : 차트(도넛 또는 막대) + 패널 묶음
    METHODS show_summary IMPORTING iv_title        TYPE string OPTIONAL
                                   iv_chart_type   TYPE ty_ctype DEFAULT 'D'
                                   iv_chart_title  TYPE string OPTIONAL
                                   it_chart_item   TYPE tt_item
                                   iv_chart_center TYPE string OPTIONAL
                                   it_card         TYPE tt_card
                                   iv_rows         TYPE i OPTIONAL
                                   iv_height       TYPE i OPTIONAL
                                   iv_foot         TYPE string OPTIONAL.
    CLASS-METHODS summary_widgets IMPORTING iv_chart_type   TYPE ty_ctype DEFAULT 'D'
                                            iv_chart_title  TYPE string OPTIONAL
                                            it_chart_item   TYPE tt_item
                                            iv_chart_center TYPE string OPTIONAL
                                            it_card         TYPE tt_card
                                            iv_rows         TYPE i OPTIONAL
                                            iv_height       TYPE i OPTIONAL
                                  RETURNING VALUE(rt_widget) TYPE tt_widget.
    CLASS-METHODS w_chart IMPORTING iv_type   TYPE ty_ctype DEFAULT 'D'
                                    iv_title  TYPE string OPTIONAL
                                    it_item   TYPE tt_item
                                    iv_center TYPE string OPTIONAL
                                    iv_height TYPE i OPTIONAL
                          RETURNING VALUE(rs_w) TYPE ty_widget.
    CLASS-METHODS w_panels IMPORTING it_card   TYPE tt_card
                                     iv_rows   TYPE i OPTIONAL
                                     iv_height TYPE i OPTIONAL
                           RETURNING VALUE(rs_w) TYPE ty_widget.

    METHODS free.

  PRIVATE SECTION.
    DATA mo_html TYPE REF TO cl_gui_html_viewer.
    CLASS-METHODS esc IMPORTING iv_text TYPE string RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS append_lines IMPORTING iv_text TYPE string CHANGING ct_html TYPE tt_html.
    CLASS-METHODS fmt IMPORTING iv TYPE decfloat34 RETURNING VALUE(rv) TYPE string.
    CLASS-METHODS fmt2 IMPORTING iv TYPE decfloat34 RETURNING VALUE(rv) TYPE string.
    CLASS-METHODS color_hex IMPORTING iv_c TYPE ty_card-color RETURNING VALUE(rv) TYPE string.
    CLASS-METHODS auto_color IMPORTING iv_c TYPE ty_card-color iv_idx TYPE i RETURNING VALUE(rv) TYPE string.
    CLASS-METHODS head_html IMPORTING iv_svg TYPE abap_bool RETURNING VALUE(rv) TYPE string.
    CLASS-METHODS html_hbar IMPORTING is_w TYPE ty_widget RETURNING VALUE(rv) TYPE string.
    CLASS-METHODS html_donut IMPORTING is_w TYPE ty_widget RETURNING VALUE(rv) TYPE string.
    CLASS-METHODS html_trend IMPORTING is_w TYPE ty_widget RETURNING VALUE(rv) TYPE string.
    CLASS-METHODS html_ring IMPORTING is_w TYPE ty_widget RETURNING VALUE(rv) TYPE string.
    CLASS-METHODS html_table IMPORTING is_w TYPE ty_widget RETURNING VALUE(rv) TYPE string.
ENDCLASS.



CLASS ZCL_CM_KPI_HTML IMPLEMENTATION.


  METHOD constructor.
    CREATE OBJECT mo_html
      EXPORTING parent = io_parent
                uiflag = cl_gui_html_viewer=>uiflag_no3dborder.
  ENDMETHOD.


  METHOD show.
    DATA lt_w TYPE tt_widget.
    LOOP AT it_card INTO DATA(ls_c).
      APPEND VALUE #( kind = c_card card = ls_c ) TO lt_w.
    ENDLOOP.
    IF is_bar-label IS NOT INITIAL.
      APPEND VALUE #( kind = c_prog bar = is_bar ) TO lt_w.
    ENDIF.
    show_widgets( it_widget = lt_w iv_title = iv_title iv_foot = iv_foot ).
  ENDMETHOD.


  METHOD build_html.
    DATA lt_w TYPE tt_widget.
    LOOP AT it_card INTO DATA(ls_c).
      APPEND VALUE #( kind = c_card card = ls_c ) TO lt_w.
    ENDLOOP.
    IF is_bar-label IS NOT INITIAL.
      APPEND VALUE #( kind = c_prog bar = is_bar ) TO lt_w.
    ENDIF.
    rt_html = build_html_w( it_widget = lt_w iv_title = iv_title iv_foot = iv_foot ).
  ENDMETHOD.


  METHOD show_widgets.
    DATA: lt_html TYPE tt_html,
          lv_url  TYPE c LENGTH 255.
    lt_html = build_html_w( it_widget = it_widget iv_title = iv_title iv_foot = iv_foot ).
    mo_html->load_data( EXPORTING type         = 'text'
                                  subtype      = 'html'
                        IMPORTING assigned_url = lv_url
                        CHANGING  data_table   = lt_html
                        EXCEPTIONS OTHERS      = 1 ).
    IF sy-subrc = 0.
      mo_html->show_url( url = lv_url ).
    ENDIF.
  ENDMETHOD.


  METHOD free.
    IF mo_html IS BOUND.
      mo_html->free( ).
      FREE mo_html.
    ENDIF.
  ENDMETHOD.


  METHOD w_card.
    rs_w = VALUE #( kind = c_card
                    card = VALUE #( label = iv_label value = iv_value sub = iv_sub color = iv_color ) ).
  ENDMETHOD.


  METHOD w_progress.
    rs_w = VALUE #( kind = c_prog
                    bar = VALUE #( label = iv_label pct = iv_pct text = iv_text color = iv_color ) ).
  ENDMETHOD.


  METHOD w_hbar.
    rs_w = VALUE #( kind = c_hbar title = iv_title items = it_item ).
  ENDMETHOD.


  METHOD w_donut.
    rs_w = VALUE #( kind = c_donut title = iv_title items = it_item center = iv_center ).
  ENDMETHOD.


  METHOD w_ring.
    rs_w = VALUE #( kind = c_ring title = iv_title items = it_item center = iv_center size = iv_size ).
  ENDMETHOD.


  METHOD w_stack.
    rs_w = VALUE #( kind = c_stack cards = it_card cols = iv_cols ).
  ENDMETHOD.


  METHOD w_trend.
    rs_w = VALUE #( kind = c_trend title = iv_title items = it_item ).
  ENDMETHOD.


  METHOD w_table.
    rs_w = VALUE #( kind = c_table title = iv_title head = it_head rows = it_row ).
  ENDMETHOD.


  METHOD show_summary.
    DATA(lt_w) = summary_widgets( iv_chart_type   = iv_chart_type
                                  iv_chart_title  = iv_chart_title
                                  it_chart_item   = it_chart_item
                                  iv_chart_center = iv_chart_center
                                  it_card         = it_card
                                  iv_rows         = iv_rows
                                  iv_height       = iv_height ).
    show_widgets( it_widget = lt_w iv_title = iv_title iv_foot = iv_foot ).
  ENDMETHOD.


  METHOD summary_widgets.
    DATA(lv_h) = COND i( WHEN iv_height > 0 THEN iv_height ELSE c_def_h ).
    APPEND w_chart( iv_type   = iv_chart_type
                    iv_title  = iv_chart_title
                    it_item   = it_chart_item
                    iv_center = iv_chart_center
                    iv_height = lv_h ) TO rt_widget.
    APPEND w_panels( it_card   = it_card
                     iv_rows   = iv_rows
                     iv_height = lv_h ) TO rt_widget.
  ENDMETHOD.


  METHOD w_chart.
    DATA(lv_h) = COND i( WHEN iv_height > 0 THEN iv_height ELSE c_def_h ).
    IF iv_type = c_ct_bar.
      rs_w = VALUE #( kind = c_hbar title = iv_title items = it_item height = lv_h ).
    ELSE.
      rs_w = VALUE #( kind = c_ring title = iv_title items = it_item center = iv_center
                      size = nmax( val1 = 60 val2 = lv_h - 66 ) height = lv_h ).
    ENDIF.
  ENDMETHOD.


  METHOD w_panels.
    rs_w = VALUE #( kind   = c_panels
                    cards  = it_card
                    nrows  = COND #( WHEN iv_rows > 0 THEN iv_rows ELSE 2 )
                    height = COND #( WHEN iv_height > 0 THEN iv_height ELSE c_def_h ) ).
  ENDMETHOD.


  METHOD esc.
    rv_text = escape( val = iv_text format = cl_abap_format=>e_html_text ).
  ENDMETHOD.


  METHOD append_lines.
    " 255자 단위로 자르되, 각 줄이 '>'로 끝나게 만들어서 끝 공백 유실 없음
    DATA(lv_len) = strlen( iv_text ).
    DATA(lv_off) = 0.
    WHILE lv_off < lv_len.
      DATA(lv_n) = nmin( val1 = 255 val2 = lv_len - lv_off ).
      APPEND CONV ty_line( iv_text+lv_off(lv_n) ) TO ct_html.
      lv_off = lv_off + lv_n.
    ENDWHILE.
  ENDMETHOD.


  METHOD fmt.
    " 정수면 정수로, 아니면 소수 1자리 (사용자 소수점 설정과 무관하게 '.')
    IF frac( iv ) = 0.
      rv = |{ CONV i( iv ) }|.
    ELSE.
      rv = |{ iv DECIMALS = 1 NUMBER = RAW }|.
    ENDIF.
  ENDMETHOD.


  METHOD fmt2.
    " SVG 좌표/비율용: 소수 2자리, 항상 '.' 구분
    rv = |{ iv DECIMALS = 2 NUMBER = RAW }|.
  ENDMETHOD.


  METHOD color_hex.
    rv = SWITCH string( iv_c
           WHEN 'R' THEN `#ee7d7d`
           WHEN 'Y' THEN `#eab94d`
           WHEN 'G' THEN `#5fb98f`
           WHEN 'B' THEN `#6f9bec`
           ELSE          `#a3abbd` ).
  ENDMETHOD.


  METHOD auto_color.
    " 색을 안 줬으면 순서대로 파랑-초록-노랑-빨강-회색 반복
    IF iv_c IS NOT INITIAL.
      rv = color_hex( iv_c ).
      RETURN.
    ENDIF.
    DATA(lv_k) = ( iv_idx - 1 ) MOD 5.
    rv = SWITCH string( lv_k
           WHEN 0 THEN color_hex( 'B' )
           WHEN 1 THEN color_hex( 'G' )
           WHEN 2 THEN color_hex( 'Y' )
           WHEN 3 THEN color_hex( 'R' )
           ELSE        color_hex( 'N' ) ).
  ENDMETHOD.


  METHOD head_html.
    DATA(nl) = cl_abap_char_utilities=>newline.
    rv = `<html><head>` && nl.
    rv = rv &&
      `<meta http-equiv="Content-Type" content="text/html; charset=utf-8">` && nl &&
      `<style>` && nl &&
      `body{margin:0;padding:6px 10px;font-family:'Malgun Gothic',Arial,sans-serif;font-size:12px;background:#f6f7fb;overflow:hidden}` && nl &&
      `.t{font-size:13px;font-weight:bold;color:#2c3347;margin-bottom:8px}` && nl &&
      `.card{display:inline-block;vertical-align:top;min-width:150px;margin:0 8px 8px 0;padding:8px 14px;background:#eef0f4;border-radius:14px}` && nl &&
      `.l{font-size:11px;color:#7a8296}` && nl &&
      `.v{font-size:20px;font-weight:bold;color:#3b4358}` && nl &&
      `.s{font-size:11px;color:#7a8296}` && nl &&
      `.cR{background:#fdeaea}.cR .v{color:#cf5555}` && nl &&
      `.cY{background:#fdf3dc}.cY .v{color:#b8860b}` && nl &&
      `.cG{background:#e6f6ee}.cG .v{color:#2a8a60}` && nl &&
      `.cB{background:#e8f0fd}.cB .v{color:#3563c9}` && nl &&
      `.cW{background:#fff;box-shadow:0 1px 3px rgba(60,70,100,.1)}` && nl &&
      `.bar{margin-top:2px;margin-bottom:6px}` && nl &&
      `.bl{display:inline-block;width:100px;color:#3b4358;font-weight:bold}` && nl &&
      `.track{display:inline-block;width:320px;height:12px;background:#eceff5;border-radius:10px;vertical-align:middle;overflow:hidden}` && nl &&
      `.fill{display:block;height:12px;border-radius:10px}` && nl &&
      `.fR{background:#ee7d7d}.fY{background:#eab94d}.fG{background:#5fb98f}.fB{background:#6f9bec}.fN{background:#a3abbd}` && nl &&
      `.bt{margin-left:8px;color:#3b4358}` && nl &&
      `.f{margin-top:4px;font-size:11px;color:#7a8296}` && nl &&
      `.w{display:inline-block;vertical-align:top;margin:0 8px 8px 0;padding:8px 14px;background:#fff;border-radius:14px;box-shadow:0 1px 3px rgba(60,70,100,.1)}` && nl &&
      `.wt{font-size:11px;font-weight:bold;color:#7a8296;margin-bottom:6px}` && nl &&
      `.hr{margin:3px 0;white-space:nowrap}` && nl &&
      `.hl{display:inline-block;width:80px;color:#3b4358;overflow:hidden}` && nl &&
      `.ht{display:inline-block;width:150px;height:10px;background:#eceff5;border-radius:10px;vertical-align:middle;overflow:hidden}` && nl &&
      `.hv{margin-left:6px;color:#3b4358;font-weight:bold}` && nl &&
      `.lg{display:inline-block;vertical-align:middle;margin-left:10px;color:#3b4358}` && nl &&
      `.lg div{margin:2px 0;white-space:nowrap}` && nl &&
      `.sq{display:inline-block;width:9px;height:9px;margin-right:5px;border-radius:3px}` && nl &&
      `.mt{border-collapse:collapse;color:#3b4358}` && nl &&
      `.mt th{text-align:left;font-size:11px;font-weight:normal;color:#7a8296;padding:2px 14px 2px 0}` && nl &&
      `.mt td{padding:3px 14px 3px 0;border-top:1px solid #f0f2f7}` && nl &&
      `.mt .r{text-align:right}` && nl &&
      `.nd{color:#98a2b3}` && nl &&
      `.big{font-size:20px;font-weight:bold;color:#3b4358}` && nl &&
      `.stk{font-size:0;white-space:nowrap;height:14px;width:260px;background:#eceff5;border-radius:10px;overflow:hidden}` && nl &&
      `.seg{display:inline-block;height:14px}` && nl &&
      `.cols{white-space:nowrap;height:92px}` && nl &&
      `.cc{display:inline-block;width:34px;margin-right:6px;text-align:center;vertical-align:bottom}` && nl &&
      `.cv{font-size:10px;color:#3b4358}` && nl &&
      `.cb{margin:1px auto 2px auto;width:20px;border-radius:8px 8px 3px 3px}` && nl &&
      `.cx{font-size:10px;color:#7a8296}` && nl &&
      `.grp{display:inline-block;vertical-align:top;margin:0 8px 0 0;font-size:0}` && nl &&
      `.pg{display:inline-block;vertical-align:top;margin:0 8px 0 0}` && nl &&
      `.pc{display:block;box-sizing:border-box;min-width:0;margin:0;padding:8px 14px;overflow:hidden}` && nl &&
      `.grp .card{display:block;margin:0 0 6px 0;min-width:190px;padding:6px 14px}` && nl &&
      `.grp .gc{display:inline-block;vertical-align:top;box-sizing:border-box;width:200px;min-width:0;margin:0 8px 8px 0;padding:8px 14px}` && nl &&
      `</style></head><body>` && nl.
  ENDMETHOD.


  METHOD html_hbar.
    DATA(nl) = cl_abap_char_utilities=>newline.
    DATA lv_max TYPE decfloat34.
    LOOP AT is_w-items INTO DATA(ls_m).
      IF ls_m-value > lv_max.
        lv_max = ls_m-value.
      ENDIF.
    ENDLOOP.
    DATA(lv_idx) = 0.
    LOOP AT is_w-items INTO DATA(ls_i).
      lv_idx = lv_idx + 1.
      DATA(lv_pct) = 0.
      IF lv_max > 0 AND ls_i-value > 0.
        lv_pct = nmax( val1 = 2 val2 = CONV i( round( val = ls_i-value / lv_max * 100 dec = 0 ) ) ).
      ENDIF.
      DATA(lv_col) = auto_color( iv_c = ls_i-color iv_idx = lv_idx ).
      rv = rv && |<div class="hr"><span class="hl">{ esc( ls_i-label ) }</span>{ nl }|
              && |<span class="ht"><span class="fill" style="background:{ lv_col };width:{ lv_pct }%"></span></span>{ nl }|
              && |<span class="hv">{ fmt( ls_i-value ) }</span></div>{ nl }|.
    ENDLOOP.
  ENDMETHOD.


  METHOD html_donut.
    DATA(nl) = cl_abap_char_utilities=>newline.
    DATA: lv_total TYPE decfloat34,
          lv_segs  TYPE string.
    LOOP AT is_w-items INTO DATA(ls_t).
      lv_total = lv_total + ls_t-value.
    ENDLOOP.
    IF lv_total <= 0.
      rv = |<span class="nd">{ esc( gv_empty_text ) }</span>{ nl }|.
      RETURN.
    ENDIF.
    DATA(lv_center) = COND string( WHEN is_w-center IS NOT INITIAL THEN is_w-center
                                   ELSE fmt( lv_total ) ).
    DATA(lv_idx) = 0.
    LOOP AT is_w-items INTO DATA(ls_i).
      lv_idx = lv_idx + 1.
      CHECK ls_i-value > 0.
      DATA(lv_px) = nmax( val1 = 3 val2 = CONV i( round( val = ls_i-value / lv_total * 260 dec = 0 ) ) ).
      DATA(lv_col) = auto_color( iv_c = ls_i-color iv_idx = lv_idx ).
      lv_segs = lv_segs && |<span class="seg" style="background:{ lv_col };width:{ lv_px }px"></span>|.
    ENDLOOP.
    rv = |<div class="big">{ esc( lv_center ) }</div>{ nl }|
      && |<div class="stk">{ lv_segs }</div>{ nl }|
      && |<div class="lg" style="margin-left:0">{ nl }|.
    lv_idx = 0.
    LOOP AT is_w-items INTO DATA(ls_l).
      lv_idx = lv_idx + 1.
      DATA(lv_lc) = auto_color( iv_c = ls_l-color iv_idx = lv_idx ).
      DATA(lv_lp) = COND decfloat34( WHEN lv_total > 0 THEN ls_l-value / lv_total * 100 ELSE 0 ).
      rv = rv && |<div><span class="sq" style="background:{ lv_lc }"></span>{ esc( ls_l-label ) } { fmt( ls_l-value ) } ({ CONV i( round( val = lv_lp dec = 0 ) ) }%)</div>{ nl }|.
    ENDLOOP.
    rv = rv && |</div>{ nl }|.
  ENDMETHOD.


  METHOD html_trend.
    DATA(nl) = cl_abap_char_utilities=>newline.
    DATA: lv_max  TYPE decfloat34,
          lv_cols TYPE string.
    IF lines( is_w-items ) = 0.
      rv = |<span class="nd">{ esc( gv_empty_text ) }</span>{ nl }|.
      RETURN.
    ENDIF.
    LOOP AT is_w-items INTO DATA(ls_m).
      IF ls_m-value > lv_max.
        lv_max = ls_m-value.
      ENDIF.
    ENDLOOP.
    DATA(lv_idx) = 0.
    LOOP AT is_w-items INTO DATA(ls_i).
      lv_idx = lv_idx + 1.
      DATA(lv_h) = 2.
      IF lv_max > 0 AND ls_i-value > 0.
        lv_h = nmax( val1 = 2 val2 = CONV i( round( val = ls_i-value / lv_max * 56 dec = 0 ) ) ).
      ENDIF.
      DATA(lv_c1) = ls_i-color.
      IF lv_c1 IS INITIAL.
        lv_c1 = 'B'.
      ENDIF.
      lv_cols = lv_cols && |<span class="cc"><div class="cv">{ fmt( ls_i-value ) }</div>|
                        && |<div class="cb" style="background:{ color_hex( lv_c1 ) };height:{ lv_h }px"></div>|
                        && |<div class="cx">{ esc( ls_i-label ) }</div></span>|.
    ENDLOOP.
    rv = |<div class="cols">{ lv_cols }</div>{ nl }|.
  ENDMETHOD.


  METHOD html_ring.
    DATA(nl) = cl_abap_char_utilities=>newline.
    DATA: lv_total TYPE decfloat34,
          lv_cum   TYPE decfloat34,
          lv_p     TYPE decfloat34.
    LOOP AT is_w-items INTO DATA(ls_t).
      lv_total = lv_total + ls_t-value.
    ENDLOOP.
    IF lv_total <= 0.
      rv = |<span class="nd">{ esc( gv_empty_text ) }</span>{ nl }|.
      RETURN.
    ENDIF.
    DATA(lv_size) = COND i( WHEN is_w-size > 0 THEN is_w-size ELSE 92 ).
    rv = |<svg width="{ lv_size }" height="{ lv_size }" viewBox="0 0 42 42" style="vertical-align:middle">{ nl }|
      && |<circle cx="21" cy="21" r="15.9155" fill="none" stroke="#eceff5" stroke-width="6.5"></circle>{ nl }|.
    DATA(lv_idx) = 0.
    LOOP AT is_w-items INTO DATA(ls_i).
      lv_idx = lv_idx + 1.
      CHECK ls_i-value > 0.
      lv_p = ls_i-value / lv_total * 100.
      DATA(lv_col) = auto_color( iv_c = ls_i-color iv_idx = lv_idx ).
      rv = rv && |<circle cx="21" cy="21" r="15.9155" fill="none" stroke="{ lv_col }" stroke-width="6.5" |
              && |stroke-dasharray="{ fmt2( lv_p ) } { fmt2( 100 - lv_p ) }" |
              && |stroke-dashoffset="{ fmt2( 25 - lv_cum ) }"></circle>{ nl }|.
      lv_cum = lv_cum + lv_p.
    ENDLOOP.
    DATA(lv_center) = COND string( WHEN is_w-center IS NOT INITIAL THEN is_w-center
                                   ELSE fmt( lv_total ) ).
    rv = rv && |<text x="21" y="23.5" text-anchor="middle" font-size="7" font-weight="bold" fill="#3b4358">{ esc( lv_center ) }</text>{ nl }|
            && |</svg>{ nl }|
            && |<div class="lg">{ nl }|.
    lv_idx = 0.
    LOOP AT is_w-items INTO DATA(ls_l).
      lv_idx = lv_idx + 1.
      DATA(lv_lc) = auto_color( iv_c = ls_l-color iv_idx = lv_idx ).
      DATA(lv_lp) = COND decfloat34( WHEN lv_total > 0 THEN ls_l-value / lv_total * 100 ELSE 0 ).
      rv = rv && |<div><span class="sq" style="background:{ lv_lc }"></span>{ esc( ls_l-label ) } { fmt( ls_l-value ) } ({ CONV i( round( val = lv_lp dec = 0 ) ) }%)</div>{ nl }|.
    ENDLOOP.
    rv = rv && |</div>{ nl }|.
  ENDMETHOD.


  METHOD html_table.
    DATA(nl) = cl_abap_char_utilities=>newline.
    rv = |<table class="mt">{ nl }|.
    IF is_w-head IS NOT INITIAL.
      rv = rv && |<tr>{ nl }|.
      LOOP AT is_w-head INTO DATA(lv_h).
        rv = rv && |<th>{ esc( lv_h ) }</th>{ nl }|.
      ENDLOOP.
      rv = rv && |</tr>{ nl }|.
    ENDIF.
    LOOP AT is_w-rows INTO DATA(ls_r).
      rv = rv && |<tr>{ nl }|.
      LOOP AT ls_r-cells INTO DATA(lv_c).
        DATA(lv_cls) = COND string( WHEN lv_c IS NOT INITIAL AND lv_c CO '0123456789.,-% '
                                    THEN ` class="r"` ELSE `` ).
        rv = rv && |<td{ lv_cls }>{ esc( lv_c ) }</td>{ nl }|.
      ENDLOOP.
      rv = rv && |</tr>{ nl }|.
    ENDLOOP.
    rv = rv && |</table>{ nl }|.
  ENDMETHOD.


  METHOD build_html_w.
    DATA(nl) = cl_abap_char_utilities=>newline.

    DATA(lv_svg) = abap_false.
    LOOP AT it_widget INTO DATA(ls_chk) WHERE kind = c_donut OR kind = c_trend.
      lv_svg = abap_true.
      EXIT.
    ENDLOOP.

    DATA(lv_h) = head_html( lv_svg ).

    IF iv_title IS NOT INITIAL.
      lv_h = lv_h && |<div class="t">{ esc( iv_title ) }</div>{ nl }|.
    ENDIF.

    LOOP AT it_widget INTO DATA(ls_w).
      CASE ls_w-kind.
        WHEN c_card.
          DATA(lv_cls) = COND string( WHEN ls_w-card-color IS INITIAL THEN `N` ELSE ls_w-card-color ).
          DATA(lv_sub) = COND string( WHEN ls_w-card-sub IS INITIAL THEN `&nbsp;` ELSE esc( ls_w-card-sub ) ).
          lv_h = lv_h && |<div class="card c{ lv_cls }">{ nl }|
                      && |<div class="l">{ esc( ls_w-card-label ) }</div>{ nl }|
                      && |<div class="v">{ esc( ls_w-card-value ) }</div>{ nl }|
                      && |<div class="s">{ lv_sub }</div>{ nl }|
                      && |</div>{ nl }|.

        WHEN c_stack.
          DATA(lv_gc)  = nmax( val1 = 1 val2 = ls_w-cols ).
          DATA(lv_gw)  = lv_gc * 208 + 4.
          DATA(lv_gcl) = COND string( WHEN lv_gc > 1 THEN ` gc` ELSE `` ).
          lv_h = lv_h && |<div class="grp" style="width:{ lv_gw }px">{ nl }|.
          LOOP AT ls_w-cards INTO DATA(ls_sc).
            DATA(lv_scls) = COND string( WHEN ls_sc-color IS INITIAL THEN `N` ELSE ls_sc-color ).
            DATA(lv_ssub) = COND string( WHEN ls_sc-sub IS INITIAL THEN `&nbsp;` ELSE esc( ls_sc-sub ) ).
            lv_h = lv_h && |<div class="card c{ lv_scls }{ lv_gcl }">{ nl }|
                        && |<div class="l">{ esc( ls_sc-label ) }</div>{ nl }|
                        && |<div class="v">{ esc( ls_sc-value ) }</div>{ nl }|
                        && |<div class="s">{ lv_ssub }</div>{ nl }|
                        && |</div>{ nl }|.
          ENDLOOP.
          lv_h = lv_h && |</div>{ nl }|.

        WHEN c_panels.
          DATA(lv_pr)  = nmax( val1 = 1 val2 = ls_w-nrows ).
          DATA(lv_ph)  = COND i( WHEN ls_w-height > 0 THEN ls_w-height ELSE c_def_h ).
          DATA(lv_pch) = ( lv_ph - 8 * ( lv_pr - 1 ) ) DIV lv_pr.
          DATA(lv_pn)  = lines( ls_w-cards ).
          DATA(lv_pbs) = lv_pr * 2.
          DATA(lv_pnc) = COND i( WHEN lv_pn <= 1 THEN 1
                                 WHEN lv_pn <= lv_pbs THEN 2
                                 ELSE 2 + ( lv_pn - lv_pbs + lv_pr - 1 ) DIV lv_pr ).
          DATA(lv_pcw) = COND i( WHEN ls_w-cwidth > 0 THEN ls_w-cwidth ELSE 200 ).
          lv_h = lv_h && |<div class="pg"><table cellspacing="0" cellpadding="0">{ nl }|.
          DO lv_pr TIMES.
            DATA(lv_prow) = sy-index.
            lv_h = lv_h && |<tr>{ nl }|.
            DO lv_pnc TIMES.
              DATA(lv_pcol) = sy-index.
              DATA(lv_pix)  = COND i( WHEN lv_pcol <= 2 THEN ( lv_prow - 1 ) * 2 + lv_pcol
                                      ELSE lv_pbs + ( lv_pcol - 3 ) * lv_pr + lv_prow ).
              DATA(lv_pbot) = COND i( WHEN lv_prow < lv_pr THEN 8 ELSE 0 ).
              lv_h = lv_h && |<td style="vertical-align:top;padding:0 8px { lv_pbot }px 0">{ nl }|.
              IF lv_pix <= lv_pn.
                DATA(ls_pc)   = ls_w-cards[ lv_pix ].
                DATA(lv_pcls) = COND string( WHEN ls_pc-color IS INITIAL THEN `N` ELSE ls_pc-color ).
                DATA(lv_psub) = COND string( WHEN ls_pc-sub IS INITIAL THEN `&nbsp;` ELSE esc( ls_pc-sub ) ).
                lv_h = lv_h && |<div class="card pc c{ lv_pcls }" style="width:{ lv_pcw }px;height:{ lv_pch }px">{ nl }|
                            && |<div class="l">{ esc( ls_pc-label ) }</div>{ nl }|
                            && |<div class="v">{ esc( ls_pc-value ) }</div>{ nl }|
                            && |<div class="s">{ lv_psub }</div>{ nl }|
                            && |</div>{ nl }|.
              ENDIF.
              lv_h = lv_h && |</td>{ nl }|.
            ENDDO.
            lv_h = lv_h && |</tr>{ nl }|.
          ENDDO.
          lv_h = lv_h && |</table></div>{ nl }|.

        WHEN c_prog.
          DATA(lv_pct) = nmax( val1 = 0 val2 = nmin( val1 = 100 val2 = ls_w-bar-pct ) ).
          DATA(lv_bc)  = COND string( WHEN ls_w-bar-color IS INITIAL THEN `B` ELSE ls_w-bar-color ).
          lv_h = lv_h && |<div class="bar"><span class="bl">{ esc( ls_w-bar-label ) }</span>{ nl }|
                      && |<span class="track"><span class="fill f{ lv_bc }" style="width:{ lv_pct }%"></span></span>{ nl }|
                      && |<span class="bt">{ esc( ls_w-bar-text ) }</span></div>{ nl }|.

        WHEN c_hbar OR c_donut OR c_trend OR c_table OR c_ring.
          DATA(lv_wst) = COND string(
                           WHEN ls_w-height > 0
                           THEN | style="height:{ ls_w-height }px;min-width:300px;box-sizing:border-box;overflow:hidden"|
                           ELSE `` ).
          lv_h = lv_h && |<div class="w"{ lv_wst }>{ nl }|.
          IF ls_w-title IS NOT INITIAL.
            lv_h = lv_h && |<div class="wt">{ esc( ls_w-title ) }</div>{ nl }|.
          ENDIF.
          CASE ls_w-kind.
            WHEN c_hbar.  lv_h = lv_h && html_hbar( ls_w ).
            WHEN c_donut. lv_h = lv_h && html_donut( ls_w ).
            WHEN c_trend. lv_h = lv_h && html_trend( ls_w ).
            WHEN c_ring.  lv_h = lv_h && html_ring( ls_w ).
            WHEN c_table. lv_h = lv_h && html_table( ls_w ).
          ENDCASE.
          lv_h = lv_h && |</div>{ nl }|.
      ENDCASE.
    ENDLOOP.

    IF iv_foot IS NOT INITIAL.
      lv_h = lv_h && |<div class="f">{ esc( iv_foot ) }</div>{ nl }|.
    ENDIF.

    lv_h = lv_h && `</body></html>`.

    DATA lt_lines TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    SPLIT lv_h AT nl INTO TABLE lt_lines.
    LOOP AT lt_lines INTO DATA(lv_line).
      append_lines( EXPORTING iv_text = lv_line CHANGING ct_html = rt_html ).
    ENDLOOP.
  ENDMETHOD.


  METHOD height_hint.
    DATA: lv_inline TYPE i,
          lv_bars   TYPE i,
          lv_h      TYPE i.
    LOOP AT it_widget INTO DATA(ls_w).
      CASE ls_w-kind.
        WHEN c_card.  lv_h = 72.
        WHEN c_prog.  lv_bars = lv_bars + 22. CONTINUE.
        WHEN c_hbar.  lv_h = 26 + 18 * lines( ls_w-items ).
        WHEN c_donut. lv_h = 30 + 18 * lines( ls_w-items ) + 20.
        WHEN c_trend. lv_h = 120.
        WHEN c_ring.  lv_h = 50 + COND i( WHEN ls_w-size > 0 THEN ls_w-size ELSE 92 ).
        WHEN c_stack. lv_h = 80 * ( ( lines( ls_w-cards ) + nmax( val1 = 1 val2 = ls_w-cols ) - 1 ) DIV nmax( val1 = 1 val2 = ls_w-cols ) ).
        WHEN c_table. lv_h = 30 + 20 * ( lines( ls_w-rows ) + 1 ).
        WHEN c_panels. lv_h = COND i( WHEN ls_w-height > 0 THEN ls_w-height ELSE c_def_h ).
      ENDCASE.
      IF ls_w-height > 0.
        lv_h = ls_w-height + 8.
      ENDIF.
      lv_inline = nmax( val1 = lv_inline val2 = lv_h ).
    ENDLOOP.
    rv_px = lv_inline + lv_bars + 12.
    IF iv_title IS NOT INITIAL.
      rv_px = rv_px + 24.
    ENDIF.
    IF iv_foot IS NOT INITIAL.
      rv_px = rv_px + 20.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
