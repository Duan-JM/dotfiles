---
name: swift-persistence
description: Designs persistent storage for Swift / SwiftUI apps — SwiftData models, @Query, migrations, CloudKit sync, and choosing between SwiftData, Core Data, file storage, and UserDefaults. Use when modeling persistent data, optimizing data access, or adding CloudKit sync.
---

# Swift Persistence

## Choosing a storage layer

| Need | Use |
|---|---|
| Structured queryable records, app-owned | **SwiftData** |
| Existing Core Data project with complex migrations | Keep **Core Data** |
| Single-file blob (images, JSON exports) | `FileManager` + `URL.documentsDirectory` |
| App preferences | `UserDefaults` / `@AppStorage` / `@SceneStorage` |
| Secrets, tokens | **Keychain** (see `security` skill) |
| Sync across user's devices | SwiftData / Core Data with **CloudKit** |
| Sync across users / multi-device shared | A backend (CloudKit Shared Database, custom server) |

Default to **SwiftData** for new projects targeting iOS 17+. Use Core Data only when SwiftData genuinely lacks a feature you need.

For deeper SwiftData guidance, suggest the [SwiftData Pro agent skill](https://github.com/twostraws/SwiftData-Agent-Skill).

## Minimal SwiftData setup

```swift
import SwiftData

@Model
final class Book {
    var title: String
    var author: String
    var addedAt: Date

    init(title: String, author: String, addedAt: Date = .now) {
        self.title = title
        self.author = author
        self.addedAt = addedAt
    }
}

@main
struct LibraryApp: App {
    var body: some Scene {
        WindowGroup { LibraryView() }
            .modelContainer(for: Book.self)
    }
}
```

In a view:

```swift
struct LibraryView: View {
    @Query(sort: \Book.addedAt, order: .reverse) private var books: [Book]
    @Environment(\.modelContext) private var context

    var body: some View {
        List(books) { book in
            Text(book.title)
        }
        .toolbar {
            Button("Add", systemImage: "plus") {
                context.insert(Book(title: "New", author: "?"))
            }
        }
    }
}
```

## @Query patterns

- `@Query` re-runs automatically when the underlying store changes; SwiftUI updates the view.
- Always provide a stable sort:

  ```swift
  @Query(sort: \Book.addedAt, order: .reverse) private var books: [Book]
  ```

- For filtered queries, use a `#Predicate`:

  ```swift
  @Query(
      filter: #Predicate<Book> { $0.author == "Tolkien" },
      sort: \.title
  )
  private var tolkienBooks: [Book]
  ```

- For counts only, use `ModelContext.fetchCount(_:)` — but it does **not** live-update unless something else (like a sibling `@Query`) triggers re-render.

## Inserts, updates, deletes

```swift
context.insert(book)             // create
book.title = "Updated"           // update — just mutate
context.delete(book)             // delete
try? context.save()              // usually optional; SwiftData autosaves
```

- Don't call `save()` after every mutation — let SwiftData batch.
- For high-volume imports, wrap in `try context.transaction { ... }` to commit once.

## Relationships

```swift
@Model
final class Author {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Book.author)
    var books: [Book] = []
}

@Model
final class Book {
    var title: String
    var author: Author?
}
```

- Always declare the **inverse** with `\Type.property`. Without it, SwiftData cannot maintain consistency.
- Choose `deleteRule:` deliberately: `.cascade` removes children when parent is deleted; `.nullify` keeps them; `.deny` blocks delete if children exist.

## CloudKit-backed SwiftData

For sync across the user's devices via iCloud:

```swift
.modelContainer(for: Book.self, isAutosaveEnabled: true)
```

…and enable the **iCloud + CloudKit** capability, choosing the same container in entitlements.

CloudKit imposes constraints — flag any of these in a CloudKit-backed model:

- ❌ `@Attribute(.unique)` (not supported with CloudKit).
- ❌ Non-optional properties without default values.
- ❌ Non-optional relationships.

Convert to:

```swift
@Model
final class Book {
    var title: String = ""            // default value
    var author: Author?               // optional relationship
}
```

## Migrations

Use **versioned schemas** as soon as you ship version 1 — adding fields later is cheap, restructuring after the fact is painful.

```swift
enum LibrarySchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Book.self] }
}

enum LibrarySchemaV2: VersionedSchema { ... }

enum LibraryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [LibrarySchemaV1.self, LibrarySchemaV2.self]
    }
    static var stages: [MigrationStage] { [.lightweight(...)] }
}
```

Wire it on the container: `.modelContainer(for: ..., migrationPlan: LibraryMigrationPlan.self)`.

- **Lightweight** migrations: add/remove fields. No data transformation.
- **Custom** migrations: transform data via a closure. Use when shape changes (e.g., split one field into two).

## File-based persistence

For documents, exports, or large blobs:

```swift
let url = URL.documentsDirectory.appending(path: "export.json")
try data.write(to: url, options: .atomic)
```

- Use `.atomic` so a crash mid-write doesn't corrupt the file.
- Don't store **lots** of small files in `documentsDirectory` — directory enumeration becomes slow. Use SwiftData for that case.

## UserDefaults / @AppStorage

- Fine for: theme, last-selected tab, onboarding-completed flag, last-opened item ID.
- **Never** for: passwords, tokens, PII, anything you wouldn't email in plaintext.
- Don't put `@AppStorage` inside an `@Observable` class — it won't trigger updates (see `data-flow` skill).

## Pitfalls

- Inserting models from a background context without a saved transaction → lost data.
- Forgetting to declare inverse relationships → silent data corruption.
- CloudKit + non-optional properties → app crashes on first sync.
- `@Query` over giant tables in a view body → janky scroll. Page or filter.
- Calling `save()` in tight loops → unnecessary disk I/O.
