@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 입고검사 상세'
define view entity ZI_MM_DASH_INSPECTION
  as select from ztmma00130 as item

    inner join ztmma00120 as head
      on head.inspn = item.inspn

    inner join ZI_MM_DASH_MOVEMENT as mov
      on  mov.mblnr = head.mblnr
      and mov.mjahr = head.mjahr
      and mov.zeile = item.gritm
      and mov.bwart = '101'
{
      @EndUserText.label: '입고검사번호'
  key item.inspn,

      @EndUserText.label: '검사 아이템번호'
  key item.inspp,

      head.mblnr,
      head.mjahr,

      @EndUserText.label: '참조 입고문서 품목'
      item.gritm,

      mov.budat,
      mov.ebeln,
      mov.ebelp,

      mov.werks,
      mov.wname,
      mov.lgort,
      mov.lgobe,

      item.matnr,
      mov.maktx,

      @EndUserText.label: '검사 확인일'
      head.insdt,

      @EndUserText.label: '검사 담당자'
      head.insby,


      @EndUserText.label: '검사수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      item.insqt,

      @EndUserText.label: '합격수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      item.pasqt,

      @EndUserText.label: '불량수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      item.faiqt,

      item.meins,



      @EndUserText.label: '불량유형'
      item.defcd,

      @EndUserText.label: '불량 상세내용'
      item.deftx,

      @EndUserText.label: '검사 비고'
      head.remrk
}
