---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mattermost Team EditionでGitLabチャートを設定する
---

このドキュメントでは、既存のGitLabチャートのデプロイメントと近接してMattermost Team Edition Helm Chartをインストールする方法について説明します。

Mattermost Helmチャートは別のネームスペースにインストールされるため、クラスタ全体のIngressおよび証明書リソースを管理するように`cert-manager`と`nginx-ingress`を構成することをお勧めします。追加の設定情報については、[Mattermost Helm設定ガイド](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-team-edition#configuration)を参照してください。

## 前提要件 {#prerequisites}

- Kubernetesクラスタリングが実行されている。
- [Helm v3](https://helm.sh/docs/intro/install/)

{{< alert type="note" >}}

Team Editionの場合、実行できるレプリカは1つだけです。

{{< /alert >}}

## Mattermost Team Edition Helm Chartのデプロイ {#deploy-the-mattermost-team-edition-helm-chart}

Mattermost Team Edition Helm Chartをインストールしたら、次のコマンドを使用してデプロイできます:

```shell
helm repo add mattermost https://helm.mattermost.com
helm repo update
helm upgrade --install mattermost -f values.yaml mattermost/mattermost-team-edition
```

ポッドが実行されるまで待ちます。次に、設定で指定したIngressホストを使用して、Mattermostサーバーにアクセスします。

追加の設定情報については、[Mattermost Helm設定ガイド](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-team-edition#configuration)を参照してください。問題が発生した場合は、[Mattermost Helmチャートのイシューリポジトリ](https://github.com/mattermost/mattermost-helm/issues)または[Mattermostフォーラム](https://forum.mattermost.com/search?q=helm)をご覧ください。

## GitLab Helm Chartのデプロイ {#deploy-gitlab-helm-chart}

GitLab Helm Chartをデプロイするには、[インストール手順](../../_index.md)に従ってください。

インストールを簡単にする方法を次に示します:

```shell
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=<your-domain> \
  --set global.hosts.externalIP=<external-ip> \
  --set certmanager-issuer.email=<email>
```

- `<your-domain>`: 目的のドメイン（`gitlab.example.com`など）。
- `<external-ip>`: Kubernetesクラスタリングを指す外部IP。
- `<email>`: TLS証明書を取得するために、Let's Encryptに登録するメール。

GitLabインスタンスをデプロイしたら、[初期ログイン](../../installation/deployment.md#initial-login)の手順に従ってください。

## GitLabでOAuthアプリケーションを作成する {#create-an-oauth-application-with-gitlab}

プロセスの次の部分は、GitLab SSOインテグレーションをセットアップすることです。これを行うには、Mattermostが認証プロバイダーとしてGitLabを使用できるように、[OAuthアプリケーションを作成する](https://docs.mattermost.com/deployment/sso-gitlab.html)必要があります。

{{< alert type="note" >}}

デフォルトのGitLab SSOのみが正式にサポートされています。「二重SSO」はサポートされていません。この場合、GitLab SSOは他のSSOソリューションにチェーンされます。場合によっては、GitLab SSOをAD、LDAP、SAML、またはMFAアドオンに接続できる可能性がありますが、必要な特別なロジックがあるため、公式にはサポートされておらず、一部のエクスペリエンスでは動作しないことがわかっています。

{{< /alert >}}

## トラブルシューティング {#troubleshooting}

提供されているプロセス以外のプロセスに従っていて、認証および/またはデプロイのイシューが発生した場合は、[Mattermostトラブルシューティングフォーラム](https://docs.mattermost.com/install/troubleshooting.html?&redirect_source=mm-org)でお知らせください。
