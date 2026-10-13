# 05 — Motor poliçesi sorgula (Inquire Motor Policy)

Şablon: [TEMPLATE.md](TEMPLATE.md)

| Alan | Değer |
|---|---|
| Operasyon | Motor poliçesi sorgula: müşteri numarası ve poliçe numarasıyla Db2 `POLICY` ve `MOTOR` tablolarının birleşiminden tek satır okunur. Poliçe türü COMMAREA'daki istek kodundan (`01IMOT`) anlaşılır. |
| Programlar (çağrı zinciri) | `LGIPOL01` (iş mantığı) → `EXEC CICS LINK` → `LGIPDB01` (Db2 `SELECT`). Hata yollarında ikisi de `LGSTSQ`'ya LINK eder. Zincir VSAM'a hiç dokunmaz. Programlar dört poliçe türüne de hizmet eder; yalnızca motor (`01IMOT`) kolu ve ortak kısımlar okundu. |
| Okunan COBOL dosyaları | `base/src/lgipol01.cbl`, `base/src/lgipdb01.cbl`, `base/src/lgstsq.cbl`, `base/src/lgcmarea.cpy`, `base/src/lgpolicy.cpy` |
| Test verisi kaynağı | `base/cntl/db2cre.jcl`: `POLICY` ve `MOTOR` tanımları (`:161-178`, `:275-290`), müşteri 2, 3, 5 ve 8 (`:471`, `:505`, `:573`, `:675`), poliçe 1, 3 ve 4 ile motor 1 ve 3'ün verisi (`:945-954`, `:969-978`, `:849-858`, `:1105-1114`, `:1128-1137`). COBOL kodu değil. |
| Kullanılan belgeler ([belge]) | `docs/adr/0004-legacy-test-harness.md` (yalnızca Kod gözlemleri 10), `docs/api-design.md` (yalnızca dönüş kodu ve istek kodu tablolarına bakıldı; hiçbir tahmin buna dayanmaz) |
| Hazırlayan | Oğuz (taslak: Claude Code) |
| Tarih | 2026-10-13 |
| Kaynak commit (`git rev-parse HEAD`) | `99e4be84f053e984f51652728e149f80f0a98920` |

## Kaynak etiketleri ve ön koşul kodları

Bu dosyadaki tahminler kaynak türüyle etiketlidir:

- **[kod]**: COBOL kaynağı, copybook, JCL ya da bunların yüklediği veri dosyası (dosya + satır).
- **[belge]**: `base/` altındaki ya da `docs/` altındaki açıklama metinleri.
- Etiketsiz kaynaklar [kod]'dur.

Ön koşul kodları test düzeneğinin vereceği kararlardır (kodlar `02-customer-inquire.md` ile aynıdır). Bir kodu taşıyan tahmin
**kesin değil, ön koşulludur**: ön koşul sağlanmazsa tahmin geçersizdir ve "Ön koşullu satırlar" tablosundaki son sütun geçerli olur.

| Kod | Ön koşul |
|---|---|
| B1 | Düzenek COMMAREA'yı her LINK'te, en dıştaki çağıranın 32500 baytlık tamponunun adresiyle geçirir. `EIBCALEN` yalnızca bildirilen uzunluktur. Tamponun `EIBCALEN` ötesi boşlukla doldurulur. COMMAREA dışına yapılan yazmalar bu tampona düşer ve çağıran onları görür. |
| B2 | SQLCA `SQLCODE = 0` ile başlar. |
| B3 | Derleyici sayısal taşımalarda PICTURE'ın hane sayısına göre keser (Enterprise COBOL'da `TRUNC(STD)`, GnuCOBOL'da kesme açık). Derleme seçeneklerinde `TRUNC` belirtilmemiş [kod] `cobol.jcl:44-50`. |
| B4 | Düzenek, satırda yazılan hata kodunu (SQLCODE / RESP) ya da veri durumunu (bir kaydın var ya da yok olması, bir sütunun NULL olması) kendisi kurar. |

(B5 ve B6 bu dosyada kullanılmıyor.)

## Kod gözlemleri

1. **COMMAREA bayt haritası, poliçe görünümü** (`lgcmarea.cpy:10-13`, `:34-44`, `:65-75`). Programlar bu düzeni kullanır
   (`lgipol01.cbl:62-63`, `lgipdb01.cbl:217-220`). Motor sorgusunda alanlar:

   | Bayt | Alan | PIC | Satır |
   |---|---|---|---|
   | 1-6 | `CA-REQUEST-ID` | X(6) | `lgcmarea.cpy:10` |
   | 7-8 | `CA-RETURN-CODE` | 9(2) | `:11` |
   | 9-18 | `CA-CUSTOMER-NUM` | 9(10) | `:12` |
   | 19-28 | `CA-POLICY-NUM` | 9(10) | `:35` |
   | 29-38 | `CA-ISSUE-DATE` | X(10) | `:38` |
   | 39-48 | `CA-EXPIRY-DATE` | X(10) | `:39` |
   | 49-74 | `CA-LASTCHANGED` | X(26) | `:40` |
   | 75-84 | `CA-BROKERID` | 9(10) | `:41` |
   | 85-94 | `CA-BROKERSREF` | X(10) | `:42` |
   | 95-100 | `CA-PAYMENT` | 9(6) | `:43` |
   | 101-115 | `CA-M-MAKE` | X(15) | `:66` |
   | 116-130 | `CA-M-MODEL` | X(15) | `:67` |
   | 131-136 | `CA-M-VALUE` | 9(6) | `:68` |
   | 137-143 | `CA-M-REGNUMBER` | X(7) | `:69` |
   | 144-151 | `CA-M-COLOUR` | X(8) | `:70` |
   | 152-155 | `CA-M-CC` | 9(4) | `:71` |
   | 156-165 | `CA-M-MANUFACTURED` | X(10) | `:72` |
   | 166-171 | `CA-M-PREMIUM` | 9(6) | `:73` |
   | 172-177 | `CA-M-ACCIDENTS` | 9(6) | `:74` |
   | 178-32500 | `CA-M-FILLER` | X(32323) | `:75` |

