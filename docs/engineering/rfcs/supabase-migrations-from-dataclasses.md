# Overview: Supabase Migrations Emitted From Dataclasses

This document is the Overview of the database schema emission design. It defines goals, scope, conventions, inference rules, and operational boundaries. A separate follow‑up will specify the exact classes, public API, and implementation considerations.

## Background

### Purpose

- Treat Python dataclasses as the single source of truth for database schema while keeping Git lean and deterministic. Engineers never hand-author foreign keys, indexes, or junction tables. Concrete SQL migrations are emitted and applied by CI/CD to Supabase.

### Source of truth

- Location: `.mb/schema.py` (single importable module; no repository-wide scanning).
- Opt-in: each persisted dataclass sets `db=True` and may set `schema="public"` in its dataclass kwargs.
- Embedding: any field declared with `embed=True` is stored as `jsonb` and excluded from relational inference.

### Conventions and type mapping

- Primary key: a field named `id` of type `UUID` is the primary key by convention.
- Nullability: fields with a default or `default_factory` are nullable; others are not nullable.
- Types: `str→text`, `int→bigint`, `float→double precision`, `bool→boolean`, `bytes→bytea`, `datetime→timestamptz`, `UUID→uuid`, `enum→CREATE TYPE`. `dict`/`list` with `embed=True→jsonb`.

### Relationship inference

- One-to-one or many-to-one: a singular field of another dataclass creates a foreign key column on this table.
- One-to-many: a `list[Child]` on the parent implies the child table carries the foreign key.
- Many-to-many: if both sides declare `list[OtherClass]`, a junction table is generated automatically (users never define it).
- Non-dataclass containers (for example `list[str]`): must use `embed=True` (or the emitter fails with a clear error). Relation inference only considers dataclass types.

### Deletion and cascade rules

#### Terminology

- Parent: the table that owns the collection in a one-to-many, or either side of a many-to-many.
- Child: the table that holds the foreign key in a one-to-many or many-to-one.
- Link row: a row in the generated junction table for many-to-many relationships.

#### Defaults

- Many-to-one / one-to-one (singular field creates the foreign key on this table):
    - Default is `ON DELETE RESTRICT`.
- One-to-many (parent has list of children; child table holds the foreign key):
    - Default is `ON DELETE RESTRICT` on the child’s foreign key.
- Many-to-many (both sides declare lists, emitter creates a junction):
    - Junction foreign keys default to `ON DELETE CASCADE` on both sides.
    - Effect: deleting a parent or a child deletes only the corresponding link rows; the other side’s table rows are not deleted.

#### Overrides

- Per-relationship field, support a precise override via `on_delete="cascade" | "restrict" | "set_null"`:
    - Where to specify:
        - Many-to-one / one-to-one: on the singular field (the table that holds the foreign key).
        - One-to-many: on the parent list field or on the child’s singular back-reference (if present). Precedence: child’s singular field override wins; otherwise use the parent list field override; otherwise default.
        - Many-to-many: on either list field to change the junction behavior for that side only. The emitter maps:
            - `members: list[User] = field(on_delete="restrict")` → junction foreign key on `team_id` uses `ON DELETE RESTRICT`; the other side remains `CASCADE` unless overridden there as well.
    - Validations:
        - `set_null` is only valid when the foreign key column is nullable (the emitter errors if not).
        - `on_delete` on an embedded field is invalid (error).
        - Conflicting overrides (for example both sides specify different behaviors for the same foreign key): the side that controls the actual foreign key wins. For a junction, each side controls its own foreign key.

#### Effects per relationship type

- Many-to-one / one-to-one:
    - cascade: deleting the referenced parent deletes the child row.
    - restrict: deletion of the parent is blocked while child rows exist.
    - set_null: deleting the parent sets the child’s foreign key to null (requires nullable).
- One-to-many:
    - Applies to the foreign key on the child table (as above).
    - If the parent sets `on_delete="cascade"` on the list field, deleting the parent deletes all children.
- Many-to-many:
    - Default junction behavior is “clean up links only”: `ON DELETE CASCADE` on both foreign keys.
    - Overrides allow “no automatic cleanup” for one side by switching that side’s junction foreign key to `RESTRICT`. There is no `set_null` for junctions (junction columns are non-nullable).

### Examples (in `.mb/schema.py`)

- Many-to-many (default link cleanup only)

```python
from uuid import UUID
from mbcore.vendored_dataclass import dataclass, field

@dataclass(db=True, schema="public")
class Team:
    id: UUID = field()
    name: str = field()
    members: list["User"] = field()  # generates junction table team_user

@dataclass(db=True, schema="public")
class User:
    id: UUID = field()
    email: str = field()
    teams: list[Team] = field()      # mirrors Team.members
```

Generated behavior:

- Junction table `team_user(team_id, user_id, unique(team_id, user_id))`.
- `ON DELETE CASCADE` on both `team_id` and `user_id` in the junction.
- Deleting a Team removes its `team_user` links, but does not delete User rows; and vice versa.

- Many-to-one with cascade

```python
from uuid import UUID
from mbcore.vendored_dataclass import dataclass, field

@dataclass(db=True, schema="public")
class User:
    id: UUID = field()
    email: str = field()

@dataclass(db=True, schema="public")
class Profile:
    id: UUID = field()
    user: "User" = field(on_delete="cascade")
    settings: dict = field(embed=True)
```

Generated behavior:

- Profile has `user_id` referencing `user(id)` with `ON DELETE CASCADE`.
- Deleting a User cascades and deletes Profile rows.
- `settings` is `jsonb` (embedded), not part of relations.

- One-to-many with explicit set_null

```python
from uuid import UUID
from mbcore.vendored_dataclass import dataclass, field

@dataclass(db=True, schema="public")
class Project:
    id: UUID = field()
    name: str = field()
    tasks: list["Task"] = field(on_delete="set_null")

@dataclass(db=True, schema="public")
class Task:
    id: UUID = field()
    project: "Project | None" = field(default=None)  # nullable for set_null
    title: str = field()
```

Generated behavior:

- Task has `project_id` referencing `project(id)` with `ON DELETE SET NULL`.
- Deleting a Project sets `Task.project_id` to null (allowed because the field is nullable).

### Migration emission and application

- Emission writes SQL to `.mb/supabase/migrations/<timestamp>_<slug>.sql` and a snapshot to `.mb/supabase/schema.json`. Emitted SQL includes `CREATE TABLE`, `ALTER TABLE`, `CREATE TYPE`, `CREATE INDEX`, and foreign keys with `ON DELETE` exactly as above. Destructive changes are blocked unless explicitly allowed.
- Application: `mb db push --database-url $MB_TEST_DATABASE_URL` applies migrations in order to the target test database. Push never generates schema; it only applies committed SQL.

### Ownership and permissions

- Dataclasses never set roles, grants, or row-level security.
- Policy packs live in `.mb/policy/<env>.sql` and define ownership (`ALTER TABLE … OWNER TO …`), grants, and row-level security. CI/CD selects the environment policy and applies it after migrations. Team-based or public access rules are encoded here, and CI/CD is authoritative.
