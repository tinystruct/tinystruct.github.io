# tinystruct 数据库集成

本指南解释如何在 tinystruct 应用程序中集成和使用数据库。

## 支持的数据库

tinystruct 为多种数据库系统提供内置支持：

- MySQL
- SQLite
- H2
- Redis
- Microsoft SQL Server

## 配置

### 数据库属性

在属性文件中配置数据库连接：

```properties
# MySQL 配置
driver=com.mysql.cj.jdbc.Driver
database.url=jdbc:mysql://localhost:3306/mydb?useSSL=false&serverTimezone=UTC
database.user=root
database.password=password
database.connections.max=10

# H2 配置
# driver=org.h2.Driver
# database.url=jdbc:h2:~/test
# database.user=sa
# database.password=
# database.connections.max=10

# SQLite 配置
# driver=org.sqlite.JDBC
# database.url=jdbc:sqlite:mydb.sqlite
# database.user=
# database.password=
# database.connections.max=10
```

## 仓库 API

tinystruct 使用仓库模式进行数据库操作。Repository 接口提供了执行查询和更新的方法。

### 创建仓库

```java
// 创建 MySQL 仓库
Repository repository = Type.MySQL.createRepository();
repository.connect(getConfiguration());

// 创建 H2 仓库
Repository repository = Type.H2.createRepository();
repository.connect(getConfiguration());

// 创建 SQLite 仓库
Repository repository = Type.SQLite.createRepository();
repository.connect(getConfiguration());
```

### 执行查询

```java
@Action("users")
public JsonResponse getUsers() {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        List<Row> users = repository.query("SELECT id, name, email FROM users");
        
        return new JsonResponse(users);
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
    }
}
```

### 参数化查询

```java
@Action("users/{id}")
public JsonResponse getUser(Integer id) {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        List<Row> results = repository.query("SELECT id, name, email FROM users WHERE id = ?", id);
        
        if (results.isEmpty()) {
            return new JsonResponse(Map.of("error", "未找到用户"));
        }
        
        return new JsonResponse(results.get(0));
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
    }
}
```

### 执行更新

```java
@Action("users/create")
public JsonResponse createUser(Request request) {
    try {
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        
        if (name == null || email == null) {
            return new JsonResponse(Map.of("error", "名称和电子邮件是必需的"));
        }
        
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        int result = repository.execute(
            "INSERT INTO users (name, email) VALUES (?, ?)",
            name, email
        );
        
        return new JsonResponse(Map.of("success", true, "rowsAffected", result));
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
    }
}
```

### 事务

```java
@Action("transfer")
public JsonResponse transferFunds(Request request) {
    int fromAccount = Integer.parseInt(request.getParameter("from"));
    int toAccount = Integer.parseInt(request.getParameter("to"));
    double amount = Double.parseDouble(request.getParameter("amount"));
    
    Repository repository = Type.MySQL.createRepository();
    repository.connect(getConfiguration());
    
    try {
        repository.setAutoCommit(false);
        
        // 从源账户扣除
        int result1 = repository.execute(
            "UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance >= ?",
            amount, fromAccount, amount
        );
        
        if (result1 == 0) {
            repository.rollback();
            return new JsonResponse(Map.of("error", "资金不足"));
        }
        
        // 添加到目标账户
        int result2 = repository.execute(
            "UPDATE accounts SET balance = balance + ? WHERE id = ?",
            amount, toAccount
        );
        
        if (result2 == 0) {
            repository.rollback();
            return new JsonResponse(Map.of("error", "未找到目标账户"));
        }
        
        // 记录交易
        repository.execute(
            "INSERT INTO transactions (from_account, to_account, amount, date) VALUES (?, ?, ?, NOW())",
            fromAccount, toAccount, amount
        );
        
        repository.commit();
        
        return new JsonResponse(Map.of("success", true));
    } catch (Exception e) {
        repository.rollback();
        return new JsonResponse(Map.of("error", e.getMessage()));
    } finally {
        repository.setAutoCommit(true);
    }
}
```

## 处理结果

### Row 接口

`Row` 接口提供了访问列值的方法：

