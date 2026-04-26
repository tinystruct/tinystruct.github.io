# AI & MCP Integration with tinystruct

The Model Context Protocol (MCP) module for tinystruct provides comprehensive integration for AI model interactions, tool discovery, resource management, and prompt handling.

## Overview

The MCP module enables tinystruct applications to act as both MCP servers and clients. It supports the standard MCP specification including JSON-RPC communication, Server-Sent Events (SSE), and a unified resource model.

## Key Concepts

- **MCPApplication**: The base class for applications that want to handle MCP requests.
- **MCPServer**: A complete server implementation that manages tools, resources, and prompts.
- **MCPClient**: A client used to connect to and interact with MCP servers.
- **MCPTool**: Executable functions that can be discovered and called by AI models.
- **MCPResource**: Data sources that can be read by AI models.
- **MCPPrompt**: Template-based text generation for AI prompts.

## Implementation

### Creating an MCP Server

To create an MCP server, extend the `MCPServer` class and register your tools, resources, or prompts in the `init()` method:

```java
import org.tinystruct.mcp.MCPServer;
import org.tinystruct.mcp.tools.CalculatorTool;

public class MyMCPServer extends MCPServer {

    @Override
    public void init() {
        super.init();

        // Register built-in tools
        CalculatorTool calculator = new CalculatorTool();
        this.registerTool(calculator);

        // Register custom tools
        this.registerTool(new MyCustomTool());
    }
}
```

### Creating a Custom Tool

Custom tools can be created by extending `MCPTool` and using the `@Action` annotation to define executable methods:

```java
import org.tinystruct.mcp.MCPTool;
import org.tinystruct.system.annotation.Action;
import org.tinystruct.system.annotation.Argument;

public class MyCustomTool extends MCPTool {
    
    public MyCustomTool() {
        super("my-tool", "A custom tool for data processing", null, null, true);
    }
    
    @Action(value = "my-tool/process", 
            description = "Process input data", 
            arguments = {
                @Argument(key = "input", description = "The data to process", type = "string")
            })
    public String processData(String input) {
        return "Processed: " + input.toUpperCase();
    }
}
```

### Using the MCP Client

You can connect to an MCP server programmatically using the `MCPClient`:

```java
import org.tinystruct.mcp.MCPClient;
import java.util.HashMap;
import java.util.Map;

public class ClientExample {
    public static void main(String[] args) {
        MCPClient client = new MCPClient("http://localhost:8080", "your-auth-token");
        
        try {
            client.connect();
            
            // Execute a tool
            Map<String, Object> params = new HashMap<>();
            params.put("a", 10);
            params.put("b", 20);
            Object result = client.executeResource("calculator/add", params);
            
            System.out.println("Result: " + result);
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            client.disconnect();
        }
    }
}
```

## Running the Server

Start your MCP server using the tinystruct dispatcher:

```bash
bin/dispatcher start --import com.example.MyMCPServer
```

## CLI Interaction

The tinystruct CLI also provides commands to interact with MCP servers:

```bash
# Connect to a server
bin/dispatcher mcp/connect --url http://localhost:8080

# List available tools
bin/dispatcher mcp/list/tools

# Call a tool
bin/dispatcher mcp/call --name calculator/add --arguments "a:10,b:20"

# Disconnect
bin/dispatcher mcp/disconnect
```

## Real-time Updates with SSE

The MCP module uses Server-Sent Events (SSE) for real-time notifications. When a tool or resource is updated on the server, connected clients receive immediate notifications via the `MCPPushManager`.
