# 04 — Motor poliçesi ekle (Add Motor Policy)

Şablon: [TEMPLATE.md](TEMPLATE.md)

| Alan | Değer |
|---|---|
| Operasyon | Motor poliçesi ekle: yeni poliçe Db2 `POLICY` ve `MOTOR` tablolarına, motor kaydının bir bölümü de VSAM `KSDSPOLY` dosyasına yazılır. Poliçe türü COMMAREA'daki istek kodundan (`01AMOT`) anlaşılır. |
| Programlar (çağrı zinciri) | `LGAPOL01` (iş mantığı) → `EXEC CICS LINK` → `LGAPDB01` (Db2 `POLICY` + `MOTOR` INSERT) → `LINK` → `LGAPVS01` (VSAM yazma). Hata yollarında üçü de `LGSTSQ`'ya LINK eder. Programlar dört poliçe türüne de hizmet eder; yalnızca motor (`01AMOT`) kolları ve ortak kısımlar okundu. |
| Okunan COBOL dosyaları | `base/src/lgapol01.cbl`, `base/src/lgapdb01.cbl`, `base/src/lgapvs01.cbl`, `base/src/lgstsq.cbl`, `base/src/lgcmarea.cpy`, `base/src/lgpolicy.cpy` |
| Test verisi kaynağı | `base/cntl/db2cre.jcl`: `POLICY` ve `MOTOR` tanımları (`:161-178`, `:275-290`), müşteri 2 (`:471`), poliçe 1 ve motor 1'in verisi (`:945-954`, `:1105-1114`). `base/cntl/adef121.jcl` ve `base/data/ksdspoly.txt`: `KSDSPOLY` tanımı ve başlangıç verisi. COBOL kodu değil. |
| Kullanılan belgeler ([belge]) | `base/Architecture.md` (yalnızca Kod gözlemleri 5; kodda doğrulanmadı), `docs/adr/0004-legacy-test-harness.md` (yalnızca Kod gözlemleri 12), `docs/api-design.md` (yalnızca dönüş kodu ve istek kodu tablolarına bakıldı; hiçbir tahmin buna dayanmaz) |
| Hazırlayan | Oğuz (taslak: Claude Code) |
| Tarih | 2026-10-13 |
| Kaynak commit (`git rev-parse HEAD`) | `99e4be84f053e984f51652728e149f80f0a98920` |

## Kaynak etiketleri ve ön koşul kodları

Bu dosyadaki tahminler kaynak türüyle etiketlidir:

- **[kod]**: COBOL kaynağı, copybook, JCL ya da bunların yüklediği veri dosyası (dosya + satır).
- **[belge]**: `base/` altındaki ya da `docs/` altındaki açıklama metinleri. Belgeye dayanan bir tahmin kodda doğrulanmamıştır.
- Etiketsiz kaynaklar [kod]'dur.

Ön koşul kodları test düzeneğinin vereceği kararlardır (kodlar `02-customer-inquire.md` ve `01-customer-add.md` ile aynıdır).
Bir kodu taşıyan tahmin **kesin değil, ön koşulludur**: ön koşul sağlanmazsa tahmin geçersizdir ve
"Ön koşullu satırlar" tablosundaki son sütun geçerli olur.

| Kod | Ön koşul |
|---|---|
| B1 | Düzenek COMMAREA'yı her LINK'te, en dıştaki çağıranın 32500 baytlık tamponunun adresiyle geçirir. `EIBCALEN` yalnızca bildirilen uzunluktur. Tamponun `EIBCALEN` ötesi boşlukla doldurulur. COMMAREA dışına yapılan yazmalar bu tampona düşer ve çağıran onları görür. |
| B2 | SQLCA `SQLCODE = 0` ile başlar. |
| B3 | Derleyici sayısal taşımalarda PICTURE'ın hane sayısına göre keser (Enterprise COBOL'da `TRUNC(STD)`, GnuCOBOL'da kesme açık). Derleme seçeneklerinde `TRUNC` belirtilmemiş [kod] `cobol.jcl:44-50`. |
| B4 | Düzenek, satırda yazılan hata kodunu (SQLCODE / RESP) ya da veri durumunu (bir kaydın var ya da yok olması) kendisi kurar. |
| B6 | Db2'de `POLICY` tablosuna `DEFAULT` ile daha önce hiç satır eklenmemiştir; ilk kimlik değeri `START WITH` değeridir (1000001: [kod] `db2cre.jcl:162-163`). Örnek poliçeler 1-10 numarasını açıkça verir (`db2cre.jcl:945`, `:969`, `:993` …), kimlik sayacını ilerletmez. |

(B5 bu dosyada kullanılmıyor.)

## Kod gözlemleri

1. **COMMAREA bayt haritası, poliçe görünümü** (`lgcmarea.cpy:10-13`, `:34-44`, `:65-75`). Üç program da bu düzeni kullanır
   (`lgapol01.cbl:70-71`, `lgapdb01.cbl:134-137`, `lgapvs01.cbl:86-87`). Motor isteği için alanlar:

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

2. **Uzunluk eşikleri iki programda farklıdır.**
   - LGAPOL01 yalnızca başlık uzunluğunu ister: `WS-CA-HEADER-LEN` = 28 (`lgapol01.cbl:59`), `WS-REQUIRED-CA-LEN` önce 0
   (`:60`), 28 eklenir (`:109`). Kontrol `lgapol01.cbl:113-116`. Eşik: 28.
   - LGAPDB01 28'e motor için `WS-FULL-MOTOR-LEN` = 137 ekler: toplam **165** (`lgapdb01.cbl:65-66`, `:182`, `:194-195`, `:210-213`;
   `lgpolicy.cpy:26`). 137 = 72 (ortak: `lgpolicy.cpy:18`) + 65 (motor: `lgpolicy.cpy:21`).
   - 165 bayt 1-165'i, yani `CA-M-MANUFACTURED`'ın sonuna kadar olan alanları kapsar (ortak alanlar 10+10+26+10+10+6 baytı: `lgcmarea.cpy:38-43`;
     motor alanları 15+15+6+7+8+4+10 baytı: `:66-72`). `CA-M-PREMIUM` (166-171) ve `CA-M-ACCIDENTS` (172-177) bu kontrolün dışında
     kalır. İkisi de INSERT-MOTOR'da okunur (`lgapdb01.cbl:445-446`).
