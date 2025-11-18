---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: チャートを使用したPraefect
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< alert type="warning" >}}

Praefectチャートはまだ開発中です。この実験的なバージョンは、まだ本番環境での使用には適していません。移行には、大幅な手作業が必要になる場合があります。詳細については、[Praefect GAリリース](https://gitlab.com/groups/gitlab-org/charts/-/epics/33)をご覧ください。

{{< /alert >}}

Praefectチャートは、HelmチャートでデプロイされたGitLabインスタンス内の[Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)を管理するために使用されます。

## 既知の問題 {#known-issues}

1. データベースは[手動で作成](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2310)する必要があります。
1. クラスターサイズは固定されています: [Gitaly Cluster (Praefect)はオートスケールをサポートしていません](https://gitlab.com/gitlab-org/gitaly/-/issues/2997)。
1. クラスター内のPraefectインスタンスを使用してクラスター外のGitalyインスタンスを管理することは[サポートされていません](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2662)。

## 要件 {#requirements}

このチャートは、Gitalyチャートを使用します。`global.gitaly`の設定は、このチャートによって作成されたインスタンスを設定するために使用されます。これらの設定のドキュメントは、[Gitalyチャートドキュメント](../gitaly/_index.md)にあります。

_重要_: `global.gitaly.tls`は`global.praefect.tls`から独立しています。これらは個別に設定されます。

デフォルトでは、このチャートは3つのGitalyレプリカを作成します。

## 設定 {#configuration}

このチャートはデフォルトで無効になっています。チャートデプロイの一部として有効にするには、`global.praefect.enabled=true`を設定します。

### レプリカ:  {#replicas}

デプロイするレプリカのデフォルトの数は3です。これは、目的のレプリカ数で`global.praefect.virtualStorages[].gitalyReplicas`を設定することで変更できます。例: 

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
```

### 複数の仮想ストレージ {#multiple-virtual-storages}

複数の仮想ストレージを設定できます（[Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)ドキュメントを参照）。例: 

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
```

これにより、Gitalyのリソースが2セット作成されます。これには、2つのGitaly StatefulSet（仮想ストレージごとに1つ）が含まれます。

管理者は、[新しいリポジトリの保存場所を設定できます](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored)。

### 永続性 {#persistence}

仮想ストレージごとに永続性設定を提供できます。

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
      persistence:
        enabled: true
        size: 50Gi
        accessMode: ReadWriteOnce
        storageClass: storageclass1
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
      persistence:
        enabled: true
        size: 100Gi
        accessMode: ReadWriteOnce
        storageClass: storageclass2
```

## defaultReplicationFactor {#defaultreplicationfactor}

`defaultReplicationFactor`は、各仮想ストレージで設定できます（[レプリケーション係数を設定する](https://docs.gitlab.com/administration/gitaly/praefect/#configure-replication-factor)ドキュメントを参照）。

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 5
      maxUnavailable: 2
      defaultReplicationFactor: 3
    - name: secondary
      gitalyReplicas: 4
      maxUnavailable: 1
      defaultReplicationFactor: 2
```

### Praefectへの移行 {#migrating-to-praefect}

{{< alert type="note" >}}

グループWikiは[APIを使用しても移動できません](https://docs.gitlab.com/api/project_repository_storage_moves/)。

{{< /alert >}}

スタンドアロンのGitalyインスタンスからPraefectセットアップに移行する場合、`global.praefect.replaceInternalGitaly`を`false`に設定できます。これにより、新しいPraefectで管理されるGitalyインスタンスが作成されている間、既存のGitalyインスタンスが確実に保持されます。

```yaml
global:
  praefect:
    enabled: true
    replaceInternalGitaly: false
    virtualStorages:
    - name: virtualStorage2
      gitalyReplicas: 5
      maxUnavailable: 2
```

{{< alert type="note" >}}

Praefectに移行する場合、Praefectの仮想ストレージに`default`という名前を付けることはできません。これは、常に少なくとも1つのストレージに`default`という名前が付けられている必要があるため、名前はPraefect以外の設定ですでに使用されているためです。

{{< /alert >}}

[Gitaly Cluster (Praefect)への移行](https://docs.gitlab.com/administration/gitaly/praefect/#migrate-to-gitaly-cluster-praefect)の手順に従って、`default`ストレージから`virtualStorage2`にデータを移動できます。`global.gitaly.internal.names`で追加のストレージが定義されている場合は、それらのストレージからリポジトリを移行してください。

リポジトリが`virtualStorage2`に移行された後、Praefect設定で`default`という名前のストレージが追加されている場合は、`replaceInternalGitaly`を`true`に戻すことができます。

```yaml
global:
  praefect:
    enabled: true
    replaceInternalGitaly: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
    - name: virtualStorage2
      gitalyReplicas: 5
      maxUnavailable: 2
```

[Gitaly Cluster (Praefect)への移行](https://docs.gitlab.com/administration/gitaly/praefect/#migrate-to-gitaly-cluster-praefect)の手順に再度従うと、必要に応じて`virtualStorage2`から新しく追加された`default`ストレージにデータを移動できます。

最後に、新しいリポジトリの保存場所を設定するには、[リポジトリストレージパスのドキュメント](https://docs.gitlab.com/administration/repository_storage_paths/#choose-where-new-repositories-are-stored)を参照してください。

### データベースの作成 {#creating-the-database}

Praefectは、独自のデータベースを使用して状態を追跡します。Praefectが機能するためには、これを手動で作成する必要があります。

{{< alert type="note" >}}

これらの手順では、バンドルされたPostgreSQLサーバーを使用していることを前提としています。独自のサーバーを使用している場合は、接続方法に多少のバリエーションがあります。

{{< /alert >}}

1. データベースインスタンスにログインします:

   ```shell
   kubectl exec -it $(kubectl get pods -l app.kubernetes.io/name=postgresql -o custom-columns=NAME:.metadata.name --no-headers) -- bash
   ```

   ```shell
   PGPASSWORD=$(echo $POSTGRES_POSTGRES_PASSWORD) psql -U postgres -d template1
   ```

1. データベースユーザーを作成します:

   ```sql
   CREATE ROLE praefect WITH LOGIN;
   ```

1. データベースユーザーのパスワードを設定します。

   デフォルトでは、`shared-secrets`ジョブはシークレットを生成します。

   1. パスワードをフェッチします:

      ```shell
      kubectl get secret RELEASE_NAME-praefect-dbsecret -o jsonpath="{.data.secret}" | base64 --decode
      ```

   1. `psql`プロンプトでパスワードを設定します:

      ```sql
      \password praefect
      ```

1. データベースを作成します:

   ```sql
   CREATE DATABASE praefect WITH OWNER praefect;
   ```

### TLS経由でのPraefectの実行 {#running-praefect-over-tls}

Praefectは、TLS経由でクライアントおよびGitalyノードとの通信をサポートします。これは、`global.praefect.tls.enabled`と`global.praefect.tls.secretName`の設定によって制御されます。TLS経由でPraefectを実行するには、次の手順に従います:

1. Helmチャートは、TLS経由でPraefectと通信するために証明書が提供されることを想定しています。この証明書は、存在するすべてのPraefectノードに適用される必要があります。したがって、これらのノードの各ホスト名はすべて、証明書のサブジェクト代替名（SAN）として追加するか、またはワイルドカードを使用できます。

   使用するホスト名を知るには、Toolboxポッドの`/srv/gitlab/config/gitlab.yml`ファイルを確認し、その中の`repositories.storages`で指定されているさまざまな`gitaly_address`フィールドを確認してください。

   ```shell
   kubectl exec -it <Toolbox Pod> -- grep gitaly_address /srv/gitlab/config/gitlab.yml
   ```

{{< alert type="note" >}}

内部Praefectポッド用のカスタム署名証明書を生成するための基本的なスクリプトは、[このリポジトリにあります](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh)。ユーザーは、そのスクリプトを使用して、適切なSAN属性を持つ証明書を生成できます。

{{< /alert >}}

1. 作成した証明書を使用してTLSシークレットを作成します。

   ```shell
   kubectl create secret tls <secret name> --cert=praefect.crt --key=praefect.key
   ```

1. `--set global.praefect.tls.enabled=true`を渡してHelmチャートを再度デプロイします。

TLS経由でGitalyを実行する場合は、仮想ストレージごとにシークレット名を指定する必要があります。

```yaml
global:
  gitaly:
    tls:
      enabled: true
  praefect:
    enabled: true
    tls:
      enabled: true
      secretName: praefect-tls
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
      tlsSecretName: default-tls
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
      tlsSecretName: vs2-tls
```

### インストールコマンドラインオプション {#installation-command-line-options}

以下の表に、`helm install`コマンドラインに`--set`フラグを使用して指定できるすべてのチャートの設定を示します。

| パラメータ                                                | デフォルト                                           | 説明 |
|----------------------------------------------------------|---------------------------------------------------|-------------|
| common.labels                                            | `{}`                                              | このチャートによって作成されたすべてのオブジェクトに適用される補助ラベル。 |
| failover.enabled                                         | はい                                              | Praefectがノード障害時にフェイルオーバーを実行するかどうか |
| failover.readonlyAfter                                   | いいえ                                             | フェイルオーバー後にノードが読み取り専用モードになるかどうか |
| autoMigrate                                              | はい                                              | 起動時に移行を自動的に実行する |
| image.repository                                         | `registry.gitlab.com/gitlab-org/build/cng/gitaly` | 使用するデフォルトのイメージリポジトリ。Praefectは、Gitalyイメージの一部としてバンドルされています |
| podLabels                                                | `{}`                                              | 補助ポッドラベル。セレクターには使用されません。 |
| ntpHost                                                  | `pool.ntp.org`                                    | 現在の時刻についてPraefectが要求する必要があるNTPサーバーを設定します。 |
| service.name                                             | `praefect`                                        | 作成するサービスの名前 |
| service.type                                             | ClusterIP                                         | 作成するサービスの種類 |
| service.internalPort                                     | 8075                                              | Praefectポッドがリッスンする内部ポート番号 |
| service.externalPort                                     | 8075                                              | Praefectサービスがクラスターで公開するポート番号 |
| init.resources                                           |                                                   |             |
| init.image                                               |                                                   |             |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                           | initコンテナ固有: プロセスがプロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                            | initコンテナ固有: コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                       | initコンテナ固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| extraEnvFrom                                             |                                                   | 公開する他のデータソースからの追加の環境変数のリスト |
| logging.level                                            |                                                   | ログレベル   |
| logging.format                                           | `json`                                            | ログ形式  |
| logging.sentryDsn                                        |                                                   | Sentry DSN URL - Goサーバーからの例外 |
| logging.sentryEnvironment                                |                                                   | ログに使用するSentry環境変数 |
| `metrics.enabled`                                        | `true`                                            | メトリクスエンドポイントをスクレイプために利用できるようにするかどうか |
| `metrics.port`                                           | `9236`                                            | メトリクスエンドポイントポート |
| `metrics.separate_database_metrics`                      | `true`                                            | trueの場合、メトリクスのスクレイプはデータベースクエリを実行しません。falseに設定すると[パフォーマンスの問題が発生する可能性があります](https://gitlab.com/gitlab-org/gitaly/-/issues/3796) |
| `metrics.path`                                           | `/metrics`                                        | メトリクスエンドポイント |
| `metrics.serviceMonitor.enabled`                         | `false`                                           | メトリクスのスクレイプを管理するためにPrometheusオペレーターを有効にするためにServiceMonitorを作成する場合は、これを有効にすると`prometheus.io`スクレイプ注釈が削除されることに注意してください |
| `affinity`                                               | `{}`                                              | ポッド割り当ての[アフィニティルール](../_index.md#affinity) |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                              | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                              | ServiceMonitorの追加エンドポイント設定 |
| securityContext.runAsUser                                | 1,000                                              |             |
| securityContext.fsGroup                                  | 1,000                                              |             |
| securityContext.fsGroupChangePolicy                      |                                                   | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                  | 使用するSeccompプロファイル |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                           | コンテナのプロセスがプロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                            | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                       | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.annotations`                             | `{}`                                              | ServiceAccount注釈 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                           | デフォルトのServiceAccountアクセストークンをポッドにマップするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                           | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                           | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                   | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます |
| serviceLabels                                            | `{}`                                              | 補助サービスラベル |
| statefulset.strategy                                     | `{}`                                              | statefulsetが利用する更新戦略を設定できます |

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマップするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccount注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます。 |

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。
