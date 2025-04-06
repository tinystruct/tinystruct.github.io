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

`DatabaseOperator` 类提供了一种方便的方式来执行数据库操作，而无需直接管理 Repository 实例。它自动处理连接管理、语句准备和资源清理。

### 创建 DatabaseOperator

```java
// 默认构造函数 - 从 ConnectionManager 获取连接
DatabaseOperator operator = new DatabaseOperator();

// 使用特定数据库
DatabaseOperator operator = new DatabaseOperator("myDatabase");

// 使用现有连接
Connection connection = getConnection();
DatabaseOperator operator = new DatabaseOperator(connection);
```

### 执行查询

```java
// 无参数的简单查询
ResultSet results = operator.query("SELECT * FROM users");

// 带参数的查询（使用预处理语句）
PreparedStatement stmt = operator.preparedStatement("SELECT * FROM users WHERE id = ?", new Object[]{1});
ResultSet results = operator.executeQuery(stmt);

// 处理结果
while (results.next()) {
    int id = results.getInt("id");
    String name = results.getString("name");
    // 处理行数据
}
```

### 执行更新

```java
// 无参数的简单更新
int rowsAffected = operator.update("UPDATE users SET status = 'active'");

// 带参数的更新
PreparedStatement stmt = operator.preparedStatement(
    "UPDATE users SET name = ? WHERE id = ?",
    new Object[]{"张三", 1}
);
int rowsAffected = operator.executeUpdate(stmt);

// 执行可能是查询或更新的语句
boolean isResultSet = operator.execute("CALL some_procedure()");
```

### 资源管理

```java
// 使用 try-with-resources 自动清理
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM users");
    // 处理结果
} // 自动关闭 ResultSet、PreparedStatement，并将 Connection 返回到连接池
```

### SQL 注入保护

DatabaseOperator 包含内置的 SQL 注入检测：

```java
// 默认启用 SQL 注入检查
DatabaseOperator operator = new DatabaseOperator();

// 禁用 SQL 注入检查（例如，用于 CLI 工具）
operator.disableSafeCheck();
```

## 仓库 API

Tinystruct 还使用仓库模式进行直接数据库操作。Repository 接口提供了执行查询和更新的方法。

### 创建仓库

```java
// 创建 MySQL 仓库
Repository repository = Type.MySQL.createRepository();

// 创建 H2 仓库
Repository repository = Type.H2.createRepository();

// 创建 SQLite 仓库
Repository repository = Type.SQLite.createRepository();
```

### 执行查询

```java
@Action("users")
public String getUser(Integer id, Request request, Response response) {
    try {
        // 创建 DatabaseOperator 实例
        DatabaseOperator operator = new DatabaseOperator();

        // 执行带参数的查询
        ResultSet results = operator.query("SELECT id, name, email FROM users WHERE id = " + id);

        // 设置内容类型为 JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        if (!results.next()) {
            // 创建错误响应
            Builder builder = new Builder();
            builder.put("error", "未找到用户");
            return builder.toString();
        }

        // 创建成功响应
        Builder builder = new Builder();
        builder.put("id", results.getInt("id"));
        builder.put("name", results.getString("name"));
        builder.put("email", results.getString("email"));

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
public String createUser(Request request, Response response) {
    try {
        String name = request.getParameter("name");
        String email = request.getParameter("email");

        if (name == null || email == null) {
            response.headers().add(Header.CONTENT_TYPE.set("application/json"));
            Builder builder = new Builder();
            builder.put("error", "名称和电子邮件是必需的");
            return builder.toString();
        }

        // 创建 DatabaseOperator 实例
        DatabaseOperator operator = new DatabaseOperator();

        // 执行带参数的更新
        PreparedStatement stmt = operator.preparedStatement(
            "INSERT INTO users (name, email) VALUES (?, ?)",
            new Object[]{name, email}
        );
        int result = operator.executeUpdate(stmt);

        // 设置内容类型为 JSON
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));

        // 创建成功响应
        Builder builder = new Builder();
        builder.put("success", true);
        builder.put("rowsAffected", result);

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

### 事务

Tinystruct 通过 `DatabaseOperator` 类提供全面的事务支持。

#### 基本事务用法

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    // 开始事务
    operator.beginTransaction();

    try {
        // 执行数据库操作
        PreparedStatement stmt1 = operator.preparedStatement(
            "INSERT INTO users (name) VALUES (?)",
            new Object[]{"张三"}
        );
        operator.executeUpdate(stmt1);

        PreparedStatement stmt2 = operator.preparedStatement(
            "UPDATE settings SET value = ? WHERE name = ?",
            new Object[]{"新值", "setting_name"}
        );
        operator.executeUpdate(stmt2);

        // 如果所有操作都成功，则提交事务
        operator.commitTransaction();

    } catch (Exception e) {
        // 如果任何操作失败，则回滚事务
        operator.rollbackTransaction();
        throw e;
    }
}
```

#### 示例：使用事务进行资金转账

