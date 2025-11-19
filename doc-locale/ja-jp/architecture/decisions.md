---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 設計上の判断
---

このドキュメントでは、このリポジトリ内のHelm Chartのデザインに関して行われた理由と決定事項を収集します。提案をお待ちしております。決定の適用方法については、[意思決定](decision-making.md)を参照してください。

## 問題のある設定の捕捉を試みる {#attempt-to-catch-problematic-configurations}

これらのチャートの複雑さとその柔軟性のレベルにより、予測不可能または完全に機能しないデプロイにつながる設定を生成できるオーバーラップがいくつかあります。既知の問題のある設定の組み合わせを回避するために、設定が機能しないことを検出し、ユーザーに警告するように設計されたテンプレートロジックを実装しました。

これは非推奨の動作をレプリケートしますが、機能的な設定を保証することに特化しています。

[!757 checkConfig: 既知のエラーをテストする方法を追加](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/757)で導入

## 非推奨による破壊的な変更 {#breaking-changes-via-deprecation}

これらのチャートの開発中に、既存のデプロイのプロパティに改変を必要とする改善を行うことがあります。2つの例は、MinIOの使用を設定するための一元化と、（当社の好みに従って）外部オブジェクトストレージの設定をプロパティからシークレットへの移行でした。

機能しなくなる設定に対して破壊的な変更を含むこれらのチャートの更新バージョンをユーザーが誤ってデプロイすることを防ぐ手段として、[非推奨](../development/_index.md#handling-configuration-deprecations)通知を実装することにしました。これらは、プロパティの場所が変更、改変、置換、または完全に削除されたことを検出し、設定に必要な変更についてユーザーに通知するように設計されています。これには、プロパティをシークレットに置き換える方法に関するドキュメントを見るようにユーザーに通知することが含まれる場合があります。これらの通知により、Helmの`install`または`upgrade`コマンドが解析エラーで停止し、対処が必要な項目の完全なリストを出力します。ユーザーがエラー、修正、繰り返しのループに陥らないように注意を払っています。

デプロイを成功させるには、すべての非推奨に対処する必要があります。ユーザーは、デバッグが必要な予期しない動作や完全な失敗を経験するよりも、破壊的な変更について知らされることを好むと考えています。

[!396 Deprecations: バッファリングされた非推奨のリストを実装](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/396)で導入

## 環境変数よりもinitコンテナ内のシークレットを優先する {#preference-of-secrets-in-initcontainer-over-environment}

多くのコンテナエコシステムは、環境変数を介して設定される機能を備えているか、または期待しています。この[構成プラクティス](https://12factor.net/config)は、[The Twelve-Factor App](https://12factor.net)の概念に由来します。これにより、複数のデプロイ環境全体での設定が大幅に簡素化されますが、コンテナの環境を介してパスワードやキーなどの接続シークレットを渡すことには、セキュリティ上の懸念が残ります。

ほとんどのコンテナエコシステムは、実行中のコンテナの状態を検査する簡単な方法を提供しており、通常は環境が含まれます。[Docker](https://www.docker.com/)を例として使用すると、デーモンと通信できるすべてのプロセスは、実行中のすべてのコンテナの状態をクエリできます。つまり、[`dind`](https://hub.docker.com/r/gitlab/dind/)のような特権コンテナがある場合、そのコンテナは、特定のノード上の_すべて_のコンテナの環境を検査し、内部に含まれる_すべて_のシークレットを公開できます。[完全なDevOpsライフサイクル](https://about.gitlab.com/blog/from-dev-to-devops/)の一部として、[`dind`](https://hub.docker.com/r/gitlab/dind/)は、レジストリにプッシュされ、その後デプロイされるコンテナの構築に定期的に使用されます。

この懸念が、[initContainers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)を介して機密情報を投入することを優先することにした理由です。

関連イシュー:

- [\#90](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/90)
- [\#114](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/114)

## サブチャートはグローバルチャートからデプロイされます {#sub-charts-are-deployed-from-global-chart}

このリポジトリのすべてのサブチャートは、グローバルチャートを介してデプロイされるように設計されています。各コンポーネントは個別にデプロイできますが、グローバルチャートによって容易になる共通のプロパティセットを利用します。

この決定により、リポジトリ全体の利用とメンテナンスの両方が簡素化されます。

関連イシューを参照してください:

- [\#352](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/352)

## `gitlab/*`のテンプレートパーシャルは、可能な限りグローバルにする必要があります {#template-partials-for-gitlab-should-be-global-whenever-possible}

`gitlab/*`サブチャートのすべてのテンプレートパーシャルは、可能な限りグローバルまたはGitLabサブチャート`templates/_helpers.tpl`の一部である必要があります。[フォークしたチャート](#forked-charts)からのテンプレートは、それらのチャートの一部になります。これにより、これらのフォークのメンテナンスへの影響が軽減されます。

これによる利点は、非常に簡単です:

- DRYの動作が向上し、メンテナンスが容易になります。単一のエントリで十分な場合、複数のサブチャートにわたって同じ関数の複製を作成する理由はありません。
- テンプレートの名前の競合が軽減されます。[チャート全体のすべてのパーシャルがまとめてコンパイル](https://helm.sh/docs/chart_template_guide/named_templates/#declaring-and-using-templates-with-define-and-template)されるため、グローバルな動作と同様に扱うことができます。

関連イシューを参照してください:

- [\#352](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/352)

## フォークしたチャート {#forked-charts}

次のチャートは、[フォークおよび新しいチャートのガイドライン](../development/readiness/_index.md)に従って、このリポジトリでフォークまたは再作成されています

### Redis {#redis}

`3.0`リリースのGitLab Helmチャートでは、[アップストリームRedisチャート](https://github.com/bitnami/charts/tree/main/bitnami/redis)をフォークしなくなり、依存関係として含めるようになりました。

### Redis HA {#redis-ha}

Redis-HAは、`3.0`より前のリリースに含まれていたチャートでした。削除され、オプションのHAサポートが追加された[アップストリームRedisチャート](https://github.com/bitnami/charts/tree/main/bitnami/redis)に置き換えられました。

### MinIO {#minio}

当社の[MinIOチャート](../charts/minio/_index.md)は、アップストリーム[MinIO](https://github.com/helm/charts/tree/master/stable/minio)から変更されました。

- プロパティから新しいKubernetes Secretsを作成する代わりに、既存のKubernetes Secretsを使用します。
- 環境を介した機密情報の提供を削除します。
- `defaultBucket.*`プロパティの代わりに`defaultBuckets`を介して複数のバケットの作成を自動化します。

### レジストリ {#registry}

当社の[レジストリチャート](../charts/registry/_index.md)は、アップストリーム[`docker-registry`](https://github.com/helm/charts/tree/master/stable/docker-registry)から変更されました。

- チャート内のMinIOサービスの使用を自動的に有効にします。
- GitLabサービスへの認証を自動的にフックします。

### NGINX Ingress {#nginx-ingress}

当社の[NGINX Ingressチャート](../charts/nginx/_index.md)は、アップストリーム[NGINX Ingress](https://github.com/kubernetes/ingress-nginx)から変更されました。

- TCP ConfigMapをチャートの外部に配置できるようにする機能を追加
- リリース名に基づいてIngressクラスをテンプレート化できるようにする機能を追加

## チャート全体で使用されるKubernetesバージョン {#kubernetes-version-used-throughout-chart}

さまざまなKubernetesバージョンのサポートを最大化するには、現在の安定リリースのKubernetesよりも1つ小さいマイナーバージョンの`kubectl`を使用します。これにより、少なくとも3つ、場合によってはさらに多くのKubernetesマイナーバージョンがサポートされるはずです。`kubectl`バージョンの詳細については、[イシュー1509](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1509)を参照してください。

関連イシュー:

- [`charts/gitlab#1509`](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1509)
- [`charts/gitlab#1583`](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1583)

関連するマージリクエスト:

- [`charts/gitlab!1053`](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/1053)
- [`build/CNG!329`](https://gitlab.com/gitlab-org/build/CNG/-/merge_requests/329)
- [`gitlab-build-images!251`](https://gitlab.com/gitlab-org/gitlab-build-images/-/merge_requests/251)

## CNGとともに出荷されるイメージバリアント {#image-variants-shipped-with-cng}

日付: 2022-02-10

[CNGプロジェクト](https://gitlab.com/gitlab-org/build/CNG)は、DebianとUBIの両方に基づいてイメージを出荷します。両方のディストリビューションの設定を維持するという決定は、以下に基づいています:

- Debianベースのイメージを出荷する理由:
  - 実績、先例
  - ディストリビューションの知識
  - コミュニティ対「エンタープライズ」
  - 認識されたベンダーロックインの欠如
- UBIベースのイメージを出荷する理由:
  - 一部の顧客環境で必須
  - RHEL認定およびOpenShift Marketplace / RedHatカタログへの包含に必要

このトピックに関する詳細なディスカッションについては、[イシュー#3095](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3095)を参照してください。

## Kubernetesリリースサポートポリシー {#kubernetes-release-support-policy}

日付: 2024-03-26

GitLabは、Kubernetesの3つのマイナーリリース（`N`、`N-1`、および`N-2`）を正式にサポートします。`N`は次のいずれかです:

- 認定が完了している場合は、Kubernetesの最新リリースされたマイナーバージョン。
- 最新のマイナーバージョンの認定を完了していないか、開始していない場合は、次に最新のマイナーバージョン。

たとえば、現在利用可能なリリースが`1.28`、`1.27`、`1.26`、`1.25`であり、リリース`1.28`を認定していない場合、`N`は`1.27`になり、この表に示すように、リリース`1.25`、`1.26`、および`1.27`を正式にサポートします。

| リリース | 参照 |
|---------|-----------|
| `1.27`  | `N`       |
| `1.26`  | `N-1`     |
| `1.25`  | `N-2`     |

詳細については、[Distribution Team Kubernetes and OpenShift release support policy](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/k8s-release-support-policy/)をご覧ください

## OpenShiftリリースサポートポリシー {#openshift-release-support-policy}

日付: 2024-03-26

GitLabは、OpenShiftの4つのマイナーリリース（`N`、`N-1`、`N-2`、`N-3`）を正式にサポートします。Kubernetesと同様に、`N`は次のいずれかです:

- 認定が完了している場合は、OpenShiftの最新リリースされたマイナーバージョン。
- 最新のマイナーバージョンの認定を完了していないか、開始していない場合は、次に最新のマイナーバージョン。

たとえば、現在利用可能なリリースが`4.14`、`4.13`、`4.12`、`4.11`であり、リリース4.15を認定していない場合、`N`は`4.14`になり、この表に示すように、リリース`4.14`、`4.13`、`4.12`、および`4.11`を正式にサポートします。

| リリース | 参照 |
|---------|-----------|
| `4.14`  | `N`       |
| `4.13`  | `N-1`     |
| `4.12`  | `N-2`     |
| `4.11`  | `N-2`     |

詳細については、[Distribution Team Kubernetes and OpenShift release support policy](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/k8s-release-support-policy/)をご覧ください
