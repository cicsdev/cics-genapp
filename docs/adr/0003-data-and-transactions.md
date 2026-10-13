# ADR 0003: Db2 ve VSAM'den PostgreSQL'e data ve transaction kararı

- **Durum:** Önerildi
- **Tarih:** 2026-10-11
- **Yazan:** Hasan
- **İlgili:** [Database şeması](../database-schema.md) (#15, PR #92), [ADR 0002](0002-rest-api.md) (REST API ve return code mapping), [API tasarımı](../api-design.md), [SRS](../srs.md) (NFR-04, NFR-05), #75

## Bağlam

Eski GenApp customer ve policy data'sını iki yerde tutar:

- **Db2:** 8 table (`customer`, `customer_secure`, `policy`, dört policy type table'ı ve
  `claim`).
- **VSAM:** iki KSDS dosyası. `KSDSCUST` customer record'larının, `KSDSPOLY` policy
  record'larının kısaltılmış bir kopyasıdır ([database-schema.md](../database-schema.md),
  "VSAM dosyaları").

Bir write operasyonu önce Db2'ye, ardından VSAM'a yazar. IBM bunu bilerek böyle kurmuş:
*"The application uses a two-phase commit to store customer and policy data in Db2 and, if
successful, it updates VSAM. The requirement for a VSAM file is not a best practice,
but is provided as a way to test two-phase commit processing in CICS."*
(`base/Architecture.md:48-49`).

**Eski sistemde transaction nasıl işliyor.** CICS'te bir task, Db2 ve recoverable VSAM
(`KSDSCUST` ve `KSDSPOLY` `LOG(UNDO)` ile tanımlı, `adef121.jcl:20`, `:45`)
değişikliklerini tek bir unit of work olarak tutar. Task normal biterse hepsi commit edilir. Task ABEND ederse ya da bir program
`EXEC CICS SYNCPOINT ROLLBACK` çağırırsa hepsi birlikte rollback edilir. Bu yüzden VSAM'a
yazma başarısız olduğunda Db2'ye yazılan da geri alınır. Ancak rollback kararı tek bir yerde
değil, katmanlara dağılmış durumda:

- Bazı data access programları rollback'i kasıtlı ABEND ile tetikler
  (örneğin `lgapdb01.cbl:392-393`: *"Issue Abend to cause backout of update to Policy table"*).
- Bazı VSAM programları error'da ABEND eder (`LGV0`…`LGV4`).
- Screen programları, return code `00` değilse ekleme ve silmede
  `SYNCPOINT ROLLBACK` yapar (`lgtestc1.cbl:133`, `lgtestp1.cbl:120`, `:144`).

**Optimistic locking.** Her policy row'u bir `LASTCHANGED` timestamp'i taşır. Kullanıcı
policy'yi sorguladığında bu değer screen'e gelir, update isteğinde geri gönderilir.
`LGUPDB01` gelen değeri Db2'deki değerle karşılaştırır (`lgupdb01.cbl:278`). Farklıysa,
yani arada başka biri policy'yi değiştirmişse, update yapılmaz ve return code `02`
set edilir (`:346`). Eşitse update yapılır ve `LASTCHANGED = CURRENT TIMESTAMP` ile
yenilenir (`:322`). Customer table'ında böyle bir column yoktur.

**Yeni sistemde durum.**
- Tek bir PostgreSQL database'i ve EF Core kullanılıyor (#15).
- Şema hazır. VSAM için table oluşturulmadı.
- `policy.last_changed` EF Core'da concurrency token olarak işaretli
  (`PolicyConfiguration.cs`).
- Henüz hiçbir operasyon kodu transaction açmıyor.
- SRS iki şey istiyor:
  - Birden fazla table'a yazan her işlem tek bir database transaction'ı olmalı (NFR-04).
  - Eşzamanlı update'te son yazan öncekinin değişikliğini ezmemeli (NFR-05).

Bu ADR, şema belgesinin "ADR 0003'e bırakılanlar" bölümündeki soruları kesinleştirir:

| Şema belgesindeki soru | Cevap |
|---|---|
| Db2 + VSAM two-phase commit'in yerini tek PostgreSQL transaction'ı alacak mı? | Evet, Karar 2 |
| VSAM write'ı başarısız olunca dönen code'lar nasıl korunacak? | Oluşmazlar, Karar 2 (error mapping) |
| `KSDSCUST` record size tutarsızlığı (225 / 82 byte) | Yeni sistemi etkilemez, Karar 1 |

