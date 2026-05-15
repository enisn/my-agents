---
name: abp-release-qa-orchestrator
description: Generate ABP/VOLO/Lepton branch-diff QA plans and create assigned Turkish issues in vs-internal.
---

# ABP Release QA Orchestrator

Automates repeatable release-QA preparation for ABP ecosystem repositories:
- `C:\P\abp`
- `C:\P\volo`
- `C:\P\lepton`

Produces feature-grouped QA test-plan markdown files, converts issue content to Turkish, then creates 3 GitHub issues in `C:\P\vs-internal` assigned to `gizemmutukurt`.

## Input Contract

Required:
- `framework_from` (example: `10.0`)
- `framework_to` (example: `10.1`)

Optional:
- `lepton_from`
- `lepton_to`

## Branch Derivation Rules

Framework repos (`abp`, `volo`):
- source branch: `rel-{framework_from}`
- target branch: `rel-{framework_to}`

Lepton repo (`lepton`):
- If `lepton_from` / `lepton_to` are provided, use them directly.
- Otherwise apply default offset rule:
  - `lepton_major = framework_major - 5`
  - `lepton_minor = framework_minor`
  - branch names: `rel-{derived_version}`

Example:
- `framework_from=10.0`, `framework_to=10.1`
- derived lepton: `5.0 -> 5.1`
- lepton branches: `rel-5.0` and `rel-5.1`

## Workflow

1. Analyze branch delta in `C:\P\abp` (`rel-{from}`...`rel-{to}`) and generate concise, feature-grouped QA markdown at ABP repo root.
2. Analyze branch delta in `C:\P\volo` and generate same-style markdown at VOLO repo root.
3. Analyze branch delta in `C:\P\lepton` and generate same-style markdown at Lepton repo root.
4. For each repo, create full merge-PR exhaustive set from branch diff as baseline, then exclude bot PRs by author/login (primary match `github-actions[bot]`, also `github-actions`) and exclude bot-authored auto-sync titles matching `^Merge branch dev with rel-\d+\.\d+$`.
5. Default issue-generation mode is **UI test team mode**: build scenarios from `ui_testable_set` (not raw exhaustive set). Include backend/app changes when user-facing impact is testable via UI route/page/flow/message/visibility; exclude infra-only/technical-only changes not UI-verifiable.
6. Validate coverage rule before final issue body in UI mode: `ui_testable_set - scenario_pr_set = 0`; if not zero, auto-append/adjust test cases until zero. Note: in UI mode `scenario_pr_set`, by design, can be a subset of non-bot exhaustive set.
7. Translate each generated doc content to Turkish in concise issue-friendly form.
8. In `C:\P\vs-internal`, create 3 GitHub issues via `gh issue create`, assigning `gizemmutukurt` for each.

## QA Test Plan Document Format (for each repo)

Create one markdown file in each repo root named exactly:
- `rel-{from}-to-rel-{to}-changelog-and-testing-scenarios.md`

Required sections:
1. `# QA Test Plan: {repo} {from} -> {to}`
2. `## Scope`
3. `## Feature Groups`
4. `## Test Cases` (grouped by feature)
   - UI mode'da her `ui_testable_set` PR'ı en az bir test-case bloğunda yer almalıdır.
   - For each test case include (Turkish terms): `Test Case ID/Adı`, `Etkilenen PR/Commit Referansları` (yalnızca tam URL), `Nereden Test Edilir`, `Etkilenen Yerler`, `Test Adımları`, `Beklenen Sonuç`, `Efor Sınıfı (XS/SM/MD/LG/XL)`, `Efor Gerekçesi`, `Tahmini Süre` (opsiyonel), `Öncelik (P0/P1/P2)`
   - Efor sınıfı zorunludur; XS/SM/MD/LG/XL viewport/breakpoint değil, test efor seviyesidir: `XS: çok düşük efor`, `SM: düşük efor`, `MD: orta efor`, `LG: yüksek efor`, `XL: çok yüksek efor`.
5. `## Risk-Based Priority` (P0/P1/P2)
6. `## Notes` (mention if based on PR mapping or direct commits)

## Issue Reference Rules (Critical)