3. **LGAPOL01, LGAPDB01'i her zaman `LENGTH(32500)` ile çağırır** (`lgapol01.cbl:121-124`). LGAPDB01 her zaman `EIBCALEN = 32500` görür.
   Bu yüzden LGAPDB01'in kendi "COMMAREA yok" (`lgapdb01.cbl:165-169`) ve "COMMAREA kısa / 165" (`:210-213`) kontrollerine LGAPOL01
   üzerinden ulaşılamaz. Yalnızca LGAPDB01 doğrudan çağrılınca çalışırlar. LGAPOL01'i 28 bayt ile geçen bir istek, LGAPDB01'e 165'ten
   kısa ama "32500 baytlık" görünerek girer.
4. **Poliçe türü istek kodundan anlaşılır.** LGAPDB01 `CA-REQUEST-ID`'yi iki kez `EVALUATE` eder (`lgapdb01.cbl:184-207`, `:223-241`).
   `'01AMOT'` → `DB2-POLICYTYPE = 'M'` (`:194-196`). Karşılaştırma büyük/küçük harfe duyarlıdır: `UPPER-CASE` yok (sorgulamada ve silmede var).
   LGAPOL01 istek koduna hiç bakmaz. İkinci `WHEN OTHER` (`lgapdb01.cbl:237-240`) ölü koddur: tanınmayan kod daha önce `:202-205`'te `RETURN` yapar.
   LGAPVS01 poliçe türünü `CA-REQUEST-ID`'nin 4. karakterinden alır (`lgapvs01.cbl:99`): `'01AMOT'` → `'M'`.
5. **Çağrı sırası ve geri alma.**
   - Sıra: `INSERT-POLICY` (`lgapdb01.cbl:219`), `INSERT-MOTOR` (`:231-232`), LGAPVS01'e LINK (`:243-246`).
   - Motor INSERT hatasında program `ABEND LGSQ` yapar; yorum bunun `POLICY` INSERT'ini geri almak için olduğunu söyler
     (`lgapdb01.cbl:476-477`).
   - LGAPVS01 hatasında ABEND ya da `ROLLBACK` yoktur: `80` yazar ve `RETURN` yapar (`lgapvs01.cbl:142-147`). LGAPDB01 de dönüş kodunu
     kontrol etmeden `RETURN` yapar (`lgapdb01.cbl:243-250`). Programlar `POLICY` ve `MOTOR` satırlarını geri almaz;
     `80`, çağırana ulaşır.
   - [belge] `base/Architecture.md:48`: uygulama müşteri ve poliçe verisini Db2'ye iki aşamalı onayla yazar, başarılıysa VSAM'ı günceller.
     Bu belge ifadesi VSAM hatasında geri alma yapıldığını söylemez. `04-15` bu yüzden "satırlar kalır" der; bu, kodda geri alma
     bulunmamasına dayanır, belgeye değil.
6. **`POLICY` INSERT'inin kuralları** (`lgapdb01.cbl:261-322`).
   - `policyNumber` `DEFAULT` ile verilir (`:279`); sütun `GENERATED BY DEFAULT AS IDENTITY (START WITH 1000001 …)`
     (`db2cre.jcl:162-163`). Girdideki `CA-POLICY-NUM` hiç okunmaz ve INSERT'e girmez. Yeni numara `IDENTITY_VAL_LOCAL()` ile alınır ve
     `CA-POLICY-NUM`'a yazılır (`:308-311`).
   - `lastChanged` = `CURRENT TIMESTAMP` (`:284`). Girdideki `CA-LASTCHANGED` kullanılmaz. Değer sonradan `SELECT` ile COMMAREA'ya
     konur (`:316-321`); bu `SELECT`'in SQLCODE'u hiç kontrol edilmez.
   - `commission` sütunu INSERT listesinde yoktur (`:270-278`, sütun: `db2cre.jcl:172`).
   - `CA-BROKERID` 10 haneli, host değişkeni `PIC S9(9) COMP` (`lgapdb01.cbl:91`, `:264`): B3 ile en soldaki hane kesilir.
7. **Hiçbir alan doğrulanmaz.** İki COBOL programında da tarih, marka, değer, cc, prim, kaza sayısı için kontrol yok. `POLICY` ve `MOTOR`
   tanımlarında `CHECK` kısıtı yok (`db2cre.jcl:161-176`, `:275-288`). Metin sütunları COMMAREA alanlarıyla aynı genişlikte:
   `make` `CHAR(15)`, `model` `CHAR(15)`, `regNumber` `CHAR(7)`, `colour` `CHAR(8)` (`db2cre.jcl:277-281`).
8. **VSAM kaydı** (`lgapvs01.cbl:25-51`, `:99-101`, `:124-128`, `:135-141`).
   - Kayıt 64 bayttır: anahtar 21 bayt (tür harfi 1 + müşteri no 10 + poliçe no 10) + veri 43 bayt. Motor verisi: marka 15, model 15,
     değer 6, plaka 7 (`lgapvs01.cbl:47-51`). `CA-M-COLOUR`, `CA-M-CC`, `CA-M-MANUFACTURED`, `CA-M-PREMIUM`, `CA-M-ACCIDENTS`
     VSAM'a yazılmaz.
   - Anahtardaki poliçe numarası, LGAPDB01'in `CA-POLICY-NUM`'a yazdığı yeni numaradır. Anahtardaki müşteri numarası `CA-CUSTOMER-NUM`'un
     10 haneli halidir; Db2'ye gidenin kesilmiş hali değildir.
   - Küme `KEYS(21 0)`, `RECORDSIZE(64 64)` ile tanımlıdır [kod] `adef121.jcl:49-50`. Başlangıç verisinde üç motor kaydı var:
     `ksdspoly.txt:8-10`.
9. **Dönüş kodları.**

   | Kod | Nerede | Anlamı | Çağırana ulaşır mı |
   |---|---|---|---|
   | `00` | `lgapol01.cbl:105`, `lgapdb01.cbl:172`, `:293` | Başlangıç / `POLICY` INSERT başarılı | Evet |
   | `70` | `lgapdb01.cbl:296` | `POLICY` INSERT `SQLCODE = -530` | Evet |
   | `80` | `lgapvs01.cbl:144` | VSAM yazma hatası | Evet (ABEND yok) |
   | `90` | `lgapdb01.cbl:301` | `POLICY` INSERT'te diğer SQLCODE'lar | Evet |
   | `90` | `lgapdb01.cbl:474` | `MOTOR` INSERT hatası | Belirsiz: hemen ardından `ABEND LGSQ` (`:477`) |
   | `98` | `lgapol01.cbl:114` | COMMAREA < 28 | Evet |
   | `98` | `lgapdb01.cbl:211` | COMMAREA < 165 | Yalnızca LGAPDB01 doğrudan çağrılırsa |
   | `99` | `lgapdb01.cbl:204` | İstek kodu tanınmıyor | Evet |
   | ABEND `LGCA` | `lgapol01.cbl:101`, `lgapdb01.cbl:168` | COMMAREA yok | — |
   | ABEND `LGSQ` | `lgapdb01.cbl:477` | `MOTOR` INSERT hatası | — |

