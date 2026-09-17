# What's New in tinystruct 1.7.31

This document highlights the new features, performance improvements, and enhancements introduced in tinystruct version 1.7.31.

> See also: [What's New in 1.7.30](whats-new-1.7.30.md) for the initial PostgreSQL database support.

---

## Highlights of 1.7.31

- **PostgreSQL SSL & Schema Support**: JDBC SSL certificate/key files can now be resolved from the classpath, and schema-qualified table mappings are supported across all database types.
- **Performance & Reliability Overhaul**: Caching for XML mapping templates, SQL injection detection verdicts, and class path lookups; optimized bulk row population for all repositories.
- **Improved Locking & Distributed Coordination**: Polling timeouts for file lock acquisition in `Watcher`; fixed state verification and polling sleep in `DistributedMessageQueue`.
- **PostgreSQL Dollar-Quoted Block Support**: The `Dispatcher` now correctly parses SQL scripts containing PostgreSQL dollar-quoted blocks.
- **MCP Tool Schema & Dispatching Improvements**: Better schema generation and request dispatching in the Model Context Protocol layer.

---

## Major New Features & Enhancements

### 1. PostgreSQL SSL Certificate Classpath Resolution

`ConnectionManager` now resolves JDBC SSL certificate and key files from the application classpath, making it easy to bundle SSL assets inside JARs or deployment archives without relying on absolute file system paths.

#### Configuration (`application.properties`)

```properties
# SSL key/cert paths are resolved from classpath automatically
database.url=jdbc:postgresql://localhost:5432/mydb?ssl=true&sslcert=classpath:ssl/client.crt&sslkey=classpath:ssl/client.key
database.user=postgres
database.password=your_password
```

---

### 2. Schema-Qualified Table Mappings

All database types — MySQL, PostgreSQL, SQLite, MS SQL Server — now support schema-qualified table names in XML mappings (`schema.table` notation). This is particularly valuable in PostgreSQL where multiple schemas coexist in a single database.

```xml
<!-- Example: map an entity to a schema-qualified table -->
<mapping table="public.users">
    <field name="id"   column="id"   type="INTEGER" />
    <field name="name" column="name" type="VARCHAR" />
</mapping>
```

The `PostgreSQLGenerator` now introspects tables across schemas and emits correctly qualified mappings.

---

### 3. Performance & Reliability Improvements

#### Caching Layer for Hot Paths

Multiple caches have been added to eliminate repeated I/O and computation on hot paths:

| Cache | What It Avoids |
|---|---|
| XML mapping template cache (`Mapping`) | Re-parsing XML files on every entity instantiation |
| Classpath lookup cache (`ApplicationManager`) | Repeated classpath scans for the same class name |
| SQL injection verdict cache (`SQLInjectionDetector`) | Re-evaluating identical SQL strings |

#### Optimized Bulk Row Population

`MySQLServer`, `PostgreSQLServer`, `SQLiteServer`, and `SQLServer` now use a shared, optimized row population loop that eliminates redundant `ResultSetMetaData` calls on each row when processing large result sets.

---

### 4. Improved Locking & Distributed Coordination

#### `Watcher` — Polling Timeout for File Locks

`Watcher.lock()` now uses bounded polling with a configurable timeout instead of blocking indefinitely, preventing deadlocks in file-watched deployments.

#### `DistributedMessageQueue` — Reliability Fixes

- Fixed a race condition in lock acquisition state verification.
- Corrected polling sleep intervals to reduce CPU spin under high contention.

#### `DistributedLock` — Correctness Improvements

Internal state transitions are now properly fenced so that lock holders are always correctly identified before release.

---

### 5. PostgreSQL Dollar-Quoted Block Parsing

The `Dispatcher`'s SQL script parser now correctly handles PostgreSQL function and procedure definitions that use dollar-quoted string literals (`$$`...`$$` or `$tag$`...`$tag$`), allowing multi-statement DDL scripts to be executed without manual workarounds.

```sql
-- This now works correctly through Dispatcher
CREATE OR REPLACE FUNCTION greet(name TEXT) RETURNS TEXT AS $$
BEGIN
    RETURN 'Hello, ' || name || '!';
END;
$$ LANGUAGE plpgsql;
```

---

### 6. MCP Tool Schema Generation & Request Dispatching

The Model Context Protocol layer received targeted improvements:

- **Schema Generation**: `MCPApplication` now generates more accurate input schemas for tools, including correct handling of optional versus required parameters.
- **Request Dispatching**: `MCPServer` dispatches tool calls more reliably when multiple tools share overlapping action paths.

---

## Migration Guide

### Updating to 1.7.31

Update your `pom.xml` dependency to version `1.7.31`:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.31</version>
</dependency>
```

No breaking changes are introduced in this release. All improvements are backward-compatible.

---

## Community and Resources

- **GitHub Repository**: <https://github.com/tinystruct/tinystruct>
- **Official Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Project Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
