# ADR 0005: Test mimarisi ve CI hattı

| Alan | Değer |
|---|---|
| Durum | Önerildi |
| Tarih | 2026-10-11 |
| Yazan | Sercan (taslak: Claude Code) |
| İlgili iş | #76 |
| İlgili | [ADR 0002](0002-rest-api.md) (REST API ve dönüş kodu eşlemesi), [ADR 0004](0004-legacy-test-harness.md) (Eski COBOL kodunu CICS ve Db2 olmadan çalıştırmak için test düzeneği) |

## Bağlam

Test ekibi COBOL kodunu okuyarak **tahmin** yazar: "şu girdide program şu dönüş kodunu verir"
(`tests/predictions/TEMPLATE.md`). Her tahmin satırı ya **arayüz (COMMAREA) kuralıdır** (programlar arasında bilgi
taşıyan COMMAREA'nın kendisiyle ilgili, örn. kısa gelirse `98`) ya da **iş kuralıdır** (sigorta işiyle ilgili, örn.
müşteri yoksa `01`). Kararı etkileyen noktalar:

1. **Testler koddan önce `main`'e girer.** Yapım ve test ekipleri aynı COBOL kodunu birbirinden habersiz okur; bir
   **dilimin** (müşterinin ya da bir poliçe türünün operasyonları) testleri, kod PR'ından önce birleşir (#19).
2. **NFR-10 gereği her PR'da kod otomatik derlenir ve testler çalışır (CI, sürekli entegrasyon); testleri geçmeyen
   değişiklik `main`'e girmemelidir** (`docs/srs.md`).
3. **18 operasyonun her biri için eşdeğerlik testi olmalıdır** (NFR-11).
4. **Eşdeğerlik testleri API'yi dışarıdan çağırır** ve cevabı eski dönüş koduyla karşılaştırır (ADR 0002).

## Karar

### 1. Test türleri ve test piramidi