10. **Hata mesajı içerikleri.**
    - `ERROR-MSG` uzunlukları: LGAPOL01 45 bayt (`lgapol01.cbl:41-46`), LGAPDB01 87 bayt (`lgapdb01.cbl:41-53`),
      LGAPVS01 101 bayt (`lgapvs01.cbl:58-73`). `CA-ERROR-MSG` üçünde de 99 bayttır: `'COMMAREA='` + 90 bayt.
    - LGAPDB01: `EM-SQLREQ` `POLICY` INSERT'inde `' INSERT POLICY'` + 2 boşluk (`:267`), `MOTOR` INSERT'inde `' INSERT MOTOR '` + 2 boşluk
      (`:448`). `EM-CUSNUM` ← `CA-CUSTOMER-NUM` (`:179`). `EM-POLNUM` yalnızca `POLICY` INSERT başarılı olduktan sonra dolar (`:313`):
      `POLICY` INSERT hatasında 10 boşluktur (`:50`), `MOTOR` INSERT hatasında yeni poliçe numarasıdır. `EM-SQLRC` `PIC +9(5)`: `-530`
      → `-00530` (`:53`, `:564`).
    - LGAPVS01: `' PNUM='` + poliçe no, `' CNUM='` + müşteri no, `' Write file KSDSPOLY'`, `' RESP='`, `' RESP2='`
      (`lgapvs01.cbl:63-73`, `:165-168`). `RESP2` ← `EIBRESP2` (`:143`).
    - LGAPDB01'in `EIBCALEN = 0` mesajı: 21 karakterlik `' NO COMMAREA RECEIVED'`, 63 baytlık `EM-VARIABLE` grubuna taşınır ve sabitleri
      ezer (`lgapdb01.cbl:46-53`, `:166`). Sonra `MOVE SQLCODE TO EM-SQLRC` son 6 baytı ezer (`:564`).
11. **`WRITE-ERROR-MESSAGE` dalları** (`IF EIBCALEN > 0` / `< 91` / `ELSE`).
    - LGAPOL01'de yalnızca `EIBCALEN = 0` dalından çağrılır (`lgapol01.cbl:100`). İçindeki `IF EIBCALEN > 0` her zaman yanlıştır:
      `lgapol01.cbl:155-167` arasına hiçbir girdiyle ulaşılamaz (ölü kod).
    - LGAPDB01'de hata çağrılarından biri `EIBCALEN = 0` dalındandır (iç dallar çalışmaz). Diğerleri, 165 sınırını geçtikten sonra
      yapılır, yani `EIBCALEN ≥ 165` iken. `< 91` dalına (`lgapdb01.cbl:581-586`) hiçbir girdiyle ulaşılamaz (ölü kod).
    - LGAPVS01 zincirde `EIBCALEN = 32500` görür, `ELSE` dalı çalışır (`lgapvs01.cbl:180-186`). `< 91` dalına yalnızca doğrudan çağrıyla
      ulaşılır (`04-21`).
12. **WORKING-STORAGE kalıcılığı.** `WS-REQUIRED-CA-LEN` `VALUE +0` ile tanımlı ve her çağrıda üstüne eklenir (`lgapol01.cbl:60`, `:109`;
    `lgapdb01.cbl:66`, `:182`, `:195`). WORKING-STORAGE aynı süreçte yeniden kurulmazsa ikinci çağrıda eşikler iki katına çıkar
    (LGAPOL01: 56, LGAPDB01: 330). Test düzeneği her durumu ayrı süreçte çalıştırır [belge] `docs/adr/0004-legacy-test-harness.md`
    (karar 4). Bu yüzden bu dosyadaki tahminler tek çağrı içindir.
13. **Test verisi** (`base/cntl/db2cre.jcl`). Bu değerler yalnızca test veritabanı bu JCL ile yüklendiyse ve sonradan değiştirilmediyse geçerlidir.
    - Müşteri numaraları 1-10 (`db2cre.jcl:437`, `:471`, `:505`, …, `:743`). Girdide kullanılan müşteri 2: `db2cre.jcl:471`.
    - 04-01'in ortak ve motor değerleri, örnek poliçe 1'in ve motor 1'in değerleridir (`db2cre.jcl:947-953`, `:1106-1114`). Böylece her girdinin
      JCL'de bir kaynağı var. Poliçe 1 zaten Db2'de bulunduğundan 04-01'de yeni satırın numarası 1000001'dir, 1 değil.
    - Olmayan müşteri için `0000000000` kullanılır (04-11): JCL 1-10 numaralarını verir.

## Tahmin tablosu

