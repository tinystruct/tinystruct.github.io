# Tinystruct 数据库集成

本指南以 [bible-online](https://github.com/m0ver/bible-online) 项目为参考，介绍如何在 Tinystruct 应用程序中集成和使用数据库。

## 支持的数据库

Tinystruct 内置支持以下数据库系统：

- SQLite
- MySQL
- PostgreSQL
- H2
- Microsoft SQL Server
- Redis

## 配置

### 数据库属性

在 `application.properties` 中配置数据库连接：

```properties
# SQLite 配置（bible-online 实际使用）
driver=org.sqlite.JDBC
database.url=jdbc:sqlite:src/main/resources/bible.db
database.user=
database.password=
database.connections.max=1

# MySQL 配置
# driver=com.mysql.cj.jdbc.Driver
# database.url=jdbc:mysql://localhost:3306/mydb?useSSL=false&serverTimezone=UTC
# database.user=root
# database.password=password
# database.connections.max=10

# H2 配置
# driver=org.h2.Driver
# database.url=jdbc:h2:~/test
# database.user=sa
# database.password=
# database.connections.max=10
```

> **提示：** 嵌入式 SQLite 使用 `database.connections.max=1` 即可；MySQL 等共享服务器建议设置为 `10` 或更高。

也可通过配置节头定义命名数据库配置：

```properties
[database]
driver=com.mysql.cj.jdbc.Driver
database.url=jdbc:mysql://localhost:3306/mydb
database.user=root
database.password=secret
database.connections.max=10
```

---

## 数据库访问方式

Tinystruct 提供两种互补的数据库访问方式：

1. **对象映射（`AbstractData`）** - 推荐方式。定义模型类和 XML 映射文件，调用内置 CRUD 方法。
2. **`DatabaseOperator`** - 底层工具，适用于原始 SQL、聚合查询或跨表操作。

---

## 对象映射方式

这是在 Tinystruct 中操作数据库实体的**推荐方式**。将 Java POJO 与 XML 映射文件结合，提供透明的 CRUD 操作。

### 1. 定义模型类

模型类继承 `AbstractData`，并在每个 setter 中使用 `setFieldAs*` 辅助方法。这些方法负责将字段注册到 ORM，使 `append()`、`update()` 和 `delete()` 知道哪些字段需要持久化。

```java
package custom.objects;

import java.util.Date;
import org.tinystruct.data.component.AbstractData;
import org.tinystruct.data.component.Row;

public class User extends AbstractData {
    private String email;
    private String username;
    private String password;
    private String nickname;
    private int gender;
    private String firstName;
    private String lastName;
    private String country;
    private String city;
    private Date lastloginTime;
    private Date registrationTime;
    private boolean status;

    // 返回自动生成的 UUID 字符串
    public String getId() {
        return String.valueOf(this.Id);
    }

    // setter 必须调用 setFieldAs* 将值注册到 ORM
    public void setEmail(String email) {
        this.email = this.setFieldAsString("email", email);
    }
    public String getEmail() { return this.email; }

    public void setUsername(String username) {
        this.username = this.setFieldAsString("username", username);
    }
    public String getUsername() { return this.username; }

    public void setPassword(String password) {
        this.password = this.setFieldAsString("password", password);
    }
    public String getPassword() { return this.password; }

    public void setNickname(String nickname) {
        this.nickname = this.setFieldAsString("nickname", nickname);
    }
    public String getNickname() { return this.nickname; }

    public void setGender(int gender) {
        this.gender = this.setFieldAsInt("gender", gender);
    }
    public int getGender() { return this.gender; }

    public void setFirstName(String firstName) {
        this.firstName = this.setFieldAsString("firstName", firstName);
    }
    public String getFirstName() { return this.firstName; }

    public void setLastName(String lastName) {
        this.lastName = this.setFieldAsString("lastName", lastName);
    }
    public String getLastName() { return this.lastName; }

    public void setCountry(String country) {
        this.country = this.setFieldAsString("country", country);
    }
    public String getCountry() { return this.country; }

    public void setCity(String city) {
        this.city = this.setFieldAsString("city", city);
    }
    public String getCity() { return this.city; }

    public void setLastloginTime(Date lastloginTime) {
        this.lastloginTime = this.setFieldAsDate("lastloginTime", lastloginTime);
    }
    public Date getLastloginTime() { return this.lastloginTime; }

    public void setRegistrationTime(Date registrationTime) {
        this.registrationTime = this.setFieldAsDate("registrationTime", registrationTime);
    }
    public Date getRegistrationTime() { return this.registrationTime; }

    public void setStatus(boolean status) {
        this.status = this.setFieldAsBoolean("status", status);
    }
    public boolean getStatus() { return this.status; }

    // setData() 将数据库列名（snake_case）映射到 Java 字段
    @Override
    public void setData(Row row) {
        if (row.getFieldInfo("id") != null)
            this.setId(row.getFieldInfo("id").stringValue());
        if (row.getFieldInfo("email") != null)
            this.setEmail(row.getFieldInfo("email").stringValue());
        if (row.getFieldInfo("username") != null)
            this.setUsername(row.getFieldInfo("username").stringValue());
        if (row.getFieldInfo("password") != null)
            this.setPassword(row.getFieldInfo("password").stringValue());
        if (row.getFieldInfo("nickname") != null)
            this.setNickname(row.getFieldInfo("nickname").stringValue());
        if (row.getFieldInfo("gender") != null)
            this.setGender(row.getFieldInfo("gender").intValue());
        if (row.getFieldInfo("first_name") != null)
            this.setFirstName(row.getFieldInfo("first_name").stringValue());
        if (row.getFieldInfo("last_name") != null)
            this.setLastName(row.getFieldInfo("last_name").stringValue());
        if (row.getFieldInfo("country") != null)
            this.setCountry(row.getFieldInfo("country").stringValue());
        if (row.getFieldInfo("city") != null)
            this.setCity(row.getFieldInfo("city").stringValue());
        if (row.getFieldInfo("lastlogin_time") != null)
            this.setLastloginTime(row.getFieldInfo("lastlogin_time").dateValue());
        if (row.getFieldInfo("registration_time") != null)
            this.setRegistrationTime(row.getFieldInfo("registration_time").dateValue());
        if (row.getFieldInfo("status") != null)
            this.setStatus(row.getFieldInfo("status").booleanValue());
    }

    @Override
    public String toString() {
        StringBuffer buffer = new StringBuffer();
        buffer.append("{");
        buffer.append("\"Id\":\"" + this.getId() + "\"");
        buffer.append(",\"email\":\"" + this.getEmail() + "\"");
        buffer.append(",\"username\":\"" + this.getUsername() + "\"");
        buffer.append(",\"nickname\":\"" + this.getNickname() + "\"");
        buffer.append(",\"gender\":" + this.getGender());
        buffer.append(",\"firstName\":\"" + this.getFirstName() + "\"");
        buffer.append(",\"lastName\":\"" + this.getLastName() + "\"");
        buffer.append(",\"country\":\"" + this.getCountry() + "\"");
        buffer.append(",\"city\":\"" + this.getCity() + "\"");
        buffer.append(",\"lastloginTime\":\"" + this.getLastloginTime() + "\"");
        buffer.append(",\"registrationTime\":\"" + this.getRegistrationTime() + "\"");
        buffer.append(",\"status\":" + this.getStatus());
        buffer.append("}");
        return buffer.toString();
    }
}
```

#### 可用的 `setFieldAs*` 方法

| 方法 | Java 类型 | XML `type` |
|---|---|---|
| `setFieldAsString(name, value)` | `String` | `varchar`、`longtext` |
| `setFieldAsInt(name, value)` | `int` | `int` |
| `setFieldAsDate(name, value)` | `java.util.Date` | `datetime` |
| `setFieldAsBoolean(name, value)` | `boolean` | `bit` |
| `setFieldAsLocalDateTime(name, value)` | `LocalDateTime` | `DATETIME` |

### 2. 创建 XML 映射文件

将映射文件放在 `src/main/resources` 下，路径与 Java 包路径一致。例如 `custom.objects.User` 类对应：

```
src/main/resources/custom/objects/User.map.xml
```

```xml
<?xml version="1.0" encoding="UTF-8"?>

<mapping>
 <class name="User" table="User">
  <id name="Id" column="id" increment="false" generate="true" length="50" type="varchar"/>
  <property name="email"            column="email"             length="50"  type="varchar"/>
  <property name="username"         column="username"          length="50"  type="varchar"/>
  <property name="password"         column="password"          length="15"  type="varchar"/>
  <property name="nickname"         column="nickname"          length="50"  type="varchar"/>
  <property name="gender"           column="gender"            length="4"   type="int"/>
  <property name="firstName"        column="first_name"        length="10"  type="varchar"/>
  <property name="lastName"         column="last_name"         length="10"  type="varchar"/>
  <property name="country"          column="country"           length="50"  type="varchar"/>
  <property name="city"             column="city"              length="50"  type="varchar"/>
  <property name="lastloginTime"    column="lastlogin_time"    length="0"   type="datetime"/>
  <property name="registrationTime" column="registration_time" length="0"   type="datetime"/>
  <property name="status"           column="status"            length="1"   type="bit"/>
 </class>
</mapping>
```

#### XML 映射关键属性

| 属性 | 含义 |
|---|---|
| `<class>` 的 `name` | 简单类名（无包前缀） |
| `table` | 数据库表名 |
| `<property>` 的 `name` | Java 属性名（camelCase） |
| `column` | 数据库列名（通常为 snake_case） |
| `type` | SQL 列类型（`varchar`、`int`、`datetime`、`bit`、`longtext` 等） |
| `length` | 列长度；`datetime`、`longtext` 等可变长类型填 `0` |
| `<id>` 的 `increment="false"` | ID 不是数值型自增 |
| `<id>` 的 `generate="true"` | 调用 `append()` 时框架自动生成 UUID |

> **UUID 主键**：bible-online 所有实体均使用 `generate="true"` + `type="varchar"` 作为主键。调用 `append()` 前无需手动设置 ID - 框架自动生成 UUID，之后可通过 `getId()` 读取。

以下是项目中更简单的映射示例：

**`bible.map.xml`**（经文表）：
```xml
<?xml version="1.0" encoding="UTF-8"?>

<mapping>
 <class name="bible" table="bible">
  <id name="Id" column="id" increment="false" generate="true" length="48" type="varchar"/>
  <property name="bookId"    column="book_id"    length="4" type="int"/>
  <property name="chapterId" column="chapter_id" length="4" type="int"/>
  <property name="partId"    column="part_id"    length="4" type="int"/>
  <property name="content"   column="content"    length="0" type="longtext"/>
 </class>
</mapping>
```

**`book.map.xml`**：
```xml
<?xml version="1.0" encoding="UTF-8"?>

<mapping>
 <class name="book" table="book">
  <id name="Id" column="id" increment="false" generate="true" length="50" type="varchar"/>
  <property name="bookId"   column="book_id"   length="4"   type="int"/>
  <property name="bookName" column="book_name" length="255" type="varchar"/>
  <property name="language" column="language"  length="10"  type="varchar"/>
 </class>
</mapping>
```

### 3. CRUD 操作

#### 新增 - `append()`

```java
// 注册新用户，UUID 自动生成
User user = new User();
user.setNickname(request.getParameter("nickname"));
user.setEmail(request.getParameter("email"));
user.setPassword(new Security(user.getEmail())
        .encodePassword(request.getParameter("password")));
user.setFirstName(request.getParameter("first-name"));
user.setLastName(request.getParameter("last-name"));
user.setGender(Integer.parseInt(request.getParameter("gender")));
user.setCountry(request.getParameter("country"));
user.setCity(request.getParameter("city"));
user.setLastloginTime(new Date());
user.setRegistrationTime(new Date());
user.append();  // INSERT；user.getId() 返回新生成的 UUID
```

#### 查询 - `findOneById()`

```java
User user = new User();
user.setId(someId);   // 传入 UUID 字符串
user.findOneById();   // SELECT ... WHERE id = ?
System.out.println(user.getEmail());
```

#### 条件查询 - `findWith()`

`findWith` 是 Tinystruct 的主要查询方法。接受参数化的 WHERE/ORDER BY 子句和值数组，返回 `Table`（`Row` 对象的列表）。

```java
// 按用户名查找
User u = new User();
Table list = u.findWith("WHERE username=? AND status='1'",
        new Object[]{"james"});

if (list.size() > 0) {
    u.setData(list.get(0));  // 用第一行数据填充对象
}
```

```java
// 按语言查找书目
book b = new book();
Table table = b.findWith("WHERE book_id=? AND language=?",
        new Object[]{bookId, "zh_CN"});

if (!table.isEmpty()) {
    b.setData(table.get(0));
}
```

#### 查询全部 - `findAll()`

```java
book b = new book();
Table list = b.findAll();

Iterator<Row> iter = list.iterator();
while (iter.hasNext()) {
    b.setData(iter.next());
    System.out.println(b.getBookName() + " (" + b.getLanguage() + ")");
}
```

#### 聚合查询 - `setRequestFields()`

调用 `findWith()` 前使用 `setRequestFields()` 覆盖 SELECT 投影。bible-online 通过此方式检查邮箱是否重复及获取最大章节数：

```java
// 注册前检查邮箱是否已存在
int count = user
    .setRequestFields("count(*) as p")
    .findWith("WHERE email=?", new Object[]{email})
    .get(0).getFieldInfo("p").intValue();

if (count > 0) {
    throw new ApplicationException("邮箱已被注册。");
}
```

```java
// 获取某书的最大章节编号
bible bible = new bible();
int maxChapter = bible
    .setRequestFields("max(chapter_id) as max_chapter")
    .findWith("WHERE book_id=?", new Object[]{bookId})
    .get(0).get(0).get("max_chapter").intValue();
```

#### 动态切换表 - `setTableName()`

当同一模型类对应多张结构相同的表（如不同版本的圣经译文表），在运行时调用 `setTableName()` 切换目标表：

```java
bible bible = new bible();
bible.setTableName("zh_CN");   // 默认：简体中文

if (request.getParameter("version") != null) {
    switch (request.getParameter("version")) {
        case "NIV": bible.setTableName("NIV"); break;
        case "ESV": bible.setTableName("ESV"); break;
        case "KJV": bible.setTableName("KJV"); break;
    }
}

// 查询所选版本的经文
Table verses = bible
    .setRequestFields("*")
    .findWith("WHERE book_id=? AND chapter_id=? ORDER BY part_id",
              new Object[]{bookId, chapterId});
```

此模式使您可以维护多张独立译文表（`NIV`、`ESV`、`KJV`、`zh_CN`、`zh_TW` 等），同时共用一个模型类和映射文件。

#### 更新 - `update()`

```java
// 登录成功后更新登录时间
user.setLastloginTime(new Date());
user.update();   // UPDATE ... WHERE id = ?
```

#### 删除 - `delete()`

```java
user.delete();   // DELETE FROM ... WHERE id = ?
```

#### 存在则更新、不存在则新增模式

bible-online 中常见的做法是先查询记录是否存在，再决定插入还是更新：

```java
// 更新或新增登录日志
Log log = new Log();
Table logs = log.findWith("WHERE user_id=?",
        new Object[]{currentUser.getId()});

if (!logs.isEmpty()) {
    log.setData(logs.get(0));
    log.setDate(new Date());
    log.update();              // 记录存在，更新它
} else {
    log.setUserId(currentUser.getId());
    log.setAction("登录成功");
    log.setActionType(0);
    log.setDate(new Date());
    log.append();              // 尚无记录，插入它
}
```

### 4. `Table` 与 `Row` API

`findWith()` 和 `findAll()` 返回 `Table`（`Row` 对象的有序列表）。`Row` 是列名到 `Field` 值的映射。

```java
Table table = bible.findWith(
    "WHERE book_id=? AND chapter_id=? ORDER BY part_id",
    new Object[]{bookId, chapterId});

for (int i = 0; i < table.size(); i++) {
    Row row = table.get(i);
    bible.setData(row);            // 用该行数据填充模型
    System.out.println(bible.getContent());
}
```

也可以直接从 `Row` 读取 `Field` 值，无需填充模型对象：

```java
Row row = table.get(0);
int     maxChapter = row.getFieldInfo("max_chapter").intValue();
String  email      = row.getFieldInfo("email").stringValue();
Date    created    = row.getFieldInfo("registration_time").dateValue();
boolean active     = row.getFieldInfo("status").booleanValue();
```

### 5. 多实体协作示例（用户注册）

以下示例来自 bible-online 的 `register` 应用，展示多个 `AbstractData` 对象如何在同一流程中协作：

```java
public boolean append(Request request) throws ApplicationException {
    // 1. 根据请求参数构建 User 对象
    User user = new User();
    user.setNickname(request.getParameter("nickname"));
    user.setEmail(request.getParameter("email"));
    user.setPassword(new Security(user.getEmail())
            .encodePassword(request.getParameter("password")));
    user.setFirstName(request.getParameter("first-name"));
    user.setLastName(request.getParameter("last-name"));
    user.setGender(Integer.parseInt(request.getParameter("gender")));
    user.setCountry(request.getParameter("country"));
    user.setCity(request.getParameter("city"));
    user.setLastloginTime(new Date());
    user.setRegistrationTime(new Date());

    // 2. 防止重复注册
    int count = user
        .setRequestFields("count(*) as p")
        .findWith("WHERE email=?", new Object[]{user.getEmail()})
        .get(0).getFieldInfo("p").intValue();

    if (count > 0) {
        throw new ApplicationException("邮箱已被注册。");
    }

    // 3. 插入用户记录（UUID 自动生成）
    user.append();

    // 4. 将新用户加入默认成员组
    Member member = new Member();
    member.setUserId(user.getId());  // user.getId() 返回新生成的 UUID
    member.setGroupId("386e27c2-5db6-4f63-b28d-68a4adec2fd6");
    member.append();

    return true;
}
```

---

## 内存缓存 - `Cache`

对于读频率高、变化较少的数据（如书目元数据、章节数量），bible-online 使用 Tinystruct 内置的 `Cache` 单例避免重复查询数据库：

```java
private static final Cache data = Cache.getInstance();

// 优先从缓存读取
String cacheKey = "book:" + bookId + ":lang:" + lang;
book book;

if (data.get(cacheKey) != null) {
    book = (book) data.get(cacheKey);
} else {
    book = new book();
    Table table = book.findWith("WHERE book_id=? AND language=?",
            new Object[]{bookId, lang});
    if (!table.isEmpty()) {
        book.setData(table.get(0));
    }
    data.set(cacheKey, book);  // 写入缓存供后续请求使用
}
```

聚合结果同样适用此模式：

```java
String maxChapterKey = "book:" + bookId + ":max_chapter";
int maxChapter;

if (data.get(maxChapterKey) != null) {
    maxChapter = (int) data.get(maxChapterKey);
} else {
    maxChapter = bible
        .setRequestFields("max(chapter_id) as max_chapter")
        .findWith("WHERE book_id=?", new Object[]{bookId})
        .get(0).get(0).get("max_chapter").intValue();
    data.set(maxChapterKey, maxChapter);
}
```

适合使用 `Cache` 的数据特征：
- 读取非常频繁
- 在进程生命周期内基本不变
- 数据量小，适合放在堆内存中

---

## DatabaseOperator

对于原始 SQL、多表连接，或对象映射 API 无法覆盖的操作，使用 `DatabaseOperator`。

### 创建 DatabaseOperator

```java
// 默认 - 从连接池借用一个连接
DatabaseOperator operator = new DatabaseOperator();

// 命名配置（对应 application.properties 中的 [节] 名）
DatabaseOperator operator = new DatabaseOperator("myDatabase");

// 使用现有连接
DatabaseOperator operator = new DatabaseOperator(connection);
```

### 执行查询

```java
// 参数化查询（始终优于字符串拼接）
PreparedStatement stmt = operator.preparedStatement(
    "SELECT id, username, email FROM User WHERE id = ?",
    new Object[]{userId}
);
ResultSet results = operator.executeQuery(stmt);

while (results.next()) {
    String email = results.getString("email");
}
```

### 执行更新

```java
PreparedStatement stmt = operator.preparedStatement(
    "INSERT INTO User (username, email) VALUES (?, ?)",
    new Object[]{"james", "james@example.com"}
);
int rowsAffected = operator.executeUpdate(stmt);
```

### 资源管理

使用 try-with-resources 确保连接归还连接池：

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM User");
    // 处理结果
} // 自动关闭 ResultSet、PreparedStatement 并释放连接
```

### SQL 注入保护

`DatabaseOperator` 默认检测 SQL 注入。仅在可信内部工具中禁用：

```java
operator.disableSafeCheck();
```

### 事务

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    operator.beginTransaction();
    try {
        PreparedStatement s1 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance - ? WHERE id = ?",
            new Object[]{amount, fromId}
        );
        operator.executeUpdate(s1);

        PreparedStatement s2 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance + ? WHERE id = ?",
            new Object[]{amount, toId}
        );
        operator.executeUpdate(s2);

        operator.commitTransaction();
    } catch (Exception e) {
        operator.rollbackTransaction();
        throw e;
    }
}
```