2. **Gerekli uzunluk 170, ama program 182. bayta kadar yazar.**
   - `WS-CA-HEADERTRAILER-LEN` = 33 (`lgipdb01.cbl:73`), `WS-REQUIRED-CA-LEN` önce 0 (`:74`). Motor için `WS-FULL-MOTOR-LEN` = 137 eklenir
     (`lgpolicy.cpy:26`): 33 + 137 = **170** (`lgipdb01.cbl:576-577`). Kontrol `lgipdb01.cbl:581-584`.
   - Veri 29-165. baytlara (ortak 72 bayt + `CA-MOTOR(1:65)`: `lgipdb01.cbl:601-602`), `CA-M-PREMIUM` ve `CA-M-ACCIDENTS`'e
     (166-177: `:598-599`) ve `'FINAL'` işaretine (`CA-M-FILLER(1:5)`, yani 178-182. baytlar: `:606`) yazılır. Son yazılan bayt 182'dir;
     gerekli uzunluk 170'tir. Aradaki 12 bayt `CA-M-PREMIUM` + `CA-M-ACCIDENTS` kadardır (6 + 6).
     Bu yüzden `EIBCALEN` 170 ile 181 arasındaysa kontrol geçer ama yazma COMMAREA'nın dışına taşar.
   - **LGIPOL01'de uzunluk kontrolü yoktur** ve LGIPDB01'i her zaman `Length(32500)` ile çağırır (`lgipol01.cbl:91-94`). LGIPDB01 her zaman
     `EIBCALEN = 32500` görür: kendi `EIBCALEN = 0` (`lgipdb01.cbl:251-255`) ve `98` (`:581-583`) kontrollerine LGIPOL01 üzerinden ulaşılamaz.
   - `98`, uzunluk kontrolünden önce `SELECT`'in başarılı olmasını ister (`lgipdb01.cbl:572`, `:581`): kayıt yoksa kısa COMMAREA'da da
     `01` döner.
3. **İstek kodu.** LGIPDB01 `CA-REQUEST-ID`'yi büyük harfe çevirip `WS-REQUEST-ID`'ye alır (`lgipdb01.cbl:275`); `CA-REQUEST-ID`'nin kendisi
   değişmez. `'01IMOT'` motor sorgusudur (`:287-289`); `WHEN OTHER` → `'99'` (`:307-308`) ve hemen `End-Program` (`RETURN`, `:312-313`).
   LGIPOL01 istek koduna bakmaz.
4. **Db2'den COMMAREA'ya aktarım** (`lgipdb01.cbl:243-245`, `:588-602`).
   - `INITIALIZE` ile `DB2-IN-INTEGERS`, `DB2-OUT-INTEGERS` ve `DB2-POLICY` sıfırlanır/boşaltılır; motor kolunda ayrıca `DB2-MOTOR`
     (`:288`).
   - `CA-POLICY-COMMON` ← `DB2-POLICY-COMMON` (tarihler, zaman damgası, `DB2-BROKERID`, `DB2-BROKERSREF`, `DB2-PAYMENT`: `lgpolicy.cpy:45-51`).
   - `CA-MOTOR(1:65)` ← `DB2-MOTOR` (77 bayt): ilk 65 bayt, yani marka … üretim tarihi, kopyalanır. `CA-M-PREMIUM` ve `CA-M-ACCIDENTS` ayrıca
     doldurulur (`:598-599`).
   - `CA-CUSTOMER-NUM`, `CA-POLICY-NUM` ve `CA-REQUEST-ID` yazılmaz; girdideki değerle kalır.
5. **NULL işleme.** `BROKERID` ve `PAYMENT` için gösterge (indicator) var (`lgipdb01.cbl:203-205`, `:551-553`). Gösterge `-1` ise (NULL) `DB2-BROKERID` ve
   `DB2-PAYMENT` doldurulmaz (`:588-593`); `INITIALIZE` ile sıfırlandıkları için (`:245`) COMMAREA'ya `0` gider. Diğer seçilen sütunlarda gösterge yok;
   kod yorumuna göre NULL gelirse `FETCH` `SQLCODE = -305` ile başarısız olur (`lgipdb01.cbl:200-202`). `MOTOR` tablosunda `policyNumber` dışında hiçbir
   sütun `NOT NULL` değildir (`db2cre.jcl:275-286`).
