@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception - Interface'
define root view entity ZI_EXCEPTION
  as select from ztexa00010
  composition [0..*] of ZI_EXCEPTION_HIST as _History 
  association [0..1] to ZI_EXC_SRC_RISK   as _Risk
    on  $projection.srtyp = 'RISK'
    and $projection.srnum = _Risk.ebeln
    and $projection.sritm = _Risk.ebelp
  association [0..1] to ZI_EXC_SRC_INVC   as _Invc
    on  $projection.srtyp = 'INVC'
    and $projection.srnum = _Invc.ivnum
    and $projection.sritm = _Invc.invit
  association [0..1] to ZI_EXC_SRC_QM as _Qm
    on  $projection.srtyp = 'QM'
    and $projection.srnum = _Qm.inspn
    and $projection.sritm = _Qm.inspp
  association [0..1] to ZI_EXC_SRC_SUBC   as _Subc
    on  $projection.srtyp = 'SUBC'
    and $projection.srnum = _Subc.cevno    
  association [0..*] to ZI_EXCEPTION_REQ  as _Request          // ★ 후속 요청
    on  $projection.exnum = _Request.exnum    
  association [0..1] to ZI_EXC_HOLD_FLAG as _HoldF
    on  $projection.exnum = _HoldF.exnum  
{
  key exnum,
      srtyp,
      srnum,
      sritm,
      owgrp,
      extyp,
      prsta,
      uname,
      crdat,
      ernam,
      erdat,
      erzet,
      aenam,
      aedat,
      aezet,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at,
      // ★ 경과일: 종료·반려 건은 0
      case prsta
        when 'CLSD' then 0
        when 'RJCT' then 0
        else dats_days_between( crdat, $session.system_date )
      end                                               as age_days,

      // ★ 경과일 색상: 7일↑ 빨강(1) / 3일↑ 노랑(2) / 그 외 초록(3) / 종료·반려 회색(0)
      // TODO(의논): 3일·7일 기준은 임시값
      case
        when prsta = 'CLSD' or prsta = 'RJCT'                     then 0
        when dats_days_between( crdat, $session.system_date ) >= 7 then 1
        when dats_days_between( crdat, $session.system_date ) >= 3 then 2
        else 3
      end                                               as age_crit,

      // ★ 상태 색상: 미처리 빨강 / 처리중·조치중 노랑 / 종료 초록 / 반려 회색
      case prsta
        when 'OPEN' then 1
        when 'PROG' then 2
        when 'ACTN' then 2
        when 'CLSD' then 3
        else 0
      end                                               as status_crit,
            // ★ 상태 텍스트 (TODO(A1): PRSTA 코드 확정 시 점검)
      cast( case prsta
              when 'OPEN' then '접수대기'
              when 'PROG' then '처리중'
              when 'ACTN' then '조치실행중'
              when 'CLSD' then '종료'
              when 'RJCT' then '반려'
              else prsta
            end as abap.char(12) )                       as prsta_text,
      cast( case srtyp
              when 'RISK' then '납기 리스크'
              when 'SUBC' then '외주 정합성'
              when 'QM'   then '품질 검사'
              when 'INVC' then '송장 정산'
              else srtyp
            end as abap.char(12) )                       as srtyp_text,

      cast( case extyp
              when 'PROC' then '조달'
              when 'QUAL' then '품질'
              when 'SETL' then '정산'
              else extyp
            end as abap.char(8) )                        as extyp_text,

      cast( case owgrp
              when 'MM'   then '자재(MM)'
              when 'FI'   then '재무(FI)'
              when 'BOTH' then '공동(MM+FI)'
              else owgrp
            end as abap.char(12) )                       as owgrp_text,            

      cast( case prsta
              when 'CLSD' then ' '
              when 'RJCT' then ' '
              else 'X'
            end as abap.char(1) )                       as is_open,
            
      cast( case prsta 
            when 'OPEN' then ' ' 
            else 'X' end
            as abap_boolean preserving type )                 as hide_start,      
      cast( case prsta when 'PROG' then ' ' else 'X' end
              as abap_boolean preserving type ) as hide_decide,
      cast( case prsta when 'ACTN' then ' ' else 'X' end
              as abap_boolean preserving type ) as hide_actn,
      cast( case when prsta = 'OPEN' or prsta = 'PROG' then ' ' else 'X' end
              as abap_boolean preserving type ) as hide_early,
      cast( case when prsta = 'OPEN' or prsta = 'PROG' or prsta = 'ACTN' then ' ' else 'X' end
              as abap_boolean preserving type ) as hide_reassign,     
              
      // ★ Hold 상태: NONE(없음) / ACTV(활성) / RLSD(해제됨)
      cast( case when _HoldF.act_cnt  > 0 then 'ACTV'
                 when _HoldF.hold_cnt > 0 then 'RLSD'
                 else 'NONE' end as abap.char(4) )          as hold_state,

      // ★ RISK 섹션 숨김 플래그: RISK 건이 아니면 'X'
      cast( case srtyp
              when 'RISK' then ' '
              else 'X'
            end as abap_boolean preserving type )                       as hide_risk,

      // ★ RISK 상세 8개 (ZI_EXC_SRC_RISK 기준)
      _Risk.matnr       as rk_matnr,
      _Risk.lifnr       as rk_lifnr,
      _Risk.name1       as rk_name1,
      _Risk.pldat       as rk_pldat,
      _Risk.acdat       as rk_acdat,
      _Risk.dlday       as rk_dlday,
      _Risk.rkgrd       as rk_rkgrd,
      _Risk.rkgrd_text  as rk_rkgrd_text,
     // ★ INVC 섹션 숨김 플래그
      cast( case srtyp
              when 'INVC' then ' '
              else 'X'
            end as abap_boolean preserving type )                       as hide_invc,

      // ★ INVC 상세 (ZI_EXC_SRC_INVC 기준)
      _Invc.lifnr       as iv_lifnr,
      _Invc.name1       as iv_name1,
      _Invc.ebeln       as iv_ebeln,
      _Invc.ebelp       as iv_ebelp,
      _Invc.matnr       as iv_matnr,
      @Semantics.quantity.unitOfMeasure: 'iv_meins'
      _Invc.menge       as iv_menge,
      _Invc.meins       as iv_meins,
      _Invc.waers       as iv_waers,
      @Semantics.amount.currencyCode: 'iv_waers'
      _Invc.netpr       as iv_netpr,
      @Semantics.amount.currencyCode: 'iv_waers'
      _Invc.wrbtr       as iv_wrbtr,
      @Semantics.amount.currencyCode: 'iv_waers'
      _Invc.po_netpr    as iv_ponetpr,
      @Semantics.amount.currencyCode: 'iv_waers'
      _Invc.diff_amt    as iv_diff,
      _Invc.mstat       as iv_mstat,
      _Invc.mstat_text  as iv_mstat_text,      
      _Invc.vdudt       as iv_vdudt,
      cast( case srtyp
              when 'QM' then ' '
              else 'X'
            end as abap_boolean preserving type )                       as hide_qm,

      // ★ QM 상세 (ZI_EXC_SRC_QM 기준)
      _Qm.mblnr         as qm_mblnr,
      _Qm.mjahr         as qm_mjahr,
      _Qm.insdt         as qm_insdt,
      _Qm.insby         as qm_insby,
      _Qm.statu         as qm_statu,
      _Qm.statu_text    as qm_statu_text,
      _Qm.matnr         as qm_matnr,
      @Semantics.quantity.unitOfMeasure: 'qm_meins'
      _Qm.insqt         as qm_insqt,
      @Semantics.quantity.unitOfMeasure: 'qm_meins'
      _Qm.pasqt         as qm_pasqt,
      @Semantics.quantity.unitOfMeasure: 'qm_meins'
      _Qm.faiqt         as qm_faiqt,
      _Qm.meins         as qm_meins,
      _Qm.reslt         as qm_reslt,
      _Qm.reslt_text    as qm_reslt_text,
      _Qm.defcd         as qm_defcd,
      _Qm.defcd_text    as qm_defcd_text,
      _Qm.deftx         as qm_deftx,
      
      // ★ SUBC 섹션 숨김 플래그
      cast( case srtyp
              when 'SUBC' then ' '
              else 'X'
            end as abap_boolean preserving type )                       as hide_subc,

      // ★ SUBC 상세 (ZI_EXC_SRC_SUBC 기준)
      _Subc.ebeln       as sc_ebeln,
      _Subc.ebelp       as sc_ebelp,
      _Subc.matnr       as sc_matnr,
      _Subc.lifnr       as sc_lifnr,
      _Subc.name1       as sc_name1,
      @Semantics.quantity.unitOfMeasure: 'sc_meins'
      _Subc.pliss       as sc_pliss,
      @Semantics.quantity.unitOfMeasure: 'sc_meins'
      _Subc.aciss       as sc_aciss,
      @Semantics.quantity.unitOfMeasure: 'sc_meins'
      _Subc.pluse       as sc_pluse,
      @Semantics.quantity.unitOfMeasure: 'sc_meins'
      _Subc.acuse       as sc_acuse,
      _Subc.meins       as sc_meins,
      @Semantics.quantity.unitOfMeasure: 'sc_meins'
      _Subc.diff_iss    as sc_diff_iss,
      @Semantics.quantity.unitOfMeasure: 'sc_meins'
      _Subc.diff_use    as sc_diff_use,
      _Subc.rcsts       as sc_rcsts,
      _Subc.rcsts_text  as sc_rcsts_text,
      _Subc.cfdat       as sc_cfdat,
      _Subc.cfusr       as sc_cfusr,
      _Subc.znote       as sc_znote,      
      
      _History,
      _Risk,
      _Invc,
      _Qm, 
      _Subc,
      _Request
}