#### 事务方法

| 方法 | 说明 |
|---|---|
| `beginTransaction()` | 开始新事务 |
| `commitTransaction()` | 提交当前事务 |
| `rollbackTransaction()` | 回滚整个事务 |
| `rollbackTransaction(Savepoint)` | 回滚到指定保存点 |
| `createSavepoint(String)` | 创建命名保存点 |
| `releaseSavepoint(Savepoint)` | 释放保存点 |
| `isInTransaction()` | 返回事务是否处于活动状态 |

> 若 `DatabaseOperator` 在事务未提交或回滚的情况下被关闭，事务将**自动回滚**以保护数据完整性。

---

## 内置 POJO 生成器

Tinystruct 内置代码生成器，可直接从数据库模式生成模型类和 XML 映射文件。支持 **MySQL**、**MSSQL**、**SQLite** 和 **H2**。

### 运行生成器

```bash
# 交互模式 - 提示输入表名和输出路径
bin/dispatcher generate

# 非交互模式 - 指定单张表
bin/dispatcher generate --tables users

# 多张表（分号分隔）
bin/dispatcher generate --tables "users;orders;products"
```

### 自动类型映射

| SQL 列类型 | Java 类型 | `setFieldAs*` 方法 |
|---|---|---|
| `VARCHAR`、`CHAR`、`TEXT` | `String` | `setFieldAsString` |
| `INT`、`SMALLINT`、`TINYINT` | `int` | `setFieldAsInt` |
| `BIGINT` | `long` | *（原始字段）* |
| `FLOAT` | `float` | *（原始字段）* |
| `DOUBLE` | `double` | *（原始字段）* |
| `DATETIME`、`TIMESTAMP` | `LocalDateTime` | `setFieldAsLocalDateTime` |
| `DATE` | `java.util.Date` | `setFieldAsDate` |
| `BIT`、`BOOLEAN` | `boolean` | `setFieldAsBoolean` |
| `BLOB`、`BINARY`、`VARBINARY` | `byte[]` | *（原始字段）* |