6. **Dönüş kodları.**

   | Kod | Nerede | Anlamı | Çağırana ulaşır mı |
   |---|---|---|---|
   | `00` | `lgipol01.cbl:86`, `lgipdb01.cbl:258` | Başlangıç / `SELECT` başarılı | Evet |
   | `01` | `lgipdb01.cbl:612` | `SQLCODE = 100` (kayıt yok) | Evet |
   | `90` | `lgipdb01.cbl:615` | Diğer SQLCODE'lar | Evet |
   | `98` | `lgipdb01.cbl:582` | `SELECT` başarılı ama COMMAREA < 170 | Yalnızca LGIPDB01 doğrudan çağrılırsa |
   | `99` | `lgipdb01.cbl:308` | İstek kodu tanınmıyor | Evet |
   | ABEND `LGCA` | `lgipol01.cbl:82`, `lgipdb01.cbl:254` | COMMAREA yok | — |

   (`88` ve `89` yalnızca ticari imleç kollarında: `lgipdb01.cbl:844`, `:856`; motor için geçerli değil.)
7. **Sonuca etki etmeyen noktalar.** Sorgulama hiçbir tabloyu değiştirmez. Zincir VSAM'a bakmaz (`lgipdb01.cbl`'de `LGSTSQ` dışında LINK yok).
   `FINAL` işareti yalnızca `SELECT` başarılıysa ve (LGIPDB01 doğrudan çağrılıyorsa) uzunluk yeterliyse yazılır; `98` ve `RETURN`'den önce
   yazılmaz (`lgipdb01.cbl:581-583`, `:606`).
8. **Hata mesajı içerikleri.**
   - `ERROR-MSG` uzunlukları: LGIPOL01 45 bayt (`lgipol01.cbl:41-46`), LGIPDB01 87 bayt (`lgipdb01.cbl:48-60`). `CA-ERROR-MSG` ikisinde de 99 bayttır:
     `'COMMAREA='` + 90 bayt.
   - LGIPDB01: `EM-SQLREQ` = `' SELECT MOTOR '` + 2 boşluk (`:531`). `EM-CUSNUM` ← `CA-CUSTOMER-NUM`, `EM-POLNUM` ← `CA-POLICY-NUM` (`:266-267`).
     `EM-SQLRC` `PIC +9(5)` (`:60`, `:999`).
   - LGIPDB01'in `EIBCALEN = 0` mesajı: 21 karakterlik `' NO COMMAREA RECEIVED'`, 63 baytlık `EM-VARIABLE` grubuna taşınır ve sabitleri ezer
     (`lgipdb01.cbl:53-60`, `:252`). Sonra `MOVE SQLCODE TO EM-SQLRC` son 6 baytı ezer (`:999`).
9. **`WRITE-ERROR-MESSAGE` dalları** (`IF EIBCALEN > 0` / `< 91` / `ELSE`).
   - LGIPOL01'de yalnızca `EIBCALEN = 0` dalından çağrılır (`lgipol01.cbl:81`); iç dallar (`lgipol01.cbl:124-138`) çalışmaz, ölü kod.
   - LGIPDB01 zincirden çağrıldığında `EIBCALEN = 32500` olduğu için `ELSE` dalı çalışır (`lgipdb01.cbl:1022-1027`). `< 91` dalına
     (`lgipdb01.cbl:1016-1021`) yalnızca LGIPDB01 doğrudan `EIBCALEN < 91` ile çağrılıp `90` yoluna düşülürse ulaşılır (05-15).
10. **WORKING-STORAGE kalıcılığı.** `WS-REQUIRED-CA-LEN` `VALUE +0` ve her başarılı `SELECT`'te üstüne eklenir (`lgipdb01.cbl:74`, `:576-577`).
    WORKING-STORAGE yeniden kurulmazsa ikinci çağrıda eşik 340 olur. Test düzeneği her durumu ayrı süreçte çalıştırır [belge]
    `docs/adr/0004-legacy-test-harness.md` (karar 4). Bu dosyadaki tahminler tek çağrı içindir.
11. **Test verisi** (`base/cntl/db2cre.jcl`). Bu değerler yalnızca test veritabanı bu JCL ile yüklendiyse ve sonradan değiştirilmediyse geçerlidir.
    - Motor poliçeleri: poliçe 1 (müşteri 2: `:945-946`), poliçe 3 (müşteri 5: `:969-970`), poliçe 2 (müşteri 10: `:993-994`). Poliçe 4 müşteri 8'e ait
      bir hayat sigortası (`policyType = E`, `:849-853`); `MOTOR`'da satırı yok.
    - `db2cre.jcl`'de `brokerId` 0, `brokersReference` boş (`CHAR(10)`: `:170`) ve `payment` 0 (`:951-953`).
    - Olmayan poliçe için `0000000999` kullanılır: JCL poliçe numaralarını 1-10 verir, kimlik değeri 1000001'den başlar (`:162-163`).

## Tahmin tablosu