Şema belgesindeki tip eşlemesi de Karar 3'ün dayanağıdır: `last_changed`'in `timestamp
without time zone` olması, timestamp'in mikrosaniyeye kırpılmasını ve `Kind` kuralını
gerektirir.

## Karar

**1. Tek database; VSAM'ın ayrı bir karşılığı olmayacak.**

- 8 Db2 table'ı, aynı adlarla tek bir PostgreSQL database'indeki 8 table'a taşınır
  ([database-schema.md](../database-schema.md)).
- `KSDSCUST`'in karşılığı `customer` table'ıdır. `KSDSPOLY`'nin karşılığı `policy` ve ilgili
  policy type table'ıdır.
- VSAM'a yazan programların (`LGACVS01`, `LGUCVS01`, `LGAPVS01`, `LGDPVS01`, `LGUPVS01`)
  C#'ta karşılığı yazılmaz. Yaptıkları write, aynı operasyonun Db2 write'ında zaten vardır.
- VSAM'dan okuyan `LGICVS01` ve `LGIPVS01` random record seçen test yardımcılarıdır; kapsam
  dışıdır.
- `base/data` altındaki VSAM sample dosyaları ayrıca taşınmaz. Sample data'nın kaynağı Db2
  sample data'sıdır (#51).
- Şema belgesinde not edilen `KSDSCUST` record size tutarsızlığı (225 / 82 byte) yeni sistemi
  etkilemez, çünkü VSAM record'u hiç oluşturulmaz.

**2. Her operasyon tek bir database transaction'ında çalışır.**

Bir API request'i bir operasyondur, bir operasyon da bir transaction'dır: operasyonun bütün
write'ları ya birlikte commit edilir ya da hiçbiri yazılmaz.

- **Transaction boundary application layer'dadır** (operasyonu yürüten handler/service).
  Controller ve repository transaction açmaz. Bu, eski sistemde screen'deki
  `SYNCPOINT ROLLBACK`'in ve data access'teki kasıtlı ABEND'lerin yerini tek bir yerde alır.
- **Tek `SaveChanges` yeterliyse** ek bir şey gerekmez; EF Core bir `SaveChanges` çağrısını
  zaten tek transaction'da çalıştırır.
- **Generated key gerektiren çok adımlı write'larda explicit transaction açılır.** Yeni
  `customer_number`'ın `customer_secure`'a, yeni `policy_number`'ın policy type table'ına
  yazılması iki ayrı `SaveChanges` gerektirir, çünkü bu entity'ler arasında navigation yok:

  ```csharp
  await using var tx = await db.Database.BeginTransactionAsync(ct);
  db.Policies.Add(policy);
  await db.SaveChangesAsync(ct);            // policy_number generate edilir
  motor.PolicyNumber = policy.PolicyNumber;
  db.MotorPolicies.Add(motor);
  await db.SaveChangesAsync(ct);
  await tx.CommitAsync(ct);                 // exception olursa commit'e gelinmez, dispose rollback eder
  ```