```java
@Action("transfer")
public String transferFunds(Request request, Response response) {
    int fromAccount = Integer.parseInt(request.getParameter("from"));
    int toAccount = Integer.parseInt(request.getParameter("to"));
    double amount = Double.parseDouble(request.getParameter("amount"));

    try (DatabaseOperator operator = new DatabaseOperator()) {
        // 开始事务
        operator.beginTransaction();

        try {
            // 从源账户扣除
            PreparedStatement stmt1 = operator.preparedStatement(
                "UPDATE accounts SET balance = balance - ? WHERE id = ? AND balance >= ?",
                new Object[]{amount, fromAccount, amount}
            );
            int result1 = operator.executeUpdate(stmt1);

            if (result1 == 0) {
                operator.rollbackTransaction();

                response.headers().add(Header.CONTENT_TYPE.set("application/json"));
                Builder builder = new Builder();
                builder.put("error", "资金不足");
                return builder.toString();
            }

            // 添加到目标账户
            PreparedStatement stmt2 = operator.preparedStatement(
                "UPDATE accounts SET balance = balance + ? WHERE id = ?",
                new Object[]{amount, toAccount}
            );
            int result2 = operator.executeUpdate(stmt2);

            if (result2 == 0) {
                operator.rollbackTransaction();

                response.headers().add(Header.CONTENT_TYPE.set("application/json"));
                Builder builder = new Builder();
                builder.put("error", "未找到目标账户");
                return builder.toString();
            }

            // 记录交易
            PreparedStatement stmt3 = operator.preparedStatement(
                "INSERT INTO transactions (from_account, to_account, amount, date) VALUES (?, ?, ?, NOW())",
                new Object[]{fromAccount, toAccount, amount}
            );
            operator.executeUpdate(stmt3);

            // 提交事务
            operator.commitTransaction();

            response.headers().add(Header.CONTENT_TYPE.set("application/json"));
            Builder builder = new Builder();
            builder.put("success", true);
            return builder.toString();
        } catch (Exception e) {
            // 出错时回滚
            operator.rollbackTransaction();
            throw e;
        }
    } catch (Exception e) {
        response.headers().add(Header.CONTENT_TYPE.set("application/json"));
        Builder builder = new Builder();
        builder.put("error", e.getMessage());
        return builder.toString();
    }
}
```

#### 使用保存点

保存点允许您在事务中创建点，您可以回滚到这些点，而无需回滚整个事务。

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    // 开始事务
    operator.beginTransaction();

    // 执行第一个操作
    PreparedStatement stmt1 = operator.preparedStatement(
        "INSERT INTO users (name) VALUES (?)",
        new Object[]{"张三"}
    );
    operator.executeUpdate(stmt1);

    // 在第一个操作后创建保存点
    Savepoint savepoint = operator.createSavepoint("AFTER_INSERT");

    try {
        // 执行第二个操作
        PreparedStatement stmt2 = operator.preparedStatement(
            "UPDATE settings SET value = ? WHERE name = ?",
            new Object[]{"新值", "setting_name"}
        );
        operator.executeUpdate(stmt2);
    } catch (Exception e) {
        // 如果第二个操作失败，回滚到保存点
        operator.rollbackTransaction(savepoint);

        // 尝试替代操作
        PreparedStatement altStmt = operator.preparedStatement(
            "INSERT INTO logs (message) VALUES (?)",
            new Object[]{"操作失败"}
        );
        operator.executeUpdate(altStmt);
    }

    // 提交事务
    operator.commitTransaction();
}
```

#### 事务方法

`DatabaseOperator` 类提供以下与事务相关的方法：

- `beginTransaction()`：开始新事务
- `commitTransaction()`：提交当前事务
- `rollbackTransaction()`：回滚整个事务
- `rollbackTransaction(Savepoint)`：回滚到特定保存点
- `createSavepoint(String)`：创建命名保存点
- `releaseSavepoint(Savepoint)`：释放保存点
- `isInTransaction()`：检查事务是否活动

#### 事务最佳实践

1. 始终使用 try-with-resources 确保正确关闭 `DatabaseOperator`
2. 将事务操作包裹在 try-catch 块中
3. 始终显式地提交或回滚事务
4. 对于可能需要部分回滚的复杂操作，使用保存点
5. 保持事务尽可能短，以避免长时间锁定资源
6. 适当处理异常，确保在出错时回滚事务

注意：如果带有活动事务的 `DatabaseOperator` 在未显式提交或回滚事务的情况下关闭，事务将自动回滚以确保数据完整性。

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
newBook.setAuthor("F. 司科特·菲茨杰拉德");
newBook.setContent("在我年轻和更容易受伤的岁月里...");
newBook.append(); // 向数据库插入新记录

// 根据 ID 查找书籍
Book book = new Book();
book.setId(1);
book.findOneById(); // 根据 ID 查找

// 更新书籍
book.setName("更新的标题");
book.update();

// 删除书籍
book.delete(); // 删除记录

// 查找所有书籍
List<Book> allBooks = book.findAll();

// 条件查找书籍
List<Book> books = book.findWhere("author = ?", "F. 司科特·菲茨杰拉德");
```

### 数据操作的重要说明

在 Tinystruct 框架中，不同的数据库操作有不同的方法：

- `append()`：专门用于向数据库插入新记录。
- `update()`：专门用于更新数据库中的现有记录。
- `save()`：此方法根据记录是否存在来决定是插入还是更新。它是一个便利方法，内部会根据需要调用 `append()` 或 `update()`。

为了清晰和精确控制，建议使用 `append()` 进行插入操作，使用 `update()` 进行更新操作，而不是依赖 `save()`。

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
