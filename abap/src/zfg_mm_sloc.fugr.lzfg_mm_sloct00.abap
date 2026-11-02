*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZVMMA00050......................................*
TABLES: ZVMMA00050, *ZVMMA00050. "view work areas
CONTROLS: TCTRL_ZVMMA00050
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_ZVMMA00050. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZVMMA00050.
* Table for entries selected to show on screen
DATA: BEGIN OF ZVMMA00050_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZVMMA00050.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVMMA00050_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZVMMA00050_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZVMMA00050.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVMMA00050_TOTAL.

*.........table declarations:.................................*
TABLES: ZTCMA00150                     .
