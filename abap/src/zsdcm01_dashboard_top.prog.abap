*&---------------------------------------------------------------------*
*& Include zsdcm01_dashboard_top
*&---------------------------------------------------------------------*


DATA: gt_data TYPE STANDARD TABLE OF zv_sd_dashboard,
      go_alv  TYPE REF TO cl_salv_table.

DATA: gs_data TYPE zv_sd_dashboard.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_vbeln FOR gs_data-SoNumber,
                  s_kunnr FOR gs_data-Customer.
SELECTION-SCREEN END OF BLOCK b1.
