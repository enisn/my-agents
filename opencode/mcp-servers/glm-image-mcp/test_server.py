#!/usr/bin/env python3
import asyncio
import sys
from mcp.server import Server
from mcp.server.stdio import stdio_server

server = Server("test-server")


@server.list_tools()
async def list_tools_handler():
    print("list_tools called", file=sys.stderr)
    return [
        {
            "name": "test_tool",
            "description": "A test tool",
            "inputSchema": {"type": "object", "properties": {}},
        }
    ]


@server.call_tool()
async def call_tool_handler(name: str, arguments: dict):
    print(f"call_tool called: {name}", file=sys.stderr)
    return [{"type": "text", "text": f"Called {name} with {arguments}"}]


async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream, write_stream, server.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
