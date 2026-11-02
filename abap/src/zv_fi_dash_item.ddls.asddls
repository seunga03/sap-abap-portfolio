@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '채권·채무 대시보드 (Fiori용)'
// ZV_FI_OPEN_ITEM 에 오늘 날짜를 넘겨 파라미터 없는 뷰로 만듦 (OData 용)
// 연체 일수·만기 구간은 앱에서 고른 기준일로 다시 계산
define view entity ZV_FI_DASH_ITEM
  as select from ZV_FI_OPEN_ITEM( p_keydt: $session.system_date )
{
  key dtype,       // AP 채무 / AR 채권
  key docno,       // 채무·채권번호
      refno,       // 송장·청구번호
      partner,     // 공급업체·고객
      name1,       // 거래처명
      bldat,       // 증빙일
      duedt,       // 지급·수금기한
      clsta,       // 상태 코드
      waers,
      dmbtr,       // 금액
      clrbt,       // 반제누계 (지급·수금)
      adjbt,       // 조정누계
      openbal      // 잔액
}
