*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZVCMA00160......................................*
TABLES: ZVCMA00160, *ZVCMA00160. "view work areas
CONTROLS: TCTRL_ZVCMA00160
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_ZVCMA00160. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZVCMA00160.
* Table for entries selected to show on screen
DATA: BEGIN OF ZVCMA00160_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZVCMA00160.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVCMA00160_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZVCMA00160_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZVCMA00160.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVCMA00160_TOTAL.

*.........table declarations:.................................*
TABLES: ZTCMA00160                     .
