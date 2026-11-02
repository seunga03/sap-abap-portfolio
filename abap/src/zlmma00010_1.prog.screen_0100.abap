PROCESS BEFORE OUTPUT.
  MODULE clear_ok_code.
  MODULE status_0100.
  MODULE display_kpi.
  MODULE set_tab_0100.


  CALL SUBSCREEN sub_main INCLUDING sy-repid gv_dynnr.

PROCESS AFTER INPUT.
  MODULE exit AT EXIT-COMMAND.
  CALL SUBSCREEN sub_main.
  MODULE user_command_0100.
