#!/bin/bash
set -e

echo "クラスターを削除しています..."
kind delete cluster --name gbc-product

echo "クラスターが削除されました" 