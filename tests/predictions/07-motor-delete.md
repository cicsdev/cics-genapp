# 07 — Motor poliçesi sil (Delete Motor Policy)

Şablon: [TEMPLATE.md](TEMPLATE.md)

| Alan | Değer |
|---|---|
| Operasyon | Motor poliçesi sil: müşteri ve poliçe numarasıyla bulunan `POLICY` satırı Db2'den silinir (bağlı `MOTOR` satırı yabancı anahtar nedeniyle birlikte gider) ve VSAM `KSDSPOLY` kaydı silinir. Poliçe türü COMMAREA'daki istek kodundan (`01DMOT`) anlaşılır. |
| Programlar (çağrı zinciri) | `LGDPOL01` (iş mantığı) → `EXEC CICS LINK` → `LGDPDB01` (Db2 `DELETE`) → `LINK` → `LGDPVS01` (VSAM silme). Hata yollarında üçü de `LGSTSQ`'ya LINK eder. Programlar dört poliçe türüne de hizmet eder; yalnızca motor (`01DMOT`) kolu ve ortak kısımlar okundu. |
| Okunan COBOL dosyaları | `base/src/lgdpol01.cbl`, `base/src/lgdpdb01.cbl`, `base/src/lgdpvs01.cbl`, `base/src/lgstsq.cbl`, `base/src/lgcmarea.cpy` |
| Test verisi kaynağı | `base/cntl/db2cre.jcl`: `POLICY` ve `MOTOR` tanımları (`:161-178`, `:275-290`), müşteri 2 ve 3 (`:471`, `:505`), poliçe 1 ve motor 1'in verisi (`:945-954`, `:1105-1114`). `base/cntl/adef121.jcl` ve `base/data/ksdspoly.txt`: `KSDSPOLY` tanımı ve başlangıç verisi. COBOL kodu değil. |
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
| B4 | Düzenek, satırda yazılan hata kodunu (SQLCODE / RESP) ya da veri durumunu (bir kaydın var ya da yok olması) kendisi kurar. **Aksi söylenmedikçe** her SQL deyiminin `SQLCODE`'u `0`, her dosya komutunun `RESP`'i `NORMAL`'dir; satırda yalnızca düzeneğin değiştirdiği değer yazılır. |

(B5 ve B6 bu dosyada kullanılmıyor.)

## Kod gözlemleri

1. **COMMAREA bayt haritası, poliçe görünümü** (`lgcmarea.cpy:10-13`, `:34-35`). Üç program da bu düzeni kullanır
   (`lgdpol01.cbl:68-69`, `lgdpdb01.cbl:99-102`, `lgdpvs01.cbl:64-65`). Silme yalnızca ilk 28 baytı kullanır:

   | Bayt | Alan | PIC | Satır |
   |---|---|---|---|
   | 1-6 | `CA-REQUEST-ID` | X(6) | `lgcmarea.cpy:10` |
   | 7-8 | `CA-RETURN-CODE` | 9(2) | `:11` |
   | 9-18 | `CA-CUSTOMER-NUM` | 9(10) | `:12` |
   | 19-28 | `CA-POLICY-NUM` | 9(10) | `:35` |
   | 29-32500 | (kullanılmaz) | — | Silme zincirinde bu baytlar okunmuyor, yazılmıyor |

2. **Uzunluk eşiği 28'dir ve iki yerde kontrol edilir.** `WS-CA-HEADER-LEN` = 28 (`lgdpol01.cbl:57`, `lgdpdb01.cbl:66`). LGDPOL01: `lgdpol01.cbl:107-110`.
   LGDPDB01: `lgdpdb01.cbl:143-146`. LGDPOL01, LGDPDB01'i her zaman `LENGTH(32500)` ile çağırır (`lgdpol01.cbl:141-144`); LGDPDB01 her zaman
   `EIBCALEN = 32500` görür. Bu yüzden LGDPDB01'in `EIBCALEN = 0` (`lgdpdb01.cbl:131-135`) ve `98` (`:143-146`) kontrollerine LGDPOL01 üzerinden ulaşılamaz.
   LGDPDB01, LGDPVS01'i de `LENGTH(32500)` ile çağırır (`lgdpdb01.cbl:168-171`). LGDPVS01'de `EIBCALEN` kontrolü yoktur.
