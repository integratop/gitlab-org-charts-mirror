---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのトラブルシューティング
---

## UPGRADE FAILED: "$name" has no deployed releases {#upgrade-failed-name-has-no-deployed-releases}

このエラーは、最初のインストールに失敗した場合、2回目のインストール/アップグレードで発生します。

最初のインストールが完全に失敗し、GitLabが動作しなかった場合は、再度インストールする前に、まず失敗したインストールをパージする必要があります。

```shell
helm uninstall <release-name>
```

代わりに、最初のインストールコマンドがタイムアウトしたが、GitLabが正常に起動した場合は、エラーを無視してリリースの更新を試みるために、`helm upgrade`コマンドに`--force`フラグを追加できます。

それ以外の場合、以前にGitLabチャートのデプロイに成功した後でこのエラーが発生した場合は、バグが発生しています。当社の[イシュートラッカー](https://gitlab.com/gitlab-org/charts/gitlab/-/issues)でイシューをオープンし、この問題からCIサーバーを復元した[issue #630](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/630)もご確認ください。

## エラー: このコマンドには2つの引数が必要です: リリース名、チャートパス {#error-this-command-needs-2-arguments-release-name-chart-path}

このようなエラーは、`helm upgrade`を実行し、パラメータにスペースが含まれている場合に発生する可能性があります。次の例では、`Test Username`が原因です:

```shell
helm upgrade gitlab gitlab/gitlab --timeout 600s --set global.email.display_name=Test Username ...
```

修正するには、パラメータをシングルクォートで渡します:

```shell
helm upgrade gitlab gitlab/gitlab --timeout 600s --set global.email.display_name='Test Username' ...
```

## アプリケーションコンテナが初期化を繰り返す {#application-containers-constantly-initializing}

Sidekiq、Webservice、またはその他のRailsベースのコンテナが初期化の定常状態になっている場合は、`dependencies`コンテナが渡されるのを待っている可能性があります。

特定の`dependencies`コンテナの特定のポッドのログをチェックすると、次の繰り返しが表示される場合があります:

```plaintext
Checking database connection and schema version
WARNING: This version of GitLab depends on gitlab-shell 8.7.1, ...
Database Schema
Current version: 0
Codebase version: 20190301182457
```

これは、`migrations`ジョブがまだ完了していないことを示しています。このジョブの目的は、データベースがシードされていることと、関連するすべてのマイグレーションが適切に配置されていることを確認することです。アプリケーションコンテナは、データベースが予想されるデータベースバージョン以上になるのを待機しようとしています。これは、コードベースの期待にスキーマが一致しないために、アプリケーションが誤動作しないようにするためです。

1. `migrations`ジョブを検索します。`kubectl get job -lapp=migrations`
1. ジョブによって実行されているポッドを検索します。`kubectl get pod -lbatch.kubernetes.io/job-name=<job-name>`
1. 出力を調べて、`STATUS`列を確認します。

`STATUS`が`Running`の場合は、続行します。`STATUS`が`Completed`の場合、アプリケーションコンテナは、次のチェックに合格するとすぐに起動します。

このポッドからのログを調べます。`kubectl logs <pod-name>`

このジョブの実行中のエラーはすべて対処する必要があります。これらは解決されるまで、アプリケーションの使用をブロックします。考えられる問題は次のとおりです:

- 構成されたPostgreSQLデータベースへの到達不能または認証の失敗
- 構成されたRedisサービスへの到達不能または認証の失敗
- Gitalyインスタンスに到達できない

## 設定の変更を適用する {#applying-configuration-changes}

次のコマンドは、`gitlab.yaml`に加えられた更新を適用するために必要な操作を実行します:

```shell
helm upgrade <release name> <chart path> -f gitlab.yaml
```

## 含まれているGitLab Runnerの登録に失敗する {#included-gitlab-runner-failing-to-register}

これは、GitLabでRunner登録トークンが変更された場合に発生する可能性があります。（これは、バックアップを復元した後に発生することがよくあります）

1. GitLabインストールの`admin/runners` Webページにある新しい共有Runnerトークンを見つけます。
1. Kubernetesに保存されている既存のRunnerトークンシークレットの名前を見つけます

   ```shell
   kubectl get secrets | grep gitlab-runner-secret
   ```

1. 既存のシークレットを削除します

   ```shell
   kubectl delete secret <runner-secret-name>
   ```

1. 2つのキー（共有トークンを持つ`runner-registration-token`と、空の`runner-token`）を使用して新しいシークレットを作成します

   ```shell
   kubectl create secret generic <runner-secret-name> --from-literal=runner-registration-token=<new-shared-runner-token> --from-literal=runner-token=""
   ```

## リダイレクトが多すぎる {#too-many-redirects}

これは、NGINXイングレスの前にTLS終端があり、tls-シークレットが設定で指定されている場合に発生する可能性があります。

1. `global.ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect": "false"`を設定するために値を更新します

   値ファイル経由:

   ```yaml
   # values.yaml
   global:
     ingress:
       annotations:
         "nginx.ingress.kubernetes.io/ssl-redirect": "false"
   ```

   Helm CLI経由:

   ```shell
   helm ... --set-string global.ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect"=false
   ```

1. 変更を適用してください。

{{< alert type="note" >}}

SSL終端に外部サービスを使用する場合、そのサービスはhttpsへのリダイレクトを担当します（必要に応じて）。

{{< /alert >}}

## イミュータブルフィールドエラーでアップグレードに失敗する {#upgrades-fail-with-immutable-field-error}

### spec.clusterIP {#specclusterip}

これらのチャートの3.0.0リリースより前は、実際の値（`""`）がないにもかかわらず、`spec.clusterIP`プロパティが[いくつかのサービスに入力された](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1710)いました。これはバグであり、Helm 3のプロパティの3方向マージで問題が発生します。

チャートがHelm 3でデプロイされると、さまざまなサービスから`clusterIP`プロパティを収集し、それらをHelmに提供される値に入力するか、影響を受けるサービスをKubernetesから削除しない限り、_可能なアップグレードパスはありません_。

このチャートの[3.0.0リリースでこのエラーが修正されました](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1710)が、手動による修正が必要です。

これは、影響を受けるすべてのサービスを削除するだけで解決できます。

1. 影響を受けるすべてのサービスを削除します:

   ```shell
   kubectl delete services -lrelease=RELEASE_NAME
   ```

1. Helmを使用してアップグレードを実行します。
1. 今後のアップグレードでは、このエラーは発生しません。

{{< alert type="note" >}}

これにより、使用中の場合、このチャートからのNGINXイングレスの`LoadBalancer`ロードバランサーの動的な値が変更されます。`externalIP`に関する詳細については、[グローバルイングレス設定のドキュメント](../charts/globals.md#configure-ingress-settings)を参照してください。DNSレコードの更新が必要になる場合があります。

{{< /alert >}}

### spec.selector {#specselector}

Sidekiqポッドは、チャートリリース`3.0.0`より前に一意のセレクターを受信しませんでした。[この問題についてはドキュメント化されています](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/663)。

Helmを使用した`3.0.0`へのアップグレードでは、古いSidekiqデプロイメントが自動的に削除され、Sidekiq `Deployments`、`HPAs`、および`Pods`の名前に`-v1`が付加された新しいデプロイメントが作成されます。

`3.0.0`のインストール時にSidekiqデプロイメントでこのエラーが発生し続ける場合は、次の手順でこれらを解決します:

1. Sidekiqサービスを削除します

   ```shell
   kubectl delete deployment --cascade -lrelease=RELEASE_NAME,app=sidekiq
   ```

1. Helmを使用してアップグレードを実行します。

### 種類デプロイメントで「RELEASE-NAME-cert-manager」にパッチを適用できません {#cannot-patch-release-name-cert-manager-with-kind-deployment}

**CertManager**バージョン`0.10`からのアップグレードでは、多くの破壊的な変更が導入されました。古いカスタムリソース定義をアンインストールし、Helmの追跡から削除してから、再インストールする必要があります。

Helmチャートはデフォルトでこれを試みますが、このエラーが発生した場合は、新しいカスタムリソース定義がデプロイメントに実際に適用されるようにするために、通常よりももう1つ手順を実行する必要がある場合があります。

このエラーメッセージが表示された場合は、新しいカスタムリソース定義がデプロイメントに実際に適用されるようにするために、アップグレードには通常よりももう1つ手順が必要です。

1. 古い**CertManager**デプロイメントを削除します。

   ```shell
   kubectl delete deployments -l app=cert-manager --cascade
   ```

1. アップグレードを再度実行します。今回は、新しいカスタムリソース定義をインストールします

   ```shell
   helm upgrade --install --values - YOUR-RELEASE-NAME gitlab/gitlab < <(helm get values YOUR-RELEASE-NAME)
   ```

### 種類デプロイメントで`gitlab-kube-state-metrics`にパッチを適用できません {#cannot-patch-gitlab-kube-state-metrics-with-kind-deployment}

**Prometheus**バージョン`11.16.9`から`15.0.4`へのアップグレードでは、[kube-state-metricsデプロイメント](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics)で使用されるセレクターラベルが変更されます。これはデフォルトで無効になっています（`prometheus.kubeStateMetrics.enabled=false`）。

このエラーメッセージが表示された場合、つまり`prometheus.kubeStateMetrics.enabled=true`を意味する場合、アップグレードには[追加の手順](https://artifacthub.io/packages/helm/prometheus-community/prometheus#to-15-0)が必要です:

1. 古い**kube-state-metrics**デプロイメントを削除します。

   ```shell
   kubectl delete deployments.apps -l app.kubernetes.io/instance=RELEASE_NAME,app.kubernetes.io/name=kube-state-metrics --cascade=orphan
   ```

1. Helmを使用してアップグレードを実行します。

## `ImagePullBackOff`、`Failed to pull image`、および`manifest unknown`エラー {#imagepullbackoff-failed-to-pull-image-and-manifest-unknown-errors}

[`global.gitlabVersion`](../charts/globals.md#gitlab-version)を使用している場合は、まずそのプロパティを削除します。[チャートとGitLab間のバージョンマッピングを確認](../installation/version_mappings.md)し、`helm`コマンドで互換性のある`gitlab/gitlab`チャートのバージョンを指定します。

## `helm 2to3 convert`の後にUPGRADE FAILED: "cannot patch ..." {#upgrade-failed-cannot-patch--after-helm-2to3-convert}

これは既知の問題です。Helm 2リリースをHelm 3に移行した後、後続のアップグレードが失敗する可能性があります。完全な説明と回避策は、[Helm v2からHelm v3への移行](../installation/migration/helm.md#known-issues)にあります。

## UPGRADE FAILED: mailroomの型の不一致: `%!t(<nil>)` {#upgrade-failed-type-mismatch-on-mailroom-tnil}

このようなエラーは、マップを予期するキーに有効なマップを提供しない場合に発生する可能性があります。

たとえば、次の設定では、このエラーが発生します:

```yaml
gitlab:
  mailroom:
```

これを修正するには、次のいずれかの操作を行います:

1. `gitlab.mailroom`に有効なマップを提供します。
1. `mailroom`キーを完全に削除します。

オプションのキーの場合、空のマップ（`{}`）は有効な値であることに注意してください。

## エラー: `cannot drop view pg_stat_statements because extension pg_stat_statements requires it` {#error-cannot-drop-view-pg_stat_statements-because-extension-pg_stat_statements-requires-it}

Helmチャートインスタンスでバックアップを復元する際に、このエラーが発生する可能性があります。次の手順を回避策として使用します:

1. `toolbox`ポッド内で、DBコンソールを開きます:

   ```shell
   /srv/gitlab/bin/rails dbconsole -p
   ```

1. 拡張機能をドロップします:

   ```shell
   DROP EXTENSION pg_stat_statements;
   ```

1. リストア処理を実行します。
1. リストアが完了したら、DBコンソールで拡張機能を再作成します:

   ```shell
   CREATE EXTENSION pg_stat_statements;
   ```

`pg_buffercache`拡張機能で同じ問題が発生した場合は、上記と同じ手順に従ってドロップして再作成してください。

このエラーの詳細については、[\#2469](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2469)イシューを参照してください。

## バンドルされたPostgreSQLポッドが起動に失敗する: `database files are incompatible with server` {#bundled-postgresql-pod-fails-to-start-database-files-are-incompatible-with-server}

GitLab Helmチャートの新しいバージョンにアップグレードした後、バンドルされたPostgreSQLポッドに次のエラーメッセージが表示される場合があります:

```plaintext
gitlab-postgresql FATAL:  database files are incompatible with server
gitlab-postgresql DETAIL:  The data directory was initialized by PostgreSQL version 11, which is not compatible with this version 12.7.
```

これを解決するには、チャートの以前のバージョンへの[Helmロールバック](https://helm.sh/docs/helm/helm_rollback/)を実行し、[アップグレードガイド](../installation/upgrade.md)の手順に従って、バンドルされたPostgreSQLバージョンをアップグレードします。PostgreSQLが適切にアップグレードされたら、GitLab Helmチャートのアップグレードを再度試してください。

## バンドルされたNGINXイングレスポッドが起動に失敗する: `Failed to watch *v1beta1.Ingress` {#bundled-nginx-ingress-pod-fails-to-start-failed-to-watch-v1beta1ingress}

Kubernetesバージョン1.22以降を実行している場合、バンドルされたNGINXイングレスコントローラーポッドに次のエラーメッセージが表示されることがあります:

```plaintext
Failed to watch *v1beta1.Ingress: failed to list *v1beta1.Ingress: the server could not find the requested resource
```

これを解決するには、Kubernetesバージョンが1.21以前であることを確認してください。Kubernetesバージョン1.22以降のNGINXイングレスのサポートに関する詳細については、[\#2852](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2852)を参照してください。

## `/api/v4/jobs/request`エンドポイントの負荷が増加しました {#increased-load-on-apiv4jobsrequest-endpoint}

オプション`workhorse.keywatcher`が`/api/*`のサービスデプロイメントで`false`に設定されている場合、この問題が発生する可能性があります。確認するには、次の手順に従ってください:

1. `/api/*`を提供するポッド内の`gitlab-workhorse`コンテナにアクセスします:

   ```shell
   kubectl exec -it --container=gitlab-workhorse <gitlab_api_pod> -- /bin/bash
   ```

1. `/srv/gitlab/config/workhorse-config.toml`ファイルを調べます。`[redis]`設定が見つからない可能性があります:

   ```shell
   grep '\[redis\]' /srv/gitlab/config/workhorse-config.toml
   ```

`[redis]`設定が存在しない場合、`workhorse.keywatcher`フラグはデプロイメント中に`false`に設定されたため、`/api/v4/jobs/request`エンドポイントで余分な負荷が発生しています。これを修正するには、`webservice`チャートで`keywatcher`を有効にします:

```yaml
workhorse:
  keywatcher: true
```

## SSH経由のGit: `the remote end hung up unexpectedly` {#git-over-ssh-the-remote-end-hung-up-unexpectedly}

SSH経由でのGit操作は、次のエラーで断続的に失敗する可能性があります:

```plaintext
fatal: the remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

このエラーには、考えられる原因がいくつかあります:

- **ネットワークタイムアウト**:

  Gitクライアントは、オブジェクトを圧縮するときなど、接続を開いてアイドル状態のままにすることがあります。HAProxyの`timeout client`のような設定では、これらのアイドル接続が終了する可能性があります。

  `sshd`でkeepaliveを設定できます:

  ```yaml
  gitlab:
    gitlab-shell:
      config:
        clientAliveInterval: 15
  ```

- **`gitlab-shell`メモリ**:

  デフォルトでは、チャートはGitLabシェルメモリの制限を設定しません。`gitlab.gitlab-shell.resources.limits.memory`が低すぎると、SSH経由でのGit操作がこれらのエラーで失敗する可能性があります。

  ネットワーク経由でのタイムアウトではなく、メモリ制限が原因であることを確認するには、`kubectl describe nodes`を実行します。

  ```plaintext
  System OOM encountered, victim process: gitlab-shell
  Memory cgroup out of memory: Killed process 3141592 (gitlab-shell)
  ```

## エラー: `kex_exchange_identification: Connection closed by remote host` {#error-kex_exchange_identification-connection-closed-by-remote-host}

次のエラーがGitLabシェルログに表示されることがあります:

```plaintext
subcomponent":"ssh","time":"2025-02-21T19:07:52Z","message":"kex_exchange_identification: Connection closed by remote host\r"}
```

このエラーは、OpenSSH `sshd`が準備プローブと活性プローブを処理できないことが原因です。このエラーを解決するには、`sshDaemon: openssh`を設定で`sshDaemon: gitlab-ssd`に変更することにより、代わりに[`gitlab-sshd`](../charts/gitlab/gitlab-shell/_index.md#configuration)を使用します:

```yaml
gitlab:
  gitlab-shell:
    sshDaemon: gitlab-sshd
```

## YAMLの設定: `mapping values are not allowed in this context` {#yaml-configuration-mapping-values-are-not-allowed-in-this-context}

YAML設定に先頭のスペースが含まれている場合、次のエラーメッセージが表示されることがあります:

```plaintext
template: /var/opt/gitlab/templates/workhorse-config.toml.tpl:16:98:
  executing \"/var/opt/gitlab/templates/workhorse-config.toml.tpl\" at <data.YAML>:
    error calling YAML:
      yaml: line 2: mapping values are not allowed in this context
```

これを解決するには、設定に先頭のスペースがないことを確認してください。

たとえば、次のように変更します:

```yaml
  key1: value1
  key2: value2
```

...これへ:

```yaml
key1: value1
key2: value2
```

## TLSと証明書 {#tls-and-certificates}

GitLabインスタンスがプライベートTLS認証局を信頼する必要がある場合、GitLabはオブジェクトストレージ、Elasticsearch、Jira、Jenkinsなどの他のサービスとのハンドシェイクに失敗する可能性があります:

```plaintext
error: certificate verify failed (unable to get local issuer certificate)
```

プライベート認証局によって署名された証明書の部分的な信頼は、次の場合に発生する可能性があります:

- 提供された証明書が個別のファイルにない。
- 証明書のinitコンテナが、必要なすべての手順を実行しない。

また、GitLabは主にRuby on RailsとGo言語で記述されており、各言語のTLSライブラリの動作は異なります。この違いにより、ジョブログがGitLab UIに表示されないが、rawジョブログが問題なくダウンロードされるなどの問題が発生する可能性があります。

さらに、`proxy_download`設定によっては、トラストストアが正しく設定されている場合、ブラウザは問題なくオブジェクトストレージにリダイレクトされます。同時に、1つ以上のGitLabコンポーネントによるTLSハンドシェイクが引き続き失敗する可能性があります。

### 証明書の信頼セットアップとトラブルシューティング {#certificate-trust-setup-and-troubleshooting}

証明書の問題のトラブルシューティングの一環として、以下を必ず行ってください:

- 信頼する必要がある各証明書のシークレットを作成します。
- ファイルごとに1つの証明書のみを提供します。

  ```plaintext
  kubectl create secret generic custom-ca --from-file=unique_name=/path/to/cert
  ```

  この例では、証明書はキー名`unique_name`を使用して保存されています

バンドルまたはチェーンを提供する場合、一部のGitLabコンポーネントは機能しません。

`kubectl get secrets`および`kubectl describe secrets/secretname`を使用してシークレットをクエリします。これにより、`Data`の証明書のキー名が表示されます。

[チャートグローバル](../charts/globals.md#custom-certificate-authorities)で`global.certificates.customCAs`を使用して、信頼する追加の証明書を提供します。

ポッドがデプロイされると、initコンテナは証明書をマウントし、GitLabコンポーネントがそれらを使用できるようにセットアップします。初期化コンテナは`registry.gitlab.com/gitlab-org/build/cng/alpine-certificates`です。

追加の証明書は、シークレットキー名を証明書ファイル名として使用して、`/usr/local/share/ca-certificates`コンテナにマウントされます。

初期化コンテナは`/scripts/bundle-certificates`（[ソース](https://gitlab.com/gitlab-org/build/CNG-mirror/-/blob/master/certificates/scripts/bundle-certificates)）を実行します。そのスクリプトでは、`update-ca-certificates`:

1. `/usr/local/share/ca-certificates`から`/etc/ssl/certs`にカスタム証明書をコピーします。
1. バンドル`ca-certificates.crt`をコンパイルします。
1. 各証明書のハッシュを生成し、Railsに必要なハッシュを使用してシンボリックリンクを作成します。証明書バンドルは、次の警告でスキップされます:

   ```plaintext
   WARNING: unique_name does not contain exactly one certificate or CRL: skipping
   ```

[Initコンテナのステータスとログの問題を解決](https://kubernetes.io/docs/tasks/debug/debug-application/debug-init-containers/)。たとえば、認証局Initコンテナのログを表示し、警告を確認するには、次のようにします:

```plaintext
kubectl logs gitlab-webservice-default-pod -c certificates
```

### Railsコンソールで確認 {#check-on-the-rails-console}

Toolboxポッドを使用して、提供した認証局をRailsが信頼するかどうかを確認します。

1. Railsコンソールを開始します（`<namespace>`をGitLabがインストールされているネームスペースに置き換えます）:

   ```shell
   kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
   /srv/gitlab/bin/rails console
   ```

1. Railsが認証局を確認する場所を確認します:

   ```ruby
   OpenSSL::X509::DEFAULT_CERT_DIR
   ```

1. RailsコンソールでHTTPSクエリを実行します:

   ```ruby
   ## Configure a web server to connect to:
   uri = URI.parse("https://myservice.example.com")

   require 'openssl'
   require 'net/http'
   Rails.logger.level = 0
   OpenSSL.debug=1
   http = Net::HTTP.new(uri.host, uri.port)
   http.set_debug_output($stdout)
   http.use_ssl = true

   http.verify_mode = OpenSSL::SSL::VERIFY_PEER
   # http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TLS verification disabled

   response = http.request(Net::HTTP::Get.new(uri.request_uri))
   ```

### Initコンテナの問題を解決 {#troubleshoot-the-init-container}

Dockerを使用して、認証局コンテナを実行します。

1. ディレクトリ構造をセットアップし、認証局を入力します:

   ```shell
   mkdir -p etc/ssl/certs usr/local/share/ca-certificates

     # The secret name is: my-root-ca
     # The key name is: corporate_root

   kubectl get secret my-root-ca -ojsonpath='{.data.corporate_root}' | \
        base64 --decode > usr/local/share/ca-certificates/corporate_root

     # Check the certificate is correct:

   openssl x509 -in usr/local/share/ca-certificates/corporate_root -text -noout
   ```

1. 正しいコンテナのバージョンを特定します:

   ```shell
   kubectl get deployment -lapp=webservice -ojsonpath='{.items[0].spec.template.spec.initContainers[0].image}'
   ```

1. コンテナを実行します。これにより、`etc/ssl/certs`コンテンツの準備が実行されます:

   ```shell
   docker run -ti --rm \
        -v $(pwd)/etc/ssl/certs:/etc/ssl/certs \
        -v $(pwd)/usr/local/share/ca-certificates:/usr/local/share/ca-certificates \
        registry.gitlab.com/gitlab-org/build/cng/gitlab-base:v15.10.3
   ```

1. 認証局が正しくビルドされたことを確認します:

   - `etc/ssl/certs/corporate_root.pem`が作成されているはずです。
   - ハッシュされたファイル名が必要です。これは認証局自体へのシンボリックリンクです（`etc/ssl/certs/1234abcd.0`など）。
   - ファイルとシンボリックリンクは次のように表示されるはずです:

     ```shell
     ls -l etc/ssl/certs/ | grep corporate_root
     ```

     例: 

     ```plaintext
     lrwxrwxrwx   1 root root      20 Oct  7 11:34 28746b42.0 -> corporate_root.pem
     -rw-r--r--   1 root root    1948 Oct  7 11:34 corporate_root.pem
     ```

## リダイレクトループを引き起こす`308: Permanent Redirect` {#308-permanent-redirect-causing-a-redirect-loop}

`308: Permanent Redirect`は、ロードバランサーが暗号化されていないトラフィック（HTTP）をNGINXに送信するように構成されている場合に発生する可能性があります。NGINXは`HTTP`から`HTTPS`へのリダイレクトがデフォルトであるため、「リダイレクトループ」が発生する可能性があります。

これを修正するには、[NGINXの`use-forwarded-headers`設定を有効にします](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#use-forwarded-headers)。

## `nginx-controller`ログおよび`404`エラーの「無効な単語」エラー {#invalid-word-errors-in-the-nginx-controller-logs-and-404-errors}

Helmチャート6.6以降にアップグレードすると、クラスターにインストールされているアプリケーションのGitLabまたはサードパーティドメインにアクセスしたときに`404`リターンコードが発生する可能性があり、`gitlab-nginx-ingress-controller`ログに「無効な単語」エラーも表示されます:

```console
gitlab-nginx-ingress-controller-899b7d6bf-688hr controller W1116 19:03:13.162001       7 store.go:846] skipping ingress gitlab/gitlab-minio: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-688hr controller W1116 19:03:13.465487       7 store.go:846] skipping ingress gitlab/gitlab-registry: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.233577       6 store.go:846] skipping ingress gitlab/gitlab-kas: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.536534       6 store.go:846] skipping ingress gitlab/gitlab-webservice-default: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.848844       6 store.go:846] skipping ingress gitlab/gitlab-webservice-default-smartcard: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:13.161640       6 store.go:846] skipping ingress gitlab/gitlab-minio: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:13.465425       6 store.go:846] skipping ingress gitlab/gitlab-registry: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
```

その場合は、[設定スニペット](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)の使用について、GitLabの設定とサードパーティIngressオブジェクトをレビューしてください。`nginx-ingress.controller.config.annotation-value-word-blocklist`設定の調整または変更が必要になる場合があります。

詳細については、[注釈値の単語許可リスト](../charts/nginx/_index.md#annotation-value-word-blocklist)を参照してください。

### ボリュームのマウントに時間がかかる {#volume-mount-takes-a-long-time}

`gitaly`や`toolbox`チャートボリュームなどの大規模なボリュームをマウントすると、Kubernetesがボリュームの内容の権限をポッドの`securityContext`に合わせて再帰的に変更するため、時間がかかる場合があります。

Kubernetes 1.23以降では、`securityContext.fsGroupChangePolicy`を`OnRootMismatch`に設定して、この問題を軽減できます。このフラグは、すべてのGitLabサブチャートでサポートされています。

たとえば、Gitalyサブチャートの場合:

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroupChangePolicy: "OnRootMismatch"
```

詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods)を参照してください。

