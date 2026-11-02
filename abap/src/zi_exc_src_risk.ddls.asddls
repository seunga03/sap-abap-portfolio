@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '납기 리스크 상세 (CM03 소스 섹션)'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_EXC_SRC_RISK as select from ztexa00040 as rk
    inner join   ZI_EXC_RISK_LATEST as lt
      on  lt.ebeln = rk.ebeln
      and lt.ebelp = rk.ebelp
      and lt.crdat = rk.crdat
    left outer join ztmma00050 as hd
      on  hd.ebeln = rk.ebeln
    left outer join ztcma00010 as vn
      on  vn.lifnr = hd.lifnr
    left outer join ztmma00060 as it
      on  it.ebeln = rk.ebeln
      and it.ebelp = rk.ebelp
{
  key rk.ebeln                          as ebeln,
  key rk.ebelp                          as ebelp,
      cast( 'RISK' as abap.char(4) )    as srtyp,
      rk.rknum                          as rknum,
      it.matnr                          as matnr,
      hd.lifnr                          as lifnr,
      vn.name1                          as name1,
      rk.pldat                          as pldat,
      rk.acdat                          as acdat,
      rk.dlday                          as dlday,
      rk.rkgrd                          as rkgrd,
      cast( case rk.rkgrd
              when 'NORM' then '정상'
              when 'WARN' then '주의'
              when 'CRIT' then '위험'
              else rk.rkgrd
            end as abap.char(6) )       as rkgrd_text
}