- PR referansları issue içeriğinde sadece tam URL olarak verilir (örnek: `https://github.com/abpframework/abp/pull/12345`), `#12345` formatı kullanılmaz.
- Test-case grouped yapı zorunludur: her test case bloğunun altında kendi `Etkilenen PR/Commit Referansları` listesi bulunur.
- Test case blokları markdown checkbox formatıyla yazılır (`- [ ]`) ve her test case için checklist girişi bulunur.
- Her test case bloğunda `Efor Sınıfı (XS/SM/MD/LG/XL)` ve `Efor Gerekçesi` alanları bulunmalıdır; `Tahmini Süre` alanı opsiyoneldir.
- UI mode'da her `ui_testable_set` PR bir test-case bloğuna map edilmelidir; PR'lar issue sonunda ayrı toplu liste olarak tekrar edilmez.
- PR eşleştirmesi yoksa ilgili test case altında tam commit URL verilir (örnek: `https://github.com/abpframework/abp/commit/<sha>`).
- Tüm repolarda (ABP, VOLO, Lepton) referanslar her test case altında tam PR URL (veya zorunlu durumda commit URL) olarak yazılır.
- Tüm repolarda issue body self-contained olmalıdır: yerel markdown dosya yolu (`C:\P\...\.md`) referans olarak verilmez; gerekli özet, değişiklik grupları ve test case detayları issue body içinde doğrudan yer alır.
- Mevcut issue düzenleniyorsa mevcut `@username` mention'ları korunur; yeni içerik mention'ları silmez/bozmaz.

## PR Kapsama ve Hariç Tutma Kuralları

- Hariç tutma kuralı (author/login kontrolü): author login aşağıdakilerden biriyle eşleşiyorsa PR kapsam dışıdır:
  - `github-actions[bot]`
  - `github-actions`
- Başlık bazlı güvenlik kuralı: title `^Merge branch dev with rel-\d+\.\d+$` regex'i ile eşleşen bot-author'lı auto-sync/auto-merge PR'lar kapsam dışıdır.
- Örnek eşleşen başlıklar: `Merge branch dev with rel-10.1`, `Merge branch dev with rel-10.2`, `Merge branch dev with rel-11.0`.
- `exhaustive PR set`: Branch diff'ten çıkan full merge PR baseline kümesi, ancak yukarıdaki bot author/login eşleşmeleri ve bot-authored `^Merge branch dev with rel-\d+\.\d+$` başlıklı auto-sync PR'lar hariç.
- `ui_testable_set` (varsayılan issue generation seti): non-bot exhaustive kümeden UI'da doğrulanabilir etkisi olan PR'lar (route/page/flow/message/visibility etkisi olan backend/app değişiklikleri dahil); infra-only/technical-only UI'dan doğrulanamayan değişiklikler hariç.
- `scenario_pr_set`: Test-case bloklarındaki `Etkilenen PR/Commit Referansları` altında verilen PR URL'lerinden oluşan küme.
- Varsayılan (UI mode) zorunlu doğrulama: `ui_testable_set - scenario_pr_set = 0`.
- Not: UI mode'da `scenario_pr_set`, tasarım gereği non-bot `exhaustive PR set` kümesinin alt kümesi olabilir.
- Sonuç sıfır değilse eksik `ui_testable_set` PR'larını kapsayacak şekilde test-case bloklarını otomatik ekle/güncelle ve denklemi tekrar kontrol et.
- Bot PR'ları (`github-actions[bot]`, `github-actions`) hem exhaustive set oluşturma aşamasında hem kapsama doğrulamasında dışlanır.

## Issue Language Rule

All issue titles and bodies MUST be in Turkish.

## Turkish Character Quality Rule

- Türkçe issue başlıkları ve gövdeleri doğru Türkçe karakterlerle yazılmalıdır: `ç, ğ, ı, İ, ö, ş, ü`.
- ASCII transliterasyon (örn. `saglikli`, `guncelleme`) kabul edilmez.
- Teknik token/path/URL değerleri aynen korunur; doğal dil anlatımı doğru Türkçe karakterlerle yazılır.

## Issue Template (Turkish)

Title:
- `QA Test Plan: {RepoAdi} {from} -> {to}`

