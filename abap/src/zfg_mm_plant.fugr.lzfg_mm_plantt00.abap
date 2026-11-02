*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZVMMA00040......................................*
TABLES: ZVMMA00040, *ZVMMA00040. "view work areas
CONTROLS: TCTRL_ZVMMA00040
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_ZVMMA00040. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZVMMA00040.
* Table for entries selected to show on screen
DATA: BEGIN OF ZVMMA00040_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZVMMA00040.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVMMA00040_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZVMMA00040_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZVMMA00040.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVMMA00040_TOTAL.

*.........table declarations:.................................*
TABLES: ZTCMA00140                     .
