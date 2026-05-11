#!/usr/bin/env python3
"""
MCP Server for Z.AI Image Generation API (Simplified Version)
Provides image generation capabilities using Z.AI's GLM-Image and CogView-4 models.
"""

import asyncio
import json
import os
import sys
from pathlib import Path

try:
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
except ImportError:
    print(
        "Error: mcp not installed. Install with: pip install mcp",
        file=sys.stderr,
    )
    sys.exit(1)

try:
    from zai import ZaiClient
except ImportError:
    print(
        "Error: zai-sdk not installed. Install with: pip install zai-sdk",
        file=sys.stderr,
    )
    sys.exit(1)

import httpx


# Create MCP server
server = Server("zai-image-mcp")

# Configuration - API credentials come from environment variables.
ZAI_CREDENTIAL = os.getenv("ZAI_API_KEY") or os.getenv("ZAI_IMAGE_API_KEY")
DEFAULT_MODEL = "cogView-4-250304"


# Model configurations
MODEL_CONFIGS = {
    "glm-image": {
        "name": "GLM-Image",
        "default_size": "1280x1280",
        "default_quality": "hd",
        "has_quality": True,
        "recommended_sizes": [
            "1280x1280",
            "1568x1056",
            "1056x1568",
            "1472x1088",
            "1088x1472",
            "1728x960",
            "960x1728",
        ],
        "custom_size_requirements": {
            "width_range": "1024-2048px",
            "height_range": "1024-2048px",
            "divisible_by": 32,
            "max_pixels": "2^22 (4,194,304)",
        },
        "price": "$0.015/image",
        "description": "Hybrid architecture model, excellent for text rendering (posters, diagrams, multi-panel drawings)",
    },
    "cogView-4-250304": {
        "name": "CogView-4",
        "default_size": "1024x1024",
        "default_quality": None,
        "has_quality": False,
        "recommended_sizes": [
            "1024x1024",
            "768x1344",
            "864x1152",
            "1344x768",
            "1152x864",
            "1440x720",
            "720x1440",
        ],
        "custom_size_requirements": {
            "width_range": "512-2048px",
            "height_range": "512-2048px",
            "divisible_by": 16,
            "max_pixels": "2^21 (2,097,152)",
        },
        "price": "$0.01/image",
        "description": "SOTA open-source model, bilingual support (Chinese/English), any resolution support",
    },
}

VALID_QUALITIES = ["hd", "standard"]


def get_client():
    """Get authenticated Z.AI client."""
    if not ZAI_CREDENTIAL:
        raise ValueError("ZAI_API_KEY environment variable not set")
    return ZaiClient(api_key=ZAI_CREDENTIAL)


def validate_size(size: str, model: str) -> bool:
    """Validate image size format for a specific model."""
    config = MODEL_CONFIGS.get(model)
    if not config:
        return False

    if size in config["recommended_sizes"]:
        return True

    try:
        width, height = size.lower().split("x")
        width, height = int(width), int(height)

        size_req = config["custom_size_requirements"]
        width_range = size_req["width_range"].replace("px", "")
        height_range = size_req["height_range"].replace("px", "")

        min_width, max_width = map(int, width_range.split("-"))
        min_height, max_height = map(int, height_range.split("-"))

        if not (min_width <= width <= max_width and min_height <= height <= max_height):
            return False

        if (
            width % size_req["divisible_by"] != 0
            or height % size_req["divisible_by"] != 0
        ):
            return False

        max_pixels = int(size_req["max_pixels"].split("(")[1].rstrip(")"))
        if width * height > max_pixels:
            return False

        return True
    except (ValueError, AttributeError, KeyError):
        return False


async def download_image(url: str, output_path: Path) -> Path:
    """Download image from URL to local path."""
    async with httpx.AsyncClient() as client:
        response = await client.get(url, follow_redirects=True)
        response.raise_for_status()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_bytes(response.content)
    return output_path