| Test no | Girdi | Beklenen dönüş kodu | Beklenen veri | Tahminin dayandığı COBOL satırı | Kural türü |
|---|---|---|---|---|---|
| 05-01 | LGIPOL01 çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01IMOT'`. `CA-CUSTOMER-NUM = 0000000002`, `CA-POLICY-NUM = 0000000001` (poliçe 1, müşteri 2: `db2cre.jcl:945-946`). Db2 yalnızca `db2cre.jcl` ile yüklenmiş. | `CA-RETURN-CODE = 00` | Poliçe 1 ve motor 1'in bilgileri döner (alan alan aşağıdaki **"05-01 beklenen değerler"** tablosunda): ortak alanlar, `FORD` `KA` `LL60LOO`, değer 8500, prim 450, kaza 0. `CA-M-FILLER`'ın ilk 5 baytı (178-182. baytlar) `FINAL` olur. `CA-REQUEST-ID`, `CA-CUSTOMER-NUM`, `CA-POLICY-NUM` değişmez. Tarih ve zaman damgası alanlarının biçimi **belirsiz**. Hata mesajı yazılmaz. | `lgipol01.cbl:79`, `:86`, `:91-96`<br>`lgipdb01.cbl:258`, `:263-264`, `:275`, `:287-289`, `:529-570`, `:572`, `:576-581`, `:584-606` | İş kuralı |
| 05-02 | 05-01 ile aynı, ama poliçe 3 ve müşteri 5 (`db2cre.jcl:969-970`; motor 3: `:1128-1137`). Bu satır `prim` ve `kaza` alanlarının sıfırdan farklı değerlerle doğru eşlendiğini sınar. | `CA-RETURN-CODE = 00` | `CA-M-MAKE = DENNIS` + ␣×9, `CA-M-MODEL = ENGINE` + ␣×9, `CA-M-VALUE = 023500`, `CA-M-REGNUMBER = FIRE1` + ␣×2, `CA-M-COLOUR = RED` + ␣×5, `CA-M-CC = 5000`, `CA-M-MANUFACTURED` 13 Mayıs 1973 (biçim **belirsiz**), `CA-M-PREMIUM = 002850`, `CA-M-ACCIDENTS = 000012`. `CA-ISSUE-DATE` 8 Eylül 2011, `CA-EXPIRY-DATE` 7 Eylül 2012, `CA-LASTCHANGED` 8 Eylül 2011 13:14:45 (biçimler **belirsiz**). `CA-BROKERID = 0000000000`, `CA-BROKERSREF` ␣×10, `CA-PAYMENT = 000000`. `FINAL` işareti 178-182. baytlarda. | `lgipdb01.cbl:594-602`, `:606`<br>`db2cre.jcl:971-978`, `:1129-1137` | İş kuralı |
| 05-03 | LGIPOL01 çağrılır. `EIBCALEN = 32500`, `CA-REQUEST-ID = '01IMOT'`. `CA-CUSTOMER-NUM = 0000000002`, `CA-POLICY-NUM = 0000000999` (poliçe 999 yok). | `CA-RETURN-CODE = 01` | Alanlara dokunulmaz: `SELECT` satır bulmaz (`SQLCODE = 100`), `FINAL` yazılmaz. Hata mesajı yazılmaz (`100` dalında `WRITE-ERROR-MESSAGE` yok). | `lgipdb01.cbl:572`, `:608-612` | İş kuralı |
| 05-04 | 05-01 ile aynı, ama `CA-CUSTOMER-NUM = 0000000003` (poliçe 1 müşteri 2'ye ait, müşteri 3'e değil: `db2cre.jcl:946`). | `CA-RETURN-CODE = 01` | 05-03 ile aynı: `WHERE` koşulu müşteri numarasını da içerir, eşleşen satır yoktur. | `lgipdb01.cbl:564-569`, `:608-612` | İş kuralı |
| 05-05 | 05-01 ile aynı, ama `CA-CUSTOMER-NUM = 0000000008`, `CA-POLICY-NUM = 0000000004` (poliçe 4, müşteri 8'e ait bir hayat sigortası: `db2cre.jcl:849-853`; `MOTOR`'da satırı yok). | `CA-RETURN-CODE = 01` | 05-03 ile aynı: poliçe var ama `MOTOR` birleşiminde satır yok. İstek kodu motor olduğu için tür denetimi ayrıca yapılmaz; sonuç birleşimin boş çıkmasından gelir. | `lgipdb01.cbl:287-289`, `:563-569`, `:608-612` | İş kuralı |
| 05-06 | 05-01 ile aynı, ama [B4] `SELECT`'te 0 ve 100 dışında bir `SQLCODE` (örn. `-904`) üretilir. | `CA-RETURN-CODE = 90` | Alanlara dokunulmaz, `FINAL` yazılmaz.<br>Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG` (87 bayt): tarih, saat, `' LGIPDB01'`, `' CNUM='` + `0000000002`, `' PNUM='` + `0000000001`, `' SELECT MOTOR '` + 2 boşluk, `' SQLCODE='` + `-00904`. (2) `CA-ERROR-MSG`: `'COMMAREA='` + COMMAREA'nın ilk 90 baytı (`EIBCALEN = 32500`, `ELSE` dalı). | `lgipdb01.cbl:266-267`, `:531`, `:613-618`, `:999-1027` | İş kuralı |
| 05-07 | 05-01 ile aynı, ama `CA-REQUEST-ID = '01imot'` (küçük harf). | `CA-RETURN-CODE = 00` | 05-01 ile aynı dönüş. İstek kodu yalnızca karşılaştırma için büyük harfe çevrilir; dönüşte `CA-REQUEST-ID` girdideki gibi küçük harfle kalır. Ekleme (`04-03`) küçük harfi reddeder, sorgulama kabul eder. | `lgipdb01.cbl:275`, `:287-289` | Arayüz (COMMAREA) kuralı |
| 05-08 | LGIPOL01 çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01IXXX'` (tanınmayan kod; `'01AMOT'` gibi başka bir işlemin kodu da aynı yola girer). | `CA-RETURN-CODE = 99` | Hiçbir SQL çalıştırılmaz, alanlara dokunulmaz, hata mesajı yazılmaz. | `lgipdb01.cbl:277`, `:307-308`, `:312-313` | Arayüz (COMMAREA) kuralı |
| 05-09 | LGIPOL01 COMMAREA'sız çağrılır (`EIBCALEN = 0`). | Dönüş kodu yok. Görev `ABEND` kodu `LGCA` ile (NODUMP) sonlanır. | COMMAREA olmadığı için veri dönmez. LGIPDB01 çağrılmaz.<br>Yan etki: `LGSTSQ`'ya tek LINK yapılır: 45 baytlık `ERROR-MSG` (tarih, saat, `' LGIPOL01'`, `' NO COMMAREA RECEIVED'`). COMMAREA dökümü gönderilmez (`EIBCALEN > 0` sağlanmaz). | `lgipol01.cbl:79-83`, `:41-46`, `:107-124` | Arayüz (COMMAREA) kuralı |
| 05-10 | **LGIPDB01 doğrudan** COMMAREA'sız çağrılır (`EIBCALEN = 0`). [B2] `SQLCODE = 0`. | Dönüş kodu yok. Görev `ABEND` kodu `LGCA` ile (NODUMP) sonlanır. | SQL çalışmaz.<br>Yan etki: `LGSTSQ`'ya tek LINK yapılır: 87 baytlık `ERROR-MSG`. İçeriği: tarih, saat, `' LGIPDB01'`, `' NO COMMAREA RECEIVED'` + 36 boşluk + 6 baytlık `EM-SQLRC`. Taşıma 63 baytlık `EM-VARIABLE` grubunun tamamını ezdiği için `' CNUM='`, `' PNUM='`, `' SQLCODE='` sabitleri mesajda yer almaz. [B2] `EM-SQLRC = +00000` [kod] `lgipdb01.cbl:999`. COMMAREA dökümü gönderilmez.<br>LGIPOL01 üzerinden bu yola ulaşılamaz (Kod gözlemleri 2). | `lgipdb01.cbl:251-255`, `:53-60`, `:997-1015` | Arayüz (COMMAREA) kuralı |
| 05-11 | LGIPOL01 çağrılır. `EIBCALEN` 28 ile 169 arasında (örn. 100). Diğer girdiler 05-01 ile aynı; müşteri ve poliçe numaraları (9-28. baytlar) COMMAREA'nın içinde. | `CA-RETURN-CODE = 00`. `98` **dönmez**. | LGIPOL01 uzunluğa bakmaz ve LGIPDB01'i `Length(32500)` ile çağırır; LGIPDB01 `EIBCALEN = 32500` görür, uzunluk kontrolünü geçer. Veri 05-01'deki gibi yazılır. [B1] Yazmaların `EIBCALEN` ötesine düşen kısmı (en çok 182. bayta kadar) çağıranın tamponuna düşer ve çağıran bunları görür (ön koşullu) [kod] `lgipol01.cbl:91-94`. B1 sağlanmazsa COMMAREA dışına yazmanın etkisi belirsiz. | `lgipol01.cbl:91-94`<br>`lgipdb01.cbl:581-584`, `:598-606` | Arayüz (COMMAREA) kuralı |
| 05-12 | **LGIPDB01 doğrudan** çağrılır. `EIBCALEN` 28 ile 169 arasında (sınır değer: `169`). Diğer girdiler 05-01 ile aynı; kayıt Db2'de var. | `CA-RETURN-CODE = 98` | `SELECT` çalışır ve satır bulunur, ama alanlar COMMAREA'ya taşınmaz ve `FINAL` yazılmaz (`98` ve `RETURN`, taşımalardan önce). Hata mesajı yazılmaz. LGIPOL01 üzerinden bu yola ulaşılamaz. | `lgipdb01.cbl:572`, `:576-583`<br>`lgipdb01.cbl:73`, `lgpolicy.cpy:26` | Arayüz (COMMAREA) kuralı |
| 05-13 | **LGIPDB01 doğrudan** çağrılır. `EIBCALEN = 170` (kabul edilen en küçük uzunluk). Diğer girdiler 05-01 ile aynı; kayıt Db2'de var. | `CA-RETURN-CODE = 00` | Uzunluk kontrolü geçilir (`170 < 170` yanlış). `CA-M-PREMIUM`'un son baytı (171), `CA-M-ACCIDENTS` (172-177) ve `FINAL` işareti (178-182) COMMAREA'nın dışına yazılır (Kod gözlemleri 2). [B1] Bu yazmalar çağıranın tamponuna düşer: tamponda `CA-M-PREMIUM = 000450`, `CA-M-ACCIDENTS = 000000`, 178-182. baytlar `FINAL` olur (ön koşullu) [kod] `lgipdb01.cbl:598-599`, `:606`. B1 sağlanmazsa 171-182. baytlar belirsiz. | `lgipdb01.cbl:576-584`, `:598-599`, `:606`<br>`lgcmarea.cpy:73-75` | Arayüz (COMMAREA) kuralı |
| 05-14 | **LGIPDB01 doğrudan** çağrılır. `EIBCALEN` 28 ile 169 arasında (örn. 100). `CA-POLICY-NUM = 0000000999` (poliçe yok). | `CA-RETURN-CODE = 01` | `98` **dönmez**: uzunluk kontrolü yalnızca `SELECT` başarılı olunca yapılır. Alanlara dokunulmaz. | `lgipdb01.cbl:572`, `:581`, `:608-612` | Arayüz (COMMAREA) kuralı |
| 05-15 | **LGIPDB01 doğrudan** çağrılır. `EIBCALEN` 28 ile 90 arasında (örn. 50). [B4] `SELECT`'te 0 ve 100 dışında bir `SQLCODE` üretilir. | `CA-RETURN-CODE = 90` | Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG`: 05-06 ile aynı biçim. (2) `EIBCALEN < 91` dalı: `'COMMAREA='` + `DFHCOMMAREA(1:EIBCALEN)`, `CA-DATA`'nın kalanı boşluk. Bu dala yalnızca bu yolla ulaşılır. | `lgipdb01.cbl:613-618`, `:1015-1021` | Arayüz (COMMAREA) kuralı |
| 05-16 | 05-01 ile aynı, ama [B4] poliçe 1'in `brokerId` sütunu NULL. | `CA-RETURN-CODE = 00` | `CA-BROKERID = 0000000000`: gösterge `-1` olduğu için `DB2-BROKERID` doldurulmaz, `INITIALIZE` ile sıfırdır. Diğer alanlar 05-01 ile aynı. | `lgipdb01.cbl:245`, `:551`, `:588-590`, `:601` | İş kuralı |
| 05-17 | 05-01 ile aynı, ama [B4] poliçe 1'in `payment` sütunu NULL. | `CA-RETURN-CODE = 00` | `CA-PAYMENT = 000000`: gösterge `-1` olduğu için `DB2-PAYMENT` doldurulmaz. Diğer alanlar 05-01 ile aynı. | `lgipdb01.cbl:245`, `:553`, `:591-593`, `:601` | İş kuralı |
| 05-18 | 05-01 ile aynı, ama [B4] motor 1'in `make` sütunu NULL (göstergesi olmayan bir sütun). | **belirsiz** (kod yorumuna göre `90`) | Kod yorumu: gösterge olmayan sütunda NULL dönerse `FETCH` `SQLCODE = -305` ile başarısız olur [kod yorumu] `lgipdb01.cbl:200-202`. Öyleyse `SQLCODE` ne `0` ne `100` olur ve `90` yolu (05-06) çalışır. Db2'nin bu durumda gerçekte ne döndüreceği kodda tanımlı değil. | `lgipdb01.cbl:539`, `:554`, `:613-618`<br>[kod yorumu] `lgipdb01.cbl:200-202`<br>`db2cre.jcl:277` | İş kuralı |
| 05-19 | 05-01 ile aynı, ama `CA-CUSTOMER-NUM = 1000000002` (10 haneli). [B3] | [B3] `CA-RETURN-CODE = 00` (ön koşullu) [kod] `lgipdb01.cbl:572`. | [B3] `PIC 9(10)` → `PIC S9(9) COMP` taşımasında en soldaki hane kesilir ve `DB2-CUSTOMERNUM-INT = 2` olur: **müşteri 2'nin poliçe 1'i** sorgulanır. Dönen alanlar 05-01 ile aynıdır. `CA-CUSTOMER-NUM` girdideki gibi `1000000002` kalır.<br>B3 sağlanmazsa sonuç **belirsiz**. | `lgcmarea.cpy:12`<br>`lgipdb01.cbl:167`, `:263`<br>`cobol.jcl:44-50` | Arayüz (COMMAREA) kuralı |
| 05-20 | 05-01 ile aynı, ama `CA-POLICY-NUM` ya da `CA-CUSTOMER-NUM` sayısal değil (örn. boşluk). | **belirsiz** | **belirsiz**. İki programda da sayısallık kontrolü yok. Sayısal olmayan değer doğrudan `DB2-CUSTOMERNUM-INT`/`DB2-POLICYNUM-INT`'e taşınır. | `lgipdb01.cbl:263-264` | Arayüz (COMMAREA) kuralı |
| 05-21 | LGIPOL01 çağrılır. `EIBCALEN = 32500`. 05-01 ile aynı, ama LGIPDB01'e yapılan LINK başarısız olur (örn. program tanımlı değil). | **belirsiz** | **belirsiz**. LINK'te `RESP`/`NOHANDLE` yok, programda `HANDLE CONDITION` da yok. Sonuç CICS'in varsayılan davranışına bağlı ve kodda yazmıyor. | `lgipol01.cbl:91-94` | Arayüz (COMMAREA) kuralı |

