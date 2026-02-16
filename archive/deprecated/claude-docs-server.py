#!/usr/bin/env python3
"""
MCP Server for Claude Code Documentation

Provides access to the most recent Claude Code documentation from docs.anthropic.com
"""

import json
import sys
from typing import Any, Dict, List, Optional
import requests
from urllib.parse import urljoin, urlparse
import re

class ClaudeDocsServer:
    """MCP Server for Claude Code Documentation"""
    
    def __init__(self):
        self.base_url = "https://docs.anthropic.com/en/docs/claude-code/"
        self.pages = {
            "overview": "overview",
            "quickstart": "quickstart", 
            "memory": "memory",
            "common-workflows": "common-workflows",
            "ide-integrations": "ide-integrations",
            "mcp": "mcp",
            "github-actions": "github-actions",
            "sdk": "sdk",
            "troubleshooting": "troubleshooting",
            "third-party-integrations": "third-party-integrations",
            "amazon-bedrock": "amazon-bedrock",
            "google-vertex-ai": "google-vertex-ai", 
            "corporate-proxy": "corporate-proxy",
            "llm-gateway": "llm-gateway",
            "devcontainer": "devcontainer",
            "iam": "iam",
            "security": "security",
            "monitoring-usage": "monitoring-usage",
            "costs": "costs",
            "cli-reference": "cli-reference",
            "interactive-mode": "interactive-mode",
            "slash-commands": "slash-commands",
            "settings": "settings",
            "hooks": "hooks"
        }
        
    def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """Handle incoming MCP requests"""
        method = request.get("method")
        
        if method == "tools/list":
            return self._list_tools()
        elif method == "tools/call":
            return self._call_tool(request.get("params", {}))
        else:
            return {"error": f"Unknown method: {method}"}
    
    def _list_tools(self) -> Dict[str, Any]:
        """List available tools"""
        return {
            "tools": [
                {
                    "name": "fetch_claude_docs",
                    "description": "Fetch Claude Code documentation from docs.anthropic.com",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "page": {
                                "type": "string",
                                "description": "Documentation page to fetch",
                                "enum": list(self.pages.keys())
                            },
                            "query": {
                                "type": "string", 
                                "description": "Optional search query to filter content",
                                "default": ""
                            }
                        },
                        "required": ["page"]
                    }
                },
                {
                    "name": "search_claude_docs",
                    "description": "Search across all Claude Code documentation",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "query": {
                                "type": "string",
                                "description": "Search query"
                            },
                            "pages": {
                                "type": "array",
                                "items": {"type": "string", "enum": list(self.pages.keys())},
                                "description": "Specific pages to search (optional)",
                                "default": []
                            }
                        },
                        "required": ["query"]
                    }
                }
            ]
        }
    
    def _call_tool(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Call a specific tool"""
        tool_name = params.get("name")
        arguments = params.get("arguments", {})
        
        if tool_name == "fetch_claude_docs":
            return self._fetch_docs(arguments)
        elif tool_name == "search_claude_docs":
            return self._search_docs(arguments)
        else:
            return {"error": f"Unknown tool: {tool_name}"}
    
    def _fetch_docs(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Fetch a specific documentation page"""
        page = args.get("page")
        query = args.get("query", "")
        
        if page not in self.pages:
            return {"error": f"Unknown page: {page}"}
        
        try:
            url = urljoin(self.base_url, self.pages[page])
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            
            # Extract text content (simple HTML stripping)
            content = self._extract_text_content(response.text)
            
            if query:
                content = self._filter_content(content, query)
            
            return {
                "content": [
                    {
                        "type": "text",
                        "text": f"# Claude Code Documentation: {page.title()}\n\nURL: {url}\n\n{content}"
                    }
                ]
            }
        except Exception as e:
            return {"error": f"Failed to fetch {page}: {str(e)}"}
    
    def _search_docs(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Search across documentation pages"""
        query = args.get("query")
        pages_to_search = args.get("pages", list(self.pages.keys()))
        
        results = []
        for page in pages_to_search:
            if page not in self.pages:
                continue
                
            try:
                url = urljoin(self.base_url, self.pages[page])
                response = requests.get(url, timeout=30)
                response.raise_for_status()
                
                content = self._extract_text_content(response.text)
                if self._contains_query(content, query):
                    filtered = self._filter_content(content, query)
                    results.append({
                        "page": page,
                        "url": url,
                        "content": filtered[:1000] + "..." if len(filtered) > 1000 else filtered
                    })
            except Exception as e:
                continue
        
        if not results:
            return {
                "content": [
                    {
                        "type": "text", 
                        "text": f"No results found for query: '{query}'"
                    }
                ]
            }
        
        result_text = f"# Search Results for '{query}'\n\n"
        for result in results:
            result_text += f"## {result['page'].title()}\n"
            result_text += f"URL: {result['url']}\n\n"
            result_text += f"{result['content']}\n\n---\n\n"
        
        return {
            "content": [
                {
                    "type": "text",
                    "text": result_text
                }
            ]
        }
    
    def _extract_text_content(self, html: str) -> str:
        """Extract text content from HTML (basic implementation)"""
        # Remove script and style elements
        html = re.sub(r'<script[^>]*>.*?</script>', '', html, flags=re.DOTALL | re.IGNORECASE)
        html = re.sub(r'<style[^>]*>.*?</style>', '', html, flags=re.DOTALL | re.IGNORECASE)
        
        # Remove HTML tags
        html = re.sub(r'<[^>]+>', '', html)
        
        # Clean up whitespace
        html = re.sub(r'\s+', ' ', html).strip()
        
        return html
    
    def _contains_query(self, content: str, query: str) -> bool:
        """Check if content contains the query (case-insensitive)"""
        return query.lower() in content.lower()
    
    def _filter_content(self, content: str, query: str) -> str:
        """Filter content to show relevant sections around query matches"""
        sentences = content.split('. ')
        relevant_sentences = []
        
        for i, sentence in enumerate(sentences):
            if self._contains_query(sentence, query):
                # Include context: 2 sentences before and after
                start = max(0, i - 2)
                end = min(len(sentences), i + 3)
                relevant_sentences.extend(sentences[start:end])
        
        if not relevant_sentences:
            return content[:500] + "..." if len(content) > 500 else content
        
        # Remove duplicates while preserving order
        seen = set()
        filtered = []
        for sentence in relevant_sentences:
            if sentence not in seen:
                seen.add(sentence)
                filtered.append(sentence)
        
        return '. '.join(filtered)

def main():
    """Main MCP server loop"""
    server = ClaudeDocsServer()
    
    for line in sys.stdin:
        try:
            request = json.loads(line.strip())
            response = server.handle_request(request)
            print(json.dumps(response))
            sys.stdout.flush()
        except json.JSONDecodeError:
            print(json.dumps({"error": "Invalid JSON"}))
            sys.stdout.flush()
        except Exception as e:
            print(json.dumps({"error": f"Server error: {str(e)}"}))
            sys.stdout.flush()

if __name__ == "__main__":
    main()