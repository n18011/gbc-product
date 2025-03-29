FROM nginx:alpine

# ビルド引数
ARG APP_ENV=production

# 環境変数
ENV APP_ENV=${APP_ENV}

# Nginxの設定ファイルをコピー
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# アプリケーションファイルをコピー
COPY ./app/index.html /usr/share/nginx/html

# ヘルスチェックのためのエンドポイント
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"] 