## 05-01 beklenen değerler

Poliçe 1 (müşteri 2) için dönüşte COMMAREA'nın alan alan beklenen hali. "␣×n" sağdaki n adet boşluğu gösterir.

| COMMAREA alanı | Beklenen değer | Değerin kaynağı (`db2cre.jcl`) | Alanı dolduran COBOL satırı |
|---|---|---|---|
| `CA-REQUEST-ID` X(6) | Girdideki değer (`01IMOT`), değişmez | — | Kodda bu alana yazılmıyor |
| `CA-RETURN-CODE` 9(2) | `00` | — | `lgipdb01.cbl:258` |
| `CA-CUSTOMER-NUM` 9(10) | `0000000002` (girdi, değişmez) | `:946` | `lgipdb01.cbl:263` (yalnızca okunur) |
| `CA-POLICY-NUM` 9(10) | `0000000001` (girdi, değişmez) | `:945` | `lgipdb01.cbl:264` (yalnızca okunur) |
| `CA-ISSUE-DATE` X(10) | 11 Mayıs 2011. JCL'de `'2011-05-11'` olarak ekleniyor, ama dönen metnin biçimi **belirsiz** | `:947` (sütun `DATE`: `:165`) | `lgipdb01.cbl:534`, `:548`, `:601` |
| `CA-EXPIRY-DATE` X(10) | 10 Mayıs 2012. JCL'de `'2012-05-10'`; dönen biçim **belirsiz** | `:948` (sütun `DATE`: `:166`) | `lgipdb01.cbl:535`, `:549`, `:601` |
| `CA-LASTCHANGED` X(26) | 11 Mayıs 2011 17:12:17. JCL'de `'2011-05-11 17:12:17'`; dönen biçim **belirsiz** | `:950` (sütun `TIMESTAMP`: `:168`) | `lgipdb01.cbl:536`, `:550`, `:601` |
| `CA-BROKERID` 9(10) | `0000000000` | `:951` | `lgipdb01.cbl:536`, `:551`, `:588-590`, `:601` |
| `CA-BROKERSREF` X(10) | ␣×10 | `:952` (sütun `CHAR(10)`: `:170`) | `lgipdb01.cbl:537`, `:552`, `:601` |
| `CA-PAYMENT` 9(6) | `000000` | `:953` | `lgipdb01.cbl:538`, `:553`, `:591-593`, `:601` |
| `CA-M-MAKE` X(15) | `FORD` + ␣×11 | `:1106` (sütun `CHAR(15)`: `:277`) | `lgipdb01.cbl:539`, `:554`, `:602` |
| `CA-M-MODEL` X(15) | `KA` + ␣×13 | `:1107` (sütun `CHAR(15)`: `:278`) | `lgipdb01.cbl:540`, `:555`, `:602` |
| `CA-M-VALUE` 9(6) | `008500` | `:1108` | `lgipdb01.cbl:541`, `:556`, `:595`, `:602` |
| `CA-M-REGNUMBER` X(7) | `LL60LOO`. Karakterler L-L-6-0-L-O-O: 4. karakter sıfır rakamı, son ikisi O harfi | `:1109` (sütun `CHAR(7)`: `:280`) | `lgipdb01.cbl:542`, `:557`, `:602` |
| `CA-M-COLOUR` X(8) | `ORANGE` + ␣×2 | `:1110` (sütun `CHAR(8)`: `:281`) | `lgipdb01.cbl:543`, `:558`, `:602` |
| `CA-M-CC` 9(4) | `1000` | `:1111` | `lgipdb01.cbl:544`, `:559`, `:594`, `:602` |
| `CA-M-MANUFACTURED` X(10) | 19 Temmuz 1999. JCL'de `'1999-07-19'`; dönen biçim **belirsiz** | `:1112` (sütun `DATE`: `:283`) | `lgipdb01.cbl:545`, `:560`, `:602` |
| `CA-M-PREMIUM` 9(6) | `000450` | `:1113` | `lgipdb01.cbl:546`, `:561`, `:596`, `:598` |
| `CA-M-ACCIDENTS` 9(6) | `000000` | `:1114` | `lgipdb01.cbl:547`, `:562`, `:597`, `:599` |
| `CA-M-FILLER` X(32323) | İlk 5 bayt (178-182. baytlar) `FINAL`; gerisi girdideki gibi | — | `lgipdb01.cbl:606` |

