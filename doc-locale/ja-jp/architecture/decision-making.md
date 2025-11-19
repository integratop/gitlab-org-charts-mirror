---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#designated-technical-writers
title: 意思決定
---

このリポジトリへの変更は、まず[merge request workflow](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/merge_requests/)を使用してレビューされ、その後プロジェクトメンテナーによってマージされます。

（[architecture](architecture.md)ページや[decisions](decisions.md)ページに表示されるような）アーキテクチャに関する決定には、プロジェクトのシニアテクニカルリーダーシップによるレビューが必要です。シニアテクニカルリーダーシップとは、プロジェクトを担当するチームのエンジニアリングマネージャー、および[architecture handbook](https://handbook.gitlab.com/handbook/engineering/architecture/#architecture-as-a-practice-is-everyones-responsibility)に記載されているそのチームのスタッフ以上のリーダーシップ、およびプロジェクトに特有の目標を中心に編成された現在のワーキンググループによって特定される個人です。

## メンテナー {#maintainers}

プロジェクトメンテナーは、[GitLab projects page](https://handbook.gitlab.com/handbook/engineering/projects/#gitlab-chart)に記載されているか、[review workload dashboard](https://gitlab-org.gitlab.io/gitlab-roulette/?currentProject=gitlab-chart&mode=hide)を使用して見つけることができます。

メンテナーは、自身のドメイン内の変更をマージする責任を負い、プロジェクト全体と、変更が自身の専門分野外の領域にどのような影響を与えるかを理解する必要があります。

レビュアーは任意のメンテナーに割り当てることができ、メンテナーは自身の専門分野に該当しない場合、適切なドメインエキスパートを関与させます。

専門知識を継続的に展開するために、メンテナーは、自身のドメイン外の変更をマージする権限を与えられていますが、以下の場合を除き、**highly confident**である必要があります:

- 変更を後で元に戻せない場合
- 変更に、従う必要のある確立されたプロセスがある場合（JiHuレビュー、セキュリティ、法務/ライセンスの変更）
- 変更にアーキテクチャ上の決定が明確に必要な場合

緊急の変更が必要な場合、メンテナーは行動を重視し、決定が後で元に戻すことができ、既知のプロジェクトプロセス要件に準拠している限り、決定を下すことができます。

### 依存関係メンテナー {#dependency-maintainers}

依存関係メンテナーは、通常のメンテナーと同じ責任を負いますが、マージする能力は、特定のドメインの依存関係バージョニングに関連する変更に厳密にスコープが限定されています。依存関係バージョニング以外の変更がマージリクエストにある場合、通常のメンテナーがメンテナーレビューを実行する必要があります。

すべての変更は、動作するチャートをもたらす必要があり、依存関係バージョンの変更の影響は、依存関係メンテナーが完全に理解している必要があります。すでにチャートレビュアーである人は、依存関係メンテナーになるための良い候補者です。

| ユーザー名         | スコープ |
|------------------|-------|
| `@DylanGriffith` | `gitlab-zoekt` |
| `@dgruzd`        | `gitlab-zoekt` |
| `@terrichu`      | `gitlab-zoekt` |
| `@johnmason`     | `gitlab-zoekt` |

## プロジェクトリーダーシップ {#project-leadership}

| ユーザー名      | ロール |
|---------------|------|
| `@WarheadsSE` | スタッフエンジニア、ディストリビューションデプロイ |
| `@twk3`       | エンジニアリングマネージャー、ディストリビューションビルド |
| `@ayufan`     | 著名なエンジニア、イネーブルメント |
| `@stanhu`     | エンジニアリングフェロー |
