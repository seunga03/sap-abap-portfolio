@EndUserText.label: 'SO상태 값 목록'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZV_SD_VH_STATUS
  as select distinct from ztsda00010
{
      @ObjectModel.text.element: [ 'StatusText' ]
      @EndUserText.label: 'SO상태'
  key cast( 'SO' as abap.char(4) )  as SoStatus,

      @Semantics.text: true
      @EndUserText.label: '설명'
      cast( '수주' as abap.char(10) ) as StatusText
}
union
  select distinct from ztsda00010
{
  key cast( 'DO' as abap.char(4) )  as SoStatus,
      cast( '납품' as abap.char(10) ) as StatusText
}
union
  select distinct from ztsda00010
{
  key cast( 'GI' as abap.char(4) )  as SoStatus,
      cast( '출고' as abap.char(10) ) as StatusText
}
union
  select distinct from ztsda00010
{
  key cast( 'BI' as abap.char(4) )  as SoStatus,
      cast( '청구' as abap.char(10) ) as StatusText
}
