# AI 与 MCP 集成 (tinystruct)

tinystruct 的 Model Context Protocol (MCP) 模块为 AI 模型交互、工具发现、资源管理和提示词处理提供了全面的集成支持。

## 概述

MCP 模块允许 tinystruct 应用程序同时作为 MCP 服务器和客户端运行。它支持标准的 MCP 规范，包括 JSON-RPC 通信、Server-Sent Events (SSE) 和统一的资源模型。

## 核心概念

- **MCPApplication**: 处理 MCP 请求的应用程序基类。
- **MCPServer**: 完整的服务器实现，管理工具、资源和提示词。
- **MCPClient**: 用于连接和与 MCP 服务器交互的客户端。
- **MCPTool**: 可供 AI 模型发现和调用的可执行函数。
- **MCPResource**: 可供 AI 模型读取的数据源。
- **MCPPrompt**: 基于模板的 AI 提示词生成。

## 实现方式

### 创建 MCP 服务器

要创建 MCP 服务器，请继承 `MCPServer` 类并在 `init()` 方法中注册您的工具、资源或提示词：

```java
import org.tinystruct.mcp.MCPServer;
import org.tinystruct.mcp.tools.CalculatorTool;

public class MyMCPServer extends MCPServer {

    @Override
    public void init() {
        super.init();

        // 注册内置工具
        CalculatorTool calculator = new CalculatorTool();
        this.registerTool(calculator);

        // 注册自定义工具
        this.registerTool(new MyCustomTool());
    }
}
```

### 创建自定义工具

可以通过继承 `MCPTool` 并使用 `@Action` 注解定义可执行方法来创建自定义工具：

```java
import org.tinystruct.mcp.MCPTool;
import org.tinystruct.system.annotation.Action;
import org.tinystruct.system.annotation.Argument;

public class MyCustomTool extends MCPTool {
    
    public MyCustomTool() {
        super("my-tool", "一个用于数据处理的自定义工具", null, null, true);
    }
    
    @Action(value = "my-tool/process", 
            description = "处理输入数据", 
            arguments = {
                @Argument(key = "input", description = "待处理的数据", type = "string")
            })
    public String processData(String input) {
        return "Processed: " + input.toUpperCase();
    }
}
```

### 使用 MCP 客户端

您可以使用 `MCPClient` 以编程方式连接到 MCP 服务器：

```java
import org.tinystruct.mcp.MCPClient;
import java.util.HashMap;
import java.util.Map;

public class ClientExample {
    public static void main(String[] args) {
        MCPClient client = new MCPClient("http://localhost:8080", "your-auth-token");
        
        try {
            client.connect();
            
            // 执行工具
            Map<String, Object> params = new HashMap<>();
            params.put("a", 10);
            params.put("b", 20);
            Object result = client.executeResource("calculator/add", params);
            
            System.out.println("结果: " + result);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            client.disconnect();
        }
    }
}
```

## 运行服务器

使用 tinystruct 调度器启动您的 MCP 服务器：

```bash
bin/dispatcher start --import com.example.MyMCPServer
```

## 命令行交互

tinystruct CLI 还提供了与 MCP 服务器交互的命令：

```bash
# 连接到服务器
bin/dispatcher mcp/connect --url http://localhost:8080

# 列出可用工具
bin/dispatcher mcp/list/tools

# 调用工具
bin/dispatcher mcp/call --name calculator/add --arguments "a:10,b:20"

# 断开连接
bin/dispatcher mcp/disconnect
```

## 使用 SSE 进行实时更新

MCP 模块使用 Server-Sent Events (SSE) 进行实时通知。当服务器上的工具或资源更新时，连接的客户端将通过 `MCPPushManager` 立即收到通知。