- **Isolation level değişmez:** PostgreSQL default'u olan `READ COMMITTED` kullanılır. Eski
  sistemin Db2 package'ları da bunun Db2'deki karşılığı olan Cursor Stability ile bind
  edilmiş (`db2bind.jcl:15`, bütün package'larda `ISO(CS)`).
- **Error mapping:** Transaction içinde beklenmeyen bir database error'unda transaction
  rollback edilir ve return code `90` döner. HTTP karşılığı ADR 0002'deki gibidir: 500,
  deadlock ve timeout'ta 503 (karar 8). VSAM'a ait `80`, `81`, `82` yeni sistemde oluşmaz.

**3. `LASTCHANGED` kontrolü, `policy.last_changed` üzerinde EF Core optimistic locking ile yapılır.**

- **Inquire:** Policy inquire response'u `lastChanged` değerini döndürür. Update request'i bu
  değeri değiştirmeden geri gönderir (ADR 0002 karar 7, API tasarımı bölüm 5).
- **Update'te iki değer set edilir:**
  - **Original value:** EF Core'a `last_changed`'in original value'su olarak client'ın
    gönderdiği değer verilir:
    `db.Entry(policy).Property(p => p.LastChanged).OriginalValue = request.LastChanged;`
    Bu satır olmazsa EF Core, aynı request içinde database'den okuduğu güncel değeri
    karşılaştırır ve kontrol hiçbir zaman çakışma bulamaz.
  - **Current value:** Yeni timestamp.
- **Üretilen SQL:**
  `UPDATE policy SET ..., last_changed = @yeni WHERE policy_number = @n AND last_changed = @client_degeri`
  - Satır eşleşmezse EF Core `DbUpdateConcurrencyException` fırlatır. Bu, return code `02`
    (409 Conflict) olarak döner.
  - Policy type table'ının update'i de aynı transaction'dadır; `02` durumunda hiçbir şey
    yazılmaz.
- **Yeni timestamp'in kuralları:**
  - **Tek saat kaynağı uygulamadır.** Hem ekleme hem update'te değer uygulamada set edilir
    (`DateTime.Now`). Column'daki `DEFAULT CURRENT_TIMESTAMP` sadece uygulama dışından
    eklenen row'lar (sample data) içindir.
  - **Mikrosaniyeye kırpılır.** PostgreSQL `timestamp` mikrosaniye tutar, .NET `DateTime`
    100 nanosaniye. Kırpılmazsa client'a dönen değer database'dekinden farklı olur ve bir
    sonraki update haksız yere `02` alır:
    `new DateTime(now.Ticks - now.Ticks % 10, DateTimeKind.Unspecified)`.
  - **`Kind` `Unspecified` olur**, `Utc` olmaz; Npgsql `Utc` değeri `timestamp without time
    zone` column'una yazmayı reddeder ([database-schema.md](../database-schema.md)).
  - Ekleme ve update response'u yeni değeri döndürür. Eski sistem de bunu ekleme ve
    update'ten sonra `SELECT LASTCHANGED INTO CA-LASTCHANGED` ile yapar.
- **Customer update'te concurrency kontrolü olmaz.** Eski sistemde de yoktur (customer
  table'ında timestamp column'u yok). Last write wins davranışı korunur.

**4. Customer ve policy number'ları PostgreSQL identity column'u generate eder.**

- **Eski sistem:** Önce CICS named counter'ı (`GENACUSTNUM`) dener, olmazsa Db2 identity
  column'unu kullanır (`lgacdb01.cbl:199-211`).
- **Yeni sistem:**
  - Named counter'ın karşılığı yoktur. Numara her zaman identity column'dan gelir
    (`START WITH 1000001`), yani eski sistemin ikinci yolu.
  - Sequence değerleri transaction'a dahil değildir; rollback edilen bir ekleme numarayı
    geri vermez. Bu, eski sistemle aynıdır ([database-schema.md](../database-schema.md),
    "Korunan davranışlar").

## Gerekçe

- **Neden VSAM için table yok:** VSAM record'ları Db2'deki data'nın kopyasıdır ve yeni bilgi
  taşımaz. IBM VSAM'ı yalnızca CICS'in two-phase commit'ini göstermek için eklemiş. Tek
  database'te aynı data'yı iki table'da tutmak, eski sistemin kaynaklar arası tutarsızlık
  riskini (bkz. "Sonuçlar") yeni sisteme taşımak olurdu.
- **Neden tek transaction:** Eski sistemin amacı zaten "ya hep ya hiç"tir; yeni sistemde iki
  kaynak kalmadığı için bu, tek bir database transaction'ıyla sağlanır (NFR-04).
  Two-phase commit'e gerek kalmaz.
- **Neden boundary application layer'da:** Bir operasyonun hangi write'ları kapsadığını
  sadece o operasyonun kodu bilir. Repository seviyesinde açılan transaction'lar çok adımlı
  write'ı bölebilir, controller seviyesinde açılan transaction ise HTTP'ye bağımlı olur ve
  test edilmesi zorlaşır.
