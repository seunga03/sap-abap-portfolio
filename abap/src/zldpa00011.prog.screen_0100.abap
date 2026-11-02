*&---------------------------------------------------------------------*
*& PROCESS BEFORE OUTPUT
*&---------------------------------------------------------------------*
PROCESS BEFORE OUTPUT.
*  MODULE clear_ok_code.
*  MODULE status_0100.
*  MODULE create_text_editor_0100.
*  MODULE set_text_editor_0100.
*  MODULE set_tab_0100.
*  CALL SUBSCREEN sub_preview INCLUDING sy-repid gv_dynnr.
  MODULE clear_ok_code.
  MODULE status_0100.
  MODULE set_source_screen_0100.
  CALL SUBSCREEN sub_source INCLUDING sy-repid gv_source_dynnr.
  MODULE set_tab_0100.
  CALL SUBSCREEN sub_preview INCLUDING sy-repid gv_dynnr.

*&---------------------------------------------------------------------*
*& PROCESS AFTER INPUT
*&---------------------------------------------------------------------*
PROCESS AFTER INPUT.
*  MODULE exit AT EXIT-COMMAND.
*  CALL SUBSCREEN sub_preview.
*  MODULE user_command_0100.
  MODULE exit AT EXIT-COMMAND.
  CALL SUBSCREEN sub_source.
  CALL SUBSCREEN sub_preview.
  MODULE user_command_0100.
