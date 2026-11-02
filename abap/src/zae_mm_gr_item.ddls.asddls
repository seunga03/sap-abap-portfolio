@EndUserText.label: '바코드 입고 품목'
define abstract entity ZAE_MM_GR_ITEM
{
  key RequestId : abap.char( 32 );
  key ScanNo    : abap.numc( 6 );

  Ebeln : ebeln;
  Ebelp : ebelp;
  Werks : werks_d;
  Lgort : lgort_d;
  Matnr : matnr;

  @Semantics.quantity.unitOfMeasure: 'Meins'
  MengeI : menge_d;

  @Semantics.unitOfMeasure: true
  Meins : meins;

  Bwart : bwart;

  _Request : association to parent ZAE_MM_GR_REQUEST
    on $projection.RequestId = _Request.RequestId;
}
