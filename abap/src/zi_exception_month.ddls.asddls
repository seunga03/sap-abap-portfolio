@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Exception - 발생월'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_EXCEPTION_MONTH
  as select from ZI_EXCEPTION as ex
  left outer join ZI_EXCEPTION_CLOSE as cl
    on cl.exnum = ex.exnum
{
  key ex.exnum,
      ex.owgrp,
      ex.extyp,
      ex.srtyp,
      ex.prsta,
      substring( ex.crdat, 1, 6 ) as crmon,     // YYYYMM

      case when cl.clts is not null
            and ( ex.prsta = 'CLSD' or ex.prsta = 'RJCT' )
            and ex.exnum not like 'EX8%'          // 시연용 가상 데이터 제외
           then 1 else 0 end                    as DoneFlag,

      case when cl.clts is not null
            and ( ex.prsta = 'CLSD' or ex.prsta = 'RJCT' )
            and ex.exnum not like 'EX8%'
           then dats_days_between( ex.crdat, cl.cldat )
           else 0 end                           as DoneDays
}
