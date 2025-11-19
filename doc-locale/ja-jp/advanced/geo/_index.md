---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab GeoでGitLabチャートを設定する
---

GitLab Geoは、地理的に分散したアプリケーションデプロイを可能にします。

外部データベースサービスも使用できますが、これらのドキュメントでは、PostgreSQL用の[Linuxパッケージ](https://docs.gitlab.com/omnibus/)を使用して、最もプラットフォームに依存しないガイドを提供し、`gitlab-ctl`に含まれる自動化を利用することに重点を置いています。

このガイドでは、両方のクラスタリングで同じ外部URLを使用します。この機能は、バージョン7.3以降のチャートでサポートされています。[Geo](https://docs.gitlab.com/administration/geo/secondary_proxy/#set-up-a-unified-url-for-geo-sites)サイトの統一されたURLを設定するを参照してください。オプションで、[セカンダリサイトに個別のURLを設定する](#configure-a-separate-url-for-the-secondary-site-optional)ことができます。

既知の問題については、[Geoのドキュメント](https://docs.gitlab.com/administration/geo/#known-issues)を参照してください。

{{< alert type="note" >}}

Geoのすべての側面（主に`site`と`node`の区別）を説明する[定義された用語](https://docs.gitlab.com/administration/geo/glossary/)を参照してください。

{{< /alert >}}

## 要件 {#requirements}

GitLab GeoをGitLab Helmチャートで使用するには、次の要件を満たす必要があります:

- [外部PostgreSQL](../external-db/_index.md)サービスの使用。チャートに含まれるPostgresSQLは外部ネットワークに公開されておらず、レプリケーションに必要なWALサポートがないため。
- 提供されるデータベースは、以下をサポートする必要があります:
  - レプリケーションをサポートします。
  - プライマリデータベースは、プライマリサイト、およびすべてのセカンダリデータベースノード（レプリケーション用）から到達可能である必要があります。
  - セカンダリデータベースは、セカンダリサイトからのみ到達可能である必要があります。
  - プライマリおよびセカンダリデータベースノード間のSSLをサポートします。
- プライマリサイトは、すべてのセカンダリサイトからHTTP(S)経由で到達可能である必要があります。セカンダリサイトは、プライマリサイトからHTTP(S)経由でアクセス可能である必要があります。
- 要件の完全なリストについては、[Geoの実行に関する要件](https://docs.gitlab.com/administration/geo/#requirements-for-running-geo)を参照してください。

## 概要 {#overview}

このガイドでは、Linuxパッケージを使用して作成された2つのデータベースノードを使用し、必要なPostgreSQLサービスのみを設定し、GitLab Helmチャートの2つのデプロイを使用します。これは、必要な_最小限_の設定であることを目的としています。このドキュメントには、アプリケーションからデータベースへのSSL、他のデータベースプロバイダーのサポート、または[セカンダリサイトをプライマリにプロモートする](https://docs.gitlab.com/administration/geo/disaster_recovery/)ことは含まれていません。

以下の概要は、順番に従う必要があります:

1. [Linuxパッケージデータベースノードを設定する](#set-up-linux-package-database-nodes)
1. [Kubernetesクラスタリングを設定する](#set-up-kubernetes-clusters)
1. [情報を収集する](#collect-information)
1. [プライマリデータベースを設定する](#configure-primary-database)
1. [Geoプライマリサイトとしてチャートをデプロイする](#deploy-chart-as-geo-primary-site)
1. [Geoプライマリサイトを設定する](#set-the-geo-primary-site)
1. [セカンダリデータベースを設定する](#configure-secondary-database)
1. [プライマリサイトからセカンダリサイトにシークレットをコピーする](#copy-secrets-from-the-primary-site-to-the-secondary-site)
1. [Geoセカンダリサイトとしてチャートをデプロイする](#deploy-chart-as-geo-secondary-site)
1. [プライマリ経由でセカンダリGeoサイトを追加する](#add-secondary-geo-site-via-primary)
1. [運用ステータスを確認する](#confirm-operational-status)
1. [セカンダリサイトに個別のURLを設定する（オプション）](#configure-a-separate-url-for-the-secondary-site-optional)
1. [レジストリ](#registry)
1. [Cert-managerと統合URL](#cert-manager-and-unified-url)

## Linuxパッケージデータベースノードを設定する {#set-up-linux-package-database-nodes}

このプロセスでは、2つのノードが必要です。1つはプライマリデータベースノード、もう1つはセカンダリデータベースノードです。オンプレミスまたはクラウドプロバイダーから、マシンインフラストラクチャの任意のプロバイダーを使用できます。

通信が必要になることに注意してください:

- レプリケーションのための2つのデータベースノード間。
- 各データベースノードとそのそれぞれのKubernetesデプロイ間:
  - プライマリは、TCPポート`5432`を公開する必要があります。
  - セカンダリは、TCPポート`5432`と`5431`を公開する必要があります。

[Linuxパッケージでサポートされているオペレーティングシステム](https://docs.gitlab.com/install/requirements/#operating-systems)をインストールし、[Linuxパッケージ](https://about.gitlab.com/install/)をインストールします。インストール時に`EXTERNAL_URL`環境変数を指定しないでください。パッケージを再設定する前に、最小限の設定ファイルを提供します。

オペレーティングシステムとGitLabパッケージをインストールしたら、使用するサービスの設定を作成できます。その前に、情報を収集する必要があります。

## Kubernetesクラスタリングを設定する {#set-up-kubernetes-clusters}

このプロセスでは、2つのKubernetesクラスタリングを使用する必要があります。これらは、オンプレミスまたはクラウドプロバイダーから、任意のプロバイダーからのものでかまいません。

通信が必要になることに注意してください:

- それぞれのデータベースノードへ:
  - プライマリはTCP `5432`へ送信。
  - セカンダリはTCP `5432`と`5431`へ送信。
- HTTPS経由の両方のKubernetes Ingress間。

プロビジョニングされる各クラスタリングには、以下が必要です:

- これらのチャートのベースラインインストールをサポートするのに十分なリソース。
- 永続ストレージへのアクセス:
  - [外部オブジェクトストレージ](../external-object-storage/_index.md)を使用している場合は、MinIOは不要です。
  - [外部Gitaly](../external-gitaly/_index.md)を使用している場合は、Gitalyは不要です。
  - [外部Redis](../external-redis/_index.md)を使用している場合は、Redisは不要です。

## 情報を収集する {#collect-information}

設定を続行するには、さまざまなソースから次の情報を収集する必要があります。これらを収集し、このドキュメントの残りの部分で使用するためのメモを作成します。

- プライマリデータベース:
  - IPアドレス
  - ホスト名（オプション）
- セカンダリデータベース:
  - IPアドレス
  - ホスト名（オプション）
- プライマリクラスタリング:
  - 外部URL
  - 内部URL
  - ノードのIPアドレス
- セカンダリクラスタリング:
  - 内部URL
  - ノードのIPアドレス
- データベースパスワード（_事前にパスワードを決定する必要があります_）:
  - `gitlab`（`postgresql['sql_user_password']`、`global.psql.password`で使用）
  - `gitlab_geo`（`geo_postgresql['sql_user_password']`、`global.geo.psql.password`で使用）
  - `gitlab_replicator`（レプリケーションに必要）
- GitLabライセンスファイル

各クラスタリングの内部URLは、すべてのクラスタリングが他のすべてのクラスタリングにリクエストできるように、クラスタリングに一意である必要があります。例: 

- すべてのクラスタリングの外部URL: `https://gitlab.example.com`
- プライマリクラスタリングの内部URL: `https://london.gitlab.example.com`
- セカンダリクラスタリングの内部URL: `https://shanghai.gitlab.example.com`

このガイドでは、DNSのセットアップについては説明しません。

`gitlab`データベースと`gitlab_geo`データベースのユーザーパスワードは、ベアパスワードとPostgreSQLハッシュパスワードの2つの形式で存在する必要があります。ハッシュ形式を取得するには、Linuxパッケージインストールインスタンスの1つで次のコマンドを実行します。これにより、パスワードを入力して確認するように求められた後、メモするための適切なハッシュ値が出力されます。

1. `gitlab-ctl pg-password-md5 gitlab`
1. `gitlab-ctl pg-password-md5 gitlab_geo`

## プライマリデータベースを設定する {#configure-primary-database}

_このセクションは、プライマリLinuxパッケージインストールデータベースノードで実行されます。_

プライマリデータベースノードのLinuxパッケージインストールの設定を構成するには、この設定例から作業を開始します:

```ruby
### Geo Primary
external_url 'http://gitlab.example.com'
roles ['geo_primary_role']
# The unique identifier for the Geo node.
gitlab_rails['geo_node_name'] = 'London Office'
gitlab_rails['auto_migrate'] = false
## turn off everything but the DB
sidekiq['enable']=false
puma['enable']=false
gitlab_workhorse['enable']=false
nginx['enable']=false
geo_logcursor['enable']=false
gitaly['enable']=false
redis['enable']=false
gitlab_kas['enable']=false
prometheus_monitoring['enable'] = false
## Configure the DB for network
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['sql_user_password'] = 'gitlab_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - primary application deployment
# - secondary database node(s)
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
```

いくつかのアイテムを置き換える必要があります:

- `external_url`は、プライマリサイトのホスト名を反映するように更新する必要があります。
- `gitlab_rails['geo_node_name']`は、サイトの一意の名前に置き換える必要があります。[共通設定](https://docs.gitlab.com/administration/geo_sites/#common-settings)の名前フィールドを参照してください。
- `gitlab_user_password_hash`は、`gitlab`パスワードのハッシュ形式に置き換える必要があります。
- `postgresql['md5_auth_cidr_addresses']`は、明示的なIPアドレスのリスト、またはクラスレスドメイン間ルーティング表記のアドレスブロックに更新できます。

`md5_auth_cidr_addresses`は、`[ '127.0.0.1/24', '10.41.0.0/16']`の形式である必要があります。Linuxパッケージの自動化はこれを使用して接続するため、このリストに`127.0.0.1`を含めることが重要です。このリストのアドレスには、セカンダリデータベースのIPアドレス（ホスト名ではない）と、プライマリKubernetesクラスタリングのすべてのノードが含まれている必要があります。これは`['0.0.0.0/0']`として残す_こと_もできますが、_ベストプラクティスではありません_。

上記の設定を準備した後:

1. コンテンツを`/etc/gitlab/gitlab.rb`に配置します
1. `gitlab-ctl reconfigure`を実行します。TCPでリッスンしていないサービスに関して問題が発生した場合は、`gitlab-ctl restart postgresql`で直接再起動してみてください。
1. `gitlab-ctl set-replication-password`を実行して、`gitlab_replicator`ユーザーのパスワードを設定します。
1. プライマリデータベースノードの公開証明書を取得します。これは、セカンダリデータベースがレプリケーションできるようにするために必要です（この出力を保存します）:

   ```shell
   cat ~gitlab-psql/data/server.crt
   ```

## Geoプライマリサイトとしてチャートをデプロイする {#deploy-chart-as-geo-primary-site}

_このセクションは、プライマリサイトのKubernetesクラスタリングで実行されます。_

このチャートをGeoプライマリとしてデプロイするには、[この設定例から](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)開始します:

1. チャートが消費するデータベースパスワードを含むシークレットを作成します。以下の`PASSWORD`を、`gitlab`データベースユーザーのパスワードに置き換えます:

   ```shell
   kubectl --namespace gitlab create secret generic geo --from-literal=postgresql-password=PASSWORD
   ```

1. [設定例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)に基づいて`primary.yaml`ファイルを作成し、正しい値を反映するように設定を更新します:

   ```yaml
   ### Geo Primary
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: example.com
       # optionally configure a static IP for the default LoadBalancer
       # externalIP:
       # optionally configure a static IP for the Geo LoadBalancer
       # externalGeoIP:
     # configure DB connection
     psql:
       host: geo-1.db.example.com
       port: 5432
       password:
         secret: geo
         key: postgresql-password
     # configure geo (primary)
     geo:
       nodeName: London Office
       enabled: true
       role: primary
   # configure Geo Nginx Controller for internal Geo site traffic
   nginx-ingress-geo:
     enabled: true
   gitlab:
     webservice:
       # Use the Geo NGINX controller.
       ingress:
         useGeoClass: true
       # Configure an Ingress for internal Geo traffic
       extraIngress:
         enabled: true
         hostname: gitlab.london.example.com
         useGeoClass: true
   # External DB, disable
   postgresql:
     install: false
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName`は、[管理者エリアのGeoサイトの名前フィールド](https://docs.gitlab.com/administration/geo_sites/#common-settings)と一致する必要があります
   - Geoトラフィックがセカンダリから転送されるようにIngressコントローラーを有効にするには、[`nginx-ingress-geo.enabled`](../../charts/nginx/_index.md#gitlab-geo)を設定します。
   - GeoトラフィックのプライマリGeoサイトの[`gitlab.webservice`](../../charts/gitlab/webservice/_index.md#ingress-settings)Ingressを設定します。
   - 次のような追加の設定も行います:
     - [SSL/TLSの設定](../../installation/tools.md#tls-certificates)
     - [外部Redisの使用](../external-redis/_index.md)
     - [外部](../external-object-storage/_index.md)オブジェクトストレージを使用
   <!-- markdownlint-enable MD044 -->

1. この設定を使用してチャートをデプロイします:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f primary.yaml
   ```

   {{< alert type="note" >}}

   これは、`gitlab`ネームスペースを使用していることを前提としています。別のネームスペースを使用する場合は、このドキュメントの残りの部分全体で`--namespace gitlab`でも置き換える必要があります。

   {{< /alert >}}

1. デプロイが完了し、アプリケーションがオンラインになるまで待ちます。アプリケーションに到達できるようになったら、ログインします。

1. GitLabにサインインし、[GitLabサブスクリプションをアクティブ化](https://docs.gitlab.com/administration/license/)します。

   {{< alert type="note" >}}

   この手順は、Geoが機能するために必要です。

   {{< /alert >}}

## Geoプライマリサイトを設定する {#set-the-geo-primary-site}

これで、チャートがデプロイされ、ライセンスがアップロードされたので、これをプライマリサイトとして設定できます。これは、Toolboxポッドを介して行います。

1. Toolboxポッドを探す

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. `kubectl exec`で`gitlab-rake geo:set_primary_node`を実行します:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake geo:set_primary_node
   ```

1. Railsランナーコマンドを使用して、プライマリサイトの内部URLを設定します。`https://primary.gitlab.example.com`を実際の内部URLに置き換えます:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rails runner "GeoNode.primary_node.update!(internal_url: 'https://primary.gitlab.example.com')"
   ```

1. Geo設定のステータスを確認します:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake gitlab:geo:check
   ```

   以下のような出力が表示されます:

   ```plaintext
   WARNING: This version of GitLab depends on gitlab-shell 10.2.0, but you're running Unknown. Please update gitlab-shell.
   Checking Geo ...

   GitLab Geo is available ... yes
   GitLab Geo is enabled ... yes
   GitLab Geo secondary database is correctly configured ... not a secondary node
   Database replication enabled? ... not a secondary node
   Database replication working? ... not a secondary node
   GitLab Geo HTTP(S) connectivity ... not a secondary node
   HTTP/HTTPS repository cloning is enabled ... yes
   Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
   Git user has default SSH configuration? ... yes
   OpenSSH configured to use AuthorizedKeysCommand ... no
     Reason:
     Cannot find OpenSSH configuration file at: /assets/sshd_config
     Try fixing it:
     If you are not using our official docker containers,
     make sure you have OpenSSH server installed and configured correctly on this system
     For more information see:
     doc/administration/operations/fast_ssh_key_lookup.md
   GitLab configured to disable writing to authorized_keys file ... yes
   GitLab configured to store new projects in hashed storage? ... yes
   All projects are in hashed storage? ... yes

   Checking Geo ... Finished
   ```

   - Kubernetesコンテナはホストクロックにアクセスできないため、`Exception: getaddrinfo: Servname not supported for ai_socktype`を心配しないでください。_これは問題ありません_。
   - `OpenSSH configured to use AuthorizedKeysCommand ... no` _が予想されます_。このRakeタスクはローカルのSSHサーバーをチェックしていますが、実際には`gitlab-shell`チャート内に存在し、別の場所にデプロイされており、すでに適切に設定されています。

## セカンダリデータベースを設定する {#configure-secondary-database}

_このセクションは、セカンダリLinuxパッケージインストールデータベースノードで実行されます。_

セカンダリデータベースノードのLinuxパッケージインストールの設定を構成するには、この設定例から作業を開始します:

```ruby
### Geo Secondary
# external_url must match the Primary cluster's external_url
external_url 'http://gitlab.example.com'
roles ['geo_secondary_role']
gitlab_rails['enable'] = true
# The unique identifier for the Geo node.
gitlab_rails['geo_node_name'] = 'Shanghai Office'
gitlab_rails['auto_migrate'] = false
geo_secondary['auto_migrate'] = false
## turn off everything but the DB
sidekiq['enable']=false
puma['enable']=false
gitlab_workhorse['enable']=false
nginx['enable']=false
geo_logcursor['enable']=false
gitaly['enable']=false
redis['enable']=false
prometheus_monitoring['enable'] = false
gitlab_kas['enable']=false
## Configure the DBs for network
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['sql_user_password'] = 'gitlab_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - secondary application deployment
# - secondary database node(s)
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
geo_postgresql['listen_address'] = '0.0.0.0'
geo_postgresql['sql_user_password'] = 'gitlab_geo_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - secondary application deployment
# - secondary database node(s)
geo_postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
gitlab_rails['db_password']='gitlab_user_password'
```

いくつかのアイテムを置き換える必要があります:

- `gitlab_rails['geo_node_name']`は、サイトの一意の名前に置き換える必要があります。[共通設定](https://docs.gitlab.com/administration/geo_sites/#common-settings)の名前フィールドを参照してください。
- `gitlab_user_password_hash`は、`gitlab`パスワードのハッシュ形式に置き換える必要があります。
- `postgresql['md5_auth_cidr_addresses']`は、明示的なIPアドレスのリスト、またはクラスレスドメイン間ルーティング表記のアドレスブロックに更新する必要があります。
- `gitlab_geo_user_password_hash`は、`gitlab_geo`パスワードのハッシュ形式に置き換える必要があります。
- `geo_postgresql['md5_auth_cidr_addresses']`は、明示的なIPアドレスのリスト、またはクラスレスドメイン間ルーティング表記のアドレスブロックに更新する必要があります。
- `gitlab_user_password`を更新する必要があり、LinuxパッケージがPostgreSQL設定を自動化できるようにするためにここで使用されます。

`md5_auth_cidr_addresses`は、`[ '127.0.0.1/24', '10.41.0.0/16']`の形式である必要があります。Linuxパッケージの自動化はこれを使用して接続するため、このリストに`127.0.0.1`を含めることが重要です。このリストのアドレスには、セカンダリKubernetesクラスタリングのすべてのノードのIPアドレスが含まれている必要があります。これは`['0.0.0.0/0']`として残す_こと_もできますが、_ベストプラクティスではありません_。

上記の設定を準備した後:

1. **プライマリ**サイトのPostgreSQLノードへのTCP接続を確認します:

   ```shell
   openssl s_client -connect <primary_node_ip>:5432 </dev/null
   ```

   出力は次のようになります:

   ```plaintext
   CONNECTED(00000003)
   write:errno=0
   ```

   {{< alert type="note" >}}

   この手順が失敗した場合は、間違ったIPアドレスを使用しているか、ファイアウォールがサーバーへのアクセスを妨げている可能性があります。IPアドレスを確認し、パブリックアドレスとプライベートアドレスの違いに注意し、ファイアウォールが存在する場合は、**セカンダリ** PostgreSQLノードがTCPポート5432で**プライマリ** PostgreSQLノードへの接続を許可されていることを確認します。

   {{< /alert >}}

1. コンテンツを`/etc/gitlab/gitlab.rb`に配置します
1. `gitlab-ctl reconfigure`を実行します。TCPでリッスンしていないサービスに関して問題が発生した場合は、`gitlab-ctl restart postgresql`で直接再起動してみてください。
1. プライマリPostgreSQLノードの証明書コンテンツを上記の`primary.crt`に配置します
1. **セカンダリ** PostgreSQLノードで、PostgreSQL TLSの検証を設定します:

   `primary.crt`ファイルをインストールします:

   ```shell
   install \
      -D \
      -o gitlab-psql \
      -g gitlab-psql \
      -m 0400 \
      -T primary.crt ~gitlab-psql/.postgresql/root.crt
   ```

   PostgreSQLは、TLS接続を検証する際に、その正確な証明書のみを認識するようになります。証明書をレプリケーションできるのは、秘密キーへのアクセス権を持つユーザーのみです。秘密キーは、**プライマリ**PostgreSQLノード**にのみ**存在します。

1. `gitlab-psql`ユーザーが**プライマリ**サイトのPostgreSQL（デフォルトのLinuxパッケージデータベース名は`gitlabhq_production`）に接続できることをテストします:

   ```shell
   sudo \
      -u gitlab-psql /opt/gitlab/embedded/bin/psql \
      --list \
      -U gitlab_replicator \
      -d "dbname=gitlabhq_production sslmode=verify-ca" \
      -W \
      -h <primary_database_node_ip>
   ```

   `gitlab_replicator`ユーザーに対して以前に収集したパスワードのプロンプトが表示されたら、入力します。すべてが正しく動作していれば、**プライマリ** PostgreSQLノードのデータベースのリストが表示されるはずです。

   ここで接続に失敗した場合は、TLSの設定が間違っていることを示しています。**プライマリ** PostgreSQLノードの`~gitlab-psql/data/server.crt`の内容が、**セカンダリ** PostgreSQLノードの`~gitlab-psql/.postgresql/root.crt`の内容と一致していることを確認してください。

1. データベースをレプリケーションします。`PRIMARY_DATABASE_HOST`をプライマリPostgreSQLノードのIPアドレスまたはホスト名に置き換えます:

   ```shell
   gitlab-ctl replicate-geo-database --slot-name=geo_2 --host=PRIMARY_DATABASE_HOST --sslmode=verify-ca
   ```

1. レプリケーションが完了したら、`pg_hba.conf`がセカンダリPostgreSQLノードに対して正しいことを確認するために、Linuxパッケージをもう一度設定する必要があります:

   ```shell
   gitlab-ctl reconfigure
   ```

## プライマリサイトからセカンダリサイトにシークレットをコピーします {#copy-secrets-from-the-primary-site-to-the-secondary-site}

次に、プライマリサイトのKubernetesデプロイメントからセカンダリサイトのKubernetesデプロイメントに、いくつかのシークレットをコピーします:

- `gitlab-geo-gitlab-shell-host-keys`
- `gitlab-geo-rails-secret`
- レジストリのレプリケーションが有効になっている場合は、`gitlab-geo-registry-secret`。

1. `kubectl`コンテキストをプライマリのコンテキストに変更します。
1. プライマリデプロイメントからこれらのシークレットを収集します:

   ```shell
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-gitlab-shell-host-keys > ssh-host-keys.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-rails-secret > rails-secrets.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-registry-secret > registry-secrets.yaml
   ```

1. `kubectl`コンテキストをセカンダリのコンテキストに変更します。
1. これらのシークレットを適用します:

   ```shell
   kubectl --namespace gitlab apply -f ssh-host-keys.yaml
   kubectl --namespace gitlab apply -f rails-secrets.yaml
   kubectl --namespace gitlab apply -f registry-secrets.yaml
   ```

次に、データベースのパスワードを含むシークレットを作成します。以下のパスワードを適切な値に置き換えます:

```shell
kubectl --namespace gitlab create secret generic geo \
   --from-literal=postgresql-password=gitlab_user_password \
   --from-literal=geo-postgresql-password=gitlab_geo_user_password
```

## Geoセカンダリサイトとしてチャートをデプロイします {#deploy-chart-as-geo-secondary-site}

_このセクションは、セカンダリサイトのKubernetesクラスターで実行されます。_

このチャートをGeoセカンダリサイトとしてデプロイするには、[この設定例から](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml)開始します。

1. [設定例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml)に基づいて`secondary.yaml`ファイルを作成し、正しい値を反映するように設定を更新します:

   ```yaml
   ## Geo Secondary
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: shanghai.example.com
       # use a unified URL (same external URL as the primary site)
       gitlab:
         name: gitlab.example.com
     # configure DB connection
     psql:
       host: geo-2.db.example.com
       port: 5432
       password:
         secret: geo
         key: postgresql-password
     # configure geo (secondary)
     geo:
       enabled: true
       role: secondary
       nodeName: Shanghai Office
       psql:
         host: geo-2.db.example.com
         port: 5431
         password:
           secret: geo
           key: geo-postgresql-password
   # Optional for secondary sites: Configure Geo Nginx Controller for internal Geo site traffic.
   # nginx-ingress-geo:
   #   enabled: true
   gitlab:
     webservice:
       # Configure a Ingress for internal Geo traffic
       extraIngress:
         enabled: true
         hostname: shanghai.gitlab.example.com
   # External DB, disable
   postgresql:
     install: false
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - [`global.geo.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName`は、[管理者エリアのGeoサイトの名前フィールド](https://docs.gitlab.com/administration/geo_sites/#common-settings)と一致する必要があります
   - `nginx-ingress-geo.enabled`を設定すると、内部Geoトラフィック用に事前設定されたIngressコントローラーを有効にできます。[これにより、サイトをプライマリにプロモートすることが容易になります。](../../charts/nginx/_index.md#gitlab-geo)。
   - セカンダリサイトの内部URLに送信されるトラフィックを処理するために、[gitlab.webservice](../../charts/gitlab/webservice/_index.md#ingress-settings)の追加のIngressを設定します。
   - 次のような追加の設定も行います:
     - [SSL/TLSの設定](../../installation/tools.md#tls-certificates)
     - [外部Redisの使用](../external-redis/_index.md)
     - [外部](../external-object-storage/_index.md)オブジェクトストレージを使用
   - 外部データベースの場合、`global.psql.host`はセカンダリの読み取り専用レプリカデータベースであり、`global.geo.psql.host`はGeoトラッキングデータベースです
   <!-- markdownlint-enable MD044 -->

1. この設定を使用してチャートをデプロイします:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. デプロイが完了し、アプリケーションがオンラインになるまで待ちます。

## プライマリを介してGeoセカンダリサイトを追加 {#add-secondary-geo-site-via-primary}

両方のデータベースが設定され、アプリケーションがデプロイされたので、プライマリサイトにセカンダリサイトが存在することを通知する必要があります:

1. **プライマリ**サイトにアクセスします。
1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. **Geo > サイトを追加**を選択します。
1. **セカンダリ**サイトを追加します。URLには、完全なGitLab URLを使用します。
1. セカンダリサイトの`global.geo.nodeName`を使用して名前を入力します。これらの値は常に文字どおり完全に一致する必要があります。
1. 内部URL（例: `https://shanghai.gitlab.example.com`）を入力します。
1. オプションで、どのグループまたはストレージシャードを**セカンダリ**サイトでレプリケーションするかを選択します。すべてをレプリケーションするには、空白のままにします。
1. **ノードを追加**を選択します。

**セカンダリ**サイトが管理パネルに追加されると、**プライマリ**サイトから不足しているデータのレプリケーションが自動的に開始されます。このプロセスは「バックフィル」と呼ばれます。一方、**プライマリ**サイトは各**セカンダリ**サイトに変更を通知し始め、**セカンダリ**サイトはそれらの変更を迅速にレプリケーションできます。

## オペレーションステータスを確認 {#confirm-operational-status}

最終的な手順は、Toolboxポッドを介して、完全に設定されたらセカンダリサイトのGeo設定を再確認することです。

1. Toolboxポッドを探します:

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. `kubectl exec`を使用してポッドにアタッチします:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- bash -l
   ```

1. Geo設定のステータスを確認します:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   以下のような出力が表示されます:

   ```plaintext
   WARNING: This version of GitLab depends on gitlab-shell 10.2.0, but you're running Unknown. Please update gitlab-shell.
   Checking Geo ...

   GitLab Geo is available ... yes
   GitLab Geo is enabled ... yes
   GitLab Geo secondary database is correctly configured ... yes
   Database replication enabled? ... yes
   Database replication working? ... yes
   GitLab Geo HTTP(S) connectivity ...
   * Can connect to the primary node ... yes
   HTTP/HTTPS repository cloning is enabled ... yes
   Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
   Git user has default SSH configuration? ... yes
   OpenSSH configured to use AuthorizedKeysCommand ... no
     Reason:
     Cannot find OpenSSH configuration file at: /assets/sshd_config
     Try fixing it:
     If you are not using our official docker containers,
     make sure you have OpenSSH server installed and configured correctly on this system
     For more information see:
     doc/administration/operations/fast_ssh_key_lookup.md
   GitLab configured to disable writing to authorized_keys file ... yes
   GitLab configured to store new projects in hashed storage? ... yes
   All projects are in hashed storage? ... yes

   Checking Geo ... Finished
   ```

   - `Exception: getaddrinfo: Servname not supported for ai_socktype`については、Kubernetesコンテナーはホストクロックにアクセスできないため、心配しないでください。_これは問題ありません_。
   - `OpenSSH configured to use AuthorizedKeysCommand ... no` _が予想されます_。このRakeタスクはローカルのSSHサーバーをチェックしていますが、実際には`gitlab-shell`チャート内に存在し、別の場所にデプロイされており、すでに適切に設定されています。

## セカンダリサイトの個別のURLを設定します（オプション） {#configure-a-separate-url-for-the-secondary-site-optional}

プライマリサイトとセカンダリサイトの単一の統合URLは、通常、ユーザーにとってより便利です。たとえば、次のことができます:

- 両方のサイトをロードバランサーの背後に配置します。
- クラウドプロバイダーのDNS機能を使用して、ユーザーを最寄りのサイトにルーティングします。

場合によっては、ユーザーがどのサイトにアクセスするかを制御できるようにすることがあります。この目的のために、セカンダリGeoサイトを設定して、一意の外部URLを使用できます。例: 

- プライマリクラスタの外部URL: `https://gitlab.example.com`
- セカンダリクラスタの外部URL: `https://shanghai.gitlab.example.com`

1. `secondary.yaml`を編集し、セカンダリクラスタの外部URLを更新して、`webservice`チャートがそれらのリクエストを処理できるようにします:

   ```yaml
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: example.com
       # use a unique external URL for the secondary site
       gitlab:
         name: shanghai.gitlab.example.com
   ```

1. GitLabでセカンダリサイトの外部URLを更新して、必要な場所でURLを使用できるようにします:
   - 管理者UIの使用:
     1. **プライマリ**サイトにアクセスします。
     1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
     1. **Geo > サイト**を選択します。
     1. 鉛筆アイコンを選択して、**セカンダリサイトを編集**します。
     1. 外部URL（例: `https://shanghai.gitlab.example.com`）を編集します。
     1. **変更を保存**を選択します。

1. セカンダリサイトのチャートを再デプロイします:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. デプロイが完了し、アプリケーションがオンラインになるまで待ちます。

## レジストリ {#registry}

セカンダリレジストリをプライマリレジストリと同期するには、[レジストリレプリケーション](https://docs.gitlab.com/administration/geo/replication/container_registry/#configure-container-registry-replication)を、[通知シークレット](../../charts/registry/_index.md#notification-secret)を使用して設定できます。

## Cert-managerと統合URL {#cert-manager-and-unified-url}

Geoの統合URLは、地理位置情報対応ルーティング（たとえば、Amazon Route 53またはGoogleクラウドプロバイダーDNSを使用）でよく使用されます。これにより、ドメイン名が管理下にあることを検証するために、[HTTP01 Challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)を使用すると問題が発生する可能性があります。

1つのGeoサイトの証明書をリクエストすると、Let's Encryptは、DNS名をリクエストしているGeoサイトに解決する必要があります。DNSが別のGeoサイトに解決される場合、統合URLの証明書は発行または更新されません。

cert-managerで確実に証明書を作成して更新するには、統合ホスト名をGeoサイトのIPアドレスに解決することがわかっているサーバーに[Challengeネームサーバーを設定](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks)するか、[DNS01](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) [Issuer](https://cert-manager.io/docs/configuration/acme/dns01/)を設定します。
