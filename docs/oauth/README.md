# Diffusion Studio local integration

This folder hosts public OAuth client metadata for ELPROFUG0's locally customized Diffusion Studio editor. It is not an official Diffusion Studio service or an Orbe feature.

The desktop app connects directly to ElevenLabs through its official ElevenCreative MCP server. Authorization returns to the app's loopback callback at `http://127.0.0.1:49172/callback`, using authorization code with PKCE. This static site receives no authorization codes, account tokens or generated media. Credentials remain encrypted on the user's device.

Client metadata: https://elprofug0.github.io/orbe/oauth/diffusion-studio.json

To disconnect, use the editor's Plugins integration settings. Access may also be revoked in ElevenLabs account settings.
