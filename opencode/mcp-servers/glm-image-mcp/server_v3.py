#!/usr/bin/env python3
"""
MCP Server for Z.AI Image Generation API
Provides image generation capabilities using Z.AI's GLM-Image and CogView-4 models.
"""

import json
import os
import sys
import concurrent.futures
import requests
from pathlib import Path

try:
    from mcp.server.fastmcp import FastMCP
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


# Initialize MCP server
mcp = FastMCP("zai-image-mcp")

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

_executor = concurrent.futures.ThreadPoolExecutor(max_workers=4)


def run_in_thread(func, *args, **kwargs):
    """Run a blocking function in a thread pool to avoid asyncio event loop conflicts."""
    future = _executor.submit(func, *args, **kwargs)
    return future.result()


def get_client():
    """Get authenticated Z.AI client."""
    if not ZAI_CREDENTIAL:
        raise ValueError("ZAI_API_KEY environment variable not set")
    return ZaiClient(api_key=ZAI_CREDENTIAL)


def generate_image_in_thread(model: str, prompt: str, size: str, quality: str = None):
    """Generate image using ZAI SDK in a thread to avoid asyncio event loop conflicts."""
    import asyncio

    # Create a new event loop for this thread to avoid conflicts
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        client = get_client()
        if quality:
            return client.images.generations(
                model=model, prompt=prompt, size=size, quality=quality
            )
        else:
            return client.images.generations(model=model, prompt=prompt, size=size)
    finally:
        loop.close()


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


def download_image_sync(url: str, output_path: Path) -> Path:
    """Download image from URL to local path (synchronous version)."""
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(response.content)
    return output_path


@mcp.tool()
def generate_image(
    prompt: str,
    model: str = DEFAULT_MODEL,
    size: str = None,
    quality: str = None,
    save_path: str = None,
) -> str:
    """
    Generate an image using Z.AI's image generation models.

    Args:
        prompt: Text description of image to generate
        model: Model to use. Options: "glm-image" ($0.015/image), "cogView-4-250304" ($0.01/image, default). CogView-4 is cheaper and supports Chinese/English.
        size: Image dimensions (format: WIDTHxHEIGHT). If not provided, uses model default.
               - CogView-4 recommended: 1024x1024, 768x1344, 864x1152, 1344x768, 1152x864, 1440x720, 720x1440
               - GLM-Image recommended: 1280x1280, 1568x1056, 1056x1568, 1472x1088, 1088x1472, 1728x960, 960x1728
        quality: Image quality (only for glm-image). 'hd' for higher quality (~20s), 'standard' for faster (~5-10s). Ignored for CogView-4.
        save_path: Optional path to save image. If not provided, saves as 'generated_image_{timestamp}.png' in current directory

    Returns:
        JSON string with image URL, local path (if saved), and metadata
    """
    try:
        if not prompt:
            raise ValueError("Prompt cannot be empty")

        if model not in MODEL_CONFIGS:
            available = ", ".join(MODEL_CONFIGS.keys())
            raise ValueError(f"Invalid model: {model}. Available models: {available}")

        config = MODEL_CONFIGS[model]

        if size is None:
            size = config["default_size"]

        if not validate_size(size, model):
            raise ValueError(
                f"Invalid size: {size} for model {model}. "
                f"Recommended: {', '.join(config['recommended_sizes'])}. "
                f"Custom: {config['custom_size_requirements']}"
            )

        if config["has_quality"]:
            if quality is None:
                quality = config["default_quality"]
            elif quality not in VALID_QUALITIES:
                raise ValueError(
                    f"Invalid quality. Must be one of: {', '.join(VALID_QUALITIES)}"
                )
        else:
            if quality is not None:
                return json.dumps(
                    {
                        "success": False,
                        "error": f"Model {model} does not support quality parameter",
                        "error_type": "ValueError",
                    },
                    indent=2,
                )
            quality = None

        # Generate image - run in thread to avoid asyncio conflict
        response = run_in_thread(generate_image_in_thread, model, prompt, size, quality)

        image_url = response.data[0].url
        created = response.created

        if save_path:
            output_path = Path(save_path)
        else:
            output_path = Path(f"generated_image_{created}.png")

        # Use synchronous download instead of asyncio.run
        download_image_sync(image_url, output_path)

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

        return json.dumps(result, indent=2)

    except Exception as e:
        error_result = {
            "success": False,
            "error": str(e),
            "error_type": type(e).__name__,
        }
        return json.dumps(error_result, indent=2)


