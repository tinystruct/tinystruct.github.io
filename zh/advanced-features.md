# tinystruct 高级特性

本指南涵盖 tinystruct 框架中的高级特性和技术。

## 事件系统

tinystruct 包含一个强大的事件系统，允许组件在没有直接耦合的情况下进行通信。

### 事件调度器

```java
// 获取事件调度器实例
EventDispatcher dispatcher = EventDispatcher.getInstance();

// 注册事件处理程序
dispatcher.registerHandler(UserCreatedEvent.class, event -> {
    User user = event.getPayload();
    System.out.println("用户已创建：" + user.getName());
    
    // 发送欢迎邮件
    emailService.sendWelcomeEmail(user.getEmail());
});

// 分发事件
User newUser = userService.createUser("john@example.com", "password");
dispatcher.dispatch(new UserCreatedEvent(newUser));
```

### 自定义事件

```java
public class UserCreatedEvent implements Event<User> {
    private final User user;
    
    public UserCreatedEvent(User user) {
        this.user = user;
    }
    
    @Override
    public User getPayload() {
        return user;
    }
}
```

### 应用程序生命周期事件

```java
public class MyApp extends AbstractApplication {
    private static final EventDispatcher dispatcher = EventDispatcher.getInstance();
    
    static {
        // 注册应用程序启动处理程序
        dispatcher.registerHandler(ApplicationStartEvent.class, event -> {
            System.out.println("应用程序已启动：" + event.getPayload().getName());
        });
        
        // 注册应用程序关闭处理程序
        dispatcher.registerHandler(ApplicationShutdownEvent.class, event -> {
            System.out.println("应用程序正在关闭：" + event.getPayload().getName());
        });
    }
    
    @Override
    public void init() {
        // 分发启动事件
        dispatcher.dispatch(new ApplicationStartEvent(this));
        
        // 注册关闭钩子
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            dispatcher.dispatch(new ApplicationShutdownEvent(this));
        }));
    }
}
```

## 依赖注入

tinystruct 提供了一个简单的依赖注入机制。

### 服务注册表

```java
// 注册服务
ServiceRegistry.getInstance().register(UserService.class, new UserServiceImpl());
ServiceRegistry.getInstance().register(EmailService.class, new EmailServiceImpl());

// 检索服务
UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
EmailService emailService = ServiceRegistry.getInstance().getService(EmailService.class);
```

### 在动作中注入

```java
@Action("users")
public JsonResponse getUsers() {
    UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
    List<User> users = userService.findAll();
    return new JsonResponse(users);
}
```

## 面向切面编程

tinystruct 通过拦截器支持面向切面编程。

### 动作拦截器

```java
// 创建拦截器
public class LoggingInterceptor implements ActionInterceptor {
    @Override
    public boolean before(Action action, Object[] args) {
        System.out.println("执行动作：" + action.getPathRule());
        return true; // 继续执行
    }
    
    @Override
    public void after(Action action, Object result) {
        System.out.println("动作完成：" + action.getPathRule());
    }
    
    @Override
    public void onException(Action action, Exception e) {
        System.err.println("动作失败：" + action.getPathRule() + " - " + e.getMessage());
    }
}

// 注册拦截器
ActionManager.getInstance().addInterceptor(new LoggingInterceptor());
```

### 身份验证拦截器

```java
public class AuthInterceptor implements ActionInterceptor {
    @Override
    public boolean before(Action action, Object[] args) {
        // 检查动作是否需要身份验证
        if (action.getClass().isAnnotationPresent(RequiresAuth.class)) {
            // 从参数中获取请求
            Request request = null;
            for (Object arg : args) {
                if (arg instanceof Request) {
                    request = (Request) arg;
                    break;
                }
            }
            
            if (request == null) {
                return false; // 未找到请求
            }
            
            // 检查用户是否已通过身份验证
            Session session = request.getSession(false);
            if (session == null || session.getAttribute("user") == null) {
                // 用户未通过身份验证
                if (request.isAjax()) {
                    // 对于 AJAX 请求，设置未授权状态
                    request.setAttribute("_response_status", 401);
                    request.setAttribute("_response_message", "未授权");
                } else {
                    // 对于常规请求，重定向到登录
                    request.setAttribute("_redirect", "/login");
                }
                return false; // 停止执行
            }
        }
        
        return true; // 继续执行
    }
}

// 身份验证要求的自定义注解
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface RequiresAuth {
}

// 在动作上使用注解
@RequiresAuth
@Action("profile")
public Response showProfile(Request request) {
    // 此动作仅在用户通过身份验证时执行
    String username = (String) request.getSession().getAttribute("user");
    return new TemplateResponse("profile.html", Map.of("username", username));
}
```

