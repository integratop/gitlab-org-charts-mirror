---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GKEまたはEKSでGitLabチャートをテストする
---

このガイドでは、Google Kubernetes Engine（GKE）またはAmazon Elastic Kubernetes Service（EKS）にデフォルト値でGitLabチャートをインストールする方法について、簡潔かつ完全なドキュメントとして説明します。

デフォルトでは、GitLabチャートには、インクラスタのPostgreSQL、Redis、MinIOデプロイが含まれています。これらはトライアル目的のみを対象としており、**本番環境での使用は推奨されません**。これらのチャートを継続的な負荷の下で本番環境にデプロイする場合は、完全な[インストールガイド](../installation/_index.md)に従ってください。

## 前提要件 {#prerequisites}

このガイドを完了するには、以下が必要です:

- DNSレコードを追加できる、所有しているドメイン。
- Kubernetesクラスター。
- `kubectl`が正常にインストールされていること。
- Helm v3が正常にインストールされていること。

### 利用可能なドメイン {#available-domain}

DNSレコードを追加できる、インターネットからアクセス可能なドメインへのアクセス権が必要です。これは`poc.domain.com`のようなサブドメインにすることができますが、Let's Encryptサーバーは、証明書を発行するためにアドレスを解決できる必要があります。

### Kubernetesクラスタの作成 {#create-a-kubernetes-cluster}

少なくとも8つの仮想CPUと30 GBのRAMの合計を持つクラスタをお勧めします。

クラウドプロバイダーのKubernetesクラスタを作成する方法に関する指示を参照するか、GitLab提供のスクリプトを使用して[クラスタ作成を自動化](../installation/cloud/_index.md)できます。

{{< alert type="warning" >}}

Kubernetesノードは、x86-64アーキテクチャを使用する必要があります。AArch64/ARM64を含む複数のアーキテクチャのサポートは、現在開発中です。詳細については、[イシュー2899](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2899)を参照してください。

{{< /alert >}}

### kubectlのインストール {#install-kubectl}

kubectlをインストールするには、[Kubernetesインストールに関するドキュメント](https://kubernetes.io/docs/tasks/tools/)を参照してください。このドキュメントでは、ほとんどのオペレーティングシステムとGoogle Cloud SDKについて説明しています。これらは、前の手順でインストールした可能性があります。

クラスタリングを作成したら、コマンドラインからクラスタリングとやり取りする前に、[`kubectl`を構成](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#generate_kubeconfig_entry)する必要があります。

### Helmのインストール {#install-helm}

このガイドでは、Helm v3（v3.9.4以降）の最新リリースを使用します。Helmをインストールするには、[Helmインストールに関するドキュメント](https://helm.sh/docs/intro/install/)を参照してください。

## GitLab Helmリポジトリを追加します。 {#add-the-gitlab-helm-repository}

`helm`の構成にGitLab Helmリポジトリを追加します:

```shell
helm repo add gitlab https://charts.gitlab.io/
```

## GitLabをインストールする {#install-gitlab}

このチャートが何ができるかの素晴らしさをご紹介します。コマンド1つ。はい、完了！GitLabがすべてインストールされ、SSLで構成されています。

チャートを構成するには、以下が必要です:

- GitLabが動作するドメインまたはサブドメイン。
- Let's Encryptが証明書を発行できるように、メールアドレス。

チャートをインストールするには、2つの`--set`引数を指定して、インストールコマンドを実行します:

```shell
helm install gitlab gitlab/gitlab \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=me@example.com
```

このステップは、すべてのリソースが割り当てられ、サービスが開始され、アクセスが可能になるまでに数分かかることがあります。

完了したら、インストールされているNGINXイングレスに動的に割り当てられたIPアドレスを収集するに進むことができます。

## IPアドレスの取得 {#retrieve-the-ip-address}

`kubectl`を使用して、GKEによって動的に割り当てられたアドレスをフェッチできます。これは、GitLabチャートの一部としてインストールおよび構成したばかりのNGINXイングレスに対するものです:

```shell
kubectl get ingress -lrelease=gitlab
```

出力は次のようになります:

```plaintext
NAME               HOSTS                 ADDRESS         PORTS     AGE
gitlab-minio       minio.domain.tld      35.239.27.235   80, 443   118m
gitlab-registry    registry.domain.tld   35.239.27.235   80, 443   118m
gitlab-webservice  gitlab.domain.tld     35.239.27.235   80, 443   118m
```

3つのエントリがあり、すべて同じIPアドレスになっていることに気付くでしょう。このIPアドレスを取得し、使用するように選択したドメインのDNSに追加します。タイプ`A`の複数のレコードを追加できますが、簡単にするために、単一の「ワイルドカード」レコードをお勧めします:

- Google Cloud DNSで、名前`*`の`A`レコードを作成します。また、TTLを`1`分ではなく`5`分に設定することをお勧めします。
- AWS EKSでは、アドレスはIPアドレスではなくURLになります。[Route 53エイリアスレコードを作成](https://repost.aws/knowledge-center/route-53-create-alias-records)し、このURLを指す`*.domain.tld`。

## GitLabにサインインします。 {#sign-in-to-gitlab}

`gitlab.domain.tld`でGitLabにアクセスできます。たとえば、`global.hosts.domain=my.domain.tld`を設定すると、`gitlab.my.domain.tld`にアクセスします。

サインインするには、`root`ユーザーのパスワードを収集する必要があります。これはインストール時に自動的に生成され、Kubernetesシークレットに保存されます。シークレットからそのパスワードをフェッチしてデコードしましょう:

```shell
kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

これで、ユーザー名`root`と取得したパスワードでGitLabにサインインできます。ログイン後、ユーザー名の設定でこのパスワードを変更できます。これは、お客様に代わって最初のログインを保護できるようにするためにのみ生成されます。

## トラブルシューティング {#troubleshooting}

このガイドで問題が発生した場合は、以下が正常に動作していることを確認してください:

1. `gitlab.my.domain.tld`が、取得したイングレスのIPアドレスに解決されます。
1. 証明書の警告が表示された場合は、Let's Encryptに問題が発生しています。通常はDNS、または再試行の要件に関連しています。

詳細なトラブルシューティングのヒントについては、[トラブルシューティング](../troubleshooting/_index.md)ガイドを参照してください。

### Helmインストールが`roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden`を返します {#helm-install-returns-rolesrbacauthorizationk8sio-gitlab-shared-secrets-is-forbidden}

実行後:

```shell
helm install gitlab gitlab/gitlab  \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=user@example.com
```

次のようなエラーが表示される場合があります:

```shell
Error: failed pre-install: warning: Hook pre-install templates/shared-secrets-rbac-config.yaml failed: roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden: user "some-user@some-domain.com" (groups=["system:authenticated"]) is attempting to grant RBAC permissions not currently held:
{APIGroups:[""], Resources:["secrets"], Verbs:["get" "list" "create" "patch"]}
```

これは、クラスタへの接続に使用している`kubectl`コンテキストに、[RBAC](../installation/rbac.md)リソースの作成に必要な権限がないことを意味します。
