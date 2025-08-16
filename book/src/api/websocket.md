cat > book/src/api/websocket.md << 'EOF'
## 🔄 WebSocket (UI Events)

`ruvname` использует **односторонний канал** через `window.external.invoke()` (в `web-view`) для отправки событий в GUI.

### Пример события
```json
{
  "event": "block_mined",
  "data": {
    "height": 150,
    "hash": "a1b2c3..."
  }
}