## 缓存

tinystruct 提供了一个缓存机制来提高性能。

### 缓存配置

```java
// 在应用程序中配置缓存
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 配置缓存，具有 1000 个条目和 10 分钟过期时间
        CacheManager.configure(1000, 10 * 60 * 1000);
    }
}
```

### 使用缓存

```java
@Action("users")
public JsonResponse getUsers() {
    // 首先尝试从缓存获取
    @SuppressWarnings("unchecked")
    List<User> users = (List<User>) CacheManager.get("all_users");
    
    if (users == null) {
        // 不在缓存中，从数据库获取
        UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
        users = userService.findAll();
        
        // 存储在缓存中供将来请求使用
        CacheManager.put("all_users", users, 5 * 60 * 1000); // 5 分钟
    }
    
    return new JsonResponse(users);
}

@Action("users/create")
public JsonResponse createUser(Request request) {
    // 创建用户逻辑...
    
    // 修改后使缓存失效
    CacheManager.remove("all_users");
    
    return new JsonResponse(Map.of("success", true));
}
```

## 国际化 (i18n)

tinystruct 支持国际化，用于构建多语言应用程序。

### 消息配置

```properties
# messages_en.properties
greeting=Hello, {0}!
welcome=Welcome to our application
error.notfound=Resource not found

# messages_fr.properties
greeting=Bonjour, {0}!
welcome=Bienvenue dans notre application
error.notfound=Ressource non trouvée

# messages_zh.properties
greeting=你好，{0}！
welcome=欢迎使用我们的应用程序
error.notfound=未找到资源
```

### 使用消息

```java
@Action("welcome")
public Response welcome(Request request) {
    // 从请求获取区域设置或使用默认值
    Locale locale = request.getLocale();
    
    // 获取区域设置的消息包
    ResourceBundle bundle = ResourceBundle.getBundle("messages", locale);
    
    // 获取带参数的消息
    String greeting = MessageFormat.format(
        bundle.getString("greeting"),
        request.getParameter("name", "访客")
    );
    
    // 获取简单消息
    String welcome = bundle.getString("welcome");
    
    Map<String, Object> model = new HashMap<>();
    model.put("greeting", greeting);
    model.put("welcome", welcome);
    
    return new TemplateResponse("welcome.html", model);
}
```

### 区域设置检测

```java
public class LocaleInterceptor implements ActionInterceptor {
    @Override
    public boolean before(Action action, Object[] args) {
        // 在参数中查找请求
        for (Object arg : args) {
            if (arg instanceof Request) {
                Request request = (Request) arg;
                
                // 检查区域设置参数
                String localeParam = request.getParameter("locale");
                if (localeParam != null) {
                    // 解析区域设置
                    Locale locale = Locale.forLanguageTag(localeParam);
                    
                    // 存储在会话中
                    Session session = request.getSession(true);
                    session.setAttribute("locale", locale);
                    
                    // 在请求中设置
                    request.setAttribute("locale", locale);
                } else {
                    // 检查会话中的区域设置
                    Session session = request.getSession(false);
                    if (session != null && session.getAttribute("locale") != null) {
                        request.setAttribute("locale", session.getAttribute("locale"));
                    }
                }
                
                break;
            }
        }
        
        return true;
    }
}
```

## WebSocket 支持

tinystruct 提供 WebSocket 支持，用于实时通信。

### WebSocket 处理程序

```java
public class ChatWebSocketHandler implements WebSocketHandler {
    private static final Set<WebSocketSession> sessions = new ConcurrentHashSet<>();
    
    @Override
    public void onOpen(WebSocketSession session) {
        sessions.add(session);
        System.out.println("WebSocket 已打开：" + session.getId());
    }
    
    @Override
    public void onMessage(WebSocketSession session, String message) {
        System.out.println("收到消息：" + message);
        
        // 向所有会话广播消息
        for (WebSocketSession s : sessions) {
            try {
                s.sendMessage(message);
            } catch (IOException e) {
                System.err.println("发送消息时出错：" + e.getMessage());
            }
        }
    }
    
    @Override
    public void onClose(WebSocketSession session, int closeCode, String reason) {
        sessions.remove(session);
        System.out.println("WebSocket 已关闭：" + session.getId());
    }
    
    @Override
    public void onError(WebSocketSession session, Throwable error) {
        System.err.println("WebSocket 错误：" + error.getMessage());
    }
}
```

### 注册 WebSocket 端点

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 注册 WebSocket 端点
        WebSocketManager.getInstance().addEndpoint("/chat", new ChatWebSocketHandler());
    }
}
```

### WebSocket 客户端

```javascript
// JavaScript 客户端
const socket = new WebSocket('ws://localhost:8080/chat');

