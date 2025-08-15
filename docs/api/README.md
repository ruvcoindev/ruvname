# 📚 API Документация RUVNAME

Этот раздел описывает **внутренний HTTP API**, используемый веб-интерфейсом `ruvname` для взаимодействия с локальным узлом.

> 🔐 API доступен только по `localhost` (по умолчанию: `http://127.0.0.1:5311`)

---

## 🧩 Доступные эндпоинты

| Модуль | Эндпоинты |
|-------|----------|
| 🌐 DNS | `GET /dns-query` (DoH), `GET /resolve` |
| 🔐 Домены | `POST /domain`, `GET /domains`, `GET /domain/{name}` |
| ⛏️ Майнинг | `POST /start_mining`, `POST /stop_mining` |
| 🔑 Ключи | `POST /new_key`, `GET /keys` |
| 📊 Статистика | `GET /status`, `GET /stats` |
| 🧾 Блокчейн | `GET /blocks`, `GET /block/{height}` |

---

## 🔐 Безопасность

- Все вызовы инициируются через `window.external.invoke()` в `web-view`
- Нет аутентификации (доступ только с локальной машины)
- Не открывайте порт `5311` в интернет

---

## 🚀 Как включить API

API включено по умолчанию.  
Порт задаётся в `ruvname.toml`:

```toml
[dns]
listen = "127.0.0.1:5311"
enable_api = true  # ← по умолчанию true

🧪 Пример использования (cURL)

curl -X POST http://127.0.0.1:5311/start_mining
curl "http://127.0.0.1:5311/resolve?name=ya.ru.bit&type=A"


## 🌐 DNS API

### `GET /resolve`

Разрешает доменное имя.

#### Параметры
- `name` (string) — домен, например `example.ruv`
- `type` (string, опционально) — тип записи: `A`, `AAAA`, `TXT`, `MX`, `CNAME`, `SRV`. По умолчанию: `A`

#### Пример
```http
GET /resolve?name=ya.ru.bit&type=A

Ответ (успех)

{
  "status": "ok",
  "answer": [
    {
      "name": "ya.ru.bit",
      "type": "A",
      "ttl": 300,
      "data": "87.250.250.242"
    }
  ]
}

Ответ (ошибка)

{
  "status": "error",
  "message": "Domain not found"
}

GET /dns-query (DoH)
DNS-over-HTTPS — совместим с RFC 8484.

Пример

GET /dns-query?dns=AAABAAABAAAAAAAAAWEFZXhhbXBsZQNydXYAABcAHg==

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

Ответ

{
  "status": "mining_started",
  "domain": "mydomain.ruv"
}


# 📚 API Документация RUVNAME

Этот раздел описывает **внутренний HTTP API**, используемый веб-интерфейсом `ruvname` для взаимодействия с локальным узлом.

> 🔐 API доступен только по `localhost` (по умолчанию: `http://127.0.0.1:5311`)

---

## 🧩 Доступные эндпоинты

| Модуль | Эндпоинты |
|-------|----------|
| 🌐 DNS | `GET /dns-query` (DoH), `GET /resolve` |
| 🔐 Домены | `POST /domain`, `GET /domains`, `GET /domain/{name}` |
| ⛏️ Майнинг | `POST /start_mining`, `POST /stop_mining` |
| 🔑 Ключи | `POST /new_key`, `GET /keys` |
| 📊 Статистика | `GET /status`, `GET /stats` |
| 🧾 Блокчейн | `GET /blocks`, `GET /block/{height}` |

---

## 🔐 Безопасность

- Все вызовы инициируются через `window.external.invoke()` в `web-view`
- Нет аутентификации (доступ только с локальной машины)
- Не открывайте порт `5311` в интернет

---

## 🚀 Как включить API

API включено по умолчанию.  
Порт задаётся в `ruvname.toml`:

