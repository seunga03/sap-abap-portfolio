*&---------------------------------------------------------------------*
*& PROCESS BEFORE OUTPUT
*&---------------------------------------------------------------------*
PROCESS BEFORE OUTPUT.
  MODULE create_plan_toolbar.
  MODULE set_tc_plan_lines.
  LOOP AT gt_plan INTO gs_plan WITH CONTROL tc_plan.
  ENDLOOP.

*&---------------------------------------------------------------------*
*& PROCESS AFTER INPUT
*&---------------------------------------------------------------------*
PROCESS AFTER INPUT.
  LOOP AT gt_plan.
    MODULE modify_plan_data.
  ENDLOOP.

*&---------------------------------------------------------------------*
*& PROCESS ON VALUE-REQUEST
*&---------------------------------------------------------------------*
PROCESS ON VALUE-REQUEST.
  FIELD gs_plan-matnr MODULE f4_plan_matnr.
  FIELD gs_plan-change_dir MODULE f4_plan_change_dir.