Body:

```md
## Özet
- {Sürüm geçiş kapsamının kısa özeti}

## Değişiklik Grupları
- {Özellik grubu 1}
- {Özellik grubu 2}

## Test Senaryoları
### {Grup 1}
- [ ] **Test Case ID/Adı**: {TC-001 / Test adı}
- **Etkilenen PR/Commit Referansları**:
  - `https://github.com/<org>/<repo>/pull/123`
  - `https://github.com/<org>/<repo>/pull/124`
  - *(PR eşleşmesi yoksa ilgili commit URL'leri)* `https://github.com/<org>/<repo>/commit/<sha>`
- **Nereden Test Edilir**: {UI/API/Servis ekranı veya uç noktası}
- **Etkilenen Yerler**: `{src/...}`, `{modules/...}`
- **Test Adımları**: {Adımlar}
- **Beklenen Sonuç**: {Beklenen sonuç}
- **Efor Sınıfı (XS/SM/MD/LG/XL)**: {XS/SM/MD/LG/XL}
- **Efor Gerekçesi**: {Seçilen efor sınıfının kısa gerekçesi}
- **Tahmini Süre**: {Opsiyonel: örn. 30 dk / 2 saat}
- **Öncelik (P0/P1/P2)**: {P0/P1/P2}

### {Grup 2}
- [ ] **Test Case ID/Adı**: {TC-002 / Test adı}
- **Etkilenen PR/Commit Referansları**:
  - `https://github.com/<org>/<repo>/pull/125`
  - *(PR eşleşmesi yoksa)* `https://github.com/<org>/<repo>/commit/<sha>`
- **Nereden Test Edilir**: {UI/API/Servis ekranı veya uç noktası}
- **Etkilenen Yerler**: `{...}`
- **Test Adımları**: {Adımlar}
- **Beklenen Sonuç**: {Beklenen sonuç}
- **Efor Sınıfı (XS/SM/MD/LG/XL)**: {XS/SM/MD/LG/XL}
- **Efor Gerekçesi**: {Seçilen efor sınıfının kısa gerekçesi}
- **Tahmini Süre**: {Opsiyonel: örn. 45 dk / 1.5 saat}
- **Öncelik (P0/P1/P2)**: {P0/P1/P2}

## Öncelik ve Risk
- P0: {Kritik alanlar}
- P1: {Orta seviye alanlar}
- P2: {Düşük risk alanları}

## Referans
- Karşılaştırma: `{from_branch}...{to_branch}`
- Not: {PR eşleştirme durumu / commit URL bilgisi / bot PR hariç tutma bilgisi (`github-actions[bot]` öncelikli, ayrıca `github-actions`)}
- Kural (ABP/VOLO/Lepton): Issue gövdesi self-contained olmalı; yerel markdown dosya yolu referansı (`C:\P\...\.md`) verme, gerekli içerik issue gövdesinde yer almalı.
- Kural: Issue sonunda tam PR listesi (exhaustive dump) verme; PR referansları yalnızca ilgili test-case bloklarında yer almalı.
```

## gh CLI Command Examples (HEREDOC)

Run in `C:\P\vs-internal`:

```bash
gh issue create \
  --title "QA Test Plan: ABP 10.0 -> 10.1" \
  --assignee "gizemmutukurt" \
  --body "$(cat <<'EOF'
## Özet
- ABP 10.0 -> 10.1 geçişindeki değişiklikler için QA kapsamı.

## Değişiklik Grupları
- Identity ve Permission akışları
- UI/UX ve tema etkileri

## Test Senaryoları
### Identity
- [ ] **Test Case ID/Adı**: TC-ABP-001 / Kullanıcı oluşturma, rol atama, giriş akışı
- **Etkilenen PR/Commit Referansları**:
  - https://github.com/abpframework/abp/pull/12345
  - https://github.com/abpframework/abp/pull/12367
- **Nereden Test Edilir**: ABP Suite kullanıcı yönetimi ekranı ve ilgili Identity API uç noktaları.
- **Etkilenen Yerler**: `modules/identity`, `framework/src/Volo.Abp.Identity`
- **Test Adımları**: Kullanıcı oluştur, rol ata, kullanıcıyla giriş yap.
- **Beklenen Sonuç**: Rol bazlı erişim doğru çalışır.
- **Efor Sınıfı (XS/SM/MD/LG/XL)**: LG
- **Efor Gerekçesi**: Kimlik ve yetki akışlarında birden fazla kritik adım ve rol kombinasyonu bulunduğu için yüksek efor gerekir.
- **Tahmini Süre**: 2 saat
- **Öncelik (P0/P1/P2)**: P0

## Öncelik ve Risk
- P0: Kimlik doğrulama ve yetkilendirme

## Referans
- Karşılaştırma: `rel-10.0...rel-10.1`
- Not: ABP issue gövdesi self-contained hazırlandı; yerel markdown dosya yolu referansı verilmedi, tüm referanslar test case altında tam URL olarak verildi ve bot PR'ları (`github-actions[bot]`, `github-actions`) kapsam dışı bırakıldı.
EOF
)"
```

```bash
gh issue create \
  --title "QA Test Plan: VOLO 10.0 -> 10.1" \
  --assignee "gizemmutukurt" \
  --body "$(cat <<'EOF'
