---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリのメタデータデータベース
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/5521)されました（[beta](https://docs.gitlab.com/policy/development_stages_support/#beta)）機能として。
- GitLab 17.3で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)になりました。

{{< /history >}}

メタデータデータベースは、オンラインガベージコレクションなど、多くの新しいレジストリ機能を提供し、多くのレジストリ操作の効率性を高めます。

既存のレジストリがある場合は、メタデータデータベースに移行できます。

データベースが有効になっている機能の一部は、GitLab.comでのみ有効になっており、レジストリデータベースの自動データベースプロビジョニングは利用できません。コンテナレジストリデータベースに関連する機能のステータスについては、[管理ドキュメント](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support)の機能サポートセクションを確認してください。

## 外部メタデータデータベースを作成 {#create-an-external-metadata-database}

本番環境では、外部メタデータデータベースを作成する必要があります。

前提要件: 

- [外部PostgreSQLサーバー](../../advanced/external-db/_index.md)をセットアップします。

外部PostgreSQLサーバーをセットアップした後:

1. メタデータデータベースのシークレットを作成します:

   ```shell
   kubectl create secret generic RELEASE_NAME-registry-database-password --from-literal=password=<your_registry_password>
    ```

1. データベースサーバーにログインします。
1. 次のSQLコマンドを使用して、ユーザー名とデータベースを作成します:

   ```sql
   -- Create the registry user
   CREATE USER registry WITH PASSWORD '<your_registry_password>';

   -- Create the registry database
   CREATE DATABASE registry OWNER registry;
   ```

1. クラウドマネージドサービスの場合は、必要に応じて追加のロールを付与します:

   {{< tabs >}}

   {{< tab title="Amazon RDS" >}}

   ```sql
   GRANT rds_superuser TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Azure database" >}}

   ```sql
   GRANT azure_pg_admin TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Google Cloud SQL" >}}

   ```sql
   GRANT cloudsqlsuperuser TO registry;
   ```

   {{< /tab >}}

   {{< /tabs >}}

## 組み込みメタデータデータベースを作成 {#create-a-built-in-metadata-database}

{{< alert type="warning" >}}

組み込みクラウドネイティブメタデータデータベースは、トライアル目的でのみ使用できます。本番環境で使用しないでください。

{{< /alert >}}

### データベースを自動的に作成 {#create-the-database-automatically}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5931)されました。

{{</ history >}}

前提要件: 

- Helmチャート9.3バージョン以降。

GitLabチャートのインストール時に`postgresql.install=true`を設定する新しいインストールでは、レジストリデータベース、ユーザー名、および共有シークレット`RELEASE-registry-database-password`が自動的に作成されます。

この自動プロビジョニング:

- 専用の`registry`データベースを作成します。
- 適切な権限を持つ`registry`ユーザー名をセットアップします。
- データベースパスワードを含む`RELEASE-registry-database-password`シークレットを生成します。
- 必要なデータベーススキーマと権限を設定します。