## Kapsam tablosu

Koddaki her `IF`/`EVALUATE` dalının ve dönüş kodunun, onu kapsayan test numaraları.

| Envanter no | Madde | Test no | Not |
|---|---|---|---|
| IO-01 | `lgipol01.cbl:79-83` `IF EIBCALEN = 0` → ABEND `LGCA` | 05-09 | |
| IO-02 | `lgipol01.cbl:86` `'00'` → `CA-RETURN-CODE` | 05-01 | |
| IO-03 | `lgipol01.cbl:91-96` LINK LGIPDB01 `Length(32500)`, RETURN; uzunluk kontrolü yok | 05-01, 05-11, 05-21 | Kod gözlemleri 2 |
| IO-04 | `lgipol01.cbl:107-139` `WRITE-ERROR-MESSAGE` | 05-09 | Dış `IF EIBCALEN > 0` yanlış. İç dallar (`lgipol01.cbl:124-138`) ölü kod (Kod gözlemleri 9) |
| ID-01 | `lgipdb01.cbl:251-255` `IF EIBCALEN = 0` → ABEND `LGCA` | 05-10 | Yalnızca doğrudan çağrı |
| ID-02 | `lgipdb01.cbl:258` `'00'` | 05-01 | |
| ID-03 | `lgipdb01.cbl:263-267` `CA-CUSTOMER-NUM`, `CA-POLICY-NUM` → host değişkenleri, `EM-*` | 05-01, 05-06, 05-19, 05-20 | |
| ID-04 | `lgipdb01.cbl:275-310` `UPPER-CASE`, `EVALUATE WS-REQUEST-ID` | 05-01 (`WHEN '01IMOT'`), 05-07 (küçük harf), 05-08 (`WHEN OTHER` → `99`) | Motor dışı `WHEN` kolları kapsam dışı |
| ID-05 | `lgipdb01.cbl:529-570` `SELECT` (join, 3 koşul) | 05-01, 05-03, 05-04, 05-05 | |
| ID-06 | `lgipdb01.cbl:572` `IF SQLCODE = 0` | 05-01 (doğru dal), 05-03, 05-06 (yanlış dal) | |
| ID-07 | `lgipdb01.cbl:581-583` `IF EIBCALEN < 170` → `98` (doğru ve yanlış dal) | 05-12 (doğru dal); 05-01, 05-13 (yanlış dal) | Yalnızca doğrudan çağrı |
| ID-08 | `lgipdb01.cbl:588-590` `IF IND-BROKERID NOT EQUAL MINUS-ONE` | 05-01 (doğru dal), 05-16 (yanlış dal) | |
| ID-09 | `lgipdb01.cbl:591-593` `IF IND-PAYMENT NOT EQUAL MINUS-ONE` | 05-01 (doğru dal), 05-17 (yanlış dal) | |
| ID-10 | `lgipdb01.cbl:594-602` Db2 → COMMAREA taşımaları | 05-01, 05-02 | |
| ID-11 | `lgipdb01.cbl:606` `'FINAL'` işareti | 05-01, 05-02, 05-13 | |
| ID-12 | `lgipdb01.cbl:610-612` `IF SQLCODE EQUAL 100` → `01` | 05-03, 05-04, 05-05, 05-14 | |
| ID-13 | `lgipdb01.cbl:613-618` `ELSE` → `90` + hata mesajı | 05-06, 05-15, 05-18 | |
| ID-14 | `lgipdb01.cbl:997-1030` `WRITE-ERROR-MESSAGE` | 05-06 (`ELSE`), 05-15 (`< 91`), 05-10 (dış `IF` yanlış) | |
| SQ-01 | `lgstsq.cbl:68-71` LINK yolu | 05-06, 05-09, 05-10, 05-15 | |
| SQ-02 | `lgstsq.cbl:72-80` terminalden RECEIVE | — | **Kapsam dışı: bu zincirden ulaşılamaz.** LGSTSQ yalnızca LINK ile çağrılır. |
| SQ-03 | `lgstsq.cbl:94-111` WRITEQ TD `CSMT`, TS `GENAERRS` | 05-06 | |
| N-01 | `CA-REQUEST-ID` büyük/küçük harf duyarsız | 05-07 | |
| N-02 | Sayısallık ve aralık kontrolü yok | 05-19, 05-20 | |
| N-03 | LINK'te `RESP` yok | 05-21 | |
| N-04 | Göstergesiz sütunda NULL | 05-18 | Kod gözlemleri 5 |

