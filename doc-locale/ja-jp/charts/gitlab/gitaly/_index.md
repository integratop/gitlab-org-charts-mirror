---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-Gitalyチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`gitaly`サブチャートは、Gitalyサーバーの構成可能なデプロイを提供します。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされるKubernetesクラスタから到達可能な外部サービスとして提供されるWorkhorseサービスへのアクセスに依存します。

## 設計上の選択 {#design-choices}

このチャートで使用されているGitalyコンテナには、まだGitalyに移植されていないGitリポジトリに対するアクションを実行するために、GitLab Shellコードベースも含まれています。Gitalyコンテナには、その中にGitLab Shellコンテナのコピーが含まれており、その結果、このチャート内でGitLab Shellも構成する必要があります。

## 設定 {#configuration}

`gitaly`チャートは、[外部サービス](#external-services)と[チャート設定](#chart-settings)の2つの部分で構成されています。

Gitalyは、GitLabチャートをデプロイする際に、デフォルトでコンポーネントとしてデプロイされます。Gitalyを個別にデプロイする場合は、`global.gitaly.enabled`を`false`に設定する必要があり、追加の設定は、[外部Gitalyドキュメント](../../../advanced/external-gitaly/_index.md)に記載されているように実行する必要があります。

### インストールコマンドラインオプション {#installation-command-line-options}

以下の表に、`helm install`コマンドに`--set`フラグを使用して指定できる、可能なすべてのチャートの設定を示します。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `annotations`                                            |                                                         | ポッドの注釈 |
| `backup.goCloudUrl`                                      |                                                         | [サーバー側のGitalyバックアップ](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)のオブジェクトストレージURL。 |
| `common.labels`                                          | `{}`                                                    | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `podLabels`                                              |                                                         | 追加のポッドラベル。セレクターには使用されません。 |
| `external[].hostname`                                    | `- ""`                                                  | 外部ノードのホスト名 |
| `external[].name`                                        | `- ""`                                                  | 外部ノードストレージの名前 |
| `external[].port`                                        | `- ""`                                                  | 外部ノードのポート |
| `extraContainers`                                        |                                                         | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                    |                                                         | 含める追加のinitコンテナのリスト |
| `extraVolumeMounts`                                      |                                                         | 実行する追加のボリュームマウントのリスト |
| `extraVolumes`                                           |                                                         | 作成する追加のボリュームのリスト |
| `extraEnv`                                               |                                                         | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                         | 公開する他のデータソースからの追加の環境変数のリスト |
| `gitaly.serviceName`                                     |                                                         | 生成されたGitalyサービスの名前。`global.gitaly.serviceName`をオーバーライドし、デフォルトは`<RELEASE-NAME>-gitaly`です |
| `gpgSigning.enabled`                                     | `false`                                                 | [Gitaly GPG署名](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)を使用するかどうか。 |
| `gpgSigning.secret`                                      |                                                         | Gitaly GPG署名に使用されるシークレットの名前。 |
| `gpgSigning.key`                                         |                                                         | GitalyのGPG署名キーを含むGPGシークレット内のキー。 |
| `image.pullPolicy`                                       | `Always`                                                | Gitalyイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                         | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitaly`       | Gitalyイメージリポジトリ |
| `image.tag`                                              | `master`                                                | Gitalyイメージタグ付け |
| `init.image.repository`                                  |                                                         | initコンテナイメージ |
| `init.image.tag`                                         |                                                         | initコンテナイメージタグ付け |
| `init.containerSecurityContext`                          |                                                         | initコンテナ固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | initコンテナ固有: プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | initコンテナ固有: コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | initコンテナ固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `internal.names[]`                                       | `- default`                                             | StatefulSetストレージの順序付けられた名前 |
| `serviceLabels`                                          | `{}`                                                    | 補足サービスラベル |
| `service.externalPort`                                   | `8075`                                                  | Gitalyサービス公開ポート |
| `service.internalPort`                                   | `8075`                                                  | Gitaly内部ポート |
| `service.name`                                           | `gitaly`                                                | GitalyがServiceオブジェクトの背後にあるServiceポートの名前。 |
| `service.type`                                           | `ClusterIP`                                             | Gitalyサービスタイプ |
| `service.clusterIP`                                      | `None`                                                  | Service作成リクエストの一部として、独自のクラスタIPアドレスを指定できます。これは、KubernetesのServiceオブジェクトのclusterIPと同じ規則に従います。`service.type`がLoadBalancerの場合は、これを設定しないでください。 |
| `service.loadBalancerIP`                                 |                                                         | 設定しない場合は、一時的なIPアドレスが作成されます。これは、KubernetesのServiceオブジェクトのloadbalancerIP設定と同じ規則に従います。 |
| `serviceAccount.annotations`                             | `{}`                                                    | ServiceAccountのアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                 | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                 | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                         | ServiceAccountの名前。設定しない場合、チャートのフルネームが使用されます |
| `securityContext.fsGroup`                                | `1000`                                                  | ポッドを開始するグループID |
| `securityContext.fsGroupChangePolicy`                    |                                                         | ボリュームの所有権とアクセス許可を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.runAsUser`                              | `1000`                                                  | ポッドを開始するユーザーID |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | 使用するSeccompプロファイル |
| `shareProcessNamespace`                                  | `false`                                                 | 同じポッド内の他のすべてのコンテナがコンテナプロセスを表示できるようにします |
| `containerSecurityContext`                               |                                                         | Gitalyコンテナが開始されるオーバーライドコンテナ[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | Gitalyコンテナが開始される特定のsecurityContextユーザーIDの上書きを許可します |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | Gitalyコンテナのプロセスが親プロセスよりも多くの権限を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | Gitalyコンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `tolerations`                                            | `[]`                                                    | ポッドの割り当ての容認ラベル |
| `affinity`                                               | `{}`                                                    | ポッドの割り当ての[アフィニティルール](../_index.md#affinity) |
| `persistence.accessMode`                                 | `ReadWriteOnce`                                         | Gitalyの永続アクセスモード |
| `persistence.annotations`                                |                                                         | Gitaly永続アノテーション |
| `persistence.enabled`                                    | `true`                                                  | Gitalyの永続化を有効にするフラグ |
| `persistance.labels`                                     |                                                         | Gitalyの永続ラベル |
| `persistence.matchExpressions`                           |                                                         | バインドするラベル式の照合 |
| `persistence.matchLabels`                                |                                                         | バインドするラベル値の一致 |
| `persistence.size`                                       | `50Gi`                                                  | Gitaly永続ボリュームサイズ |
| `persistence.storageClass`                               |                                                         | プロビジョニングのstorageClassName |
| `persistence.subPath`                                    |                                                         | Gitalyの永続ボリュームのマウントパス |
| `priorityClassName`                                      |                                                         | Gitaly StatefulSet priorityClassName |
| `logging.level`                                          |                                                         | ログレベル   |
| `logging.format`                                         | `json`                                                  | ログ形式  |
| `logging.sentryDsn`                                      |                                                         | Sentry DSN URL - Goサーバーからの例外 |
| `logging.sentryEnvironment`                              |                                                         | ログ記録に使用するSentry環境 |
| `shell.concurrency[]`                                    |                                                         | 各RPCsエンドポイントの並行処理。設定キーについては、[RPCの並行処理を制限する](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/#limit-rpc-concurrency)および[RPCの並行処理の適応機能を有効にする](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/#enable-adaptiveness-for-rpc-concurrency)を参照してください。 |
| `packObjectsCache.enabled`                               | `false`                                                 | Gitalyパック化されたオブジェクトのキャッシュを有効にします |
| `packObjectsCache.dir`                                   | `/home/git/repositories/+gitaly/PackObjectsCache`       | キャッシュファイルが格納されるディレクトリ |
| `packObjectsCache.max_age`                               | `5m`                                                    | キャッシュエントリの有効期間 |
| `packObjectsCache.min_occurrences`                       | `1`                                                     | キャッシュエントリを作成するために必要な最小カウント |
| `git.catFileCacheSize`                                   |                                                         | Git cat-fileプロセスで使用されるキャッシュサイズ |
| `git.config[]`                                           | `[]`                                                    | Gitコマンドの起動時にGitalyが設定する必要があるGit設定 |
| `prometheus.grpcLatencyBuckets`                          |                                                         | Gitalyによって記録されるGRPCメソッド呼び出しにおけるヒストグラムレイテンシーに対応するバケット。文字列形式の配列（たとえば、`"[1.0, 1.5, 2.0]"`）が入力として必要です |
| `statefulset.strategy`                                   | `{}`                                                    | StatefulSetで使用される更新戦略を構成できます |
| `statefulset.livenessProbe.initialDelaySeconds`          | `0`                                                     | Livenessプローブが開始されるまでの遅延。startupProbeが有効になっている場合、これは0に設定されます。 |
| `statefulset.livenessProbe.periodSeconds`                | `10`                                                    | Livenessプローブを実行する頻度 |
| `statefulset.livenessProbe.timeoutSeconds`               | `3`                                                     | Livenessプローブがタイムアウトしたとき |
| `statefulset.livenessProbe.successThreshold`             | `1`                                                     | Livenessプローブが失敗した後、正常と見なされるために連続して成功する最小回数 |
| `statefulset.livenessProbe.failureThreshold`             | `3`                                                     | Livenessプローブが成功した後、失敗と見なされるために連続して失敗する最小回数 |
| `statefulset.readinessProbe.initialDelaySeconds`         | `0`                                                     | Readinessプローブが開始されるまでの遅延。startupProbeが有効になっている場合、これは0に設定されます。 |
| `statefulset.readinessProbe.periodSeconds`               | `5`                                                     | Readinessプローブを実行する頻度 |
| `statefulset.readinessProbe.timeoutSeconds`              | `3`                                                     | Readinessプローブがタイムアウトしたとき |
| `statefulset.readinessProbe.successThreshold`            | `1`                                                     | Readinessプローブが失敗した後、正常と見なされるために連続して成功する最小回数 |
| `statefulset.readinessProbe.failureThreshold`            | `3`                                                     | Readinessプローブが成功した後、失敗と見なされるために連続して失敗する最小回数 |
| `statefulset.startupProbe.enabled`                       | `true`                                                  | Startupプローブを有効にするかどうか。 |
| `statefulset.startupProbe.initialDelaySeconds`           | `1`                                                     | Startupプローブが開始されるまでの遅延 |
| `statefulset.startupProbe.periodSeconds`                 | `1`                                                     | Startupプローブを実行する頻度 |
| `statefulset.startupProbe.timeoutSeconds`                | `1`                                                     | Startupプローブがタイムアウトしたとき |
| `statefulset.startupProbe.successThreshold`              | `1`                                                     | Startupプローブが失敗した後、正常と見なされるために連続して成功する最小回数 |
| `statefulset.startupProbe.failureThreshold`              | `60`                                                    | Startupプローブが成功した後、失敗と見なされるために連続して失敗する最小回数 |
| `metrics.enabled`                                        | `false`                                                 | メトリクスエンドポイントをスクレイプできるようにするかどうか |
| `metrics.port`                                           | `9236`                                                  | メトリクスエンドポイントのポート |
| `metrics.path`                                           | `/metrics`                                              | メトリクスエンドポイントのパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Prometheus Operatorがメトリクスのスクレイピングを管理できるようにServiceMonitorを作成するかどうか。これを有効にすると、`prometheus.io`スクレイピングアノテーションが削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | ServiceMonitorの追加のエンドポイント設定 |
| `metrics.metricsPort`                                    |                                                         | **DEPRECATED**（非推奨）`metrics.port`を使用 |
| `gomemlimit.enabled`                                     | `true`                                                  | この値は、Gitalyコンテナの環境変数`GOMEMLIMIT`を自動的に`resources.limits.memory`に設定します（その制限も設定されている場合）。ユーザーは、この値を失敗に設定し、`GOMEMLIMIT`を`extraEnv`に設定することで、この値をオーバーライドできます。これは、[ドキュメント化された形式基準](https://pkg.go.dev/runtime#hdr-Environment_Variables)を満たしている必要があります。 |
| `cgroups.enabled`                                        | `false`                                                 | Gitalyには、cgroups制御が組み込まれています。設定すると、Gitalyは、Gitコマンドが動作しているリポジトリに基づいて、Gitプロセスをcgroupに割り当てます。このパラメータは、リポジトリcgroupsを有効にします。有効にした場合、cgroups v2のみがサポートされることに注意してください。 |
| `cgroups.initContainer.image.repository`                 | `registry.com/gitlab-org/build/cng/gitaly-init-cgroups` | Gitalyイメージリポジトリ |
| `cgroups.initContainer.image.tag`                        | `master`                                                | Gitalyイメージタグ付け |
| `cgroups.initContainer.image.pullPolicy`                 | `IfNotPresent`                                          | Gitalyイメージプルポリシー |
| `cgroups.mountpoint`                                     | `/etc/gitlab-secrets/gitaly-pod-cgroup`                 | 親cgroupディレクトリがマウントされている場所。 |
| `cgroups.hierarchyRoot`                                  | `gitaly`                                                | 親cgroup。Gitalyがグループを作成し、Gitalyが実行するユーザーとグループが所有権を持つことが想定されています。 |
| `cgroups.memoryBytes`                                    |                                                         | Gitalyが起動するすべてのGitプロセスにまとめて課せられる合計メモリ制限。0は制限がないことを意味します。 |
| `cgroups.cpuShares`                                      |                                                         | Gitalyが起動するすべてのGitプロセスにまとめて課せられるCPU制限。0は制限がないことを意味します。最大は1024共有で、CPUの100％を表します。 |
| `cgroups.cpuQuotaUs`                                     |                                                         | このクォータ値を超えた場合にcgroupsのプロセスをスロットルするために使用されます。cpuQuotaUsを100msに設定すると、1コアは100000になります。0は制限がないことを意味します。 |
| `cgroups.repositories.count`                             |                                                         | cgroupsプール内のcgroupの数。新しいGitコマンドが起動されるたびに、Gitalyはコマンドの対象となるリポジトリに基づいて、これらのcgroupのいずれかに割り当てます。循環ハッシュアルゴリズムは、これらのcgroupにGitコマンドを割り当てます。そのため、リポジトリのGitコマンドは常に同じcgroupに割り当てられます。 |
| `cgroups.repositories.memoryBytes`                       |                                                         | リポジトリcgroupに含まれるすべてのGitプロセスに課せられる合計メモリ制限。0は制限がないことを意味します。この値は、トップレベルのmemoryBytesの値を超えることはできません。 |
| `cgroups.repositories.cpuShares`                         |                                                         | リポジトリcgroupに含まれるすべてのGitプロセスに課せられるCPU制限。0は制限がないことを意味します。最大は1024共有で、CPUの100％を表します。この値は、トップレベルのcpuSharesの値を超えることはできません。 |
| `cgroups.repositories.cpuQuotaUs`                        |                                                         | リポジトリcgroupに含まれるすべてのGitプロセスに課せられるcpuQuotaUs。Gitプロセスは、指定されたクォータを超えることはできません。cpuQuotaUsを100msに設定すると、1コアは100000になります。0は制限がないことを意味します。 |
| `cgroups.repositories.maxCgroupsPerRepo`                 | `1`                                                     | 特定のリポジトリをターゲットとするGitプロセスを分散できるリポジトリcgroupの数。これにより、バースト的なワークロードを許可しながら、より保守的なCPUおよびメモリ制限をリポジトリcgroupに構成できます。たとえば、`maxCgroupsPerRepo`が`2`で、`memoryBytes`制限が10GBの場合、特定のリポジトリに対する独立したGit操作では、最大20GBのメモリを消費できます。 |
| `gracefulRestartTimeout`                                 | `25`                                                    | Gitalyシャットダウンの猶予期間。飛行中のリクエストが完了するまで待機する時間（秒）。ポッド`terminationGracePeriodSeconds`は、この値+ 5秒に設定されます。 |
| `timeout.uploadPackNegotiation`                          |                                                         | [ネゴシエーションタイムアウトを設定する](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#configure-the-negotiation-timeouts)を参照してください。 |
| `timeout.uploadArchiveNegotiation`                       |                                                         | [ネゴシエーションタイムアウトを設定する](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#configure-the-negotiation-timeouts)を参照してください。 |
| `dailyMaintenance.disabled`                              |                                                         | 毎日のバックグラウンドメンテナンスを無効にすることができます。 |
| `dailyMaintenance.duration`                              |                                                         | 毎日のバックグラウンドメンテナンスの最大継続時間。たとえば、「1h」または「45m」。 |
| `dailyMaintenance.startHour`                             |                                                         | 毎日のバックグラウンドメンテナンスの開始時間。 |
| `dailyMaintenance.startMinute`                           |                                                         | 毎日のバックグラウンドメンテナンスの開始時間。 |
| `dailyMaintenance.storages`                              |                                                         | 毎日のバックグラウンドメンテナンスを実行するストレージ名の配列。たとえば、[「default」]。 |
| `bundleUri.goCloudUrl`                                   |                                                         | [バンドルURIに関するドキュメント](https://docs.gitlab.com/administration/gitaly/bundle_uris/)を参照してください。 |

## チャート設定の例 {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv`を使用すると、ポッド内のすべてのコンテナで追加の環境変数を公開できます。

`extraEnv`の使用例を以下に示します:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナの起動時に、環境変数が公開されていることを確認できます:

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで、他のデータソースからの追加の環境変数を公開できます。

`extraEnvFrom`の使用例を以下に示します:

```yaml
extraEnvFrom:
  MY_NODE_NAME:
    fieldRef:
      fieldPath: spec.nodeName
  MY_CPU_REQUEST:
    resourceFieldRef:
      containerName: test-container
      resource: requests.cpu
  SECRET_THING:
    secretKeyRef:
      name: special-secret
      key: special_token
      # optional: boolean
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに認証して、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)にあります。

`pullSecrets`の使用例を以下に示します

```yaml
image:
  repository: my.gitaly.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、またデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccount注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | を設定すると、デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます。 |

### tolerations {#tolerations}

`tolerations`を使用すると、taintされたワーカーノードでポッドをスケジュールできます

`tolerations`の使用例を以下に示します:

```yaml
tolerations:
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
```

### アフィニティ {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

### 注釈 {#annotations}

`annotations`を使用すると、注釈をGitalyポッドに追加できます。

`annotations`の使用例を以下に示します:

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### priorityClassName {#priorityclassname}

`priorityClassName`を使用すると、[PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)をGitalyポッドに割り当てることができます。

`priorityClassName`の使用例を以下に示します:

```yaml
priorityClassName: persistence-enabled
```

### `git.config` {#gitconfig}

`git.config`を使用すると、Gitalyによって起動されたすべてのGitコマンドに設定を追加できます。以下に示すように、`git-config(1)`のドキュメントに記載されている設定を`key` / `value`のペアで受け入れます。

```yaml
git:
  config:
    - key: "pack.threads"
      value: 4
    - key: "fsck.missingSpaceBeforeDate"
      value: ignore
```

### cgroups {#cgroups}

リソースの枯渇を防ぐため、Gitalyは**cgroups**を使用して、操作対象のリポジトリに基づいてGitプロセスをcgroupに割り当てます。各cgroupにはメモリとCPUの制限があり、システムの安定性を確保し、リソースの飽和を防ぎます。

Gitalyの起動前に実行される`initContainer`は、**rootとして実行**される必要があります。このコンテナは、Gitalyがcgroupを管理できるように、権限を設定します。したがって、`/sys/fs/cgroup`への書き込みアクセス権を持つように、ファイルシステムにボリュームをマウントします。

[オーバーサブスクリプションの例](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configuring-oversubscription)

```yaml
cgroups:
  enabled: true
  # Total limit across all repository cgroups
  memoryBytes: 64424509440 # 60GiB
  cpuShares: 1024
  cpuQuotaUs: 1200000 # 12 cores
  # Per repository limits, 1000 repository cgroups
  repositories:
    count: 1000
    memoryBytes: 32212254720 # 30GiB
    cpuShares: 512
    cpuQuotaUs: 400000 # 4 cores
```

## 外部サービス {#external-services}

このチャートは、Workhorseサービスに接続する必要があります。

### Workhorse {#workhorse}

```yaml
workhorse:
  host: workhorse.example.com
  serviceName: webservice
  port: 8181
```

| 名前          |  型   | デフォルト      | 説明 |
|:--------------|:-------:|:-------------|:------------|
| `host`        | 文字列  |              | Workhorseサーバーのホスト名。`serviceName`の代わりとして省略できます。 |
| `port`        | 整数 | `8181`       | Workhorseサーバーへの接続ポート。 |
| `serviceName` | 文字列  | `webservice` | Workhorseサーバーを操作している`service`名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、WorkhorseをGitLabチャート全体の一部として使用する場合に便利です。 |

## チャートの設定 {#chart-settings}

次の値は、Gitalyポッドを設定するために使用されます。

{{< alert type="note" >}}

Gitalyは、認証トークンを使用してWorkhorseおよびSidekiqサービスで認証します。認証トークンのシークレットとキーは、`global.gitaly.authToken`値から取得されます。さらに、GitalyコンテナにはGitLab Shellのコピーがあり、設定できるものがいくつかあります。Shell認証トークンは、`global.shell.authToken`値から取得されます。

{{< /alert >}}

### Gitリポジトリの永続性 {#git-repository-persistence}

このチャートは、PersistentVolumeClaimをプロビジョニングし、Gitリポジトリデータに対応する永続ボリュームをマウントします。これが機能するには、Kubernetesクラスタリングで使用可能な物理ストレージが必要です。emptyDirを使用する場合は、`persistence.enabled: false`でPersistentVolumeClaimを無効にします。

{{< alert type="note" >}}

Gitalyの永続性の設定は、すべてのGitalyポッドに対して有効であるボリュームクレームテンプレートで使用されます。単一の特定のボリューム（`volumeName`など）を参照するための設定を含めるべき*ではありません*。特定のボリュームを参照する場合は、PersistentVolumeClaimを手動で作成する必要があります。

{{< /alert >}}

{{< alert type="note" >}}

一度デプロイすると、これらの設定を当社経由で変更することはできません。[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)では、`VolumeClaimTemplate`はイミュータブルです。{{< /alert >}}

```yaml
persistence:
  enabled: true
  storageClass: standard
  accessMode: ReadWriteOnce
  size: 50Gi
  matchLabels: {}
  matchExpressions: []
  subPath: "data"
  annotations: {}
```

| 名前               |  型   | デフォルト         | 説明 |
|:-------------------|:-------:|:----------------|:------------|
| `accessMode`       | 文字列  | `ReadWriteOnce` | PersistentVolumeClaimでリクエストされたaccessModeを設定します。詳細については、[Kubernetesアクセスモードのドキュメント](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)を参照してください。 |
| `enabled`          | ブール値 | `true`          | リポジトリデータにPersistentVolumeClaimを使用するかどうかを設定します。`false`の場合、emptyDirボリュームが使用されます。 |
| `matchExpressions` |  配列  |                 | バインドするボリュームを選択するときに、照合するラベル条件オブジェクトの配列を受け入れます。これは、`PersistentVolumeClaim` `selector`セクションで使用されます。[ボリュームドキュメント](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)を参照してください。 |
| `matchLabels`      |   マップ   |                 | バインドするボリュームを選択するときに、照合するラベル名とラベル値のマップを受け入れます。これは、`PersistentVolumeClaim` `selector`セクションで使用されます。[ボリュームドキュメント](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)を参照してください。 |
| `size`             | 文字列  | `50Gi`          | データ永続性に対してリクエストする最小ボリュームサイズ。 |
| `storageClass`     | 文字列  |                 | 動的なプロビジョニングのために、ボリュームクレームにstorageClassNameを設定します。設定されていないかnullの場合、デフォルトのプロビジョニング機能が使用されます。ハイフンに設定すると、動的なプロビジョニングが無効になります。 |
| `subPath`          | 文字列  |                 | ボリュームルートではなく、マウントするボリューム内のパスを設定します。subPathが空の場合、ルートが使用されます。 |
| `annotations`      |   マップ   |                 | 動的なプロビジョニングのために、ボリュームクレームに注釈を設定します。詳細については、[Kubernetes注釈のドキュメント](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)を参照してください。 |

### TLS経由でのGitalyの実行 {#running-gitaly-over-tls}

{{< alert type="note" >}}

このセクションでは、Helm Chartを使用してクラスタリング内で実行されるGitalyについて説明します。外部Gitalyインスタンスを使用しており、TLSを使用して通信する場合は、[外部Gitalyドキュメント](../../../advanced/external-gitaly/_index.md#connecting-to-external-gitaly-over-tls)を参照してください

{{< /alert >}}

Gitalyは、TLS経由で他のコンポーネントとの通信をサポートしています。これは、`global.gitaly.tls.enabled`および`global.gitaly.tls.secretName`の設定によって制御されます。TLS経由でGitalyを実行する手順に従ってください:

1. Helm Chartは、TLS経由でGitalyと通信するために証明書が提供されることを想定しています。この証明書は、存在するすべてのGitalyノードに適用される必要があります。したがって、これらの各Gitalyノードのすべてのホスト名を、件名代替名（SAN）として証明書に追加する必要があります。

   使用するホスト名を知るには、Toolboxポッドの`/srv/gitlab/config/gitlab.yml`ファイルを確認し、その中の`repositories.storages`キーの下に指定されているさまざまな`gitaly_address`フィールドを確認します。

   ```shell
   kubectl exec -it <Toolbox pod> -- grep gitaly_address /srv/gitlab/config/gitlab.yml
   ```

{{< alert type="note" >}}

内部Gitalyポッド用のカスタム署名付き証明書を生成するための基本的なスクリプトは、[このリポジトリにあります](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh)。ユーザーは、適切なSAN属性を持つ証明書を生成するために、そのスクリプトを使用または参照できます。

{{< /alert >}}

1. 作成された証明書を使用して、k8s TLSシークレットを作成します。

   ```shell
   kubectl create secret tls gitaly-server-tls --cert=gitaly.crt --key=gitaly.key
   ```

1. `--set global.gitaly.tls.enabled=true`を渡して、Helm Chartを再デプロイします。

### グローバルサーバーフック {#global-server-hooks}

Gitaly StatefulSetは、[グローバルサーバーフック](https://docs.gitlab.com/administration/server_hooks/#create-a-global-server-hook-for-all-repositories)をサポートしています。フックスクリプトはGitalyポッドで実行されるため、[Gitalyコンテナ](https://gitlab.com/gitlab-org/build/CNG/-/blob/master/gitaly/Dockerfile)で使用可能なツールに限定されます。

フックは[ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)を使用して入力された状態になり、必要に応じて次の値を設定することで使用できます:

1. `global.gitaly.hooks.preReceive.configmap`
1. `global.gitaly.hooks.postReceive.configmap`
1. `global.gitaly.hooks.update.configmap`

ConfigMapに入力するには、スクリプトのディレクトリに`kubectl`マップを割り当てることができます:

```shell
kubectl create configmap MAP_NAME --from-file /PATH/TO/SCRIPT/DIR
```

### GitLabによって作成されたコミットへのGPG署名 {#gpg-signing-commits-created-by-gitlab}

Gitalyには、GitLab UI（WebIDEなど）を介して作成されたすべての[GPG署名コミット](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)だけでなく、マージコミットやスカッシュなど、GitLabによって作成されたコミットに署名する機能があります。

1. GPGプライベートキーを使用して、k8sシークレットを作成します。

   ```shell
   kubectl create secret generic gitaly-gpg-signing-key --from-file=signing_key=/path/to/gpg_signing_key.gpg
   ```

1. `values.yaml`設定でGPG署名を有効にします。

   ```yaml
   gitlab:
     gitaly:
       gpgSigning:
         enabled: true
         secret: gitaly-gpg-signing-key
         key: signing_key
   ```

### サーバー側のバックアップ {#server-side-backups}

このチャートは、[Gitalyサーバー側のバックアップ](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)をサポートしています。それらを使用するには:

1. バックアップを保存するためのバケットを作成します。
1. オブジェクトストレージの認証情報とストレージURLを設定します。

   ```yaml
   gitlab:
     gitaly:
       extraEnvFrom:
          # Mount the exisitign object store secret to the expected environment variables.
          AWS_ACCESS_KEY_ID:
            secretKeyRef:
              name: <Rails object store secret>
              key: aws_access_key_id
          AWS_SECRET_ACCESS_KEY:
            secretKeyRef:
              name: <Rails object store secret>
              key: aws_secret_access_key
       backup:
         # This is the connection string for Gitaly server side backups.
         goCloudUrl: <object store connection URL>
   ```

   オブジェクトストレージバックエンドに必要な環境変数とストレージURL形式については、[Gitalyドキュメント](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)を参照してください。

1. [`backup-utility`でサーバー側のバックアップを有効にする](../../../backup-restore/backup.md#server-side-repository-backups)。
