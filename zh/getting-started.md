# tinystruct 入门指南

本指南将帮助您设置第一个 tinystruct 应用程序并了解基本工作流程。

## 前提条件

- Java 开发工具包 (JDK) 17 或更高版本
- Maven（用于依赖管理）
- 文本编辑器或 IDE（IntelliJ IDEA、Eclipse、VS Code 等）

## 安装

### Maven 依赖

将 tinystruct 依赖项添加到项目的 `pom.xml` 文件中：

```xml
<dependency>
    <groupId>org.tinystruct</groupId>
    <artifactId>tinystruct</artifactId>
    <version>1.7.8</version>
    <classifier>jar-with-dependencies</classifier>
</dependency>
```

### 手动安装

或者，您可以直接从 [Maven 仓库](https://mvnrepository.com/artifact/org.tinystruct/tinystruct) 下载 JAR 文件，并将其添加到项目的类路径中。

## 创建您的第一个应用程序

### 1. 创建基本应用程序类

创建一个扩展 `AbstractApplication` 的新 Java 类：

```java
package com.example;

import org.tinystruct.AbstractApplication;
import org.tinystruct.system.annotation.Action;

public class HelloWorldApp extends AbstractApplication {

    @Override
    public void init() {
        // 初始化代码
    }

    @Override
    public String version() {
        return "1.0.0";
    }

    @Action("hello")
    public String hello() {
        return "你好，世界！";
    }

    @Action("hello")
    public String hello(String name) {
        return "你好，" + name + "！";
    }
}
```

### 2. 创建配置文件

在项目的资源目录中创建 `config.properties` 文件：

```properties
# 应用程序设置
application.name=HelloWorldApp
application.mode=development

# 服务器设置
server.port=8080
server.host=localhost

# 默认设置
default.file.encoding=UTF-8
default.home.page=hello/World
default.reload.mode=true
default.date.format=yyyy-MM-dd HH:mm:ss
```

### 3. 作为 CLI 应用程序运行

您可以使用 tinystruct 调度器从命令行运行应用程序：

```bash
# 显示版本
bin/dispatcher --version

# 运行 hello 动作
bin/dispatcher hello --import com.example.HelloWorldApp

# 使用参数运行
bin/dispatcher hello/John --import com.example.HelloWorldApp
```

### 4. 作为 Web 应用程序运行

要将应用程序作为 Web 服务器运行：

```bash
# 使用 Netty 启动服务器
bin/dispatcher start --import org.tinystruct.system.NettyHttpServer --import com.example.HelloWorldApp
```

然后访问您的应用程序：
- http://localhost:8080/?q=hello
- http://localhost:8080/?q=hello/John

## 项目结构

典型的 tinystruct 项目结构如下所示：

```
my-app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── example/
│   │   │           ├── HelloWorldApp.java
│   │   │           └── ...
│   │   └── resources/
│   │       └── config.properties
│   └── test/
│       └── java/
│           └── com/
│               └── example/
│                   └── HelloWorldAppTest.java
├── bin/
│   └── dispatcher
└── pom.xml
```

## 下一步

- 了解[核心概念](core-concepts.md)
- 探索[Web应用开发](web-applications.md)
- 查看[命令行应用](cli-applications.md)
- 理解[配置说明](configuration.md)
- 深入[数据库集成](database.md)