## Ön koşullu satırlar

Ön koşul kodları dosyanın başında ("Kaynak etiketleri ve ön koşul kodları").

| Test no | Ön koşul | Ön koşulla tahmin | Ön koşul sağlanmazsa |
|---|---|---|---|
| 05-06 | B4 | Girdi düzenekle kurulur; tahmin (`90`) değişmez | Girdi kurulamaz |
| 05-10 | B2 | `EM-SQLRC = +00000` | `EM-SQLRC` belirsiz |
| 05-11 | B1 | COMMAREA dışına yazılan baytlar çağıranın tamponuna düşer | COMMAREA dışına yazmanın etkisi belirsiz |
| 05-13 | B1 | Tamponda `CA-M-PREMIUM = 000450`, `CA-M-ACCIDENTS = 000000`, 178-182. baytlar `FINAL` | 171-182. baytlar belirsiz |
| 05-15 | B4 | Girdi düzenekle kurulur; tahmin (`90`, `< 91` dalı) değişmez | Girdi kurulamaz |
| 05-16 | B4 | `brokerId` NULL satırı düzenekle kurulur; `CA-BROKERID = 0000000000` | Girdi kurulamaz: başlangıç verisinde NULL yok (`db2cre.jcl:951`) |
| 05-17 | B4 | `payment` NULL satırı düzenekle kurulur; `CA-PAYMENT = 000000` | Girdi kurulamaz: başlangıç verisinde NULL yok (`db2cre.jcl:953`) |
| 05-18 | B4 | `make` NULL satırı düzenekle kurulur | Girdi kurulamaz |
| 05-19 | B3 | Müşteri 2'nin poliçe 1'i sorgulanır: `00` ve 05-01'deki değerler | Dönüş kodu ve veri belirsiz |