3. **İstek kodu.** LGDPOL01 `CA-REQUEST-ID`'yi **COMMAREA'nın içinde** büyük harfe çevirir (`lgdpol01.cbl:117`): çağıran, kendi alanının büyük harfli halini geri alır.
   Dört kodu kabul eder: `'01DEND'`, `'01DMOT'`, `'01DHOU'`, `'01DCOM'` (`lgdpol01.cbl:119-122`); başkasında `'99'` yazar (`:124`) ve `RETURN` yapar (`:133`).
   LGDPDB01 aynı dört kodu kontrol eder, ama büyük harfe çevirmez (`lgdpdb01.cbl:160-165`). **Silinen satır, istek kodundaki türle eşleşmek zorunda
   değildir:** `DELETE` yalnızca müşteri ve poliçe numarasına bakar (`lgdpdb01.cbl:189-194`). `'01DEND'` ile bir motor poliçesi de silinir (07-06).
4. **Poliçe türü tablolarına ayrı silme yoktur.** `DELETE FROM POLICY` yeterlidir; yorum, silmenin yabancı anahtar tanımları nedeniyle tür tablosuna yayıldığını söyler
   (`lgdpdb01.cbl:183-185`). `MOTOR` tablosunun `policyNumber` yabancı anahtarı `ON DELETE CASCADE` ile tanımlıdır [kod] `db2cre.jcl:287-288`.
   Aynı şey `POLICY` → `CLAIM` için de geçerlidir (`db2cre.jcl:371-373`).
5. **`SQLCODE = 100` hata sayılır.** Yorum "SQLCODE 0 ve 100 (kayıt yok) başarılı sayılır; sonuç, kaydın yok olmasıdır" der (`lgdpdb01.cbl:196-197`), ama kod
   `IF SQLCODE NOT EQUAL 0` ile **100'ü de** `'90'` yapar ve `RETURN` eder (`lgdpdb01.cbl:198-202`). Kod yorumdan farklıdır; tahminler kodu izler (07-02, 07-03).
   Aynı poliçeyi ikinci kez silmek bu yüzden `90` döndürür.
6. **VSAM hatasında geri alma yoktur.** LGDPVS01 `RESP ≠ NORMAL` olursa `'81'` yazar ve `RETURN` yapar (`lgdpvs01.cbl:86-91`); ABEND ya da `ROLLBACK` yoktur.
   LGDPDB01 de dönüş kodunu kontrol etmeden `RETURN` yapar (`lgdpdb01.cbl:168-175`). Db2 `DELETE`'i önceden yapıldığı için satırlar silinmiş kalır ve `81`
   çağırana ulaşır (ABEND olmadığı için).
7. **VSAM anahtarı.** 21 bayt: `CA-Request-ID(4:1)` + `CA-Customer-Num` + `CA-Policy-Num` (`lgdpvs01.cbl:25-29`, `:77-79`). `'01DMOT'` → `'M'`. Anahtardaki müşteri numarası,
   Db2'ye giden kesilmiş değer değil, `CA-CUSTOMER-NUM`'un 10 haneli halidir. Küme `KEYS(21 0)` [kod] `adef121.jcl:49`. `DELETE` önceden `READ` yapmaz.
   Başlangıç verisinde üç motor kaydı: `ksdspoly.txt:8-10`.
8. **Dönüş kodları.**

   | Kod | Nerede | Anlamı | Çağırana ulaşır mı |
   |---|---|---|---|
   | `00` | `lgdpol01.cbl:102`, `lgdpdb01.cbl:138` | Başlangıç / silme başarılı | Evet |
   | `81` | `lgdpvs01.cbl:88` | VSAM `DELETE` hatası | Evet (ABEND yok) |
   | `90` | `lgdpdb01.cbl:199` | `DELETE`'te `SQLCODE ≠ 0` (100 dahil) | Evet |
   | `98` | `lgdpol01.cbl:108` | COMMAREA < 28 | Evet |
   | `98` | `lgdpdb01.cbl:144` | COMMAREA < 28 | Yalnızca LGDPDB01 doğrudan çağrılırsa |
   | `99` | `lgdpol01.cbl:124` | İstek kodu tanınmıyor | Evet |
   | `99` | `lgdpdb01.cbl:165` | İstek kodu tanınmıyor | Yalnızca LGDPDB01 doğrudan çağrılırsa |
   | ABEND `LGCA` | `lgdpol01.cbl:98`, `lgdpdb01.cbl:134` | COMMAREA yok | — |

