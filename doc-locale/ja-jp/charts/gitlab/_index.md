---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Helmサブチャート
---

GitLab Helm Chartは複数のサブチャートで構成されており、これらがコアのGitLabコンポーネントを提供します:

- [Gitaly](gitaly/_index.md)
- [GitLab Exporter](gitlab-exporter/_index.md)
- [GitLab Pages](gitlab-pages/_index.md)
- [GitLab Runner](gitlab-runner/_index.md)
- [GitLab Shell](gitlab-shell/_index.md)
- [GitLabエージェントサーバー（KAS）](kas/_index.md)
- [Mailroom](mailroom/_index.md)
- [移行](migrations/_index.md)
- [Praefect](praefect/_index.md)
- [Sidekiq](sidekiq/_index.md)
- [Spamcheck](spamcheck/_index.md)
- [Toolbox](toolbox/_index.md)
- [Webservice](webservice/_index.md)

各サブチャートのパラメータは、`gitlab`キーの下にある必要があります。たとえば、GitLab Shellのパラメータは次のようになります:

```yaml
gitlab:
  gitlab-shell:
    ...
```

これらのチャートは、オプションの依存関係に使用します:

- [MinIO](../minio/_index.md)
- [NGINX](../nginx/_index.md)
- [HAProxy](../haproxy/_index.md)
- [PostgreSQL](https://artifacthub.io/packages/helm/bitnami/postgresql)
- [Redis](https://artifacthub.io/packages/helm/bitnami/redis)
- [レジストリ](../registry/_index.md)
- [Traefik](../traefik/_index.md)

これらのチャートは、オプションの追加として使用します:

- [Prometheus](https://artifacthub.io/packages/helm/prometheus-community/prometheus)
- [_権限のない_](https://docs.gitlab.com/runner/install/kubernetes.html#running-docker-in-docker-containers-with-gitlab-runner) Kubernetes executorを使用する[GitLab Runner](https://docs.gitlab.com/runner/)
- [Let's Encrypt](https://letsencrypt.org/)から自動的にプロビジョニングされたSSL。[Jetstack](https://venafi.com/jetstack-consult/)の[cert-manager](https://cert-manager.io/docs/)と[certmanager-issuer](../certmanager-issuer/_index.md)を使用します

## GitLab Helmサブチャートのオプションのパラメータ {#gitlab-helm-subchart-optional-parameters}

### アフィニティ {#affinity}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3770) GitLab 17.3（チャート8.3） `webservice`および`sidekiq`を除くすべてのGitLab Helmサブチャート用

{{< /history >}}

`affinity`は、すべてのGitLab Helmサブチャートのオプションのパラメータです。設定すると、[グローバル`affinity`](../globals.md#affinity)の値よりも優先されます。`affinity`の詳細については、[関連するKubernetesドキュメント](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)を参照してください。

{{< alert type="note" >}}

`webservice`および`sidekiq` Helmチャートは、[グローバル`affinity`](../globals.md#affinity)の値のみを使用できます。ローカル`affinity`が`webservice`および`sidekiq`に実装される時期については、[イシュー25403](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25403)に従ってください。

{{< /alert >}}

`affinity`を使用すると、次のいずれかまたは両方を設定できます:

- 次の`podAntiAffinity`ルール:
  - `topology key`に対応する式に一致するポッドと同じドメインにポッドをスケジュール設定しません。
  - 2つのモードの`podAntiAffinity`ルールを設定します。必須（`requiredDuringSchedulingIgnoredDuringExecution`）と推奨（`preferredDuringSchedulingIgnoredDuringExecution`）。`antiAffinity`変数を`values.yaml`で使用して、設定を`soft`に設定して推奨モードを適用するか、`hard`に設定して必須モードを適用します。
- 次の`nodeAffinity`ルール:
  - 特定のゾーンに属するノードにポッドをスケジュール設定します。
  - 2つのモードの`nodeAffinity`ルールを設定します。必須（`requiredDuringSchedulingIgnoredDuringExecution`）と推奨（`preferredDuringSchedulingIgnoredDuringExecution`）。`soft`に設定すると、推奨モードが適用されます。`hard`に設定すると、必須モードが適用されます。このルールは、`registry`チャートと、`webservice`および`sidekiq`を除くすべてのサブチャートとともに`gitlab`チャートにのみ実装されます。

`nodeAffinity`は、[`In`演算子](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators)のみを実装します。

次の例では、`affinity`を設定し、`nodeAffinity`と`antiAffinity`の両方を`hard`に設定します:

```yaml
nodeAffinity: "hard"
antiAffinity: "hard"
affinity:
  nodeAffinity:
    key: "test.com/zone"
    values:
    - us-east1-a
    - us-east1-b
  podAntiAffinity:
    topologyKey: "test.com/hostname"
```
