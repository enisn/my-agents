---
name: abp-translator
description: "Add translations to ABP Framework localization files using base language as reference. Use when: (1) adding new translation keys, (2) localizing new features, (3) updating existing translations across multiple languages."
---

# ABP Translator

Add and manage translations in ABP Framework localization files using base language as reference.

## When to Use This Skill

- Adding new localization keys for features
- Translating existing keys to new languages
- Updating translations across multiple language files
- Ensuring all languages have consistent translations
- Working with ABP Framework JSON localization files

## ABP Localization Structure

ABP Framework uses JSON localization files typically located at:

```
{Project}.Application.Contracts/Localization/{ProjectName}/
├── en.json              # English (base language)
├── tr.json              # Turkish
├── fr.json              # French
├── de.json              # German
└── ...
```

### Localization File Format

```json
{
  "culture": "en",
  "texts": {
    "Menu:Home": "Home",
    "Menu:Patients": "Patients",
    "Permission:Patients": "Patients",
    "Permission:Patients.Create": "Create new patient",
    "Patient:Name": "Name",
    "Patient:Email": "Email",
    "Patient:DateOfBirth": "Date of Birth",
    "Patient:AlreadyExists": "A patient with email '{Email}' already exists.",
    "Patient:NotFound": "Patient with ID '{Id}' not found."
  }
}
```

## Translation Workflow

### Step 1: Identify Base Language Keys

First, read the base language file (typically `en.json`) to understand what needs translation:

```json
// en.json
{
  "culture": "en",
  "texts": {
    "Feature:NewFeature": "New Feature",
    "Feature:NewFeature.Description": "Description of new feature",
    "Feature:NewFeature.Title": "New Feature Title"
  }
}
```

### Step 2: Add Translations to Other Languages

For each target language, create/update the translation file with appropriate translations:

#### Turkish (tr.json)

```json
{
  "culture": "tr",
  "texts": {
    "Feature:NewFeature": "Yeni Özellik",
    "Feature:NewFeature.Description": "Yeni özelliğin açıklaması",
    "Feature:NewFeature.Title": "Yeni Özellik Başlığı"
  }
}
```

#### French (fr.json)

```json
{
  "culture": "fr",
  "texts": {
    "Feature:NewFeature": "Nouvelle fonctionnalité",
    "Feature:NewFeature.Description": "Description de la nouvelle fonctionnalité",
    "Feature:NewFeature.Title": "Titre de la nouvelle fonctionnalité"
  }
}
```

#### German (de.json)

```json
{
  "culture": "de",
  "texts": {
    "Feature:NewFeature": "Neue Funktion",
    "Feature:NewFeature.Description": "Beschreibung der neuen Funktion",
    "Feature:NewFeature.Title": "Titel der neuen Funktion"
  }
}
```

## Translation Guidelines

### Key Naming Conventions

| Pattern | Example | Usage |
|----------|----------|--------|
| `Menu:{Name}` | `Menu:Patients` | Menu items |
| `Permission:{Resource}` | `Permission:Patients` | Permission groups |
| `Permission:{Resource}.{Action}` | `Permission:Patients.Create` | Permission actions |
| `{Entity}:{Property}` | `Patient:Name` | Entity properties |
| `{Entity}:{Error}` | `Patient:NotFound` | Error messages |
| `{Feature}:{Message}` | `App:Welcome` | Feature-specific messages |

### Parameterized Translations

When translations contain parameters, use `{ParameterName}` syntax:

```json
{
  "culture": "en",
  "texts": {
    "Patient:EmailAlreadyExists": "A patient with email '{Email}' already exists.",
    "Patient:Created": "Patient '{Name}' has been created successfully.",
    "Patient:Deleted": "Patient with ID '{Id}' has been deleted."
  }
}
```

**Important:** Parameter names must match exactly across all languages.

## Common Translation Patterns

### Permission Translations

```json
{
  "Permission:Patients": "Patients",
  "Permission:Patients.Default": "View patients",
  "Permission:Patients.Create": "Create patients",
  "Permission:Patients.Edit": "Edit patients",
  "Permission:Patients.Delete": "Delete patients",
  "Permission:Patients.Manage": "Manage patients"
}
```

### Entity Property Translations

```json
{
  "Patient:Name": "Name",
  "Patient:Email": "Email",
  "Patient:Phone": "Phone Number",
  "Patient:Address": "Address",
  "Patient:DateOfBirth": "Date of Birth",
  "Patient:Status": "Status"
}
```

### Error Message Translations

```json
{
  "Patient:NotFound": "Patient not found",
  "Patient:EmailAlreadyExists": "Email already exists",
  "Patient:InvalidEmail": "Invalid email address",
  "Patient:NameRequired": "Name is required",
  "Patient:EmailRequired": "Email is required"
}
```

### Success Message Translations

```json
{
  "Patient:Created": "Patient created successfully",
  "Patient:Updated": "Patient updated successfully",
  "Patient:Deleted": "Patient deleted successfully",
  "Operation:Successful": "Operation completed successfully",
  "Operation:Failed": "Operation failed"
}
```

## Translation Best Practices

### Do's

