# What's New in tinystruct 1.7.23

This document highlights the new features, improvements, and changes introduced in tinystruct version 1.7.23.

> See also: [What's New in 1.7.19](whats-new-1.7.18.md) for earlier features including HTTP method-specific actions, AI/MCP integration, and SSE support.

## Major New Features

### 1. Built-in POJO Generator with Automatic Imports

The framework now includes a fully automated POJO generator that creates Java classes and XML mapping files directly from your database schema. The generator intelligently detects column types and adds the necessary Java imports automatically — no manual package specification is required.

**Supported Databases:**
- MySQL
- Microsoft SQL Server (MSSQL)
- SQLite
- H2

**Usage:**

```bash
# Interactive mode — prompts for table names and output path
bin/dispatcher generate

# Non-interactive — specify tables directly
bin/dispatcher generate --tables users

# Multiple tables at once (semicolon-delimited)
bin/dispatcher generate --tables "users;orders;products"
```

**What It Generates:**

For each table, the generator produces two files:

1. **Java POJO** — e.g. `src/main/java/com/example/objects/User.java`
2. **XML Mapping** — e.g. `src/main/resources/com/example/objects/User.map.xml`

The generated classes extend `AbstractData` and integrate directly with tinystruct's ORM, enabling immediate CRUD operations (`append()`, `findOneById()`, `update()`, `delete()`).

### 2. Native `LocalDateTime` Support

Full support for Java 8+ `java.time.LocalDateTime` has been integrated into the data hydration layer.

**Field Mapping:**

| SQL Column Type | Java Type | Automatic Import |
|---|---|---|
| `DATETIME`, `TIMESTAMP`, `DATETIME2` | `LocalDateTime` | `java.time.LocalDateTime` |
| `DATE` | `Date` | `java.util.Date` |
| `TIMESTAMP` (explicit) | `Timestamp` | `java.sql.Timestamp` |
| `TIME` | `Time` | `java.sql.Time` |

**Robust Hydration:**

The `FieldInfo` utility now handles conversions from both `java.sql.Timestamp` objects and ISO-compliant strings, ensuring compatibility across different JDBC drivers and database vendors:

```java
// In generated POJO setData() method
if(row.getFieldInfo("created_at") != null)
    this.setCreatedAt(row.getFieldInfo("created_at").localDateTimeValue());
```

### 3. Streamlined CLI Generator Workflow

The `generate` command has been simplified by removing the interactive prompt for manual package imports. The generator now:

- **Auto-detects** your project's base package from the source tree
- **Automatically imports** all required types based on database column types
- Only prompts for **table name(s)** and **base path** — two simple steps

**Before (1.7.19):**
```
Please specify the table name(s):
Please specify the base path:
Please specify the packages to be imported:   ← REMOVED
```

**After (1.7.23):**
```
Please specify the table name(s):
Please specify the base path:
```

## Architecture Improvements

### Simplified Generator Interface

The `Generator` interface has been streamlined by removing the `importPackages()` method. Import management is now fully internal to each generator implementation.

**Before:**
```java
public interface Generator {
    void setPath(String path);
    void setPackageName(String packageName);
    void importPackages(String packageNameList);  // REMOVED
    void create(String className, String table) throws ApplicationException;
}
```

**After:**
```java
public interface Generator {
    void setPath(String path);
    void setPackageName(String packageName);
    void create(String className, String table) throws ApplicationException;
}
```

### Modern Java Switch Expressions

All generators now use modern Java switch expressions for type-to-import resolution, replacing verbose if-else chains:

```java
// Automatic imports based on propertyType
switch (propertyType) {
    case "LocalDateTime" -> imports.add("java.time.LocalDateTime");
    case "Date" -> imports.add("java.util.Date");
    case "Timestamp" -> imports.add("java.sql.Timestamp");
    case "Time" -> imports.add("java.sql.Time");
}
```

### Unique and Sorted Imports

Imports are collected using a `TreeSet`, ensuring they are always unique and alphabetically sorted in the generated output:

```java
import java.io.Serializable;
import java.time.LocalDateTime;
import org.tinystruct.data.component.AbstractData;
import org.tinystruct.data.component.Row;
```

## Breaking Changes

### `Generator.importPackages()` Removed

The `importPackages(String packageNameList)` method has been removed from the `Generator` interface and all implementations. If your code directly calls this method on a generator instance, remove those calls — imports are now handled automatically.

## Migration Guide

### From 1.7.19 to 1.7.23

1. **Update Maven Dependency**
   ```xml
   <dependency>
       <groupId>org.tinystruct</groupId>
       <artifactId>tinystruct</artifactId>
       <version>1.7.23</version>
   </dependency>
   ```

2. **Remove Manual Import Calls** (if applicable)
   ```java
   // Old way — no longer needed
   generator.importPackages("java.time.LocalDateTime;java.util.Date");

   // New way — imports are automatic, just call create()
   generator.create(className, tableName);
   ```

3. **Enjoy the Simplified CLI**
   The `generate` command no longer prompts for packages. Just provide your table names and output path.

## Community and Resources

- **GitHub**: <https://github.com/tinystruct/tinystruct>
- **Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
- **Smalltalk (AI Chat)**: <https://github.com/tinystruct/smalltalk>

## What's Next

### Planned for Future Releases

- Enhanced reactive programming support
- GraphQL integration
- gRPC support
- Kubernetes native features
- Enhanced monitoring and metrics

## Conclusion

Version 1.7.23 focuses on developer experience by automating the POJO generation pipeline. The addition of native `LocalDateTime` support and automatic import detection means less manual configuration and fewer errors during code generation. The streamlined CLI workflow reduces the generation process to just two prompts, making it faster to go from database schema to working Java code.
