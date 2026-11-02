@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 안전재고 미달'
define view entity ZI_MM_DASH_SHORTAGE
  as select from ztcma00030 as mp

    left outer join ZI_MM_DASH_STOCK_PLANT as stock
      on  stock.werks = mp.werks
      and stock.matnr = mp.matnr
      and stock.meins = mp.meins

    left outer join ZI_MM_DASH_PLANT as plant
      on plant.werks = mp.werks

    left outer join ztcma00020 as material
      on material.matnr = mp.matnr
{
  key mp.werks,
  key mp.matnr,

      plant.name1 as wname,
      material.maktx,
      material.mtart,

      @EndUserText.label: '안전재고'
      @Semantics.quantity.unitOfMeasure: 'meins'
      mp.eisbe as safetyqty,

      @EndUserText.label: '플랜트 가용재고'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( stock.stqty as abap.dec(13,3) ),
          0
        )
        as abap.quan(13,3)
      ) as stqty,

      @EndUserText.label: '부족수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        cast( mp.eisbe as abap.dec(13,3) )
        -
        coalesce(
          cast( stock.stqty as abap.dec(13,3) ),
          0
        )
        as abap.quan(13,3)
      ) as shortqty,

      @EndUserText.label: '부족률(%)'
      division(
        (
          cast( mp.eisbe as abap.dec(13,3) )
          -
          coalesce(
            cast( stock.stqty as abap.dec(13,3) ),
            0
          )
        ) * 100,
        case
          when mp.eisbe > 0
            then cast( mp.eisbe as abap.dec(13,3) )
          else cast( 1 as abap.dec(13,3) )
        end,
        2
      ) as shortpct,

      mp.meins
}
where
      mp.eisbe > 0
  and cast( mp.eisbe as abap.dec(13,3) )
      >
      coalesce(
        cast( stock.stqty as abap.dec(13,3) ),
        0
      )
