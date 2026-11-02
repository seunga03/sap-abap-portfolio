@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 구매요청'
define view entity ZI_MM_DASH_PR
  as select from ztmma00040 as pr

    left outer join ztcma00020 as material
      on material.matnr = pr.matnr

    left outer join ZI_MM_DASH_PLANT as plant
      on plant.werks = pr.werks

    left outer join ZI_MM_DASH_STORAGE as storage
      on  storage.werks = pr.werks
      and storage.lgort = pr.lgort
{
  key pr.banfn,
  key pr.bnfpo,

      pr.matnr,
      material.maktx,

      pr.werks,
      plant.name1 as wname,

      pr.lgort,
      storage.lgobe,

      pr.prtyp,
      pr.srtyp,
      pr.srdoc,
      pr.sritm,

      @EndUserText.label: '요청자'
      pr.ruser,

      @EndUserText.label: '요청일'
      pr.rdate,

      @EndUserText.label: '요청수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      pr.rqty,

      pr.meins,

      @EndUserText.label: '필요일'
      pr.ndate,

      pr.ptype,
      pr.ekgrp,

      @EndUserText.label: '승인상태'
      pr.astat,

      @EndUserText.label: '승인자'
      pr.auser,

      @EndUserText.label: '승인일'
      pr.adate,

      @EndUserText.label: '진행상태'
      pr.pstat
}
