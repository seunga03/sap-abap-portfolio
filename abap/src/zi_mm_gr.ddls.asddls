@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '바코드 입고 결과'
define root view entity ZI_MM_GR
  as select from ztmma00090 as GrItem
{
  key GrItem.mblnr as Mblnr,
  key GrItem.mjahr as Mjahr,
  key GrItem.zeile as Zeile,

      GrItem.ebeln as Ebeln,
      GrItem.ebelp as Ebelp,
      GrItem.werks as Werks,
      GrItem.lgort as Lgort,
      GrItem.matnr as Matnr,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      GrItem.menge as Menge,

      GrItem.meins as Meins,

      GrItem.bwart as Bwart
}
where GrItem.bwart = '101'