## Özet
- VOLO sürüm geçiş QA kapsam planı.

## Değişiklik Grupları
- Ticari modül akışları
- Lisans/ödeme ve tenant etkileri

## Test Senaryoları
### Ticari Modüller
- [ ] **Test Case ID/Adı**: TC-VOLO-001 / Lisans doğrulama ve tenant erişim akışı
- **Etkilenen PR/Commit Referansları**:
  - https://github.com/volosoft/volo/pull/4567
  - https://github.com/volosoft/volo/commit/abcdef1234567890abcdef1234567890abcdef12
- **Nereden Test Edilir**: Ticari modül yönetim paneli, lisans doğrulama servisi ve SaaS tenant yönetim ekranları.
- **Etkilenen Yerler**: `modules/license`, `modules/saas`
- **Test Adımları**: Lisans kontrolünü doğrula, tenant bazlı modül erişimini test et.
- **Beklenen Sonuç**: Lisans ve tenant davranışı beklenen şekilde çalışır.
- **Efor Sınıfı (XS/SM/MD/LG/XL)**: XL
- **Efor Gerekçesi**: Lisans, tenant ve ticari modül bağımlılıkları nedeniyle kapsam geniş ve hata etkisi yüksek olduğundan çok yüksek efor gerekir.
- **Tahmini Süre**: 3 saat
- **Öncelik (P0/P1/P2)**: P0

## Öncelik ve Risk
- P0: Ödeme/lisans ve tenant etkileri

## Referans
- Karşılaştırma: `rel-10.0...rel-10.1`
- Not: VOLO issue gövdesi self-contained hazırlanır; gerekli özet ve test case içerikleri doğrudan yer alır, yerel markdown dosya yolu referansı verilmez, bot PR'ları (`github-actions[bot]`, `github-actions`) hariç tutulur.
EOF
)"
```

```bash
gh issue create \
  --title "QA Test Plan: Lepton 5.0 -> 5.1" \
  --assignee "gizemmutukurt" \
  --body "$(cat <<'EOF'
## Özet
- Lepton tema/bileşen değişiklikleri için QA kapsamı.

## Değişiklik Grupları
- Tema ve frontend bileşenleri

## Test Senaryoları
### Tema
- [ ] **Test Case ID/Adı**: TC-LEPTON-001 / Tema varyantları ve responsive davranış
- **Etkilenen PR/Commit Referansları**:
  - https://github.com/volosoft/lepton/pull/891
- **Nereden Test Edilir**: LeptonX demo uygulaması ana sayfa, menü ve form ekranları.
- **Etkilenen Yerler**: `themes/leptonx`, `src/LeptonX.Theme`
- **Test Adımları**: Ana sayfa, menü ve kritik formları farklı boyutlarda doğrula.
- **Beklenen Sonuç**: UI kırılmaları olmadan tutarlı görünüm sağlanır.
- **Efor Sınıfı (XS/SM/MD/LG/XL)**: MD
- **Efor Gerekçesi**: Tema ve bileşen doğrulaması orta kapsamlıdır; kritik akışlar mevcut ancak bağımlılık sayısı sınırlıdır.
- **Tahmini Süre**: 90 dk
- **Öncelik (P0/P1/P2)**: P0

