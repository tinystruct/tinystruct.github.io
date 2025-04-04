# Advanced Features in tinystruct

This guide covers advanced features and techniques in the tinystruct framework.

## Event System

tinystruct includes a powerful event system that allows components to communicate without direct coupling.

### Event Dispatcher

```java
// Get the event dispatcher instance
EventDispatcher dispatcher = EventDispatcher.getInstance();

// Register an event handler
dispatcher.registerHandler(UserCreatedEvent.class, event -> {
    User user = event.getPayload();
    System.out.println("User created: " + user.getName());
    
    // Send welcome email
    emailService.sendWelcomeEmail(user.getEmail());
});

// Dispatch an event
User newUser = userService.createUser("john@example.com", "password");
dispatcher.dispatch(new UserCreatedEvent(newUser));
```

### Custom Events

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

### Application Lifecycle Events

```java
public class MyApp extends AbstractApplication {
    private static final EventDispatcher dispatcher = EventDispatcher.getInstance();
    
    static {
        // Register application startup handler
        dispatcher.registerHandler(ApplicationStartEvent.class, event -> {
            System.out.println("Application started: " + event.getPayload().getName());
        });
        
        // Register application shutdown handler
        dispatcher.registerHandler(ApplicationShutdownEvent.class, event -> {
            System.out.println("Application shutting down: " + event.getPayload().getName());
        });
    }
    
    @Override
    public void init() {
        // Dispatch startup event
        dispatcher.dispatch(new ApplicationStartEvent(this));
        
        // Register shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            dispatcher.dispatch(new ApplicationShutdownEvent(this));
        }));
    }
}
```

## Dependency Injection

tinystruct provides a simple dependency injection mechanism.

### Service Registry

```java
// Register services
ServiceRegistry.getInstance().register(UserService.class, new UserServiceImpl());
ServiceRegistry.getInstance().register(EmailService.class, new EmailServiceImpl());

// Retrieve services
UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
EmailService emailService = ServiceRegistry.getInstance().getService(EmailService.class);
```

### Injection in Actions

```java
@Action("users")
public JsonResponse getUsers() {
    UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
    List<User> users = userService.findAll();
    return new JsonResponse(users);
}
```

## Aspect-Oriented Programming

tinystruct supports aspect-oriented programming through interceptors.

### Action Interceptors

```java
// Create an interceptor
public class LoggingInterceptor implements ActionInterceptor {
    @Override
    public boolean before(Action action, Object[] args) {
        System.out.println("Executing action: " + action.getPathRule());
        return true; // Continue execution
    }
    
    @Override
    public void after(Action action, Object result) {
        System.out.println("Action completed: " + action.getPathRule());
    }
    
    @Override
    public void onException(Action action, Exception e) {
        System.err.println("Action failed: " + action.getPathRule() + " - " + e.getMessage());
    }
}

// Register the interceptor
ActionManager.getInstance().addInterceptor(new LoggingInterceptor());
```

### Authentication Interceptor

```java
public class AuthInterceptor implements ActionInterceptor {
    @Override
    public boolean before(Action action, Object[] args) {
        // Check if action requires authentication
        if (action.getClass().isAnnotationPresent(RequiresAuth.class)) {
            // Get the request from arguments
            Request request = null;
            for (Object arg : args) {
                if (arg instanceof Request) {
                    request = (Request) arg;
                    break;
                }
            }
            
            if (request == null) {
                return false; // No request found
            }
            
            // Check if user is authenticated
            Session session = request.getSession(false);
            if (session == null || session.getAttribute("user") == null) {
                // User not authenticated
                if (request.isAjax()) {
                    // For AJAX requests, set unauthorized status
                    request.setAttribute("_response_status", 401);
                    request.setAttribute("_response_message", "Unauthorized");
                } else {
                    // For regular requests, redirect to login
                    request.setAttribute("_redirect", "/login");
                }
                return false; // Stop execution
            }
        }
        
        return true; // Continue execution
    }
}

// Custom annotation for authentication requirement
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
public @interface RequiresAuth {
}

// Using the annotation on an action
@RequiresAuth
@Action("profile")
public Response showProfile(Request request) {
    // This action will only execute if user is authenticated
    String username = (String) request.getSession().getAttribute("user");
    return new TemplateResponse("profile.html", Map.of("username", username));
}
```

