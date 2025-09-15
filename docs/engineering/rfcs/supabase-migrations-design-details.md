# Design Details — Dataclasses to Supabase Migrations

This is the concrete design for emitting deterministic PostgreSQL SQL migrations from `.mb/schema.py` dataclasses and applying them with `mb db push` to Supabase. It defines exact classes, APIs, naming, diff rules, and tests.

## Classes and Options (authoring)
- Dataclass (authoring time)
  - Declared in `.mb/schema.py` only.
  - `@dataclass(db=True, schema="public")`
  - Fields use `field(...)` from `mbcore.vendored_dataclass`.
  - Per-field options:
    - `embed=True` → store in `jsonb`; excluded from relational inference.
    - `on_delete` in {"cascade", "restrict", "set_null"} on relationship fields.
- Conventions
  - Primary key: `id: UUID` is the primary key by convention.
  - Nullability: default or `default_factory` implies nullable; `Optional[T]` also implies nullable.
  - Types: `str→text`, `int→bigint`, `float→double precision`, `bool→boolean`, `bytes→bytea`, `datetime→timestamptz`, `UUID→uuid`, `enum→CREATE TYPE`, `dict/list` with `embed=True→jsonb`.

## Relationship Inference (exact)
- One-to-one / many-to-one: a singular field of another dataclass creates a foreign key on this table.
- One-to-many: a `list[Child]` on the parent implies the child table carries the foreign key.
- Many-to-many: if both sides declare `list[OtherClass]`, a junction table is generated automatically with columns `<a>_id`, `<b>_id`, a unique `(a_id, b_id)`, and two foreign keys.
- Non-dataclass lists/dicts must use `embed=True` or the emitter errors.

Deletion behavior
- Defaults
  - One-to-one / many-to-one: `ON DELETE RESTRICT`.
  - One-to-many: child foreign key is `ON DELETE RESTRICT`.
  - Many-to-many junction: both foreign keys are `ON DELETE CASCADE` (removes link rows only).
- Overrides (per relationship field)
  - `on_delete="cascade" | "restrict" | "set_null"`.
  - Many-to-one: set on the singular field.
  - One-to-many: set on the parent list or child singular back-ref; precedence: child singular override, else parent list override, else default.
  - Many-to-many: each side may override its own junction foreign key; no `set_null` for junctions.
  - Validation: `set_null` requires a nullable foreign key column; invalid on embedded fields.

## Emission Library API
- `load_models(module_path: str) -> list[type]`
  - Imports `.mb/schema.py` safely and returns dataclasses with `db=True`.
- `build_spec(models: list[type]) -> SchemaSpec`
  - Produces an in-memory specification (schemas, tables, columns, fks, indexes, enums) using rules above.
- `load_snapshot(path: Path) -> SchemaSpec | None` and `save_snapshot(spec: SchemaSpec, path: Path)`
- `diff_specs(old: SchemaSpec | None, new: SchemaSpec) -> Diff`
  - Non-destructive operations only by default (create table/enum/index, add column, widen nullability, add fk, add enum value).
  - Destructive operations (drop/rename/narrow type/remove enum value) are flagged and blocked unless explicitly allowed.
- `render_sql(diff: Diff) -> list[str]`
  - Deterministic SQL statements.
- `write_migration(dir: Path, stmts: list[str], slug: str) -> Path`
  - Writes `.mb/supabase/migrations/<timestamp>_<slug>.sql` and updates `.mb/supabase/schema.json`.

## SchemaSpec (in-memory)
- `SchemaSpec`: `schemas: dict[str, Schema]`
- `Schema`: `name`, `tables: dict[str, Table]`, `enums: dict[str, Enum]`
- `Table`: `schema`, `name`, `columns: list[Column]`, `primary_key: list[str]`, `uniques: list[list[str]]`, `indexes: list[Index]`, `fks: list[ForeignKey]`
- `Column`: `name`, `pg_type`, `nullable`, `server_default | None`
- `Index`: `name`, `columns: list[str]`, `unique: bool`
- `ForeignKey`: `name`, `columns: list[str]`, `ref_schema`, `ref_table`, `ref_columns`, `on_delete`
- `Enum`: `name`, `values: list[str]`