9. **Hata mesajı içerikleri.**
   - `ERROR-MSG` uzunlukları: LGDPOL01 45 bayt (`lgdpol01.cbl:39-44`), LGDPDB01 87 bayt (`lgdpdb01.cbl:41-53`), LGDPVS01 102 bayt (`lgdpvs01.cbl:36-51`).
     `CA-ERROR-MSG` üçünde de 99 bayttır: `'COMMAREA='` + 90 bayt.
   - LGDPDB01: `EM-SQLREQ` = `' DELETE POLICY  '` (`:188`). `EM-CUSNUM` ← `CA-CUSTOMER-NUM`, `EM-POLNUM` ← `CA-POLICY-NUM` (`:152-153`). `EM-SQLRC` `PIC +9(5)`
     (`:53`, `:214`): `100` → `+00100`.
   - LGDPVS01: `' PNUM='` + poliçe no, `' CNUM='` + müşteri no, `' Delete file KSDSPOLY'`, `' RESP='`, `' RESP2='` (`lgdpvs01.cbl:41-51`, `:109-112`). `RESP2` ← `EIBRESP2` (`:87`).
   - LGDPDB01'in `EIBCALEN = 0` mesajı: 21 karakterlik `' NO COMMAREA RECEIVED'`, 63 baytlık `EM-VARIABLE` grubuna taşınır ve sabitleri ezer
     (`lgdpdb01.cbl:46-53`, `:132`). Sonra `MOVE SQLCODE TO EM-SQLRC` son 6 baytı ezer (`:214`).
10. **`WRITE-ERROR-MESSAGE` dalları** ve **WORKING-STORAGE kalıcılığı.**
    - LGDPOL01'de yalnızca `EIBCALEN = 0` dalından çağrılır (`lgdpol01.cbl:97`); iç dallar (`lgdpol01.cbl:172-184`) çalışmaz, ölü kod.
    - LGDPDB01 zincirden çağrıldığında `EIBCALEN = 32500`, LGDPVS01 de `EIBCALEN = 32500` görür; ikisinde de `ELSE` dalı çalışır. `< 91` dallarına
      (`lgdpdb01.cbl:231-236`, `lgdpvs01.cbl:118-123`) yalnızca ilgili program doğrudan 28-90 bayt arası bir COMMAREA ile çağrılırsa ulaşılır
      (LGDPDB01 için 07-21, LGDPVS01 için 07-16).
    - Silme zincirinde birikim yapan sayaç yoktur: `WS-CA-HEADER-LEN` (`lgdpol01.cbl:57`, `lgdpdb01.cbl:66`) `VALUE +28`'dir ve hiç değiştirilmez; `VALUE +0` ile başlayıp
      üstüne eklenen bir alan yoktur. Test düzeneği yine de her durumu ayrı süreçte çalıştırır [belge] `docs/adr/0004-legacy-test-harness.md` (karar 4).
11. **Test verisi** (`base/cntl/db2cre.jcl`). Bu değerler yalnızca test veritabanı bu JCL ile yüklendiyse ve sonradan değiştirilmediyse geçerlidir.
    - 07-01'de silinen poliçe 1 (müşteri 2: `:945-946`), motor 1 (`:1105-1114`) ve VSAM kaydı `M0000000002` + `0000000001` (`ksdspoly.txt:8`).
    - Poliçe 1 müşteri 2'ye aittir. Müşteri 3 başka bir müşteridir (`:505`); eşleşmeyen çift (müşteri 3, poliçe 1) için kullanılır.
    - Olmayan poliçe için `0000000999` kullanılır: JCL poliçe numaralarını 1-10 verir, kimlik değeri 1000001'den başlar (`:162-163`).
    - Sonraki bir test aynı poliçeyi bulmak isterse silme testlerinin veriyi bozduğunu hesaba katmalıdır; her test veriyi baştan kurar.

## Tahmin tablosu

