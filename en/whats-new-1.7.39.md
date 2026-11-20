# What's New in tinystruct 1.7.39

This document highlights the changes introduced in tinystruct version 1.7.39, a security, stability, and portability release featuring the new `TokenGuard` pre-authentication input validation engine, HTTP and MCP status code mapping, template engine cross-platform portability and locale fixes, ClassLoader fallback resolution, and core DOM and connection manager bug fixes.

> See also: [What's New in 1.7.38](whats-new-1.7.38.md) for the previous release featuring ASM CVE patches, JSON round-trip fixes, and faster lock-file I/O.

---

## Highlights of 1.7.39

- **TokenGuard Pre-Authentication Token Defense**: Introduced `org.tinystruct.http.security.TokenGuard` for proactive, pre-authentication validation of authorization tokens across the framework. Enforces configurable maximum length limits (`4096`), rejects empty or whitespace-only inputs, filters illegal ASCII control characters and newlines, strictly validates Base64 padding semantics, and validates compact JWT structure (RFC 7515/7519) prior to expensive cryptographic operations.
- **ReDoS Protection with Bounded Regex Evaluation**: Token deny patterns support regular expressions evaluated through a step-budgeted `CharSequence` (budgeted at 50,000 character reads), preventing Regular Expression Denial of Service (ReDoS) and failing closed safely if evaluation exceeds budget.
- **HTTP Server & MCP Security Status Mapping**: `HttpServer` and `AuthorizationHandler` integrate `TokenGuard`. `HttpServer` maps validation and parsing outcomes to precise HTTP response statuses: `400 Bad Request` for malformed or oversized tokens, `401 Unauthorized` for failed authentication or expired tokens, and `403 Forbidden` for policy-blocked tokens. `AuthorizationHandler` cleanly supports optional `Bearer ` scheme prefixes without rejecting standard headers.
- **Template Engine Cross-Platform Portability**: `AbstractApplication.toString()` standardizes on `'/'` as the template path separator instead of the OS-dependent `File.separatorChar`, ensuring seamless cross-platform template resolution on Windows and within executable JARs.
- **Locale Resolution & ClassLoader Hierarchy**: Removed the hardcoded `Locale.CHINA` comparison in `AbstractApplication` so localized templates work consistently across all configured locales. Added a 3-tier ClassLoader fallback (Thread context class loader -> Class-level class loader -> System class loader) in `getResourceAsStream`.
- **Stream Leak Prevention**: Converted template `InputStream` loading in `AbstractApplication` to try-with-resources, preventing resource leaks on I/O or parsing failures.
- **DOM & Core Stability Fixes**: Fixed an infinite loop in `Element.removeElement(String)` by properly advancing the child index; wrapped original `IOException` in `Document.load(...)` instead of its potentially null cause; safely handled URI credentials in `ConnectionManager` when username is provided without a password; and allowed 1-, 2-, or 3-part locales in `AbstractApplication.setLocale(...)`.

---

## Details

### 1. TokenGuard Pre-Authentication Token Defense

Prior to version 1.7.39, invalid or malicious authorization tokens were passed directly to cryptographic parsing libraries (such as JJWT), which could incur high CPU costs when parsing oversized payloads, deeply nested structures, or malformed inputs.

`TokenGuard` provides a dedicated, lightweight pre-authentication validation layer in `org.tinystruct.http.security.TokenGuard`:

- **Oversized Token Mitigation**: Enforces a configurable maximum length limit (default `4096` characters, configurable via `security.token.guard.max-length`). Oversized tokens are rejected in sub-millisecond time before entering cryptographic parsers, preventing memory exhaustion and denial-of-service vectors.
- **Whitespace & Control Character Filtering**: Strips leading and trailing whitespace and rejects tokens containing newlines (`\r`, `\n`), tabs, null bytes, or non-printable ASCII control characters (`< 0x20` or `0x7F`).
- **Base64 Padding Semantics**: Validates that Base64 padding (`=`) only appears at the end of payloads, contains at most two padding characters, and enforces modulo-4 total length constraints whenever padding is present.
- **RFC 7515/7519 Compact JWT Validation**: For JWT tokens, verifies exactly 2 period separators dividing into 3 non-empty unpadded Base64URL parts (`header.payload.signature`), rejecting misplaced or invalid characters before cryptographic verification.
- **Safe Token Masking in Logs**: Provides `TokenGuard.mask(token)` to prevent accidental leakage of sensitive credentials in log files (e.g. `eyJ...abc [len=142]`).

```java
// Create a TokenGuard with custom configuration
TokenGuard guard = new TokenGuard();
guard.setMaxLength(2048);
guard.setPatternDetection(true);
guard.setBlockPatterns("^revoked-.*,.*malicious.*");

// Validate tokens prior to cryptographic operations
TokenGuard.ValidationResult result = guard.validate(rawToken, TokenGuard.TokenType.JWT);
if (!result.isValid()) {
    // Status can be: INVALID_FORMAT, OVERSIZED, MALFORMED, or BLOCKED
    logger.warning("Token rejected: " + result.getStatus() + " - " + result.getMessage());
}

// Attach TokenGuard to JWTManager
JWTManager jwtManager = new JWTManager().withTokenGuard(guard);
```

---

### 2. ReDoS Protection with Bounded Regex Evaluation

When token pattern detection is enabled (`security.token.guard.pattern-detection=true`), tokens are checked against configured regex deny patterns (`security.token.guard.block-patterns`).

To defend against Regular Expression Denial of Service (ReDoS) from catastrophic backtracking patterns, `TokenGuard` wraps evaluated inputs in a `BudgetedCharSequence` limited to **50,000 character read operations**:

- If pattern evaluation exceeds the allocated step budget, a `PatternBudgetExceededException` is thrown.
- The guard fails closed, returning `TokenGuard.Status.BLOCKED`, ensuring predictable execution times (< 1 ms) regardless of input size or pattern complexity.

```java
// Bounded evaluation prevents catastrophic backtracking from locking worker threads
tokenGuard.setPatternDetection(true);
tokenGuard.setBlockPatterns("a*a*a*a*a*b");

// Catastrophic pattern terminates within bounded steps and fails closed safely
TokenGuard.ValidationResult result = tokenGuard.validate("aaaaaaaaaaaaaaaaaaaaaaaaa", TokenGuard.TokenType.GENERIC);
assert TokenGuard.Status.BLOCKED == result.getStatus();
```

---

### 3. HTTP Server & MCP Security Status Mapping

`HttpServer` and MCP `AuthorizationHandler` now integrate `TokenGuard` to return accurate HTTP response statuses:

| Status Code | Meaning | Trigger |
| :--- | :--- | :--- |
| **`400 Bad Request`** | Malformed input | Oversized tokens, control characters, invalid Base64 padding, or broken JWT structure |
| **`401 Unauthorized`** | Authentication failure | Expired tokens, invalid cryptographic signatures, or missing JWT secret/keys |
| **`403 Forbidden`** | Policy blocked | Tokens matching configured `security.token.guard.block-patterns` |

In MCP `AuthorizationHandler`:
- Authorization headers with optional `Bearer ` schemes are properly parsed before validation, preventing normal scheme separation spaces from being flagged as invalid control whitespace.
- Malformed or oversized credentials fail closed immediately before attempting database or token comparisons.

---

### 4. Template Engine Portability & ClassLoader Improvements

- **Cross-Platform Template Paths**: In `AbstractApplication.toString()`, template file path concatenation now standardizes on `/` instead of `File.separatorChar`. On Windows, `File.separatorChar` produced `\` paths that failed to resolve resources packaged inside JAR files or across UNIX-standard container deployments.
- **Locale Resolution Fix**: Removed a hardcoded `Locale.CHINA` identity check in `AbstractApplication` that prevented templates for other configured locales from resolving correctly. Localized templates now match the application's actual locale setting.
- **ClassLoader Hierarchy Fallback**: `AbstractApplication.getResourceAsStream(...)` now implements a robust three-tier ClassLoader search strategy:
  1. Thread context ClassLoader: `Thread.currentThread().getContextClassLoader()`
  2. Class-level ClassLoader: `AbstractApplication.class.getClassLoader()`
  3. System ClassLoader: `ClassLoader.getSystemClassLoader()`
- **Try-With-Resources Leak Prevention**: Template stream reads in `AbstractApplication` are now wrapped in `try-with-resources` blocks to guarantee `InputStream` closure even if parsing or reading encounters an exception.

---

### 5. DOM, Data & Core Stability Fixes

- **`Element.removeElement(String)` Infinite Loop**: Advancing loop counter index fixed an issue where removing elements by tag name from an XML or DOM tree could stall in an infinite loop.
- **`Document.load(...)` Exception Cause**: When XML parsing fails with an `IOException`, the exception is now wrapped directly rather than referencing `e.getCause()`, which was frequently `null` and obscured the underlying error message.
- **Safe ConnectionManager User Info Parsing**: Safely parses URI authority when only a username is provided without a colon or password (e.g. `user@host`), eliminating `ArrayIndexOutOfBoundsException`.
- **Flexible Locale Parsing**: `AbstractApplication.setLocale(String)` now safely parses 1-, 2-, or 3-part locale strings (e.g. `en`, `zh_CN`, `zh_CN_POSIX`).

---

### 6. Configuration Reference

New configuration properties in `application.properties`:

| Property | Description | Default |
| :--- | :--- | :--- |
| `security.token.guard.enabled` | Enable pre-authentication token validation (`TokenGuard`) | `true` |
| `security.token.guard.max-length` | Maximum allowed token character length | `4096` |
| `security.token.guard.reject-malformed` | Reject invalid Base64 padding, control chars, and malformed JWT structures | `true` |
| `security.token.guard.pattern-detection` | Enable regex deny-pattern evaluation | `false` |
| `security.token.guard.block-patterns` | Comma-separated list of regex patterns to block | _(empty)_ |

Example `application.properties` snippet:

```properties
# Security Token Guard settings
security.token.guard.enabled=true
security.token.guard.max-length=4096
security.token.guard.reject-malformed=true
security.token.guard.pattern-detection=false
security.token.guard.block-patterns=
```

---

## Migration Guide

### Updating to 1.7.39

Update your `pom.xml` dependency:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.39</version>
</dependency>
```

### Things to Check When Upgrading from 1.7.38

- **Token Pre-Validation Behavior**: Requests with invalid JWT structures or trailing padding errors that previously resulted in `401 Unauthorized` will now receive `400 Bad Request`. If client integrations expect 401 specifically for malformed tokens, verify client-side handling.
- **Token Length Limit**: If your application issues exceptionally large JWTs (e.g., carrying large permission claims or serialized state > 4 KB), increase `security.token.guard.max-length` in `application.properties` accordingly.
- **Template Resource Separators**: Custom template loaders relying on Windows backslashes (`\`) should be updated to use `/`, ensuring seamless deployment across both Linux and Windows environments.

---

## Community and Resources

- **GitHub Repository**: <https://github.com/tinystruct/tinystruct>
- **Official Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Project Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
