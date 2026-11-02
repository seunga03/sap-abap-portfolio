@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 자재이동'
define view entity ZI_MM_DASH_MOVEMENT
  as select from ztmma00090 as item

    inner join ztmma00080 as head
      on  head.mblnr = item.mblnr
      and head.mjahr = item.mjahr

    left outer join ztcma00020 as material
      on material.matnr = item.matnr

    left outer join ZI_MM_DASH_PLANT as plant
      on plant.werks = item.werks

    left outer join ZI_MM_DASH_STORAGE as storage
      on  storage.werks = item.werks
      and storage.lgort = item.lgort
{
      @EndUserText.label: '자재문서'
  key item.mblnr,

      @EndUserText.label: '자재문서 연도'
  key item.mjahr,

      @EndUserText.label: '자재문서 품목'
  key item.zeile,

      @EndUserText.label: '이동유형'
      item.bwart,

      @EndUserText.label: '증빙일'
      head.bldat,

      @EndUserText.label: '전기일'
      head.budat,

      @EndUserText.label: '플랜트'
      item.werks,

      @EndUserText.label: '플랜트명'
      plant.name1 as wname,

      @EndUserText.label: '창고'
      item.lgort,

      @EndUserText.label: '창고명'
      storage.lgobe,

      @EndUserText.label: '자재'
      item.matnr,

      @EndUserText.label: '자재명'
      material.maktx,

      @EndUserText.label: '이동수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      item.menge,

      @EndUserText.label: '단위'
      item.meins,

      @EndUserText.label: '구매오더'
      item.ebeln,

      @EndUserText.label: '구매오더 품목'
      item.ebelp,

      @EndUserText.label: '납품문서'
      item.vbeln,

      @EndUserText.label: '납품문서 품목'
      item.vbelp,

      @EndUserText.label: '판매문서'
      item.vbeln_so,

      @EndUserText.label: '판매문서 품목'
      item.posnr,

      @EndUserText.label: '처리 사용자'
      head.usnam
}
