@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AI 수요예측 분석 기본 데이터'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_DPA_FORECAST
  as select from ztmma00010 as Header
    inner join   ztmma00020 as Item on Header.fcsno = Item.fcsno
{
      // Forecast 식별자
  key Header.fcsno  as Fcsno,
  key Item.iteno    as Iteno,

      // Forecast Header
      Header.werks  as Werks,
      Header.fcdat  as Fcdat,
      Header.tcdat  as Tcdat,
      Header.bsdat  as Bsdat,
      Header.hmons  as Hmons,
      Header.cstat  as Cstat,
      Header.activ  as Activ,
      Header.cuser  as Cuser,
      Header.cdate  as Cdate,
      Header.ctime  as Ctime,


      // Forecast Item
      Item.matnr    as Matnr,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Item.soqty    as Soqty,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Item.giqty    as Giqty,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Item.gapqty   as Gapqty,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Item.opqty    as Opqty,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Item.aiqty    as Aiqty,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Item.adqty    as Adqty,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      Item.fiqty    as Fiqty,

      Item.meins    as Meins,

      Item.rdate    as Rdate,
      Item.aistat   as Aistat,
      Item.aidat    as Aidat,
      Item.aitim    as Aitim,
      Item.aireason as Aireason

}