| Test no | Girdi | Beklenen dönüş kodu | Beklenen veri | Tahminin dayandığı COBOL satırı | Kural türü |
|---|---|---|---|---|---|
| 07-01 | LGDPOL01 çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01DMOT'`. `CA-CUSTOMER-NUM = 0000000002`, `CA-POLICY-NUM = 0000000001` (poliçe 1, müşteri 2: `db2cre.jcl:945-946`). Db2 yalnızca `db2cre.jcl` ile yüklenmiş; `KSDSPOLY`'de `M0000000002` + `0000000001` anahtarlı kayıt var [kod] `ksdspoly.txt:8`. [B4] `DELETE` ve VSAM silme başarılı. | `CA-RETURN-CODE = 00` | COMMAREA alanları girdideki gibi kalır.<br>Yan etkiler: `POLICY`'de poliçe 1'in satırı silinir; `MOTOR`'da poliçe 1'in satırı da silinir (yabancı anahtar `ON DELETE CASCADE`); `KSDSPOLY`'deki `M0000000002` + `0000000001` kaydı silinir. Müşteri 2'nin `CUSTOMER` satırı ve diğer poliçelerle VSAM kayıtları değişmez. Hata mesajı yazılmaz. | `lgdpol01.cbl:95`, `:102`, `:107`, `:117`, `:119-122`, `:126-133`, `:141-144`<br>`lgdpdb01.cbl:131`, `:138`, `:143`, `:149-150`, `:160-163`, `:167-175`, `:188-202`<br>`lgdpvs01.cbl:77-79`, `:81-91`<br>`db2cre.jcl:287-288` | İş kuralı |
| 07-02 | LGDPOL01 çağrılır. `EIBCALEN = 32500`, `CA-REQUEST-ID = '01DMOT'`, `CA-CUSTOMER-NUM = 0000000002`, `CA-POLICY-NUM = 0000000999` (poliçe 999 yok). [B4] `DELETE`, `SQLCODE = 100` döner. | `CA-RETURN-CODE = 90` | Kod yorumuna rağmen `100` başarı sayılmaz (Kod gözlemleri 5). `RETURN` yapılır: LGDPVS01 çağrılmaz, VSAM'a dokunulmaz. Hiçbir tablo değişmez.<br>Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG` (87 bayt): tarih, saat, `' LGDPDB01'`, `' CNUM='` + `0000000002`, `' PNUM='` + `0000000999`, `' DELETE POLICY  '`, `' SQLCODE='` + `+00100`. (2) `CA-ERROR-MSG`: `'COMMAREA='` + COMMAREA'nın ilk 90 baytı (`EIBCALEN = 32500`, `ELSE` dalı). | `lgdpdb01.cbl:188-202`, `:152-153`, `:214-228`, `:237-242`<br>[kod yorumu] `lgdpdb01.cbl:196-197` | İş kuralı |
| 07-03 | 07-01 ile aynı, ama `CA-CUSTOMER-NUM = 0000000003` (poliçe 1 müşteri 2'ye ait: `db2cre.jcl:946`). [B4] `DELETE`, `SQLCODE = 100` döner (müşteri ve poliçe birlikte eşleşmiyor). | `CA-RETURN-CODE = 90` | 07-02 ile aynı. Başka müşterinin poliçesi silinmez: poliçe 1 ve motor 1 satırları ile VSAM kaydı yerinde kalır. `' CNUM='` yanında `0000000003`, `' PNUM='` yanında `0000000001` yazılır. | `lgdpdb01.cbl:189-194`, `:198-202` | İş kuralı |
| 07-04 | 07-01 ile aynı, ama [B4] `DELETE`'te 0 ve 100 dışında bir `SQLCODE` (örn. `-904`). | `CA-RETURN-CODE = 90` | 07-02 ile aynı; `EM-SQLRC` üretilen SQLCODE'dur (`-904` → `-00904`). Hiçbir tablo değişmez, VSAM'a dokunulmaz. | `lgdpdb01.cbl:198-202`, `:214` | İş kuralı |
| 07-05 | 07-01 ile aynı, ama [B4] VSAM `DELETE`'te `RESP ≠ NORMAL` (kayıt yok; örn. `KSDSPOLY`'den `M0000000002` + `0000000001` silinmiş). | `CA-RETURN-CODE = 81` | Db2'de poliçe 1 ve motor 1 **silinmiş kalır** (VSAM hatasında ABEND ya da `ROLLBACK` yok: Kod gözlemleri 6). `81` çağırana ulaşır. Hata sonrası `RETURN` ile görev biter.<br>Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG` (102 bayt): tarih, saat, `' LGDPVS01'`, `' PNUM='` + `0000000001`, `' CNUM='` + `0000000002`, `' Delete file KSDSPOLY'`, `' RESP='` + RESP, `' RESP2='` + RESP2. (2) `CA-ERROR-MSG`: `'COMMAREA='` + COMMAREA'nın ilk 90 baytı (`EIBCALEN = 32500`, `ELSE` dalı). | `lgdpvs01.cbl:81-91`, `:99-132`<br>`lgdpdb01.cbl:168-175` | İş kuralı |
| 07-06 | 07-01 ile aynı, ama `CA-REQUEST-ID = '01DEND'` (hayat sigortası silme kodu), silinen poliçe motor poliçesi 1. VSAM yalnızca başlangıç verisiyle yüklü: `E0000000002` + `0000000001` anahtarlı kayıt yok [kod] `ksdspoly.txt:1-10`. | `CA-RETURN-CODE = 81` | İstek koduyla poliçe türü eşleşmediği halde Db2 silme çalışır (`DELETE` türe bakmaz): poliçe 1 ve motor 1 satırları silinir. VSAM anahtarının harfi `CA-REQUEST-ID(4:1)` = `E` olduğu için `E0000000002` + `0000000001` aranır, bulunamaz. Motor kaydı `M0000000002` + `0000000001` **VSAM'da kalır** (Db2 ile VSAM tutarsız). Yan etki: 07-05'teki iki mesaj. | `lgdpol01.cbl:119-122`<br>`lgdpdb01.cbl:160-163`, `:189-194`<br>`lgdpvs01.cbl:77-79`, `:81-91` | İş kuralı |
| 07-07 | LGDPOL01 çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01DXXX'` (tanınmayan kod). Diğer girdiler 07-01 ile aynı. | `CA-RETURN-CODE = 99` | LGDPDB01 çağrılmaz: hiçbir tablo ve VSAM kaydı değişmez, hata mesajı yazılmaz. | `lgdpol01.cbl:117`, `:119-124`, `:133` | Arayüz (COMMAREA) kuralı |
| 07-08 | 07-01 ile aynı, ama `CA-REQUEST-ID = '01dmot'` (küçük harf). | `CA-RETURN-CODE = 00` | 07-01 ile aynı silme yapılır. Dönüşte `CA-REQUEST-ID = '01DMOT'` olur: LGDPOL01 küçük harfi COMMAREA'da büyük harfe çevirir. | `lgdpol01.cbl:117`, `:119-122`<br>`lgdpvs01.cbl:77` | Arayüz (COMMAREA) kuralı |
| 07-09 | LGDPOL01 COMMAREA'sız çağrılır (`EIBCALEN = 0`). | Dönüş kodu yok. Görev `ABEND` kodu `LGCA` ile (NODUMP) sonlanır. | COMMAREA olmadığı için veri dönmez. LGDPDB01 çağrılmaz.<br>Yan etki: `LGSTSQ`'ya tek LINK yapılır: 45 baytlık `ERROR-MSG` (tarih, saat, `' LGDPOL01'`, `' NO COMMAREA RECEIVED'`). COMMAREA dökümü gönderilmez (`EIBCALEN > 0` sağlanmaz). | `lgdpol01.cbl:95-99`, `:39-44`, `:154-171` | Arayüz (COMMAREA) kuralı |
| 07-10 | LGDPOL01 çağrılır. `EIBCALEN` 8 ile 27 arasında (sınır değer: `27`). | `CA-RETURN-CODE = 98` | LGDPDB01 çağrılmaz, hata mesajı yazılmaz (`lgdpol01.cbl:107-110` arasında `WRITE-ERROR-MESSAGE` yok). Hiçbir tablo değişmez. | `lgdpol01.cbl:102`, `:107-110`<br>`lgdpol01.cbl:57` | Arayüz (COMMAREA) kuralı |
| 07-11 | LGDPOL01 çağrılır. `EIBCALEN` 1 ile 7 arasında. | [B1] Tamponun 7-8. baytları `98` olur (ön koşullu) [kod] `lgdpol01.cbl:108`. | Kod `98`'i yazıp `RETURN` yapar. `CA-RETURN-CODE` 7-8. baytlarda olduğu için gelen COMMAREA'nın dışında kalır (1-6'da tamamen, 7'de yarısı) ve B1 ile çağıranın tamponuna düşer. Ön koşulsuz kesin olan: `EIBCALEN = 7` ise COMMAREA'nın 7. baytı `9` olur. İstek kodu bu yolda okunmaz; LGDPDB01 çağrılmaz. | `lgcmarea.cpy:10-11`<br>`lgdpol01.cbl:102`, `:107-110` | Arayüz (COMMAREA) kuralı |
| 07-12 | LGDPOL01 çağrılır. `EIBCALEN = 28` (kabul edilen en küçük uzunluk). Diğer girdiler 07-01 ile aynı; istek kodu, müşteri ve poliçe numaraları COMMAREA'nın içinde. | `CA-RETURN-CODE = 00` | Silme 07-01 ile aynı şekilde çalışır (`28 < 28` yanlış). LGDPDB01, LGDPOL01'den `LENGTH(32500)` ile çağrılır. | `lgdpol01.cbl:107-110`, `:141-144`<br>`lgdpdb01.cbl:143`, `:149-150` | Arayüz (COMMAREA) kuralı |
| 07-13 | **LGDPDB01 doğrudan** COMMAREA'sız çağrılır (`EIBCALEN = 0`). [B2] `SQLCODE = 0`. | Dönüş kodu yok. Görev `ABEND` kodu `LGCA` ile (NODUMP) sonlanır. | SQL çalışmaz, LGDPVS01 çağrılmaz.<br>Yan etki: `LGSTSQ`'ya tek LINK yapılır: 87 baytlık `ERROR-MSG`. İçeriği: tarih, saat, `' LGDPDB01'`, `' NO COMMAREA RECEIVED'` + 36 boşluk + 6 baytlık `EM-SQLRC`. Taşıma 63 baytlık `EM-VARIABLE` grubunun tamamını ezdiği için `' CNUM='`, `' PNUM='`, `' SQLCODE='` sabitleri mesajda yer almaz. [B2] `EM-SQLRC = +00000` [kod] `lgdpdb01.cbl:214`. COMMAREA dökümü gönderilmez.<br>LGDPOL01 üzerinden bu yola ulaşılamaz (Kod gözlemleri 2). | `lgdpdb01.cbl:131-135`, `:46-53`, `:212-230` | Arayüz (COMMAREA) kuralı |
| 07-14 | **LGDPDB01 doğrudan** çağrılır. `EIBCALEN` 8 ile 27 arasında (sınır değer: `27`). | `CA-RETURN-CODE = 98` | SQL çalışmaz, LGDPVS01 çağrılmaz, hata mesajı yazılmaz. LGDPOL01 üzerinden bu yola ulaşılamaz. | `lgdpdb01.cbl:138`, `:143-146`<br>`lgdpdb01.cbl:66` | Arayüz (COMMAREA) kuralı |
| 07-15 | **LGDPDB01 doğrudan** çağrılır. `EIBCALEN = 32500`. `CA-REQUEST-ID = '01dmot'` (küçük harf). | `CA-RETURN-CODE = 99` | LGDPDB01 büyük harfe çevirmez: küçük harfli kod tanınmaz, `99` yazılır. `DELETE` ve VSAM silme yapılmaz, hata mesajı yazılmaz. LGDPOL01 üzerinden bu yola küçük harfle girilemez (07-08). | `lgdpdb01.cbl:160-166`, `:175` | Arayüz (COMMAREA) kuralı |
| 07-16 | **LGDPVS01 doğrudan** çağrılır. `EIBCALEN` 28 ile 90 arasında (anahtardaki müşteri ve poliçe numaraları 9-28. baytlarda, içeride kalır). `CA-REQUEST-ID = '01DMOT'`. [B4] `DELETE`'te `RESP ≠ NORMAL`. | `CA-RETURN-CODE = 81` | Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG`: 07-05'teki gibi. (2) `EIBCALEN < 91` dalı: `'COMMAREA='` + `DFHCOMMAREA(1:EIBCALEN)`; kalan `CA-DATA` boşluk. Bu dala yalnızca bu yolla ulaşılır. | `lgdpvs01.cbl:75-91`, `:117-123` | Arayüz (COMMAREA) kuralı |
| 07-17 | **LGDPVS01 doğrudan** COMMAREA'sız çağrılır (`EIBCALEN = 0`). | **belirsiz** | **belirsiz**. LGDPVS01'de `EIBCALEN` kontrolü yok. `DELETE`, var olmayan COMMAREA'daki alanları anahtar olarak kullanır. Sonuç kodda tanımlı değil. | `lgdpvs01.cbl:75-85` | Arayüz (COMMAREA) kuralı |
| 07-18 | 07-01 ile aynı, ama `CA-CUSTOMER-NUM = 1000000002` (10 haneli). [B3] | [B3] `CA-RETURN-CODE = 81` (ön koşullu) [kod] `lgdpvs01.cbl:86-90`. | [B3] `PIC 9(10)` → `PIC S9(9) COMP` taşımasında en soldaki hane kesilir ve `DB2-CUSTOMERNUM-INT = 2` olur: Db2'de **müşteri 2'nin poliçe 1'i** silinir (`DELETE` başarılı) [kod] `lgcmarea.cpy:12`, `lgdpdb01.cbl:82`, `:149`. VSAM ise 10 haneli `1000000002`'yi kesilmeden kullanır [kod] `lgdpvs01.cbl:79`: `M1000000002` + `0000000001` anahtarlı kayıt yok, `DELETE` başarısız olur. Motor kaydı `M0000000002` + `0000000001` VSAM'da kalır (Db2 ile tutarsız).<br>B3 sağlanmazsa sonuç **belirsiz**. | `lgcmarea.cpy:12`<br>`lgdpdb01.cbl:82`, `:149`<br>`lgdpvs01.cbl:78-79`, `:81-91`<br>`cobol.jcl:44-50` | Arayüz (COMMAREA) kuralı |
| 07-19 | 07-01 ile aynı, ama `CA-CUSTOMER-NUM` ya da `CA-POLICY-NUM` sayısal değil (örn. boşluk). | **belirsiz** | **belirsiz**. Hiçbir programda sayısallık kontrolü yok. Değer doğrudan `DB2-CUSTOMERNUM-INT`/`DB2-POLICYNUM-INT`'e taşınır ve VSAM anahtarı olarak da kullanılır. | `lgdpdb01.cbl:149-150`<br>`lgdpvs01.cbl:78-79` | Arayüz (COMMAREA) kuralı |
| 07-20 | 07-01 ile aynı. LGDPDB01'e ya da LGDPVS01'e yapılan LINK başarısız olur. | **belirsiz** | **belirsiz**. İki LINK'te de `RESP`/`NOHANDLE` yok, programlarda `HANDLE CONDITION` da yok. Sonuç CICS'in varsayılan davranışına bağlı ve kodda yazmıyor. | `lgdpol01.cbl:141-144`<br>`lgdpdb01.cbl:168-171` | Arayüz (COMMAREA) kuralı |
| 07-21 | **LGDPDB01 doğrudan** çağrılır. `EIBCALEN` 28 ile 90 arasında (örn. 50). `CA-REQUEST-ID = '01DMOT'`, `CA-CUSTOMER-NUM = 0000000002`, `CA-POLICY-NUM = 0000000001`. [B4] `DELETE`'te `SQLCODE ≠ 0` (örn. `-904`). | `CA-RETURN-CODE = 90` | `RETURN` yapılır: LGDPVS01 çağrılmaz, hiçbir tablo değişmez. Yan etki: `LGSTSQ`'ya iki LINK yapılır. (1) `ERROR-MSG`: 07-04 ile aynı. (2) `EIBCALEN < 91` dalı: `'COMMAREA='` + `DFHCOMMAREA(1:EIBCALEN)`, `CA-DATA`'nın kalanı boşluk. Bu dala yalnızca bu yolla ulaşılır. | `lgdpdb01.cbl:143`, `:198-202`, `:230-236` | Arayüz (COMMAREA) kuralı |

