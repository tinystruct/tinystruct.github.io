# What's New in tinystruct 1.7.38

This document highlights the changes introduced in tinystruct version 1.7.38, a reliability, performance, and security release featuring ASM CVE patches, JSON `Builder`/`Builders` round-trip fixes, faster lock-file I/O with configurable lock timeouts, default file logging, and synchronized updates across server and ecosystem modules.

> See also: [What's New in 1.7.37](whats-new-1.7.37.md) for the previous release featuring static file serving access control and path traversal mitigation.

---

## Highlights of 1.7.38

- **Security & Dependency Upgrades**: Pinned `org.ow2.asm` artifacts (`asm`, `asm-commons`, `asm-analysis`, `asm-tree`, `asm-util`) to `9.11.1` to resolve CVEs pulled in transitively via `nashorn-core`, and upgraded `reactor-core` (`3.8.8`) and `sqlite-jdbc` (`3.54.1.0`).
- **JSON Round-Trip & Escaping Fixes**: `Builder` now escapes object keys on output and keeps lookalike strings quoted, while `Builders` fixes escaped backslashes, unescapes array strings, and preserves `Boolean` / `null` literals in arrays.
- **Faster Lock-File I/O & Configurable Timeouts**: `Watcher` scans `.lock` slots in a single read and writes slots directly, cutting stale-lock contention; added `distributed.lock.timeout` and `distributed.lock.file.timeout` settings (`5000` ms default).
- **Concurrency, Logging & App Lifecycle**: `DistributedMessageQueue.take()` releases its lock between polls to prevent worker starvation, `LogFormatter` uses thread-safe `DateTimeFormatter`, `ApplicationManager.uninstall()` removes all matching actions, and `Application.setAction(String, String)` is undeprecated for dynamic routing.
- **File Logging Enabled by Default**: Default `application.properties` enables `java.util.logging.FileHandler` alongside `ConsoleHandler` (`logs/tinystruct-%g.log`, 5 rotating 10 MB files).
- **Ecosystem & Server Modules Updated**: Updated `tinystruct-netty-http-server` (`1.1.12`), `tinystruct-tomcat-server` (`1.1.12`), `tinystruct-undertow-server` (`1.1.3`), `tinystruct-workflow` (`1.0.3`), and `tinystruct-typesafe` (`1.0.1`).

---

## Details

### 1. Security & Dependency Upgrades

Managed and direct dependencies updated in `pom.xml`:

| Dependency | Old | New | Notes |
| :--- | :--- | :--- | :--- |
| `org.ow2.asm:asm*` (`asm`, `-commons`, `-analysis`, `-tree`, `-util`) | `7.3.1` (transitive via `nashorn-core 15.7`) | **`9.11.1`** | Pinned via `${asm.version}`; fixes `CVE-2026-110257/58/60/61/63` and `CVE-2026-110591` |
| `io.projectreactor:reactor-core` | `3.6.18` | **`3.8.8`** | Managed transitive vulnerability update |
| `org.xerial:sqlite-jdbc` | `3.53.4.0` | **`3.54.1.0`** | SQLite JDBC driver update |

> **Tip:** If your project also imports ASM or Reactor directly, align those versions with the managed versions above.

---

### 2. JSON `Builder` / `Builders` Round-Trip & Escaping Fixes

JSON parsing and serialization in `org.tinystruct.data.component.Builder` and `Builders` now preserve structure, escaping, and primitive types across parse/serialize round trips:

- **Escaped Object Keys**: Object keys are escaped with `StringUtilities.escape(...)` on `toString()`, matching parser unescaping for quotes, backslashes, and control characters (e.g., `"C:\\dir"` and `"say \"hi\""`).
- **Lookalike Strings Stay Strings**: Single-value `Builder` instances store and emit strings as quoted JSON strings rather than re-parsing `"true"`, `"false"`, `"null"`, or `"123"` as unquoted literals or numbers.
- **Native Array Literals & Unescaping**: `Builders` parses unquoted `true`, `false`, and `null` array elements as `Boolean` or `null` (`Builder.ofNull()`) instead of strings, properly handles escaped backslashes before closing quotes, and unescapes parsed array strings.

```java
// Mixed literals and lookalike strings preserve types across parse -> toString()
String json = "[true,false,null,1,\"true\",\"1\"]";
Builders array = new Builders();
array.parse(json);
assert json.equals(array.toString());

// Keys containing quotes, backslashes, or newlines round-trip cleanly
Builder obj = new Builder().put("C:\\dir\\", "v");
Builder reparsed = new Builder();
reparsed.parse(obj.toString());
assert "v".equals(reparsed.get("C:\\dir\\"));
```

---

### 3. Lock-File I/O Performance & Configurable Timeouts

Concurrent workloads using `DistributedHashMap` and `Watcher` benefit from lower lock-file overhead and tunable timeouts:

- **Single-Read `.lock` Scanning**: `Watcher` now reads the `.lock` file in one `FileChannel` read, scans slot records in memory, and writes updated flags directly instead of per-slot small reads—cutting median lock/unlock cycles on a stale `90`-slot file from `15.5 ms` to `6.4 ms`. The on-disk format (`36`-byte lock ID + `8`-byte flag per slot) is unchanged and backward-compatible.
- **Configurable Lock Timeouts**: Both lock waits (previously hardcoded to `5000` ms) are now configurable in `application.properties` via `LockSettings`. Missing, non-numeric, or non-positive values log a warning and fall back to `5000` ms.

```properties
# Lock timeouts in milliseconds (default: 5000)
distributed.lock.timeout=5000
distributed.lock.file.timeout=5000
```

- **Explicit Per-Map Timeout Constructor**: `DistributedHashMap` adds `new DistributedHashMap(dataFilePath, lockTimeoutMs)` for programmatic control.

---

### 4. Concurrency, Logging & Application Lifecycle Improvements

- **Queue Lock Starvation Fix**: `DistributedMessageQueue.take(String)` now releases its lock between `1` ms poll intervals so background `copy()` workers are never starved waiting to enqueue incoming messages, and returns `"{}"` immediately for unregistered session IDs.
- **Thread-Safe `LogFormatter`**: Replaced the mutable `SimpleDateFormat` instance field in `LogFormatter` with a static thread-safe `DateTimeFormatter`.
- **Default File Logging Enabled**: Default `application.properties` now activates both console and rotating file logging:

```properties
handlers = java.util.logging.ConsoleHandler, java.util.logging.FileHandler
```

- **`ApplicationManager` & Dynamic Action Registration**:
  - `ApplicationManager.uninstall(Application)` now removes all matching actions belonging to an application rather than returning after the first match.
  - `ApplicationManager.init()` always marks `initialized = true` even when `default.import.applications` is empty.
  - `Application.setAction(String, String)` is no longer deprecated (`@Deprecated` removed), supporting dynamic route registration cleanly.

---

### 5. Server & Companion Ecosystem Modules Updated

All tinystruct HTTP server modules and companion libraries have been released against `tinystruct 1.7.38` with updated dependencies:

| Module | Version | tinystruct Version | Highlights |
| :--- | :--- | :--- | :--- |
| [`tinystruct-netty-http-server`](https://github.com/tinystruct/tinystruct-netty-http-server) | **1.1.12** | `1.7.38` | Aligned with `1.7.38`; upgrades Netty to `4.2.20.Final` and `netty-tcnative` to `2.0.85.Final`. |
| [`tinystruct-tomcat-server`](https://github.com/tinystruct/tinystruct-tomcat-server) | **1.1.12** | `1.7.38` | Aligned with `1.7.38` alongside embedded Tomcat `11.0.27` and `jakarta.servlet-api` `6.1.0`. |
| [`tinystruct-undertow-server`](https://github.com/tinystruct/tinystruct-undertow-server) | **1.1.3** | `1.7.38` | Aligned with `1.7.38` alongside Undertow `2.4.4.Final`, XNIO `3.8.17.Final`, and `jboss-logging` `3.6.3.Final`. |
| [`tinystruct-workflow`](https://github.com/tinystruct/tinystruct-workflow) | **1.0.3** | `1.7.38` | Aligned with `1.7.38`; upgrades Lettuce to `7.9.0.RELEASE` and updates Maven build plugins. |
| [`tinystruct-typesafe`](https://github.com/tinystruct/tinystruct-typesafe) | **1.0.1** | `1.7.38` | Natural-language `@Action` dispatcher aligned with `tinystruct 1.7.38` and `tinystruct-workflow` `1.0.3`; upgrades Lettuce (`7.9.0.RELEASE`), adds `semantic/pending` listing (`PendingSummary`) and expired confirmation sweeper. |

---

## Migration Guide

### Updating to 1.7.38

Update your `pom.xml` dependency:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.38</version>
</dependency>
```

Update companion modules if your project uses them:

```xml
<!-- HTTP Server Modules -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-netty-http-server</artifactId>
    <version>1.1.12</version>
</dependency>

<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-tomcat-server</artifactId>
    <version>1.1.12</version>
</dependency>

<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-undertow-server</artifactId>
    <version>1.1.3</version>
</dependency>

<!-- Workflow Engine -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-workflow</artifactId>
    <version>1.0.3</version>
</dependency>

<!-- TypeSafe Semantic Dispatcher -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-typesafe-core</artifactId>
    <version>1.0.1</version>
</dependency>
```

### Things to Check When Upgrading from 1.7.37

- **`Builders` Array Literal Types**: Unquoted `true`, `false`, and `null` elements inside JSON arrays now yield `Boolean` or `null` from `Builder.getValue()` instead of `String`. Quoted values (`"true"`, `"null"`) remain `String`.
- **Default File Logging**: Because the bundled `application.properties` now enables `java.util.logging.FileHandler` by default, applications create rotating logs under `logs/tinystruct-%g.log`. Override `handlers = java.util.logging.ConsoleHandler` in your own `application.properties` if console-only logging is preferred.
- **Distributed Lock Timeouts**: Configure `distributed.lock.timeout` or `distributed.lock.file.timeout` (milliseconds) in `application.properties` if your environment requires values other than `5000`.

---

## Community and Resources

- **GitHub Repository**: <https://github.com/tinystruct/tinystruct>
- **Official Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Project Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
