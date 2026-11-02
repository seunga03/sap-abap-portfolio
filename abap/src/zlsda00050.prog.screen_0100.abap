*&---------------------------------------------------------------------*
*& [화면 0100 Flow Logic]
*&---------------------------------------------------------------------*
PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  MODULE set_alv_0100.

PROCESS AFTER INPUT.
  MODULE exit_0100 AT EXIT-COMMAND.
  MODULE user_command_0100.

PROCESS ON VALUE-REQUEST.
  FIELD gv_s_kunfr MODULE f4_kunfr.
  FIELD gv_s_kunto MODULE f4_kunto.
