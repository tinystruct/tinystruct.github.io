# What's New in tinystruct 1.7.35

This document highlights the changes introduced in tinystruct version 1.7.35, a maintenance release focused on dependency security, reliability, and build tooling.

> See also: [What's New in 1.7.34](whats-new-1.7.34.md) for the previous release featuring annotation-driven ORM mapping and enum-collection arguments.

---

## Highlights of 1.7.35

- **Dependency Upgrades**: Lettuce 7.8.0, H2 2.5.252, Mockito 5.24.0, and a pinned Netty BOM 4.2.18.Final.
- **CVE Patches**: Vulnerable transitive dependencies (Netty, Kafka's zstd-jni / lz4-java / snappy-java, and Reactor) are now overridden with patched versions.
- **Proper Interrupt Handling**: `DistributedMessageQueue` and `AlarmClock` now restore the thread interrupt flag instead of swallowing `InterruptedException`.
- **Cleaner `DistributedMessageQueue`**: The duplicated producer/consumer runnables were extracted into shared `produce` / `consume` helpers.
- **CI Workflow**: A GitHub Actions build workflow was added, and the central publishing plugin was bumped to 0.11.0.

---

## Details

### 1. Dependency Upgrades and CVE Patches

| Dependency | Old | New |
|---|---|---|
| Lettuce | 7.7.0.RELEASE | 7.8.0.RELEASE |
| H2 | 2.5.250 | 2.5.252 |
| Mockito | 5.23.0 | 5.24.0 |
| Netty (via BOM) | 4.2.13.Final | 4.2.18.Final |
| zstd-jni | transitive | 1.5.7-20 |
| lz4-java | transitive | 1.12.0 |
| snappy-java | transitive | 1.1.10.8 |
| reactor-core | transitive | 3.6.18 |

The framework's `pom.xml` now imports the Netty BOM and manages the patched transitive versions through `dependencyManagement`, so all Netty modules stay aligned.

> **Tip:** If your application depends on tinystruct and also declares these libraries directly, consider aligning your own versions with the table above.

---

### 2. Reliable Interrupt Handling

Previously, interrupted threads in the message queue and the alarm clock logged the exception and kept running. They now call `Thread.currentThread().interrupt()` so that executors can shut the work down cleanly:

- Producer loops exit as soon as the thread is interrupted.
- Consumer loops run `while (!Thread.currentThread().isInterrupted())` and stop on shutdown.
- Console `System.out` output in the queue demo was replaced by the framework logger.

There are no API changes; existing `DistributedMessageQueue` usage works as before.

---

## Migration Guide

### Updating to 1.7.35

Update your `pom.xml` dependency:

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.35</version>
</dependency>
```

No source changes are required when upgrading from 1.7.34.

---

## Community and Resources

- **GitHub Repository**: <https://github.com/tinystruct/tinystruct>
- **Official Documentation**: <https://tinystruct.org>
- **Examples**: <https://github.com/tinystruct/tinystruct-examples>
- **Project Archetype**: <https://github.com/tinystruct/tinystruct-archetype>
