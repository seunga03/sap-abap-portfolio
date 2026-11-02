@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception 소스 - 입고검사(QM)'
define view entity ZI_EXC_SRC_QM
  as select from ztmma00130 as it
    inner join   ztmma00120 as hd on hd.inspn = it.inspn
{
  key it.inspn                                   as inspn,
  key cast( it.inspp as abap.numc( 5 ) )         as inspp,
      cast( 'QM' as abap.char( 4 ) )             as srtyp,
      hd.mblnr                                   as mblnr,
      hd.mjahr                                   as mjahr,
      hd.insdt                                   as insdt,
      hd.insby                                   as insby,
      hd.statu                                   as statu,
      cast( case hd.statu
              when 'DONE' then '검사완료'
              when 'OPEN' then '검사대기'
              else hd.statu end as abap.char( 10 ) ) as statu_text,
      it.matnr                                   as matnr,
      @Semantics.quantity.unitOfMeasure: 'meins'
      it.insqt                                   as insqt,
      @Semantics.quantity.unitOfMeasure: 'meins'
      it.pasqt                                   as pasqt,
      @Semantics.quantity.unitOfMeasure: 'meins'
      it.faiqt                                   as faiqt,
      it.meins                                   as meins,
      it.reslt                                   as reslt,
      cast( case it.reslt
              when 'PASS' then '합격'
              when 'FAIL' then '불합격'
              when 'PEND' then '판정대기'
              else it.reslt end as abap.char( 10 ) ) as reslt_text,
      it.defcd                                   as defcd,
      cast( case it.defcd
              when 'NONE' then '없음'
              when 'SCRT' then '표면 스크래치'
              when 'FUNC' then '기능 불량'
              else it.defcd end as abap.char( 20 ) ) as defcd_text,
      it.deftx                                   as deftx
}
