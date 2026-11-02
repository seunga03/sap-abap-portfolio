@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '외주 정합성 상세 (CM03 소스 섹션)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_EXC_SRC_SUBC
  as select from ztmma00110 as cv
    left outer join ztmma00050 as po
      on  po.ebeln = cv.ebeln
    left outer join ztcma00010 as vn
      on  vn.lifnr = po.lifnr
{
  key cv.cevno                          as cevno,
      cast( 'SUBC' as abap.char(4) )    as srtyp,
      cv.ebeln                          as ebeln,
      cv.ebelp                          as ebelp,
      cv.matnr                          as matnr,
      po.lifnr                          as lifnr,
      vn.name1                          as name1,
      @Semantics.quantity.unitOfMeasure: 'meins'
      cv.pliss                          as pliss,
      @Semantics.quantity.unitOfMeasure: 'meins'
      cv.aciss                          as aciss,
      @Semantics.quantity.unitOfMeasure: 'meins'
      cv.pluse                          as pluse,
      @Semantics.quantity.unitOfMeasure: 'meins'
      cv.acuse                          as acuse,
      cv.meins                          as meins,

      // ★ 지급 차이 = 실제 지급 - 예정 지급
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast( cast( cv.aciss as abap.dec(13,3) )
          - cast( cv.pliss as abap.dec(13,3) ) as abap.quan(13,3) )
                                        as diff_iss,
      // ★ 사용 차이 = 실제 사용 - 예정 사용
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast( cast( cv.acuse as abap.dec(13,3) )
          - cast( cv.pluse as abap.dec(13,3) ) as abap.quan(13,3) )
                                        as diff_use,

      cv.rcsts                          as rcsts,
      cast( case cv.rcsts
              when 'PASS' then '정합'
              when 'FAIL' then '불일치'
              else cv.rcsts
            end as abap.char(8) )       as rcsts_text,
      cv.cfdat                          as cfdat,
      cv.cfusr                          as cfusr,
      cv.znote                          as znote
}
