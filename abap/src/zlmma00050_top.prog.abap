*&---------------------------------------------------------------------*
*& Include ZLMMA00010_TOP                           - Report ZLMMA00010
*&---------------------------------------------------------------------*

DATA : ok_code TYPE sy-ucomm.

DATA : go_con TYPE REF TO cl_gui_custom_container.
DATA : go_splitter TYPE REF TO cl_gui_splitter_container,
       go_top      TYPE REF TO cl_gui_container,
       go_bot      TYPE REF TO cl_gui_container.

DATA : go_alv_top TYPE REF TO cl_gui_alv_grid,
       go_alv_bot TYPE REF TO cl_gui_alv_grid.



DATA : gt_alv_top  TYPE TABLE OF zsmma00050,
       gt_alv_bot  TYPE TABLE OF zsmma00050,
       gt_fcat_top TYPE lvc_t_fcat,
       gt_fcat_bot TYPE lvc_t_fcat.

DATA : gs_layo_top TYPE lvc_s_layo,
       gs_layo_bot TYPE lvc_s_layo.

DATA : gt_cdval TYPE TABLE OF ztcma00080-cdval.


""""" 200 화면
DATA : go_note_con TYPE REF TO cl_gui_custom_container,
       go_textedit TYPE REF TO cl_gui_textedit.

DATA : gv_note_load TYPE abap_bool.
DATA : gt_note_text TYPE STANDARD TABLE OF char255 WITH EMPTY KEY.
DATA : gv_note_row TYPE lvc_index.

DATA gt_exclude_bot TYPE ui_functions.
