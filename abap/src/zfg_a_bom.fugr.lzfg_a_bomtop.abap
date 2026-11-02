FUNCTION-POOL zfg_a_bom.                    "MESSAGE-ID ..

* INCLUDE LZFG_A_BOMD...                     " Local class definition

TYPES: BEGIN OF ty_solt_key,
         matnr TYPE ztmma00070-matnr,
         werks TYPE ztmma00070-werks,
       END OF ty_solt_key,
       ty_t_solt_key TYPE SORTED TABLE OF ty_solt_key
         WITH UNIQUE KEY matnr werks.

TYPES: BEGIN OF ty_solt_vendor,
         matnr     TYPE ztcma00040-matnr,
         lifnr     TYPE ztcma00040-lifnr,
         meins     TYPE ztcma00040-meins,
         plifz     TYPE ztcma00040-plifz,
         priok     TYPE ztcma00040-priok,
         valfr     TYPE ztcma00040-valfr,
         eval_from TYPE ztmma00100-datab,
         vevno     TYPE ztmma00100-vevno,
         tscor     TYPE ztmma00100-tscor,
       END OF ty_solt_vendor,
       ty_t_solt_vendor TYPE STANDARD TABLE OF ty_solt_vendor
         WITH EMPTY KEY.
