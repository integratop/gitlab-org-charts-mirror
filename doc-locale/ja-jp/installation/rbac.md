---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのロールベースのアクセス制御を設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Kubernetes 1.7までは、クラスタリング内に権限がありませんでした。1.7のリリースにより、クラスタリング内でサービスが実行できるアクションを決定するロールベースのアクセス制御システム（[RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)）が導入されました。

ロールベースのアクセス制御は、GitLabのいくつかの異なる側面に影響を与えます:

- Helmを使用したGitLabのインストール
- Prometheusモニタリング
- GitLab Runner
- クラスタリング内のPostgreSQLデータベース（ロールベースのアクセス制御が有効な場合）
- 証明書マネージャー

## ロールベースのアクセス制御が有効になっていることの確認 {#checking-that-rbac-is-enabled}

現在のクラスタリングロールをリストしてみてください。失敗した場合、`RBAC`ロールベースのアクセス制御は無効になっています

このコマンドは、`RBAC`ロールベースのアクセス制御が無効になっている場合は`false`を出力し、それ以外の場合は`true`を出力します

`kubectl get clusterroles > /dev/null 2>&1 && echo true || echo false`

## サービスアカウント {#service-accounts}

GitLabチャートは、特定のタスクを実行するためにサービスアカウントを使用します。これらのサービスアカウントとそれに関連付けられたロールは、チャートによって作成および管理されます。

以下のチャートでは、サービスアカウントについて説明しています。各サービスアカウントについて、チャートには以下が示されています:

- 名前のプレフィックス（プレフィックスはリリース名です）。
- 簡単な説明。たとえば、どこで使用されているか、または何に使用されているか。
- 関連付けられたロールと、どのリソースに対するどのアクセスレベルを持っているか。アクセスレベルは、読み取り専用（R）、書き込み専用（W）、または読み取り/書き込み（RW）です。リソースのグループ名は省略されていることに注意してください。
- ロールのスコープ。 クラスタリング（C）またはネームスペース（NS）のいずれかです。一部のインスタンスでは、ロールのスコープは、どちらかの値で構成できます（NS/Cで示されます）

| 名前のサフィックス | 説明 | ロール | スコープ
| ---         | ---         | ---   | ---
| `gitlab-runner` | このアカウントでGitLab Runnerが実行されます。 | すべてのリソース（RW） | NS/C
| `ingress-nginx` | Ingress NGINXがサービスのエンドポイントを制御するために使用します。 | シークレット、ポッド、エンドポイント、Ingress（R）。イベント（W）。ConfigMap、サービス（RW） | NS/C
| `shared-secrets` | このアカウントで、共有シークレットを作成するジョブが実行されます。（インストール前/アップグレードフック内） | シークレット（RW） | NS
| `cert-manager` | このアカウントで証明書マネージャーを制御するジョブが実行されます。 | Issuer、Certificate、CertificateRequest、Order（RW）  | NS/C

GitLabチャートは、ロールベースのアクセス制御を使用し、独自のサービスアカウントとロールバインディングを作成する他のチャートに依存します。概要は次のとおりです:

- Prometheusモニタリングは、デフォルトで複数の独自のサービスアカウントを作成します。それらはすべてクラスタリングレベルのロールに関連付けられています。詳細については、[Prometheusチャートのドキュメント](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#rbac-configuration)を参照してください。
- 証明書マネージャーは、デフォルトでサービスアカウントを作成して、クラスタリングレベルでネイティブリソースとともにカスタムリソースを管理します。詳細については、[証明書マネージャー](https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/templates/rbac.yaml)チャートのロールベースのアクセス制御テンプレートを参照してください。
- クラスタリング内のPostgreSQLデータベースを使用する場合（これはデフォルト）、サービスアカウントは有効になりません。有効にすることはできますが、PostgreSQLサービスを実行するためにのみ使用され、特定のロールに関連付けられていません。詳細については、[PostgreSQLチャート](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)を参照してください。
