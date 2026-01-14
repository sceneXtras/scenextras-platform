# Quick Start Prompt for Your LLM

Copy this prompt into your Cursor chat or LLM system prompt:

---

You have access to MCP tools via code execution. When you need to use tools:

1. **Discover**: List the 'servers/' directory to see available servers
2. **Explore**: Read 'servers/{server}/index.ts' to see available tools  
3. **Generate Code**: Write TypeScript code that imports and uses tools
4. **Execute**: Code runs in sandbox, you see only results

Available servers:
- memory (9 tools) - Knowledge graph operations
- perplexity-server (3 tools) - Perplexity AI API
- chrome-devtools (26 tools) - Browser automation
- context7 (2 tools) - Documentation lookup
- sequential-thinking (1 tool) - Problem solving

Example code structure:
```typescript
import * as memory from './servers/memory';
import * as perplexity from './servers/perplexity-server';

// Use tools
const results = await memory.search_nodes({ query: 'test' });
const answer = await perplexity.perplexity_ask({
  messages: [{ role: 'user', content: 'What is MCP?' }]
});

console.log(results);
```

When processing large datasets:
- Fetch data using MCP tools
- Process/filter/transform in code
- Only return summaries or samples
- Never pass full datasets through context

---

## Helper Commands

```bash
cd mcp-code-execution

# List all servers
npx tsx llm-helper.ts list

# List tools for a server
npx tsx llm-helper.ts tools memory

# Search for tools
npx tsx llm-helper.ts search "search"

# Generate example code
npx tsx llm-helper.ts example memory search_nodes

# Get full discovery prompt
npx tsx llm-helper.ts prompt
```

## Example Usage

**You**: "Search my knowledge graph for nodes related to 'authentication'"

**LLM generates**:
```typescript
import * as memory from './servers/memory';
const results = await memory.search_nodes({ query: 'authentication' });
console.log(`Found ${results.length} nodes:`);
results.slice(0, 10).forEach(node => {
  console.log(`- ${node.name}: ${node.description}`);
});
```

Then execute this code using `executeWithImports()` from `mcp-code-execution/src/sandbox.js`

