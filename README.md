# RUVNAME — Decentralized DNS on Blockchain

**RUVNAME** — это децентрализованная система доменных имён (DNS), построенная на основе **лёгкой медленно растущей блокчейн-сети**.
Она позволяет регистрировать и разрешать домены вроде .ruv .mesh .node .dnet .p2p .tamb .tmb .dweb .dht .hub без централизованных органов.

> 🔐 Безопасно. 🌐 Децентрализовано. 💻 Поддержка Linux, Windows, macOS.

---

## 🚀 Быстрый старт

### 1. Скачайте последнюю версию

👉 Перейдите в [Releases](https://github.com/ruvcoindev/ruvname/releases)

Выберите сборку под вашу ОС:
- **Linux**: `ruvname-linux-amd64-v0.1.0-nogui.deb`
- **Windows**: `ruvname-windows-x64-v0.1.0-gui.zip`
- **macOS**: `ruvname-macos-universal-v0.1.0-nogui.dmg`

### 2. Установите

#### Linux (Debian/Ubuntu)
```bash
sudo dpkg -i ruvname-linux-amd64-v0.1.0-nogui.deb
sudo systemctl enable ruvname
sudo systemctl start ruvname

Windows
Распакуйте архив
Запустите ruvname.exe
Используйте веб-интерфейс на http://localhost:5311
macOS
Откройте .dmg → перетащите в Applications

Сборка из исходников
Требования
Rust 1.89+
musl-tools, pkg-config, libglib2.0-dev, libwebkit2gtk-4.0-dev (Linux)
upx (опционально, для сжатия)

Собрать вручную

git clone https://github.com/ruvcoindev/ruvname.git
cd ruvname
cargo build --release --features="doh"

Собрать с GUI (только Windows)

cargo build --release --features="webgui"

Мультиархитектурная сборка (Linux, Windows, macOS)

make release

Создаст .deb, .zip, .dmg в папках bin/deb/, bin/win/, bin/macos/.

Конфигурация
После первого запуска создастся ruvname.toml.

Основные настройки

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

📁 Конфиг по умолчанию: /etc/ruvname.conf (Linux), ruvname.toml (в папке с .exe на Windows) 

Использование
1. Настройка DNS
Укажите в системе DNS:

127.0.0.1#5311

Или проверьте:

dig @127.0.0.1 -p 5311 ya.ru.bit

2. Веб-интерфейс (Windows GUI)
После запуска откройте:

http://localhost:5311

Там вы сможете:

Просмотреть блокчейн
Зарегистрировать домен
Проверить статус узла

3. Автозапуск (systemd)
На Linux:

sudo systemctl enable ruvname
sudo systemctl status ruvname

Как это работает?
Блокчейн хранит записи о доменах
P2P-сеть на порту 6890 (IPv6/IPv4)
DNS-сервер на 127.0.0.1:5311 — разрешает .bit и пересылает обычные запросы
Майнинг — для регистрации доменов (proof-of-work)

Разработка
Запуск в режиме разработки

cargo run -- --debug

Генерация конфига

./ruvname -g > ruvname.toml

Автоматические обновления
Включены по умолчанию. Проверяются через GitHub API.

📂 Структура проекта

ruvname/
├── src/
│   ├── main.rs        # Точка входа
│   ├── blockchain/    # Цепочка, майнинг
│   ├── dns/           # DNS-сервер и DoH
│   ├── p2p/           # Сеть узлов
│   └── web_ui/        # Веб-интерфейс (GUI)
├── contrib/deb/       # Скрипты сборки
├── ruvname.toml       # Пример конфига
└── Makefile           # Упрощённые команды

🤝 Вклад в проект
Приветствуются:

Исправления багов
Новые фичи
Документация
Тесты
Форкните репозиторий
Создайте ветку feature/... или fix/...
Сделайте pull request
Лицензия
MIT — см. файл LICENSE

📬 Поддержка
GitHub Issues: Сообщить об ошибке
Сайт: https://ruv.name

🔗 RUVNAME — часть экосистемы RUVchain 
