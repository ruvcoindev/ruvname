#!/bin/sh

# Try to get version from GITHUB_REF first (CI)
if [ -n "${GITHUB_REF:-}" ]; then
  case "$GITHUB_REF" in
    refs/tags/v*)
      TAG="${GITHUB_REF#refs/tags/v}"
      printf '%s' "$TAG"
      exit 0
      ;;
    refs/heads/*)
      # Ветка, не тег
      BRANCH="${GITHUB_REF#refs/heads/}"
      ;;
  esac
fi

# Fallback: использовать git (локальная разработка)
TAG=$(git describe --abbrev=0 --tags --match="v[0-9]*.[0-9]*.[0-9]*" 2>/dev/null)
if [ $? = 0 ] && [ -n "$TAG" ]; then
  TAG="${TAG#v}"
else
  printf 'unknown'
  exit 0
fi

BRANCH=$(git symbolic-ref -q HEAD --short 2>/dev/null)
if [ $? != 0 ] || [ -z "$BRANCH" ]; then
  BRANCH="master"
fi

# Извлекаем MAJOR, MINOR, PATCH
MAJOR=$(echo "$TAG" | cut -d. -f1)
MINOR=$(echo "$TAG" | cut -d. -f2)
PATCH=$(echo "$TAG" | cut -d. -f3)

# Форматируем
if [ "$PATCH" -eq 0 ]; then
  printf '%d.%d' "$MAJOR" "$MINOR"
else
  printf '%d.%d.%d' "$MAJOR" "$MINOR" "$PATCH"
fi

# Добавляем билд-номер только если не на теге
if [ "$BRANCH" != "master" ] && [ "$BRANCH" != "main" ] && [ "$BRANCH" != "$TAG" ]; then
  BUILD=$(git rev-list --count "v$TAG..HEAD" 2>/dev/null)
  if [ $? = 0 ] && [ -n "$BUILD" ] && [ "$BUILD" -gt 0 ]; then
    printf '-%04d' "$BUILD"
  fi
fi