## Caching

tinystruct provides a caching mechanism to improve performance.

### Cache Configuration

```java
// Configure cache in your application
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // Configure cache with 1000 entries and 10 minutes expiration
        CacheManager.configure(1000, 10 * 60 * 1000);
    }
}
```

### Using the Cache

```java
@Action("users")
public JsonResponse getUsers() {
    // Try to get from cache first
    @SuppressWarnings("unchecked")
    List<User> users = (List<User>) CacheManager.get("all_users");
    
    if (users == null) {
        // Not in cache, fetch from database
        UserService userService = ServiceRegistry.getInstance().getService(UserService.class);
        users = userService.findAll();
        
        // Store in cache for future requests
        CacheManager.put("all_users", users, 5 * 60 * 1000); // 5 minutes
    }
    
    return new JsonResponse(users);
}

@Action("users/create")
public JsonResponse createUser(Request request) {
    // Create user logic...
    
    // Invalidate cache after modification
    CacheManager.remove("all_users");
    
    return new JsonResponse(Map.of("success", true));
}
```

## Internationalization (i18n)

tinystruct supports internationalization for building multilingual applications.

### Message Configuration

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

### Using Messages

```java
@Action("welcome")
public Response welcome(Request request) {
    // Get locale from request or use default
    Locale locale = request.getLocale();
    
    // Get message bundle for locale
    ResourceBundle bundle = ResourceBundle.getBundle("messages", locale);
    
    // Get message with parameters
    String greeting = MessageFormat.format(
        bundle.getString("greeting"),
        request.getParameter("name", "Guest")
    );
    
    // Get simple message
    String welcome = bundle.getString("welcome");
    
    Map<String, Object> model = new HashMap<>();
    model.put("greeting", greeting);
    model.put("welcome", welcome);
    
    return new TemplateResponse("welcome.html", model);
}
```

### Locale Detection

```java
public class LocaleInterceptor implements ActionInterceptor {
    @Override
    public boolean before(Action action, Object[] args) {
        // Find request in arguments
        for (Object arg : args) {
            if (arg instanceof Request) {
                Request request = (Request) arg;
                
                // Check for locale parameter
                String localeParam = request.getParameter("locale");
                if (localeParam != null) {
                    // Parse locale
                    Locale locale = Locale.forLanguageTag(localeParam);
                    
                    // Store in session
                    Session session = request.getSession(true);
                    session.setAttribute("locale", locale);
                    
                    // Set in request
                    request.setAttribute("locale", locale);
                } else {
                    // Check for locale in session
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

## WebSocket Support

tinystruct provides WebSocket support for real-time communication.

### WebSocket Handler

```java
public class ChatWebSocketHandler implements WebSocketHandler {
    private static final Set<WebSocketSession> sessions = new ConcurrentHashSet<>();
    
    @Override
    public void onOpen(WebSocketSession session) {
        sessions.add(session);
        System.out.println("WebSocket opened: " + session.getId());
    }
    
    @Override
    public void onMessage(WebSocketSession session, String message) {
        System.out.println("Received message: " + message);
        
        // Broadcast message to all sessions
        for (WebSocketSession s : sessions) {
            try {
                s.sendMessage(message);
            } catch (IOException e) {
                System.err.println("Error sending message: " + e.getMessage());
            }
        }
    }
    
    @Override
    public void onClose(WebSocketSession session, int closeCode, String reason) {
        sessions.remove(session);
        System.out.println("WebSocket closed: " + session.getId());
    }
    
    @Override
    public void onError(WebSocketSession session, Throwable error) {
        System.err.println("WebSocket error: " + error.getMessage());
    }
}
```

### Registering WebSocket Endpoint

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // Register WebSocket endpoint
        WebSocketManager.getInstance().addEndpoint("/chat", new ChatWebSocketHandler());
    }
}
```

### WebSocket Client

