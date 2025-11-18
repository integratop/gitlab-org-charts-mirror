---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Runnerチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Runnerサブチャートは、CIジョブを実行するためのGitLab Runnerを提供します。これはデフォルトで有効になっており、S3互換オブジェクトストレージを使用したキャッシュをサポートし、すぐに使用できるはずです。

{{< alert type="warning" >}}

含まれているGitLab Runnerチャートのデフォルトの設定は、**本番環境を対象としていません**。これは、すべてのGitLabサービスがクラスターにデプロイされる、概念実証（PoC）の実装として提供されています。本番環境のデプロイでは、[セキュリティとパフォーマンス上の理由](https://docs.gitlab.com/install/requirements/#gitlab-runner)から、別のマシンにGitLab Runnerをインストールしてください。詳細については、[リファレンスアーキテクチャ](../../../installation/_index.md#use-the-reference-architectures)を参照してください。

{{< /alert >}}

## 要件 {#requirements}

GitLab 16.0では、Runner認証トークンを使用してRunnerを登録する新しいRunner作成ワークフローが導入されました。登録トークンを使用する従来のワークフローは非推奨となり、GitLab 17.0ではデフォルトで無効になっています。これはGitLab 18.0で削除される予定です。

推奨されるワークフローを使用するには:

- [認証トークンを生成します。](https://docs.gitlab.com/ci/runners/new_creation_workflow/#prevent-your-runner-registration-workflow-from-breaking)
- 設定は[`shared-secrets`](../../shared-secrets.md)ジョブで処理されないため、Runnerシークレット（`<release>-gitlab-runner-secret`）を手動で更新します。
- `gitlab-runner.runners.locked`を`null`に設定します:

  ```yaml
  gitlab-runner:
    runners:
      locked: null
  ```

従来のワークフローを使用する場合（推奨されません）:

- [従来のワークフローを再度有効にする](https://docs.gitlab.com/administration/settings/continuous_integration/#enable-runner-registrations-tokens)必要があります。
- 登録トークンは、[`shared-secrets`](../../shared-secrets.md)ジョブによって入力されたものです。
- GitLab 18.0より前に新しいワークフローに移行する必要があります。これにより、従来のワークフローのサポートが削除されます。

## 設定 {#configuration}

詳細については、[使用方法と設定](https://docs.gitlab.com/runner/install/kubernetes/)に関するドキュメントを参照してください。

## スタンドアロンRunnerのデプロイ {#deploying-a-stand-alone-runner}

既定では、`gitlabUrl`を推測し、登録トークンを自動的に生成し、`migrations`チャートを介して生成します。この動作は、実行中のGitLabインスタンスでデプロイする場合は機能しません。

この場合、`gitlabUrl`の値を、実行中のGitLabインスタンスのURLに設定する必要があります。また、`gitlab-runner`シークレットを手動で作成し、実行中のGitLabから提供された`registrationToken`でそれを満たす必要があります。

## Docker-in-Dockerを使用する {#using-docker-in-docker}

Docker-in-Dockerを実行するには、Runnerコンテナが、必要な機能にアクセスできるように特権を持っている必要があります。これを有効にするには、`privileged`の値を`true`に設定します。これが`true`にデフォルト設定されていない理由については、[アップストリームドキュメント](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#use-privileged-containers-for-the-runners)を参照してください。

### セキュリティに関する懸念 {#security-concerns}

特権コンテナには拡張機能があり、たとえば、実行元のホストから任意のファイルをマウントできます。重要なものが隣で実行されないように、隔離された環境でコンテナを実行してください。

## デフォルトのRunner設定 {#default-runner-configuration}

GitLabチャートで使用されるデフォルトのRunner設定は、デフォルトでキャッシュ用に含まれているMinIOを使用するようにカスタマイズされています。Runner `config`値を設定する場合は、独自のキャッシュ設定も構成する必要があります。

```yaml
gitlab-runner:
  runners:
    config: |
      [[runners]]
        [runners.kubernetes]
        image = "ubuntu:22.04"
        {{- if .Values.global.minio.enabled }}
        [runners.cache]
          Type = "s3"
          Path = "gitlab-runner"
          Shared = true
          [runners.cache.s3]
            ServerAddress = {{ include "gitlab-runner.cache-tpl.s3ServerAddress" . }}
            BucketName = "runner-cache"
            BucketLocation = "us-east-1"
            Insecure = false
        {{ end }}
```

カスタマイズされたすべてのGitLab Runnerチャートの設定は、`gitlab-runner`キーの下の[トップレベル`values.yaml`ファイル](https://gitlab.com/gitlab-org/charts/gitlab/raw/master/values.yaml)にあります。
