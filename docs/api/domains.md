## 🔐 Домены API

### `POST /domain`

Регистрирует новый домен (запускает майнинг).

#### Тело запроса
```json
{
  "name": "mydomain",
  "zone": "ruv",
  "data": {
    "records": [
      {
        "type": "A",
        "domain": "mydomain.ruv",
        "addr": "127.0.0.1",
        "ttl": 300
      }
    ],
    "info": "My personal domain",
    "contacts": [
      {
        "name": "email",
        "value": "me@example.com"
      }
    ]
  }
}
