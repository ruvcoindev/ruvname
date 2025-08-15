#!/usr/bin/env python3
# Пример работы с API RUVNAME

import requests
import json

BASE_URL = "http://127.0.0.1:5311"

def resolve(name, qtype="A"):
    """Разрешить доменное имя"""
    resp = requests.get(f"{BASE_URL}/resolve", params={"name": name, "type": qtype})
    return resp.json()

def get_status():
    """Получить статус узла"""
    resp = requests.get(f"{BASE_URL}/status")
    return resp.json()

def create_key():
    """Создать новый ключ"""
    resp = requests.post(f"{BASE_URL}/new_key")
    return resp.json()

def register_domain(name, zone="ruv", ip="127.0.0.1"):
    """Зарегистрировать домен"""
    data = {
        "name": name,
        "zone": zone,
        "data": {
            "records": [
                {"type": "A", "domain": f"{name}.{zone}", "addr": ip, "ttl": 300}
            ],
            "info": f"Domain {name}.{zone}"
        }
    }
    resp = requests.post(f"{BASE_URL}/domain", json=data)
    return resp.json()

def start_mining(threads=0):
    """Запустить майнинг"""
    data = {"threads": threads}
    resp = requests.post(f"{BASE_URL}/start_mining", json=data)
    return resp.json()

# === Пример использования ===
if __name__ == "__main__":
    print("📡 Статус узла:", get_status())
    print("🔍 ya.ru.bit:", resolve("ya.ru.bit"))
    
    # print("🔑 Создаём ключ:", create_key())
    # print("⛏️  Запускаем майнинг:", start_mining(2))
    # print("🌐 Регистрируем домен:", register_domain("mytest", "ruv"))
