---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートにカスタムDockerイメージを使用する
---

特定のシナリオ（オフライン環境など）では、インターネットからプルするのではなく、独自のDockerイメージを持ち込むことが必要な場合があります。これには、GitLabリリースを構成するチャートごとに、独自のDockerイメージレジストリ/リポジトリを指定する必要があります。

## デフォルトのイメージ形式 {#default-image-format}

ほとんどの場合、イメージのデフォルト形式には、タグを除外するイメージへの完全パスが含まれます:

```yaml
image:
  repository: repo.example.com/image
  tag: custom-tag
```

最終的な結果は`repo.example.com/image:custom-tag`になります。

## 現在のイメージとタグ {#current-images-and-tags}

アップグレードを計画する際、現在の`values.yaml`とターゲットバージョンのGitLabチャートを使用して、[Helm template](https://helm.sh/docs/helm/helm_template/)を生成できます。このテンプレートには、指定されたバージョンのチャートに必要なイメージとそれぞれのタグが含まれます。

```shell
# Gather the latest values
helm get values gitlab > gitlab.yaml

# Use the gitlab.yaml to find the images and tags
helm template versionfinder gitlab/gitlab -f gitlab.yaml --version 7.3.0 | grep 'image:' | tr -d '[[:blank:]]' | sort --unique
```

このコマンドは、カスタム設定の検証にも使用できます。

## 値ファイルの例 {#example-values-file}

カスタムDockerレジストリ/リポジトリとタグを設定する方法を示す[値ファイルの例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/custom-images/values.yaml)があります。独自のリリースに合わせて、このファイルの関連セクションをコピーできます。

{{< alert type="note" >}}

一部のチャート（特にサードパーティのチャート）では、イメージレジストリ/リポジトリとタグを指定するための規則が若干異なる場合があります。サードパーティのチャートに関するドキュメントは、[Artifact Hub](https://artifacthub.io/)で確認できます。

{{< /alert >}}
