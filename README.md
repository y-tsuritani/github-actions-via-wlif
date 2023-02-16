# Workload Identity Federation

## 概要

GitHub が GitHub Actions ワークフローに OIDC トークンを導入したため、Workload Identity 連携を使用して GitHub Actions から Google Cloud に認証できる

### アーキテクチャ

![architecture_img](img/architecture.png)

## 構築の手順

Slack app を作成したことがない人でも作成できることを目指しているため、
Slack app の作成から Cloud Functions のデプロイまで細かく説明する。

### Slack app の作成

[Slack api](https://api.slack.com/) にアクセスして Slack app を作成してください。

![slack_create_app](img/slack_create_app.png)

from scratch を選択

![slack_create_from_scratch](img/slack_create_from_scrach.png)

Basic Information で Bots, Event Subscriptions, Permissions を設定

![slack_create_bot](img/slack_create_bot.png)

OAuth & Permissions で Bot User OAuth Token を発行する

![slack_OAuth_token](img/slack_outh_permissions.png)

Scopes でアプリが持つ権限を設定する
**Bot Token Scopes**

- app_mentions:read
- channels:history
- chat:write
- chat:write.customize
- groups:history

### OpenAI API キーの取得

[OpenAI の HP](https://platform.openai.com/) にアクセスして OpenAI API key を取得してください。

![openai_api_key](img/OpenAI_api_key.png)

### Cloud Functions のデプロイ

[Google Cloud Platform](https://console.cloud.google.com/?hl=JA) にアクセスして チュートリアルを参考にして Cloud Functions 関数を作成してください。

[公式ドキュメント：Cloud Functions のチュートリアル](https://cloud.google.com/functions/docs/tutorials/http?hl=ja)

`applications\davinci-bot\davinci-bot.zip` をアップロードすれば動作します。(環境変数の設定は以下参照)

API キーは Secret Manager に登録して環境変数を参照する形で利用します。

[公式ドキュメント：Cloud Functions でのシークレットの使用](https://cloud.google.com/functions/docs/configuring/secrets?hl=ja)

Cloud Functions の呼び出し URL を Slack app に設定する

![slack_event_url](img/slack_event_url.png)

Subscribe to bot events で **app_mention** を設定

## その他各種チュートリアル

### Terraform の活用

[GCP で terraform を利用するチュートリアル](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started)

[Terraform Cloud Functions をデプロイするチュートリアル（第 2 世代）](https://cloud.google.com/functions/docs/tutorials/terraform?hl=ja)

GitHub Actions を用いた CI/CD の実現

## API ドキュメント

### Slack

- [Slack Bolt 入門ガイド](https://slack.dev/bolt-python/ja-jp/tutorial/getting-started)
- [slack_bolt documentation](https://slack.dev/bolt-python/api-docs/slack_bolt/)
- [Standard app mention when your app is already in channel](https://api.slack.com/events/app_mention#app_mention-event__example-event-payloads__app-mention-that-invites-your-app-to-a-channel)

### GCP

### OpenAI API

- [OpenAI API Reference](https://platform.openai.com/docs/api-reference/introduction)
- [Authentication](https://platform.openai.com/docs/api-reference/authentication)
- [Completions](https://platform.openai.com/docs/api-reference/completions)

## Architecture Documentation

[Cloud Functions の概要](https://cloud.google.com/functions?hl=ja)
[Terraform registry (google_cloudfunctions2_function)](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudfunctions2_function)
