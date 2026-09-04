# 数据库 API 参考

## Repository 接口

`Repository` 接口提供了执行底层数据库操作的方法。

### 接口定义

```java
public interface Repository {
    // 查询方法
    List<Row> query(String sql, Object... parameters) throws SQLException;
    Row queryOne(String sql, Object... parameters) throws SQLException;
    
    // 更新方法
    int update(String sql, Object... parameters) throws SQLException;
    int[] batchUpdate(String sql, List<Object[]> parametersList) throws SQLException;
    
    // 执行方法
    boolean execute(String sql, Object... parameters) throws SQLException;
    
    // 事务方法
    void begin() throws SQLException;
    void commit() throws SQLException;
    void rollback() throws SQLException;
    
    // 连接管理
    Connection getConnection() throws SQLException;
    void close() throws SQLException;
}
```

## DatabaseOperator

`DatabaseOperator` 类提供了一种方便的方式来执行原始 SQL 数据库操作和管理事务。

### 类定义

```java
public class DatabaseOperator implements AutoCloseable {
    // 构造函数
    public DatabaseOperator();
    public DatabaseOperator(String database);
    public DatabaseOperator(Connection connection);
    
    // 查询方法
    public ResultSet query(String sql) throws SQLException;
    public ResultSet executeQuery(PreparedStatement statement) throws SQLException;
    
    // 更新方法
    public int update(String sql) throws SQLException;
    public int executeUpdate(PreparedStatement statement) throws SQLException;
    
    // 执行方法
    public boolean execute(String sql) throws SQLException;
    public boolean execute(PreparedStatement statement) throws SQLException;
    
    // 预处理语句
    public PreparedStatement preparedStatement(String sql, Object[] parameters) throws SQLException;
    
    // 事务方法
    public Savepoint beginTransaction() throws SQLException;
    public void commitTransaction() throws SQLException;
    public void rollbackTransaction() throws SQLException;
    public void rollbackTransaction(Savepoint savepoint) throws SQLException;
    public Savepoint createSavepoint(String name) throws SQLException;
    public void releaseSavepoint(Savepoint savepoint) throws SQLException;
    public boolean isInTransaction() throws SQLException;
    
    // SQL 注入保护
    public void enableSafeCheck();
    public void disableSafeCheck();
    
    // 资源管理
    public void close() throws SQLException;
}
```

## AbstractData

`AbstractData` 类是 Tinystruct 中对象关系映射 (ORM) 的基础。

### 类定义

```java
public abstract class AbstractData {
    // 字段注册方法（必须在 setter 中调用）
    protected String setFieldAsString(String fieldName, String value);
    protected int setFieldAsInt(String fieldName, int value);
    protected Date setFieldAsDate(String fieldName, Date value);
    protected boolean setFieldAsBoolean(String fieldName, boolean value);
    protected LocalDateTime setFieldAsLocalDateTime(String fieldName, LocalDateTime value);

    // CRUD 操作
    public void append() throws ApplicationException;
    public void update() throws ApplicationException;
    public void delete() throws ApplicationException;
    
    // 查询操作
    public void findOneById() throws ApplicationException;
    public <T extends AbstractData> Table findAll() throws ApplicationException;
    public <T extends AbstractData> Table findWith(String condition, Object[] parameters) throws ApplicationException;
    
    // 聚合与配置
    public AbstractData setRequestFields(String fields);
    public void setTableName(String tableName);
    
    // 标识符管理
    public Object getId();
    public void setId(Object id);
    
    // 数据映射（必须实现）
    public abstract void setData(Row row);
}
```

## Table 和 Row 接口

使用 `AbstractData` 查询会返回一个 `Table`，它作为一个包含结果数据的 `Row` 对象列表。

### 接口定义

```java
public interface Table extends Iterable<Row> {
    int size();
    boolean isEmpty();
    Row get(int index);
    Iterator<Row> iterator();
}

public interface Row extends Iterable<Field> {
    // 获取原始字段信息
    Field getFieldInfo(String columnName);
    
    // 检查方法
    boolean hasColumn(String columnName);
    
    // 列信息
    Set<String> getColumnNames();
}

public interface Field {
    String name();
    Object value();
    
    // 类型化获取方法
    String stringValue();
    int intValue();
    long longValue();
    double doubleValue();
    boolean booleanValue();
    Date dateValue();
    LocalDateTime localDateTimeValue();
}
```

