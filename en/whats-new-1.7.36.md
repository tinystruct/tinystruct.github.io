# What's New in tinystruct 1.7.36

This document highlights the changes introduced in tinystruct version 1.7.36, a release focused on MCP hardening, configurable logging, and a leaner dependency set.

> See also: [What's New in 1.7.35](whats-new-1.7.35.md) for the previous release featuring dependency security updates and interrupt-handling fixes.

---

## Highlights of 1.7.36

- **Configurable Logging Handlers**: The `handlers` property now controls which handlers are created, with full `FileHandler` support (rotation, size limit, append).
- **Hardened MCP Server**: Requests are rejected until the session is initialized, active sessions are kept alive, and the generated auth token is no longer logged.
- **Safer MCP Input Handling**: `tools/call` and `resources/read` tolerate missing arguments and query strings, and URL-decode resource parameters.
- **Unified Schema Generation**: Tool schema generation and overload merging now live in a single `SchemaGenerator`.
- **Kafka Client Removed**: `KafkaClient` and the Kafka dependencies were dropped from the framework.
- **UTF-8 Dispatcher Scripts**: `bin/dispatcher` and `bin/dispatcher.cmd` force UTF-8 so non-ASCII output is not garbled.

---

## Details

### 1. Configurable Logging Handlers

Handlers listed in the `handlers` property are now created at startup, each with its own level, formatter and encoding. The default is still the console handler. To also write log files, append the `FileHandler`:

```properties
handlers = java.util.logging.ConsoleHandler, java.util.logging.FileHandler

java.util.logging.FileHandler.pattern = logs/tinystruct-%g.log
java.util.logging.FileHandler.limit = 10485760
java.util.logging.FileHandler.count = 5
java.util.logging.FileHandler.level = INFO
java.util.logging.FileHandler.formatter = org.tinystruct.system.logging.LogFormatter
java.util.logging.FileHandler.encoding = UTF-8
```

- The log directory is created automatically.
- Handlers removed on reconfiguration are closed, so repeated setup no longer leaves stray `.1` / `.2` log files.
- ANSI colors are applied to console output only.
- A warning is logged when a configured formatter cannot be loaded.
- The default console formatter is now `org.tinystruct.system.logging.LogFormatter`.

---

### 2. MCP Server Hardening

- **Initialization is enforced**: every method other than `initialize` and `ping` returns a `Session not initialized` error unless the session has been initialized.
- **Sessions stay alive**: any request refreshes the session activity timestamp, not only `ping`, so active sessions are no longer expired by the watchdog.
- **No state leak**: leftover session states (for example `DISCONNECTED`) of sessions that no longer exist are purged.
- **Token not logged**: when no auth token is configured, a generated one is used but is no longer written to the log. Set the auth token in your configuration if you need a fixed value.
- **Quieter client**: the MCP client logs full JSON-RPC payloads at `FINE` instead of `INFO`.

---

### 3. Safer `tools/call` and `resources/read`

- `tools/call` with a missing or non-object `arguments` value is treated as an empty argument set instead of failing with a cast error.
- `resources/read` accepts URIs without a query string, and parses parameters robustly (keys without values, `=` inside values) with URL decoding.

---

### 4. Unified Schema Generation

The duplicated schema code in `MCPServer` and `MCPTool` was consolidated into `SchemaGenerator`, which builds parameter schemas from `@Action` / `@Argument` metadata and merges overloaded tool methods. A parameter is required in the merged schema only if every overload requires it. Tool behavior is unchanged.

---

### 5. Kafka Client Removed

`org.tinystruct.data.tools.KafkaClient` and the Kafka dependencies were removed from the framework, which shrinks the dependency tree.

> **Note:** If your application used `KafkaClient`, add the Kafka client library to your own project and keep your own wrapper.

---

### 6. UTF-8 Dispatcher Scripts

`bin/dispatcher` and `bin/dispatcher.cmd` now start the JVM with `-Dfile.encoding=UTF-8` and the stdout/stderr encodings set to UTF-8. The Windows script also switches the console code page with `chcp 65001`, so Chinese and other non-ASCII text displays correctly.

---

## Migration Guide

### Updating to 1.7.36

Update your `pom.xml` dependency:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.36</version>
</dependency>
```

If you use the `dispatcher` scripts, update the version they reference as well.

Things to check when upgrading from 1.7.35:

- MCP clients must send `initialize` before other requests (spec-compliant clients already do).
- Projects relying on `KafkaClient` need their own Kafka dependency.
- If you copied `application.properties`, consider switching the console formatter to `org.tinystruct.system.logging.LogFormatter`.

---

## Community and Resources

- **GitHub Repository**: <https://github.com/tinystruct/tinystruct>
- **Official Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Project Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
