---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部データベースでGitLabチャートを設定する
---

{{< alert type="warning" >}}

バンドルされているbitnami PostgreSQLチャートは、本番環境に対応していません。本番環境に対応したGitLabチャートのデプロイでは、外部データベースを使用してください。

{{< /alert >}}

前提要件: 

- [必要なバージョンのPostgreSQL](https://docs.gitlab.com/install/requirements/#postgresql)のデプロイ。お持ちでない場合は、[AWS RDS PostgreSQL](https://aws.amazon.com/rds/postgresql/)や[GCP Cloud SQL](https://cloud.google.com/sql/)のようなクラウド提供のソリューションを検討してください。別のソリューションとして、[Linuxパッケージ](external-omnibus-psql.md)を検討してください。
- デフォルトでは、`gitlabhq_production`という名前の空のデータベース。
- データベースへのフルアクセス権を持つユーザー。詳細については、[外部データベースのドキュメント](https://docs.gitlab.com/administration/postgresql/external/)を参照してください。
- データベースユーザーのパスワードが設定された[Kubernetesシークレット](https://kubernetes.io/docs/concepts/configuration/secret/)。
- [`amcheck`、`pg_trgm`、`btree_gist`の拡張機能](https://docs.gitlab.com/install/postgresql_extensions/)。GitLabにスーパーユーザーフラグを持つアカウントを提供しない場合は、データベースのインストールに進む前に、これらの拡張機能が読み込むようにしてください。

ネットワーキングの前提条件:

- データベースがクラスタリングから到達可能であることを確認してください。ファイアウォールポリシーがトラフィックを許可していることを確認してください。
- PostgreSQLをロードバランシングクラスタリングおよびサービスディスカバリ用のKubernetes DNSとして使用する場合は、`bitnami/postgresql`チャートのインストール時に`--set slave.service.clusterIP=None`を使用します。この設定では、PostgreSQLセカンダリインスタンスごとにDNS `A`レコードが作成されるように、PostgreSQLセカンダリサービスをヘッドレスサービスとして構成します。

  サービスディスカバリにKubernetes DNSを使用する方法の例については、[`examples/database/values-loadbalancing-discover.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/database/values-loadbalancing-discover.yaml)を参照してください。

外部データベースを使用するようにGitLabチャートを構成するには:

1. 次のパラメータを設定します:

   - `postgresql.install`: `false`に設定して、埋め込みデータベースを無効にします。
   - `global.psql.host`: 外部データベースのホスト名に設定します。ドメインまたはIPアドレスを指定できます。
   - `global.psql.password.secret`: [`gitlab`ユーザーのデータベースパスワードを含むシークレット](../../installation/secrets.md#postgresql-password)の名前。
   - `global.psql.password.key`: シークレット内で、パスワードを含むキー。

1. オプション。デフォルトを使用していない場合、次の項目をさらにカスタマイズできます:

   - `global.psql.port`: データベースが利用可能なポート。`5432`がデフォルトです。
   - `global.psql.database`: データベース名。
   - `global.psql.username`: データベースへのアクセス権を持つユーザー。

1. オプション。データベースへの相互TLS接続を使用する場合は、以下を設定します:

   - `global.psql.ssl.secret`: クライアント証明書、キー、認証局を含むシークレット。
   - `global.psql.ssl.serverCA`: シークレットで、認証局（CA）を参照するキー。
   - `global.psql.ssl.clientCertificate`: シークレットで、クライアント証明書を参照するキー。
   - `global.psql.ssl.clientKey`: シークレット内のクライアント。

1. GitLabチャートをデプロイするときは、`--set`フラグを使用して値を追加します。例: 

   ```shell
   helm install gitlab gitlab/gitlab
     --set postgresql.install=false
     --set global.psql.host=psql.example
     --set global.psql.password.secret=gitlab-postgresql-password
     --set global.psql.password.key=postgres-password
   ```
