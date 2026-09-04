# What's New in tinystruct 1.7.30

This document highlights the new features, enhancements, and changes introduced in tinystruct version 1.7.30.

> See also: [What's New in 1.7.29](whats-new-1.7.29.md) for earlier features including Asymmetric RSA & Configurable JWT Security, and HTTP Server Security.

---

## Highlights of 1.7.30

- **PostgreSQL Database Support**: Added out-of-the-box support for PostgreSQL in the `Type` enum and Database operator, including a dedicated `PostgreSQLGenerator` for automated POJO generation.

---

## Major New Features & Enhancements

### 1. PostgreSQL Integration

Tinystruct now natively supports PostgreSQL alongside MySQL, SQLite, H2, MS SQL Server, and Oracle. The support includes:

- **`Type.PostgreSQL`** — A new entry in the `Type` enum backed by the `PostgreSQLServer` repository class.
- **`PostgreSQLServer`** — A full `AbstractDataRepository` implementation with `append`, `appendAndGetId`, `update`, and `find` operations.
- **`PostgreSQLGenerator`** — A new POJO code generator that introspects a PostgreSQL schema and emits ready-to-use `AbstractData` subclasses.
- **Automatic driver detection** — The `ConnectionManager` automatically selects `Type.PostgreSQL` when the configured JDBC URL contains `"postgresql"`.

#### Configuration (`application.properties`)

```properties
# PostgreSQL Configuration
driver=org.postgresql.Driver
database.url=jdbc:postgresql://localhost:5432/mydb
database.user=postgres
database.password=your_password
database.connections.max=10
```

> **Tip:** You must add the PostgreSQL JDBC driver to your project's `pom.xml`:
> ```xml
> <dependency>
>     <groupId>org.postgresql</groupId>
>     <artifactId>postgresql</artifactId>
>     <version>42.7.3</version>
> </dependency>
> ```

#### Using `Type.PostgreSQL` Directly

```java
// Explicitly select PostgreSQL repository
Repository repo = Type.PostgreSQL.createRepository();
```

#### PostgreSQL-Aware SQL Type Handling

The `PostgreSQLServer.find()` method correctly maps PostgreSQL-native types:

| PostgreSQL Type | Java Type |
|---|---|
| `INT`, `SERIAL`, `INTEGER` | `int` / `long` |
| `BIGINT`, `INT8`, `BIGSERIAL` | `long` |
| `REAL`, `FLOAT`, `DOUBLE`, `NUMERIC`, `DECIMAL` | `double` |
| `BOOL`, `BOOLEAN`, `BIT` | `boolean` |
| `DATE`, `TIME`, `TIMESTAMP` | `java.sql.Timestamp` |
| `BYTEA`, `BINARY`, `BLOB` | `byte[]` |
| All others (`VARCHAR`, `TEXT`, etc.) | `String` |

#### POJO Generation for PostgreSQL

You can use the built-in `PostgreSQLGenerator` to generate `AbstractData` model classes directly from your PostgreSQL schema:

```bash
bin/dispatcher generate --import org.tinystruct.data.tools.PostgreSQLGenerator --table my_table
```

This emits a fully wired `AbstractData` subclass with all column-to-field mappings, ready for use with tinystruct's ORM layer.

---

## Migration Guide

### Updating to 1.7.30

Update your `pom.xml` dependency to version `1.7.30`:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.30</version>
</dependency>
```

No breaking changes are introduced in this release. PostgreSQL support is purely additive.

---

## Community and Resources

- **GitHub Repository**: <https://github.com/tinystruct/tinystruct>
- **Official Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Project Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
