## 🌐 DNS API

### `GET /resolve`

Разрешает доменное имя.

#### Параметры
- `name` (string) — домен, например `example.ruv`
- `type` (string, опционально) — тип записи: `A`, `AAAA`, `TXT`, `MX`, `CNAME`, `SRV`. По умолчанию: `A`

#### Пример
```http
GET /resolve?name=ya.ru.bit&type=A