```java
List<Row> results = repository.query("SELECT id, name, email FROM users");

for (Row row : results) {
    int id = row.getInt("id");
    String name = row.getString("name");
    String email = row.getString("email");
    
    System.out.println("用户：" + id + ", " + name + ", " + email);
}
```

### 将结果转换为对象

```java
List<User> users = new ArrayList<>();
List<Row> results = repository.query("SELECT id, name, email FROM users");

for (Row row : results) {
    User user = new User();
    user.setId(row.getInt("id"));
    user.setName(row.getString("name"));
    user.setEmail(row.getString("email"));
    
    users.add(user);
}
```

## 数据库工具

### 架构创建

```java
@Action(value = "init-db", 
        description = "初始化数据库架构",
        mode = Action.Mode.CLI)
public String initDatabase() {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        // 创建用户表
        repository.execute(
            "CREATE TABLE IF NOT EXISTS users (" +
            "id INT AUTO_INCREMENT PRIMARY KEY, " +
            "name VARCHAR(100) NOT NULL, " +
            "email VARCHAR(100) NOT NULL UNIQUE, " +
            "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
            ")"
        );
        
        // 创建帖子表
        repository.execute(
            "CREATE TABLE IF NOT EXISTS posts (" +
            "id INT AUTO_INCREMENT PRIMARY KEY, " +
            "user_id INT NOT NULL, " +
            "title VARCHAR(200) NOT NULL, " +
            "content TEXT, " +
            "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
            "FOREIGN KEY (user_id) REFERENCES users(id)" +
            ")"
        );
        
        return "数据库架构初始化成功";
    } catch (Exception e) {
        return "初始化数据库时出错：" + e.getMessage();
    }
}
```

### 数据导入/导出

```java
@Action(value = "export-data", 
        description = "将数据导出到 CSV",
        mode = Action.Mode.CLI)
public String exportData() {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        List<Row> users = repository.query("SELECT id, name, email FROM users");
        
        try (FileWriter writer = new FileWriter("users.csv");
             CSVWriter csvWriter = new CSVWriter(writer)) {
            
            // 写入标题
            csvWriter.writeNext(new String[]{"ID", "姓名", "电子邮件"});
            
            // 写入数据
            for (Row user : users) {
                csvWriter.writeNext(new String[]{
                    String.valueOf(user.getInt("id")),
                    user.getString("name"),
                    user.getString("email")
                });
            }
        }
        
        return "已将 " + users.size() + " 个用户导出到 users.csv";
    } catch (Exception e) {
        return "导出数据时出错：" + e.getMessage();
    }
}
```

## 高级数据库操作

### 批处理操作

```java
@Action("batch-insert")
public JsonResponse batchInsert(Request request) {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        // 准备批处理数据
        List<Object[]> batchData = new ArrayList<>();
        batchData.add(new Object[]{"张三", "zhangsan@example.com"});
        batchData.add(new Object[]{"李四", "lisi@example.com"});
        batchData.add(new Object[]{"王五", "wangwu@example.com"});
        
        // 执行批量插入
        int[] results = repository.executeBatch(
            "INSERT INTO users (name, email) VALUES (?, ?)",
            batchData
        );
        
        return new JsonResponse(Map.of("success", true, "rowsAffected", Arrays.stream(results).sum()));
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
    }
}
```

### 存储过程

```java
@Action("call-procedure")
public JsonResponse callProcedure(Request request) {
    try {
        Repository repository = Type.MySQL.createRepository();
        repository.connect(getConfiguration());
        
        List<Row> results = repository.query(
            "CALL get_user_posts(?)",
            Integer.parseInt(request.getParameter("userId"))
        );
        
        return new JsonResponse(results);
    } catch (Exception e) {
        return new JsonResponse(Map.of("error", e.getMessage()));
    }
}
```

## 最佳实践

1. **连接管理**：完成后始终关闭数据库连接。

2. **参数化查询**：使用参数化查询防止 SQL 注入。

3. **事务**：对需要原子性的操作使用事务。

4. **错误处理**：为数据库操作实现适当的错误处理。

5. **连接池**：为应用程序需求配置适当的连接池设置。

## 下一步

- 了解[高级特性](advanced-features.md)
- 探索[最佳实践](best-practices.md)
- 查看[数据库 API 参考](api/database.md)