每张表生成两个文件：

1. **Java POJO** - 例如 `src/main/java/custom/objects/User.java`
2. **XML 映射** - 例如 `src/main/resources/custom/objects/User.map.xml`

---

## 最佳实践

1. **setter 中必须调用 `setFieldAs*`。** 若未调用，ORM 不知道该字段需要持久化，`append()` / `update()` 将静默跳过该字段。

2. **`setData()` 中使用数据库列名。** `row.getFieldInfo()` 的键必须是实际数据库列名（snake_case），而非 Java 属性名。

3. **始终使用参数化查询。** 通过 `findWith()` 或 `preparedStatement()` 的 `Object[]` 参数传递值，绝不将用户输入拼接进 SQL 字符串。

4. **缓存稳定的参考数据。** 使用 `Cache.getInstance()` 缓存跨请求基本不变的数据（如书目列表、章节数量、语言元数据）。

5. **使用 `setTableName()` 处理版本化表。** 当一个模型对应多张结构相同的表（如圣经各译文版本），通过 `setTableName()` 在运行时切换。

6. **使用 `setRequestFields()` 进行聚合查询。** 在调用 `findWith()` 前覆盖 SELECT 投影（如 `"count(*) as n"`、`"max(chapter_id) as max_chapter"`）。

7. **UUID 自动生成。** XML 映射中设置 `generate="true"` 后，`append()` 会自动写入 UUID 并可通过 `getId()` 立即读取，无需手动设置主键。

8. **用 try-with-resources 包裹 `DatabaseOperator`。** 即使抛出异常，也能确保连接归还连接池。

9. **映射文件路径须与 Java 包路径一致。** `custom.objects.User` 类对应的映射文件路径为类路径根目录下的 `custom/objects/User.map.xml`。

---

## 下一步

- 了解[高级特性](advanced-features.md)
- 探索[最佳实践](best-practices.md)
- 查看[数据库 API 参考](api/database.md)