## Kapsam tablosu

Koddaki her `IF`/`EVALUATE` dalının ve dönüş kodunun, onu kapsayan test numaraları.

| Envanter no | Madde | Test no | Not |
|---|---|---|---|
| DO-01 | `lgdpol01.cbl:95-99` `IF EIBCALEN = 0` → ABEND `LGCA` | 07-09 | |
| DO-02 | `lgdpol01.cbl:102` `'00'` → `CA-RETURN-CODE` | 07-01, 07-10, 07-11 | |
| DO-03 | `lgdpol01.cbl:107-110` `IF EIBCALEN < 28` → `98` | 07-10, 07-11 (doğru dal); 07-01, 07-12 (yanlış dal) | |
| DO-04 | `lgdpol01.cbl:117` `UPPER-CASE` → `CA-REQUEST-ID` | 07-08 | |
| DO-05 | `lgdpol01.cbl:119-124` `IF` kod ∉ {4 kod} → `99` | 07-07 (doğru dal); 07-01 (yanlış dal) | |
| DO-06 | `lgdpol01.cbl:126-129` `PERFORM`, `If CA-RETURN-CODE > 0` → `RETURN` | 07-02 … 07-05 (doğru dal); 07-01 (yanlış dal) | İki dal da `RETURN`'e (`:133`) varır; fark gözlenemez |
| DO-07 | `lgdpol01.cbl:139-146` LINK LGDPDB01 `LENGTH(32500)` | 07-01, 07-12, 07-20 | |
| DO-08 | `lgdpol01.cbl:154-186` `WRITE-ERROR-MESSAGE` | 07-09 | Dış `IF EIBCALEN > 0` yanlış. İç dallar (`lgdpol01.cbl:172-184`) ölü kod (Kod gözlemleri 10) |
| DD-01 | `lgdpdb01.cbl:131-135` `IF EIBCALEN = 0` → ABEND `LGCA` | 07-13 | Yalnızca doğrudan çağrı |
| DD-02 | `lgdpdb01.cbl:138` `'00'` | 07-01, 07-14 | |
| DD-03 | `lgdpdb01.cbl:143-146` `IF EIBCALEN < 28` → `98` | 07-14 (doğru dal); 07-01 (yanlış dal) | Yalnızca doğrudan çağrı |
| DD-04 | `lgdpdb01.cbl:149-153` `CA-CUSTOMER-NUM`, `CA-POLICY-NUM` → host değişkenleri, `EM-*` | 07-01, 07-02, 07-18, 07-19 | |
| DD-05 | `lgdpdb01.cbl:160-166` `IF` kod ∉ {4 kod} → `99` | 07-15 (doğru dal); 07-01 (yanlış dal) | Yalnızca doğrudan çağrı |
| DD-06 | `lgdpdb01.cbl:186-202` `DELETE`, `IF SQLCODE NOT EQUAL 0` → `90`, mesaj, `RETURN` | 07-02, 07-03, 07-04 (doğru dal); 07-01 (yanlış dal) | `100` da doğru dala girer (Kod gözlemleri 5) |
| DD-07 | `lgdpdb01.cbl:168-171`, `:175` LINK LGDPVS01 `LENGTH(32500)`, RETURN | 07-01, 07-05, 07-06, 07-20 | |
| DD-08 | `lgdpdb01.cbl:212-245` `WRITE-ERROR-MESSAGE` | 07-02 (`ELSE`), 07-21 (`< 91`), 07-13 (dış `IF` yanlış) | |
| DV-01 | `lgdpvs01.cbl:75-79` anahtar kurma | 07-01, 07-18, 07-19 | |
| DV-02 | `lgdpvs01.cbl:81-91` `DELETE`; `RESP ≠ NORMAL` → `81`, mesaj, `RETURN` | 07-05, 07-06, 07-16, 07-18 (doğru dal); 07-01 (yanlış dal) | |
| DV-03 | `lgdpvs01.cbl:99-132` `WRITE-ERROR-MESSAGE` | 07-05 (`ELSE`), 07-16 (`< 91`) | `EIBCALEN = 0` dalı: LGDPVS01'de `EIBCALEN` kontrolü yok (07-17) |
| SQ-01 | `lgstsq.cbl:68-71` LINK yolu | 07-02, 07-04, 07-05, 07-06, 07-09, 07-13, 07-16, 07-21 | |
| SQ-02 | `lgstsq.cbl:72-80` terminalden RECEIVE | — | **Kapsam dışı: bu zincirden ulaşılamaz.** LGSTSQ yalnızca LINK ile çağrılır. |
| SQ-03 | `lgstsq.cbl:94-111` WRITEQ TD `CSMT`, TS `GENAERRS` | 07-02, 07-05 | |
| N-01 | `SQLCODE = 100` yorumda başarı, kodda `90` | 07-02, 07-03 | Kod gözlemleri 5 |
| N-02 | Silme poliçe türünü denetlemez | 07-06 | Kod gözlemleri 3 |
| N-03 | VSAM hatasında Db2 silmesi geri alınmaz | 07-05, 07-06, 07-18 | Kod gözlemleri 6 |
| N-04 | `CA-CUSTOMER-NUM` kesilmesi (B3) | 07-18 | |
| N-05 | Sayısallık ve aralık kontrolü yok | 07-18, 07-19 | |
| N-06 | LINK'te `RESP` yok | 07-20 | |

