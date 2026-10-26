# What's New in tinystruct 1.7.37

This document highlights the changes introduced in tinystruct version 1.7.37, a security and reliability release focused on static file serving access control, path traversal mitigation, and cross-server module consistency.

> See also: [What's New in 1.7.36](whats-new-1.7.36.md) for the previous release featuring MCP hardening and configurable logging handlers.

---

## Highlights of 1.7.37

- **Static File Serving Protection**: Static files are served exclusively from dedicated static directories (`server.static.dirs` or `server.static.dir`, default `static`). Project root files and sources are never exposed.
- **Path Traversal & Alias Mitigation**: Requests containing path traversal sequences, null bytes, encoded traversals, or Windows NTFS alternate data streams (`::$DATA`) and trailing dot/space aliases are strictly rejected with `403 Forbidden`.
- **Symlink Boundary Verification**: Resolved real paths must remain strictly within configured static directories, preventing directory escaping via symbolic links.
- **HTTP Caching & Conditional Requests**: Full support for `If-Modified-Since` (HTTP 304 Not Modified), `Cache-Control`, and `Expires` headers.
- **Unified Server Modules**: Updated `tinystruct-netty-http-server` (1.1.11), `tinystruct-tomcat-server` (1.1.11), and `tinystruct-undertow-server` (1.1.2) with matching security policies.
- **Logging Test Hardening**: Added test coverage verifying `LoggerConfigurer` multi-handler rotation, ANSI escape suppression for file logs, and handler resource cleanup.

---

## Details

### 1. Static File Serving Access Control

In previous releases, static file lookup could resolve against the project root directory if no specific static root was matched. Version 1.7.37 enforces strict directory whitelisting:

- Static files are served only from directories configured via `server.static.dirs` (comma- or semicolon-separated) or `server.static.dir` (default: `static`).
- Any attempt to access files in the project root directory (such as `pom.xml`, `application.properties`, `.git/config`, or source files in `src/`) is rejected with `403 Forbidden` (`This request is forbidden!`).
- Working directory boundary check: configured static directories cannot be the working directory itself or an ancestor directory.

```properties
# Custom static asset directories (defaults to "static" if unset)
server.static.dirs = static, public, assets
```

---

### 2. Path Traversal & Windows Alias Protection

The URI sanitization and static file resolution have been rewritten across `HttpServer` and all server modules:

- **Path Traversal**: Any relative segments (`..` or `.`), percent-encoded traversals (`%2e%2e`, `%2f`, `%5c`), and double slashes are rejected before file lookup.
- **Forbidden Characters**: Null bytes (`\0`) and colons (`:`) are rejected immediately, blocking drive letter injection and Windows NTFS Alternate Data Streams (such as `file.txt::$DATA`).
- **Trailing Dots and Spaces**: Windows file systems normalize `secret.txt.` and `secret.txt ` to `secret.txt`. Version 1.7.37 explicitly rejects paths with trailing dots or spaces in any segment.
- **Hidden Files**: Hidden files and folders (e.g., `.env`, `.git`) are never served.
- **Symlink Safety**: Before serving any file, `toRealPath()` is compared against the base directory's `toRealPath()` to prevent symlink traversal.

---

### 3. HTTP Caching Headers and 304 Not Modified

Static file responses now automatically handle cache validation:

- Sends `Cache-Control: public, max-age=86400, must-revalidate` and appropriate `Expires` headers.
- Evaluates the incoming `If-Modified-Since` header against the file's last modified timestamp. If matched, responds with `304 Not Modified` and closes the exchange without transmitting the body.
- Automatic MIME type lookup via `/META-INF/mime.types` with fallback to `java.nio.file.Files.probeContentType`.

---

### 4. Server Modules Updated

All tinystruct server modules have been updated to adopt the unified static file security model:

| Module | Version | tinystruct Version | Description |
| :--- | :--- | :--- | :--- |
| `tinystruct-netty-http-server` | **1.1.11** | `1.7.37` | `HttpStaticFileHandler` respects static directories and blocks root file downloads. |
| `tinystruct-tomcat-server` | **1.1.11** | `1.7.37` | Filter intercepts static routes and rejects path traversal before DefaultServlet. |
| `tinystruct-undertow-server` | **1.1.2** | `1.7.37` | Resolves whitelisted static paths and streams files using blocking worker channels. |

---

### 5. Logging Test Suite Hardening

Added `LoggerConfigurerTest` to test `LoggerConfigurer` behavior:
- Multi-handler setup: simultaneous `ConsoleHandler` and `FileHandler` creation.
- ANSI color escape code stripping: verifies log files do not contain ANSI formatting while console outputs retain colors.
- Re-configuration safety: re-running `LoggerConfigurer.setup()` releases previous file locks and prevents `.log.1` duplicate files.
- Graceful fallback: defaults to the built-in formatter when an unknown formatter class name is supplied.

---

## Migration Guide

### Updating to 1.7.37

Update your `pom.xml` dependency:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.37</version>
</dependency>
```

If you use server modules, update their versions accordingly:

```xml
<!-- Netty HTTP Server -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-netty-http-server</artifactId>
    <version>1.1.11</version>
</dependency>

<!-- Tomcat Server -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-tomcat-server</artifactId>
    <version>1.1.11</version>
</dependency>

<!-- Undertow Server -->
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct-undertow-server</artifactId>
    <version>1.1.2</version>
</dependency>
```

### Static Asset Placement

If your application relied on static files located directly in the project root, move them into a `static/` folder (or specify custom directories via `server.static.dirs`):

```
my-project/
├── pom.xml
├── src/
└── static/               <-- Place static web assets here
    ├── css/
    ├── js/
    └── images/
```

---

## Community and Resources

- **GitHub Repository**: <https://github.com/tinystruct/tinystruct>
- **Official Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Project Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
