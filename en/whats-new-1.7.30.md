# What's New in tinystruct 1.7.30

This document highlights the new features, enhancements, and changes introduced in tinystruct version 1.7.30.

> See also: [What's New in 1.7.29](whats-new-1.7.29.md) for earlier features including Asymmetric RSA & Configurable JWT Security, and HTTP Server Security.

---

## Highlights of 1.7.30

- **PostgreSQL Database Support**: Added out-of-the-box support for PostgreSQL in the `Type` enum and Database operator. 

---

## Major New Features & Enhancements

### 1. PostgreSQL Integration
Tinystruct now natively supports PostgreSQL alongside MySQL, SQLite, H2, MS SQL Server, and Oracle. 
You can now configure your application to use PostgreSQL by specifying the appropriate driver in `application.properties` and using `Type.PostgreSQL`.

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

---

## Community and Resources

- **GitHub Repository**: <https://github.com/tinystruct/tinystruct>
- **Official Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Project Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
