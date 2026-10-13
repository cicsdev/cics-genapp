# 06 — Motor poliçesi güncelle (Update Motor Policy)

Şablon: [TEMPLATE.md](TEMPLATE.md)

| Alan | Değer |
|---|---|
| Operasyon | Motor poliçesi güncelle: müşteri ve poliçe numarasıyla bulunan `POLICY` satırı ile `MOTOR` satırı COMMAREA'daki değerlerle güncellenir ve VSAM `KSDSPOLY` kaydı yeniden yazılır. Güncelleme, COMMAREA'daki `LASTCHANGED` değeri Db2'dekiyle aynıysa yapılır (iyimser kilit). Poliçe türü COMMAREA'daki istek kodundan (`01UMOT`) anlaşılır. |
| Programlar (çağrı zinciri) | `LGUPOL01` (iş mantığı) → `EXEC CICS LINK` → `LGUPDB01` (Db2 imleci, `MOTOR` ve `POLICY` UPDATE) → `LINK` → `LGUPVS01` (VSAM `READ UPDATE` + `REWRITE`). Hata yollarında üçü de `LGSTSQ`'ya LINK eder. Programlar dört poliçe türüne de hizmet eder; yalnızca motor (`01UMOT`) kolları ve ortak kısımlar okundu. |
| Okunan COBOL dosyaları | `base/src/lgupol01.cbl`, `base/src/lgupdb01.cbl`, `base/src/lgupvs01.cbl`, `base/src/lgstsq.cbl`, `base/src/lgcmarea.cpy`, `base/src/lgpolicy.cpy` |
| Test verisi kaynağı | `base/cntl/db2cre.jcl`: `POLICY` ve `MOTOR` tanımları (`:161-178`, `:275-290`), müşteri 2, 3, 5 ve 8 (`:471`, `:505`, `:573`, `:675`), poliçe 1, 3 ve 4 ile motor 1 ve 3'ün verisi (`:945-954`, `:969-978`, `:849-858`, `:1105-1114`, `:1128-1137`). `base/cntl/adef121.jcl` ve `base/data/ksdspoly.txt`: `KSDSPOLY` tanımı ve başlangıç verisi. COBOL kodu değil. |
| Kullanılan belgeler ([belge]) | `base/Architecture.md` (yalnızca Kod gözlemleri 9; kodda doğrulanmadı), `docs/srs.md` (yalnızca Kod gözlemleri 4'teki karşılaştırma), `docs/adr/0004-legacy-test-harness.md` (yalnızca Kod gözlemleri 13), `docs/api-design.md` (yalnızca dönüş kodu ve `lastChanged` açıklamasına bakıldı; hiçbir tahmin buna dayanmaz) |
| Hazırlayan | Oğuz (taslak: Claude Code) |
| Tarih | 2026-10-13 |
| Kaynak commit (`git rev-parse HEAD`) | `99e4be84f053e984f51652728e149f80f0a98920` |

## Kaynak etiketleri ve ön koşul kodları

Bu dosyadaki tahminler kaynak türüyle etiketlidir:

- **[kod]**: COBOL kaynağı, copybook, JCL ya da bunların yüklediği veri dosyası (dosya + satır).
- **[belge]**: `base/` altındaki ya da `docs/` altındaki açıklama metinleri. Belgeye dayanan bir tahmin kodda doğrulanmamıştır.
- Etiketsiz kaynaklar [kod]'dur.

Ön koşul kodları test düzeneğinin vereceği kararlardır (kodlar `03-customer-update.md` ile aynıdır). Bir kodu taşıyan tahmin
**kesin değil, ön koşulludur**: ön koşul sağlanmazsa tahmin geçersizdir ve "Ön koşullu satırlar" tablosundaki son sütun geçerli olur.

| Kod | Ön koşul |
|---|---|
| B1 | Düzenek COMMAREA'yı her LINK'te, en dıştaki çağıranın 32500 baytlık tamponunun adresiyle geçirir. `EIBCALEN` yalnızca bildirilen uzunluktur. Tamponun `EIBCALEN` ötesi boşlukla doldurulur. COMMAREA dışına yapılan yazmalar bu tampona düşer ve çağıran onları görür. |
| B2 | SQLCA `SQLCODE = 0` ile başlar. |
| B3 | Derleyici sayısal taşımalarda PICTURE'ın hane sayısına göre keser (Enterprise COBOL'da `TRUNC(STD)`, GnuCOBOL'da kesme açık). Derleme seçeneklerinde `TRUNC` belirtilmemiş [kod] `cobol.jcl:44-50`. |
| B4 | Düzenek, satırda yazılan hata kodunu (SQLCODE / RESP) ya da veri durumunu (bir kaydın var ya da yok olması) kendisi kurar. **Aksi söylenmedikçe** her SQL deyiminin `SQLCODE`'u `0`, her dosya komutunun `RESP`'i `NORMAL`'dir; satırda yalnızca düzeneğin değiştirdiği değer yazılır. |

(B5 ve B6 bu dosyada kullanılmıyor.)

## Kod gözlemleri

1. **COMMAREA bayt haritası, poliçe görünümü** (`lgcmarea.cpy:10-13`, `:34-44`, `:65-75`). Üç program da bu düzeni kullanır
   (`lgupol01.cbl:73-74`, `lgupdb01.cbl:150-153`, `lgupvs01.cbl:89-90`). Motor güncellemesinde alanlar:

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

2. **Uzunluk kontrolü yalnızca LGUPOL01'de ve yalnızca tanınan istek kodlarında vardır.**
   - LGUPOL01, `'01UMOT'` için 28 (`lgupol01.cbl:62`) + 137 (`lgupol01.cbl:41`) = **165** ister (`:131-137`). 165 bayt, 1-165'i yani
     `CA-M-MANUFACTURED`'ın sonuna kadar olan alanları kapsar; `CA-M-PREMIUM` (166-171) ve `CA-M-ACCIDENTS` (172-177) kontrolün dışında kalır.
     İkisi de UPDATE-MOTOR'da okunur (`lgupdb01.cbl:465-466`).
   - LGUPOL01, LGUPDB01'i her zaman `LENGTH(32500)` ile çağırır (`lgupol01.cbl:157-160`). LGUPDB01'de uzunluk kontrolü yoktur: `WS-CA-HEADER-LEN` ve
     `WS-REQUIRED-CA-LEN` tanımlı ama hiç kullanılmaz (`lgupdb01.cbl:63-65`); yorum "check commarea length" der (`:201-204`) ama kod yoktur.
     LGUPDB01'in `EIBCALEN = 0` kontrolüne (`:183-187`) LGUPOL01 üzerinden ulaşılamaz.
   - LGUPDB01, LGUPVS01'i `LENGTH(225)` ile çağırır (`lgupdb01.cbl:209-212`). LGUPVS01'de `EIBCALEN` kontrolü yoktur.
3. **İstek kodu `99`'u çağırana ulaşmaz.** LGUPOL01 tanınmayan kodda `'99'` yazar (`lgupol01.cbl:139-140`) ama `RETURN` yapmaz; `PERFORM
   UPDATE-POLICY-DB2-INFO` her durumda çalışır (`:143`). LGUPDB01 başta `CA-RETURN-CODE`'u `'00'` yapar (`lgupdb01.cbl:190`) ve `99` kaybolur.
   LGUPDB01'in istek kodu `EVALUATE`'ında `WHEN OTHER` yoktur (`lgupdb01.cbl:283-300`): tanınmayan kodda tür tablosu (`MOTOR`) güncellenmez, ama
   kod `POLICY` tablosunu güncellemeye devam eder (`:313-326`). Sonra LGUPVS01 çağrılır; VSAM tür harfi `CA-REQUEST-ID`'nin 4. karakterinden gelir
   (`lgupvs01.cbl:102`). İstek kodu karşılaştırması büyük/küçük harfe duyarlıdır (`UPPER-CASE` yok).
4. **LASTCHANGED kontrolü.** Akış (`lgupdb01.cbl:251-360`):
   - `POLICY_CURSOR` müşteri **ve** poliçe numarasıyla açılır (`:128-143`, `:256`) ve ilk satır okunur (`:273`).
   - `CA-LASTCHANGED` (X(26)) ile `DB2-LASTCHANGED` (X(26)) bire bir karşılaştırılır (`:278`).
   - Eşitse sırayla: `MOTOR` UPDATE (`:296-298`), `POLICY` UPDATE (`:318-326`, `LASTCHANGED = CURRENT TIMESTAMP`), yeni zaman damgası
     COMMAREA'ya okunur (`:329-334`).
   - Eşit değilse `'02'` atanır (`:344-346`), hiçbir UPDATE çalışmaz.
   - **`'02'` çağırana ulaşmaz.** `'02'` atandıktan sonra program `PERFORM CLOSE-PCURSOR` (`:360`) çalıştırır. CLOSE başarılıysa (`SQLCODE = 0`)
     `CLOSE-PCURSOR` `CA-RETURN-CODE`'u `'00'` yapar (`:369-371`) ve `'02'` ezilir. Sonra LGUPDB01 yine LGUPVS01'i çağırır
     (`:209-212`; arada `RETURN` yok) ve VSAM kaydı yeni değerlerle yeniden yazılır. Sonuç: çağıran `'00'` görür, Db2 güncellenmemiştir, VSAM
     güncellenmiştir (06-02).
   - Bu, [belge] `docs/srs.md:124-126` ("değiştirilmişse güncellemeyi yapmaz ve bunu bildirir") ile çelişir. Kodun fiilen yaptığı yukarıdaki gibidir.
5. **`CLOSE-PCURSOR` dönüş kodunu ezer.** `CLOSE POLICY_CURSOR` sonrası (`lgupdb01.cbl:365-380`): `SQLCODE = 0` → `'00'`; `-501` → `'00'` ve `RETURN`;
   diğer → `'90'`, hata mesajı, `RETURN`. `PERFORM CLOSE-PCURSOR` iki yerden çağrılır: tür tablosu hatasında (`:305`, ardından `RETURN` `:306`) ve
   akışın sonunda (`:360`). Sonuçları aşağıdaki tabloda:

   | Yol | Atanan kod | `CLOSE` sonrası | LGUPVS01 çağrılır mı | Çağırana ulaşan |
   |---|---|---|---|---|
   | Başarı | `00` (`:261`) | `00` | Evet | `00` (VSAM başarılıysa) |
   | `LASTCHANGED` uyuşmuyor | `02` (`:346`) | `00` | Evet | `00` |
   | `FETCH` `SQLCODE = 100` | `01` (`:352`) | `00` | Evet | VSAM kaydı yoksa ABEND `LGV3`, varsa `00` |
   | `FETCH` diğer SQLCODE | `90` (`:354`) | `00` | Evet | `00` |
   | `MOTOR` UPDATE `SQLCODE = 100` | `01` (`:488`) | `00` | Hayır (`RETURN` `:306`) | `00` |
   | `MOTOR` UPDATE diğer SQLCODE | `90` (`:490`) | `00` | Hayır (`RETURN` `:306`) | `00` |
   | `POLICY` UPDATE hatası, ardından `SELECT` başarılı | — (kod atanmaz) | `00` | Evet | `00` |
   | `SELECT LASTCHANGED` hatası, `CLOSE` `0` | `90` (`:339`) | `00` | Evet | `00` |
   | `SELECT LASTCHANGED` hatası, `CLOSE` `-501` | `90` (`:339`) | `00`, `RETURN` (`:372-375`) | Hayır | `00` |
   | `OPEN` hatası | `90` (`:263`, `:267`) | `CLOSE` çağrılmaz, `RETURN` | Hayır | `90` |
   | `CLOSE` hatası (0 ve -501 dışında) | `90` (`:377`) | `90`, `RETURN` | Hayır | `90` |

6. **`POLICY` UPDATE'inin SQLCODE'u kontrol edilmez.** `UPDATE POLICY ... WHERE CURRENT OF` (`lgupdb01.cbl:318-326`) hemen ardından `SELECT LASTCHANGED`
   gelir ve kontrol edilen yalnızca `SELECT`'in `SQLCODE`'udur (`:329-336`). UPDATE hata verse de `SELECT` başarılıysa hata görünmez.
7. **`CA-PAYMENT` Db2'ye yazılmaz.** `MOVE CA-PAYMENT TO DB2-PAYMENT-INT` yapılır (`lgupdb01.cbl:314`) ama `POLICY` UPDATE'inin `SET` listesinde
   `PAYMENT` yoktur (`:320-324`); imleç de `PAYMENT`'ı seçmez ve "payment ya da commission alanlarını güncellemez" der (`:126-127`, `:130-143`).
   `POLICY` UPDATE'i yalnızca `ISSUEDATE`, `EXPIRYDATE`, `LASTCHANGED`, `BROKERID`, `BROKERSREFERENCE` sütunlarını yazar.
8. **`MOTOR` UPDATE'i dokuz sütunun hepsini yazar** (`lgupdb01.cbl:469-483`): `MAKE`, `MODEL`, `VALUE`, `REGNUMBER`, `COLOUR`, `CC`,
   `YEAROFMANUFACTURE`, `PREMIUM`, `ACCIDENTS`. Kısmi güncelleme yok; boş gönderilen alan Db2'deki değeri boşlukla ezer. Hiçbir alan doğrulanmaz.
9. **Geri alma.** Programlarda tek `SYNCPOINT ROLLBACK` `lgupdb01.cbl:338`'dedir. LGUPVS01 abend ederse (`lgupvs01.cbl:151`, `:164`) önceki Db2 UPDATE'lerinin
   geri alınıp alınmayacağı kodda yazmıyor. [belge] `base/Architecture.md:48`: uygulama müşteri ve poliçe verisini Db2'ye iki aşamalı onayla yazar, başarılıysa
   VSAM'ı günceller. "Db2 geri alınır" diyen satırlar (06-15, 06-16, 06-28) bu belge ifadesine dayanır ve işaretlidir.
10. **VSAM kaydı** (`lgupvs01.cbl:26-52`, `:100-166`).
    - Anahtar 21 bayt: `CA-Request-ID(4:1)` + `CA-Customer-Num` + `CA-Policy-Num` (`:102-104`, `:137`). `'01UMOT'` → `'M'`.
    - `READ ... UPDATE` önce kaydı okur: `INTO(WS-FileIn)` (1024 bayt), `LENGTH(WS-Commarea-Len)` = `EIBCALEN` = 225 (`:54`, `:100`, `:139-146`). Okunan kayıt hiçbir
      satırda kullanılmaz.
    - `REWRITE FROM(WF-Policy-Info) LENGTH(WS-Commarea-LenF)` (`:155-159`); `WS-Commarea-LenF` `VALUE 64` (`:24`). Yazılan 64 bayt: anahtar 21 + marka 15 + model 15
      + değer 6 + plaka 7 (`:48-52`, `:127-131`). `CA-M-COLOUR`, `CA-M-CC`, `CA-M-MANUFACTURED`, `CA-M-PREMIUM`, `CA-M-ACCIDENTS` VSAM'a yazılmaz.
    - Küme `KEYS(21 0)`, `RECORDSIZE(64 64)` [kod] `adef121.jcl:49-50`. Başlangıç verisinde üç motor kaydı: `ksdspoly.txt:8-10`.
    - LGUPVS01'in hata mesajında `EM-POLNUM` hiç doldurulmaz; `' PNUM='` yanında 10 boşluk kalır (`lgupvs01.cbl:182-186`; karşılaştırma: LGDPVS01
      `lgdpvs01.cbl:110`).
11. **Dönüş kodları.**

    | Kod | Nerede | Anlamı | Çağırana ulaşır mı |
    |---|---|---|---|
    | `00` | `lgupol01.cbl:105`, `lgupdb01.cbl:190`, `:261`, `:371`, `:373` | Başlangıç / `OPEN` ve `CLOSE` başarılı | Evet |
    | `01` | `lgupdb01.cbl:352`, `:411`, `:447`, `:488` | Kayıt yok | Hayır: `CLOSE` ezer (Kod gözlemleri 5) |
    | `02` | `lgupdb01.cbl:346` | `LASTCHANGED` uyuşmuyor | Hayır: `CLOSE` ezer (Kod gözlemleri 4) |
    | `90` | `lgupdb01.cbl:263`, `:267`, `:377` | `OPEN` / `CLOSE` hatası | Evet |
    | `90` | `lgupdb01.cbl:339`, `:354`, `:413`, `:449`, `:490` | `SELECT`, `FETCH`, `UPDATE` hatası | Hayır: `CLOSE` ezer |
    | `81` | `lgupvs01.cbl:149` | VSAM `READ` hatası | Alana yazılır, hemen ardından `ABEND LGV3` |
    | `82` | `lgupvs01.cbl:162` | VSAM `REWRITE` hatası | Alana yazılır, hemen ardından `ABEND LGV4` |
    | `98` | `lgupol01.cbl:135` | COMMAREA < 165 (`'01UMOT'`) | Evet |
    | `99` | `lgupol01.cbl:140` | İstek kodu tanınmıyor | Hayır: `lgupdb01.cbl:190` ezer (Kod gözlemleri 3) |
    | ABEND `LGCA` | `lgupol01.cbl:102`, `lgupdb01.cbl:186` | COMMAREA yok | — |
    | ABEND `LGV3` | `lgupvs01.cbl:151` | VSAM `READ` hatası | — |
    | ABEND `LGV4` | `lgupvs01.cbl:164` | VSAM `REWRITE` hatası | — |

    (`lgupdb01.cbl:411`, `:447` `ENDOW` ve `HOUSE` kollarındadır; motor için `:488`.)
12. **Hata mesajı içerikleri.**
    - `ERROR-MSG` uzunlukları: LGUPOL01 45 bayt (`lgupol01.cbl:44-49`), LGUPDB01 87 bayt (`lgupdb01.cbl:39-51`), LGUPVS01 101 bayt (`lgupvs01.cbl:61-76`).
      `CA-ERROR-MSG` üçünde de 99 bayttır: `'COMMAREA='` + 90 bayt.
    - LGUPDB01'de `EM-SQLREQ` değerleri (16 bayta boşlukla tamamlanır): `' OPEN   PCURSOR '` (`:254`), `' FETCH  ROW   '` (`:229`), `' UPDATE MOTOR '` (`:468`),
      `' UPDATE POLICY  '` (`:317`), `' CLOSE  PCURSOR'` (`:364`). `EM-CUSNUM` ← `CA-CUSTOMER-NUM`, `EM-POLNUM` ← `CA-POLICY-NUM` (`:198-199`). `EM-SQLRC`
      `PIC +9(5)` (`:51`, `:504`): `-913` → `-00913`.
    - LGUPVS01'de sabit metin `' Re-write  KSDSPOLY '` (`lgupvs01.cbl:71-72`) **READ hatasında da** kullanılır.
    - LGUPDB01'in `EIBCALEN = 0` mesajı: 21 karakterlik `' NO COMMAREA RECEIVED'`, 63 baytlık `EM-VARIABLE` grubuna taşınır ve sabitleri ezer
      (`lgupdb01.cbl:44-51`, `:184`). Sonra `MOVE SQLCODE TO EM-SQLRC` son 6 baytı ezer (`:504`).
13. **`WRITE-ERROR-MESSAGE` dalları** (`IF EIBCALEN > 0` / `< 91` / `ELSE`) ve **WORKING-STORAGE kalıcılığı.**
    - LGUPOL01'de yalnızca `EIBCALEN = 0` dalından çağrılır (`lgupol01.cbl:101`); iç dallar (`lgupol01.cbl:186-199`) çalışmaz, ölü kod.
    - LGUPDB01 zincirden çağrıldığında `EIBCALEN = 32500`, LGUPVS01 `EIBCALEN = 225` görür; ikisinde de `ELSE` dalı çalışır. `< 91` dallarına
      (`lgupdb01.cbl:521-526`, `lgupvs01.cbl:192-197`) yalnızca doğrudan çağrıyla ulaşılır (06-24, 06-25).
    - `WS-REQUIRED-CA-LEN` (`lgupol01.cbl:63`) `VALUE +0` ve eşik hesabında üstüne eklenir. WORKING-STORAGE yeniden kurulmazsa ikinci çağrıda eşik 330 olur.
      Test düzeneği her durumu ayrı süreçte çalıştırır [belge] `docs/adr/0004-legacy-test-harness.md` (karar 4). Bu dosyadaki tahminler tek çağrı içindir.
      `WS-RETRY` (`lgupdb01.cbl:31`, `:173`) hiçbir yerde kullanılmaz.
14. **Test verisi** (`base/cntl/db2cre.jcl`). Bu değerler yalnızca test veritabanı bu JCL ile yüklendiyse ve sonradan değiştirilmediyse geçerlidir.
    - 06-01'de güncellenen satır poliçe 1 (müşteri 2: `:945-946`, motor 1: `:1105-1114`). Yeni değerler poliçe 3'ün ve motor 3'ün değerleridir
      (`:971-977`, `:1129-1137`). Böylece her girdinin JCL'de bir kaynağı var.
    - `CA-LASTCHANGED` girdisi, `Db2`'deki değerin kendisidir (poliçe 1 için JCL'de `'2011-05-11 17:12:17'`, `:950`). Dönen metnin biçimi belirsiz olduğundan test, bu değeri
      önce `05-01` ile okur ve aynen geri verir.
    - Olmayan poliçe için `0000000999` kullanılır (JCL poliçe numaralarını 1-10 verir, kimlik değeri 1000001'den başlar: `:162-163`). VSAM başlangıç verisinde de yoktur
      (`ksdspoly.txt:1-10`).

## Tahmin tablosu

| Test no | Girdi | Beklenen dönüş kodu | Beklenen veri | Tahminin dayandığı COBOL satırı | Kural türü |
|---|---|---|---|---|---|
| 06-01 | LGUPOL01 çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01UMOT'`. `CA-CUSTOMER-NUM = 0000000002`, `CA-POLICY-NUM = 0000000001` (poliçe 1, müşteri 2). `CA-LASTCHANGED` = Db2'deki değer (önce sorgulanıp aynen geri verilir). Ortak ve motor alanlarında poliçe 3'ün değerleri var (alan alan aşağıdaki **"06-01 girdi ve beklenen değerler"** tablosunda). `KSDSPOLY`'de `M0000000002` + `0000000001` anahtarlı kayıt var [kod] `ksdspoly.txt:8`. [B4] Tüm SQL ve dosya komutları başarılı. | `CA-RETURN-CODE = 00` | `CA-LASTCHANGED` yeni değer olur: güncelleme anındaki zaman damgası, eskisinden farklı (biçimi **belirsiz**). Diğer COMMAREA alanları girdideki gibi kalır.<br>Yan etkiler: `MOTOR`'da poliçe 1'in dokuz sütunu girdideki değerlerle değişir. `POLICY`'de poliçe 1'in `issueDate`, `expiryDate`, `brokerId`, `brokersReference` sütunları değişir ve `lastChanged` güncelleme zamanı olur; `payment`, `customerNumber`, `policyType` değişmez. `KSDSPOLY`'deki kayıt 64 bayt olarak yeniden yazılır. Ayrıntı aşağıda **"06-01'den sonra Db2'de ve VSAM'da beklenen durum"** tablosunda. Hata mesajı yazılmaz. | `lgupol01.cbl:99`, `:105`, `:113`, `:131-137`, `:143`, `:157-160`<br>`lgupdb01.cbl:190`, `:195-196`, `:256-261`, `:273-278`, `:296-298`, `:302`, `:313-334`, `:336`, `:360`, `:369-371`, `:209-216`<br>`lgupvs01.cbl:102-104`, `:127-131`, `:139-159` | İş kuralı |
| 06-02 | 06-01 ile aynı, ama `CA-LASTCHANGED` Db2'deki değerden **farklı**: kayıt, bu istemci sorgulayıp güncellemeden önce başka bir istemci tarafından güncellenmiş (örn. iki istemci poliçe 1'i aynı zaman damgasıyla okur, ilki güncellemeyi bitirir, ikincisi eski zaman damgasıyla güncellemeye çalışır; ya da `CA-LASTCHANGED` boşluk). [B4] `CLOSE` `SQLCODE = 0`. | `CA-RETURN-CODE = 00`. `02` **çağırana ulaşmaz**: `lgupdb01.cbl:346`'da atanır, `CLOSE-PCURSOR` `:371`'de `00` ile ezer (Kod gözlemleri 4, 5). | Db2'de **hiçbir satır değişmez**: `MOTOR` ve `POLICY` UPDATE'leri çalışmaz. `CA-LASTCHANGED` COMMAREA'da girdideki (eski) değerle kalır. Hata mesajı yazılmaz.<br>**VSAM kaydı yine de yeniden yazılır** (LGUPVS01 her durumda çağrılır, `lgupdb01.cbl:209-212`): `KSDSPOLY`'deki kayıt girdideki motor değerleriyle değişir, Db2 değişmez. Db2 ile VSAM tutarsız kalır.<br>[belge] `docs/srs.md:124-126` ve görev tanımı `02` bekler; kod bunu çağırana iletmez. | `lgupdb01.cbl:273-278`, `:344-347`, `:358-360`, `:362-371`, `:209-216`<br>`lgupvs01.cbl:139-159`<br>[belge] `docs/srs.md:124-126` | İş kuralı |
| 06-03 | 06-01 ile aynı, ama `CA-POLICY-NUM = 0000000999` (poliçe Db2'de yok, VSAM'da da yok). [B4] `FETCH` `SQLCODE = 100`, `CLOSE` `0`, VSAM `READ`'de `RESP ≠ NORMAL` (`NOTFND`). | Dönüş kodu yok. LGUPDB01'in yazdığı `01`, `CLOSE`'da `00` ile ezilir; LGUPVS01 `81` yazar ve görev `ABEND` kodu `LGV3` ile (NODUMP) sonlanır. Çağıranın `81`'i görüp görmeyeceği **belirsiz**. | Db2'de hiçbir satır değişmez, VSAM'a yazılmaz. LGUPDB01 hata mesajı yazmaz (`100` dalında yok). **Poliçe bulunamadığında çağıran `01` görmez.**<br>Yan etki: LGUPVS01, `LGSTSQ`'ya iki LINK yapar. (1) `ERROR-MSG` (101 bayt): tarih, saat, `' LGUPVS01'`, `' PNUM='` + 10 boşluk, `' CNUM='` + `0000000002`, `' Re-write  KSDSPOLY '` (READ hatası olduğu halde), `' RESP='` + RESP, `' RESP2='` + RESP2. (2) `CA-ERROR-MSG`: `'COMMAREA='` + gelen 225 baytın ilk 90'ı (`EIBCALEN = 225`, `ELSE` dalı); içinde `81` var. | `lgupdb01.cbl:273-275`, `:349-352`, `:360`, `:369-371`, `:209-212`<br>`lgupvs01.cbl:139-153`, `:174-205` | İş kuralı |
| 06-04 | 06-01 ile aynı, ama `CA-CUSTOMER-NUM = 0000000003` (poliçe 1 müşteri 2'ye ait: `db2cre.jcl:946`). [B4] `CLOSE` `0`, VSAM `READ`'de `RESP ≠ NORMAL` (anahtar `M0000000003` + `0000000001` VSAM'da yok). | 06-03 ile aynı: dönüş kodu yok, `ABEND LGV3`. | 06-03 ile aynı: imleç müşteri numarasını da içerir (`lgupdb01.cbl:136-137`), eşleşen satır yoktur; başka müşterinin poliçesi güncellenemez. `' CNUM='` yanında `0000000003` yazılır. | `lgupdb01.cbl:128-137`, `:349-352`<br>`lgupvs01.cbl:102-104`, `:139-153` | İş kuralı |
| 06-05 | 06-03 ile aynı, ama VSAM'da anahtarı `M0000000002` + `0000000999` olan kayıt var, Db2'de poliçe 999 yok (tutarsız veri; başlangıç verisinde böyle bir durum yok [kod] `ksdspoly.txt:1-10`). [B4] `READ` ve `REWRITE` `NORMAL`. | `CA-RETURN-CODE = 00` | Db2'de hiçbir satır değişmez. **Db2'de poliçe olmadığı halde VSAM kaydı yeni değerlerle yeniden yazılır.** Hata mesajı yazılmaz. | `lgupdb01.cbl:349-352`, `:360`, `:369-371`, `:209-212`<br>`lgupvs01.cbl:139-159` | İş kuralı |
| 06-06 | 06-01 ile aynı, ama [B4] `OPEN POLICY_CURSOR`'da `SQLCODE = -913`. | `CA-RETURN-CODE = 90` | Hiçbir UPDATE çalışmaz, LGUPVS01 çağrılmaz (`RETURN`). `CA-LASTCHANGED` değişmez.<br>Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG` (87 bayt): tarih, saat, `' LGUPDB01'`, `' CNUM='` + `0000000002`, `' PNUM='` + `0000000001`, `' OPEN   PCURSOR '`, `' SQLCODE='` + `-00913`. (2) `CA-ERROR-MSG`: COMMAREA'nın ilk 90 baytı (`EIBCALEN = 32500`, `ELSE` dalı). | `lgupdb01.cbl:254-265`, `:504-532` | İş kuralı |
| 06-07 | 06-01 ile aynı, ama [B4] `OPEN`'da 0 ve -913 dışında bir `SQLCODE` (örn. `-904`). | `CA-RETURN-CODE = 90` | 06-06 ile aynı; `EM-SQLRC` üretilen SQLCODE'dur. | `lgupdb01.cbl:266-269`, `:504-532` | İş kuralı |
| 06-08 | 06-01 ile aynı, ama [B4] `FETCH`'te 0 ve 100 dışında bir `SQLCODE`, `CLOSE` `0`; `READ` ve `REWRITE` `NORMAL`. | `CA-RETURN-CODE = 00`. `FETCH` hatasının `90`'ı `CLOSE`'da ezilir. | Db2'de hiçbir satır değişmez. **VSAM kaydı yeni değerlerle yeniden yazılır.**<br>Yan etki: LGUPDB01, `LGSTSQ`'ya iki LINK yapar. (1) `ERROR-MSG`: 06-06'daki biçimde, `EM-SQLREQ` `' FETCH  ROW   '`. (2) `CA-ERROR-MSG`: COMMAREA'nın ilk 90 baytı. | `lgupdb01.cbl:228-239`, `:349-357`, `:360`, `:369-371`, `:209-212` | İş kuralı |
| 06-09 | 06-01 ile aynı, ama `CA-CUSTOMER-NUM = 0000000008`, `CA-POLICY-NUM = 0000000004` (poliçe 4, müşteri 8'e ait bir hayat sigortası; `MOTOR`'da satırı yok: `db2cre.jcl:849-853`). `CA-LASTCHANGED` poliçe 4'ün Db2'deki değeri. İstek kodu `'01UMOT'`. | `CA-RETURN-CODE = 00`. `MOTOR` UPDATE'inin `01`'i `CLOSE`'da ezilir. | `MOTOR` UPDATE'i `SQLCODE = 100` döner (satır yok). `POLICY` UPDATE'i çalışmaz ve LGUPVS01 çağrılmaz (`RETURN`): Db2 ve VSAM değişmez. **Çağıran `01` görmez; güncelleme hiç yapılmadığı halde `00` döner.** Hata mesajı yazılmaz (`100` dalında yok). | `lgupdb01.cbl:296-298`, `:485-488`, `:302-307`, `:362-371` | İş kuralı |
| 06-10 | 06-01 ile aynı, ama [B4] `MOTOR` UPDATE'inde 0 ve 100 dışında bir `SQLCODE` (örn. `-904`), `CLOSE` `0`. | `CA-RETURN-CODE = 00`. `90` `CLOSE`'da ezilir. | Db2'de `MOTOR` ve `POLICY` değişmez (UPDATE hata verdi, `POLICY` UPDATE'ine geçilmez), VSAM'a yazılmaz (`RETURN`).<br>Yan etki: LGUPDB01, `LGSTSQ`'ya iki LINK yapar. (1) `ERROR-MSG`: 06-06'daki biçimde, `EM-SQLREQ` `' UPDATE MOTOR '` + 2 boşluk. (2) `CA-ERROR-MSG`: COMMAREA'nın ilk 90 baytı. | `lgupdb01.cbl:468-494`, `:302-307`, `:362-371` | İş kuralı |
| 06-11 | 06-01 ile aynı, ama [B4] `POLICY` UPDATE'inde `SQLCODE ≠ 0` (örn. `-904`); sonraki `SELECT LASTCHANGED` başarılı (`0`). | `CA-RETURN-CODE = 00` | `POLICY` UPDATE'inin hatası görülmez: kontrol edilen yalnızca `SELECT`'in `SQLCODE`'udur (Kod gözlemleri 6). `MOTOR` UPDATE'i yapılmıştır; `POLICY` satırı değişmez; `CA-LASTCHANGED` Db2'deki (eski) değerle döner. LGUPVS01 çağrılır, VSAM kaydı yeniden yazılır. Hata mesajı yazılmaz. | `lgupdb01.cbl:318-336`, `:360`, `:209-212` | İş kuralı |
| 06-12 | 06-01 ile aynı, ama [B4] `SELECT LASTCHANGED`'da `SQLCODE ≠ 0` (örn. `-904`); `CLOSE` `0`. | `CA-RETURN-CODE = 00`. `SELECT` hatasının `90`'ı `CLOSE`'da ezilir. | `EXEC CICS SYNCPOINT ROLLBACK` çalışır: o ana kadarki Db2 değişiklikleri (`MOTOR`, `POLICY` UPDATE'leri) geri alınır. Sonra LGUPVS01 çağrılır ve VSAM kaydı yeni değerlerle yeniden yazılır (geri almadan sonra): Db2 eski değerlerde, VSAM yeni değerlerde kalır.<br>Yan etki: LGUPDB01, `LGSTSQ`'ya iki LINK yapar. (1) `ERROR-MSG`: `EM-SQLREQ` `' UPDATE POLICY  '`. (2) `CA-ERROR-MSG`: COMMAREA'nın ilk 90 baytı. | `lgupdb01.cbl:329-342`, `:360`, `:369-371`, `:209-212` | İş kuralı |
| 06-13 | 06-12 ile aynı, ama [B4] `CLOSE` `SQLCODE = -501` (imleç `ROLLBACK` ile kapanmıştır). | `CA-RETURN-CODE = 00` | 06-12'deki geri alma geçerlidir. `CLOSE-PCURSOR` `-501` dalında `00` yazar ve `RETURN` yapar: LGUPVS01 çağrılmaz, VSAM'a yazılmaz. Db2 ve VSAM eski değerlerinde kalır. | `lgupdb01.cbl:329-342`, `:360`, `:372-375` | İş kuralı |
| 06-14 | 06-01 ile aynı, ama [B4] `CLOSE`'da 0 ve -501 dışında bir `SQLCODE` (örn. `-904`). | `CA-RETURN-CODE = 90` | `MOTOR` ve `POLICY` UPDATE'leri `CLOSE`'dan önce yapıldığı için Db2'de değişiklik vardır ve kodda geri alma yoktur. LGUPVS01 çağrılmaz (`RETURN`): VSAM değişmez, Db2 ile VSAM tutarsız kalır.<br>Yan etki: LGUPDB01, `LGSTSQ`'ya iki LINK yapar. (1) `ERROR-MSG`: `EM-SQLREQ` `' CLOSE  PCURSOR'` + 1 boşluk. (2) `CA-ERROR-MSG`: COMMAREA'nın ilk 90 baytı. | `lgupdb01.cbl:360`, `:376-379`, `:364` | İş kuralı |
| 06-15 | 06-01 ile aynı, ama [B4] VSAM `READ`'de `RESP ≠ NORMAL` (kayıt yok; örn. `KSDSPOLY`'den `M0000000002` + `0000000001` silinmiş). | Dönüş kodu yok. `CA-RETURN-CODE`'a `81` yazılır, ardından görev `ABEND` kodu `LGV3` ile (NODUMP) sonlanır. Çağıranın `81`'i görüp görmeyeceği **belirsiz**. | Db2 UPDATE'leri önceden çalıştı; abend olduğu için **geri alınır** ve poliçe 1 eski değerlerinde kalır (`db2cre.jcl:945-953`, `:1105-1114`) [belge, kodda doğrulanmadı] `base/Architecture.md:48` (Kod gözlemleri 9). VSAM'a yazılmaz.<br>Yan etki: LGUPVS01'in iki mesajı (06-03'teki gibi, `' CNUM='` + `0000000002`). | `lgupdb01.cbl:209-212`<br>`lgupvs01.cbl:139-153`<br>[belge] `base/Architecture.md:48` | İş kuralı |
| 06-16 | 06-01 ile aynı, ama [B4] VSAM `READ` `NORMAL`, `REWRITE`'ta `RESP ≠ NORMAL`. | Dönüş kodu yok. `CA-RETURN-CODE`'a `82` yazılır, ardından görev `ABEND` kodu `LGV4` ile (NODUMP) sonlanır. Çağıranın `82`'yi görüp görmeyeceği **belirsiz**. | Db2 UPDATE'leri ve VSAM kaydı **geri alınır**: poliçe 1 eski değerlerinde, VSAM kaydı başlangıç halinde (`ksdspoly.txt:8`) kalır [belge, kodda doğrulanmadı] `base/Architecture.md:48`. VSAM kümesi geri alınabilir tanımlı ([kod] `adef121.jcl:45`, `LOG(UNDO)`).<br>Yan etki: LGUPVS01'in iki mesajı. Metin yine `' Re-write  KSDSPOLY '`; `RESP` ve `RESP2` REWRITE'ınki. İkinci mesajda `82` var. | `lgupvs01.cbl:155-166`, `:174-205`<br>`adef121.jcl:45`<br>[belge] `base/Architecture.md:48` | İş kuralı |
| 06-17 | LGUPOL01 çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01XMOT'` (tanınmayan kod; 4. karakter `M`). Diğer girdiler 06-01 ile aynı. [B4] Tüm SQL ve dosya komutları başarılı. | `CA-RETURN-CODE = 00`. LGUPOL01'in `99`'u LGUPDB01'de `00` ile ezilir. | `POLICY` satırı güncellenir (`issueDate`, `expiryDate`, `brokerId`, `brokersReference`, `lastChanged`); **`MOTOR` satırı güncellenmez** (`EVALUATE`'ta eşleşme yok). VSAM kaydı anahtar harfi `M` olduğu için bulunur ve girdideki motor değerleriyle yeniden yazılır. `CA-LASTCHANGED` yeni zaman damgası olur. Hata mesajı yazılmaz. LGUPOL01 uzunluk kontrolü bu kodda yapılmaz. | `lgupol01.cbl:113`, `:139-140`, `:143`<br>`lgupdb01.cbl:190`, `:278`, `:283-300`, `:302`, `:313-334`, `:360`<br>`lgupvs01.cbl:102`, `:127-131`, `:139-159` | Arayüz (COMMAREA) kuralı |
| 06-18 | 06-17 ile aynı, ama `CA-REQUEST-ID = '01UXXX'` (4. karakter `X`). [B4] `READ`'de `RESP ≠ NORMAL`. | Dönüş kodu yok. `CA-RETURN-CODE`'a `81` yazılır, ardından görev `ABEND` kodu `LGV3` ile (NODUMP) sonlanır. Çağıranın `81`'i görüp görmeyeceği **belirsiz**. | LGUPVS01 anahtar harfi `X` ile kayıt arar; `WHEN OTHER` dalı `WF-Policy-Data`'yı boşluk yapar (`lgupvs01.cbl:133-134`). `X` anahtarlı kayıt VSAM'da yok. `POLICY` UPDATE'i abend öncesi yapılmıştır; abend ile geri alınması [belge, kodda doğrulanmadı] `base/Architecture.md:48`. Yan etki: LGUPVS01'in iki mesajı. | `lgupol01.cbl:139-143`<br>`lgupdb01.cbl:190`, `:283-300`, `:313-326`<br>`lgupvs01.cbl:102`, `:133-134`, `:139-153` | Arayüz (COMMAREA) kuralı |
| 06-19 | LGUPOL01 COMMAREA'sız çağrılır (`EIBCALEN = 0`). | Dönüş kodu yok. Görev `ABEND` kodu `LGCA` ile (NODUMP) sonlanır. | COMMAREA olmadığı için veri dönmez. LGUPDB01 çağrılmaz.<br>Yan etki: `LGSTSQ`'ya tek LINK yapılır: 45 baytlık `ERROR-MSG` (tarih, saat, `' LGUPOL01'`, `' NO COMMAREA RECEIVED'`). COMMAREA dökümü gönderilmez (`EIBCALEN > 0` sağlanmaz). | `lgupol01.cbl:99-103`, `:44-49`, `:169-186` | Arayüz (COMMAREA) kuralı |
| 06-20 | LGUPOL01 çağrılır. `EIBCALEN` 8 ile 164 arasında (sınır değer: `164`). `CA-REQUEST-ID = '01UMOT'` (istek kodu ve dönüş kodu COMMAREA'nın içinde). | `CA-RETURN-CODE = 98` | LGUPDB01 ve LGUPVS01 çağrılmaz, hiçbir tablo değişmez, hata mesajı yazılmaz (`lgupol01.cbl:134-137` arasında `WRITE-ERROR-MESSAGE` yok). | `lgupol01.cbl:105`, `:131-137`<br>`lgupol01.cbl:41`, `:62` | Arayüz (COMMAREA) kuralı |
| 06-21 | LGUPOL01 çağrılır. `EIBCALEN` 6 ile 7 arasında. `CA-REQUEST-ID = '01UMOT'` (tamamı içeride). | [B1] Tamponun 7-8. baytları `98` olur (ön koşullu) [kod] `lgupol01.cbl:135`. | Kod `98`'i yazıp `RETURN` yapar. `CA-RETURN-CODE` 7-8. baytlarda olduğu için gelen COMMAREA'nın dışında kalır (7'de yarısı) ve B1 ile çağıranın tamponuna düşer. LGUPDB01 çağrılmaz, hata mesajı yazılmaz.<br>`EIBCALEN` 1 ile 5 arasında istek kodu kısmen COMMAREA dışındadır; sonuç **belirsiz** (B1 ile boşluk okunur ve 06-17 yoluna benzer). | `lgcmarea.cpy:10-11`<br>`lgupol01.cbl:113`, `:131-137` | Arayüz (COMMAREA) kuralı |
| 06-22 | LGUPOL01 çağrılır. `EIBCALEN = 165` (kabul edilen en küçük uzunluk). `CA-REQUEST-ID = '01UMOT'`, `CA-LASTCHANGED` Db2'deki değer. | `98` **dönmez**. Asıl dönüş kodu **belirsiz**. | Uzunluk kontrolü geçilir (`165 < 165` yanlış). `CA-M-PREMIUM` (166-171) ve `CA-M-ACCIDENTS` (172-177) COMMAREA'nın dışında kalır ve `MOTOR` UPDATE'inde okunur (Kod gözlemleri 2). [B1] İkisi de boşluk olur. Boşluk içeren sayısal alanın `MOVE` sonucu ve UPDATE'in kabul edilip edilmeyeceği kodda ve Db2'de yazmıyor. | `lgupol01.cbl:131-137`<br>`lgupdb01.cbl:465-466`, `:479-480`<br>`lgcmarea.cpy:73-74` | Arayüz (COMMAREA) kuralı |
| 06-23 | **LGUPDB01 doğrudan** COMMAREA'sız çağrılır (`EIBCALEN = 0`). [B2] `SQLCODE = 0`. | Dönüş kodu yok. Görev `ABEND` kodu `LGCA` ile (NODUMP) sonlanır. | SQL çalışmaz, LGUPVS01 çağrılmaz.<br>Yan etki: `LGSTSQ`'ya tek LINK yapılır: 87 baytlık `ERROR-MSG`. İçeriği: tarih, saat, `' LGUPDB01'`, `' NO COMMAREA RECEIVED'` + 36 boşluk + 6 baytlık `EM-SQLRC`. Taşıma 63 baytlık `EM-VARIABLE` grubunun tamamını ezdiği için `' CNUM='`, `' PNUM='`, `' SQLCODE='` sabitleri mesajda yer almaz. [B2] `EM-SQLRC = +00000` [kod] `lgupdb01.cbl:504`. COMMAREA dökümü gönderilmez.<br>LGUPOL01 üzerinden bu yola ulaşılamaz (Kod gözlemleri 2). | `lgupdb01.cbl:183-187`, `:44-51`, `:502-520` | Arayüz (COMMAREA) kuralı |
| 06-24 | **LGUPDB01 doğrudan** çağrılır. `EIBCALEN` 28 ile 90 arasında (örn. 50). `CA-REQUEST-ID = '01UMOT'`, `CA-LASTCHANGED` (49-74. baytlar) kısmen COMMAREA dışında. [B4] `OPEN`'da `SQLCODE = -913`. | `CA-RETURN-CODE = 90` | LGUPDB01'de uzunluk kontrolü yok; `98` dönmez. Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG`: 06-06 ile aynı. (2) `EIBCALEN < 91` dalı: `'COMMAREA='` + `DFHCOMMAREA(1:EIBCALEN)`, `CA-DATA`'nın kalanı boşluk. Bu dala yalnızca bu yolla ulaşılır.<br>`OPEN` başarılı olsaydı sonuç **belirsiz** olurdu: `CA-LASTCHANGED`, `CA-ISSUE-DATE` vb. COMMAREA dışından okunur. | `lgupdb01.cbl:254-265`, `:520-526`<br>`lgupdb01.cbl:63-65`, `:201-204` | Arayüz (COMMAREA) kuralı |
| 06-25 | **LGUPVS01 doğrudan** çağrılır. `EIBCALEN` 28 ile 90 arasında (anahtardaki müşteri ve poliçe numaraları 9-28. baytlarda, içeride kalır). `CA-REQUEST-ID = '01UMOT'`. [B4] `READ`'de `RESP ≠ NORMAL`. | Dönüş kodu yok. `CA-RETURN-CODE`'a `81` yazılır, ardından görev `ABEND` kodu `LGV3` ile (NODUMP) sonlanır (06-03 ile aynı belirsizlik). | Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG`: 06-03'teki gibi. (2) `EIBCALEN < 91` dalı: `'COMMAREA='` + `DFHCOMMAREA(1:EIBCALEN)`. Bu dala yalnızca bu yolla ulaşılır. | `lgupvs01.cbl:100-104`, `:139-153`, `:191-197` | Arayüz (COMMAREA) kuralı |
| 06-26 | **LGUPVS01 doğrudan** COMMAREA'sız çağrılır (`EIBCALEN = 0`). | **belirsiz** | **belirsiz**. LGUPVS01'de `EIBCALEN` kontrolü yok. `READ`, var olmayan COMMAREA'daki alanları anahtar olarak kullanır. Sonuç kodda tanımlı değil. | `lgupvs01.cbl:100-104`, `:139-146` | Arayüz (COMMAREA) kuralı |
| 06-27 | 06-01 ile aynı, ama `CA-PAYMENT = 000123` (Db2'deki değer 0: `db2cre.jcl:953`). | `CA-RETURN-CODE = 00` | `POLICY.payment` **0 olarak kalır**: `PAYMENT` UPDATE'in `SET` listesinde yok. Diğer alanlar 06-01 gibi güncellenir. Sonraki bir sorgulama (`05`) `CA-PAYMENT = 000000` döndürür. | `lgupdb01.cbl:314`, `:320-324`, `:126-143` | İş kuralı |
| 06-28 | 06-01 ile aynı, ama `CA-CUSTOMER-NUM = 1000000002` (10 haneli). [B3] [B4] `READ`'de `RESP ≠ NORMAL` (`1000000002` anahtarlı kayıt VSAM'da yok). | [B3] Dönüş kodu yok (ön koşullu): `CA-RETURN-CODE`'a `81` yazılır, ardından görev `ABEND` kodu `LGV3` ile (NODUMP) sonlanır [kod] `lgupvs01.cbl:149-151`. Çağıranın `81`'i görüp görmeyeceği **belirsiz**. | [B3] `PIC 9(10)` → `PIC S9(9) COMP` taşımasında en soldaki hane kesilir ve `DB2-CUSTOMERNUM-INT = 2` olur: Db2'de **müşteri 2'nin poliçe 1'i** güncellenir (UPDATE'ler başarılı) [kod] `lgcmarea.cpy:12`, `lgupdb01.cbl:87`, `:195`. VSAM ise 10 haneli `1000000002`'yi kesilmeden kullanır [kod] `lgupvs01.cbl:104`, bu anahtar VSAM'da yok. Db2 güncellemeleri abend yüzünden **geri alınır** [belge, kodda doğrulanmadı] `base/Architecture.md:48`.<br>B3 sağlanmazsa sonuç **belirsiz**. | `lgcmarea.cpy:12`<br>`lgupdb01.cbl:87`, `:195`<br>`lgupvs01.cbl:104`, `:139-153`<br>`cobol.jcl:44-50`, `ksdspoly.txt:8-10`<br>[belge] `base/Architecture.md:48` | Arayüz (COMMAREA) kuralı |
| 06-29 | 06-01 ile aynı, ama `CA-CUSTOMER-NUM` ya da `CA-POLICY-NUM` sayısal değil (örn. boşluk). | **belirsiz** | **belirsiz**. Hiçbir programda sayısallık kontrolü yok. Değer doğrudan `DB2-CUSTOMERNUM-INT`/`DB2-POLICYNUM-INT`'e taşınır ve VSAM anahtarı olarak da kullanılır. | `lgupdb01.cbl:195-196`<br>`lgupvs01.cbl:103-104` | Arayüz (COMMAREA) kuralı |
| 06-30 | 06-01 ile aynı. LGUPDB01'e ya da LGUPVS01'e yapılan LINK başarısız olur. | **belirsiz** | **belirsiz**. İki LINK'te de `RESP`/`NOHANDLE` yok, programlarda `HANDLE CONDITION` da yok. Sonuç CICS'in varsayılan davranışına bağlı ve kodda yazmıyor. | `lgupol01.cbl:157-160`<br>`lgupdb01.cbl:209-212` | Arayüz (COMMAREA) kuralı |

## 06-01 girdi ve beklenen değerler

Poliçe 1 (müşteri 2), poliçe 3'ün ve motor 3'ün değerleriyle güncellenir. "␣×n" sağdaki n adet boşluğu gösterir.

| COMMAREA alanı | Girdi | Girdinin kaynağı (`db2cre.jcl`) | Dönüşte beklenen | Alanı kullanan COBOL satırı |
|---|---|---|---|---|
| `CA-REQUEST-ID` X(6) | `01UMOT` | — (değer koddan: `lgupdb01.cbl:296`) | Değişmez | `lgupol01.cbl:131`, `lgupdb01.cbl:283`, `:296` |
| `CA-RETURN-CODE` 9(2) | Herhangi bir değer | — | `00` | `lgupol01.cbl:105`, `lgupdb01.cbl:190`, `:261`, `:371` |
| `CA-CUSTOMER-NUM` 9(10) | `0000000002` | `:946` | Değişmez | `lgupdb01.cbl:195` |
| `CA-POLICY-NUM` 9(10) | `0000000001` | `:945` | Değişmez | `lgupdb01.cbl:196` |
| `CA-ISSUE-DATE` X(10) | `2011-09-08` | `:971` | Değişmez | `lgupdb01.cbl:320` |
| `CA-EXPIRY-DATE` X(10) | `2012-09-07` | `:972` | Değişmez | `lgupdb01.cbl:321` |
| `CA-LASTCHANGED` X(26) | Db2'deki değer (poliçe 1: `2011-05-11 17:12:17`, `:950`; biçim **belirsiz**) | `:950` | Yeni zaman damgası (eskisinden farklı; biçim **belirsiz**) | `lgupdb01.cbl:278`, `:322`, `:329-334` |
| `CA-BROKERID` 9(10) | `0000000000` | `:975` | Değişmez | `lgupdb01.cbl:313`, `:323` |
| `CA-BROKERSREF` X(10) | ␣×10 (JCL'de `''`) | `:976` | Değişmez | `lgupdb01.cbl:324` |
| `CA-PAYMENT` 9(6) | `000000` | `:977` | Değişmez (Db2'ye yazılmaz) | `lgupdb01.cbl:314` |
| `CA-M-MAKE` X(15) | `DENNIS` + ␣×9 | `:1129` (sütun `CHAR(15)`: `:277`) | Değişmez | `lgupdb01.cbl:472`, `lgupvs01.cbl:128` |
| `CA-M-MODEL` X(15) | `ENGINE` + ␣×9 | `:1130` (sütun `CHAR(15)`: `:278`) | Değişmez | `lgupdb01.cbl:473`, `lgupvs01.cbl:129` |
| `CA-M-VALUE` 9(6) | `023500` | `:1131` | Değişmez | `lgupdb01.cbl:464`, `:474`, `lgupvs01.cbl:130` |
| `CA-M-REGNUMBER` X(7) | `FIRE1` + ␣×2 | `:1132` (sütun `CHAR(7)`: `:280`) | Değişmez | `lgupdb01.cbl:475`, `lgupvs01.cbl:131` |
| `CA-M-COLOUR` X(8) | `RED` + ␣×5 | `:1133` (sütun `CHAR(8)`: `:281`) | Değişmez | `lgupdb01.cbl:476` |
| `CA-M-CC` 9(4) | `5000` | `:1134` | Değişmez | `lgupdb01.cbl:463`, `:477` |
| `CA-M-MANUFACTURED` X(10) | `1973-05-13` | `:1135` | Değişmez | `lgupdb01.cbl:478` |
| `CA-M-PREMIUM` 9(6) | `002850` | `:1136` | Değişmez | `lgupdb01.cbl:465`, `:479` |
| `CA-M-ACCIDENTS` 9(6) | `000012` | `:1137` | Değişmez | `lgupdb01.cbl:466`, `:480` |
| `CA-M-FILLER` X(32323) | Herhangi bir değer | — | Değişmez | Kodda okunmuyor, yazılmıyor |

## 06-01'den sonra Db2'de ve VSAM'da beklenen durum

| Hedef | Beklenen | COBOL satırı |
|---|---|---|
| `POLICY` | Poliçe 1'in satırı: `policyNumber` = 1 ve `customerNumber` = 2 (değişmez), `issueDate` = 2011-09-08, `expiryDate` = 2012-09-07, `policyType` = `M` (değişmez), `lastChanged` = güncelleme anındaki zaman damgası, `brokerId` = 0, `brokersReference` = boşluk, `payment` = 0 (değişmez). Önceki `issueDate`/`expiryDate` değerleri (`db2cre.jcl:947-948`) kalmaz. Diğer poliçelerin satırları değişmez. | `lgupdb01.cbl:318-326` |
| `MOTOR` | Poliçe 1'in satırı: `make` = `DENNIS`, `model` = `ENGINE`, `value` = 23500, `regNumber` = `FIRE1`, `colour` = `RED`, `cc` = 5000, `yearOfManufacture` = 1973-05-13, `premium` = 2850, `accidents` = 12. Önceki değerler (`db2cre.jcl:1106-1114`) kalmaz. Motor 3 ve 2'nin satırları değişmez. | `lgupdb01.cbl:469-483` |
| `KSDSPOLY` | Anahtarı `M0000000002` + `0000000001` olan kayıt 64 bayt ile yeniden yazılır: `M` + `0000000002` + `0000000001` + `DENNIS` + ␣×9 + `ENGINE` + ␣×9 + `023500` + `FIRE1` + ␣×2. Kaydın başlangıç hali (`ksdspoly.txt:8`) tamamen ezilir. Diğer kayıtlar değişmez. | `lgupvs01.cbl:102-104`, `:127-131`, `:155-159` |
| `CUSTOMER` | Değişmez. Güncelleme zincirinde müşteri tablosuna giden SQL yok. | `lgupdb01.cbl:318-334`, `:469-483` |

## Kapsam tablosu

Koddaki her `IF`/`EVALUATE` dalının ve dönüş kodunun, onu kapsayan test numaraları.

| Envanter no | Madde | Test no | Not |
|---|---|---|---|
| UO-01 | `lgupol01.cbl:99-103` `IF EIBCALEN = 0` → ABEND `LGCA` | 06-19 | |
| UO-02 | `lgupol01.cbl:105` `'00'` → `CA-RETURN-CODE` | 06-01, 06-20, 06-21 | |
| UO-03 | `lgupol01.cbl:113-141` `EVALUATE CA-REQUEST-ID` | 06-01 (`WHEN '01UMOT'`), 06-17, 06-18 (`WHEN OTHER`) | `'01UEND'`, `'01UHOU'` kolları kapsam dışı |
| UO-04 | `lgupol01.cbl:131-137` `IF EIBCALEN < 165` → `98` | 06-20, 06-21 (doğru dal); 06-01, 06-22 (yanlış dal) | |
| UO-05 | `lgupol01.cbl:139-140` `WHEN OTHER` → `99`; `RETURN` yok | 06-17, 06-18 | `99` çağırana ulaşmaz (Kod gözlemleri 3) |
| UO-06 | `lgupol01.cbl:143`, `:157-160` LINK LGUPDB01 `LENGTH(32500)`, RETURN | 06-01, 06-30 | |
| UO-07 | `lgupol01.cbl:169-201` `WRITE-ERROR-MESSAGE` | 06-19 | Dış `IF EIBCALEN > 0` yanlış. İç dallar (`lgupol01.cbl:186-199`) ölü kod (Kod gözlemleri 13) |
| UD-01 | `lgupdb01.cbl:183-187` `IF EIBCALEN = 0` → ABEND `LGCA` | 06-23 | Yalnızca doğrudan çağrı |
| UD-02 | `lgupdb01.cbl:190` `'00'` (`99`'u ezer) | 06-01, 06-17 | |
| UD-03 | `lgupdb01.cbl:195-199` `CA-CUSTOMER-NUM`, `CA-POLICY-NUM` → host değişkenleri, `EM-*` | 06-01, 06-28, 06-29 | |
| UD-04 | `lgupdb01.cbl:201-204` uzunluk kontrolü yok | 06-22, 06-24 | |
| UD-05 | `lgupdb01.cbl:254-270` `OPEN`, `EVALUATE SQLCODE` | 06-01 (`0`), 06-06 (`-913`), 06-07 (diğer) | |
| UD-06 | `lgupdb01.cbl:273`, `:228-239` `FETCH` | 06-01, 06-03, 06-08 | |
| UD-07 | `lgupdb01.cbl:275` `IF SQLCODE = 0` | 06-01 (doğru dal), 06-03, 06-08 (yanlış dal) | |
| UD-08 | `lgupdb01.cbl:278` `IF CA-LASTCHANGED EQUAL TO DB2-LASTCHANGED` | 06-01 (doğru dal), 06-02 (yanlış dal) | |
| UD-09 | `lgupdb01.cbl:283-300` `EVALUATE CA-REQUEST-ID` | 06-01 (`WHEN '01UMOT'`), 06-17, 06-18 (eşleşme yok) | `WHEN OTHER` yok. `'01UEND'`, `'01UHOU'` kolları kapsam dışı |
| UD-10 | `lgupdb01.cbl:302-307` `IF CA-RETURN-CODE NOT EQUAL '00'` | 06-09, 06-10 (doğru dal); 06-01 (yanlış dal) | |
| UD-11 | `lgupdb01.cbl:313-326` `POLICY` UPDATE | 06-01, 06-11, 06-27 | |
| UD-12 | `lgupdb01.cbl:329-334` `SELECT LASTCHANGED` | 06-01, 06-12 | |
| UD-13 | `lgupdb01.cbl:336-342` `IF SQLCODE NOT EQUAL 0` → `ROLLBACK`, `90`, mesaj | 06-12, 06-13 (doğru dal); 06-01 (yanlış dal) | |
| UD-14 | `lgupdb01.cbl:344-346` `ELSE` → `02` | 06-02 | `02` çağırana ulaşmaz (Kod gözlemleri 4) |
| UD-15 | `lgupdb01.cbl:349-357` `FETCH` `ELSE`: `100` → `01`, diğer → `90` + mesaj | 06-03, 06-04, 06-05 (`100`); 06-08 (diğer) | |
| UD-16 | `lgupdb01.cbl:360-380` `CLOSE-PCURSOR`: `0`, `-501`, diğer | 06-01 (`0`), 06-13 (`-501`), 06-14 (diğer) | |
| UD-17 | `lgupdb01.cbl:460-495` `UPDATE-MOTOR-DB2-INFO`: başarı, `100`, diğer | 06-01 (başarı), 06-09 (`100`), 06-10 (diğer) | |
| UD-18 | `lgupdb01.cbl:209-216` LINK LGUPVS01 `LENGTH(225)`, RETURN | 06-01, 06-30 | |
| UD-19 | `lgupdb01.cbl:502-535` `WRITE-ERROR-MESSAGE` | 06-06 (`ELSE`), 06-24 (`< 91`), 06-23 (dış `IF` yanlış) | |
| UV-01 | `lgupvs01.cbl:100-104`, `:137` anahtar kurma | 06-01, 06-28, 06-29 | |
| UV-02 | `lgupvs01.cbl:106-135` `EVALUATE WF-Request-ID` | 06-01 (`WHEN 'M'`), 06-18 (`WHEN OTHER`) | `C`, `E`, `H` kolları kapsam dışı |
| UV-03 | `lgupvs01.cbl:139-153` `READ ... UPDATE`; `RESP ≠ NORMAL` → `81` + ABEND `LGV3` | 06-03, 06-04, 06-15, 06-18, 06-25, 06-28 (doğru dal); 06-01 (yanlış dal) | |
| UV-04 | `lgupvs01.cbl:155-166` `REWRITE`; `RESP ≠ NORMAL` → `82` + ABEND `LGV4` | 06-16 (doğru dal); 06-01 (yanlış dal) | |
| UV-05 | `lgupvs01.cbl:174-206` `WRITE-ERROR-MESSAGE` | 06-03 (`ELSE`), 06-25 (`< 91`) | `EIBCALEN = 0` dalı: LGUPVS01'de `EIBCALEN` kontrolü yok (06-26) |
| SQ-01 | `lgstsq.cbl:68-71` LINK yolu | 06-03, 06-06, 06-07, 06-08, 06-10, 06-12, 06-14, 06-15, 06-16, 06-19, 06-23 … 06-25 | |
| SQ-02 | `lgstsq.cbl:72-80` terminalden RECEIVE | — | **Kapsam dışı: bu zincirden ulaşılamaz.** LGSTSQ yalnızca LINK ile çağrılır. |
| SQ-03 | `lgstsq.cbl:94-111` WRITEQ TD `CSMT`, TS `GENAERRS` | 06-03, 06-06 | |
| N-01 | `LASTCHANGED` kontrolü: `02` ezilir, VSAM yine yazılır | 06-02 | Kod gözlemleri 4 |
| N-02 | `CLOSE-PCURSOR` `01`, `90` kodlarını ezer | 06-08, 06-09, 06-10, 06-12 | Kod gözlemleri 5 |
| N-03 | Db2 ile VSAM tutarsız kalabilir | 06-02, 06-05, 06-08, 06-12, 06-14 | |
| N-04 | `POLICY` UPDATE'inin `SQLCODE`'u kontrol edilmez | 06-11 | Kod gözlemleri 6 |
| N-05 | `PAYMENT` Db2'ye yazılmaz | 06-27 | Kod gözlemleri 7 |
| N-06 | Tanınmayan istek kodunda `POLICY` yine güncellenir | 06-17, 06-18 | Kod gözlemleri 3 |
| N-07 | Uzunluk kontrolü yalnızca LGUPOL01'de | 06-22, 06-24 | Kod gözlemleri 2 |
| N-08 | `CA-CUSTOMER-NUM` kesilmesi (B3) | 06-28 | |
| N-09 | LINK'te `RESP` yok | 06-30 | |

## Ön koşullu satırlar

Ön koşul kodları dosyanın başında ("Kaynak etiketleri ve ön koşul kodları").

| Test no | Ön koşul | Ön koşulla tahmin | Ön koşul sağlanmazsa |
|---|---|---|---|
| 06-01 | B4 | Başarı yolu | Girdi kurulamaz |
| 06-02 | B4 | `CLOSE` `SQLCODE = 0`; tahmin (`00`) değişmez | `CLOSE` başarısızsa dönüş kodu `90` ya da `00` (`-501`) olabilir; `02` yine ulaşmaz |
| 06-03 | B4 | Girdi düzenekle kurulur; tahmin (`81` + ABEND `LGV3`) değişmez | Girdi kurulamaz |
| 06-04 | B4 | Girdi düzenekle kurulur; tahmin (`81` + ABEND `LGV3`) değişmez | Girdi kurulamaz |
| 06-05 | B4 | VSAM'a Db2'de olmayan kayıt eklenir; tahmin (`00`) değişmez | Girdi kurulamaz: başlangıç verisinde böyle bir durum yok |
| 06-06 | B4 | Girdi düzenekle kurulur; tahmin (`90`) değişmez | Girdi kurulamaz |
| 06-07 | B4 | Girdi düzenekle kurulur; tahmin (`90`) değişmez | Girdi kurulamaz |
| 06-08 | B4 | Girdi düzenekle kurulur; tahmin (`00`) değişmez | Girdi kurulamaz |
| 06-10 | B4 | Girdi düzenekle kurulur; tahmin (`00`) değişmez | Girdi kurulamaz |
| 06-11 | B4 | Girdi düzenekle kurulur; tahmin (`00`) değişmez | Girdi kurulamaz |
| 06-12 | B4 | Girdi düzenekle kurulur; tahmin (`00`) değişmez | Girdi kurulamaz |
| 06-13 | B4 | `CLOSE` `-501` düzenekle kurulur; tahmin (`00`, VSAM yazılmaz) değişmez | Girdi kurulamaz |
| 06-14 | B4 | Girdi düzenekle kurulur; tahmin (`90`) değişmez | Girdi kurulamaz |
| 06-15 | B4 | Girdi düzenekle kurulur (VSAM'dan poliçe 1'in kaydı silinir); tahmin (`81` + ABEND `LGV3`) değişmez | Girdi kurulamaz: başlangıç verisinde VSAM kaydı var |
| 06-16 | B4 | Girdi düzenekle kurulur; tahmin (`82` + ABEND `LGV4`) değişmez | Girdi kurulamaz |
| 06-17 | B4 | Başarı yolu; tahmin (`00`, yalnızca `POLICY` güncellenir) değişmez | Girdi kurulamaz |
| 06-18 | B4 | Girdi düzenekle kurulur; tahmin (`81` + ABEND `LGV3`) değişmez | Girdi kurulamaz |
| 06-21 | B1 | Tamponun 7-8. baytları `98` | Dönüş kodu belirsiz |
| 06-22 | B1 | `CA-M-PREMIUM`, `CA-M-ACCIDENTS` boşluk olarak okunur | Okunan değerler belirsiz |
| 06-23 | B2 | `EM-SQLRC = +00000` | `EM-SQLRC` belirsiz |
| 06-24 | B4 | Girdi düzenekle kurulur; tahmin (`90`, `< 91` dalı) değişmez | Girdi kurulamaz |
| 06-25 | B4 | Girdi düzenekle kurulur; tahmin (`81` + ABEND `LGV3`, `< 91` dalı) değişmez | Girdi kurulamaz |
| 06-28 | B3, B4 | Db2'de müşteri 2'nin poliçe 1'i güncellenir; VSAM `READ` başarısız olur → `81` + ABEND `LGV3`; Db2 güncellemesi geri alınır ([belge]) | Dönüş kodu ve veri belirsiz |

## Belirsiz satırlar

| Test no | Belirsiz olan hücre | Neden belirsiz |
|---|---|---|
| 06-01 | Beklenen veri (yalnızca `CA-LASTCHANGED` biçimi) | `lastChanged` sütunu `TIMESTAMP` türünde (`db2cre.jcl:168`) ve doğrudan `PIC X(26)` alana okunuyor (`lgupdb01.cbl:234`, `:329-334`). Okunurken hangi biçimde geleceği Db2 ayarına bağlı ve kodda yazmıyor. |
| 06-03 | Dönüş kodu (çağıranın `81`'i görmesi) | `81` yazıldıktan hemen sonra `ABEND LGV3` geliyor (`lgupvs01.cbl:149-151`) ve zincirde abend yakalama yok. |
| 06-04 | Dönüş kodu (çağıranın `81`'i görmesi) | 06-03 ile aynı neden. |
| 06-15 | Dönüş kodu (çağıranın `81`'i görmesi) | 06-03 ile aynı neden. |
| 06-16 | Dönüş kodu (çağıranın `82`'yi görmesi) | 06-03 ile aynı neden (`lgupvs01.cbl:162-164`). |
| 06-18 | Dönüş kodu (çağıranın `81`'i görmesi) | 06-03 ile aynı neden. |
| 06-21 | Dönüş kodu (`EIBCALEN` 1-5) | İstek kodu kısmen COMMAREA dışında; okunan baytlar ortama bağlı. |
| 06-22 | Dönüş kodu, beklenen veri | Boşluk içeren `PIC 9(6)` alanın `PIC S9(9) COMP` alana taşınması kodda tanımlı değil. |
| 06-24 | Dönüş kodu, beklenen veri (`OPEN` başarılı olursa) | Alanlar COMMAREA dışından okunuyor; sonuç ortama bağlı. |
| 06-25 | Dönüş kodu (çağıranın `81`'i görmesi) | 06-03 ile aynı neden. |
| 06-26 | Dönüş kodu, beklenen veri | LGUPVS01'de `EIBCALEN` kontrolü yok. COMMAREA olmadan alanlara erişimin sonucu kodda tanımlı değil. |
| 06-28 | Dönüş kodu (çağıranın `81`'i görmesi) | 06-03 ile aynı neden. |
| 06-29 | Dönüş kodu, beklenen veri | Sayısal olmayan veri sayısal alana taşınıyor ve hiçbir doğrulama yok. Sonuç tanımsız. |
| 06-30 | Dönüş kodu, beklenen veri | Kodda LINK hatası için işleme yok. Sonuç CICS'in varsayılan davranışı ve kodda tanımlı değil. |
