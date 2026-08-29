# What's New in tinystruct 1.7.29

This document highlights the new features, security enhancements, performance improvements, and changes introduced in tinystruct version 1.7.29.

> See also: [What's New in 1.7.23](whats-new-1.7.23.md) for earlier features including automated POJO generation and native `LocalDateTime` support.

---

## Highlights of 1.7.29

- **Asymmetric RSA & Configurable JWT Security**: Support for RSA public/private key pairs and flexible configuration via `application.properties`.
- **Advanced HTTP Server Security & Host Filtering**: Host header restriction via `server.name`, robust path traversal prevention, environment-based error masking, and secure cookie handling.
- **Decoupled Architecture & Domain Independence**: Removed hardcoded server domain dependencies from `HttpServer` and `SSEPushManager` for seamless multi-domain, containerized, and local development.
- **Model Context Protocol (MCP) & AI Enhancements**: Support for overloaded tool methods, schema merging, idle session watchdogs, automatic cleanup, and enhanced error resiliency.
- **Modern ANSI Console Logging & StackWalker Caller Tracing**: Color-coded console log formatting with zero-overhead, precise caller location resolution.
- **Configurable HTTP Client Timeouts**: Connect and read timeout configurations on `URLRequest` and `HTTPHandler`.
- **Dependency Upgrades**: Latest minor/patch updates for SQLite JDBC (3.53.2.1), JUnit Jupiter (6.1.1), JNA (5.19.1), and Apache Kafka (4.3.1).

---

## Major New Features & Enhancements

### 1. Asymmetric RSA & Configurable JWT Security

The `JWTManager` now supports both symmetric HMAC keys and asymmetric RSA public/private key pairs, enabling enterprise-grade authentication topologies (e.g., signing tokens on an auth server with a private key and validating them on resource servers with a public key).

#### RSA Key Pair Support in `JWTManager`:
```java
JWTManager jwtManager = new JWTManager();

// Sign using RSA Private Key (Base64 PKCS#8)
jwtManager.withPrivateKey(base64PrivateKey);
String token = jwtManager.createToken(builder);

// Verify using RSA Public Key (Base64 X.509)
jwtManager.withPublicKey(base64PublicKey);
Map<String, Object> claims = jwtManager.verify(token);
```

#### Declarative Configuration in `application.properties`:
The built-in HTTP server automatically reads JWT configuration for Bearer token validation:

```properties
# Verify with RSA Public Key (Base64 X.509 format)
jwt.key.public=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQE...

# Or verify with HMAC Secret
jwt.secret=your-256-bit-secret-key-here
jwt.secret.format=plain # 'plain' or 'base64' (default)

# Optional JWT validation timezone
jwt.timezone=UTC
```

---

### 2. HTTP Server Security Controls & Host Filtering

#### Host Header Validation (`server.name`):
Prevent HTTP Host header attacks by restricting incoming requests to configured domain names or hostnames.

```properties
# Restrict requests to specified Host headers (comma-separated). Leave empty to allow all.
server.name=localhost:8080, api.example.com, example.com
```

#### Path Traversal Protection:
Static resource resolution in `HttpServer` and `Dispatcher` has been fortified using `Path.normalize()` against base directory bounds checks to prevent unauthorized file access across all operating systems.

#### Secure Cookies & Environment-Aware Error Responses:
- Automatic `Secure` cookie flag assignment for HTTPS requests.
- Server error messages automatically mask internal exception details in `production` while providing diagnostic information when `system.environment=development`.

---

### 3. Model Context Protocol (MCP) & AI Integration Advancements

The Model Context Protocol (MCP) implementation received substantial upgrades for enterprise AI tool exposure:

- **Overloaded Tool Methods**: `MCPServer` now supports overloaded methods with identical action paths by merging input schemas and routing parameters dynamically.
- **Session Watchdog & Idle Cleanup**: Integrated ping handler, keep-alive watchdog, and automatic session cleanup for disconnected AI clients.
- **Direct POJO Registration**: Expose any POJO or service directly to AI models without having to inherit from `MCPTool`.

```java
public class CustomMCPServer extends MCPServer {
    @Override
    public void init() {
        super.init();
        // Register any plain object directly
        this.registerTool(new CalculatorService());
    }
}
```

---

### 4. ANSI Console Logging with StackWalker Tracing

Logging has been upgraded with a high-performance programmatic formatter:
- **ANSI Color Coding**: Distinct visual levels (INFO, WARNING, SEVERE, DEBUG).
- **Precise Caller Tracing**: Utilizes Java 9+ `StackWalker` for zero-overhead, accurate source class, method name, and line number resolution.
- **Default INFO Level**: Standard logging enabled by default with clean formatting.

---

### 5. Configurable HTTP Client Timeouts & Browser Automation

- **`URLRequest` & `HTTPHandler` Timeouts**: Added explicit `connectTimeout` and `readTimeout` methods.
  ```java
  URLRequest request = new URLRequest(new URL("https://api.example.com/data"))
          .setConnectTimeout(5000)  // 5 seconds
          .setReadTimeout(10000);   // 10 seconds
  ```
- **Open-Browser Integration**: Configure the HTTP server to automatically open the default browser on launch via `server.openbrowser=true` and `server.openbrowser.command`.

---

### 6. Dependency Upgrades

| Library | Previous Version | New Version (1.7.29) |
|---|---|---|
| **SQLite JDBC** | 3.45.1.0 | `3.53.2.1` |
| **JUnit Jupiter** | 5.10.2 | `6.1.1` |
| **JNA** | 5.14.0 | `5.19.1` |
| **Apache Kafka** | 3.7.0 | `4.3.1` |
| **Maven Assembly Plugin** | 2.2-beta-5 | `3.7.1` |

---

## Migration Guide

### Updating to 1.7.29

Update your `pom.xml` dependency to version `1.7.29`:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.29</version>
</dependency>
```

#### JWT Secret Configuration
If you use plain text secrets in `application.properties`, specify `jwt.secret.format=plain`:

```properties
jwt.secret=my-plain-text-secret-key
jwt.secret.format=plain
```

---

## Community and Resources

- **GitHub Repository**: <https://github.com/tinystruct/tinystruct>
- **Official Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Project Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