## Type 枚举

`Type` 枚举为不同数据库类型提供了创建仓库的工厂方法。

### 枚举定义

```java
public enum Type {
    MySQL,
    SQLite,
    H2,
    MSSQL,
    PostgreSQL,
    Oracle;
    
    public Repository createRepository();
}
```

## 使用示例

### 基本查询 (`DatabaseOperator`)

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM User LIMIT 1");
    
    if (results.next()) {
        String username = results.getString("username");
        String email = results.getString("email");
        System.out.println("用户: " + username + " (" + email + ")");
    }
}
```

### 参数化查询 (`DatabaseOperator`)

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    PreparedStatement stmt = operator.preparedStatement(
        "SELECT id, username, email FROM User WHERE email = ?", 
        new Object[]{"james@example.com"}
    );
    
    ResultSet results = operator.executeQuery(stmt);
    
    while (results.next()) {
        String id = results.getString("id");
        String name = results.getString("username");
        System.out.println("用户 ID: " + id + ", 用户名: " + name);
    }
}
```

### 事务 (`DatabaseOperator`)

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    operator.beginTransaction();
    
    try {
        PreparedStatement s1 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance - ? WHERE id = ?",
            new Object[]{100.0, "source-uuid"}
        );
        operator.executeUpdate(s1);
        
        PreparedStatement s2 = operator.preparedStatement(
            "UPDATE accounts SET balance = balance + ? WHERE id = ?",
            new Object[]{100.0, "target-uuid"}
        );
        operator.executeUpdate(s2);
        
        operator.commitTransaction();
    } catch (Exception e) {
        operator.rollbackTransaction();
        throw e;
    }
}
```

### 对象关系映射 (`AbstractData`)

```java
// 1. 定义模型类
public class User extends AbstractData {
    private String username;
    private String email;
    
    public String getId() {
        return String.valueOf(this.Id);
    }
    
    // Setter 必须注册字段
    public void setUsername(String username) {
        this.username = this.setFieldAsString("username", username);
    }
    
    public void setEmail(String email) {
        this.email = this.setFieldAsString("email", email);
    }
    
    @Override
    public void setData(Row row) {
        if (row.getFieldInfo("id") != null)
            this.setId(row.getFieldInfo("id").stringValue());
        if (row.getFieldInfo("username") != null)
            this.setUsername(row.getFieldInfo("username").stringValue());
        if (row.getFieldInfo("email") != null)
            this.setEmail(row.getFieldInfo("email").stringValue());
    }
}

// 2. 创建新用户（通过映射自动生成 UUID）
User user = new User();
user.setUsername("james");
user.setEmail("james@example.com");
user.append();
System.out.println("新 ID: " + user.getId());

// 3. 通过 ID 查找用户
User foundUser = new User();
foundUser.setId(user.getId());
foundUser.findOneById();

// 4. 更新用户
foundUser.setUsername("james_updated");
foundUser.update();

// 5. 删除用户
foundUser.delete();

// 6. 查找所有用户
Table allUsersTable = new User().findAll();

// 7. 使用条件查找用户
Table filteredTable = new User().findWith("WHERE username LIKE ?", new Object[]{"%james%"});
if (!filteredTable.isEmpty()) {
    User firstMatch = new User();
    firstMatch.setData(filteredTable.get(0));
}
```

## 最佳实践

1. **资源管理**：使用 `DatabaseOperator` 时始终使用 `try-with-resources`，以确保正确关闭数据库资源和连接池。
2. **字段注册**：扩展 `AbstractData` 时，始终在 setter 中调用适当的 `setFieldAs*` 方法。
3. **参数化查询**：通过 `findWith()` 或 `preparedStatement()` 中的 `Object[]` 参数传递值以防止 SQL 注入。
4. **聚合查询**：在调用 `findWith()` 之前使用 `setRequestFields()` 修改 SELECT 投影。
5. **事务**：对于跨多个表或需要原子性的操作，请使用事务。

## 相关 API

- [配置 API](configuration.md)
- [应用程序 API](application.md)
