# xurl Docker環境

WSL2上のDockerコンテナで [xurl](https://github.com/xdevplatform/xurl) を動かし、**ホストのWindows**からOAuth2認証を完結させるための環境です。

## 前提条件

- Docker Desktop (WSL2バックエンド)
- X Developer Portal でアプリを作成済み
  - Callback URI: `http://localhost:8080/callback` を登録していること

## セットアップ

### 1. ビルド

```bash
docker compose build
```

### 2. アプリ情報を登録

コンテナを起動してアプリのClient ID / Client Secretを登録します。

```bash
docker compose run --service-ports xurl
```

コンテナ内で:

```bash
xurl auth apps add my-app --client-id xxxx --client-secret yyyy
```

### 3. OAuth2認証

コンテナ内で:

```bash
xurl auth oauth2 --app my-app
```

表示されたURLをWindowsブラウザで開き、Xアカウントで認証してください。
認証後にブラウザが `http://localhost:8080/callback?...` へリダイレクトされ、自動的にトークンが `~/.xurl` に保存されます。

### 4. APIリクエスト

```bash
# タイムライン取得
xurl /2/tweets/search/recent?query=hello

# ツイート投稿
xurl -X POST /2/tweets -d '{"text":"Hello from xurl!"}'
```

## ディレクトリ構成

```
.
├── Dockerfile          # xurl + socat + iproute2
├── entrypoint.sh       # OAuthコールバック中継スクリプト
└── docker-compose.yml
```

## 仕組み: なぜ entrypoint.sh が必要か

xurl のOAuthコールバックサーバーはコンテナ内の `127.0.0.1:8080` にbindします。
一方、DockerのポートマッピングはWindowsからのパケットをコンテナの `eth0` IPに転送するため、`127.0.0.1` には届きません。

`entrypoint.sh` は `socat` を使って `eth0:8080` で受けたトラフィックを `127.0.0.1:8080` へ中継することでこの問題を解決しています。

```
Windowsブラウザ → localhost:8080
    → (Docker DNAT) → コンテナ eth0:8080
    → (socat 中継)  → 127.0.0.1:8080
    → xurl コールバックサーバー
```

## VPSへの移行

VPS上で

```
npm install -g @xdevplatform/xurl
xurl auth apps add myapp --client-id xxxx --client-secret yyyy
vim ~/.xurl # コンテナで生成された.xurlの内容で上書き
```