自動データベース作成を使用すると、手動データベース作成手順をスキップして、すぐに[メタデータデータベースを有効にする](#enable-the-metadata-database)ことができます。

### データベースを手動で作成 {#create-the-database-manually}

組み込みPostgreSQLサーバーを使用してメタデータデータベースを手動で作成するには:

1. データベースパスワードでシークレットを作成します:

   ```shell
   kubectl create secret generic RELEASE_NAME-registry-database-password --from-literal=password=<your_registry_password>
   ```

1. データベースインスタンスにログインします:

   ```shell
   kubectl exec -it $(kubectl get pods -l app.kubernetes.io/name=postgresql -o custom-columns=NAME:.metadata.name --no-headers) -- bash
   ```

   ```shell
   PGPASSWORD=${POSTGRES_POSTGRES_PASSWORD} psql -U postgres -d template1
   ```

1. データベースユーザーを作成します:

   ```sql
   CREATE ROLE registry WITH LOGIN;
   ```

1. データベースユーザー名のパスワードを設定します。

   1. パスワードをフェッチします:

      ```shell
      kubectl get secret RELEASE_NAME-registry-database-password -o jsonpath="{.data.password}" | base64 --decode
      ```

   1. `psql`プロンプトでパスワードを設定します:

      ```sql
      \password registry
      ```

1. データベースを作成します:

   ```sql
   CREATE DATABASE registry WITH OWNER registry;
   ```

1. PostgreSQLコマンドラインから、次に`exit`を使用してコンテナから安全に終了します:

   ```shell
   template1=# exit
   ...@gitlab-postgresql-0/$ exit
   ```

## メタデータデータベースを有効にする {#enable-the-metadata-database}

データベースを作成したら、有効にします。既存のコンテナレジストリを移行する場合は、追加の手順が必要です。

### 前提要件 {#prerequisites}

前提要件: 

- GitLab 17.3以降。
- レジストリポッドからアクセス可能な、[必要なバージョンのPostgreSQL](https://docs.gitlab.com/install/requirements/#postgresql)のデプロイ。
- KubernetesクラスタリングとHelmデプロイにローカルでアクセスします。
- レジストリポッドへのSSHアクセス。

レジストリ管理ガイドの[開始する前に](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#before-you-start)のセクションも読んでください。

{{< alert type="note" >}}

さまざまなテストおよびユーザーレジストリのインポート時間の一覧については、[イシュー423459のこのレポート](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#completed-tests-and-user-reports)を参照してください。お使いのレジストリデプロイは一意であり、インポート時間はイシューでレポートされている時間よりも長くなる可能性があります。

{{< /alert >}}

### 新しいレジストリを有効にする {#enable-for-new-registries}

新しいコンテナレジストリのデータベースを有効にするには:

1. リリースの現在のHelm値を取得し、ファイルに保存します。たとえば、`gitlab`という名前のリリースと、`values.yml`という名前のファイルの場合:

   ```shell
   helm get values gitlab > values.yml
   ```

1. `values.yml`ファイルに次の行を追加します:

   ```yaml
   registry:
     enabled: true
     database:
       enabled: true
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full
       # these settings are inherited from `global.psql.ssl`
       ssl:
         secret: gitlab-registry-postgresql-ssl # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. オプション。スキーマ移行が正しく適用されていることを確認します。次のいずれかの方法があります:

   - 移行ジョブのログ出力を確認します。例:

     ```shell
     kubectl logs jobs/gitlab-registry-migrations-1
     ...
     OK: applied 154 migrations in 13.752s
     ```

   - または、Postgresデータベースに接続し、`schema_migrations`テーブルに対してクエリを実行します:

     ```sql
     SELECT * FROM schema_migrations;
     ```

     `applied_at`列のタイムスタンプがすべての行に入力されていることを確認します。

レジストリは、メタデータデータベースを使用する準備ができました!

### 既存のレジストリを有効にしてインポートする {#enable-for-and-import-existing-registries}

既存のコンテナレジストリデータを1つのステップまたは3つのステップでインポートできます。いくつかの要因が移行の期間に影響を与えます:

- 既存のレジストリデータのサイズ。
- PostgresSQLインスタンスの仕様。
- クラスタリングで実行されているレジストリポッドの数。
- レジストリ、PostgresSQL、および設定されたオブジェクトストレージ間のネットワークレイテンシー。

{{< alert type="note" >}}

インポートプロセスを自動化する作業は、[イシュー5293](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5293)で追跡されています。

{{< /alert >}}

1ステップまたは3ステップのインポートを試みる前に、リリースの現在のHelm値を取得し、ファイルに保存します。たとえば、`gitlab`という名前のリリースと、`values.yml`という名前のファイルの場合:

```shell
helm get values gitlab > values.yml
```

#### 1つのステップでインポートする {#import-in-one-step}

1ステップのインポートを実行する場合は、以下に注意してください:

- レジストリは、インポート中は`read-only`読み取り専用モードのままにする必要があります。
- インポートが実行されているポッドが終了した場合、プロセスを完全に再起動する必要があります。このプロセスを改善する作業は、[イシュー5293](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5293)で追跡されています。

既存のコンテナレジストリを1つのステップでメタデータデータベースにインポートするには:

1. `values.yml`ファイルの`registry:`セクションを見つけて、`database`セクションを追加します。以下を設定します:
   - `database.configure`を`true`に設定します。
   - `database.enabled`を`false`に設定します。
   - `maintenance.readonly.enabled`を`true`に設定します。
   - `migrations.enabled`を`true`に設定します。

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: true  # must remain set to true while the migration is executed
     database:
       configure: true  # must be true for the migration step
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. Helmインストールをアップグレードして、デプロイの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. SSH経由でレジストリポッドの1つに接続します（たとえば、`gitlab-registry-5ddcd9f486-bvb57`という名前のポッドの場合）:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. ホームディレクトリに変更してから、次のコマンドを実行します:

   ```shell
   cd ~
   /usr/bin/registry database import /etc/docker/registry/config.yml
   ```

1. コマンドが正常に完了すると、すべてのイメージが完全にインポートされます。データベースを有効にして、設定で読み取り専用モードをオフにすることができます:

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: false
     database:
       configure: true  # once database.enabled is set to true, this option can be removed
       enabled: true
       name: registry
       user: registry
       password:
         secret: gitlab-registry-database-password
         key: password
       migrations:
         enabled: true
   ```

1. Helmインストールをアップグレードして、デプロイの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

メタデータデータベースをすべての操作に使用できるようになりました!

#### 3つのステップでインポートする {#import-in-three-steps}

既存のコンテナレジストリデータを3つの個別のステップでメタデータデータベースにインポートできます。これは、次の場合に推奨されます:

- レジストリに大量のデータが含まれている。
- 移行中のダウンタイムを最小限に抑える必要がある。

3つのステップでインポートするには、次の操作を行う必要があります:

1. リポジトリの事前インポート
1. すべてのリポジトリデータをインポートする
1. 共通blobをインポートする

{{< alert type="note" >}}

ユーザーは、ステップ1のインポートが[1時間あたり2〜4 TBのレート](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)で完了したことをレポートしています。速度が遅い場合、100 TBを超えるデータを持つレジストリでは、48時間以上かかる可能性があります。

{{< /alert >}}

##### ステップ1.リポジトリを事前にインポートする {#step-1-pre-import-repositories}

大規模なインスタンスの場合、このプロセスは、レジストリのサイズに応じて、完了までに数時間または数日かかる場合があります。このプロセス中にレジストリを引き続き使用できます。

{{< alert type="warning" >}}

インポートを再起動することは[まだ不可能](https://gitlab.com/gitlab-org/container-registry/-/issues/1162)であるため、インポートを完了まで実行することが重要です。操作を停止する必要がある場合は、この手順を再起動する必要があります。

{{< /alert >}}

1. `values.yml`ファイルの`registry:`セクションを見つけて、`database`セクションを追加します。以下を設定します:
   - `database.configure`を`true`に設定します。
   - `database.enabled`を`false`に設定します。
   - `migrations.enabled`を`true`に設定します。

   ```yaml
   registry:
     enabled: true
     database:
       configure: true
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. ファイルを保存し、Helmインストールをアップグレードして、デプロイの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. SSHを使用してレジストリポッドの1つに接続します。たとえば、`gitlab-registry-5ddcd9f486-bvb57`という名前のポッドの場合:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. ホームディレクトリに変更してから、次のコマンドを実行します:

   ```shell
   cd ~
   /usr/bin/registry database import --step-one /etc/docker/registry/config.yml
   ```

`registry import complete`が表示されると、最初の手順は完了です。

{{< alert type="note" >}}

必要なダウンタイムの量を減らすために、できるだけ早く次のステップをスケジュールするようにしてください。理想的には、ステップ1の完了後1週間以内。次のステップの前にレジストリに書き込まれた新しいデータがあると、そのステップに時間がかかるようになります。

{{< /alert >}}

##### ステップ2.すべてのリポジトリデータをインポートする {#step-2-import-all-repository-data}

このステップでは、レジストリを`read-only`読み取り専用モードに設定する必要があります。このプロセス中にダウンタイムに十分な時間を確保してください。

1. `values.yml`ファイルで、レジストリを`read-only`読み取り専用モードに設定します:

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: true   # must be true!
     database:
       configure: true
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. ファイルを保存し、Helmインストールをアップグレードして、デプロイの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. SSHを使用してレジストリポッドの1つに接続します。たとえば、`gitlab-registry-5ddcd9f486-bvb57`という名前のポッドの場合:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. ホームディレクトリに変更してから、次のコマンドを実行します:

   ```shell
   cd ~
   /usr/bin/registry database import --step-two /etc/docker/registry/config.yml
   ```

1. コマンドが正常に完了すると、すべてのイメージが完全にインポートされます。データベースを有効にして、設定で読み取り専用モードをオフにすることができます:

   ```yaml
   registry:
     enabled: true
     maintenance:        # this section can be removed
       readonly:
         enabled: false
     database:
       configure: true  # once database.enabled is set to true, this option can be removed
       enabled: true   # must be true!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. ファイルを保存し、Helmインストールをアップグレードして、デプロイの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

メタデータデータベースをすべての操作に使用できるようになりました!

##### ステップ3.共通blobをインポートする {#step-3-import-common-blobs}

レジストリは、メタデータにデータベースを完全に使用するようになりましたが、まだ潜在的に未使用のレイヤーblobへのアクセス権がありません。

プロセスを完了するには、移行の最後の手順を実行します:

```shell
cd ~
/usr/bin/registry database import --step-three /etc/docker/registry/config.yml
```

コマンドが正常に完了すると、レジストリはデータベースに完全に移行されました!

## データベースの移行 {#database-migrations}

コンテナレジストリは、2種類の移行をサポートしています:

- **通常のスキーマの移行**: 新しいアプリケーションコードをデプロイする前に実行する必要があるデータベース構造への変更。これらは、デプロイの遅延を回避するために高速である必要があります。

- **デプロイ後の移行**: アプリケーションの実行中に実行できるデータベース構造への変更。大規模なテーブルにインデックスを作成するなどのより長い操作に使用され、起動の遅延と拡張されたアップグレードのダウンタイムを回避します。

### データベース移行を適用する {#apply-database-migrations}

デフォルトでは、`database.migrations.enabled`が`true`に設定されている場合、レジストリチャートは、通常のスキーマとデプロイ後の移行の両方を自動的に適用します。

アップグレード中のダウンタイムを削減するために、デプロイ後の移行をスキップし、アプリケーションの起動後に手動で適用できます:

1. レジストリデプロイの`ExtraEnv`を使用して、`SKIP_POST_DEPLOYMENT_MIGRATIONS`環境変数を`true`に設定します:

   ```yaml
   registry:
     extraEnv:
       SKIP_POST_DEPLOYMENT_MIGRATIONS: true
   ```

1. アップグレード後、[レジストリポッドに接続する](_index.md#running-administrative-commands-against-the-container-registry)。

1. 保留中のデプロイ後の移行を適用します:

   ```shell
   registry database migrate up /etc/docker/registry/config.yml
   ```

{{< alert type="note" >}}

`migrate up`コマンドは、移行の適用方法を制御するために使用できる追加のフラグを提供します。詳細については、`registry database migrate up --help`を実行します。

{{< /alert >}}

## トラブルシューティング {#troubleshooting}

### エラー: `panic: interface conversion: interface {} is nil, not bool` {#error-panic-interface-conversion-interface--is-nil-not-bool}

既存のレジストリをインポートすると、このエラーが表示されることがあります:

```shell
panic: interface conversion: interface {} is nil, not bool
```

これは、レジストリバージョン`v4.15.2-gitlab`およびGitLab 17.9以降で修正された既知の[イシュー](https://gitlab.com/gitlab-org/container-registry/-/merge_requests/2041)です。

このイシューを回避するには、レジストリバージョンをアップグレードします:

1. `values.yml`ファイルで、レジストリイメージタグ付けを設定します:

   ```yaml
   registry:
     image:
       tag: v4.15.2-gitlab
   ```

1. Helmインストールをアップグレードします:

   ```shell
   helm upgrade gitlab -f values.yml
   ```

または、レジストリの設定を手動で更新することもできます:

- `/etc/docker/registry/config.yml`で、ストレージプロバイダーの`parallelwalk`を`false`に設定します。例: S3を使用する場合:

  ```yaml
  storage:
    s3:
      parallelwalk: false
  ```
