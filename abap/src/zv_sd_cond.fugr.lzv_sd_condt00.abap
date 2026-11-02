*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZV_SD_COND......................................*
TABLES: ZV_SD_COND, *ZV_SD_COND. "view work areas
CONTROLS: TCTRL_ZV_SD_COND
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_ZV_SD_COND. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZV_SD_COND.
* Table for entries selected to show on screen
DATA: BEGIN OF ZV_SD_COND_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZV_SD_COND.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZV_SD_COND_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZV_SD_COND_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZV_SD_COND.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZV_SD_COND_TOTAL.

*.........table declarations:.................................*
TABLES: ZTCMA00060                     .
