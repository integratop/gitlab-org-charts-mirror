---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-Migrationsチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`migrations`サブチャートは、GitLabで使用されるデータベースのシード/移行を処理する単一の[ジョブ](https://kubernetes.io/docs/concepts/workloads/controllers/job/)を提供します。このチャートは、GitLab Railsコードベースを使用して実行されます。

[ClickHouse](../../../development/clickhouse.md)が有効になっている場合、このサブチャートは[ClickHouse](../../../development/clickhouse.md)の移行も実行します。

移行後、このジョブは、[承認されたキーファイルへの書き込み](https://docs.gitlab.com/administration/operations/fast_ssh_key_lookup/#setting-up-fast-lookup-via-gitlab-shell)をオフにするために、データベース内のアプリケーション設定も編集します。SSH `AuthorizedKeysCommand`でGitLab Authorized Keys APIを使用することのみをサポートしており、承認されたキーファイルへの書き込みはサポートしていません。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされるKubernetesクラスタリングから到達可能な外部サービスとして提供されるRedisおよびPostgreSQLに依存します。

インストールでClickHouseが有効になっている場合、このチャートはClickHouseにも依存します。

## 設計上の選択 {#design-choices}

`migrations`チャートは、チャートがインストールされるたび、または新しい[チャートのバージョン](https://helm.sh/docs/topics/charts/#charts-and-versioning) 、[appVersion](https://helm.sh/docs/topics/charts/#the-appversion-field) 、または値の変更でチャートがアップグレードされるたびに、新しい移行[ジョブ](https://kubernetes.io/docs/concepts/workloads/controllers/job/)を作成します。

このチャートをインストールおよびアップグレードするために`helm install`と`helm upgrade`を使用すると、このチャートによって作成されたジョブは、次のチャートのアップグレードまでクラスタリング内のオブジェクトとして残ります。これは、移行ログを監視できるようにするためです。何らかの形式のログシッピングが完了したら、これらのオブジェクトの永続性を再検討できます。

`helm template`および`kubectl apply`または同様のツールによって生成されたマニフェストを使用してデプロイが作成された場合、古い移行ジョブオブジェクトはクラスタリングから削除されません。

このチャートで使用されているコンテナには、現在ここで使用していない追加の最適化がいくつかあります。主に、Railsアプリケーションを起動して確認しなくても、すでに最新の状態になっている場合は、移行の実行をすばやくスキップできる機能です。この最適化では、移行ステータスを保持する必要があります。これは、現時点ではこのチャートでは行っていません。将来、このチャートに移行ステータスのストレージサポートを導入する予定です。

## 設定 {#configuration}

`migrations`チャートは、外部サービスとチャートの設定の2つの部分で構成されています。

## インストールコマンドラインオプション {#installation-command-line-options}

以下の表には、`helm install`コマンドに`--set`フラグを使用して指定できる、可能なすべてのチャートの設定が含まれています

| パラメータ                   | 説明                              | デフォルト           |
| --------------------------- | ---------------------------------------- | ----------------  |
| `common.labels`             | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。  | `{}` |
| `image.repository`          | 移行イメージリポジトリ              | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee` |
| `image.tag`                 | 移行イメージタグ                     |                   |
| `image.pullPolicy`          | 移行のプルポリシー                   | `Always`          |
| `image.pullSecrets`         | イメージリポジトリのシークレット         |                   |
| `init.image.repository`     | initContainerイメージリポジトリ           | `registry.gitlab.com/gitlab-org/build/cng/gitlab-base` |
| `init.image.tag`            | initContainerイメージタグ                  | `master`          |
| `init.image.containerSecurityContext` | initコンテナsecurityContextオーバーライド | `{}`    |
| `init.containerSecurityContext.allowPrivilegeEscalation` | initContainer固有: プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します                                                                             | `false`                                                                               |
| `init.containerSecurityContext.runAsNonRoot`             | initContainer固有: コンテナを非rootユーザーで実行するかどうかを制御します                                                                                                | `true`                                                                                |
| `init.containerSecurityContext.capabilities.drop`        | initContainer固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します                                               | `[ "ALL" ]`                                                                           |
| `enabled`                   | 移行の有効フラグ                   | `true`            |
| `tolerations`               | ポッド割り当ての容認ラベル     | `[]`              |
| `affinity`                  | ポッド割り当ての[アフィニティルール](../_index.md#affinity)            | `{}`              |
| `annotations`               | ジョブ仕様の注釈             | `{}`              |
| `podAnnotations`            | pob仕様の注釈             | `{}`              |
| `podLabels`                 | 補足ポッドのラベル。セレクターには使用されません。 |   |
| `redis.serviceName`         | Redisサービス名                       | `redis`           |
| `psql.serviceName`          | PostgreSQLを提供するサービスの名前     | `release-postgresql` |
| `psql.password.secret`      | psqlシークレット                              | `gitlab-postgres` |
| `psql.password.key`         | psqlシークレット内のpsqlパスワードへのキー      | `psql-password`   |
| `psql.port`                 | PostgreSQLサーバーポートを設定します。これは、`global.psql.port`より優先されます。 |   |
| `resources.requests.cpu`    | GitLab移行の最小CPU                  | `250m`                                   |
| `resources.requests.memory` | GitLab移行の最小メモリ               | `200Mi`                                  |
| `securityContext.fsGroup`   | ポッドを開始するグループID | `1000`                                   |
| `securityContext.runAsUser` | ポッドを開始するユーザーID  | `1000`                                   |
| `securityContext.fsGroupChangePolicy` | ボリュームの所有権とアクセス許可を変更するためのポリシー（Kubernetes 1.23が必要です） |    |
| `securityContext.seccompProfile.type`                    | 使用するSeccompプロファイル                                                                                                                                                          | `RuntimeDefault`                                                                      |
| `containerSecurityContext.runAsUser`  | コンテナの開始元となる[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします | `1000` |
| `containerSecurityContext.allowPrivilegeEscalation`      | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します                                                                                    | `false`                                                                               |
| `containerSecurityContext.runAsNonRoot`                  | コンテナを非rootユーザーで実行するかどうかを制御します                                                                                                                        | `true`                                                                                |
| `containerSecurityContext.capabilities.drop`             | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します                                                                | `[ "ALL" ]`                                                                           |
| `serviceAccount.annotations` | ServiceAccount注釈              | `{}`                                                    |
| `serviceAccount.automountServiceAccountToken`| ポッドにデフォルトのServiceAccountアクセストークンをマップするかどうかを示します | `false`    |
| `serviceAccount.create`     | ServiceAccountを作成するかどうかを示します                                      | `false`           |
| `serviceAccount.enabled`    | ServiceAccountを使用するかどうかを示します                                | `false`           |
| `serviceAccount.name`       | ServiceAccountの名前。設定しない場合、完全なチャート名が使用されます  |                   |
| `extraInitContainers`       | 含める追加のinitコンテナのリスト |                   |
| `extraContainers`           | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列      |                   |
| `extraVolumes`              | 作成する追加のボリュームのリスト          |                   |
| `extraVolumeMounts`         | 実行する追加のボリュームマウントのリスト       |                   |
| `extraEnv`                  | 公開する追加の環境変数のリスト |              |
| `extraEnvFrom`              | 公開する他のデータソースからの追加の環境変数のリスト|                              |
| `priorityClassName`         | [優先](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)クラスがポッドに割り当てられています。 |                   |

## チャート設定の例 {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv`を使用すると、ポッド内のすべてのコンテナで追加の環境変数を公開できます。

`extraEnv`の使用例を以下に示します:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナの起動時に、環境変数が公開されていることを確認できます:

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで、他のデータソースからの追加の環境変数を公開できます。

`extraEnvFrom`の使用例を以下に示します:

```yaml
extraEnvFrom:
  MY_NODE_NAME:
    fieldRef:
      fieldPath: spec.nodeName
  MY_CPU_REQUEST:
    resourceFieldRef:
      containerName: test-container
      resource: requests.cpu
  SECRET_THING:
    secretKeyRef:
      name: special-secret
      key: special_token
      # optional: boolean
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに対して認証を行い、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)にあります。

`pullSecrets`の使用例を以下に示します:

```YAML
image:
  repository: my.migrations.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccount注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | の設定は、デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定しない場合、完全なチャート名が使用されます。 |

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

## このチャートのCommunity Editionの使用 {#using-the-community-edition-of-this-chart}

デフォルトの場合、HelmチャートではGitLabのEnterprise Editionを使用します。必要に応じて、代わりにCommunity Editionを使用できます。[2つのエディションの違い](https://about.gitlab.com/install/ce-or-ee/)の詳細については、こちらをご覧ください。

Community Editionを使用するには、`image.repository`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ce`に設定します

## 外部サービス {#external-services}

### Redis {#redis}

```YAML
redis:
  host: redis.example.com
  serviceName: redis
  port: 6379
  sentinels:
    - host: sentinel1.example.com
      port: 26379
  password:
    secret: gitlab-redis
    key: redis-password
```

#### host {#host}

使用するデータベースが格納されているRedisサーバーのホスト名。`serviceName`の代わりとして省略できます。Redis Sentinelを使用している場合、`host`属性は、`sentinel.conf`で指定されているクラスタ名に設定する必要があります。

#### serviceName {#servicename}

Redisデータベースを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、RedisをGitLabチャート全体の一部として使用する場合に便利です。これはデフォルトで`redis`になります

#### ポート {#port}

Redisサーバーへの接続に使用するポート。`6379`がデフォルトです。

#### password {#password}

Redisの`password`属性には、2つのサブキーがあります:

- `secret`は、プル元のKubernetes `Secret`の名前を定義します。
- `key`は、上記のシークレットのうちパスワードを含むキーの名前を定義します。

#### sentinels {#sentinels}

`sentinels`属性を使用すると、Redis HAクラスタリングへの接続が可能になります。サブキーは、各Sentinel接続を記述します。

- `host`は、Sentinelサービスのホスト名を定義します
- `port`は、Sentinelサービスに到達するためのポート番号を定義し、デフォルトは`26379`です

_注_: 現在のRedis Sentinelサポートは、GitLabチャートとは別にデプロイされたSentinelのみをサポートしています。そのため、`redis.install=false`に設定して、GitLabチャートによるRedisのデプロイを無効にする必要があります。Redisパスワードを含むKubernetesシークレットは、GitLabチャートをデプロイする前に手動で作成する必要があります。

### PostgreSQL {#postgresql}

```yaml
psql:
  host: psql.example.com
  serviceName: pgbouncer
  port: 5432
  database: gitlabhq_production
  username: gitlab
  preparedStatements: false
  password:
    secret: gitlab-postgres
    key: psql-password
```

#### host {#host-1}

使用するデータベースを持つPostgreSQLサーバーのホスト名。これは、`postgresql.install=true`（デフォルトの非本番環境）の場合に省略できます。

#### serviceName {#servicename-1}

PostgreSQLデータベースを操作しているサービス名の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名をテンプレート処理します。

#### ポート {#port-1}

PostgreSQLサーバーへの接続に使用するポート。`5432`がデフォルトです。

#### データベース {#database}

PostgreSQLサーバーで使用するデータベースの名前。これはデフォルトで`gitlabhq_production`になります。

#### preparedStatements {#preparedstatements}

PostgreSQLサーバーとの通信時にプリペアドステートメントを使用するかどうか。`false`がデフォルトです。

#### ユーザー名 {#username}

データベースへの認証に使用するユーザー名。これはデフォルトで`gitlab`になります

#### password {#password-1}

PostgreSQLの`password`属性には、2つのサブキーがあります:

- `secret`は、プル元のKubernetes `Secret`の名前を定義します。
- `key`は、上記のシークレットのうちパスワードを含むキーの名前を定義します。

### ClickHouse（オプション） {#clickhouse-optional}

``` yaml
global:
  clickhouse:
    enabled: true
    main:
      url: https://clickhouse.example.com
      database: default
      username: default
      password:
        secret: gitlab-clickhouse-password
        key: main_password
```

インストールでClickHouseが有効になっている場合、このチャートはClickHouseデータベースの移行も実行します。ClickHouseの設定は、`global.clickhouse`キーの下に指定する必要があります。

#### `main.url` {#mainurl}

ClickHouseインスタンスのURL。

#### `main.database` {#maindatabase}

ClickHouseのデータベース名。

#### `main.username` {#mainusername}

ClickHouseで認証するために使用するユーザー名。

#### `main.password` {#mainpassword}

ClickHouseの`password`属性には、2つのサブキーが含まれています:

- `secret`は、プル元のKubernetesシークレットの名前を定義します。
- `key`は、パスワードを含む上記の`secret`内のキーの名前を定義します。