`fsGroupChangePolicy`をサポートしていないKubernetesバージョンの場合、`securityContext`の設定を変更または完全に削除することで、問題を軽減できます。

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroup: ""
      runAsUser: ""
```

{{< alert type="note" >}}

構文例では、`securityContext`設定が完全に削除されます。Helmがデフォルト値をユーザーが指定した設定とマージする方法により、`securityContext: {}`または`securityContext:`の設定は機能しません。

{{< /alert >}}

### 断続的な502エラー {#intermittent-502-errors}

Pumaワーカーによって処理されているリクエストがメモリ制限のしきい値を超えると、ノードのOOMKillerによって強制終了されます。ただし、リクエストを強制終了しても、必ずしもウェブサービスのポッド自体が強制終了または再起動されるとは限りません。この状況により、リクエストは`502`タイムアウトを返します。ログでは、これは`502`エラーのログ記録の直後にPumaワーカーが作成されると表示されます。

```shell
2024-01-19T14:12:08.949263522Z {"correlation_id":"XXXXXXXXXXXX","duration_ms":1261,"error":"badgateway: failed to receive response: context canceled"....
2024-01-19T14:12:24.214148186Z {"component": "gitlab","subcomponent":"puma.stdout","timestamp":"2024-01-19T14:12:24.213Z","pid":1,"message":"- Worker 2 (PID: 7414) booted in 0.84s, phase: 0"}
```

この問題を解決するには、[ウェブサービスポッドのメモリ制限を増やしてください](../charts/gitlab/webservice/_index.md#memory-requestslimits)。

### UPGRADE FAILED - `cannot patch "gitlab-prometheus-server" with kind Deployment` {#upgrade-failed---cannot-patch-gitlab-prometheus-server-with-kind-deployment}

チャート9.0では、Prometheusサブチャートのメジャーバージョンを更新しました。Prometheusのセレクターラベルとバージョンが変更され、手動での操作が必要です。

Prometheusチャートをアップグレードするには、[移行ガイド](../releases/9_0.md#prometheus-upgrade)に従ってください。

## Toolboxのバックアップのアップロードに失敗 {#toolbox-backup-failing-on-upload}

次のようなエラーが発生し、オブジェクトストレージへのアップロードを試みると、バックアップが失敗する場合があります:

```plaintext
An error occurred (XAmzContentSHA256Mismatch) when calling the UploadPart operation: The Content-SHA256 you specified did not match what we received
```

これは、`awscli`ツールとオブジェクトストレージサービスとの間の非互換性が原因である可能性があります。この問題は、Dell ECS S3ストレージを使用している場合にレポートされています。この問題を回避するには、[データ整合性保護を無効にすることができます](../backup-restore/backup.md#data-integrity-protection-with-awscli)。

## ウェブサービス準備プローブが失敗する {#webservice-readiness-probe-fails}

GitLabチャートバージョン9.2（GitLab 18.2）以降、IPv4とIPv6の両方のデュアルスタックサポートがデフォルトで有効になっています。カスタムモニタリングIP許可リストを使用して18.2より前のGitLabバージョンを実行している場合、これにより、ウェブサービスポッドのKubernetesプローブが失敗する可能性があります。

```plaintext
Events:
  Type     Reason                Age                   From                     Message
  ----     ------                ----                  ----                     -------
[snip]
  Warning  Unhealthy             43m (x15 over 44m)    kubelet                  Startup probe failed: HTTP probe failed with statuscode: 404
```

ウェブサービスプローブを修正するには、次のいずれかを行います:

- ウェブサービスのイメージをアップグレードして、チャートのバージョンに一致させます。
- IPv6マップされた同等のアドレス（`::ffff:10.0.0.0`（`10.0.0.0`の場合）など）を使用して、モニタリング許可リストを拡張します。
- IPv4でのみリッスンするようにモニタリングエンドポイントを明示的に設定します（`gitlab.webservice.monitoring.listenAddr=0.0.0.0`）。
- [ノード/カーネルレベルでIPマッピングを無効にします](https://docs.kernel.org/networking/ip-sysctl.html#proc-sys-net-ipv6-variables)。

## 無効: `spec.progressDeadlineSeconds` {#invalid-specprogressdeadlineseconds}

Helm `v3.18.0`を使用している場合、チャートのアップグレード時にこのエラーが発生します:

```shell
Error: UPGRADE FAILED: cannot patch "gitlab-nginx-ingress-controller" with kind Deployment: Deployment.apps "gitlab-nginx-ingress-controller" is invalid: spec.progressDeadlineSeconds: Invalid value: 0: must be greater than minReadySeconds
```

修正するには、Helmクライアントを`v3.18.1`以降にアップグレードします。または、`v3.17.x`にダウングレードできます。

これは[Helmイシュー30878](https://github.com/helm/helm/issues/30878)が原因です。

## 移行に失敗: `TypeError: Invalid type for configuration.` {#migrations-failing-typeerror-invalid-type-for-configuration}

デフォルトでは、GitLabチャートは2つのデータベース接続をセットアップします:

- メインRailsアプリケーションデータベースへ。
- CIデータベースへ。

両方の接続が同じデータベースをターゲットにしている場合、設定の競合を防ぐために、1つのデータベースのみでデータベースタスク（`databaseTasks: true`）を有効にする必要があります。

両方の接続でデータベースタスクが有効になっている場合、移行はこのエラーで失敗します:

```plaintext
Running db:schema:load:main rake task
rake aborted!
TypeError: Invalid type for configuration. Expected Symbol, String, or Hash. Got nil
```

この問題を解決するには、次のいずれかの方法があります:

- 値を変更して`global.psql.databaseTasks`を省略します。
- `databaseTasks`を明示的に設定し、データベースタスクのデータベースを選択します。例: 

  ```yaml
  global:
    psql:
      main:
        databaseTasks: true
      ci:
        databaseTasks: false
  ```
