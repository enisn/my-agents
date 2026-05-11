# Z.AI Image MCP Server

An MCP (Model Context Protocol) server that provides image generation capabilities using Z.AI's image models. Supports both **GLM-Image** and **CogView-4** models with different capabilities and pricing.

## Features

- **Multi-Model Support**: Choose between GLM-Image or CogView-4
- **Multiple Resolutions**: Support for various aspect ratios and custom sizes
- **Quality Levels**: GLM-Image supports HD and Standard quality
- **Automatic Download**: Images are automatically downloaded to your project directory
- **Parameter Validation**: Validate prompts, sizes, and quality levels before generation
- **Bilingual Support**: CogView-4 supports Chinese and English prompts

## Models Comparison

| Feature | CogView-4 | GLM-Image |
|---------|-----------|------------|
| **Price** | $0.01/image ⭐ | $0.015/image |
| **Default** | ✅ Yes (Cheaper) | - |
| **Quality** | N/A | HD (~20s), Standard (~5-10s) |
| **Default Size** | 1024x1024 | 1280x1280 |
| **Custom Size Range** | 512-2048px | 1024-2048px |
| **Divisible By** | 16 | 32 |
| **Max Pixels** | 2^21 (2,097,152) | 2^22 (4,194,304) |
| **Language** | Chinese/English ⭐ | English |
| **Best For** | General use, text, bilingual | Text rendering, posters, diagrams |

## Installation

1. **Install Dependencies**:
```bash
pip install -r requirements.txt
```

2. **Set API Key**:
```bash
# On Linux/Mac
export ZAI_API_KEY='your-api-key-here'

# On Windows (PowerShell)
$env:ZAI_API_KEY='your-api-key-here'

# On Windows (Command Prompt)
set ZAI_API_KEY=your-api-key-here
```

Get your API key from: https://z.ai/manage-apikey/apikey-list

3. **Register with OpenCode**:
Add the following to your OpenCode MCP configuration (typically in `~/.config/opencode/mcp.json` or similar):

```json
{
  "mcpServers": {
    "zai-image-mcp": {
      "command": "python",
      "args": ["~/.config/opencode/mcp-servers/glm-image-mcp/server.py"],
      "env": {
        "ZAI_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

## Available Tools

### `generate_image`

Generate an image using Z.AI's image generation models.

**Parameters**:
- `prompt` (required): Text description of the image to generate
- `model` (optional): Model to use. Default: "cogView-4-250304" (cheaper)
  - `"cogView-4-250304"`: $0.01/image, bilingual, 512-2048px
  - `"glm-image"`: $0.015/image, better text rendering, 1024-2048px
- `size` (optional): Image dimensions (format: WIDTHxHEIGHT)
  - CogView-4 recommended: 1024x1024, 768x1344, 864x1152, 1344x768, 1152x864, 1440x720, 720x1440
  - GLM-Image recommended: 1280x1280, 1568x1056, 1056x1568, 1472x1088, 1088x1472, 1728x960, 960x1728
  - Custom: Use model-specific ranges and divisibility
- `quality` (optional): Image quality (GLM-Image only)
  - `"hd"`: Higher quality (~20 seconds)
  - `"standard"`: Faster generation (~5-10 seconds)
  - Ignored for CogView-4
- `save_path` (optional): Path to save the image. Default: "generated_image_{timestamp}.png"

**Returns**:
```json
{
  "success": true,
  "url": "https://...",
  "local_path": "/full/path/to/image.png",
  "model": "cogView-4-250304",
  "size": "1024x1024",
  "quality": null,
  "prompt": "A cute kitten...",
  "created_at": 1760335349
}
```

### `list_supported_models`

List all available image generation models with pricing and capabilities.

**Returns**: JSON with model information, pricing, default sizes, and requirements

### `list_supported_sizes`

List all supported image sizes for a model.

**Parameters**:
- `model` (optional): Model name. Default: "cogView-4-250304"

**Returns**: JSON with recommended sizes and custom size requirements

### `list_supported_qualities`

List all supported quality levels.

**Returns**: JSON with quality levels and descriptions (only for GLM-Image)

### `validate_image_params`

Validate image generation parameters before calling generate_image.

**Parameters**:
- `prompt` (optional): Prompt to validate
- `model` (optional): Model to validate
- `size` (optional): Size to validate (format: WIDTHxHEIGHT)
- `quality` (optional): Quality to validate

**Returns**: JSON with validation results, errors, and warnings

## Usage Examples

### Generate with default model (CogView-4, cheaper):
```
Use generate_image with prompt: "A cute kitten sitting on a sunny windowsill"
```

### Generate with GLM-Image (better for text):
```
Use generate_image with prompt: "Movie poster with title 'SUMMER 2025'" and model: "glm-image"
```

### Generate with specific size:
```
Use generate_image with prompt: "Sunset over mountains" and size: "1568x1056" and model: "glm-image"
```

### Generate faster with standard quality (GLM-Image):
```
Use generate_image with prompt: "Simple product photo" and quality: "standard" and model: "glm-image"
```

### Save to specific path:
```
Use generate_image with prompt: "Logo design" and save_path: "assets/logo.png"
```

### Bilingual prompt (CogView-4):
```
Use generate_image with prompt: "一只可爱的橘猫在阳光下打盹" (Chinese: "A cute orange cat napping in sunlight")
```

## Pricing

- **CogView-4**: $0.01 per image (default, cheaper)
- **GLM-Image**: $0.015 per image (better for text rendering)
- **URL Expiry**: Generated image URLs expire after 30 days
- **Resolution**: Supports 512px-2048px range (varies by model)

## Model Details

### CogView-4 (Default)
- SOTA open-source text-to-image model
- Bilingual support: Chinese and English prompts
- Any resolution support within range
- Excellent for general use and text generation
- 33% cheaper than GLM-Image

### GLM-Image
- Hybrid architecture: "autoregressive + diffusion decoder"
- Excellent at text rendering (posters, diagrams, etc.)
- Supports complex multi-panel drawings
- Good for commercial posters, science illustrations, social media graphics
- Higher quality modes available

## Troubleshooting

**Error: "ZAI_API_KEY environment variable not set"**
- Set the ZAI_API_KEY environment variable before starting the server
- Or add it to the MCP server configuration

**Error: "zai-sdk not installed"**
- Install with: `pip install zai-sdk`

**Error: "Model does not support quality parameter"**
- Only GLM-Image supports quality. CogView-4 ignores this parameter.

**Slow generation times**
- Use CogView-4 (default) for faster generation
- For GLM-Image, use quality="standard" for faster generation (5-10s vs 20s for HD)

**Invalid size errors**
- Check supported sizes with `list_supported_sizes` tool for your model
- Custom sizes must meet divisibility and pixel count requirements

## Documentation

- CogView-4 Guide: https://docs.z.ai/guides/image/cogview-4
- GLM-Image Guide: https://docs.z.ai/guides/image/glm-image
- API Reference: https://docs.z.ai/api-reference/image/generate-image
- Get API Key: https://z.ai/manage-apikey/apikey-list

## License

This MCP server is provided as-is for integration with Z.AI's image generation API.
