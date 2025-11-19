---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 目標
---

このイニシアチブには、いくつかの主要な目標があります:

1. 水平にスケールするのが容易
1. デプロイ、アップグレード、メンテナンスが容易
1. クラウドサービスプロバイダーの幅広いサポート
1. KubernetesとHelmの初期サポート、および将来の他のスケジューラーをサポートするための柔軟性

## スケジューラー {#scheduler}

Kubernetesのサポートを開始します。Kubernetesは成熟しており、業界全体で広くサポートされています。ただし、設計の一環として、他のスケジューラーのサポートを排除するような決定は避けるようにします。これは、ダウンストリームのKubernetesプロジェクト（OpenShiftやTectonicなど）に特に当てはまります。将来的には、Docker SwarmやMesosphereなど、他のスケジューラーもサポートされる可能性があります。

Kubernetesのスケーリング機能と自己修復機能をサポートすることを目指しています:

- ポッドが機能していることを確認し、機能していない場合はリサイクルするためのReadinessおよびヘルスチェック
- カナリアおよびローリングデプロイをサポートするための追跡
- [自動スケーリング](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

標準のKubernetes機能の活用を試みます:

- 設定を管理するためのConfigMap。これらはマップされるか、Dockerコンテナに渡されます
- 機密データ用のシークレット

Consulも使用する可能性があるため、他のインストール方法との一貫性を保つために、代わりにConsulを利用できます。

## Helmチャート {#helm-charts}

<!-- vale gitlab_base.SubstitutionWarning = NO -->

各GitLab固有のコンテナ/サービスのデプロイを管理するために、Helmチャートが作成されます。次に、バンドルされたチャートを含めて、全体のデプロイを簡単にします。これは、オールインワンのOmnibusベースのソリューションよりも、DockerおよびKubernetesレイヤーの方がはるかに複雑になるため、この取り組みにとって特に重要です。Helmは、この複雑さを管理し、`values.yaml`ファイルを介して設定を管理するための簡単なトップレベルのインターフェースを提供します。

3段階のHelmチャートのセットを提供する予定です:

![Helmチャートの構成](../images/charts.png)
