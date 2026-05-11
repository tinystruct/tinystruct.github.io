# 使用 tinystruct 开发命令行应用

本指南解释如何使用 tinystruct 框架构建命令行界面 (CLI) 应用程序。

## CLI 基础

tinystruct 的 CLI 功能由与 Web 应用程序相同的动作机制提供支持，使得使用共享代码创建 CLI 工具和 Web 界面变得容易。

## CLI 与 Web 的统一设计

与许多将 CLI 视为事后修饰的框架不同，tinystruct 将 CLI 和 Web 视为平等公民。这意味着：
- 您可以为两种模式使用相同的 `@Action` 注解。
- 业务逻辑自然共享，无需额外的层。
- 您可以轻松地通过 CLI 测试您的 Web Action。
- 非常适合 AI 驱动的任务和自动化。

## 无需 main() 方法

tinystruct 的一个现代特性是它不需要在您的应用程序类中编写 `main()` 方法。应用程序直接通过 `bin/dispatcher` 工具启动。这减少了样板代码，让您的代码专注于逻辑本身。

## 创建 CLI 命令

### 基本命令

```java
@Action(value = "hello", 
        description = "显示问候语",
        mode = Action.Mode.CLI)
public String hello() {
    return "你好，世界！";
}
```

### 带参数的命令

```java
@Action(value = "hello", 
        description = "向指定名称显示问候语",
        mode = Action.Mode.CLI)
public String hello(String name) {
    return "你好，" + name + "！";
}
```

### 访问命令行参数

```java
@Action(value = "greet", 
        description = "问候某人",
        mode = Action.Mode.CLI)
public String greet() {
    String name = getContext().getAttribute("--name");
    String greeting = getContext().getAttribute("--greeting", "你好");
    
    if (name == null) {
        return "请使用 --name 提供名称";
    }
    
    return greeting + "，" + name + "！";
}
```

## 命令选项

您可以使用 `@Action` 注解中的 `options` 参数定义命令选项：

```java
@Action(
    value = "generate",
    description = "从模板生成代码",
    options = {
        @Argument(name = "template", alias = "t", description = "模板名称"),
        @Argument(name = "output", alias = "o", description = "输出目录")
    },
    mode = Action.Mode.CLI
)
public String generate() {
    String template = getContext().getAttribute("--template");
    String output = getContext().getAttribute("--output", "./output");
    
    // 使用模板生成代码
    return "使用 " + template + " 模板在 " + output + " 中生成代码";
}
```

## 运行 CLI 应用程序

### 使用调度器

```bash
# 基本命令
bin/dispatcher hello --import com.example.MyApp

# 带参数的命令
bin/dispatcher hello/John --import com.example.MyApp

# 带命名参数的命令
bin/dispatcher greet --name 张三 --greeting 你好 --import com.example.MyApp

# 带选项的命令
bin/dispatcher generate --template entity --output ./src/main/java --import com.example.MyApp
```

## 交互式 CLI 应用程序

### 读取用户输入

```java
@Action(value = "interactive", 
        description = "交互式命令示例",
        mode = Action.Mode.CLI)
public void interactive() {
    System.out.print("输入您的姓名：");
    Scanner scanner = new Scanner(System.in);
    String name = scanner.nextLine();
    
    System.out.print("输入您的年龄：");
    int age = scanner.nextInt();
    
    System.out.println("你好，" + name + "！您今年 " + age + " 岁。");
}
```

### 进度指示器

```java
@Action(value = "process", 
        description = "带进度指示器的处理",
        mode = Action.Mode.CLI)
public void process() {
    int total = 100;
    
    for (int i = 0; i <= total; i++) {
        System.out.print("\r处理中：" + i + "% [");
        int progress = i / 2;
        for (int j = 0; j < 50; j++) {
            if (j < progress) {
                System.out.print("=");
            } else if (j == progress) {
                System.out.print(">");
            } else {
                System.out.print(" ");
            }
        }
        System.out.print("] " + i + "%");
        
        try {
            Thread.sleep(50);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    System.out.println("\n处理完成！");
}
```

## 文件系统操作

```java
@Action(value = "copy", 
        description = "复制文件",
        mode = Action.Mode.CLI)
public String copy() {
    String source = getContext().getAttribute("--source");
    String destination = getContext().getAttribute("--destination");
    
    if (source == null || destination == null) {
        return "请提供 --source 和 --destination 参数";
    }
    
    try {
        Path sourcePath = Paths.get(source);
        Path destinationPath = Paths.get(destination);
        
        Files.copy(sourcePath, destinationPath, StandardCopyOption.REPLACE_EXISTING);
        return "文件从 " + source + " 成功复制到 " + destination;
    } catch (IOException e) {
        return "复制文件时出错：" + e.getMessage();
    }
}
```

## 数据库操作

```java
@Action(value = "export-users", 
        description = "将用户导出到 CSV",
        mode = Action.Mode.CLI)
public String exportUsers() {
    String outputFile = getContext().getAttribute("--output", "users.csv");
    
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        List<Row> users = repository.query("SELECT id, name, email FROM users");
        
        try (FileWriter writer = new FileWriter(outputFile);
             CSVWriter csvWriter = new CSVWriter(writer)) {
            
            // 写入标题
            csvWriter.writeNext(new String[]{"ID", "姓名", "邮箱"});
            
            // 写入数据
            for (Row user : users) {
                csvWriter.writeNext(new String[]{
                    user.getString("id"),
                    user.getString("name"),
                    user.getString("email")
                });
            }
        }
        
        return "已将 " + users.size() + " 个用户导出到 " + outputFile;
    } catch (Exception e) {
        return "导出用户时出错：" + e.getMessage();
    }
}
```

## 创建自定义命令

### 内置 POJO 生成器

Tinystruct 包含一个内置的 `generate` 命令，可以直接从数据库模式创建 POJO 类和 XML 映射文件。它自动检测列定义中的 Java 类型并添加所需的 import 语句 — 无需手动指定包。

```bash
# 交互模式 — 提示输入表名和输出路径
bin/dispatcher generate

# 非交互模式 — 直接指定表名
bin/dispatcher generate --tables users

# 多个表（分号分隔）
bin/dispatcher generate --tables "users;orders;products"
```

生成器：
- 支持 **MySQL**、**MSSQL**、**SQLite** 和 **H2** 数据库
- **自动导入** `java.time.LocalDateTime`、`java.util.Date`、`java.sql.Timestamp` 和 `java.sql.Time`（基于列类型）
- 同时生成 **Java POJO** 和 **XML 映射文件**
- 从源代码树自动检测项目的基础包
- 自动将表名单数化作为类名（例如 `users` → `User`）

完整详情和生成代码示例，请参阅[数据库集成 — 内置 POJO 生成器](database.md#内置-pojo-生成器)部分。


## 最佳实践

1. **提供清晰的帮助**：始终为您的命令包含描述性的帮助文本。

2. **验证输入**：检查命令参数并提供有用的错误消息。

3. **进度反馈**：对于长时间运行的操作，提供进度指示器。

4. **退出代码**：返回适当的退出代码以指示成功或失败。

5. **日志记录**：实现适当的日志记录以进行调试和审计。

## 下一步

- 了解[配置说明](configuration.md)
- 探索[数据库集成](database.md)
- 查看[高级特性](advanced-features.md)
