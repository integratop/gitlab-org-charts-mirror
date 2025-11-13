---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのクラウドプロバイダー設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabチャートをデプロイする前に、選択したクラウドプロバイダーのリソースを設定する必要があります。

GitLabチャートは、少なくとも8仮想CPUと30 GBのRAMを持つクラスターに適合するように設計されています。本番環境以外のインスタンスをデプロイしようとしている場合は、より小さなクラスターに適合するようにデフォルトを減らすことができます。

## サポートされているKubernetesリリース {#supported-kubernetes-releases}

GitLab Helmチャートは、次のKubernetesリリースをサポートしています:

| Kubernetesリリース | ステータス      | 最小GitLabバージョン | アーキテクチャ |
|--------------------|-------------|------------------------|---------------|
| 1.34               | サポート対象   | 18.6                   | x86-64        |
| 1.33               | サポート対象   | 18.1                   | x86-64        |
| 1.32               | サポート対象   | 17.11                  | x86-64        |
| 1.31               | 非推奨  | 17.6                   | x86-64        |
| 1.30               | サポート対象外 | 17.6                   | x86-64        |

GitLab Helmチャートは、一度に3つのKubernetesマイナーバージョンをサポートし、新しいKubernetesリリースを最初のリリースから3か月後にサポートする予定です。

詳細については、[Kubernetesサポートポリシー](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/distribution/k8s-release-support-policy/)を参照してください。

上記のリリースよりも新しいリリースの互換性の問題については、[イシュートラッカー](https://gitlab.com/gitlab-org/charts/gitlab/-/issues)へのレポートをお待ちしております。

一部のGitLab機能は、非推奨のリリースまたは上記のリリースよりも古いリリースでは動作しない場合があります。

一部のコンポーネント（[Kubernetes用エージェント](https://docs.gitlab.com/user/clusters/agent/) 、[GitLab Operator](https://docs.gitlab.com/operator/installation/)など）では、GitLabが異なるクラスターリリースをサポートしている場合があります。

{{< alert type="warning" >}}

Kubernetesノードは、x86-64アーキテクチャを使用する必要があります。AArch64/ARM64を含む複数のアーキテクチャのサポートは、積極的に開発されています。詳細については、[イシュー2899](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2899)を参照してください。

{{< /alert >}}

- 環境のクラスタートポロジに関する推奨事項については、[参照アーキテクチャ](https://docs.gitlab.com/administration/reference_architectures/#available-reference-architectures)を参照してください。
- 3仮想CPU 12 GBクラスターに適合するようにリソースを調整する例については、[最小GKEサンプル値ファイル](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-gke-minimum.yaml)を参照してください。

## 特定のクラウドプロバイダー向けの手順 {#instructions-for-specific-cloud-providers}

環境内にKubernetesクラスターを作成して接続します:

- [Azure Kubernetes Service](aks.md)
- [Amazon EKS](eks.md)
- [Google Kubernetes Engine](gke.md)
- [OpenShift](openshift.md)
- [Oracle Container Engine for Kubernetes](oke.md)
