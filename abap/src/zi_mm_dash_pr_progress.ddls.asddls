@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '플랜트 대시보드 - 구매요청 진행'
define view entity ZI_MM_DASH_PR_PROGRESS
  as select from ZI_MM_DASH_PR as pr

    left outer join ZI_MM_DASH_PR_PO_SUM as po
      on  po.banfn = pr.banfn
      and po.bnfpo = pr.bnfpo
      and po.matnr = pr.matnr
      and po.meins = pr.meins
{
  key pr.banfn,
  key pr.bnfpo,

      pr.matnr,
      pr.maktx,
      pr.werks,
      pr.wname,
      pr.lgort,
      pr.lgobe,

      pr.prtyp,
      pr.srtyp,
      pr.srdoc,
      pr.sritm,
      pr.ruser,
      pr.rdate,
      pr.ndate,
      pr.ptype,
      pr.ekgrp,
      pr.astat,
      pr.auser,
      pr.adate,
      pr.pstat,
      @EndUserText.label: '승인상태 설명'
      case pr.astat
        when '0010' then '승인대기'
        when '0020' then '승인'
        else '미정의'
      end as astattext,

      @EndUserText.label: '진행상태 설명'
      case pr.pstat
        when '0010' then '요청등록'
        when '0020' then '승인대기'
        when '0030' then '승인완료'
        when '0040' then 'PO생성'
        when '0050' then '처리완료'
        when '0090' then '취소'
        else '미정의'
      end as pstattext,
      
            @EndUserText.label: '대시보드 진행상태'
      case
        when pr.pstat = '0090'
          then '취소'

        when pr.pstat = '0010'
         and pr.astat <> '0020'
          then '요청등록'

        when pr.astat <> '0020'
          then '승인대기'

        when coalesce( po.poitemcount, 0 ) = 0
          then '발주대기'

        when coalesce( po.poqty, 0 ) < pr.rqty
          then '일부발주'

        when coalesce( po.grqty, 0 ) = 0
          then '입고대기'

        when coalesce( po.grqty, 0 )
           < coalesce( po.poqty, 0 )
          then '일부입고'

        when coalesce( po.releasedqty, 0 )
           < coalesce( po.grqty, 0 )
          then '검사·재고전환중'

        else '재고전환완료'
      end as dashstatus,
      @EndUserText.label: '요청수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      pr.rqty,

      @EndUserText.label: '구매오더 품목 수'
      coalesce( po.poitemcount, 0 ) as poitemcount,

      @EndUserText.label: '발주수량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( po.poqty as abap.dec(13,3) ), 0
        )
        as abap.quan(13,3)
      ) as poqty,

      @EndUserText.label: '101 누적입고량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( po.grqty as abap.dec(13,3) ), 0
        )
        as abap.quan(13,3)
      ) as grqty,

      @EndUserText.label: '발주분 미입고량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( po.openqty as abap.dec(13,3) ), 0
        )
        as abap.quan(13,3)
      ) as openqty,

      @EndUserText.label: '검사수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( po.insqty as abap.dec(13,3) ), 0
        )
        as abap.quan(13,3)
      ) as insqty,

      @EndUserText.label: '합격수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( po.passqty as abap.dec(13,3) ), 0
        )
        as abap.quan(13,3)
      ) as passqty,

      @EndUserText.label: '불량수량 합계'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( po.failqty as abap.dec(13,3) ), 0
        )
        as abap.quan(13,3)
      ) as failqty,
      @EndUserText.label: '검사 후 재고전환량'
      @Semantics.quantity.unitOfMeasure: 'meins'
      cast(
        coalesce(
          cast( po.releasedqty as abap.dec(13,3) ),
          0
        )
        as abap.quan(13,3)
      ) as releasedqty,
      pr.meins
}
