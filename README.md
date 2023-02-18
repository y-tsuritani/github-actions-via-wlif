# Workload Identity Federation

## 概要

GitHub が GitHub Actions ワークフローに OIDC トークンを導入したため、Workload Identity 連携を使用して GitHub Actions から Google Cloud に認証できる

Workload Identity Federation は、GCP が利用する認証機構の一種で、これを使うことにより、外部システムのユーザーが GCP 内のユーザーを借用できるようになります。

今回は、GitHub Actions と GCP の連携例に考えます。GitHub では、Workload Identity 連携に対応する ID プロバイダを用意しており、このプロパイダが認証サーバの役割を果たしています。GCP では、GitHub が用意した ID プロパイダが提供する認証情報に応じて、ユーザー権限を与えることができます。GitHub Actions は GitHub が用意したプロパイダで認証することにより、GCP のリソースに変更を加えることができます。

結果として、「 GCP 以外のサービスが提供する外部 ID を用いて、GCP リソースに変更を加える」ことができます。

### アーキテクチャ

![structure_img](img/2_GitHub_Actions.max-1100x1100.jpg)

## 準備

[GCP のプロジェクトを準備する](https://cloud.google.com/iam/docs/configuring-workload-identity-federation?hl=ja#prepare_the_project)

「 GCP 以外のサービスが提供する外部 ID を用いて、GCP リソースに変更を加える」ことを実現するためには、まず事前に外部 ID に対して信頼する設定を行う必要があります。そのためには、GCP 側で以下のリソースを作成する必要があります。

1. Workload Identity プール
2. OIDC ID プロパイダ

Workload Identity プールには、複数の OIDC ID プロパイダが所属することが可能で、プールに対してサービスアカウントを借用する許可を与えることになります。OIDC ID プロパイダは、その名の通り、ID プロパイダに関する接続情報などをまとめたリソースです。今回であれば､ GitHub が提供している ID プロパイダを指すことになります｡

これら 2 つのリソースを作成することによって､ Workload Identity 連携が可能になります｡

次に､権限の借用許可を与える条件として「特定のリポジトリへのプッシュ時のみサービスアカウントを渡したい」という条件を考えます｡この条件を満たしている際にのみサービスアカウントを借用できるようにするために、GitHub の ID プロパイダがどのような応答をするのか、確認してみましょう。

## GCP の設定: Workload Identity 連携の設定

GCP で ID プールを作成します｡「IAM と管理」> 「Workload Identity 連携」を開き､「使ってみる」を選択すると､新しいプールを作成する画面に移行します｡

ID プールを作成するためには､名前が必要なので､適当に決めて入力を行います｡ ID も必要ですが､自動的に生成されるため､もし変更したい場合は編集してください｡

次に､ID プールに対して､GitHub の ID プロパイダを登録します｡発行元に `https://token.actions.githubusercontent.com` を指定する

発行された OIDC トークンから､判定に利用する属性をマッピングします｡ 今回は､ repository の属性に入っている値を使いたいこと､ google.subject に sub の情報を渡す必要があるため､以下のようにマッピングします｡

## GCP の設定: 借用するサービスアカウントの設定

借用するサービスアカウントを設定します｡サービスアカウントの作成方法については､この記事では割愛します｡
[サービス アカウントの作成と管理](https://cloud.google.com/iam/docs/creating-managing-service-accounts?hl=ja)

## GitHub Actions の作成

`_tf_plan.yml`

```yaml
name: caller terraform plan workflow
on:
  workflow_call:
    inputs:
      SLACK_MESSAGE_TARGET_ENV:
        type: string
        required: true
      TF_VERSION:
        type: string
        required: true
      TF_WORK_DIR:
        type: string
        required: true
    secrets:
      SLACK_WEBHOOK:
        required: true
      WORKLOAD_IDENTITY_PROVIDER:
        required: true
      SERVICE_ACCOUNT:
        required: true

jobs:
  tf_plan:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
    steps:
      - name: checkout
        uses: actions/checkout@v3.3.0

      - name: authenticate to google cloud
        uses: google-github-actions/auth@v1.0.0
        with:
          create_credentials_file: true
          workload_identity_provider: ${{ secrets.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.SERVICE_ACCOUNT }}

      - name: setup terraform
        uses: hashicorp/setup-terraform@v2.0.3
        with:
          terraform_version: ${{ inputs.TF_VERSION }}

      - name: terraform init
        id: init
        working-directory: ${{ inputs.TF_WORK_DIR }}
        run: |
          terraform init

      - name: terraform plan
        id: plan
        working-directory: ${{ inputs.TF_WORK_DIR }}
        run: |
          terraform plan -no-color
        continue-on-error: true

      # 1. PRのコメント欄に65536文字数制限がある
      # 2. github-script もしくは GitHub Actions Workflow 内にも文字数制限がある
      # よって、terraform plan/apply の結果を予め削る必要がある
      # 大量に差分が出た場合は差分を見るのではなく plan/apply の成否を見たい
      # これらを考慮して65000文字に制限する
      - name: truncate terraform plan result
        run: |
          plan=$(cat <<'EOF'
          ${{ format('{0}{1}', steps.plan.outputs.stdout, steps.plan.outputs.stderr) }}
          EOF
          )
          echo "PLAN<<EOF" >> $GITHUB_ENV
          echo "${plan}" | grep -v 'Refreshing state' | tail -c 65000 >> $GITHUB_ENV
          echo "EOF" >> $GITHUB_ENV

      - name: create comment from plan result
        uses: actions/github-script@v6.4.0
        if: github.event_name == 'pull_request'
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const output = `#### Terraform Initialization ⚙️\`${{ steps.init.outcome }}\`
            #### Terraform Plan 📖\`${{ steps.plan.outcome }}\`

            <details><summary>Show Plan</summary>

            \`\`\`\n
            ${ process.env.PLAN }
            \`\`\`

            </details>

            *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`, Working Directory: \`${{ inputs.TF_WORK_DIR }}\`, Workflow: \`${{ github.workflow }}\`*`;

            github.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

      # workflow が成功したとき
      # terraform plan のステップで、continue-on-error: true としているので、
      # plan がエラーになってもここのステップを通る
      - name: notice completed workflow
        uses: rtCamp/action-slack-notify@v2.2.0
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_MESSAGE: "github-actions-via-wlif [${{ inputs.SLACK_MESSAGE_TARGET_ENV }}] terraform plan (${{ steps.plan.outcome }})"

      # workflow が失敗したとき
      - name: notice failed workflow
        if: failure()
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_COLOR: danger
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_MESSAGE: "github-actions-via-wlif [${{ inputs.SLACK_MESSAGE_TARGET_ENV }}] terraform plan (workflow failed)"
```

`tf_plan_dev.yml`

```yaml
name: caller terraform plan workflow (dev)
on:
  # pull_request:
  #   branches:
  #     - main
  #   paths:
  #     - 'terraform/dev/**'
  #   types:
  #     - opened
  #     - synchronize

  # test用
  push:
    branches:
      - develop

jobs:
  call_workflow:
    # uses: y-tsuritani/Slackbot_ChatGPT.git/.github/workflows/_tf_plan.yml@main
    # test用
    uses: y-tsuritani/github-actions-via-wlif/.github/workflows/_tf_plan.yml@develop
    with:
      SLACK_MESSAGE_TARGET_ENV: dev
      TF_VERSION: 1.3.4
      TF_WORK_DIR: terraform/dev
    secrets:
      SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
      WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.DEV_WORKLOAD_IDENTITY_PROVIDER }}
      SERVICE_ACCOUNT: ${{ secrets.SERVICE_ACCOUNT }}