@mcp.tool()
def list_supported_models() -> str:
    """
    List all available image generation models.

    Returns:
        JSON string with model information, pricing, and capabilities
    """
    models_info = []
    for model_id, config in MODEL_CONFIGS.items():
        model_info = {
            "model": model_id,
            "name": config["name"],
            "price": config["price"],
            "description": config["description"],
            "default_size": config["default_size"],
            "supports_quality": config["has_quality"],
            "recommended_sizes": config["recommended_sizes"],
            "custom_size_requirements": config["custom_size_requirements"],
        }
        if model_id == DEFAULT_MODEL:
            model_info["is_default"] = True
        models_info.append(model_info)

    return json.dumps(models_info, indent=2)


@mcp.tool()
def list_supported_sizes(model: str = None) -> str:
    """
    List all supported image sizes for a model.

    Args:
        model: Optional model name. If not provided, shows sizes for default model.

    Returns:
        JSON string with recommended sizes and custom size requirements
    """
    if model is None:
        model = DEFAULT_MODEL

    if model not in MODEL_CONFIGS:
        available = ", ".join(MODEL_CONFIGS.keys())
        return json.dumps(
            {"error": f"Invalid model: {model}. Available models: {available}"},
            indent=2,
        )

    config = MODEL_CONFIGS[model]
    info = {
        "model": model,
        "recommended_sizes": config["recommended_sizes"],
        "custom_size_requirements": config["custom_size_requirements"],
    }
    return json.dumps(info, indent=2)


@mcp.tool()
def list_supported_qualities() -> str:
    """
    List all supported quality levels.

    Returns:
        JSON string with quality levels and descriptions
    """
    info = {
        "note": "Quality parameter only supported by glm-image model",
        "qualities": [
            {
                "value": "hd",
                "description": "Higher quality, more detailed image (~20 seconds)",
                "default": True,
            },
            {
                "value": "standard",
                "description": "Faster generation, suitable for speed requirements (~5-10 seconds)",
                "default": False,
            },
        ],
    }
    return json.dumps(info, indent=2)


@mcp.tool()
def validate_image_params(
    prompt: str = None, model: str = None, size: str = None, quality: str = None
) -> str:
    """
    Validate image generation parameters before calling generate_image.

    Args:
        prompt: Optional prompt to validate
        model: Optional model to validate
        size: Optional size to validate (format: WIDTHxHEIGHT)
        quality: Optional quality to validate

    Returns:
        JSON string with validation results
    """
    validation = {"valid": True, "errors": [], "warnings": []}

    if model is None:
        model = DEFAULT_MODEL

    if model not in MODEL_CONFIGS:
        validation["valid"] = False
        validation["errors"].append(
            f"Invalid model: {model}. Available: {', '.join(MODEL_CONFIGS.keys())}"
        )
    else:
        config = MODEL_CONFIGS[model]

        if size is not None:
            if not validate_size(size, model):
                validation["valid"] = False
                validation["errors"].append(f"Invalid size: {size} for model {model}")

        if quality is not None:
            if not config["has_quality"]:
                validation["warnings"].append(
                    f"Model {model} does not support quality parameter (ignored)"
                )
            elif quality not in VALID_QUALITIES:
                validation["valid"] = False
                validation["errors"].append(
                    f"Invalid quality: {quality}. Must be one of: {', '.join(VALID_QUALITIES)}"
                )

    if prompt is not None:
        if not prompt.strip():
            validation["valid"] = False
            validation["errors"].append("Prompt cannot be empty")
        elif len(prompt) < 10:
            validation["warnings"].append(
                "Prompt is very short, consider adding more details"
            )

    if not validation["errors"] and not validation["warnings"]:
        validation["message"] = "All parameters are valid"

    return json.dumps(validation, indent=2)


if __name__ == "__main__":
    if not ZAI_CREDENTIAL:
        print(
            "Warning: ZAI_API_KEY not set. Server will fail on API calls.",
            file=sys.stderr,
        )

    mcp.run()
