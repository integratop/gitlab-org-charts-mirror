---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アーキテクチャ
---

コンポーネントの3つの階層をサポートする予定です:

1. Dockerコンテナ
1. スケジューラ（Kubernetes）
1. 高レベルの設定ツール（Helm）

お客様がインストールに使用する主な方法は、このリポジトリ内の[Helmチャート](https://helm.sh/)です。将来的には、Amazon CloudFormationやDocker Swarmのような他のデプロイ方法も提供する可能性があります。

## Dockerコンテナイメージ {#docker-container-images}

前提として、各サービスに対してDockerコンテナを作成します。これにより、イメージサイズと複雑さを軽減し、より簡単な水平スケーリングが可能になります。設定は、Dockerの標準的な方法で、おそらく環境変数またはマウントされたファイルで渡される必要があります。これにより、スケジューラソフトウェアとのクリーンで共通のインターフェースが提供されます。

### GitLab Dockerイメージ {#gitlab-docker-images}

GitLabアプリケーションは、GitLab固有のサービスを含むDockerイメージを使用してビルドされています。これらのイメージのビルド環境は、[CNG repository](https://gitlab.com/gitlab-org/build/CNG)にあります。

以下のGitLabコンポーネントには、CNGリポジトリにイメージがあります。

- Gitaly
- GitLab Elasticsearch Indexer
- [mail_room](https://github.com/tpitale/mail_room)
- GitLab Exporter
- GitLab Shell
- Sidekiq
- GitLab Toolbox
- Webservice
- Workhorse

以下は、GitLab固有のDockerイメージも使用するフォークしたチャートです。

`initContainers`およびさまざまな`Job`で使用されるDockerイメージ。

- alpine-certificates
- kubectl

### 公式Dockerイメージ {#official-docker-images}

基盤となるサービスには、次の既存の公式コンテナを活用します:

- Docker Distribution（[Docker Registry 2.0](https://github.com/distribution/distribution)）
- Prometheus
- NGINX Ingress
- cert-manager
- Redis
- PostgreSQL

## GitLabチャート {#the-gitlab-chart}

これはトップレベルのGitLabチャート（`gitlab`）で、GitLabの完全な設定に必要なすべてのリソースを設定します。これには、GitLab、PostgreSQL、Redis、Ingress、および証明書管理チャートが含まれます。

この高レベルでは、お客様は次のような決定を下すことができます:

- 組み込みのPostgreSQLチャートを使用するか、PostgreSQL用のAmazon RDSのような外部データベースを使用するか。
- 独自のSSL証明書を持ち込むか、Let's Encryptを活用するか。
- ロードバランサーを使用するか、専用のIngressを使用するか。

手軽に始めたいお客様は、このチャートから始めることをお勧めします。

### これらのチャートの構造 {#structure-of-these-charts}

メインのGitLabチャートは、他の多くのチャートで構成されるアンブレラチャートです。各サブチャートは個別にドキュメント化され、[charts](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts)ディレクトリ構造に一致する構造で配置されます。

GitLab以外のコンポーネントは、トップレベルでパッケージ化され、ドキュメント化されています。GitLabコンポーネントサービスは、[GitLab](../charts/gitlab/_index.md)チャートの下にドキュメント化されています:

- [NGINX](../charts/nginx/_index.md)
- [MinIO](../charts/minio/_index.md)
- [レジストリ](../charts/registry/_index.md)
- GitLab/[Gitaly](../charts/gitlab/gitaly/_index.md)
- GitLab/[GitLab Exporter](../charts/gitlab/gitlab-exporter/_index.md)
- GitLab/[GitLab Shell](../charts/gitlab/gitlab-shell/_index.md)
- GitLab/[Migrations](../charts/gitlab/migrations/_index.md)
- GitLab/[Sidekiq](../charts/gitlab/sidekiq/_index.md)
- GitLab/[Webservice](../charts/gitlab/webservice/_index.md)

### コンポーネントリスト {#components-list}

チャートを使用するときにデプロイされるコンポーネントのリスト、および必要に応じて設定手順については、[アーキテクチャコンポーネントリスト](https://docs.gitlab.com/development/architecture/#component-list)ページにあります。

## 設計上の判断 {#design-decisions}

これらのチャートのアーキテクチャに関して行われた決定のドキュメントは、[設計に関する決定](decisions.md)のドキュメントにあります