## Ön koşullu satırlar

Ön koşul kodları dosyanın başında ("Kaynak etiketleri ve ön koşul kodları").

| Test no | Ön koşul | Ön koşulla tahmin | Ön koşul sağlanmazsa |
|---|---|---|---|
| 07-01 | B4 | Başarı yolu | Girdi kurulamaz |
| 07-02 | B4 | Girdi düzenekle kurulur (`DELETE` `SQLCODE = 100`); tahmin (`90`) değişmez | Girdi kurulamaz |
| 07-03 | B4 | Girdi düzenekle kurulur (`DELETE` `SQLCODE = 100`); tahmin (`90`) değişmez | Girdi kurulamaz |
| 07-04 | B4 | Girdi düzenekle kurulur; tahmin (`90`) değişmez | Girdi kurulamaz |
| 07-05 | B4 | Girdi düzenekle kurulur (VSAM'dan poliçe 1'in kaydı silinir); tahmin (`81`) değişmez | Girdi kurulamaz: başlangıç verisinde VSAM kaydı var |
| 07-11 | B1 | Tamponun 7-8. baytları `98` | Dönüş kodu belirsiz |
| 07-13 | B2 | `EM-SQLRC = +00000` | `EM-SQLRC` belirsiz |
| 07-16 | B4 | Girdi düzenekle kurulur; tahmin (`81`, `< 91` dalı) değişmez | Girdi kurulamaz |
| 07-21 | B4 | Girdi düzenekle kurulur; tahmin (`90`, `< 91` dalı) değişmez | Girdi kurulamaz |
| 07-18 | B3 | Db2'de müşteri 2'nin poliçe 1'i silinir; VSAM `DELETE` başarısız olur → `81` | Dönüş kodu ve veri belirsiz |

## Belirsiz satırlar

| Test no | Belirsiz olan hücre | Neden belirsiz |
|---|---|---|
| 07-17 | Dönüş kodu, beklenen veri | LGDPVS01'de `EIBCALEN` kontrolü yok. COMMAREA olmadan alanlara erişimin sonucu kodda tanımlı değil. |
| 07-19 | Dönüş kodu, beklenen veri | Sayısal olmayan veri sayısal alana taşınıyor ve hiçbir doğrulama yok. Sonuç tanımsız. |
| 07-20 | Dönüş kodu, beklenen veri | Kodda LINK hatası için işleme yok. Sonuç CICS'in varsayılan davranışı ve kodda tanımlı değil. |