## Öncelik ve Risk
- P0: UI kırılmaları ve kritik akışlarda görünürlük sorunları

## Referans
- Karşılaştırma: `rel-5.0...rel-5.1`
- Not: Lepton issue gövdesi self-contained hazırlandı; yerel markdown dosya yolu referansı verilmedi, referanslar test case altında tam URL olarak verildi ve bot PR'ları (`github-actions[bot]`, `github-actions`) kapsam dışı bırakıldı.
EOF
)"
```

Coverage verification pattern (before each `gh issue create`):

```bash
# 1) Baseline exhaustive PR set: branch diff full merge PR URL'leri; author/login `github-actions[bot]` (öncelikli) veya `github-actions` ise hariç
# 2) Ayrıca bot-authored `^Merge branch dev with rel-\d+\.\d+$` başlıklı auto-sync PR'ları exhaustive baseline'dan çıkar
# 3) UI mode varsayılan: ui_testable_set oluştur (UI etkisi doğrulanabilir backend/app değişiklikleri dahil, infra-only/technical-only hariç)
# 4) Scenario PR set: issue body'deki test-case PR URL'leri
# 5) Kural (UI mode): ui_testable_set - scenario_pr_set = 0
# 6) Fark varsa eksik UI-testable PR'lar için yeni test-case bloğu ekle ve tekrar kontrol et
```

## Validation Checklist

- [ ] `C:\P\abp` içinde QA markdown dokümanı oluştu.
- [ ] `C:\P\volo` içinde QA markdown dokümanı oluştu.
- [ ] `C:\P\lepton` içinde QA markdown dokümanı oluştu.
- [ ] `C:\P\vs-internal` içinde 3 issue oluşturuldu.
- [ ] Tüm issue URL'leri kaydedildi.
- [ ] Her issue assignee değeri `gizemmutukurt`.
- [ ] Author/login `github-actions[bot]` (öncelikli) veya `github-actions` olan PR'lar considered/exhaustive PR setinden çıkarıldı.
- [ ] Bot-author'lı auto-sync/auto-merge PR başlıkları (`^Merge branch dev with rel-\d+\.\d+$`; örn. `Merge branch dev with rel-10.1`, `Merge branch dev with rel-10.2`, `Merge branch dev with rel-11.0`) kapsam dışı bırakıldı.
- [ ] UI-testable filtreleme gerekçesi açıklandı (neden dahil/neden hariç).
- [ ] Kapsama doğrulaması yapıldı (UI mode): `ui_testable_set - scenario_pr_set = 0`.
- [ ] Mevcut issue düzenleme senaryosunda mevcut `@username` mention'ları korundu.
- [ ] Her test case markdown checkbox (`- [ ]`) ile yazıldı.
- [ ] Her test case bloğunda `Efor Sınıfı (XS/SM/MD/LG/XL)` ve `Efor Gerekçesi` alanları yer alıyor; `Tahmini Süre` alanı varsa tutarlı şekilde dolduruldu.
- [ ] Issue gövdelerinde PR referansları yalnızca test-case bloklarında verildi (sonda toplu PR listesi yok).
- [ ] Tüm repolarda (ABP/VOLO/Lepton) issue gövdeleri self-contained hazırlandı; yerel markdown dosya yolu referansı (`C:\P\...\.md`) kullanılmadı.
- [ ] Türkçe dil kalitesi kontrol edildi: doğal dilde ASCII transliterasyon yok, Türkçe karakterler doğru kullanıldı.

## Failure Handling

- PR eşleştirmesi mevcut değilse commit aralığını (`from...to`) temel al.
- Her ilgili test case altında tam commit URL ver ve şu notu ekle: "PR eşleştirmesi bulunamadı, commit URL referansları kullanıldı."
- Eşleşmeyen alanlar için `Notes/Referans` bölümüne takip notu ekle.
- Kapsama denklemi sıfır değilse eksik PR'lar için yeni test-case blokları ekle ve tekrar doğrula.
