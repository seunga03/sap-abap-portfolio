*&---------------------------------------------------------------------*
*& Include          ZLDPA00011_K01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Class LCL_TC_TOOLBAR_HANDLER Definition
*&---------------------------------------------------------------------*
CLASS lcl_tc_toolbar_handler DEFINITION.

  PUBLIC SECTION.

    METHODS on_function_selected
      FOR EVENT function_selected OF cl_gui_toolbar
      IMPORTING fcode.

ENDCLASS.

*&---------------------------------------------------------------------*
*& Class LCL_TC_TOOLBAR_HANDLER Implementation
*&---------------------------------------------------------------------*
CLASS lcl_tc_toolbar_handler IMPLEMENTATION.

  METHOD on_function_selected.

    CASE fcode.

      WHEN 'RADD' OR 'RDEL'.

        cl_gui_cfw=>set_new_ok_code(
          EXPORTING
            new_code = fcode
        ).

    ENDCASE.

  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* Event Handler Object
*----------------------------------------------------------------------*
DATA go_tc_toolbar_handler TYPE REF TO lcl_tc_toolbar_handler.
