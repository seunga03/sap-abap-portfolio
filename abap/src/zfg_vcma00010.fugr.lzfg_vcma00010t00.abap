*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZVCMA00010......................................*
TABLES: ZVCMA00010, *ZVCMA00010. "view work areas
CONTROLS: TCTRL_ZVCMA00010
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_ZVCMA00010. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZVCMA00010.
* Table for entries selected to show on screen
DATA: BEGIN OF ZVCMA00010_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZVCMA00010.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVCMA00010_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZVCMA00010_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZVCMA00010.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVCMA00010_TOTAL.

*.........table declarations:.................................*
TABLES: ZTCMA00080                     .
