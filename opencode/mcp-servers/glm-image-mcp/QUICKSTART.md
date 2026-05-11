# Quick Start Guide

## Step 1: Install Dependencies
```bash
pip install -r requirements.txt
```

## Step 2: Get API Key
1. Go to https://z.ai/manage-apikey/apikey-list
2. Create a new API key
3. Copy your API key

## Step 3: Configure API Key
Edit `~/.config/opencode/opencode.jsonc` and add your API key:

```json
"zai-image-mcp": {
  "type": "local",
  "command": ["python", "C:\\Users\\enisn\\.config\\opencode\\mcp-servers\\glm-image-mcp\\server.py"],
  "enabled": true,
  "env": {
    "ZAI_API_KEY": "your-actual-api-key-here"
  }
}
```

## Step 4: Restart OpenCode
The MCP server will start automatically when OpenCode launches.

## Models Available

### CogView-4 (Default) ⭐
- **Price**: $0.01/image (cheaper)
- **Best for**: General use, text, bilingual
- **Size**: 1024x1024 (default), 512-2048px custom
- **Language**: Chinese & English

### GLM-Image
- **Price**: $0.015/image
- **Best for**: Text rendering, posters, diagrams
- **Size**: 1280x1280 (default), 1024-2048px custom
- **Quality**: HD (20s) or Standard (5-10s)

## Usage Examples

### Generate with default model (CogView-4, cheaper):
```
Use generate_image with prompt: "A cute cat sitting on a windowsill"
```

### Generate with GLM-Image (better for text):
```
Use generate_image with prompt: "Poster with title 'SUMMER SALE'" and model: "glm-image"
```

### Generate with specific size:
```
Use generate_image with prompt: "Sunset over mountains" and size: "1568x1056" and model: "glm-image"
```

### Generate faster (GLM-Image):
```
Use generate_image with prompt: "Simple product" and quality: "standard" and model: "glm-image"
```

### Save to specific path:
```
Use generate_image with prompt: "Logo design" and save_path: "assets/logo.png"
```

### Compare models:
```
Use list_supported_models to see all available models
```

## Available Tools

- **generate_image**: Create images from text prompts (supports both models)
- **list_supported_models**: View models, pricing, and capabilities
- **list_supported_sizes**: View valid image dimensions per model
- **list_supported_qualities**: View quality options (GLM-Image only)
- **validate_image_params**: Check parameters before generation

## Cost & Limits

- **CogView-4**: $0.01/image (default)
- **GLM-Image**: $0.015/image
- **URL expiry**: 30 days
- **Resolution**: 512-2048px (varies by model)

## Quick Tips

- **Use CogView-4** for cheaper, faster, bilingual generation (default)
- **Use GLM-Image** for better text rendering in images
- **Use Standard quality** with GLM-Image for 2x faster generation
- **Validate first**: Use `validate_image_params` to check inputs

## Troubleshooting

**API Key Error**
```
Error: ZAI_API_KEY environment variable not set
```
Solution: Add your API key to the MCP configuration

**Quality Parameter Error**
```
Model does not support quality parameter
```
Solution: CogView-4 doesn't support quality. Remove it or use GLM-Image.

**Size Error**
Check supported sizes with `list_supported_sizes model:"your-model"` tool

**Slow Generation**
- CogView-4 is faster (default)
- GLM-Image Standard quality is faster than HD
