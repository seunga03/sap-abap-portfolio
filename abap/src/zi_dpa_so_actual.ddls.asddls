@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '수요예측 정확도 분석용 실제 SO 실적'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_DPA_SO_ACTUAL
  as select from ztsda00010 as Header
    inner join   ztsda00020 as Item on Header.vbeln = Item.vbeln
{
  key Header.audat       as Audat,
  key Item.werks         as Werks,
  key Item.matnr         as Matnr,
  key Item.meins         as Meins,

      @Semantics.quantity.unitOfMeasure: 'Meins'
      sum( Item.kwmeng ) as ActualQty
}
where
  Header.sosta <> 'CN'
group by
  Header.audat,
  Item.werks,
  Item.matnr,
  Item.meins
