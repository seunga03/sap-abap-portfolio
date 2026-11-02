**&---------------------------------------------------------------------*
**& Report ZEXDATA_A
**&---------------------------------------------------------------------*
**&
**&---------------------------------------------------------------------*
REPORT ZEXDATA_A.
*
*
*PARAMETERS:
*  p_mst TYPE abap_bool AS CHECKBOX DEFAULT abap_true,
*  p_trx TYPE abap_bool AS CHECKBOX DEFAULT abap_true.
*
*DATA:
*  gt_log   TYPE STANDARD TABLE OF string WITH EMPTY KEY,
*  gv_error TYPE abap_bool,
*  gv_user  TYPE syuname,
*  gv_date  TYPE datum,
*  gv_time  TYPE uzeit.
*
*DEFINE save_rows.
*  MODIFY &1 FROM TABLE &2.
*  IF sy-subrc = 0.
*    APPEND |&1: { lines( &2 ) }건 적재| TO gt_log.
*  ELSE.
*    gv_error = abap_true.
*    APPEND |&1: 적재 실패 (SY-SUBRC { sy-subrc })| TO gt_log.
*  ENDIF.
*END-OF-DEFINITION.
*
*START-OF-SELECTION.
*  gv_user = sy-uname.
*  gv_date = sy-datum.
*  gv_time = sy-uzeit.
*
*  IF p_mst = abap_true.
*    PERFORM seed_master_data.
*  ENDIF.
*
*  IF p_trx = abap_true.
*    PERFORM seed_mm_transaction_data.
*  ENDIF.
*
*  IF gv_error = abap_true.
*    ROLLBACK WORK.
*    MESSAGE '가라 데이터 적재 중 오류가 발생하여 저장하지 않았습니다.' TYPE 'E'.
*  ENDIF.
*
*  COMMIT WORK AND WAIT.
*  PERFORM display_log.
*
**&---------------------------------------------------------------------*
**& Form SEED_MASTER_DATA
**&---------------------------------------------------------------------*
*FORM seed_master_data.
*
*  DATA:
*    lt_vendor      TYPE STANDARD TABLE OF ztcma00010 WITH EMPTY KEY,
*    lt_material    TYPE STANDARD TABLE OF ztcma00020 WITH EMPTY KEY,
*    lt_mat_plant   TYPE STANDARD TABLE OF ztcma00030 WITH EMPTY KEY,
*    lt_mat_vendor  TYPE STANDARD TABLE OF ztcma00040 WITH EMPTY KEY,
*    lt_customer    TYPE STANDARD TABLE OF ztcma00050 WITH EMPTY KEY,
*    lt_mat_cust    TYPE STANDARD TABLE OF ztcma00060 WITH EMPTY KEY,
*    lt_code        TYPE STANDARD TABLE OF ztcma00080 WITH EMPTY KEY,
*    lt_bom_head    TYPE STANDARD TABLE OF ztcma00120 WITH EMPTY KEY,
*    lt_bom_item    TYPE STANDARD TABLE OF ztcma00130 WITH EMPTY KEY,
*    lt_plant       TYPE STANDARD TABLE OF ztcma00140 WITH EMPTY KEY,
*    lt_storage     TYPE STANDARD TABLE OF ztcma00150 WITH EMPTY KEY,
*    lt_workday     TYPE STANDARD TABLE OF ztcma00160 WITH EMPTY KEY,
*    lt_cust_plan   TYPE STANDARD TABLE OF ztcma00170 WITH EMPTY KEY,
*    lt_cust_event  TYPE STANDARD TABLE OF ztcma00180 WITH EMPTY KEY,
*    lt_bank        TYPE STANDARD TABLE OF ztfia00070 WITH EMPTY KEY,
*    lt_pay_term    TYPE STANDARD TABLE OF ztfia00080 WITH EMPTY KEY.
*
** 공급업체 Master : 5건
*  lt_vendor = VALUE #(
*    ( mandt = sy-mandt lifnr = 'V000000001'
*      name1 = '대성알루미늄' stcd1 = '110-81-00001' land1 = 'KR'
*      regio = '11' adrnr = '서울특별시 금천구 가산로 101'
*      telf1 = '02-555-1001' smtp_addr = 'sales1@example.com'
*      zterm = 'Z030' trdyn = 'Y'
*      ernam = gv_user erdat = gv_date erzet = gv_time
*      aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lifnr = 'V000000002'
*      name1 = '케이메탈' stcd1 = '110-81-00002' land1 = 'KR'
*      regio = '41' adrnr = '경기도 평택시 산단로 202'
*      telf1 = '031-555-1002' smtp_addr = 'sales2@example.com'
*      zterm = 'Z045' trdyn = 'Y'
*      ernam = gv_user erdat = gv_date erzet = gv_time
*      aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lifnr = 'V000000003'
*      name1 = '세종외주가공' stcd1 = '110-81-00003' land1 = 'KR'
*      regio = '44' adrnr = '충청남도 천안시 산업로 303'
*      telf1 = '041-555-1003' smtp_addr = 'subcon@example.com'
*      zterm = 'Z030' trdyn = 'Y'
*      ernam = gv_user erdat = gv_date erzet = gv_time
*      aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lifnr = 'V000000004'
*      name1 = '유니온전자부품' stcd1 = '110-81-00004' land1 = 'KR'
*      regio = '27' adrnr = '대구광역시 달성군 테크노로 404'
*      telf1 = '053-555-1004' smtp_addr = 'parts@example.com'
*      zterm = 'Z060' trdyn = 'Y'
*      ernam = gv_user erdat = gv_date erzet = gv_time
*      aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lifnr = 'V000000005'
*      name1 = '코어세라믹' stcd1 = '110-81-00005' land1 = 'KR'
*      regio = '48' adrnr = '부산광역시 강서구 녹산로 505'
*      telf1 = '051-555-1005' smtp_addr = 'ceramic@example.com'
*      zterm = 'Z015' trdyn = 'Y'
*      ernam = gv_user erdat = gv_date erzet = gv_time
*      aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00010 lt_vendor.
*
** 자재 Master : 10건
*  lt_material = VALUE #(
*    ( mandt = sy-mandt matnr = 'RM-AL-001'    maktx = '알루미늄 판재'      mtart = 'ROH'  meins = 'KG' mattx = '원자재' sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SUS-001'   maktx = '스테인리스 판재'    mtart = 'ROH'  meins = 'KG' mattx = '원자재' sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-CU-001'    maktx = '동선'              mtart = 'ROH'  meins = 'KG' mattx = '원자재' sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SI-001'    maktx = '실리콘 칩'         mtart = 'ROH'  meins = 'EA' mattx = '원자재' sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-RES-001'   maktx = '저항 모듈'         mtart = 'ROH'  meins = 'EA' mattx = '원자재' sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'SF-HOUS-001'  maktx = '펌프 하우징 반제품' mtart = 'HALB' meins = 'EA' mattx = '반제품'   sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'SF-ROTOR-001' maktx = '모터 로터 반제품'  mtart = 'HALB' meins = 'EA' mattx = '반제품'   sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-PUMP-001'  maktx = '산업용 펌프'       mtart = 'FERT' meins = 'EA' mattx = '완제품'   sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-MOTOR-001' maktx = 'BLDC 모터'         mtart = 'FERT' meins = 'EA' mattx = '완제품'   sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-CTRL-001'  maktx = '모터 제어기'       mtart = 'FERT' meins = 'EA' mattx = '완제품'   sLsyn = 'Y' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00020 lt_material.
*
** 플랜트 Master : 5건
*  lt_plant = VALUE #(
*    ( mandt = sy-mandt werks = 'P001' name1 = '인천 조달센터' adrnr = '인천광역시 남동구 산업로 1'  regio = '28' bukrs = 'C001' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt werks = 'P002' name1 = '이천 생산센터' adrnr = '경기도 이천시 반도체로 20'     regio = '41' bukrs = 'C001' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt werks = 'P003' name1 = '평택 품질센터' adrnr = '경기도 평택시 청북로 30'      regio = '41' bukrs = 'C001' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt werks = 'P004' name1 = '화성 가공센터' adrnr = '경기도 화성시 동탄산단로 40'    regio = '41' bukrs = 'C001' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt werks = 'P005' name1 = '부산 물류센터' adrnr = '부산광역시 강서구 물류로 50'    regio = '48' bukrs = 'C001' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00140 lt_plant.
*
** 창고 Master : 7건 (검사대기/외주지급 창고 포함)
*  lt_storage = VALUE #(
*    ( mandt = sy-mandt lgort = '0001' werks = 'P001' lgobe = '정상품 창고'  vstel = 'V001' land1 = 'KR' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lgort = '0002' werks = 'P001' lgobe = '검사대기 창고' vstel = 'V001' land1 = 'KR' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lgort = '0003' werks = 'P001' lgobe = '외주지급 창고' vstel = 'V001' land1 = 'KR' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lgort = '1001' werks = 'P002' lgobe = '반제품 창고'   vstel = 'V002' land1 = 'KR' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lgort = '2001' werks = 'P003' lgobe = '불량품 창고'   vstel = 'V003' land1 = 'KR' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lgort = '3001' werks = 'P004' lgobe = '가공품 창고'   vstel = 'V004' land1 = 'KR' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt lgort = '5001' werks = 'P005' lgobe = '출하대기 창고' vstel = 'V005' land1 = 'KR' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00150 lt_storage.
*
** 자재-플랜트 관리정보 : 10건
*  lt_mat_plant = VALUE #(
*    ( mandt = sy-mandt matnr = 'RM-AL-001'    werks = 'P001' beskz = 'F' eisbe = 100 plifz = 7  bstmi = 50 meins = 'KG' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SUS-001'   werks = 'P001' beskz = 'F' eisbe = 80  plifz = 10 bstmi = 30 meins = 'KG' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-CU-001'    werks = 'P001' beskz = 'F' eisbe = 50  plifz = 5  bstmi = 20 meins = 'KG' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SI-001'    werks = 'P001' beskz = 'F' eisbe = 100 plifz = 14 bstmi = 50 meins = 'EA' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-RES-001'   werks = 'P001' beskz = 'F' eisbe = 300 plifz = 7  bstmi = 100 meins = 'EA' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'SF-HOUS-001'  werks = 'P001' beskz = 'F' eisbe = 10  plifz = 12 bstmi = 5  meins = 'EA' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'SF-ROTOR-001' werks = 'P001' beskz = 'F' eisbe = 8   plifz = 12 bstmi = 4  meins = 'EA' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-PUMP-001'  werks = 'P002' beskz = 'E' eisbe = 5   plifz = 3  bstmi = 1  meins = 'EA' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-MOTOR-001' werks = 'P002' beskz = 'E' eisbe = 8   plifz = 3  bstmi = 1  meins = 'EA' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-CTRL-001'  werks = 'P002' beskz = 'F' eisbe = 10  plifz = 7  bstmi = 2  meins = 'EA' actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00030 lt_mat_plant.
*
** 자재-공급업체 거래조건 : 10건
*  lt_mat_vendor = VALUE #(
*    ( mandt = sy-mandt matnr = 'RM-AL-001'    lifnr = 'V000000001' valfr = '20260101' beskz = 'F' priok = '01' netpr = 12000  waers = 'KRW' plifz = 7  bstmi = 50  meins = 'KG' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SUS-001'   lifnr = 'V000000002' valfr = '20260101' beskz = 'F' priok = '01' netpr = 18000  waers = 'KRW' plifz = 10 bstmi = 30  meins = 'KG' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-CU-001'    lifnr = 'V000000001' valfr = '20260101' beskz = 'F' priok = '02' netpr = 25000  waers = 'KRW' plifz = 5  bstmi = 20  meins = 'KG' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SI-001'    lifnr = 'V000000004' valfr = '20260101' beskz = 'F' priok = '01' netpr = 85000  waers = 'KRW' plifz = 14 bstmi = 50  meins = 'EA' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-RES-001'   lifnr = 'V000000005' valfr = '20260101' beskz = 'F' priok = '01' netpr = 1500   waers = 'KRW' plifz = 7  bstmi = 100 meins = 'EA' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'SF-HOUS-001'  lifnr = 'V000000003' valfr = '20260101' beskz = 'F' priok = '01' netpr = 320000 waers = 'KRW' plifz = 12 bstmi = 5   meins = 'EA' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'SF-ROTOR-001' lifnr = 'V000000003' valfr = '20260101' beskz = 'F' priok = '01' netpr = 220000 waers = 'KRW' plifz = 12 bstmi = 4   meins = 'EA' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-CTRL-001'  lifnr = 'V000000004' valfr = '20260101' beskz = 'F' priok = '02' netpr = 450000 waers = 'KRW' plifz = 7  bstmi = 2   meins = 'EA' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-AL-001'    lifnr = 'V000000002' valfr = '20260101' beskz = 'F' priok = '02' netpr = 12500  waers = 'KRW' plifz = 9  bstmi = 50  meins = 'KG' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SI-001'    lifnr = 'V000000005' valfr = '20260101' beskz = 'F' priok = '02' netpr = 87000  waers = 'KRW' plifz = 10 bstmi = 50  meins = 'EA' valto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date erzet =
*gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00040 lt_mat_vendor.
*
** 고객 Master : 5건
*  lt_customer = VALUE #(
*    ( mandt = sy-mandt kunnr = 'C000000001' adrcde = 'C001' name1 = '떡잎반도체' land1 = 'KR' addr1 = '경기도 이천시 반도체로 100' telf1 = '031-555-2001' smail = 'buyer1@example.com' zterm = 'Z030' waers = 'KRW' trdyn = 'Y' blkyn = 'N' actyn = 'Y' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt kunnr = 'C000000002' adrcde = 'C002' name1 = '새싹전자'   land1 = 'KR' addr1 = '충청북도 청주시 산업로 200' telf1 = '043-555-2002' smail = 'buyer2@example.com' zterm = 'Z045' waers = 'KRW' trdyn = 'Y' blkyn = 'N' actyn = 'Y' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt kunnr = 'C000000003' adrcde = 'C003' name1 = '한빛모빌리티' land1 = 'KR' addr1 = '경기도 성남시 판교로 300'   telf1 = '031-555-2003' smail = 'buyer3@example.com' zterm = 'Z030' waers = 'KRW' trdyn = 'Y' blkyn = 'N' actyn = 'Y' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt kunnr = 'C000000004' adrcde = 'C004' name1 = '네오로보틱스' land1 = 'KR' addr1 = '대전광역시 유성구 테크노로 400' telf1 = '042-555-2004' smail = 'buyer4@example.com' zterm = 'Z060' waers = 'KRW' trdyn = 'Y' blkyn = 'N' actyn = 'Y' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt kunnr = 'C000000005' adrcde = 'C005' name1 = '코리아에너지' land1 = 'KR' addr1 = '부산광역시 해운대구 센텀로 500' telf1 = '051-555-2005' smail = 'buyer5@example.com' zterm = 'Z015' waers = 'KRW' trdyn = 'Y' blkyn = 'N' actyn = 'Y' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00050 lt_customer.
*
** 자재-고객 거래조건 : 5건
*  lt_mat_cust = VALUE #(
*    ( mandt = sy-mandt matnr = 'FG-PUMP-001'  kunnr = 'C000000001' vkorg = 'S001' vtweg = '10' unitp = 6500000 waers = 'KRW' disrt = 0 taxrt = 10 minlf = 1 meins = 'EA' vfrom = '20260101' vto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date
*erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-MOTOR-001' kunnr = 'C000000001' vkorg = 'S001' vtweg = '10' unitp = 1350000 waers = 'KRW' disrt = 0 taxrt = 10 minlf = 1 meins = 'EA' vfrom = '20260101' vto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date
*erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-CTRL-001'  kunnr = 'C000000002' vkorg = 'S001' vtweg = '10' unitp = 980000  waers = 'KRW' disrt = 3 taxrt = 10 minlf = 2 meins = 'EA' vfrom = '20260101' vto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date
*erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-PUMP-001'  kunnr = 'C000000003' vkorg = 'S001' vtweg = '10' unitp = 6400000 waers = 'KRW' disrt = 2 taxrt = 10 minlf = 3 meins = 'EA' vfrom = '20260101' vto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date
*erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-MOTOR-001' kunnr = 'C000000004' vkorg = 'S001' vtweg = '10' unitp = 1320000 waers = 'KRW' disrt = 5 taxrt = 10 minlf = 5 meins = 'EA' vfrom = '20260101' vto = '99991231' actyn = 'Y' ernam = gv_user erdat = gv_date
*erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00060 lt_mat_cust.
*
** 공통코드 : 구매유형, 문서상태, 검사/정합성 상태
*  lt_code = VALUE #(
*    ( mandt = sy-mandt  cdval = 'N'    cdnam = '일반구매' cdDsc = '일반 구매오더'               actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'L'    cdnam = '외주가공' cdDsc = '외주가공 구매오더'           actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'OPEN' cdnam = '진행중'   cdDsc = '후속 처리 전'                 actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'REL'  cdnam = '승인완료' cdDsc = '구매 처리 가능'                actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'GR'   cdnam = '입고중'   cdDsc = '부분 또는 전체 입고 진행'      actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'COMP' cdnam = '완료'     cdDsc = '후속 처리 완료'                actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'OPEN' cdnam = '검사대기' cdDsc = '입고검사 미처리'               actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'DONE' cdnam = '검사완료' cdDsc = '검사 결과 확정'                 actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'PASS' cdnam = '합격'     cdDsc = '입고검사 합격'                 actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'FAIL' cdnam = '불합격'   cdDsc = '입고검사 불합격'               actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'PEND' cdnam = '판정대기' cdDsc = '검사 수량만 등록된 상태'        actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'PASS' cdnam = '정합'     cdDsc = '지급량과 사용량이 일치'        actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = 'FAIL' cdnam = '차이발생' cdDsc = '지급량과 사용량이 불일치'      actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = '101'  cdnam = '입고'     cdDsc = '구매오더 기준 입고'            actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = '541'  cdnam = '외주지급' cdDsc = '외주처 지급 재고이동'          actyn = 'Y' valfr = '20260101' valto = '99991231' )
*    ( mandt = sy-mandt  cdval = '543'  cdnam = '외주소비' cdDsc = '외주처 실제 사용수량 반영'     actyn = 'Y' valfr = '20260101' valto = '99991231' ) ).
*  save_rows ztcma00080 lt_code.
*
** BOM Header : 5건
*  lt_bom_head = VALUE #(
*    ( mandt = sy-mandt stlnr = 'BOM0000001' matnr = 'FG-PUMP-001'  werks = 'P001' bmeng = 1 bmein = 'EA' stlst = 'Y' datuv = '20260101' valid_to = '99991231' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet =
*gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000002' matnr = 'FG-MOTOR-001' werks = 'P001' bmeng = 1 bmein = 'EA' stlst = 'Y' datuv = '20260101' valid_to = '99991231' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet =
*gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000003' matnr = 'FG-CTRL-001'  werks = 'P001' bmeng = 1 bmein = 'EA' stlst = 'Y' datuv = '20260101' valid_to = '99991231' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet =
*gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000004' matnr = 'SF-HOUS-001'  werks = 'P001' bmeng = 1 bmein = 'EA' stlst = 'Y' datuv = '20260101' valid_to = '99991231' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet =
*gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000005' matnr = 'SF-ROTOR-001' werks = 'P001' bmeng = 1 bmein = 'EA' stlst = 'Y' datuv = '20260101' valid_to = '99991231' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time
*) ).
*  save_rows ztcma00120 lt_bom_head.
*
** BOM Item : 11건
*  lt_bom_item = VALUE #(
*    ( mandt = sy-mandt stlnr = 'BOM0000001' stlkn = '0010' idnrk = 'RM-AL-001'  menge = 12  meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000001' stlkn = '0020' idnrk = 'RM-SUS-001' menge = 8   meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000002' stlkn = '0010' idnrk = 'RM-CU-001'  menge = 3   meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000002' stlkn = '0020' idnrk = 'RM-SI-001'  menge = 1   meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000003' stlkn = '0010' idnrk = 'RM-SI-001'  menge = 2   meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000003' stlkn = '0020' idnrk = 'RM-RES-001' menge = 10  meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000004' stlkn = '0010' idnrk = 'RM-AL-001'  menge = 12  meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000004' stlkn = '0020' idnrk = 'RM-SUS-001' menge = 8   meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000005' stlkn = '0010' idnrk = 'RM-CU-001'  menge = 3   meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000005' stlkn = '0020' idnrk = 'RM-SI-001'  menge = 1   meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt stlnr = 'BOM0000005' stlkn = '0030' idnrk = 'RM-RES-001' menge = '0.5' meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00130 lt_bom_item.
*
** 월별 영업일 기준 : 플랜트별 5건
*  lt_workday = VALUE #(
*    ( mandt = sy-mandt werks = 'P001' perio = '202610' wrkdy = 20 remark = '2026년 10월 영업일' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt werks = 'P002' perio = '202610' wrkdy = 20 remark = '2026년 10월 영업일' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt werks = 'P003' perio = '202610' wrkdy = 20 remark = '2026년 10월 영업일' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt werks = 'P004' perio = '202610' wrkdy = 20 remark = '2026년 10월 영업일' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt werks = 'P005' perio = '202610' wrkdy = 20 remark = '2026년 10월 영업일' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00160 lt_workday.
*
** 고객 생산계획 : 5건
*  lt_cust_plan = VALUE #(
*    ( mandt = sy-mandt plnno = 'PLAN000001' kunnr = 'C000000001' matnr = 'FG-PUMP-001'  perio = '202610' plan_qty = 20 meins = 'EA' change_rate = 5  source = 'MANUAL' collect_date = '20260920' raw_text = '10월 펌프 생산계획'  confirm_yn = 'Y' cuser = gv_user
*cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt plnno = 'PLAN000002' kunnr = 'C000000002' matnr = 'FG-MOTOR-001' perio = '202610' plan_qty = 30 meins = 'EA' change_rate = 3  source = 'MANUAL' collect_date = '20260920' raw_text = '10월 모터 생산계획'  confirm_yn = 'Y' cuser = gv_user
*cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt plnno = 'PLAN000003' kunnr = 'C000000003' matnr = 'FG-CTRL-001'  perio = '202610' plan_qty = 25 meins = 'EA' change_rate = 2  source = 'MANUAL' collect_date = '20260920' raw_text = '10월 제어기 생산계획' confirm_yn = 'Y' cuser = gv_user
*cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt plnno = 'PLAN000004' kunnr = 'C000000004' matnr = 'FG-PUMP-001'  perio = '202611' plan_qty = 15 meins = 'EA' change_rate = 0  source = 'MANUAL' collect_date = '20260920' raw_text = '11월 펌프 생산계획'  confirm_yn = 'Y' cuser = gv_user
*cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt plnno = 'PLAN000005' kunnr = 'C000000005' matnr = 'FG-MOTOR-001' perio = '202611' plan_qty = 18 meins = 'EA' change_rate = -2 source = 'MANUAL' collect_date = '20260920' raw_text = '11월 모터 생산계획'  confirm_yn = 'Y' cuser = gv_user
*cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00170 lt_cust_plan.
*
** 고객 Event : 5건
*  lt_cust_event = VALUE #(
*    ( mandt = sy-mandt evtno = 'EVENT00001' kunnr = 'C000000001' matnr = 'FG-PUMP-001'  event_type = 'PROM' valid_from = '20261001' valid_to = '20261031' event_text = '10월 판촉 행사'    impact_dir = 'UP' impact_rate = 10 source = 'MANUAL' collect_date =
*'20260920' confirm_yn = 'Y' cuser = gv_user cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt evtno = 'EVENT00002' kunnr = 'C000000002' matnr = 'FG-MOTOR-001' event_type = 'LNCH' valid_from = '20261010' valid_to = '20261031' event_text = '신제품 출시'      impact_dir = 'UP' impact_rate = 15 source = 'MANUAL' collect_date =
*'20260920' confirm_yn = 'Y' cuser = gv_user cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt evtno = 'EVENT00003' kunnr = 'C000000003' matnr = 'FG-CTRL-001'  event_type = 'DISC' valid_from = '20261001' valid_to = '20261015' event_text = '할인 판매'        impact_dir = 'UP' impact_rate = 5  source = 'MANUAL' collect_date =
*'20260920' confirm_yn = 'Y' cuser = gv_user cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt evtno = 'EVENT00004' kunnr = 'C000000004' matnr = 'FG-PUMP-001'  event_type = 'MNTN' valid_from = '20261020' valid_to = '20261025' event_text = '고객사 설비 정비'  impact_dir = 'DOWN' impact_rate = 20 source = 'MANUAL' collect_date =
*'20260920' confirm_yn = 'Y' cuser = gv_user cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt evtno = 'EVENT00005' kunnr = 'C000000005' matnr = 'FG-MOTOR-001' event_type = 'ETC'  valid_from = '20261101' valid_to = '20261130' event_text = '연말 수요 증가'    impact_dir = 'UP' impact_rate = 8  source = 'MANUAL' collect_date =
*'20260920' confirm_yn = 'Y' cuser = gv_user cdate = gv_date ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00180 lt_cust_event.
*
** 지급조건 Master : 5건
*  lt_pay_term = VALUE #(
*    ( mandt = sy-mandt zterm = 'Z000' zttxt = '즉시지급'     ztday = 0  actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt zterm = 'Z015' zttxt = '15일 후 지급' ztday = 15 actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt zterm = 'Z030' zttxt = '30일 후 지급' ztday = 30 actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt zterm = 'Z045' zttxt = '45일 후 지급' ztday = 45 actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt zterm = 'Z060' zttxt = '60일 후 지급' ztday = 60 actyn = 'Y' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztfia00080 lt_pay_term.
*
** 계좌 Master : 5건
*  lt_bank = VALUE #(
*    ( mandt = sy-mandt bnkac = 'BANK000001' banka = '신한은행' bankn = '110-000-000001' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt bnkac = 'BANK000002' banka = '국민은행' bankn = '123-456-789012' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt bnkac = 'BANK000003' banka = '우리은행' bankn = '100-200-300400' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt bnkac = 'BANK000004' banka = '하나은행' bankn = '555-666-777888' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt bnkac = 'BANK000005' banka = '농협은행' bankn = '301-0000-0000-01' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztfia00070 lt_bank.
*
*ENDFORM.
*
**&---------------------------------------------------------------------*
**& Form SEED_MM_TRANSACTION_DATA
**&---------------------------------------------------------------------*
*FORM seed_mm_transaction_data.
*
*  DATA:
*    lt_pr            TYPE STANDARD TABLE OF ztmma00040 WITH EMPTY KEY,
*    lt_po_head       TYPE STANDARD TABLE OF ztmma00050 WITH EMPTY KEY,
*    lt_po_item       TYPE STANDARD TABLE OF ztmma00060 WITH EMPTY KEY,
*    lt_stock         TYPE STANDARD TABLE OF ztmma00070 WITH EMPTY KEY,
*    lt_matdoc_head   TYPE STANDARD TABLE OF ztmma00080 WITH EMPTY KEY,
*    lt_matdoc_item   TYPE STANDARD TABLE OF ztmma00090 WITH EMPTY KEY,
*    lt_vendor_eval   TYPE STANDARD TABLE OF ztmma00100 WITH EMPTY KEY,
*    lt_subcon_check  TYPE STANDARD TABLE OF ztmma00110 WITH EMPTY KEY,
*    lt_qm_head       TYPE STANDARD TABLE OF ztmma00120 WITH EMPTY KEY,
*    lt_qm_item       TYPE STANDARD TABLE OF ztmma00130 WITH EMPTY KEY,
*    lt_leadtime      TYPE STANDARD TABLE OF ztmma00140 WITH EMPTY KEY,
*    lt_doc_flow      TYPE STANDARD TABLE OF ztcma00070 WITH EMPTY KEY,
*    lt_history       TYPE STANDARD TABLE OF ztcma00090 WITH EMPTY KEY,
*    lt_exception     TYPE STANDARD TABLE OF ztexa00010 WITH EMPTY KEY.
*
** PR : 일반 3건 + 외주 2건
*  lt_pr = VALUE #(
*    ( mandt = sy-mandt banfn = 'PR00000001' bnfpo = '00010' matnr = 'RM-AL-001'    werks = 'P001' lgort = '0001' prtyp = 'N' srtyp = 'FCST' srdoc = 'PLAN000001' sritm = '00010' ruser = gv_user rdate = '20260920' rqty = 100 meins = 'KG' ndate =
*'20261002' ptype = 'N' ekgrp = 'P01' astat = 'REL' auser = gv_user adate = '20260920' pstat = 'OPEN' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt banfn = 'PR00000002' bnfpo = '00010' matnr = 'RM-SUS-001'   werks = 'P001' lgort = '0001' prtyp = 'N' srtyp = 'FCST' srdoc = 'PLAN000001' sritm = '00020' ruser = gv_user rdate = '20260920' rqty = 50  meins = 'KG' ndate =
*'20260928' ptype = 'N' ekgrp = 'P01' astat = 'REL' auser = gv_user adate = '20260920' pstat = 'GR'   ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt banfn = 'PR00000003' bnfpo = '00010' matnr = 'SF-HOUS-001'  werks = 'P001' lgort = '0003' prtyp = 'N' srtyp = 'SO'   srdoc = 'SO00000001' sritm = '00010' ruser = gv_user rdate = '20260920' rqty = 10  meins = 'EA' ndate =
*'20261005' ptype = 'L' ekgrp = 'P01' astat = 'REL' auser = gv_user adate = '20260920' pstat = 'GR'   ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt banfn = 'PR00000004' bnfpo = '00010' matnr = 'FG-CTRL-001'  werks = 'P001' lgort = '0002' prtyp = 'N' srtyp = 'FCST' srdoc = 'PLAN000003' sritm = '00010' ruser = gv_user rdate = '20260920' rqty = 20  meins = 'EA' ndate =
*'20261008' ptype = 'N' ekgrp = 'P01' astat = 'REL' auser = gv_user adate = '20260920' pstat = 'GR'   ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt banfn = 'PR00000005' bnfpo = '00010' matnr = 'SF-ROTOR-001' werks = 'P001' lgort = '0003' prtyp = 'N' srtyp = 'SO'   srdoc = 'SO00000002' sritm = '00010' ruser = gv_user rdate = '20260920' rqty = 8   meins = 'EA' ndate =
*'20261012' ptype = 'L' ekgrp = 'P01' astat = 'REL' auser = gv_user adate = '20260920' pstat = 'GR'   ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00040 lt_pr.
*
** PO Header : 5건
*  lt_po_head = VALUE #(
*    ( mandt = sy-mandt ebeln = '4500000001' lifnr = 'V000000001' bedat = '20260920' bukrs = 'C001' ekorg = 'P001' ekgrp = 'P01' pstat = 'OPEN' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000002' lifnr = 'V000000002' bedat = '20260920' bukrs = 'C001' ekorg = 'P001' ekgrp = 'P01' pstat = 'GR'   ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000003' lifnr = 'V000000003' bedat = '20260920' bukrs = 'C001' ekorg = 'P001' ekgrp = 'P01' pstat = 'GR'   ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000004' lifnr = 'V000000004' bedat = '20260920' bukrs = 'C001' ekorg = 'P001' ekgrp = 'P01' pstat = 'GR'   ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000005' lifnr = 'V000000003' bedat = '20260920' bukrs = 'C001' ekorg = 'P001' ekgrp = 'P01' pstat = 'GR'   ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00050 lt_po_head.
*
** PO Item : 외주가공은 PTYPE = L
*  lt_po_item = VALUE #(
*    ( mandt = sy-mandt ebeln = '4500000001' ebelp = '00010' matnr = 'RM-AL-001'    werks = 'P001' lgort = '0002' menge = 100 meins = 'KG' netpr = 12000  waers = 'KRW' eindt = '20261002' banfn = 'PR00000001' bnfpo = '00010' ptype = 'N' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000002' ebelp = '00010' matnr = 'RM-SUS-001'   werks = 'P001' lgort = '0002' menge = 50  meins = 'KG' netpr = 18000  waers = 'KRW' eindt = '20260928' banfn = 'PR00000002' bnfpo = '00010' ptype = 'N' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000003' ebelp = '00010' matnr = 'SF-HOUS-001'  werks = 'P001' lgort = '0002' menge = 10  meins = 'EA' netpr = 320000 waers = 'KRW' eindt = '20261005' banfn = 'PR00000003' bnfpo = '00010' ptype = 'L' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000004' ebelp = '00010' matnr = 'FG-CTRL-001'  werks = 'P001' lgort = '0002' menge = 20  meins = 'EA' netpr = 450000 waers = 'KRW' eindt = '20261008' banfn = 'PR00000004' bnfpo = '00010' ptype = 'N' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000005' ebelp = '00010' matnr = 'SF-ROTOR-001' werks = 'P001' lgort = '0002' menge = 8   meins = 'EA' netpr = 220000 waers = 'KRW' eindt = '20261012' banfn = 'PR00000005' bnfpo = '00010' ptype = 'L' ernam = gv_user
*erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00060 lt_po_item.
*
** 재고 현황 : 정상/검사대기/외주지급 창고 모두 보이도록 구성
*  lt_stock = VALUE #(
*    ( mandt = sy-mandt matnr = 'RM-AL-001'    werks = 'P001' lgort = '0001' stqty = 600 rsqty = 100 qisty = 0  meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SUS-001'   werks = 'P001' lgort = '0001' stqty = 240 rsqty = 50  qisty = 0  meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-CU-001'    werks = 'P001' lgort = '0001' stqty = 150 rsqty = 24  qisty = 0  meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SI-001'    werks = 'P001' lgort = '0001' stqty = 100 rsqty = 8   qisty = 0  meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-RES-001'   werks = 'P001' lgort = '0001' stqty = 500 rsqty = 4   qisty = 0  meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'SF-HOUS-001'  werks = 'P001' lgort = '0002' stqty = 0   rsqty = 0   qisty = 6  meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'SF-ROTOR-001' werks = 'P001' lgort = '0002' stqty = 0   rsqty = 0   qisty = 4  meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-CTRL-001'  werks = 'P001' lgort = '0002' stqty = 0   rsqty = 0   qisty = 20 meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-AL-001'    werks = 'P001' lgort = '0003' stqty = 120 rsqty = 0   qisty = 0  meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SUS-001'   werks = 'P001' lgort = '0003' stqty = 80  rsqty = 0   qisty = 0  meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-CU-001'    werks = 'P001' lgort = '0003' stqty = 24  rsqty = 0   qisty = 0  meins = 'KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'RM-SI-001'    werks = 'P001' lgort = '0003' stqty = 8   rsqty = 0   qisty = 0  meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-PUMP-001'  werks = 'P002' lgort = '1001' stqty = 12  rsqty = 0   qisty = 0  meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt matnr = 'FG-MOTOR-001' werks = 'P002' lgort = '1001' stqty = 24  rsqty = 20  qisty = 0  meins = 'EA' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00070 lt_stock.
*
** 자재이동 Header : 9건
*  lt_matdoc_head = VALUE #(
*    ( mandt = sy-mandt mblnr = '5000000001' mjahr = '2026' bldat = '20260922' budat = '20260922' usnam = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000002' mjahr = '2026' bldat = '20260925' budat = '20260925' usnam = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000003' mjahr = '2026' bldat = '20260923' budat = '20260923' usnam = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000004' mjahr = '2026' bldat = '20260924' budat = '20260924' usnam = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000005' mjahr = '2026' bldat = '20260926' budat = '20260926' usnam = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000006' mjahr = '2026' bldat = '20260927' budat = '20260927' usnam = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000007' mjahr = '2026' bldat = '20260927' budat = '20260927' usnam = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000008' mjahr = '2026' bldat = '20260928' budat = '20260928' usnam = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000009' mjahr = '2026' bldat = '20260929' budat = '20260929' usnam = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00080 lt_matdoc_head.
*
** 자재이동 Item
** 101: 입고, 541: 외주지급, 543: 외주소비
*  lt_matdoc_item = VALUE #(
*    ( mandt = sy-mandt mblnr = '5000000001' mjahr = '2026' zeile = '0001' werks = 'P001' lgort = '0002' matnr = 'RM-AL-001'    ebeln = '4500000001' ebelp = '00010' menge = 100 meins = 'KG' bwart = '101' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000002' mjahr = '2026' zeile = '0001' werks = 'P001' lgort = '0002' matnr = 'RM-SUS-001'   ebeln = '4500000002' ebelp = '00010' menge = 50  meins = 'KG' bwart = '101' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000003' mjahr = '2026' zeile = '0001' werks = 'P001' lgort = '0003' matnr = 'RM-AL-001'    ebeln = '4500000003' ebelp = '00010' menge = 120 meins = 'KG' bwart = '541' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000003' mjahr = '2026' zeile = '0002' werks = 'P001' lgort = '0003' matnr = 'RM-SUS-001'   ebeln = '4500000003' ebelp = '00010' menge = 80  meins = 'KG' bwart = '541' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000004' mjahr = '2026' zeile = '0001' werks = 'P001' lgort = '0003' matnr = 'RM-AL-001'    ebeln = '4500000003' ebelp = '00010' menge = 115 meins = 'KG' bwart = '543' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000004' mjahr = '2026' zeile = '0002' werks = 'P001' lgort = '0003' matnr = 'RM-SUS-001'   ebeln = '4500000003' ebelp = '00010' menge = 80  meins = 'KG' bwart = '543' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000005' mjahr = '2026' zeile = '0001' werks = 'P001' lgort = '0002' matnr = 'SF-HOUS-001'  ebeln = '4500000003' ebelp = '00010' menge = 6   meins = 'EA' bwart = '101' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000006' mjahr = '2026' zeile = '0001' werks = 'P001' lgort = '0002' matnr = 'FG-CTRL-001'  ebeln = '4500000004' ebelp = '00010' menge = 20  meins = 'EA' bwart = '101' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000007' mjahr = '2026' zeile = '0001' werks = 'P001' lgort = '0003' matnr = 'RM-CU-001'    ebeln = '4500000005' ebelp = '00010' menge = 24  meins = 'KG' bwart = '541' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000007' mjahr = '2026' zeile = '0002' werks = 'P001' lgort = '0003' matnr = 'RM-SI-001'    ebeln = '4500000005' ebelp = '00010' menge = 8   meins = 'EA' bwart = '541' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000007' mjahr = '2026' zeile = '0003' werks = 'P001' lgort = '0003' matnr = 'RM-RES-001'   ebeln = '4500000005' ebelp = '00010' menge = 4   meins = 'EA' bwart = '541' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000008' mjahr = '2026' zeile = '0001' werks = 'P001' lgort = '0003' matnr = 'RM-CU-001'    ebeln = '4500000005' ebelp = '00010' menge = 24  meins = 'KG' bwart = '543' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000008' mjahr = '2026' zeile = '0002' werks = 'P001' lgort = '0003' matnr = 'RM-SI-001'    ebeln = '4500000005' ebelp = '00010' menge = 7   meins = 'EA' bwart = '543' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000008' mjahr = '2026' zeile = '0003' werks = 'P001' lgort = '0003' matnr = 'RM-RES-001'   ebeln = '4500000005' ebelp = '00010' menge = 4   meins = 'EA' bwart = '543' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt mblnr = '5000000009' mjahr = '2026' zeile = '0001' werks = 'P001' lgort = '0002' matnr = 'SF-ROTOR-001' ebeln = '4500000005' ebelp = '00010' menge = 4   meins = 'EA' bwart = '101' ernam = gv_user erdat = gv_date erzet = gv_time
*aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00090 lt_matdoc_item.
*
** 공급업체 평가 : 5건
*  lt_vendor_eval = VALUE #(
*    ( mandt = sy-mandt vevno = 'VEV0000001' datab = '20260101' dscor = 95 qscor = 96 pscor = 90 tscor = 94 grade = 'A' lifnr = 'V000000001' datbi = '99991231' uname = gv_user znote = '알루미늄 납기와 품질 우수' ernam = gv_user erdat = gv_date erzet = gv_time aenam
*= gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt vevno = 'VEV0000002' datab = '20260101' dscor = 88 qscor = 94 pscor = 88 tscor = 90 grade = 'A' lifnr = 'V000000002' datbi = '99991231' uname = gv_user znote = '스테인리스 납기 지연 1회' ernam = gv_user erdat = gv_date erzet = gv_time aenam
*= gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt vevno = 'VEV0000003' datab = '20260101' dscor = 85 qscor = 92 pscor = 90 tscor = 89 grade = 'B' lifnr = 'V000000003' datbi = '99991231' uname = gv_user znote = '외주 지급량 확인 필요' ernam = gv_user erdat = gv_date erzet = gv_time aenam =
*gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt vevno = 'VEV0000004' datab = '20260101' dscor = 97 qscor = 90 pscor = 88 tscor = 92 grade = 'A' lifnr = 'V000000004' datbi = '99991231' uname = gv_user znote = '제어기 납품 실적 양호' ernam = gv_user erdat = gv_date erzet = gv_time aenam =
*gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt vevno = 'VEV0000005' datab = '20260101' dscor = 82 qscor = 88 pscor = 95 tscor = 87 grade = 'B' lifnr = 'V000000005' datbi = '99991231' uname = gv_user znote = '가격 경쟁력 우수' ernam = gv_user erdat = gv_date erzet = gv_time aenam =
*gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00100 lt_vendor_eval.
*
** 외주자재 정합성 : 지급/사용량 일치와 불일치 모두 포함
*  lt_subcon_check = VALUE #(
*    ( mandt = sy-mandt cevno = 'CEV0000001' ebeln = '4500000003' ebelp = '00010' matnr = 'RM-AL-001'  werks = 'P001' lgort = '0003' pliss = 120 aciss = 120 pluse = 120 acuse = 115 meins = 'KG' rcsts = 'FAIL' cfdat = '20260926' cfusr = gv_user znote =
*'알루미늄 사용량 5KG 차이' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt cevno = 'CEV0000002' ebeln = '4500000003' ebelp = '00010' matnr = 'RM-SUS-001' werks = 'P001' lgort = '0003' pliss = 80  aciss = 80  pluse = 80  acuse = 80  meins = 'KG' rcsts = 'PASS' cfdat = '20260926' cfusr = gv_user znote =
*'스테인리스 사용량 일치' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt cevno = 'CEV0000003' ebeln = '4500000005' ebelp = '00010' matnr = 'RM-CU-001'  werks = 'P001' lgort = '0003' pliss = 24  aciss = 24  pluse = 24  acuse = 24  meins = 'KG' rcsts = 'PASS' cfdat = '20260929' cfusr = gv_user znote =
*'동선 사용량 일치' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt cevno = 'CEV0000004' ebeln = '4500000005' ebelp = '00010' matnr = 'RM-SI-001'  werks = 'P001' lgort = '0003' pliss = 8   aciss = 8   pluse = 8   acuse = 7   meins = 'EA' rcsts = 'FAIL' cfdat = '20260929' cfusr = gv_user znote =
*'실리콘 칩 사용량 1EA 차이' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt cevno = 'CEV0000005' ebeln = '4500000005' ebelp = '00010' matnr = 'RM-RES-001' werks = 'P001' lgort = '0003' pliss = 4   aciss = 4   pluse = 4   acuse = 4   meins = 'EA' rcsts = 'PASS' cfdat = '20260929' cfusr = gv_user znote =
*'저항 모듈 사용량 일치' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00110 lt_subcon_check.
*
** 입고검사 Header : 완료 4건 + 검사대기 1건
*  lt_qm_head = VALUE #(
*    ( mandt = sy-mandt inspn = 'INSP000001' mblnr = '5000000001' mjahr = '2026' insdt = '20260922' insby = gv_user statu = 'DONE' remrk = '알루미늄 판재 입고검사' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt inspn = 'INSP000002' mblnr = '5000000002' mjahr = '2026' insdt = '20260925' insby = gv_user statu = 'DONE' remrk = '스테인리스 판재 입고검사' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt inspn = 'INSP000003' mblnr = '5000000005' mjahr = '2026' insdt = '20260926' insby = gv_user statu = 'DONE' remrk = '외주 하우징 입고검사' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt inspn = 'INSP000004' mblnr = '5000000006' mjahr = '2026' insdt = '20260927' insby = gv_user statu = 'DONE' remrk = '제어기 입고검사' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt inspn = 'INSP000005' mblnr = '5000000009' mjahr = '2026' insdt = '20260929' insby = gv_user statu = 'OPEN' remrk = '외주 로터 검사대기' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00120 lt_qm_head.
*
** 입고검사 Item : PASS/FAIL/PEND 케이스
*  lt_qm_item = VALUE #(
*    ( mandt = sy-mandt inspn = 'INSP000001' inspp = '0010' gritm = '0001' matnr = 'RM-AL-001'    insqt = 100 pasqt = 98 faiqt = 2 meins = 'KG' reslt = 'FAIL' defcd = 'SCRT' deftx = '표면 스크래치 2KG' ernam = gv_user erdat = gv_date erzet = gv_time aenam =
*gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt inspn = 'INSP000002' inspp = '0010' gritm = '0001' matnr = 'RM-SUS-001'   insqt = 50  pasqt = 50 faiqt = 0 meins = 'KG' reslt = 'PASS' defcd = 'NONE' deftx = '이상 없음'        ernam = gv_user erdat = gv_date erzet = gv_time aenam =
*gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt inspn = 'INSP000003' inspp = '0010' gritm = '0001' matnr = 'SF-HOUS-001'  insqt = 6   pasqt = 6  faiqt = 0 meins = 'EA' reslt = 'PASS' defcd = 'NONE' deftx = '이상 없음'        ernam = gv_user erdat = gv_date erzet = gv_time aenam =
*gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt inspn = 'INSP000004' inspp = '0010' gritm = '0001' matnr = 'FG-CTRL-001'  insqt = 20  pasqt = 18 faiqt = 2 meins = 'EA' reslt = 'FAIL' defcd = 'FUNC' deftx = '기능 불량 2EA'      ernam = gv_user erdat = gv_date erzet = gv_time aenam =
*gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt inspn = 'INSP000005' inspp = '0010' gritm = '0001' matnr = 'SF-ROTOR-001' insqt = 4   pasqt = 0  faiqt = 0 meins = 'EA' reslt = 'PEND' defcd = 'NONE' deftx = '검사 결과 입력 대기' ernam = gv_user erdat = gv_date erzet = gv_time aenam =
*gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00130 lt_qm_item.
*
** Exception Header : 납기/품질/정산 예외
*  lt_exception = VALUE #(
*    ( mandt = sy-mandt exnum = 'EX00000001' srtyp = 'PO' srnum = '4500000002' sritm = '00010' owgrp = 'MM' extyp = 'PROC' prsta = 'OPEN' uname = gv_user crdat = '20260928' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date
*aezet = gv_time )
*    ( mandt = sy-mandt exnum = 'EX00000002' srtyp = 'PO' srnum = '4500000003' sritm = '00010' owgrp = 'QM' extyp = 'QUAL' prsta = 'OPEN' uname = gv_user crdat = '20260926' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date
*aezet = gv_time )
*    ( mandt = sy-mandt exnum = 'EX00000003' srtyp = 'PO' srnum = '4500000003' sritm = '00010' owgrp = 'MM' extyp = 'SETL' prsta = 'OPEN' uname = gv_user crdat = '20260926' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date
*aezet = gv_time )
*    ( mandt = sy-mandt exnum = 'EX00000004' srtyp = 'PO' srnum = '4500000004' sritm = '00010' owgrp = 'QM' extyp = 'QUAL' prsta = 'OPEN' uname = gv_user crdat = '20260927' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date
*aezet = gv_time )
*    ( mandt = sy-mandt exnum = 'EX00000005' srtyp = 'PO' srnum = '4500000005' sritm = '00010' owgrp = 'MM' extyp = 'SETL' prsta = 'OPEN' uname = gv_user crdat = '20260929' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date
*aezet = gv_time ) ).
*  save_rows ztexa00010 lt_exception.
*
** 납기 이력 : PO별 1건, EXNUM은 Exception Header와 연결
*  lt_leadtime = VALUE #(
*    ( mandt = sy-mandt ebeln = '4500000001' ebelp = '00010' etenr = '0001' exnum = ''           eindt = '20261002' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000002' ebelp = '00010' etenr = '0001' exnum = 'EX00000001' eindt = '20260928' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000003' ebelp = '00010' etenr = '0001' exnum = 'EX00000003' eindt = '20261005' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000004' ebelp = '00010' etenr = '0001' exnum = 'EX00000004' eindt = '20261008' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt ebeln = '4500000005' ebelp = '00010' etenr = '0001' exnum = 'EX00000005' eindt = '20261012' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztmma00140 lt_leadtime.
*
** Document Flow : PR -> PO -> GR
*  lt_doc_flow = VALUE #(
*    ( mandt = sy-mandt floid = 'FLOW000001' pdoct = 'PR' pdocn = 'PR00000001' pitem = '00010' ndoct = 'PO' ndocn = '4500000001' nitem = '00010' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt floid = 'FLOW000002' pdoct = 'PR' pdocn = 'PR00000002' pitem = '00010' ndoct = 'PO' ndocn = '4500000002' nitem = '00010' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt floid = 'FLOW000003' pdoct = 'PR' pdocn = 'PR00000003' pitem = '00010' ndoct = 'PO' ndocn = '4500000003' nitem = '00010' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt floid = 'FLOW000004' pdoct = 'PR' pdocn = 'PR00000004' pitem = '00010' ndoct = 'PO' ndocn = '4500000004' nitem = '00010' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt floid = 'FLOW000005' pdoct = 'PR' pdocn = 'PR00000005' pitem = '00010' ndoct = 'PO' ndocn = '4500000005' nitem = '00010' ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt floid = 'FLOW000006' pdoct = 'PO' pdocn = '4500000001' pitem = '00010' ndoct = 'GR' ndocn = '5000000001' nitem = '0001'  ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt floid = 'FLOW000007' pdoct = 'PO' pdocn = '4500000002' pitem = '00010' ndoct = 'GR' ndocn = '5000000002' nitem = '0001'  ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt floid = 'FLOW000008' pdoct = 'PO' pdocn = '4500000003' pitem = '00010' ndoct = 'GR' ndocn = '5000000005' nitem = '0001'  ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt floid = 'FLOW000009' pdoct = 'PO' pdocn = '4500000004' pitem = '00010' ndoct = 'GR' ndocn = '5000000006' nitem = '0001'  ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt floid = 'FLOW000010' pdoct = 'PO' pdocn = '4500000005' pitem = '00010' ndoct = 'GR' ndocn = '5000000009' nitem = '0001'  ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00070 lt_doc_flow.
*
** 거래처리 이력 : 발표 시 최근 문서 조회용
*  lt_history = VALUE #(
*    ( mandt = sy-mandt logno = 'LOG0000001' dctyp = 'PR' dcnum = 'PR00000001' prknd = 'CREA' uname = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt logno = 'LOG0000002' dctyp = 'PO' dcnum = '4500000001' prknd = 'CREA' uname = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt logno = 'LOG0000003' dctyp = 'GR' dcnum = '5000000001' prknd = 'POST' uname = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt logno = 'LOG0000004' dctyp = 'QM' dcnum = 'INSP000001' prknd = 'DONE' uname = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time )
*    ( mandt = sy-mandt logno = 'LOG0000005' dctyp = 'EXC' dcnum = 'EX00000003' prknd = 'OPEN' uname = gv_user ernam = gv_user erdat = gv_date erzet = gv_time aenam = gv_user aedat = gv_date aezet = gv_time ) ).
*  save_rows ztcma00090 lt_history.
*
*ENDFORM.
*
**&---------------------------------------------------------------------*
**& Form DISPLAY_LOG
**&---------------------------------------------------------------------*
*FORM display_log.
*  SKIP 1.
*  WRITE: / '가라 데이터 적재 완료'.
*  ULINE.
*
*  LOOP AT gt_log INTO DATA(lv_log).
*    WRITE: / lv_log.
*  ENDLOOP.
*ENDFORM.