```

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

- [Google Cloud Platform での OpenID Connect の構成](https://docs.github.com/ja/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-google-cloud-platform)

- [google-github-actions/auth](https://github.com/google-github-actions/auth)

### GCP

- [ID 連携により有効期間の短い認証情報を取得する](https://cloud.google.com/iam/docs/using-workload-identity-federation?hl=ja&_ga=2.233113054.-1968687333.1670507126&_gac=1.215256677.1676447449.CjwKCAiA_6yfBhBNEiwAkmXy5-xm9Vce3Abxvg4ukdplah0zhKcjf9r3wymvAflSQXCU6oks7vwFxBoCKtkQAvD_BwE#terraform)

- [Workload Identity プールとプロバイダを管理する](https://cloud.google.com/iam/docs/manage-workload-identity-pools-providers?hl=ja)

- [サービス アカウントの権限借用](https://cloud.google.com/iam/docs/workload-identity-federation?hl=ja#impersonation)

- [IAM permissions reference](https://cloud.google.com/iam/docs/permissions-reference)

### Terraform

- [Terraform Registry GitHub OIDC](https://registry.terraform.io/modules/terraform-google-modules/github-actions-runners/google/latest/submodules/gh-oidc#github-oidc)

## Architecture Documentation

## 参考にした記事

- [GitHub Actions で Terraform の CI/CD を構築する](https://lab.mo-t.com/blog/terraform-github-actions)

- [サービスアカウントキーを用いずに GitHub Actions から Google Cloud と認証する](https://dev.classmethod.jp/articles/google-cloud-auth-with-workload-identity/)

- [Workload Identity Federation を GitHub Actions で利用する](https://zenn.dev/amazyra/articles/workloadidentityfederation)

- [Github Actions で secret を使う](https://qiita.com/inouet/items/c7d39ac4641c05eec4a0)

- [GitHub Actions を使って Google Cloud 環境に Terraform を実行する方法](https://blog.g-gen.co.jp/entry/using-terraform-via-github-actions)

- [Workload Identity Federation を図で理解する](https://christina04.hatenablog.com/entry/workload-identity-federation)