1. **Use simple, clear language** - Avoid idioms and complex phrases
2. **Keep parameter names consistent** - `{Email}`, `{Id}`, `{Name}` etc.
3. **Maintain context** - Consider where translation will be used
4. **Review translations** - Use native speakers or translation services
5. **Keep similar keys together** - Group related translations
6. **Use consistent terminology** - Same words for same concepts
7. **Respect cultural differences** - Date formats, numbers, etc.

### Don'ts

1. **Don't translate parameter placeholders** - Keep `{Email}` as is
2. **Don't use colloquialisms** - They don't translate well
3. **Don't change key names** - Keys should stay in English
4. **Don't translate technical terms** - Keep API, ID, URL, etc.
5. **Don't make translations too long** - UI space constraints
6. **Don't forget special characters** - Accents, umlauts, etc.
7. **Don't use machine translation blindly** - Always review

## Language-Specific Considerations

### Turkish (tr)

```json
{
  "texts": {
    "Menu:Home": "Ana Sayfa",
    "Permission:Patients.Create": "Hasta Oluştur",
    "Patient:Name": "Ad",
    "Operation:Successful": "İşlem başarıyla tamamlandı"
  }
}
```

**Notes:**
- Lowercase 'i' (ı) is different from dotted 'i' (i)
- Use formal address (siz instead of sen)
- Compound words are common

### French (fr)

```json
{
  "texts": {
    "Menu:Home": "Accueil",
    "Permission:Patients.Create": "Créer des patients",
    "Patient:Name": "Nom",
    "Operation:Successful": "Opération réussie"
  }
}
```

**Notes:**
- Noun genders matter (le/la, un/une)
- Formal language preferred
- Accents are required (é, è, à, etc.)

### German (de)

```json
{
  "texts": {
    "Menu:Home": "Startseite",
    "Permission:Patients.Create": "Patienten erstellen",
    "Patient:Name": "Name",
    "Operation:Successful": "Vorgang erfolgreich"
  }
}
```

**Notes:**
- Noun capitalization (all nouns)
- Compound words are common
- Formal address required (Sie)

### Spanish (es)

```json
{
  "texts": {
    "Menu:Home": "Inicio",
    "Permission:Patients.Create": "Crear pacientes",
    "Patient:Name": "Nombre",
    "Operation:Successful": "Operación exitosa"
  }
}
```

**Notes:**
- Formal address (usted)
- Gender agreement required
- Regional variations (Spain vs Latin America)

## Example: Adding Complete Feature Translations

### Step 1: Base Language (en.json)

```json
{
  "culture": "en",
  "texts": {
    "Menu:Appointments": "Appointments",
    "Permission:Appointments": "Appointments",
    "Permission:Appointments.Default": "View appointments",
    "Permission:Appointments.Create": "Create appointments",
    "Permission:Appointments.Edit": "Edit appointments",
    "Permission:Appointments.Delete": "Delete appointments",
    "Appointment:Date": "Appointment Date",
    "Appointment:Doctor": "Doctor",
    "Appointment:Patient": "Patient",
    "Appointment:Status": "Status",
    "Appointment:Status.Scheduled": "Scheduled",
    "Appointment:Status.Completed": "Completed",
    "Appointment:Status.Cancelled": "Cancelled",
    "Appointment:Created": "Appointment created successfully",
    "Appointment:Updated": "Appointment updated successfully",
    "Appointment:Deleted": "Appointment deleted successfully",
    "Appointment:NotFound": "Appointment not found",
    "Appointment:DoctorNotAvailable": "Doctor is not available on this date"
  }
}
```

### Step 2: Turkish (tr.json)

```json
{
  "culture": "tr",
  "texts": {
    "Menu:Appointments": "Randevular",
    "Permission:Appointments": "Randevular",
    "Permission:Appointments.Default": "Randevuları görüntüle",
    "Permission:Appointments.Create": "Randevu oluştur",
    "Permission:Appointments.Edit": "Randevu düzenle",
    "Permission:Appointments.Delete": "Randevu sil",
    "Appointment:Date": "Randevu Tarihi",
    "Appointment:Doctor": "Doktor",
    "Appointment:Patient": "Hasta",
    "Appointment:Status": "Durum",
    "Appointment:Status.Scheduled": "Planlandı",
    "Appointment:Status.Completed": "Tamamlandı",
    "Appointment:Status.Cancelled": "İptal Edildi",
    "Appointment:Created": "Randevu başarıyla oluşturuldu",
    "Appointment:Updated": "Randevu başarıyla güncellendi",
    "Appointment:Deleted": "Randevu başarıyla silindi",
    "Appointment:NotFound": "Randevu bulunamadı",
    "Appointment:DoctorNotAvailable": "Doktor bu tarihte müsait değil"
  }
}
```

## Translation Checklist

Before completing translations:

- [ ] All keys from base language are translated
- [ ] Parameter names match exactly across all languages
- [ ] Technical terms not translated (ID, API, URL, etc.)
- [ ] Translations are grammatically correct
- [ ] Cultural context is appropriate
- [ ] Text fits in UI constraints
- [ ] Special characters (accents, etc.) are correct
- [ ] Consistent terminology used throughout
- [ ] Formal tone maintained where appropriate
- [ ] Date/number formats are correct for locale

## Related Skills

- `abp-framework-patterns` - ABP Framework patterns
- `abp-infrastructure-patterns` - Module configuration including localization
