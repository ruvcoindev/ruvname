#!/usr/bin/env python3
# Пример работы с API RUVNAME
# Тестировано с ruvname v0.1.0

import requests
import json
import sys
from typing import Dict, Any, Optional

BASE_URL = "http://127.0.0.1:5311"

# === Функции API ===

def resolve(name: str, qtype: str = "A") -> Dict[str, Any]:
    """Разрешить доменное имя."""
    try:
        resp = requests.get(f"{BASE_URL}/resolve", params={"name": name, "type": qtype}, timeout=10)
        resp.raise_for_status()
        return resp.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Ошибка при запросе /resolve: {e}")
        return {"status": "error", "message": str(e)}

def get_status() -> Dict[str, Any]:
    """Получить статус узла."""
    try:
        resp = requests.get(f"{BASE_URL}/status", timeout=10)
        resp.raise_for_status()
        return resp.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Ошибка при запросе /status: {e}")
        return {"status": "error", "message": str(e)}

def create_key() -> Dict[str, Any]:
    """Создать новый ключ."""
    try:
        resp = requests.post(f"{BASE_URL}/new_key", timeout=10)
        resp.raise_for_status()
        return resp.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Ошибка при создании ключа: {e}")
        return {"status": "error", "message": str(e)}

def register_domain(
    name: str,
    zone: str = "ruv",
    ip: str = "127.0.0.1",
    info: str = "",
    contacts: Optional[list] = None,
    renewal: bool = False
) -> Dict[str, Any]:
    """
    Зарегистрировать домен (начать майнинг).
    """
    if contacts is None:
        contacts = []

    data = {
        "name": name,
        "zone": zone,
        "data": {
            "records": [
                {
                    "type": "A",
                    "domain": f"{name}.{zone}",
                    "addr": ip,
                    "ttl": 300
                }
            ],
            "info": info or f"Domain {name}.{zone}",
            "contacts": contacts
        },
        "renewal": renewal
    }

    try:
        resp = requests.post(f"{BASE_URL}/domain", json=data, timeout=30)
        resp.raise_for_status()
        return resp.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Ошибка при регистрации домена: {e}")
        return {"status": "error", "message": str(e)}

# === Пример использования ===

if __name__ == "__main__":
    print("📡 Проверка подключения к RUVNAME...")
    status = get_status()
    print("📊 Статус узла:", json.dumps(status, indent=2))

    if status.get("status") == "error":
        print("❌ Не удалось подключиться к API. Убедитесь, что ruvname запущен.")
        sys.exit(1)

    print("\n🔍 Разрешение ya.ru.bit...")
    result = resolve("ya.ru.bit")
    print("✅ Ответ:", json.dumps(result, indent=2))

    print("\n🔐 Создание нового ключа...")
    key = create_key()
    print("✅ Ключ:", json.dumps(key, indent=2))

    # ❗ Раскомментируйте, чтобы зарегистрировать домен
    # print("\n⛏️  Регистрация домена...")
    # domain = register_domain("mytest", zone="ruv", ip="127.0.0.1", info="Test domain")
    # print("✅ Регистрация:", json.dumps(domain, indent=2))
