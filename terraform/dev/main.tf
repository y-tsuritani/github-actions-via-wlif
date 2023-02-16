provider "google" {
  project = var.project_id
  region  = var.region
}

# 使用するサービスアカウント
resource "google_service_account" "func_service_account" {
  account_id   = "sa-name"
  display_name = "sa_name"
  project      = var.project_id
  description  = "Cloud Functions が使用するサービスアカウント"
}

#### Cloud Functions 関連（デプロイ用 zip ファイルの作成）
# Cloud Functions デプロイ用にソースコード zip ファイルを作成
data "archive_file" "source_file_zip" {
  type        = "zip"
  source_dir  = "../../applications/${var.function_name}/src"
  output_path = "../../applications/${var.function_name}/${var.function_name}.zip"
}

#### Cloud Functions 関連（デプロイ用 GCS バケット、オブジェクトの作成）
# Cloud Functions ソースコードを格納する GCS バケットの作成
resource "google_storage_bucket" "src_cloud_functions" {
  name     = "${var.function_name}_functions_src"
  project  = var.project_id
  location = var.region
}
# Cloud Functions ソースコード GCS オブジェクトの作成
resource "google_storage_bucket_object" "source_object_zip" {
  name   = "${var.env}/${var.function_name}_${data.archive_file.source_file_zip.output_md5}.zip"
  bucket = google_storage_bucket.src_cloud_functions.name
  source = data.archive_file.source_file_zip.output_path
}

#### Cloud Functions 関連（Secret Manager で管理している情報を環境変数として利用するための記述）

# secret manager から SLACK_SIGNING_SECRET を取得する
data "google_secret_manager_secret" "SLACK_SIGNING_SECRET" {
  secret_id = "SLACK_SIGNING_SECRET"
}

# secret manager から SLACK_APP_TOKEN を取得する
data "google_secret_manager_secret" "SLACK_BOT_TOKEN" {
  secret_id = "SLACK_BOT_TOKEN"
}

# secret manager から OPENAI_API_KEY を取得する
data "google_secret_manager_secret" "OPENAI_API_KEY" {
  secret_id = "OPENAI_API_KEY"
}


#### Cloud Functions 関連（各関数をデプロイ）
# アプリケーション を Cloud Functions へデプロイ
resource "google_cloudfunctions2_function" "function" {
  name        = var.function_name
  location    = var.region
  description = "deploy ${var.function_name}"

  # ソースコード、言語、エントリーポイントを指定
  build_config {
    runtime     = "python310"
    entry_point = "slack_bot"
    source {
      storage_source {
        bucket = google_storage_bucket.src_cloud_functions.name
        object = google_storage_bucket_object.source_object_zip.name
      }
    }
  }
  # 基本スペックの設定
  service_config {
    max_instance_count    = 10
    available_memory      = "256Mi"
    timeout_seconds       = 300
    service_account_email = google_service_account.func_service_account.email
    # environment_variables = yamldecode(file("../applications/env/.env.yaml"))

    # secret managerから情報を取得
    secret_environment_variables {
      key        = "SLACK_SIGNING_SECRET"
      project_id = var.project_id
      secret     = data.google_secret_manager_secret.SLACK_SIGNING_SECRET.secret_id
      version    = "latest"
    }
    secret_environment_variables {
      key        = "SLACK_BOT_TOKEN"
      project_id = var.project_id
      secret     = data.google_secret_manager_secret.SLACK_BOT_TOKEN.secret_id
      version    = "latest"
    }

    secret_environment_variables {
      key        = "OPENAI_API_KEY"
      project_id = var.project_id
      secret     = data.google_secret_manager_secret.OPENAI_API_KEY.secret_id
      version    = "latest"
    }
  }
}
