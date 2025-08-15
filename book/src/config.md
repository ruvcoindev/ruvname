## 🔧 Конфигурация

Файл: `/etc/ruvname.conf` (Linux) или `ruvname.toml` (Windows)

### Пример
```toml
[net]
peers = ["[fa00:4715:66fa:2bd:3032:b5d1:e86f:239c]:6890"]
listen = "[::]:6890"
public = true

[dns]
listen = "127.0.0.1:5311"
forwarders = ["https://dns.adguard.com/dns-query"]
bootstraps = ["9.9.9.9:53", "94.140.14.14:53"]

[mining]
threads = 0
lower = true
