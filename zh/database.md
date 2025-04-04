# Tinystruct 数据库集成

本指南解释如何在 Tinystruct 应用程序中集成和使用数据库。

## 支持的数据库

Tinystruct 为多种数据库系统提供内置支持：

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

## 数据库访问方法

Tinystruct 提供多种数据库访问方法：

1. **DatabaseOperator**：一个方便的数据库操作工具类
2. **直接仓库 API**：使用 Repository 接口进行原始 SQL 查询和更新
3. **对象映射**：使用带有 XML 配置的映射 Java 对象，实现更面向对象的方法

## DatabaseOperator

`DatabaseOperator` 类提供了一种方便的方式来执行数据库操作，而无需直接管理 Repository 实例。

### 基本用法

```java
// 创建 DatabaseOperator 实例
DatabaseOperator operator = new DatabaseOperator();

// 执行查询
List<Map<String, Object>> results = operator.query("SELECT * FROM users WHERE id = ?", 1);

// 执行更新
int rowsAffected = operator.update("UPDATE users SET name = ? WHERE id = ?", "张三", 1);

// 执行插入
int newId = operator.insert("INSERT INTO users (name, email) VALUES (?, ?)", "李四", "lisi@example.com");

// 执行删除
operator.update("DELETE FROM users WHERE id = ?", 1);
```

### 事务支持

```java
// 开始事务
operator.begin();

try {
    // 执行多个操作
    operator.update("UPDATE accounts SET balance = balance - ? WHERE id = ?", 100.0, 1);
    operator.update("UPDATE accounts SET balance = balance + ? WHERE id = ?", 100.0, 2);

    // 提交事务
    operator.commit();
} catch (Exception e) {
    // 出错时回滚
    operator.rollback();
    throw e;
}
```

## 仓库 API

Tinystruct 还使用仓库模式进行直接数据库操作。Repository 接口提供了执行查询和更新的方法。

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
@Action("users")
public String getUser(Integer id, Request request, Response response) {
    try {
        // 创建 DatabaseOperator 实例
        DatabaseOperator operator = new DatabaseOperator();

        // 执行带参数的查询
        List<Map<String, Object>> results = operator.query("SELECT id, name, email FROM users WHERE id = ?", id);

        // 设置内容类型为 JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        if (results.isEmpty()) {
            // 创建错误响应
            Builder builder = new Builder();
            builder.put("error", "未找到用户");
            return builder.toString();
        }

        // 创建成功响应
        Builder builder = new Builder();
        builder.put("user", results.get(0));
        return builder.toString();
    } catch (Exception e) {
        // 设置内容类型为 JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // 创建错误响应
        Builder builder = new Builder();
        builder.put("error", e.getMessage());
        return builder.toString();
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

## 对象映射方法

Tinystruct 还支持使用通过 XML 配置文件映射到数据库表的 Java 对象进行面向对象的数据库访问。

### 1. 定义模型类

创建代表数据库实体的 Java 类：

```java
package custom.objects;

import org.tinystruct.data.component.AbstractData;

public class Book extends AbstractData {
    private int id;
    private String name;
    private String author;
    private String content;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
}
```

### 2. 创建 XML 映射文件

创建将 Java 类映射到数据库表的 XML 文件。将此文件放在资源目录中，路径与模型类的包结构相匹配：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mapping>
    <class name="custom.objects.Book" table="books">
        <property name="id" column="id" type="int" identifier="true"/>
        <property name="name" column="name" type="string"/>
        <property name="author" column="author" type="string"/>
        <property name="content" column="content" type="string"/>
    </class>
</mapping>
```

### 3. 使用映射对象

```java
@Action("books")
public String getBooks(Request request, Response response) {
    try {
        // 创建新的 Book 实例
        Book book = new Book();

        // 查找所有书籍
        List<Book> books = book.findAll();

        // 设置内容类型为 JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // 创建 JSON 响应
        Builder builder = new Builder();
        builder.put("books", books);

        return builder.toString();
    } catch (Exception e) {
        // 处理错误
        response.setStatus(ResponseStatus.INTERNAL_SERVER_ERROR);

        Builder builder = new Builder();
        builder.put("error", e.getMessage());

        return builder.toString();
    }
}

@Action("books")
public String getBook(Integer id, Request request, Response response) {
    try {
        // 创建新的 Book 实例
        Book book = new Book();

        // 设置要搜索的 ID
        book.setId(id);

        // 根据 ID 查找书籍
        book.find();

        // 设置内容类型为 JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // 创建 JSON 响应
        Builder builder = new Builder();
        builder.put("book", book);

        return builder.toString();
    } catch (Exception e) {
        // 处理错误
        response.setStatus(ResponseStatus.INTERNAL_SERVER_ERROR);

        Builder builder = new Builder();
        builder.put("error", e.getMessage());

        return builder.toString();
    }
}
```

### 4. CRUD 操作

```java
// 创建新书籍
Book newBook = new Book();
newBook.setName("了不起的盖茨比");
newBook.setAuthor("F. 司科特·菲兹杰拉德");
newBook.setContent("在我年轻和更容易受伤的岁月里...");
newBook.save(); // 插入数据库

// 根据 ID 查找书籍
Book book = new Book();
book.setId(1);
book.find();

// 更新书籍
book.setName("更新的标题");
book.update();

// 删除书籍
book.remove();

// 查找所有书籍
List<Book> allBooks = book.findAll();

// 条件查找书籍
List<Book> books = book.findWhere("author = ?", "F. 司科特·菲兹杰拉德");
```

## 最佳实践

1. **连接管理**：完成后始终关闭数据库连接。

2. **参数化查询**：使用参数化查询防止 SQL 注入。

3. **事务**：对需要原子性的操作使用事务。

4. **错误处理**：为数据库操作实现适当的错误处理。

5. **连接池**：为应用程序需求配置适当的连接池设置。

6. **对象映射**：在处理数据库实体时，使用对象映射方法可以获得更清晰、更易维护的代码。

7. **XML 映射文件**：将 XML 映射文件组织在与 Java 包结构相匹配的目录结构中。

## 下一步

- 了解[高级特性](advanced-features.md)
- 探索[最佳实践](best-practices.md)
- 查看[数据库 API 参考](api/database.md)
