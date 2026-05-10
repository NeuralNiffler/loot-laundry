# Loot&Laundry – TDD Development Standard

## Entwicklungs-Workflow (MANDATORY)

**Für JEDE neue Funktionalität:**

### 1️⃣ **TESTS FIRST**
- Schreibe **ZUERST** vollständige Tests für das Feature
- Tests mit aussagekräftigen Namen: `test_<behaves><when><given>`
- Teste Erfolg- und Fehlerfälle
- Tests müssen **initial FAIL** (Red-Green-Refactor)

### 2️⃣ **MINIMAL IMPLEMENTATION**
- Schreibe Produktionscode nur um Tests grün zu machen
- Keine Über-Engineering
- Fokus auf Passing Tests, nicht auf "perfekt"

### 3️⃣ **VERIFY TESTS PASS**
- Alle Tests müssen grün sein (`Cmd+U` in Xcode)
- Keine roten Tests committen
- Bevor Response: "Tests sind grün" bestätigen

### 4️⃣ **REFACTOR (optional)**
- Nach grünen Tests: Cleanup + Optimierung
- Tests müssen weiterhin grün bleiben

## Test-Struktur

- **Unit Tests**: `Services/`, `ViewModels/` → `[ServiceName]Tests.swift`
- **Test Target**: `Loot&LaundryTests`
- **Test-Framework**: `Testing` (Swift 6 native)
- **Mocking**: `MockModelContext` für SwiftData-Tests

## Beispiel-Workflow

```
1. Feature geplant: "Quest-Template löschen"
   ↓
2. Test schreiben:
   @Test("deleteTemplate entfernt aus Context")
   func deleteTemplate() { ... }
   ↓ TEST FAILS ❌
3. Code implementieren (minimal)
4. TEST PASSES ✅
5. Commit mit "✅ Tests passed: [Feature]"
```

## Ignorieren = Konsequenz

- Tests zu überspringen → Feature wird abgelehnt
- "Keine Zeit für Tests" → Feature wird abgelehnt
- Code ohne Tests → Wird nicht reviewt

---

**Gültig ab: 19.04.2026**
**Letzte Aktualisierung: [Agent Name]**
