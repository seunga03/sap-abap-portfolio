//@AccessControl.authorizationCheck: #NOT_REQUIRED
//@EndUserText.label: '바코드 입고 서비스'
//@Metadata.allowExtensions: true
//define root view entity ZC_MM_GR
//  as projection on ZI_MM_GR
//{
//  key Mblnr,
//  key Mjahr,
//  key Zeile,
//      Ebeln,
//      Ebelp,
//      Werks,
//      Lgort,
//      Matnr,
//      Menge,
//      Meins,
//      Bwart
//}

@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '바코드 입고 서비스'
@Metadata.allowExtensions: true

define root view entity ZC_MM_GR
  provider contract transactional_query
  as projection on ZI_MM_GR
{
  key Mblnr,
  key Mjahr,
  key Zeile,
      Ebeln,
      Ebelp,
      Werks,
      Lgort,
      Matnr,
      Menge,
      Meins,
      Bwart
}
