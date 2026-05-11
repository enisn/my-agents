# Z.AI Image MCP Server - Setup Complete

## Summary

Your Z.AI Image MCP server is now created and configured! It supports both **GLM-Image** and **CogView-4** models.

## What Was Created

```
~/.config/opencode/mcp-servers/glm-image-mcp/
├── server.py          # Main MCP server implementation (supports both models)
├── requirements.txt   # Python dependencies
├── README.md          # Full documentation
├── QUICKSTART.md      # Quick start guide
└── SUMMARY.md         # This file
```

## Configuration Updated

The MCP server has been added to your OpenCode configuration:
- **File**: `~/.config/opencode/opencode.jsonc`
- **Server Name**: `glm-image-mcp`
- **Status**: Enabled with API key configured

## Models Available

### CogView-4 (Default) ⭐
- **Price**: $0.01/image (33% cheaper!)
- **Default size**: 1024x1024
- **Language**: Chinese & English
- **Best for**: General use, text generation, bilingual needs
- **No quality parameter** (faster generation)

### GLM-Image
- **Price**: $0.015/image
- **Default size**: 1280x1280
- **Quality**: HD (~20s) or Standard (~5-10s)
- **Language**: English
- **Best for**: Text rendering, posters, diagrams, multi-panel drawings

## Quick Comparison

| Feature | CogView-4 | GLM-Image |
|---------|-----------|------------|
| Price | $0.01 ⭐ | $0.015 |
| Default | ✅ Yes | - |
| Quality options | No | HD/Standard |
| Language | CN/EN ⭐ | EN |
| Text rendering | Good | Better ⭐ |
| Size range | 512-2048px | 1024-2048px |
| Divisible by | 16 | 32 |

## Next Steps

1. **Restart OpenCode** if not already done

2. **Test the server** with a simple prompt:
   ```
   Generate a test image: "A blue circle on white background"
   ```

3. **Compare models** to see which works best:
   ```
   Use list_supported_models to see all options
   ```

## Available Tools

| Tool | Purpose |
|------|---------|
| `generate_image` | Create images from prompts (supports both models) |
| `list_supported_models` | View models, pricing, and capabilities |
| `list_supported_sizes` | View valid dimensions per model |
| `list_supported_qualities` | View quality options (GLM-Image only) |
| `validate_image_params` | Check parameters before generation |

## Usage Examples

### Default model (CogView-4, cheaper):
```
Generate an image of: "A modern tech startup office with collaborative workspace"
```

### GLM-Image (better for text):
```
Generate an image using GLM-Image: "Movie poster with large bold text 'ADVENTURE AWAITS'"
```

### With specific size:
```
Generate a 1568x1056 image: "Landscape photograph of mountains at sunset"
```

### Save to specific location:
```
Generate and save to assets/hero.png: "Website hero section illustration"
```

## Pricing Summary

- **CogView-4**: $0.01/image (default, recommended)
- **GLM-Image**: $0.015/image (use for text-heavy images)
- **URL Expiry**: 30 days (images are saved locally)

## Key Advantages

✅ **Cost Savings**: Default model is 33% cheaper ($0.01 vs $0.015)
✅ **Flexibility**: Choose model based on use case
✅ **Bilingual**: CogView-4 supports Chinese and English
✅ **Validation**: Check parameters before generation
✅ **Auto-download**: Images saved automatically to project

## Testing

Once OpenCode is restarted, try:

```
Generate a simple test image: "A cute cartoon cat"
```

This should create a file like `generated_image_1234567890.png` in your current directory using the default CogView-4 model.

## Switch to GLM-Image

If you need better text rendering:

```
Generate with GLM-Image: "Professional presentation slide with clear title and bullet points"
```

Or validate first:

```
Check if GLM-Image supports my size requirements
```

## Support

- Full documentation: See `README.md`
- Quick start guide: See `QUICKSTART.md`
- CogView-4 docs: https://docs.z.ai/guides/image/cogview-4
- GLM-Image docs: https://docs.z.ai/guides/image/glm-image
- API Reference: https://docs.z.ai/api-reference/image/generate-image

## API Key

The API key is configured via `ZAI_API_KEY` in `~/.config/opencode/opencode.jsonc`. Do not store literal API keys in this summary.
