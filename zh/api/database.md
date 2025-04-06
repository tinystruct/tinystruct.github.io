# 数据库 API 参考

## Repository 接口

`Repository` 接口提供了执行数据库操作的方法。

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

`DatabaseOperator` 类提供了一种方便的方式来执行数据库操作。

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

`AbstractData` 类为对象关系映射提供了一个基类。

### 类定义

```java
public abstract class AbstractData {
    // CRUD 操作
    public void append() throws ApplicationException;
    public void update() throws ApplicationException;
    public void delete() throws ApplicationException;
    public void save() throws ApplicationException;
    
    // 查询操作
    public void findOneById() throws ApplicationException;
    public <T extends AbstractData> List<T> findAll() throws ApplicationException;
    public <T extends AbstractData> List<T> findWhere(String condition, Object... parameters) throws ApplicationException;
    public <T extends AbstractData> T findOne(String condition, Object... parameters) throws ApplicationException;
    
    // 计数操作
    public long count() throws ApplicationException;
    public long countWhere(String condition, Object... parameters) throws ApplicationException;
    
    // 实用方法
    public String getTableName();
    public String getIdentifierName();
    public Object getIdentifierValue();
    public void setIdentifierValue(Object value);
}
```

## Row 接口

`Row` 接口提供了从查询结果访问数据的方法。

### 接口定义

```java
public interface Row {
    // 获取方法
    String getString(String columnName);
    int getInt(String columnName);
    long getLong(String columnName);
    double getDouble(String columnName);
    boolean getBoolean(String columnName);
    Date getDate(String columnName);
    Time getTime(String columnName);
    Timestamp getTimestamp(String columnName);
    Object getObject(String columnName);
    
    // 检查方法
    boolean isNull(String columnName);
    boolean hasColumn(String columnName);
    
    // 列信息
    Set<String> getColumnNames();
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

### 基本查询

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    ResultSet results = operator.query("SELECT * FROM users WHERE id = 1");
    
    if (results.next()) {
        String name = results.getString("name");
        String email = results.getString("email");
        System.out.println("用户: " + name + " (" + email + ")");
    }
}
```

### 参数化查询

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    PreparedStatement stmt = operator.preparedStatement(
        "SELECT * FROM users WHERE email = ?", 
        new Object[]{"zhangsan@example.com"}
    );
    
    ResultSet results = operator.executeQuery(stmt);
    
    while (results.next()) {
        int id = results.getInt("id");
        String name = results.getString("name");
        System.out.println("用户 ID: " + id + ", 姓名: " + name);
    }
}
```

### 事务

```java
try (DatabaseOperator operator = new DatabaseOperator()) {
    operator.beginTransaction();
    
    try {
        operator.update("UPDATE accounts SET balance = balance - 100 WHERE id = 1");
        operator.update("UPDATE accounts SET balance = balance + 100 WHERE id = 2");
        
        operator.commitTransaction();
    } catch (Exception e) {
        operator.rollbackTransaction();
        throw e;
    }
}
```

### 对象关系映射

```java
// 定义模型类
public class User extends AbstractData {
    private int id;
    private String name;
    private String email;
    
    // Getters 和 setters
    // ...
}

// 创建新用户
User user = new User();
user.setName("张三");
user.setEmail("zhangsan@example.com");
user.append();

// 通过 ID 查找用户
User foundUser = new User();
foundUser.setId(1);
foundUser.findOneById();

// 更新用户
foundUser.setName("李四");
foundUser.update();

// 删除用户
foundUser.delete();

// 查找所有用户
List<User> allUsers = new User().findAll();

// 使用条件查找用户
List<User> filteredUsers = new User().findWhere("name LIKE ?", "%张%");
```

## 最佳实践

1. **资源管理**：始终使用 try-with-resources 确保正确关闭数据库资源。

2. **参数化查询**：使用参数化查询防止 SQL 注入。

3. **事务**：对需要原子性的操作使用事务。

4. **错误处理**：为数据库操作实现适当的错误处理。

5. **连接池**：为应用程序需求配置适当的连接池设置。

## 相关 API

- [配置 API](configuration.md)
- [应用程序 API](application.md)