## Naming Rules (deterministic)
- Table: snake_case class name, qualified by `schema` (default `public`).
- Junction: `<a>_<b>` using alphabetical order of table names.
- Primary key: `pk_<table>`.
- Unique: `uq_<table>_<col1>_<col2>`.
- Index: `ix_<table>_<col1>_<col2>`.
- Foreign key: `fk_<table>_<col>_to_<reftable>`.
- Enum: `enum_<table>_<column>` by default.
- All identifiers are lowercased and truncated to 63 bytes with a hash suffix when necessary (PostgreSQL identifier limit).

## Diff and SQL Rules
- Order of emission: create enums → create tables (without fks) → add columns → create uniques/indexes → add foreign keys.
- Foreign keys emit `ON DELETE` exactly per rules above.
- Enum evolution: only `ALTER TYPE ... ADD VALUE` (no deletions or renames).
- Destructive changes are never auto-emitted; they are reported with guidance.

## Tests (must pass)
- Type mapping and nullability: matrix of required/optional/default/default_factory.
- One-to-one / many-to-one: default restrict; cascade/set_null overrides; invalid set_null on non-nullable.
- One-to-many: inferred child foreign key; override and precedence behavior.
- Many-to-many: symmetric lists produce junction; default cascade link cleanup; per-side restrict override; asymmetry error.
- Embedding: `embed=True` on dict/list stores as jsonb; relation inference excluded.
- Enums: create and add value; blocked destructive edits.
- Determinism: identical input yields identical snapshot and SQL; re-emit is a no-op.
- Snapshot safety: blocked destructive diffs are reported with actionable messages.
- Integration: emit to temp dir; apply with `mb db push` against a test database; verify schema via `pg_catalog`.

## Operational Notes
- `mb db push` applies files in `.mb/supabase/migrations/` in order to the specified database. It does not generate schema.
- Policies (ownership, grants, row level security) live in `.mb/policy/<env>.sql` and run after migrations in CI/CD.

---

## Revised Model (Authoritative)

The following replaces any earlier assumptions about discovery or calling flow. It is the authoritative design.

### Core Model
- Records can be declared anywhere in the repository.
- The dataclass decorator is the sole authoring surface for persistence:
  - `@dataclass(db=True, schema="public")` marks a record for persistence.
  - Per-field options:
    - `embed=True` stores the field as `jsonb` and excludes it from relational inference.
    - `on_delete` in {"cascade", "restrict", "set_null"} on relationship fields controls foreign-key delete behavior.
- TypedDicts and functions are valid authoring surfaces as well; they emit the same record entry format (no long-term state required).
- Generics are allowed when all type variables are fully bound (including Literal bounds). Unresolved type variables are rejected for persistence.

### Relationship Inference (exact)
- One-to-one / many-to-one: a singular field of another record creates a foreign key on this table (default `ON DELETE RESTRICT`).
- One-to-many: a `list[Child]` on the parent implies the child table carries the foreign key (default `RESTRICT`).
- Many-to-many: if both sides declare `list[Other]`, a junction table is generated automatically with two foreign keys and a composite unique key; both foreign keys default to `ON DELETE CASCADE` (link cleanup only).
- Overrides: `on_delete` per relationship field; precedence and validations:
  - `set_null` requires a nullable foreign key column (otherwise error).
  - `on_delete` on embedded fields is invalid (error).
  - For one-to-many, a child singular override wins over a parent list override; otherwise default.
  - For junctions, each side controls its own foreign key; `set_null` is not allowed for junctions.

### Type and Nullability Rules
- Primary key by convention: `id: UUID`.
- Nullability: default or `default_factory` implies nullable; `Optional[T]` is nullable.
- Mapping: `str→text`, `int→bigint`, `float→double precision`, `bool→boolean`, `bytes→bytea`, `datetime→timestamptz`, `UUID→uuid`, `enum→CREATE TYPE`, `dict/list` with `embed=True→jsonb`.

### Decorator-Emitted JSON (Record Entries)
The dataclass decorator (and equivalent helpers for TypedDicts/functions) writes record entries in a deterministic JSON format. Each entry is a single JSON object (newline-delimited when multiple).

TypedDict definitions of the record entry format:

```python
from typing import NotRequired, TypedDict, Literal

class EnumDomain(TypedDict):
    name: str
    values: list[str]

class ColumnDomain(TypedDict, total=False):
    primitive: Literal["uuid","text","bigint","double","boolean","bytea","timestamptz"]
    enum: EnumDomain
    embed: Literal[True]

class ColumnEntry(TypedDict):
    name: str
    domain: ColumnDomain
    nullable: bool
    server_default: NotRequired[str | None]
    unique: NotRequired[bool]
    index: NotRequired[bool]

class RelationshipRef(TypedDict):
    schema: str
    table: str
    fields: list[str]

class RelationshipEntry(TypedDict):
    type: Literal["one_to_one","many_to_one","one_to_many","many_to_many"]
    local_fields: list[str]
    remote: RelationshipRef
    on_delete: Literal["restrict","cascade","set_null"]

class OptionsEntry(TypedDict):
    pk: list[str]
    uniques: NotRequired[list[list[str]]]
    indexes: NotRequired[list[list[str]]]
    hints: NotRequired[dict[str, str]]

class RecordEntry(TypedDict):
    version: Literal[1]
    kind: Literal["dataclass","typeddict","function"]
    module: str
    name: str
    schema: str
    table: str
    columns: list[ColumnEntry]
    relationships: list[RelationshipEntry]
    options: OptionsEntry
```

Concise example (SensorFrame as a single-table record):

```json
{
  "version": 1,
  "kind": "dataclass",
  "module": "embdata.sense.frames",
  "name": "SensorFrame",
  "schema": "public",
  "table": "sensor_frame",
  "columns": [
    {"name":"id","domain":{"primitive":"uuid"},"nullable":false},
    {"name":"serial","domain":{"primitive":"text"},"nullable":false},
    {"name":"frame_index","domain":{"primitive":"bigint"},"nullable":false},
    {"name":"timestamp","domain":{"primitive":"double"},"nullable":false},
    {"name":"manufacturer","domain":{"primitive":"text"},"nullable":false},
    {"name":"device","domain":{"primitive":"bigint"},"nullable":false},
    {"name":"alignment","domain":{"enum":{"name":"enum_sensor_frame_alignment","values":["color","depth","infrared","left","right"]}},"nullable":false},
    {"name":"data","domain":{"embed":true},"nullable":true}
  ],
  "relationships": [],
  "options": {"pk":["id"]}
}
```

Many-to-many flags on each side (example fragment):

```json
{
  "type": "many_to_many",
  "local_fields": [],
  "remote": {"schema":"public","table":"user","fields":["id"]},
  "on_delete": "cascade"
}
```

One-to-many override (example fragment):

```json
{
  "type": "one_to_many",
  "local_fields": [],
  "remote": {"schema":"public","table":"task","fields":["project_id"]},
  "on_delete": "set_null"
}
```

### Aggregated Snapshot JSON (schema.json)
After linking all record entries, a canonical snapshot is materialized for diffs and SQL emission. Junction tables are materialized with two foreign keys and a composite unique key.

TypedDict definitions of the snapshot:

```python
class ForeignKeyEntry(TypedDict):
    name: str
    columns: list[str]
    ref_schema: str
    ref_table: str
    ref_columns: list[str]
    on_delete: Literal["restrict","cascade","set_null"]

class TableSnapshot(TypedDict):
    columns: list[ColumnEntry]
    primary_key: list[str]
    uniques: list[list[str]]
    indexes: list[list[str]]
    foreign_keys: list[ForeignKeyEntry]
    enums: list[EnumDomain]

class SchemaSnapshot(TypedDict):
    tables: dict[str, TableSnapshot]

class DatabaseSnapshot(TypedDict):
    version: Literal[1]
    schemas: dict[str, SchemaSnapshot]
```

### TypedDict and Functions
- TypedDicts marked for persistence emit the same record entry format as dataclasses.
- Functions may produce record entries programmatically (e.g., for generated tables) provided they conform exactly to `RecordEntry`.

### Generics With Bounds
- Accepted when every type variable resolves to a concrete bound at decoration time:
  - Literal → enum domain
  - Record type (dataclass/TypedDict) → relation domain
  - Primitive → primitive domain
- If any type variable is unresolved, persistence is rejected for that record.

### Naming Determinism
- Constraint and index names: `pk_<table>`, `uq_<table>_<cols>`, `ix_<table>_<cols>`, `fk_<table>_<col>_to_<peer>`.
- Junction table name: `<a>_<b>` (alphabetical by table name).
- All identifiers are lowercased and truncated to 63 bytes with an 8-character hash suffix when necessary.

### Enum Evolution
- Only additive changes are generated: `ALTER TYPE ... ADD VALUE [ BEFORE | AFTER ... ]`.
- Deletions or renames require a manual migration.