```toml
[dns]
listen = "127.0.0.1:5311"
enable_api = true  # ← по умолчанию true
🧪 Пример использования (cURL)

bash

curl -X POST http://127.0.0.1:5311/start_mining
curl "http://127.0.0.1:5311/resolve?name=ya.ru.bit&type=A"
⚠️ Веб-интерфейс использует window.external.invoke(JSON.stringify({cmd: 'start_mining'})), а не прямые HTTP-запросы. 



## ✅ Файл: `docs/api/dns.md`

```markdown
## 🌐 DNS API

### `GET /resolve`

Разрешает доменное имя.

#### Параметры
- `name` (string) — домен, например `example.ruv`
- `type` (string, опционально) — тип записи: `A`, `AAAA`, `TXT`, `MX`, `CNAME`, `SRV`. По умолчанию: `A`

#### Пример
```http
GET /resolve?name=ya.ru.bit&type=A
Ответ (успех)

{
  "status": "ok",
  "answer": [
    {
      "name": "ya.ru.bit",
      "type": "A",
      "ttl": 300,
      "data": "87.250.250.242"
    }
  ]
}
Ответ (ошибка)

{
  "status": "error",
  "message": "Domain not found"
}
GET /dns-query (DoH)
DNS-over-HTTPS — совместим с RFC 8484.

Пример

GET /dns-query?dns=AAABAAABAAAAAAAAAWEFZXhhbXBsZQNydXYAABcAHg==
Используется в forwarders для upstream-запросов. 

---

## ✅ Файл: `docs/api/domains.md`

```markdown
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
Ответ

{
  "status": "mining_started",
  "domain": "mydomain.ruv"
}
GET /domains
Возвращает список доменов, принадлежащих вашему ключу.

Ответ

[
  {
    "name": "mydomain.ruv",
    "timestamp": 1723700000,
    "confirmation": "a1b2c3...",
    "data": "{...}",
    "signing": "d4e5f6...",
    "encryption": "g7h8i9..."
  }
]

GET /domain/{name}

Получить данные о домене.

{
  "name": "mydomain.ruv",
  "owner": "a1b2c3...",
  "records": [...],
  "info": "...",
  "contacts": [...]
}

## ⛏️ Майнинг API

### `POST /start_mining`

Запускает майнинг доменов.

#### Тело (опционально)
```json
{
  "threads": 4
}

Ответ

{ "status": "mining_started" }

POST /stop_mining
Останавливает майнинг.

Ответ

{ "status": "mining_stopped" }

GET /status
Возвращает статус узла.

Ответ

{
  "mining": true,
  "syncing": false,
  "synced_blocks": 150,
  "sync_height": 150,
  "max_diff": 24,
  "speed": 125000,
  "peers": 3,
  "version": "0.1.0"
}

## 🔑 Ключи API

### `POST /new_key`

Создаёт новый кошелёк.

#### Ответ
```json
{
  "status": "key_created",
  "file": "keys/key1.json",
  "address": "a1b2c3d4e5..."
}

GET /keys
Возвращает список загруженных ключей.

[
  {
    "file": "keys/key1.json",
    "address": "a1b2c3d4e5...",
    "domains": 2
  }
]

## 📦 Блокчейн API

### `GET /blocks`

Возвращает последние блоки.

#### Параметры
- `limit` (int, опционально) — количество, по умолчанию 10
- `offset` (int, опционально) — смещение

#### Ответ
```json
[
  {
    "height": 150,
    "hash": "a1b2c3...",
    "timestamp": 1723700000,
    "tx_count": 1,
    "difficulty": 24
  }
]

GET /block/{height}
Получить блок по высоте.

Ответ

{
  "height": 150,
  "hash": "a1b2c3...",
  "prev_hash": "z9y8x7...",
  "timestamp": 1723700000,
  "transactions": [
    {
      "type": "DomainCreation",
      "data": "..."
    }
  ],
  "nonce": 123456,
  "difficulty": 24
}

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

Поддерживаемые события
block_mined
domain_registered
mining_started
peer_connected
error

⚠️ Настоящий WebSocket-сервер не используется. Это симуляция через external.invoke(). 

📚 [API Документация](docs/api/README.md)
