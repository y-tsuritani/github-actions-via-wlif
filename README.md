# Workload Identity Federation

## 概要

GitHub が GitHub Actions ワークフローに OIDC トークンを導入したため、Workload Identity 連携を使用して GitHub Actions から Google Cloud に認証できる

### アーキテクチャ

![structure_img](img/2_GitHub_Actions.max-1100x1100.jpg)

### 公式ドキュメント

[GitHub Actions からのキーなしの認証の有効化](https://cloud.google.com/blog/ja/products/identity-security/enabling-keyless-authentication-from-github-actions)

[GitHub Actions: Secure cloud deployments with OpenID Connect](https://github.blog/changelog/2021-10-27-github-actions-secure-cloud-deployments-with-openid-connect/)

## 構築の手順

### GCP: Workload Identity プロバイダの作成

### Terraform の活用

[GCP で terraform を利用するチュートリアル](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started)

[Terraform Cloud Functions をデプロイするチュートリアル（第 2 世代）](https://cloud.google.com/functions/docs/tutorials/terraform?hl=ja)

GitHub Actions を用いた CI/CD の実現

## API ドキュメント

### Github Actions

### GCP

### Terraform

## Architecture Documentation

## 参考にした記事

- [GitHub Actions で Terraform の CI/CD を構築する](https://lab.mo-t.com/blog/terraform-github-actions)

- [サービスアカウントキーを用いずに GitHub Actions から Google Cloud と認証する](https://dev.classmethod.jp/articles/google-cloud-auth-with-workload-identity/)

- [Workload Identity Federation を GitHub Actions で利用する](https://zenn.dev/amazyra/articles/workloadidentityfederation)

- [Github Actions で secret を使う](https://qiita.com/inouet/items/c7d39ac4641c05eec4a0)

- [ID 連携により有効期間の短い認証情報を取得する](https://cloud.google.com/iam/docs/using-workload-identity-federation?hl=ja&_ga=2.233113054.-1968687333.1670507126&_gac=1.215256677.1676447449.CjwKCAiA_6yfBhBNEiwAkmXy5-xm9Vce3Abxvg4ukdplah0zhKcjf9r3wymvAflSQXCU6oks7vwFxBoCKtkQAvD_BwE#terraform)

- [Google Cloud Platform での OpenID Connect の構成](https://docs.github.com/ja/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)

- [google-github-actions/auth](https://github.com/google-github-actions/auth)

- [Terraform Registry GitHub OIDC](https://registry.terraform.io/modules/terraform-google-modules/github-actions-runners/google/latest/submodules/gh-oidc#github-oidc)