## Belirsiz satırlar

| Test no | Belirsiz olan hücre | Neden belirsiz |
|---|---|---|
| 05-01 | Beklenen veri (yalnızca tarih ve zaman damgası biçimleri) | `issueDate`, `expiryDate`, `yearOfManufacture` sütunları `DATE`, `lastChanged` sütunu `TIMESTAMP` türünde (`db2cre.jcl:165-168`, `:283`) ve doğrudan `PIC X(10)`/`PIC X(26)` alanlara okunuyor (`lgipdb01.cbl:548-550`, `:560`). Okunurken hangi biçimde geleceği Db2 ayarına bağlı ve kodda yazmıyor. |
| 05-02 | Beklenen veri (yalnızca tarih ve zaman damgası biçimleri) | 05-01 ile aynı neden. |
| 05-18 | Dönüş kodu | Db2'nin göstergesiz sütunda NULL için `-305` döndüreceği yalnızca kod yorumunda yazıyor; gerçek Db2 davranışı kodda yok. |
| 05-20 | Dönüş kodu, beklenen veri | Sayısal olmayan veri sayısal alana taşınıyor ve hiçbir doğrulama yok. Sonuç tanımsız. |
| 05-21 | Dönüş kodu, beklenen veri | Kodda LINK hatası için işleme yok. Sonuç CICS'in varsayılan davranışı ve kodda tanımlı değil. |