```javascript
// JavaScript client
const socket = new WebSocket('ws://localhost:8080/chat');

socket.onopen = function(event) {
    console.log('Connection established');
};

socket.onmessage = function(event) {
    console.log('Message received: ' + event.data);
    // Update UI with message
    document.getElementById('messages').innerHTML += '<div>' + event.data + '</div>';
};

socket.onclose = function(event) {
    console.log('Connection closed');
};

// Send message
function sendMessage() {
    const message = document.getElementById('messageInput').value;
    socket.send(message);
    document.getElementById('messageInput').value = '';
}
```

## Task Scheduling

tinystruct provides a task scheduling mechanism for running background tasks.

### Scheduled Tasks

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // Schedule a task to run every 5 minutes
        TaskScheduler.getInstance().scheduleAtFixedRate(
            new CleanupTask(),
            0,              // Initial delay
            5 * 60 * 1000   // Period (5 minutes)
        );
        
        // Schedule a task to run at a specific time every day
        Calendar calendar = Calendar.getInstance();
        calendar.set(Calendar.HOUR_OF_DAY, 2);
        calendar.set(Calendar.MINUTE, 0);
        calendar.set(Calendar.SECOND, 0);
        
        long initialDelay = calendar.getTimeInMillis() - System.currentTimeMillis();
        if (initialDelay < 0) {
            initialDelay += 24 * 60 * 60 * 1000; // Add one day
        }
        
        TaskScheduler.getInstance().scheduleAtFixedRate(
            new DailyReportTask(),
            initialDelay,
            24 * 60 * 60 * 1000 // Period (24 hours)
        );
    }
}

// Task implementation
public class CleanupTask implements Runnable {
    @Override
    public void run() {
        try {
            System.out.println("Running cleanup task at " + new Date());
            
            // Cleanup logic
            Repository repository = Type.MySQL.createRepository();
            repository.connect(getConfiguration());
            
            // Delete expired sessions
            repository.execute("DELETE FROM sessions WHERE expiry < NOW()");
            
            // Delete old logs
            repository.execute("DELETE FROM logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)");
        } catch (Exception e) {
            System.err.println("Error in cleanup task: " + e.getMessage());
        }
    }
}
```

## Plugin System

tinystruct includes a plugin system for extending functionality.

### Plugin Interface

```java
public interface Plugin {
    void initialize(AbstractApplication application);
    void shutdown();
    String getName();
    String getVersion();
}
```

### Implementing a Plugin

```java
public class AnalyticsPlugin implements Plugin {
    private AbstractApplication application;
    
    @Override
    public void initialize(AbstractApplication application) {
        this.application = application;
        System.out.println("Initializing Analytics Plugin");
        
        // Register event handlers
        EventDispatcher dispatcher = EventDispatcher.getInstance();
        dispatcher.registerHandler(RequestEvent.class, this::handleRequest);
    }
    
    @Override
    public void shutdown() {
        System.out.println("Shutting down Analytics Plugin");
    }
    
    @Override
    public String getName() {
        return "Analytics Plugin";
    }
    
    @Override
    public String getVersion() {
        return "1.0.0";
    }
    
    private void handleRequest(Event<Request> event) {
        Request request = event.getPayload();
        
        // Log request for analytics
        String path = request.getRequestURI();
        String ip = request.getRemoteAddr();
        String userAgent = request.getHeader("User-Agent");
        
        // Store analytics data
        try {
            Repository repository = Type.MySQL.createRepository();
            repository.connect(application.getConfiguration());
            
            repository.execute(
                "INSERT INTO analytics (path, ip, user_agent, timestamp) VALUES (?, ?, ?, NOW())",
                path, ip, userAgent
            );
        } catch (Exception e) {
            System.err.println("Error logging analytics: " + e.getMessage());
        }
    }
}
```

### Loading Plugins

```java
public class MyApp extends AbstractApplication {
    @Override
    public void init() {
        // Load plugins
        PluginManager pluginManager = PluginManager.getInstance();
        
        // Load from configuration
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
                    System.err.println("Error loading plugin " + pluginClass + ": " + e.getMessage());
                }
            }
        }
    }
}
```

## Next Steps

- Explore [Best Practices](best-practices.md)
- Check out the [API Reference](api/README.md)
