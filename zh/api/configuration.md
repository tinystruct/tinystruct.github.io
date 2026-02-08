# 配置 API 参考

## Configuration 接口

`Configuration` 接口提供了访问和管理应用程序配置设置的方法。

### 接口定义

```java
public interface Configuration {
    // 获取方法
    String get(String key);
    String get(String key, String defaultValue);
    int getInt(String key, int defaultValue);
    long getLong(String key, long defaultValue);
    double getDouble(String key, double defaultValue);
    boolean getBoolean(String key, boolean defaultValue);
    
    // 设置方法
    void set(String key, String value);
    void set(String key, int value);
    void set(String key, long value);
    void set(String key, double value);
    void set(String key, boolean value);
    
    // 文件操作
    void load(String filePath) throws IOException;
    void save(String filePath) throws IOException;
    
    // 属性操作
    Set<String> keySet();
    boolean containsKey(String key);
    void remove(String key);
    void clear();
}
```

## DefaultConfiguration

`DefaultConfiguration` 类是 `Configuration` 接口的默认实现。

### 类定义

```java
public class DefaultConfiguration implements Configuration {
    // 构造函数
    public DefaultConfiguration();
    public DefaultConfiguration(String filePath) throws IOException;
    public DefaultConfiguration(Properties properties);
    
    // Configuration 接口方法的实现
    // ...
    
    // 附加方法
    public Properties getProperties();
    public void setProperties(Properties properties);
}
```

## ConfigurationManager

`ConfigurationManager` 类提供了一种集中访问配置设置的方式。

### 类定义

```java
public class ConfigurationManager {
    // 单例访问
    public static ConfigurationManager getInstance();
    
    // 配置管理
    public Configuration getConfiguration();
    public void setConfiguration(Configuration configuration);
    
    // 便捷方法
    public String get(String key);
    public String get(String key, String defaultValue);
    public int getInt(String key, int defaultValue);
    public long getLong(String key, long defaultValue);
    public double getDouble(String key, double defaultValue);
    public boolean getBoolean(String key, boolean defaultValue);
}
```

## 使用示例

### 基本配置

```java
// 创建配置
Configuration config = new DefaultConfiguration();

// 设置值
config.set("application.name", "MyApp");
config.set("application.version", "1.0.0");
config.set("application.debug", true);
config.set("server.port", 8080);

// 获取值
String appName = config.get("application.name");
String version = config.get("application.version");
boolean debug = config.getBoolean("application.debug", false);
int port = config.getInt("server.port", 8080);

System.out.println("应用程序: " + appName + " v" + version);
System.out.println("调试模式: " + debug);
System.out.println("服务器端口: " + port);
```

### 从属性文件加载

```java
try {
    // 从文件加载配置
    Configuration config = new DefaultConfiguration("config.properties");
    
    // 访问配置值
    String dbUrl = config.get("database.url");
    String dbUser = config.get("database.user");
    String dbPassword = config.get("database.password");
    int maxConnections = config.getInt("database.connections.max", 10);
    
    System.out.println("数据库 URL: " + dbUrl);
    System.out.println("数据库用户: " + dbUser);
    System.out.println("最大连接数: " + maxConnections);
} catch (IOException e) {
    System.err.println("加载配置时出错: " + e.getMessage());
}
```

### 使用 ConfigurationManager

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 加载配置
        Configuration config = new DefaultConfiguration();
        try {
            config.load("application.properties");
        } catch (IOException e) {
            System.err.println("加载配置时出错: " + e.getMessage());
        }
        
        // 设置为应用程序配置
        ConfigurationManager.getInstance().setConfiguration(config);
    }
    
    @Action("config")
    public String showConfig() {
        // 通过 ConfigurationManager 访问配置
        ConfigurationManager manager = ConfigurationManager.getInstance();
        
        String appName = manager.get("application.name", "未知");
        String appMode = manager.get("application.mode", "development");
        
        return "应用程序: " + appName + ", 模式: " + appMode;
    }
}
```

### 环境特定配置

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 确定环境
        String env = System.getProperty("app.environment", "development");
        
        // 加载基本配置
        Configuration config = new DefaultConfiguration();
        try {
            // 加载基本配置
            config.load("application.properties");
            
            // 加载环境特定配置
            config.load("application-" + env + ".properties");
            
            System.out.println("已加载环境的配置: " + env);
        } catch (IOException e) {
            System.err.println("加载配置时出错: " + e.getMessage());
        }
        
        // 设置为应用程序配置
        ConfigurationManager.getInstance().setConfiguration(config);
    }
}
```

## 最佳实践

1. **默认值**：获取配置设置时始终提供默认值，以处理缺失的属性。

2. **环境特定配置**：为不同环境（开发、测试、生产）使用环境特定的配置文件。

3. **敏感信息**：避免在配置文件中直接存储密码和 API 密钥等敏感信息。使用环境变量或安全存储代替。

4. **配置验证**：在应用程序启动时验证配置值，如果缺少或无效的必需设置，则快速失败。

5. **文档**：记录所有配置属性、其用途及其默认值。

## MCP 配置

| 属性 | 描述 | 默认值 |
|----------|-------------|---------|
| mcp.auth.token | MCP 鉴权令牌 | - |

## 相关 API


- [应用程序 API](application.md)
- [数据库 API](database.md)
