@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception Control Tower'
@Metadata.allowExtensions: true
define root view entity ZC_EXCEPTION
  provider contract transactional_query
  as projection on ZI_EXCEPTION
{
  key exnum,
      
      srnum,
      sritm,
      @EndUserText.label: '발생출처'
      @ObjectModel.text.element: [ 'srtyp_text' ]
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_EXC_SRTYP_VH', element: 'Srtyp' } } ]
      srtyp,
      srtyp_text,

      @EndUserText.label: '담당그룹'
      @ObjectModel.text.element: [ 'owgrp_text' ]
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_EXC_OWGRP_VH', element: 'Owgrp' } } ]
      owgrp,
      owgrp_text,

      @EndUserText.label: '예외유형'
      @ObjectModel.text.element: [ 'extyp_text' ]
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_EXC_EXTYP_VH', element: 'Extyp' } } ]
      extyp,
      extyp_text,

      @EndUserText.label: '처리상태'
      @ObjectModel.text.element: [ 'prsta_text' ]
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_EXC_PRSTA_VH', element: 'Prsta' } } ]
      prsta,
      prsta_text,

      @EndUserText.label: '담당자'
      uname,
      crdat,
      age_days,
      age_crit,
      status_crit,
      @EndUserText.label: '미결만'
      @UI.selectionField: [ { position: 5 } ]
      @Consumption.filter.defaultValue: 'X'
      is_open, 
      hide_risk,
      hide_start,
      hide_decide,
      hide_actn,
      hide_early,
      hide_reassign,
      hold_state,
      @EndUserText.label: '자재'
      rk_matnr,
      @EndUserText.label: '공급업체'
      rk_lifnr,
      @EndUserText.label: '공급업체명'
      rk_name1,
      @EndUserText.label: '예정입고일'
      rk_pldat,
      @EndUserText.label: '실제입고일'
      rk_acdat,
      @EndUserText.label: '지연일수'
      rk_dlday,
      @EndUserText.label: '위험등급'
      @ObjectModel.text.element: [ 'rk_rkgrd_text' ]
      rk_rkgrd,
      rk_rkgrd_text,
      hide_invc,
      @EndUserText.label: '공급업체'
      iv_lifnr,
      @EndUserText.label: '공급업체명'
      iv_name1,
      @EndUserText.label: 'PO번호'
      iv_ebeln,
      @EndUserText.label: 'PO Item'
      iv_ebelp,
      @EndUserText.label: '자재'
      iv_matnr,
      @EndUserText.label: '송장 수량'
      iv_menge,
      iv_meins,
      iv_waers,
      @EndUserText.label: '단가'
      iv_netpr,
      @EndUserText.label: '송장 금액'
      iv_wrbtr,
      @EndUserText.label: 'PO 단가'
      iv_ponetpr,
      @EndUserText.label: '차이금액'
      iv_diff,      
      @EndUserText.label: '대사상태'
      @ObjectModel.text.element: [ 'iv_mstat_text' ]
      iv_mstat,
      iv_mstat_text,
      @EndUserText.label: '만기일'
      iv_vdudt,
      hide_qm,
      qm_mblnr,
      qm_mjahr,
      qm_insdt,
      qm_insby,
      @ObjectModel.text.element: [ 'qm_statu_text' ]
      qm_statu,
      qm_statu_text,
      qm_matnr,
      qm_insqt,
      qm_pasqt,
      qm_faiqt,
      qm_meins,
      @ObjectModel.text.element: [ 'qm_reslt_text' ]
      qm_reslt,
      qm_reslt_text,
      @ObjectModel.text.element: [ 'qm_defcd_text' ]
      qm_defcd,
      qm_defcd_text,
      qm_deftx, 
      hide_subc,
      sc_ebeln,
      sc_ebelp,
      sc_matnr,
      sc_lifnr,
      sc_name1,
      sc_pliss,
      sc_aciss,
      sc_pluse,
      sc_acuse,
      sc_meins,
      sc_diff_iss,
      sc_diff_use,
      @ObjectModel.text.element: [ 'sc_rcsts_text' ]
      sc_rcsts,
      sc_rcsts_text,
      sc_cfdat,
      sc_cfusr,
      sc_znote,           
      local_last_changed_at,
      last_changed_at,
      _History : redirected to composition child ZC_EXCEPTION_HIST,
      _Request
}