- **Neden optimistic locking:** Eski sistemin korumaya çalıştığı durum, kullanıcının
  inquire ile update arasında policy'nin başkası tarafından değiştirilmesidir. Bu süre insan
  süresidir (saniyeler, dakikalar); bu kadar uzun bir lock tutmak web'de mümkün değildir.
  Eski sistem de lock'u sadece task içinde (cursor `FOR UPDATE`) tutar, ekranlar arası
  korumayı timestamp karşılaştırması sağlar. Yeni sistemdeki koşullu `UPDATE ... WHERE
  last_changed = ...` aynı korumayı tek bir atomic statement'ta verir. EF Core bunu
  concurrency token ile doğrudan destekler ve şema zaten buna göre kuruldu (#15).
- **Neden `last_changed` ve `xmin` değil:** `lastChanged` hem eski sistemde (`CA-LASTCHANGED`)
  hem API'de (ADR 0002) kullanıcıya görünen bir alan. Ayrı bir version alanı eklemek ya da
  PostgreSQL'in `xmin` system column'unu kullanmak, eşdeğerlik testlerinin karşılaştırdığı
  modelden uzaklaşırdı.

## Değerlendirilen seçenekler

| Seçenek | Neden seçilmedi |
|---|---|
| VSAM'ı ayrı table'larla taklit etmek (`customer_vsam`, `policy_vsam`) | Aynı data iki kez tutulur. Tek database'te bunların tutarlılığı zaten tek transaction'la sağlanacağı için ek bir faydası yok, sadece tutarsızlık riski getirir. |
| Her `SaveChanges`'i kendi transaction'ında bırakmak (EF Core default) | Generated key gerektiren çok adımlı write'larda ilk adım commit edilip ikincisi başarısız olabilir; NFR-04'e aykırı. |
| `TransactionScope` | Async kodda ek ayar gerektirir (`TransactionScopeAsyncFlowOption`); tek database için EF Core'un kendi transaction'ı yeterli ve daha açık. |
| `SERIALIZABLE` isolation | Bu operasyonlar için gereksiz; serialization error'larında retry mantığı yazmayı gerektirir. Eski sistem de `ISO(CS)` ile, yani Read Committed karşılığıyla çalışıyor. |
| Pessimistic lock (`SELECT ... FOR UPDATE`, eski koda birebir) | Kullanıcı sorgulama ile update arasında beklerken lock tutulamaz; tek request içinde tutulan lock ise koşullu `UPDATE`'in verdiğinden fazlasını vermez. |
| Yeni timestamp'i database'de üretmek (`last_changed = LOCALTIMESTAMP` + `RETURNING`) | Eski sisteme en yakın yol, ama EF Core'un concurrency token akışının dışına çıkıp raw SQL gerektirir. Tek saat kaynağı uygulama olduğu sürece aynı sonucu verir. Uygulama ile database saatleri ayrışırsa yeniden değerlendirilebilir. |

## Sonuçlar

**Olumlu**
- Bir operasyonun bütün write'ları tek yerde, tek transaction'da. Yarıda kalan operasyon
  data'yı tutarsız bırakmaz (NFR-04).
- Eşzamanlı policy update'te ikinci kullanıcı `409` / `02` alır, öncekinin değişikliğini
  ezemez (NFR-05).
- Eski sistemde Db2 ile VSAM arasında oluşabilen tutarsızlıklar yeni sistemde mümkün değil.

**Olumsuz ve kabul ettiklerimiz**
- **`80`, `81`, `82` return code'ları oluşmaz.** Bunlar VSAM'a aittir; ADR 0002 ve API
  tasarımındaki mapping tablosunda kalırlar ama pratikte üretilmezler.
- **Eski sistemin bazı error davranışları bilinçli olarak taşınmaz.** Her biri raporda
  "bilinçli sapma" olarak yazılacak. Customer slice'ındaki örnekler
  ([use-case analizleri](../../legacy-analysis/use-cases/), #17):
  - Customer eklerken `customer_secure` write'ı başarısız olursa eski sistem bu error'u
    kontrol etmez ve customer'ı `00` ile ekler. Yeni sistemde iki write aynı transaction'da
    olduğu için operasyon rollback edilir ve `90` döner.
  - Customer update'te Db2 `UPDATE` başarısız olsa bile eski sistem VSAM record'unu yeniden
    yazar. Yeni sistemde tek kaynak olduğu için bu durum oluşmaz.

  Bu durumlar test ortamında doğal yollarla üretilemediği için eşdeğerlik ölçümünü pratikte
  etkilemez.
- **Saat kaynağı.** Timestamp uygulama sunucusunun saatinden gelir. Birden fazla uygulama
  instance'ı farklı saatlerle çalışırsa `last_changed` değerleri sıralı olmayabilir. Kontrol
  sadece eşitliğe baktığı için bu çakışma tespitini bozmaz.
- **Uygulama kodu kuralları.** Operasyon kodu (#31 ve sonrası) bu ADR'ye göre yazılmalı:
  - transaction'ı application layer'da açmak,
  - `last_changed`'in original value'sunu client'ın gönderdiği değerle set etmek,
  - yeni timestamp'i mikrosaniyeye kırpmak,
  - `DbUpdateConcurrencyException`'ı `02`'ye çevirmek.
