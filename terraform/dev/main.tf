provider "google" {
  project = var.project_id
  region  = var.region
}

# 使用するサービスアカウント
resource "google_service_account" "func_service_account" {
  account_id   = "gcf-service-account"
  display_name = "gcf-service-account"
  project      = var.project_id
  description  = "Cloud Functions が使用するサービスアカウント"
}

#### Cloud Functions 関連（デプロイ用 zip ファイルの作成）
# Cloud Functions デプロイ用にソースコード zip ファイルを作成
data "archive_file" "source_file_zip" {
  type        = "zip"
  source_dir  = "../../applications/src"
  output_path = "../../applications/${var.function_name}.zip"
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

#### Cloud Functions 関連（各関数をデプロイ）
# アプリケーション を Cloud Functions へデプロイ
resource "google_cloudfunctions2_function" "function" {
  name        = var.function_name
  location    = var.region
  description = "deploy ${var.function_name}"

  # ソースコード、言語、エントリーポイントを指定
  build_config {
    runtime     = "python310"
    entry_point = "hello_http"
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
  }
}
