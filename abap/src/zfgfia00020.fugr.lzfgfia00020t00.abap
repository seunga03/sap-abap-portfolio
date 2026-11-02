*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZVFIA00010......................................*
TABLES: ZVFIA00010, *ZVFIA00010. "view work areas
CONTROLS: TCTRL_ZVFIA00010
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_ZVFIA00010. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZVFIA00010.
* Table for entries selected to show on screen
DATA: BEGIN OF ZVFIA00010_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZVFIA00010.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVFIA00010_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZVFIA00010_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZVFIA00010.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVFIA00010_TOTAL.

*.........table declarations:.................................*
TABLES: ZTFIA00070                     .
