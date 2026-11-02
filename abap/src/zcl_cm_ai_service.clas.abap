CLASS zcl_cm_ai_service DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS call_text
      IMPORTING
        !iv_prompt  TYPE string
      EXPORTING
        !ev_text    TYPE string
        !ev_success TYPE abap_bool
        !ev_message TYPE string .

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS: gc_dest  TYPE rfcdest VALUE 'ZOPENAI_API',
               gc_keyid TYPE c LENGTH 10 VALUE 'CM'.

ENDCLASS.



CLASS ZCL_CM_AI_SERVICE IMPLEMENTATION.


  METHOD call_text.

    TYPES: BEGIN OF ty_content,
             type TYPE string,
             text TYPE string,
           END OF ty_content.
    TYPES tt_content TYPE STANDARD TABLE OF ty_content WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_input,
             role    TYPE string,
             content TYPE tt_content,
           END OF ty_input.
    TYPES tt_input TYPE STANDARD TABLE OF ty_input WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_request,
             model TYPE string,
             input TYPE tt_input,
           END OF ty_request.

    TYPES: BEGIN OF ty_output_content,
             type TYPE string,
             text TYPE string,
           END OF ty_output_content.
    TYPES tt_output_content TYPE STANDARD TABLE OF ty_output_content WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_output,
             type    TYPE string,
             content TYPE tt_output_content,
           END OF ty_output.
    TYPES tt_output TYPE STANDARD TABLE OF ty_output WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_api_response,
             status TYPE string,
             output TYPE tt_output,
           END OF ty_api_response.

    DATA: lo_http  TYPE REF TO if_http_client,
          ls_req   TYPE ty_request,
          ls_input TYPE ty_input,
          ls_cont  TYPE ty_content,
          ls_resp  TYPE ty_api_response,
          lv_json  TYPE string,
          lv_resp  TYPE string,
          lv_key   TYPE string,
          lv_auth  TYPE string,
          lv_code  TYPE i,
          lv_reas  TYPE string,
          lv_ecode TYPE i,
          lv_emsg  TYPE string.

    CLEAR: ev_text, ev_message.
    ev_success = abap_false.

    IF iv_prompt IS INITIAL.
      ev_message = 'AI 입력(프롬프트)이 없습니다.'.
      RETURN.
    ENDIF.

    """ 키·모델은 설정 테이블에서 읽는다 (코드에 두지 않음)
    SELECT SINGLE model, apikey
      FROM ztexa00070
      WHERE keyid = @gc_keyid
      INTO @DATA(ls_cfg).

    IF sy-subrc <> 0 OR ls_cfg-apikey IS INITIAL OR ls_cfg-model IS INITIAL.
      ev_message = 'AI 연결 설정(ZTEXA00070)이 없습니다.'.
      RETURN.
    ENDIF.

    """ 요청 JSON
    ls_req-model  = condense( ls_cfg-model ).
    ls_input-role = 'user'.
    ls_cont-type  = 'input_text'.
    ls_cont-text  = iv_prompt.
    APPEND ls_cont  TO ls_input-content.
    APPEND ls_input TO ls_req-input.

    lv_json = /ui2/cl_json=>serialize(
      data        = ls_req
      compress    = abap_true
      pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    """ SM59 대상 (주소만 사용, 키는 헤더로 전달)
    cl_http_client=>create_by_destination(
      EXPORTING
        destination              = gc_dest
      IMPORTING
        client                   = lo_http
      EXCEPTIONS
        argument_not_found       = 1
        destination_not_found    = 2
        destination_no_authority = 3
        plugin_not_active        = 4
        internal_error           = 5
        OTHERS                   = 6 ).

    IF sy-subrc <> 0 OR lo_http IS NOT BOUND.
      ev_message = 'AI HTTP Destination 연결 실패'.
      RETURN.
    ENDIF.

    cl_http_utility=>set_request_uri(
      request = lo_http->request
      uri     = '/v1/responses' ).
    lo_http->request->set_method( if_http_request=>co_request_method_post ).
    lo_http->request->set_header_field( name = 'Content-Type' value = 'application/json' ).

    lv_key  = ls_cfg-apikey.
    CONDENSE lv_key NO-GAPS.
    lv_auth = |Bearer { lv_key }|.
    lo_http->request->set_header_field( name = 'Authorization' value = lv_auth ).
    CLEAR: lv_key, lv_auth.

    lo_http->request->set_cdata( data = lv_json ).

    lo_http->send(
      EXPORTING
        timeout                    = 60
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        http_invalid_timeout       = 4
        OTHERS                     = 5 ).

    IF sy-subrc <> 0.
      lo_http->get_last_error( IMPORTING code = lv_ecode message = lv_emsg ).
      ev_message = |AI 요청 실패: { lv_ecode } / { lv_emsg }|.
      lo_http->close( ).
      RETURN.
    ENDIF.

    lo_http->receive(
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4 ).

    IF sy-subrc <> 0.
      lo_http->get_last_error( IMPORTING code = lv_ecode message = lv_emsg ).
      ev_message = |AI 응답 수신 실패: { lv_ecode } / { lv_emsg }|.
      lo_http->close( ).
      RETURN.
    ENDIF.

    lo_http->response->get_status( IMPORTING code = lv_code reason = lv_reas ).
    lv_resp = lo_http->response->get_cdata( ).
    lo_http->close( ).

        IF lv_code < 200 OR lv_code >= 300.
      DATA(lv_body_len) = nmin( val1 = 300 val2 = strlen( lv_resp ) ).
      ev_message = |AI 호출 실패: HTTP { lv_code } { lv_reas } / { substring( val = lv_resp len = lv_body_len ) }|.
      RETURN.
    ENDIF.

    TRY.
        /ui2/cl_json=>deserialize(
          EXPORTING
            json        = lv_resp
            pretty_name = /ui2/cl_json=>pretty_mode-low_case
          CHANGING
            data        = ls_resp ).
      CATCH cx_root INTO DATA(lx).
        ev_message = lx->get_text( ).
        RETURN.
    ENDTRY.

    IF ls_resp-status <> 'completed'.
      ev_message = 'AI 응답이 정상 완료되지 않았습니다.'.
      RETURN.
    ENDIF.

    LOOP AT ls_resp-output INTO DATA(ls_out).
      LOOP AT ls_out-content INTO DATA(ls_oc).
        IF ls_oc-type = 'output_text' AND ls_oc-text IS NOT INITIAL.
          ev_text = ls_oc-text.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF ev_text IS NOT INITIAL.
        EXIT.
      ENDIF.
    ENDLOOP.

    IF ev_text IS INITIAL.
      ev_message = 'AI 응답에서 결과 텍스트를 찾지 못했습니다.'.
      RETURN.
    ENDIF.

    ev_success = abap_true.
    ev_message = 'AI 응답 수신 완료'.

  ENDMETHOD.
ENDCLASS.