| Test no | Girdi | Beklenen dönüş kodu | Beklenen veri | Tahminin dayandığı COBOL satırı | Kural türü |
|---|---|---|---|---|---|
| 04-01 | LGAPOL01 çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01AMOT'`. `CA-CUSTOMER-NUM = 0000000002` (müşteri 2 Db2'de var: `db2cre.jcl:471`). Ortak ve motor alanlarında örnek poliçe 1'in değerleri var (alan alan aşağıdaki **"04-01 girdi ve beklenen değerler"** tablosunda). [B6] Db2'de `POLICY`'ye `DEFAULT` ile hiç satır eklenmemiş. [B4] `POLICY` INSERT, `MOTOR` INSERT ve VSAM yazma başarılı (`SQLCODE = 0`, `RESP = NORMAL`). | `CA-RETURN-CODE = 00` | [B6] `CA-POLICY-NUM = 0001000001`. `CA-LASTCHANGED` = yeni `POLICY` satırının zaman damgası (biçimi **belirsiz**). Diğer COMMAREA alanları girdideki gibi kalır.<br>Yan etkiler: `POLICY`'de yeni satır (tür `M`), `MOTOR`'da yeni satır, `KSDSPOLY`'de 64 baytlık yeni kayıt (anahtar `M` + `0000000002` + `0001000001`). Ayrıntı aşağıda **"04-01'den sonra Db2'de ve VSAM'da beklenen durum"** tablosunda. Hata mesajı yazılmaz. | `lgapol01.cbl:98`, `:105`, `:113`, `:121-126`<br>`lgapdb01.cbl:172`, `:176`, `:184`, `:194-196`, `:210`, `:219`, `:231-232`, `:261-322`, `:440-479`, `:243-250`<br>`lgapvs01.cbl:99-101`, `:124-128`, `:135-147` | İş kuralı |
| 04-02 | LGAPOL01 çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01AXXX'` (tanınmayan kod). Diğer girdiler 04-01 ile aynı. | `CA-RETURN-CODE = 99` | LGAPDB01 `99` yazar ve `RETURN` yapar: hiçbir INSERT yapılmaz, LGAPVS01 çağrılmaz, hata mesajı yazılmaz. `CA-POLICY-NUM` değişmez. Dış katman LGAPOL01 de istek koduna bakmadığı için sonucu olduğu gibi döndürür. | `lgapdb01.cbl:184`, `:202-205`<br>`lgapol01.cbl:121-126` | Arayüz (COMMAREA) kuralı |
| 04-03 | 04-01 ile aynı, ama `CA-REQUEST-ID = '01amot'` (küçük harf). | `CA-RETURN-CODE = 99` | 04-02 ile aynı. LGAPDB01 istek kodunu büyük harfe çevirmez (`UPPER-CASE` yok); sorgulamadan (`05-06`) farklı. | `lgapdb01.cbl:184`, `:194`, `:202-205` | Arayüz (COMMAREA) kuralı |
| 04-04 | LGAPOL01 COMMAREA'sız çağrılır (`EIBCALEN = 0`). | Dönüş kodu yok. Görev `ABEND` kodu `LGCA` ile (NODUMP) sonlanır. | COMMAREA olmadığı için veri dönmez. LGAPDB01 çağrılmaz.<br>Yan etki: `LGSTSQ`'ya tek LINK yapılır: 45 baytlık `ERROR-MSG` (tarih, saat, `' LGAPOL01'`, `' NO COMMAREA RECEIVED'`). COMMAREA dökümü gönderilmez (`EIBCALEN > 0` sağlanmaz). | `lgapol01.cbl:98-102`, `:41-46`, `:137-155` | Arayüz (COMMAREA) kuralı |
| 04-05 | LGAPOL01 çağrılır. `EIBCALEN` 8 ile 27 arasında (sınır değer: `27`). | `CA-RETURN-CODE = 98` | LGAPDB01 çağrılmaz, hata mesajı yazılmaz (`lgapol01.cbl:113-116` arasında `WRITE-ERROR-MESSAGE` yok). Hiçbir tablo değişmez. | `lgapol01.cbl:105`, `:109`, `:113-116`<br>`lgapol01.cbl:59` | Arayüz (COMMAREA) kuralı |
| 04-06 | LGAPOL01 çağrılır. `EIBCALEN` 1 ile 7 arasında. | [B1] Tamponun 7-8. baytları `98` olur (ön koşullu) [kod] `lgapol01.cbl:114`. | Kod `98`'i yazıp `RETURN` yapar. `CA-RETURN-CODE` 7-8. baytlarda olduğu için gelen COMMAREA'nın dışında kalır (1-6'da tamamen, 7'de yarısı); B1 ile çağıranın tamponuna düşer. Ön koşulsuz kesin olan: `EIBCALEN = 7` ise COMMAREA'nın 7. baytı `9` olur. LGAPDB01 çağrılmaz, hata mesajı yazılmaz. | `lgcmarea.cpy:10-11`<br>`lgapol01.cbl:105`, `:113-116` | Arayüz (COMMAREA) kuralı |
| 04-07 | LGAPOL01 çağrılır. `EIBCALEN = 28` (kabul edilen en küçük uzunluk). `CA-REQUEST-ID = '01AMOT'`, `CA-CUSTOMER-NUM = 0000000002`. | `98` **dönmez**. Asıl dönüş kodu **belirsiz**. | LGAPOL01 isteği geçirir (`28 < 28` yanlış) ve LGAPDB01'i `LENGTH(32500)` ile çağırır; LGAPDB01'in kendi 165 sınırı çalışmaz (Kod gözlemleri 3). 29. baytta başlayan her alan COMMAREA'nın dışından okunur. [B1] Hepsi boşluk olur (`CA-ISSUE-DATE` boşluk vb.). Boşluğun `DATE` sütununa yazılıp yazılamayacağı Db2'ye bağlı. Aynı durum 29-164. baytların hepsi için geçerli. | `lgapol01.cbl:113-116`, `:121-124`<br>`lgapdb01.cbl:210-213`, `:281-282` | Arayüz (COMMAREA) kuralı |
| 04-08 | **LGAPDB01 doğrudan** COMMAREA'sız çağrılır (`EIBCALEN = 0`). [B2] `SQLCODE = 0`. | Dönüş kodu yok. Görev `ABEND` kodu `LGCA` ile (NODUMP) sonlanır. | SQL çalışmaz, LGAPVS01 çağrılmaz.<br>Yan etki: `LGSTSQ`'ya tek LINK yapılır: 87 baytlık `ERROR-MSG`. İçeriği: tarih, saat, `' LGAPDB01'`, `' NO COMMAREA RECEIVED'` + 36 boşluk + 6 baytlık `EM-SQLRC`. Taşıma 63 baytlık `EM-VARIABLE` grubunun tamamını ezdiği için `' CNUM='`, `' PNUM='`, `' SQLCODE='` sabitleri mesajda yer almaz. [B2] `EM-SQLRC = +00000` [kod] `lgapdb01.cbl:564`. COMMAREA dökümü gönderilmez.<br>LGAPOL01 üzerinden bu yola ulaşılamaz (Kod gözlemleri 3). | `lgapdb01.cbl:165-169`, `:46-53`, `:562-580` | Arayüz (COMMAREA) kuralı |
| 04-09 | **LGAPDB01 doğrudan** çağrılır. `EIBCALEN` 28 ile 164 arasında (sınır değer: `164`). `CA-REQUEST-ID = '01AMOT'`. | `CA-RETURN-CODE = 98` | Hiçbir INSERT yapılmaz, LGAPVS01 çağrılmaz, hata mesajı yazılmaz (`lgapdb01.cbl:210-213` arasında `WRITE-ERROR-MESSAGE` yok). `CA-POLICY-NUM` değişmez. LGAPOL01 üzerinden bu yola ulaşılamaz. | `lgapdb01.cbl:182`, `:194-195`, `:210-213`<br>`lgapdb01.cbl:65`, `lgpolicy.cpy:26` | Arayüz (COMMAREA) kuralı |
| 04-10 | **LGAPDB01 doğrudan** çağrılır. `EIBCALEN = 165` (kabul edilen en küçük uzunluk). `CA-REQUEST-ID = '01AMOT'`. | `98` **dönmez**. Asıl dönüş kodu **belirsiz**. | Uzunluk kontrolü geçilir (`165 < 165` yanlış). `CA-M-PREMIUM` (166-171) ve `CA-M-ACCIDENTS` (172-177) COMMAREA'nın dışında kalır ve INSERT-MOTOR'da okunur (Kod gözlemleri 2). [B1] İkisi de boşluk olur. Boşluk içeren sayısal alanın `MOVE` sonucu ve INSERT'in kabul edilip edilmeyeceği kodda ve Db2'de yazmıyor. | `lgapdb01.cbl:210-213`, `:445-446`<br>`lgcmarea.cpy:73-74` | Arayüz (COMMAREA) kuralı |
| 04-11 | LGAPOL01 çağrılır. `EIBCALEN = 32500`, `CA-REQUEST-ID = '01AMOT'`, `CA-CUSTOMER-NUM = 0000000000` (olmayan müşteri). [B4] `POLICY` INSERT, `SQLCODE = -530` döner. | `CA-RETURN-CODE = 70` | `POLICY`'ye satır eklenmez, `MOTOR` INSERT ve LGAPVS01 çağrılmaz (`RETURN`, ABEND yok). `CA-POLICY-NUM` değişmez (`IDENTITY_VAL_LOCAL` çalışmaz).<br>Yan etki: `LGSTSQ`'ya iki LINK yapılır.<br>(1) `ERROR-MSG` (87 bayt): tarih, saat, `' LGAPDB01'`, `' CNUM='` + `0000000000`, `' PNUM='` + 10 boşluk, `' INSERT POLICY'` + 2 boşluk, `' SQLCODE='` + `-00530`.<br>(2) `CA-ERROR-MSG`: `'COMMAREA='` + COMMAREA'nın ilk 90 baytı (`EIBCALEN = 32500`, `ELSE` dalı). | `lgapdb01.cbl:267-298`, `:179`, `:564-578`, `:587-592`<br>`db2cre.jcl:174-176` | İş kuralı |
| 04-12 | 04-11 ile aynı, ama `CA-CUSTOMER-NUM = 0000000000` ve düzenek INSERT'i kendisi yapar: gerçek Db2, yabancı anahtar tanımı (`db2cre.jcl:174-176`) ile müşteri 0 yok. [B4] yok: SQLCODE'u düzenek kurmaz. | **belirsiz** | **belirsiz**. Kod yalnızca `-530`'u `70`'e eşler. Var olmayan müşteriye INSERT'te Db2'nin `-530` döndüreceği kodda yazmıyor. `-530` dönerse sonuç 04-11'dir. Başka bir kod dönerse 04-13 yolu (`90`) çalışır. | `lgapdb01.cbl:290-305` | İş kuralı |
| 04-13 | 04-01 ile aynı, ama [B4] `POLICY` INSERT'te 0 ve `-530` dışında bir `SQLCODE` (örn. `-904`) üretilir. | `CA-RETURN-CODE = 90` | `POLICY`'ye satır eklenmez; `MOTOR` INSERT ve LGAPVS01 çağrılmaz (`RETURN`, ABEND yok). `CA-POLICY-NUM` değişmez.<br>Yan etki: `LGSTSQ`'ya iki LINK yapılır, 04-11 ile aynı iki mesaj; `EM-SQLRC` üretilen SQLCODE'dur, diğer alanlar aynıdır (`' PNUM='` + 10 boşluk). | `lgapdb01.cbl:300-303`, `:564-578` | İş kuralı |
| 04-14 | 04-01 ile aynı, ama [B4] `MOTOR` INSERT'te `SQLCODE ≠ 0` üretilir (örn. `-803`). | Dönüş kodu yok. `CA-RETURN-CODE`'a `90` yazılır, ardından görev `ABEND` kodu `LGSQ` ile (NODUMP) sonlanır. Çağıranın `90`'ı görüp görmeyeceği **belirsiz**. | LGAPVS01 çağrılmaz, VSAM'a yazılmaz. Kod yorumuna göre ABEND, `POLICY` INSERT'inin geri alınmasını sağlar: yeni `POLICY` satırı kalmaz [kod yorumu] `lgapdb01.cbl:476`. `MOTOR` satırı eklenmemiştir.<br>Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG`: 04-11'dekiyle aynı biçim, ama `' PNUM='` + **yeni poliçe numarası** (`0001000001` [B6]), `EM-SQLREQ` `' INSERT MOTOR '` + 2 boşluk. (2) `CA-ERROR-MSG`: COMMAREA'nın ilk 90 baytı; bayt 19-28 yeni poliçe numarasıdır. | `lgapdb01.cbl:308-313`, `:473-479`, `:448`, `:564-578`<br>[kod yorumu] `lgapdb01.cbl:476` | İş kuralı |
| 04-15 | 04-01 ile aynı, ama [B4] VSAM yazmada `RESP ≠ NORMAL` (örn. `DUPREC`: `KSDSPOLY`'de `M0000000002` + `0001000001` anahtarlı kayıt zaten var). | `CA-RETURN-CODE = 80` | `POLICY` ve `MOTOR` satırları eklenmiştir ve **programca geri alınmaz** (VSAM hatasında ABEND ya da `ROLLBACK` yok: Kod gözlemleri 5). Db2 ile VSAM tutarsız kalır.<br>`CA-POLICY-NUM` ve `CA-LASTCHANGED` yeni değerlerle döner.<br>Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG` (101 bayt): tarih, saat, `' LGAPVS01'`, `' PNUM='` + `0001000001`, `' CNUM='` + `0000000002`, `' Write file KSDSPOLY'`, `' RESP='` + RESP, `' RESP2='` + RESP2. (2) `CA-ERROR-MSG`: COMMAREA'nın ilk 90 baytı (`EIBCALEN = 32500`, `ELSE` dalı). | `lgapvs01.cbl:135-147`, `:155-188`<br>`lgapdb01.cbl:243-250` | İş kuralı |
| 04-16 | 04-01 ile aynı, ama [B4] `POLICY` INSERT başarılı, sonraki `SELECT LASTCHANGED` `SQLCODE ≠ 0` döner. | `CA-RETURN-CODE = 00` | `SELECT`'in SQLCODE'u kontrol edilmez: program devam eder, `MOTOR` INSERT ve VSAM yazma yapılır (04-01 gibi). `CA-LASTCHANGED`'ın ne kalacağı **belirsiz** (hata durumunda `SELECT`'in alanı ne yaptığı kodda yok). Hata mesajı yazılmaz. | `lgapdb01.cbl:316-322`, `:219-232` | Arayüz (COMMAREA) kuralı |
| 04-17 | 04-01 ile aynı, ama `CA-POLICY-NUM = 0000000001` (Db2'de var olan poliçe 1'in numarası) ve `CA-LASTCHANGED = '2011-05-11-17.12.17.000000'` (poliçe 1'in değeri, `db2cre.jcl:950`). [B6] | `CA-RETURN-CODE = 00` | Girdideki iki alan yok sayılır: `CA-POLICY-NUM = 0001000001` ve `CA-LASTCHANGED` yeni satırın zaman damgası olur. Poliçe 1'in `POLICY` ve `MOTOR` satırları **değişmez**. | `lgapdb01.cbl:279`, `:284`, `:308-311`, `:316-321` | İş kuralı |
| 04-18 | 04-01 ile aynı, ama `CA-ISSUE-DATE = '2012-05-10'` ve `CA-EXPIRY-DATE = '2011-05-11'` (bitiş başlangıçtan önce), `CA-M-MAKE` ve `CA-M-MODEL` boşluk, `CA-M-VALUE = 000000`. | `CA-RETURN-CODE = 00` | Hiçbir programda alan doğrulaması yok ve `POLICY`/`MOTOR` tanımlarında kısıt yok. İki tabloya da girdideki değerler (tarihler ters, marka ve model boşluk, değer sıfır) olduğu gibi yazılır; VSAM kaydına da boşluk marka ve model gider. | `lgapdb01.cbl:268-288`, `:443-471`<br>`lgapvs01.cbl:124-128`<br>`db2cre.jcl:161-176`, `:275-288` | İş kuralı |
| 04-19 | 04-01 ile aynı, ama `CA-CUSTOMER-NUM = 1000000002` (10 haneli). [B3] | [B3] `CA-RETURN-CODE = 00` (ön koşullu) [kod] `lgapdb01.cbl:292-293`. | [B3] `PIC 9(10)` → `PIC S9(9) COMP` taşımasında en soldaki hane kesilir ve `DB2-CUSTOMERNUM-INT = 2` olur: poliçe **müşteri 2** için eklenir [kod] `lgcmarea.cpy:12`, `lgapdb01.cbl:90`, `:176`. VSAM anahtarı ise 10 haneli `1000000002`'yi kesilmeden kullanır [kod] `lgapvs01.cbl:101`: `KSDSPOLY`'de anahtar `M` + `1000000002` + `0001000001` olur; Db2'dekiyle tutarsız.<br>B3 sağlanmazsa sonuç **belirsiz**. | `lgcmarea.cpy:12`<br>`lgapdb01.cbl:90`, `:176`, `:280`<br>`lgapvs01.cbl:100-101`, `:135-141`<br>`cobol.jcl:44-50` | Arayüz (COMMAREA) kuralı |
| 04-20 | 04-01 ile aynı, ama `CA-CUSTOMER-NUM` sayısal değil (örn. boşluk). | **belirsiz** | **belirsiz**. İki programda da sayısallık kontrolü yok. Sayısal olmayan değer doğrudan `DB2-CUSTOMERNUM-INT`'e taşınır ve VSAM anahtarı olarak da kullanılır. | `lgapdb01.cbl:176`<br>`lgapvs01.cbl:101` | Arayüz (COMMAREA) kuralı |
| 04-21 | **LGAPVS01 doğrudan** çağrılır. `EIBCALEN` 28 ile 90 arasında (anahtardaki müşteri ve poliçe numaraları 9-28. baytlarda, içeride kalır). `CA-REQUEST-ID = '01AMOT'`. [B4] Yazmada `RESP ≠ NORMAL`. | `CA-RETURN-CODE = 80` | Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG`: 04-15'teki gibi. (2) `EIBCALEN < 91` dalı: `'COMMAREA='` + `DFHCOMMAREA(1:EIBCALEN)`; kalan `CA-DATA` boşluk. Bu dala yalnızca bu yolla ulaşılır.<br>Not: LGAPVS01'de `EIBCALEN` kontrolü yok. `EIBCALEN < 28` ise poliçe numarası kısmen COMMAREA dışında kalır; anahtar ve sonuç bu satırın kapsamı dışındadır. | `lgapvs01.cbl:97-101`, `:135-147`, `:173-179` | Arayüz (COMMAREA) kuralı |
| 04-22 | **LGAPVS01 doğrudan** çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01AXXX'` (4. karakter `X`; `C`, `E`, `H`, `M` dışında). `CA-CUSTOMER-NUM` ve `CA-POLICY-NUM` dolu. [B4] Yazma başarılı. | `CA-RETURN-CODE` **değişmez** (LGAPVS01 başarıda dönüş kodu yazmaz). | `KSDSPOLY`'ye 64 baytlık kayıt yazılır: anahtar `X` + müşteri no + poliçe no, veri kısmı 43 boşluk (`WHEN OTHER`). Hata mesajı yazılmaz. | `lgapvs01.cbl:99-101`, `:130-132`, `:135-141` | Arayüz (COMMAREA) kuralı |

## 04-01 girdi ve beklenen değerler

Müşteri 2'ye, örnek poliçe 1'in ve motor 1'in değerleriyle yeni poliçe eklenir. "␣×n" sağdaki n adet boşluğu gösterir.

| COMMAREA alanı | Girdi | Girdinin kaynağı (`db2cre.jcl`) | Dönüşte beklenen | Alanı kullanan COBOL satırı |
|---|---|---|---|---|
| `CA-REQUEST-ID` X(6) | `01AMOT` | — (değer koddan: `lgapdb01.cbl:194`) | Değişmez | `lgapdb01.cbl:184`, `:194` |
| `CA-RETURN-CODE` 9(2) | Herhangi bir değer | — | `00` | `lgapol01.cbl:105`, `lgapdb01.cbl:172`, `:293` |
| `CA-CUSTOMER-NUM` 9(10) | `0000000002` | `:471` | Değişmez | `lgapdb01.cbl:176`, `:179` |
| `CA-POLICY-NUM` 9(10) | Herhangi bir değer (örn. `0000000000`) | — (kullanılmaz) | [B6] `0001000001` | `lgapdb01.cbl:279`, `:308-311` |
| `CA-ISSUE-DATE` X(10) | `2011-05-11` | `:947` | Değişmez | `lgapdb01.cbl:281` |
| `CA-EXPIRY-DATE` X(10) | `2012-05-10` | `:948` | Değişmez | `lgapdb01.cbl:282` |
| `CA-LASTCHANGED` X(26) | Herhangi bir değer | — (kullanılmaz) | Yeni satırın zaman damgası (biçimi **belirsiz**) | `lgapdb01.cbl:284`, `:316-321` |
| `CA-BROKERID` 9(10) | `0000000000` | `:951` | Değişmez | `lgapdb01.cbl:264`, `:285` |
| `CA-BROKERSREF` X(10) | ␣×10 (JCL'de `''`) | `:952` | Değişmez | `lgapdb01.cbl:286` |
| `CA-PAYMENT` 9(6) | `000000` | `:953` | Değişmez | `lgapdb01.cbl:265`, `:287` |
| `CA-M-MAKE` X(15) | `FORD` + ␣×11 | `:1106` (sütun `CHAR(15)`: `:277`) | Değişmez | `lgapdb01.cbl:462` |
| `CA-M-MODEL` X(15) | `KA` + ␣×13 | `:1107` (sütun `CHAR(15)`: `:278`) | Değişmez | `lgapdb01.cbl:463` |
| `CA-M-VALUE` 9(6) | `008500` | `:1108` | Değişmez | `lgapdb01.cbl:443`, `:464` |
| `CA-M-REGNUMBER` X(7) | `LL60LOO` | `:1109` (sütun `CHAR(7)`: `:280`) | Değişmez. Karakterler L-L-6-0-L-O-O: 4. karakter sıfır rakamı, son ikisi O harfi | `lgapdb01.cbl:465` |
| `CA-M-COLOUR` X(8) | `ORANGE` + ␣×2 | `:1110` (sütun `CHAR(8)`: `:281`) | Değişmez | `lgapdb01.cbl:466` |
| `CA-M-CC` 9(4) | `1000` | `:1111` | Değişmez | `lgapdb01.cbl:444`, `:467` |
| `CA-M-MANUFACTURED` X(10) | `1999-07-19` | `:1112` | Değişmez | `lgapdb01.cbl:468` |
| `CA-M-PREMIUM` 9(6) | `000450` | `:1113` | Değişmez | `lgapdb01.cbl:445`, `:469` |
| `CA-M-ACCIDENTS` 9(6) | `000000` | `:1114` | Değişmez | `lgapdb01.cbl:446`, `:470` |
| `CA-M-FILLER` X(32323) | Herhangi bir değer | — | Değişmez | Kodda okunmuyor, yazılmıyor |

## 04-01'den sonra Db2'de ve VSAM'da beklenen durum

| Hedef | Beklenen | COBOL satırı |
|---|---|---|
| `POLICY` | Yeni satır: `policyNumber` = 1000001 [B6], `customerNumber` = 2, `issueDate` = 2011-05-11, `expiryDate` = 2012-05-10, `policyType` = `M`, `lastChanged` = INSERT anındaki zaman damgası, `brokerId` = 0, `brokersReference` = boşluk (`CHAR(10)`), `payment` = 0. `commission` için değer verilmez. Poliçe 1'in satırı değişmez. | `lgapdb01.cbl:268-288`, `:196` |
| `MOTOR` | Yeni satır: `policyNumber` = 1000001, `make` = `FORD`, `model` = `KA`, `value` = 8500, `regNumber` = `LL60LOO`, `colour` = `ORANGE`, `cc` = 1000, `yearOfManufacture` = 1999-07-19, `premium` = 450, `accidents` = 0. | `lgapdb01.cbl:449-471` |
| `KSDSPOLY` | Yeni 64 baytlık kayıt: `M` + `0000000002` + `0001000001` + `FORD` + ␣×11 + `KA` + ␣×13 + `008500` + `LL60LOO`. Başlangıçtaki üç motor kaydı (`ksdspoly.txt:8-10`) değişmez. | `lgapvs01.cbl:99-101`, `:124-128`, `:135-141` |
| `CUSTOMER` | Değişmez. Bu zincirde müşteri tablosuna giden SQL yok. | `lgapdb01.cbl:268-321`, `:449-471` |

## Kapsam tablosu

Koddaki her `IF`/`EVALUATE` dalının ve dönüş kodunun, onu kapsayan test numaraları.

| Envanter no | Madde | Test no | Not |
|---|---|---|---|
| AO-01 | `lgapol01.cbl:98-102` `IF EIBCALEN = 0` → ABEND `LGCA` | 04-04 | |
| AO-02 | `lgapol01.cbl:105` `'00'` → `CA-RETURN-CODE` | 04-01, 04-05, 04-06 | 04-05/04-06: kontrolden önce yazılır |
| AO-03 | `lgapol01.cbl:109`, `:113-116` `IF EIBCALEN < 28` → `98` (doğru ve yanlış dal) | 04-05, 04-06 (doğru dal); 04-01, 04-07 (yanlış dal) | |
| AO-04 | `lgapol01.cbl:121-126` LINK LGAPDB01 `LENGTH(32500)`, RETURN | 04-01, 04-02, 04-07 | |
| AO-05 | `lgapol01.cbl:137-169` `WRITE-ERROR-MESSAGE` | 04-04 | Dış `IF EIBCALEN > 0` yanlış. İç dallar (`lgapol01.cbl:155-167`) ölü kod (Kod gözlemleri 11) |
| AD-01 | `lgapdb01.cbl:165-169` `IF EIBCALEN = 0` → ABEND `LGCA` | 04-08 | Yalnızca doğrudan çağrı |
| AD-02 | `lgapdb01.cbl:172` `'00'` | 04-01, 04-09 | |
| AD-03 | `lgapdb01.cbl:176`, `:179` `CA-CUSTOMER-NUM` → `DB2-CUSTOMERNUM-INT`, `EM-CUSNUM` | 04-01, 04-11, 04-19, 04-20 | |
| AD-04 | `lgapdb01.cbl:184-207` `EVALUATE CA-REQUEST-ID` ilk | 04-01 (`WHEN '01AMOT'`), 04-02, 04-03 (`WHEN OTHER` → `99`) | Motor dışı `WHEN` kolları kapsam dışı |
| AD-05 | `lgapdb01.cbl:210-213` `IF EIBCALEN < WS-REQUIRED-CA-LEN` → `98` | 04-09 (doğru dal), 04-10 (sınır), 04-01 (yanlış dal) | Yalnızca doğrudan çağrı |
| AD-06 | `lgapdb01.cbl:219`, `:261-322` `INSERT-POLICY` | 04-01, 04-11, 04-13, 04-16, 04-17 | |
| AD-07 | `lgapdb01.cbl:292-293` `When 0` → `00` | 04-01 | |
| AD-08 | `lgapdb01.cbl:295-298` `When -530` → `70` | 04-11 | 04-12: düzenek olmadan belirsiz |
| AD-09 | `lgapdb01.cbl:300-303` `When Other` → `90` | 04-13 | |
| AD-10 | `lgapdb01.cbl:308-321` `IDENTITY_VAL_LOCAL`, `SELECT LASTCHANGED` (SQLCODE kontrolsüz) | 04-01, 04-16, 04-17 | |
| AD-11 | `lgapdb01.cbl:223-241` `EVALUATE CA-REQUEST-ID` ikinci | 04-01 (`WHEN '01AMOT'`) | `WHEN OTHER` (`:237-240`) ölü kod (Kod gözlemleri 4) |
| AD-12 | `lgapdb01.cbl:440-479` `INSERT-MOTOR`, `IF SQLCODE NOT EQUAL 0` | 04-01 (yanlış dal), 04-14 (doğru dal), 04-18 | |
| AD-13 | `lgapdb01.cbl:243-250` LINK LGAPVS01 `LENGTH(32500)`, RETURN | 04-01, 04-15 | |
| AD-14 | `lgapdb01.cbl:562-595` `WRITE-ERROR-MESSAGE` | 04-08 (dış `IF` yanlış), 04-11, 04-13, 04-14 (`ELSE`) | `< 91` dalı (`:581-586`) ölü kod (Kod gözlemleri 11) |
| AV-01 | `lgapvs01.cbl:97-101` anahtar kurma | 04-01, 04-19, 04-20, 04-22 | |
| AV-02 | `lgapvs01.cbl:103-132` `EVALUATE WF-Request-ID` | 04-01 (`WHEN 'M'`), 04-22 (`WHEN OTHER`) | `C`, `E`, `H` kolları kapsam dışı |
| AV-03 | `lgapvs01.cbl:135-141` `WRITE FILE` | 04-01, 04-22 | |
| AV-04 | `lgapvs01.cbl:142-147` `RESP ≠ NORMAL` → `80` (doğru ve yanlış dal) | 04-15, 04-21 (doğru dal); 04-01 (yanlış dal) | |
| AV-05 | `lgapvs01.cbl:155-188` `WRITE-ERROR-MESSAGE` | 04-15 (`ELSE`), 04-21 (`< 91`) | `EIBCALEN = 0` dalı: LGAPVS01'de `EIBCALEN` kontrolü yok (Kod gözlemleri 11) |
| SQ-01 | `lgstsq.cbl:68-71` LINK yolu | 04-04, 04-08, 04-11, 04-13, 04-14, 04-15, 04-21 | |
| SQ-02 | `lgstsq.cbl:72-80` terminalden RECEIVE | — | **Kapsam dışı: bu zincirden ulaşılamaz.** LGSTSQ yalnızca LINK ile çağrılır. |
| SQ-03 | `lgstsq.cbl:94-111` WRITEQ TD `CSMT`, TS `GENAERRS` | 04-11 … 04-15 | |
| N-01 | Girdideki `CA-POLICY-NUM`, `CA-LASTCHANGED` yok sayılır | 04-17 | |
| N-02 | Alan doğrulaması yok | 04-18, 04-20 | Kod gözlemleri 7 |
| N-03 | VSAM hatasında Db2 satırları geri alınmaz | 04-15 | Kod gözlemleri 5 |
| N-04 | `CA-CUSTOMER-NUM` kesilmesi (B3) | 04-19 | Kod gözlemleri 6 |

## Ön koşullu satırlar

Ön koşul kodları dosyanın başında ("Kaynak etiketleri ve ön koşul kodları").

| Test no | Ön koşul | Ön koşulla tahmin | Ön koşul sağlanmazsa |
|---|---|---|---|
| 04-01 | B4, B6 | Başarı yolu; `CA-POLICY-NUM = 0001000001` | B6 yoksa numara belirsiz (kimlik sayacı ilerlemiştir) |
| 04-06 | B1 | Tamponun 7-8. baytları `98` | Dönüş kodu belirsiz |
| 04-07 | B1 | Alanlar boşluk olarak okunur | Okunan değerler belirsiz |
| 04-08 | B2 | `EM-SQLRC = +00000` | `EM-SQLRC` belirsiz |
| 04-10 | B1 | `CA-M-PREMIUM`, `CA-M-ACCIDENTS` boşluk olarak okunur | Okunan değerler belirsiz |
| 04-11 | B4 | Girdi düzenekle kurulur; tahmin (`70`) değişmez | Girdi kurulamaz: bkz. 04-12 |
| 04-13 | B4 | Girdi düzenekle kurulur; tahmin (`90`) değişmez | Girdi kurulamaz |
| 04-14 | B4, B6 | Girdi düzenekle kurulur; tahmin (`90` + ABEND `LGSQ`) değişmez; mesajdaki poliçe no `0001000001` | Girdi kurulamaz; B6 yoksa mesajdaki numara belirsiz |
| 04-15 | B4, B6 | Girdi düzenekle kurulur; tahmin (`80`) değişmez; mesajdaki poliçe no `0001000001` | Girdi kurulamaz; B6 yoksa mesajdaki numara belirsiz |
| 04-16 | B4 | Girdi düzenekle kurulur; tahmin (`00`) değişmez | Girdi kurulamaz |
| 04-17 | B6 | Yeni numara `0001000001` | Yeni numara belirsiz |
| 04-19 | B3 | Poliçe müşteri 2 için eklenir, VSAM anahtarı `1000000002` | Dönüş kodu ve veri belirsiz |
| 04-21 | B4 | Girdi düzenekle kurulur; tahmin (`80`, `< 91` dalı) değişmez | Girdi kurulamaz |
| 04-22 | B4 | Girdi düzenekle kurulur | Girdi kurulamaz |

## Belirsiz satırlar

| Test no | Belirsiz olan hücre | Neden belirsiz |
|---|---|---|
| 04-01 | Beklenen veri (yalnızca `CA-LASTCHANGED` biçimi) | `lastChanged` sütunu `TIMESTAMP` türünde (`db2cre.jcl:168`) ve doğrudan `PIC X(26)` alana okunuyor (`lgapdb01.cbl:316-321`). Okunurken hangi biçimde geleceği Db2 ayarına bağlı ve kodda yazmıyor. |
| 04-07 | Dönüş kodu, beklenen veri | 29-164. baytlar COMMAREA'nın dışından okunuyor; INSERT'in kabul edilip edilmeyeceği Db2'ye ve ortama bağlı (`DATE` sütununa boşluk). |
| 04-10 | Dönüş kodu, beklenen veri | Boşluk içeren `PIC 9(6)` alanın `PIC S9(9) COMP` alana taşınması kodda tanımlı değil. |
| 04-12 | Dönüş kodu, beklenen veri | Var olmayan müşteriye `POLICY` INSERT'inin hangi SQLCODE'u döndüreceği kodda yok. Kod yalnızca `-530`'u tanıyor. |
| 04-14 | Dönüş kodu (çağıranın `90`'ı görmesi) | `90` yazıldıktan hemen sonra `ABEND LGSQ` geliyor (`lgapdb01.cbl:474-477`) ve zincirde abend yakalama yok. |
| 04-16 | Beklenen veri (`CA-LASTCHANGED`) | Başarısız `SELECT ... INTO`'nun host değişkenine ne yazdığı kodda görünmüyor. |
| 04-20 | Dönüş kodu, beklenen veri | Sayısal olmayan veri sayısal alana taşınıyor ve hiçbir doğrulama yok. Sonuç tanımsız. |
