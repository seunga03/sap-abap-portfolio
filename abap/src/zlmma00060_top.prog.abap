*&---------------------------------------------------------------------*
*& Include ZLMMA00060_TOP                           - Report ZLMMA00060
*&---------------------------------------------------------------------*
REPORT zlmma00060 MESSAGE-ID ZMSGA.
TABLES: ztmma00100.
*TYPES: BEGIN OF ty_lifnr,
*         lifnr TYPE ztcma00010-lifnr,
*       END OF ty_lifnr.
**
*TYPES : ty_t_lifnr TYPE STANDARD TABLE OF ty_lifnr
*                  WITH EMPTY KEY.
TYPES: BEGIN OF ty_lifnr,
         lifnr TYPE ztcma00010-lifnr,
       END OF ty_lifnr,

       ty_t_lifnr TYPE STANDARD TABLE OF ty_lifnr WITH EMPTY KEY,

       ty_month TYPE n LENGTH 6,

       BEGIN OF ty_month_score,
         month  TYPE ty_month,
         weight TYPE decfloat34,
         score  TYPE decfloat34,
         count  TYPE i,
       END OF ty_month_score,

       ty_t_month_score TYPE HASHED TABLE OF ty_month_score
                          WITH UNIQUE KEY month.
DATA: gt_lifnr           TYPE ty_t_lifnr,
      gt_po_head         TYPE STANDARD TABLE OF ztmma00050 WITH EMPTY KEY,
      gt_po_item         TYPE STANDARD TABLE OF ztmma00060 WITH EMPTY KEY,
      gt_gr_item         TYPE STANDARD TABLE OF ztmma00090 WITH EMPTY KEY,
      gt_move_head       TYPE STANDARD TABLE OF ztmma00080 WITH EMPTY KEY,
      gt_integrity       TYPE STANDARD TABLE OF ztmma00110 WITH EMPTY KEY,
      gt_inspection_head TYPE STANDARD TABLE OF ztmma00120 WITH EMPTY KEY,
      gt_inspection_item TYPE STANDARD TABLE OF ztmma00130 WITH EMPTY KEY,
      gt_eval            TYPE STANDARD TABLE OF ztmma00100 WITH EMPTY KEY.

DATA: p_from LIKE sy-datum,
      p_to   LIKE sy-datum.