| Tür | Sorduğu soru | Yer | Durum |
|---|---|---|---|
| **Eşdeğerlik** | Yeni sistem aynı girdiye eskisiyle aynı sonucu veriyor mu? | `tests/GenApp.EquivalenceTests` | Var: 4 test, 3 operasyon |
| **Entegrasyon** | API ve PostgreSQL birlikte baştan sona çalışıyor mu? Cevaba ek olarak sonucun veritabanında oluştuğu da kontrol edilir. | `tests/GenApp.IntegrationTests` | Planlanan (#68): her dilim için en az bir test. Projede henüz test yok. |
| **Mutasyon** | Testlerimiz hataları yakalıyor mu? Araç koda bilerek küçük hatalar koyar (`>` yerine `>=`); yakalananların oranı **mutasyon skorudur**. | Stryker.NET | Planlanan (#53): `src/` üzerinde çalıştırılır, sonuç `tests/results/mutation.md`'ye yazılır. #53 CI'dan söz etmez; bu ADR elle çalıştırmayı önerir. Repoda henüz Stryker kurulumu yok. |

**Test piramidi**, altta çok sayıda hızlı ve ucuz **birim testi** (tek sınıf, veritabanı yok), ortada daha az
entegrasyon testi, tepede az sayıda yavaş uçtan uca test öneren modeldir. Test ekibinin C# testlerinin **tek katmanı**
vardır: eşdeğerlik ve planlanan entegrasyon testleri (#68'de "uçtan uca") API'yi HTTP ile çağırır, gerçek PostgreSQL'e
bağlanır; test ekibi birim testi yazmaz (Değerlendirilen seçenekler). GnuCOBOL çalıştırmaları (ADR 0004) elle yapılır
(`tests/gnucobol/README.md`), CI'da çalışmaz. Mutasyon testi katman değil, bir ölçüdür. **Hız ve maliyet ölçülmedi:**
4 test yalnızca derlendi, hiç çalıştırılmadı (#101). Yük testi (#84, SRS NFR-01..03) kapsam dışıdır.

### 2. Tahmin tablosundan teste

Yalnızca **iş kuralı** satırları C# testine çevrilir. Satır, **dönüş kodu kesinse** (tahminde `belirsiz` değilse) ve
**ön koşulu API'den kurulabiliyorsa** çevrilir: "müşteri var" ön koşulu `POST /api/customers` ile kurulur; düzeneğin
ürettiği koşullar (sayaç hatası, belirli bir SQLCODE) kurulamaz. API'den çevrilmiş bir satırla aynı görünen satır ayrıca
çevrilmez. Ön koşul yalnızca API'den görülemeyen kısmı etkiliyorsa ve yeni sistemde de görünen sonucu değiştirmiyorsa
yok sayılır; görülemeyen kısım (VSAM kaydı, `CA-NUM-POLICIES`, sayaçtan gelen numaranın değeri) hiçbir testte
doğrulanmaz, testin yorumuna **"Doğrulanmayanlar"** diye yazılır. Beklenen cevap `docs/api-design.md` §3'teki eşlemeden
gelir; metinler kırpılmış karşılaştırılır (ADR 0002 Karar 6). Bu ilke #19'daki "iş kuralı satırlarının her biri için bir
xUnit testi" görevini daraltır: belirsiz dönüş kodunun testi beklentiyi uydurur; kurulamayan ön koşulun testi çalışamaz;
API davranışı tanımsızsa (01-07, 01-08, 03-10) test belgede olmayan beklentiye bağlanır; 03-03'ün (VSAM) yeni sistemde
karşılığı yoktur; 01-02, 01-01'in tekrarıdır.

- **01-01** (müşteri ekle, `00`): Ön koşulları (B1: COMMAREA'nın 32500 baytlık tamponla geçirilmesi; B7: sayacın 11
  vermesi) yalnızca görülemeyen kısmı etkilediği için yok sayılır. Test `201` ve alanları doğrular, numaranın yalnızca
  öncekinden farklı olduğuna bakar; numaranın değeri, VSAM ve `CUSTOMER_SECURE` "Doğrulanmayanlar"dadır.
- **02-02** (müşteri yok, `01`): Beklenen `404`, `type: not-found`, `returnCode: "01"`. API'nin tahmindeki `0`'ı `400`
  ile reddedip reddetmeyeceği tanımlı olmadığından pratikte atanmayan `999999999` kullanılır.

Müşteri dilimindeki 66 tahminin 42'si arayüz kuralıdır. 24 iş kuralının 4'ü çevrildi (01-01, 02-01, 02-02, 03-01).
Çevrilmeyen 20 satır (dağılım #101'dekinden farklıdır: 01-02 orada "ön koşul", 03-02 "VSAM" altındaydı):

- Dönüş kodu belirsiz (8): 01-05, 01-09, 02-15, 03-02, 03-06, 03-07, 03-08, 03-11.
- Ön koşul API'den kurulamıyor; sayaç, hata üretme (5): 01-03, 01-04, 01-06 (ön koşul yeni sistemde sonucu değiştirir:
  NFR-04, bkz. Açık sorular), 02-04, 03-04.
- API'den 01-01 ile aynı görünür; ayrı test bir şey ölçmez (1): 01-02.
- Db2 kilitlenmesi (-913) API'den üretilemiyor (2): 02-03, 03-05.
- VSAM'a özgü; yeni sistemde VSAM yok (1): 03-03.
- İstekte `customerNumber` yok, `docs/api-design.md` §4.1 (1): 01-07.
- Boş ad/soyad; API'de boş metin davranışı tanımsız (2): 01-08, 03-10.

### 3. Test adı biçimi

`<COBOL_PROGRAMI>_satir_<N>_<durum>_<kod>_doner`. Program ve satır, tahmin tablosunun "Tahminin dayandığı COBOL satırı"
sütunundaki, dönüş kodunu belirleyen satırdır; `<durum>` girdinin kısa anlatımı, `<kod>` eski dönüş kodudur. Örnek:
`LGICDB01_satir_196_kayit_yok_01_doner` (tahmin 02-02, `lgicdb01.cbl:196`: `SQLCODE = 100` → `CA-RETURN-CODE '01'`).
Mevcut 4 test bu biçimdedir. **Neden:** izlenebilirlik. Kırmızı testin adı bakılacak COBOL satırını gösterir; tahmin,
GnuCOBOL ölçümü (`tests/gnucobol/README.md`, "Measured runs"; LGICUS01, #99) ve C# testi aynı satır üzerinden eşlenir.

### 4. Eşdeğerlik testleri API'yi dışarıdan çağırır

Testler API'nin yalnızca dışarıdan görünen davranışına bakar (**kara kutu testi**). ASP.NET Core'un test sınıfı
`WebApplicationFactory<Program>` API'yi test sürecinin içinde ayağa kaldırır; testler onun verdiği `HttpClient` ile
`docs/api-design.md`'deki adreslere istek gönderir (`tests/GenApp.EquivalenceTests/Altyapi/GenAppApiFactory.cs`). API
projesinden kullanılan tek tip `Program`'dır; istek gövdeleri sözlükle kurulur, cevaplar JSON olarak okunur
(`tests/GenApp.EquivalenceTests/Altyapi/ApiYardimcilari.cs`). **Neden:**

- **Testler koddan önce derlenmeli.** Yalnızca `Program`'a bağlı oldukları için operasyonun kodu yokken de derlenir.
- **Bağımsızlık.** Beklenen sonuç koddan değil belgeden çıkar; koda bakılarak yazılan test koddaki hatayı kopyalar
  (#68). Testler, web arayüzünün de kullanacağı sözleşmeyi (HTTP kodu ve `returnCode`) ölçer.

### 5. Operasyon etiketi ve `tests/active-operations.txt`

Her test operasyonunu xUnit'in `[Trait]` etiketiyle (teste bir ad-değer çifti ekler) taşır:
`[Trait("Operasyon", "musteri-sorgula")]`. Geçerli 18 ad (`tests/README.md`): `musteri-sorgula`, `musteri-ekle`,
`musteri-guncelle`, `motor-ekle`, `motor-sorgula`, `motor-guncelle`, `motor-sil`, `konut-ekle`, `konut-sorgula`,
`konut-guncelle`, `konut-sil`, `hayat-ekle`, `hayat-sorgula`, `hayat-guncelle`, `hayat-sil`, `ticari-ekle`,
`ticari-sorgula` (dört ticari sorgulama biçiminin hepsi, `docs/api-design.md` §2.5), `ticari-sil`. CI yalnızca
`tests/active-operations.txt`'te adı geçen operasyonların testlerini çalıştırır; dosya bugün boştur.

**Neden:** Testler koddan önce `main`'e girer (Bağlam 1). Kodu olmayan operasyonun testi çalışsa kırmızı olurdu; NFR-10
gereği testleri geçmeyen değişikliğin `main`'e girmemesi gerektiği için (Bağlam 2) test PR'ı birleştirilemezdi.

**Etkinleştirme:** Operasyonun kodu hazır olunca adı dosyaya eklenir (biçim kuralları `tests/README.md`'de) ve
testleri her PR'da çalışmaya başlar. Veritabanı sıfırlanmadığı için sorgula ve güncelle testleri müşteriyi `POST` ile
kurar (güncelle ayrıca `GET` yapar); bu yüzden sıra `musteri-ekle`, `musteri-sorgula`, `musteri-guncelle`'dir.

### 6. CI hattı

CI hattı `.github/workflows/ci.yml`'dedir (tek iş "Derleme ve testler", `ubuntu-latest`). Her `pull_request`'te ve
`main`'e her `push`'ta, `postgres:18` servisiyle (değerler `docker-compose.yml`'dekiyle aynı) çalışır. Adımlar:

1. Kodu al (`actions/checkout@v4`).
2. .NET SDK'yı kur (global.json) (`actions/setup-dotnet@v4`; 10.0.100, `latestFeature` ile en güncel 10.0.x kurulur).
3. Kullanılan SDK sürümünü göster (`dotnet --version`).
4. Paketleri geri yükle (`dotnet restore GenApp.slnx`).
5. Çözümü derle (test projeleri dahil) (`dotnet build GenApp.slnx --no-restore`).
6. Aktif operasyonların eşdeğerlik testlerini çalıştır (`ci.yml:60-137`): dosya yoksa ya da geçersiz ad varsa başarısız
   olur; **ad yoksa** başarılı biter. Bir ad bile başarısız olursa diğerleri yine denenir, adım sonunda başarısız biter.
   **Her ad için ayrı:** `dotnet test … --filter "Operasyon=<ad>" -- RunConfiguration.TreatNoTestsAsError=true`.

**Neden ad başına çalıştırma:** `dotnet test` eşleşen test yokken de başarılı biter; `TreatNoTestsAsError=true` bunu
hataya çevirir ama bütün çalıştırmaya uygulanır. Tek birleşik filtrede (`Operasyon=a|Operasyon=b`) testi olmayan ya da
yanlış yazılmış bir ad, diğer adın testleri sayesinde sessizce geçerdi. Bedeli: ad başına bir test oturumu (#93).

**Planlanan, henüz yok:** `ConnectionStrings__GenApp` ortam değişkeni (testlerin ayağa kaldırdığı API bağlantı
dizesini buradan alır; yoksa testler başarısız olur); şemayı kuran adım (`dotnet tool restore`,
`dotnet ef database update`; `docs/database-schema.md`); entegrasyon testi adımı (#68).

### 7. Arayüz (COMMAREA) kuralları yalnızca GnuCOBOL'da test edilir

**COMMAREA**, eski sistemde programların birbirine bilgi aktardığı ortak veri alanıdır (`docs/srs.md` 1.3). Arayüz
kuralları bu alanın kendisini anlatır: hiç gelmezse ABEND (01-10), kısa gelirse `98` (01-11), veri katmanı programı
doğrudan çağrılırsa ne olduğu (01-16 ve sonrası). Bunlar C# testine çevrilmez:

- **Yeni sistemde COMMAREA yoktur.** Eşleme tablosunda `98` → `400` vardır (`docs/api-design.md` §3, ADR 0002), ama
  bu `400`'ün gövdesinde `returnCode` yerine hatalı alanların listesi döner; bu yüzden eşdeğerlik ölçülemez.
- **Bu kurallar eski programların çağrı sözleşmesine aittir,** sigorta işine değil; ancak eski kodu çalıştırarak
  ölçülebilirler. Düzenekte sürücü program `EIBCALEN`'i ve COMMAREA'yı kurar (ADR 0004 Karar 4). LGAPOL01 denemesinde
  (ölçüm değil; ADR 0004, "Neyi ölçebiliyoruz") 10 baytlık COMMAREA `98`, 32500 baytlık `00` döndürdü.

Müşteri numarasıyla ilgili dört arayüz kuralının API'de karşılığı vardır. 02-13'te `1000000001`'in en soldaki hanesi
atılır ve müşteri 1 sorgulanır (B3: derleyicinin keserek taşıması). 03-16'da (B3, B4) Db2'de müşteri 1 güncellenir ama
VSAM okuması başarısız olur; sonuç belirsizdir (`81` + ABEND). Sayısal olmayan numarada (02-14, 03-17) sonuç
belirsizdir. Yeni sistemde numara adreste tam sayıdır (`docs/api-design.md` §1): bu dört satır bilinçli sapma adayıdır.

## Değerlendirilen seçenekler

| Seçenek | Neden seçilmedi |
|---|---|
| Tek birleşik filtre (`Operasyon=a\|Operasyon=b`, #13'teki ilk öneri) | Testi olmayan ya da yanlış yazılmış bir ad sessizce geçer (Karar 6). |
| Test ekibinin birim testi yazması | Testler koddan önce yazılır; servis sınıfları yokken birim testleri derlenmez ve derleme adımını kırar. Birim testinin beklentisi sınıfın tasarımından çıkar; eşdeğerlik ise belgeden çıkan dış davranışla ölçülmelidir. Yapım ekibinin birim testleri bu ADR'nin kapsamı dışındadır. |
| Bütün testleri her zaman çalıştırmak | Kodu olmayan operasyonun testi kırmızı olur, test PR'ı birleşemez (Karar 5). |
| Arayüz kurallarını C#'a taşımak | C#'ta önce COMMAREA'yı taklit etmek gerekir; test yeni sistemi değil, o taklidi ölçer (Karar 7). |

## Sonuçlar

**Olumlu**
- Test PR'ları koddan önce birleşebilir; testler kodu görmeden, belgeden yazılır.
- Kırmızı bir testin adı bakılacak COBOL satırını gösterir.
- Testi olmayan ya da yanlış yazılmış operasyon adı CI'ı kırmızı yapar, sessizce geçmez.

**Olumsuz ve kabul ettiklerimiz**
- **Etkinleştirme disiplinine bağlıyız:** Dosyaya eklenmeyen operasyonun testleri hiç çalışmaz ve bunu hiçbir adım
  fark etmez. Etkinleştirme sırasına uyulmazsa testler kırmızı olur (Karar 5).
- **Yanlış yazılmış etiket:** Böyle bir test de çalışmaz; aynı operasyonun başka testi varsa bu fark edilmez.
- **CI özeti iki durumu ayırmaz:** "Etiketli test yok" ile "test başarısız" aynı hatayı verir (#93, `ci.yml:132-135`).
- **Boş `houseName`:** 01-01 ve 02-01 boş `houseName` gönderip cevapta `""` bekler; API boş metni reddeder ya da
  `null` dönerse kırmızı olurlar. 03-01 de ön koşulunda aynı değeri gönderir.
- **Belirsiz seçim:** Numara aralığı tanımlı değil; API `999999999`'u `400` ile reddederse 02-02 testi kırmızı olur.
- **Veritabanı sıfırlanmaz:** Her çalıştırma yeni kayıt ekler.
- **Bilinen tutarsızlıklar** (bu ADR düzeltmez): `tests/README.md`'deki örnek test adı Karar 3'e uymaz; dosya
  eşdeğerlik kodları arasında `98`'i (bkz. Karar 7) ve `99`'u (API tasarımı §3: "oluşmaz") sayar.
  `MusteriSorgulaTests.cs` "Doğrulanmayanlar" etiketini kullanmaz. `ci.yml:3-4` ve `:38-39`'daki yorumlar eskidir.
  Bağlantı dizesi ve şema adımı eklenmeden bir operasyon etkinleştirilirse CI kırmızı olur.

## Açık sorular

- **Boş metin:** `firstName`, `lastName`, `phoneMobile` boş gelirse kabul edilir mi; bunlar ve `houseName` (API tasarımı
  §6 örneğinde istekte boş) cevapta `""` mi `null` mı? 01-08, 03-10 buna bağlı.
- **Olmayan müşteriye `PUT`:** `404` / `"01"` mi döner? (03-02)
- **İstekte `customerNumber`:** Gelirse yok mu sayılır, `400` mü döner? (01-07)
- **Güncellemede -913 (03-05):** Eski kod `90`; `returnCode` aynı kalır, yalnızca HTTP `500` → `503` ve `type`
  (`database-error` → `database-busy`) değişir. ADR 0002 Karar 8 sapmayı yalnızca sorgulama için kaydeder.
- **01-06:** Eski sistem `CUSTOMER_SECURE` kaydı yazılamasa da `00` döndürür; yeni sistemde NFR-04 gereği işlemin tamamı
  geri alınır (kesin karar ADR 0003'te, henüz yazılmadı: #75). Bilinçli sapma olarak kaydedilmeli mi?
- **10 haneli ve sayısal olmayan numara** (02-13, 03-16, 02-14, 03-17): Bilinçli sapma olarak kaydedilmeli mi (Karar 7)?
- **Çevrilmeyen 20 satırın takibi:** Belgeler netleşince hangileri (örn. 01-07, 01-08, 03-10) hangi işte çevrilecek?
- **ADR 0002 "Önerildi" durumunda:** Beklenen cevaplar ona dayanır; değişirse testler de değişir.
- **Mutasyon testi CI'da çalışacak mı?** #53 CI'dan söz etmez.
- **Entegrasyon testleri `tests/active-operations.txt` filtresine bağlı olacak mı?**

## Kaynaklar

- [ADR 0002](0002-rest-api.md), [ADR 0004](0004-legacy-test-harness.md), `docs/api-design.md` (§1, §2.5, §3, §4.1, §6),
  `docs/srs.md` (1.3, NFR-01..04, NFR-10, NFR-11), `docs/database-schema.md`
- `tests/README.md`, `tests/active-operations.txt`, `.github/workflows/ci.yml`, `tests/predictions/`,
  `tests/GenApp.EquivalenceTests/`, `tests/gnucobol/README.md`
- İşler: #13, #19, #53, #68, #75, #84. PR'lar: #93, #99, #101.
