# 使用 tinystruct 开发命令行应用

本指南解释如何使用 tinystruct 框架构建命令行界面 (CLI) 应用程序。

## CLI 基础

tinystruct 的 CLI 功能由与 Web 应用程序相同的动作机制提供支持，使得使用共享代码创建 CLI 工具和 Web 界面变得容易。

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

### POJO 生成器示例

```java
@Action(
    value = "generate-pojo",
    description = "从数据库表生成 POJO 类",
    options = {
        @Argument(name = "table", description = "数据库表名"),
        @Argument(name = "package", description = "Java 包名"),
        @Argument(name = "output", description = "输出目录")
    },
    mode = Action.Mode.CLI
)
public String generatePojo() {
    String table = getContext().getAttribute("--table");
    String packageName = getContext().getAttribute("--package", "com.example.model");
    String output = getContext().getAttribute("--output", "./src/main/java");
    
    if (table == null) {
        return "请使用 --table 提供表名";
    }
    
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        // 获取表元数据
        List<Row> columns = repository.query(
            "SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE " +
            "FROM INFORMATION_SCHEMA.COLUMNS " +
            "WHERE TABLE_NAME = ?", table);
        
        if (columns.isEmpty()) {
            return "未找到表或表没有列：" + table;
        }
        
        // 生成类名（将 snake_case 转换为 CamelCase）
        String className = Arrays.stream(table.split("_"))
            .map(word -> word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase())
            .collect(Collectors.joining());
        
        // 生成 Java 代码
        StringBuilder code = new StringBuilder();
        code.append("package ").append(packageName).append(";\n\n");
        code.append("public class ").append(className).append(" {\n\n");
        
        // 生成字段
        for (Row column : columns) {
            String columnName = column.getString("COLUMN_NAME");
            String dataType = column.getString("DATA_TYPE");
            String javaType = mapSqlTypeToJava(dataType);
            String fieldName = toCamelCase(columnName);
            
            code.append("    private ").append(javaType).append(" ").append(fieldName).append(";\n");
        }
        
        code.append("\n");
        
        // 生成 getter 和 setter
        for (Row column : columns) {
            String columnName = column.getString("COLUMN_NAME");
            String dataType = column.getString("DATA_TYPE");
            String javaType = mapSqlTypeToJava(dataType);
            String fieldName = toCamelCase(columnName);
            String capitalizedFieldName = fieldName.substring(0, 1).toUpperCase() + fieldName.substring(1);
            
            // Getter
            code.append("    public ").append(javaType).append(" get").append(capitalizedFieldName).append("() {\n");
            code.append("        return ").append(fieldName).append(";\n");
            code.append("    }\n\n");
            
            // Setter
            code.append("    public void set").append(capitalizedFieldName).append("(").append(javaType).append(" ").append(fieldName).append(") {\n");
            code.append("        this.").append(fieldName).append(" = ").append(fieldName).append(";\n");
            code.append("    }\n\n");
        }
        
        code.append("}");
        
        // 写入文件
        String packagePath = packageName.replace('.', '/');
        Path outputPath = Paths.get(output, packagePath, className + ".java");
        Files.createDirectories(outputPath.getParent());
        Files.write(outputPath, code.toString().getBytes());
        
        return "已在 " + outputPath + " 生成 " + className + ".java";
    } catch (Exception e) {
        return "生成 POJO 时出错：" + e.getMessage();
    }
}

private String toCamelCase(String snakeCase) {
    StringBuilder result = new StringBuilder();
    boolean nextUpper = false;
    
    for (char c : snakeCase.toCharArray()) {
        if (c == '_') {
            nextUpper = true;
        } else {
            if (nextUpper) {
                result.append(Character.toUpperCase(c));
                nextUpper = false;
            } else {
                result.append(Character.toLowerCase(c));
            }
        }
    }
    
    return result.toString();
}

private String mapSqlTypeToJava(String sqlType) {
    switch (sqlType.toUpperCase()) {
        case "VARCHAR":
        case "CHAR":
        case "TEXT":
            return "String";
        case "INT":
        case "SMALLINT":
        case "TINYINT":
            return "Integer";
        case "BIGINT":
            return "Long";
        case "DECIMAL":
        case "NUMERIC":
            return "BigDecimal";
        case "FLOAT":
            return "Float";
        case "DOUBLE":
            return "Double";
        case "BOOLEAN":
        case "BIT":
            return "Boolean";
        case "DATE":
            return "LocalDate";
        case "TIME":
            return "LocalTime";
        case "DATETIME":
        case "TIMESTAMP":
            return "LocalDateTime";
        default:
            return "Object";
    }
}
```

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
