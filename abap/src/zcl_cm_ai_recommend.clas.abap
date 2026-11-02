CLASS zcl_cm_ai_recommend DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS recommend
      IMPORTING iv_exnum   TYPE ztexa00010-exnum
                iv_context TYPE string OPTIONAL
      EXPORTING ev_acttp   TYPE ztcma00080-cdval
                ev_actnm   TYPE ztcma00080-cdnam
                ev_reason  TYPE string
                ev_cnt     TYPE i
                ev_success TYPE abap_bool
                ev_message TYPE string.
ENDCLASS.



CLASS ZCL_CM_AI_RECOMMEND IMPLEMENTATION.


  METHOD recommend.
    TYPES: BEGIN OF ty_ans,
             acttp  TYPE string,
             reason TYPE string,
           END OF ty_ans.
    DATA: ls_ans   TYPE ty_ans,
          lv_cases TYPE string,
          lv_res   TYPE string,
          lv_text  TYPE string.

    CLEAR: ev_acttp, ev_actnm, ev_reason, ev_cnt, ev_success, ev_message.

    " 1) 헤더
    SELECT SINGLE srtyp, extyp, owgrp, crdat
      FROM ztexa00010 WHERE exnum = @iv_exnum
      INTO @DATA(ls_hdr).
    IF sy-subrc <> 0.
      ev_message = |예외 { iv_exnum }을(를) 찾을 수 없습니다.|.
      RETURN.
    ENDIF.

    " 2) 이 출처에 허용된 조치 (decideAction과 같은 기준)
    SELECT cdval, cdnam FROM ztcma00080
      WHERE cdgrp = 'ACTTP' AND cddsc = @ls_hdr-srtyp
      INTO TABLE @DATA(lt_allow).
    IF lt_allow IS INITIAL.
      ev_message = |{ ls_hdr-srtyp }에 허용된 조치 코드가 없습니다.|.
      RETURN.
    ENDIF.
    DATA(lv_codes) = REDUCE string( INIT s = `` FOR a IN lt_allow
                       NEXT s = s && |{ a-cdval }={ a-cdnam }; | ).

    " 3) 유사 사례: 같은 출처 + 종료(CLSD) 건의 조치 결정 이력, 최근 5건
    SELECT h~exnum, l~prtxt
      FROM ztexa00010 AS h
      INNER JOIN ztexa00020 AS l ON l~exnum = h~exnum
      WHERE h~srtyp = @ls_hdr-srtyp
        AND h~prsta = 'CLSD'
        AND h~exnum <> @iv_exnum
        AND l~prres = 'ACTN'
        AND l~prtxt LIKE '[%'
      ORDER BY l~logno DESCENDING
      INTO TABLE @DATA(lt_all) UP TO 50 ROWS.

    " 건(EXNUM)당 최신 조치 1행만, 최대 5건
    DATA lt_case LIKE lt_all.
    LOOP AT lt_all INTO DATA(ls_a).
      IF line_exists( lt_case[ exnum = ls_a-exnum ] ).
        CONTINUE.
      ENDIF.
      APPEND ls_a TO lt_case.
      IF lines( lt_case ) >= 5.
        EXIT.
      ENDIF.
    ENDLOOP.
    ev_cnt = lines( lt_case ).

    LOOP AT lt_case INTO DATA(ls_c).
      CLEAR lv_res.
      SELECT prtxt FROM ztexa00020
        WHERE exnum = @ls_c-exnum AND prres = 'CLSD'
        ORDER BY logno DESCENDING
        INTO @lv_res UP TO 1 ROWS.
      ENDSELECT.
      lv_cases = lv_cases && |{ sy-tabix }) 선택 조치: { ls_c-prtxt } / 종료 메모: { lv_res }\n|.
    ENDLOOP.
    IF lv_cases IS INITIAL.
      lv_cases = `(과거 사례 없음)`.
    ENDIF.

    " 4) 프롬프트 (개인정보 없음)
    DATA(lv_age) = sy-datum - ls_hdr-crdat.
    DATA(lv_prompt) =
      |너는 반도체 장비 제조사의 구매·재무 예외(Exception) 처리 보조자다.\n| &&
      |아래 예외 건에 대해 허용된 조치 코드 중 하나만 추천하라.\n\n| &&
      |[현재 건]\n발생출처: { ls_hdr-srtyp }\n예외유형: { ls_hdr-extyp }\n| &&
      |담당그룹: { ls_hdr-owgrp }\n경과일: { lv_age }\n상세: { iv_context }\n\n| &&
      |[허용 조치 코드]\n{ lv_codes }\n\n| &&
      |[과거 유사 사례]\n{ lv_cases }\n\n| &&
      |근거에는 과거 사례에서 같은 코드가 몇 건 선택됐는지 포함하라.\n| &&
      |반드시 아래 JSON 한 개만 출력하라. 설명과 코드블록은 금지.\n| &&
      |\{"acttp":"코드","reason":"한국어 50자 이내 근거"\}|.

    " 5) 호출
    DATA lv_ok  TYPE abap_bool.
    DATA lv_msg TYPE string.
    zcl_cm_ai_service=>call_text(
      EXPORTING iv_prompt  = lv_prompt
      IMPORTING ev_text    = lv_text
                ev_success = lv_ok
                ev_message = lv_msg ).
    IF lv_ok = abap_false.
      ev_message = lv_msg.
      RETURN.
    ENDIF.

    " 6) JSON 추출·파싱
    DATA(lv_s) = find( val = lv_text sub = `{` ).
    DATA(lv_e) = find( val = lv_text sub = `}` occ = -1 ).
    IF lv_s < 0 OR lv_e < lv_s.
      ev_message = 'AI 응답 형식 오류'.
      RETURN.
    ENDIF.
    DATA(lv_json) = substring( val = lv_text off = lv_s len = lv_e - lv_s + 1 ).
    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING json        = lv_json
                    pretty_name = /ui2/cl_json=>pretty_mode-low_case
          CHANGING  data        = ls_ans ).
      CATCH cx_root.
        ev_message = 'AI 응답 파싱 오류'.
        RETURN.
    ENDTRY.

    " 7) 허용 목록 검증 (목록 밖이면 버림)
    DATA(lv_code) = to_upper( condense( ls_ans-acttp ) ).
    READ TABLE lt_allow INTO DATA(ls_hit) WITH KEY cdval = lv_code.
    IF sy-subrc <> 0.
      ev_message = |허용되지 않은 코드 응답: { lv_code }|.
      RETURN.
    ENDIF.

    ev_acttp   = ls_hit-cdval.
    ev_actnm   = ls_hit-cdnam.
    ev_reason  = condense( ls_ans-reason ).
    ev_success = abap_true.
  ENDMETHOD.
ENDCLASS.