socket.onopen = function(event) {
    console.log('连接已建立');
};

socket.onmessage = function(event) {
    console.log('收到消息：' + event.data);
    // 使用消息更新 UI
    document.getElementById('messages').innerHTML += '<div>' + event.data + '</div>';
};

socket.onclose = function(event) {
    console.log('连接已关闭');
};

// 发送消息
function sendMessage() {
    const message = document.getElementById('messageInput').value;
    socket.send(message);
    document.getElementById('messageInput').value = '';
}
```

## 任务调度

tinystruct 提供了一个任务调度机制，用于运行后台任务。

### 计划任务

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 安排每 5 分钟运行一次的任务
        TaskScheduler.getInstance().scheduleAtFixedRate(
            new CleanupTask(),
            0,              // 初始延迟
            5 * 60 * 1000   // 周期（5 分钟）
        );
        
        // 安排每天在特定时间运行的任务
        Calendar calendar = Calendar.getInstance();
        calendar.set(Calendar.HOUR_OF_DAY, 2);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        
        long initialDelay = calendar.getTimeInMillis() - System.currentTimeMillis();
        if (initialDelay < 0) {
            initialDelay += 24 * 60 * 60 * 1000; // 添加一天
        }
        
        TaskScheduler.getInstance().scheduleAtFixedRate(
            new DailyReportTask(),
            initialDelay,
            24 * 60 * 60 * 1000 // 周期（24 小时）
        );
    }
}

// 任务实现
public class CleanupTask implements Runnable {
    @Override
    public void run() {
        try {
            System.out.println("在 " + new Date() + " 运行清理任务");
            
            // 清理逻辑
            Repository repository = Type.MySQL.createRepository();
            repository.connect(getConfiguration());
            
            // 删除过期会话
            repository.execute("DELETE FROM sessions WHERE expiry < NOW()");
            
            // 删除旧日志
            repository.execute("DELETE FROM logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)");
        } catch (Exception e) {
            System.err.println("清理任务中出错：" + e.getMessage());
        }
    }
}
```

## 插件系统

tinystruct 包含一个插件系统，用于扩展功能。

### 插件接口

```java
public interface Plugin {
    void initialize(AbstractApplication application);
    void shutdown();
    String getName();
    String getVersion();
}
```

### 实现插件

```java
public class AnalyticsPlugin implements Plugin {
    private AbstractApplication application;
    
    @Override
    public void initialize(AbstractApplication application) {
        this.application = application;
        System.out.println("初始化分析插件");
        
        // 注册事件处理程序
        EventDispatcher dispatcher = EventDispatcher.getInstance();
        dispatcher.registerHandler(RequestEvent.class, this::handleRequest);
    }
    
    @Override
    public void shutdown() {
        System.out.println("关闭分析插件");
    }
    
    @Override
    public String getName() {
        return "分析插件";
    }
    
    @Override
    public String getVersion() {
        return "1.0.0";
    }
    
    private void handleRequest(Event<Request> event) {
        Request request = event.getPayload();
        
        // 记录请求以进行分析
        String path = request.getRequestURI();
        String ip = request.getRemoteAddr();
        String userAgent = request.getHeader("User-Agent");
        
        // 存储分析数据
        try {
            Repository repository = Type.MySQL.createRepository();
            repository.connect(application.getConfiguration());
            
            repository.execute(
                "INSERT INTO analytics (path, ip, user_agent, timestamp) VALUES (?, ?, ?, NOW())",
                path, ip, userAgent
            );
        } catch (Exception e) {
            System.err.println("记录分析时出错：" + e.getMessage());
        }
    }
}
```

### 加载插件

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // 加载插件
        PluginManager pluginManager = PluginManager.getInstance();
        
        // 从配置加载
        String pluginsConfig = getConfiguration().get("plugins", "");
        String[] pluginClasses = pluginsConfig.split(",");
        
        for (String pluginClass : pluginClasses) {
            if (!pluginClass.trim().isEmpty()) {
                try {
                    Class<?> clazz = Class.forName(pluginClass.trim());
                    Plugin plugin = (Plugin) clazz.getDeclaredConstructor().newInstance();
                    pluginManager.registerPlugin(plugin);
                    plugin.initialize(this);
                } catch (Exception e) {
                    System.err.println("加载插件 " + pluginClass + " 时出错：" + e.getMessage());
                }
            }
        }
    }
}
```

## 下一步

- 探索[最佳实践](best-practices.md)
- 查看 [API 参考](api/README.md)