@server.list_tools()
async def list_tools() -> list:
    """List available tools."""
    return [
        {
            "name": "generate_image",
            "description": "Generate an image using Z.AI's image generation models",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "prompt": {
                        "type": "string",
                        "description": "Text description of image to generate",
                    },
                    "model": {
                        "type": "string",
                        "description": "Model to use (glm-image or cogView-4-250304)",
                        "default": DEFAULT_MODEL,
                    },
                    "size": {
                        "type": "string",
                        "description": "Image dimensions (WIDTHxHEIGHT)",
                    },
                    "quality": {
                        "type": "string",
                        "description": "Quality (hd/standard, only for glm-image)",
                    },
                    "save_path": {
                        "type": "string",
                        "description": "Optional path to save image",
                    },
                },
                "required": ["prompt"],
            },
        },
        {
            "name": "list_supported_models",
            "description": "List all available image generation models",
            "inputSchema": {"type": "object", "properties": {}},
        },
        {
            "name": "list_supported_sizes",
            "description": "List supported sizes for a model",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "model": {"type": "string", "description": "Model name (optional)"}
                },
            },
        },
    ]


@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list:
    """Handle tool calls."""
    if name == "generate_image":
        try:
            prompt = arguments.get("prompt")
            model = arguments.get("model", DEFAULT_MODEL)
            size = arguments.get("size")
            quality = arguments.get("quality")
            save_path = arguments.get("save_path")

            if not prompt:
                raise ValueError("Prompt cannot be empty")

            if model not in MODEL_CONFIGS:
                available = ", ".join(MODEL_CONFIGS.keys())
                raise ValueError(f"Invalid model: {model}. Available: {available}")

            config = MODEL_CONFIGS[model]

            if size is None:
                size = config["default_size"]

            if not validate_size(size, model):
                raise ValueError(f"Invalid size: {size} for model {model}")

            if config["has_quality"]:
                if quality is None:
                    quality = config["default_quality"]
                elif quality not in VALID_QUALITIES:
                    raise ValueError(f"Invalid quality: {quality}")
            else:
                quality = None

            client = get_client()

            if quality:
                response = client.images.generations(
                    model=model, prompt=prompt, size=size, quality=quality
                )
            else:
                response = client.images.generations(
                    model=model, prompt=prompt, size=size
                )

            image_url = response.data[0].url
            created = response.created

            if save_path:
                output_path = Path(save_path)
            else:
                output_path = Path(f"generated_image_{created}.png")

            await download_image(image_url, output_path)

            result = {
                "success": True,
                "url": image_url,
                "local_path": str(output_path.absolute()),
                "model": model,
                "size": size,
                "quality": quality,
                "prompt": prompt,
                "created_at": created,
            }

            return [{"type": "text", "text": json.dumps(result, indent=2)}]

        except Exception as e:
            error_result = {
                "success": False,
                "error": str(e),
                "error_type": type(e).__name__,
            }
            return [{"type": "text", "text": json.dumps(error_result, indent=2)}]

    elif name == "list_supported_models":
        models_info = []
        for model_id, config in MODEL_CONFIGS.items():
            model_info = {
                "model": model_id,
                "name": config["name"],
                "price": config["price"],
                "description": config["description"],
                "default_size": config["default_size"],
                "supports_quality": config["has_quality"],
            }
            if model_id == DEFAULT_MODEL:
                model_info["is_default"] = True
            models_info.append(model_info)

        return [{"type": "text", "text": json.dumps(models_info, indent=2)}]

    elif name == "list_supported_sizes":
        model = arguments.get("model", DEFAULT_MODEL)

        if model not in MODEL_CONFIGS:
            available = ", ".join(MODEL_CONFIGS.keys())
            return [
                {
                    "type": "text",
                    "text": json.dumps(
                        {"error": f"Invalid model: {model}. Available: {available}"},
                        indent=2,
                    ),
                }
            ]

        config = MODEL_CONFIGS[model]
        info = {
            "model": model,
            "recommended_sizes": config["recommended_sizes"],
            "custom_size_requirements": config["custom_size_requirements"],
        }
        return [{"type": "text", "text": json.dumps(info, indent=2)}]

    else:
        return [
            {
                "type": "text",
                "text": json.dumps({"error": f"Unknown tool: {name}"}, indent=2),
            }
        ]


async def main():
    if not ZAI_CREDENTIAL:
        print(
            "Warning: ZAI_API_KEY not set. Server will fail on API calls.",
            file=sys.stderr,
        )

    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream, write_stream, server.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
