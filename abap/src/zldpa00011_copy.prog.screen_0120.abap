*&---------------------------------------------------------------------*
*& PROCESS BEFORE OUTPUT
*&---------------------------------------------------------------------*
PROCESS BEFORE OUTPUT.
  MODULE create_event_toolbar.
  MODULE set_tc_event_lines.
  LOOP AT gt_event INTO gs_event WITH CONTROL tc_event.
  ENDLOOP.

*&---------------------------------------------------------------------*
*& PROCESS AFTER INPUT
*&---------------------------------------------------------------------*
PROCESS AFTER INPUT.
  LOOP AT gt_event.
      MODULE modify_event_data.
  ENDLOOP.

*&---------------------------------------------------------------------*
*& PROCESS ON VALUE-REQUEST
*&---------------------------------------------------------------------*
PROCESS ON VALUE-REQUEST.
  FIELD gs_event-matnr MODULE f4_event_matnr.
  FIELD gs_event-valid_from MODULE f4_event_valid_from.
  FIELD gs_event-valid_to MODULE f4_event_valid_to.
  FIELD gs_event-impact_dir MODULE f4_event_impact_dir.
  FIELD gs_event-event_type MODULE f4_event_type.
