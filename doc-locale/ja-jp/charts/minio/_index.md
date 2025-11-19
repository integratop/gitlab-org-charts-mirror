---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オブジェクトストレージにMinIOを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このチャートは、[`stable/minio`](https://github.com/helm/charts/tree/master/stable/minio)バージョン[`0.4.3`](https://github.com/helm/charts/tree/aaaf98b5d25c26cc2d483925f7256f2ce06be080/stable/minio)に基づいており、ほとんどの設定をそこから継承します。

## 設計の選択 {#design-choices}

[アップストリームチャート](https://github.com/helm/charts/tree/master/stable/minio)に関連する設計上の選択については、プロジェクトのReadmeに記載されています。

GitLabは、シークレットの設定を簡素化し、環境変数でのシークレットの使用をすべて削除するために、そのチャートを変更することを選択しました。GitLabは、`config.json`にシークレットを入力する処理を制御するために`initContainer`を追加し、チャート全体の`enabled`フラグを追加しました。

このチャートは、1つのシークレットのみを使用します:

- `global.minio.credentials.secret`: バケットへの認証に使用される`accesskey`値と`secretkey`値を含むグローバルシークレット。

## 設定 {#configuration}

以下に、設定の主要なセクションをすべて説明します。親チャートから設定する場合、これらの値は次のようになります:

```yaml
minio:
  init:
  ingress:
    enabled:
    apiVersion:
    tls:
      enabled:
      secretName:
    annotations:
    configureCertmanager:
    proxyReadTimeout:
    proxyBodySize:
    proxyBuffering:
  tolerations:
  persistence:  # Upstream
    volumeName:
    matchLabels:
    matchExpressions:
    annotations:
  serviceType:  # Upstream
  servicePort:  # Upstream
  defaultBuckets:
  minioConfig:  # Upstream
```

### コマンドラインオプションのインストール {#installation-command-line-options}

次の表に、`--set`フラグを使用して`helm install`コマンドに指定できるすべての可能なチャート設定が含まれています:

| パラメータ                                                | デフォルト                        | 説明 |
|----------------------------------------------------------|--------------------------------|-------------|
| `common.labels`                                          | `{}`                           | このチャートによって作成されたすべてのオブジェクトに適用される補足的なラベル。 |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                        | InitContainerに固有: プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                         | InitContainerに固有: コンテナを非ルートユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                    | InitContainerに固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `defaultBuckets`                                         | `[{"name": "registry"}]`       | MinIOデフォルトバケット |
| `deployment.strategy`                                    | ``{ `type`: `Recreate` }``     | デプロイで使用される更新戦略を設定できます |
| `image`                                                  | `minio/minio`                  | MinIOイメージ |
| `imagePullPolicy`                                        | `Always`                       | MinIOイメージプルポリシー |
| `imageTag`                                               | `RELEASE.2017-12-28T01-21-00Z` | MinIOイメージタグ付け |
| `minioConfig.browser`                                    | `on`                           | MinIOブラウザフラグ |
| `minioConfig.domain`                                     |                                | MinIOドメイン |
| `minioConfig.region`                                     | `us-east-1`                    | MinIOリージョン |
| `minioMc.image`                                          | `minio/mc`                     | MinIO mcイメージ |
| `minioMc.tag`                                            | `latest`                       | MinIO mcイメージタグ付け |
| `mountPath`                                              | `/export`                      | MinIO設定ファイルのマウントパス |
| `persistence.accessMode`                                 | `ReadWriteOnce`                | MinIO永続的アクセスモード |
| `persistence.annotations`                                |                                | MinIO PersistentVolumeClaim注釈 |
| `persistence.enabled`                                    | `true`                         | MinIO永続の有効化フラグ |
| `persistence.matchExpressions`                           |                                | バインドするMinIOラベル式一致 |
| `persistence.matchLabels`                                |                                | バインドするMinIOラベル値一致 |
| `persistence.size`                                       | `10Gi`                         | MinIO永続ボリュームサイズ |
| `persistence.storageClass`                               |                                | プロビジョニング用のMinIO storageClassName |
| `persistence.subPath`                                    |                                | MinIO永続ボリュームのマウントパス |
| `persistence.volumeName`                                 |                                | MinIO既存の永続ボリューム名 |
| `priorityClassName`                                      |                                | ポッドに割り当てられる[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `pullSecrets`                                            |                                | イメージリポジトリのシークレット |
| `resources.requests.cpu`                                 | `250m`                         | MinIO最小CPUリクエスト |
| `resources.requests.memory`                              | `256Mi`                        | MinIO最小メモリリクエスト |
| `securityContext.fsGroup`                                | `1000`                         | ポッドの開始に使用するグループID |
| `securityContext.runAsUser`                              | `1000`                         | ポッドの開始に使用するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                | ボリュームの所有権と許可を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`               | 使用するSeccompプロファイル |
| `containerSecurityContext.runAsUser`                     | `1000`                         | コンテナが起動される特定のセキュリティコンテキストの上書きを許可します |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                        | Gitalyコンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                         | コンテナを非ルートユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                    | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.automountServiceAccountToken`            | `false`                        | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `servicePort`                                            | `9000`                         | MinIOサービスポート |
| `serviceType`                                            | `ClusterIP`                    | MinIOサービスタイプ |
| `tolerations`                                            | `[]`                           | ポッドの割り当てに使用するTolerationラベル |
| `jobAnnotations`                                         | `{}`                           | ジョブ仕様の注釈 |

## チャート設定の例 {#chart-configuration-examples}

### `pullSecrets` {#pullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに対して認証を行い、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法の詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)を参照してください。

`pullSecrets`の使用例を以下に示します:

```yaml
image: my.minio.repository
imageTag: latest
imagePullPolicy: Always
pullSecrets:
- name: my-secret-name
- name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

このセクションでは、ポッドにデフォルトのServiceAccountアクセストークンをマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |

### `tolerations` {#tolerations}

`tolerations`を使用すると、taintedワーカーノードでポッドをスケジュールできます

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

## サブチャートを有効にする {#enable-the-sub-chart}

デプロイで不要なコンポーネントを無効にする機能は、区分化されたサブチャートを実装するために選択した方法に含まれています。このため、最初に決定する必要がある設定は`enabled:`です。

デフォルトでは、MinIOはすぐに使用できますが、本番環境での使用は推奨されません。無効にする準備ができたら、`--set global.minio.enabled: false`を実行します。

## `initContainer`initContainerを設定します。 {#configure-the-initcontainer}

めったに変更されませんが、`initContainer`の動作は次の項目で変更できます:

```yaml
init:
  image:
    repository:
    tag:
    pullPolicy: IfNotPresent
  script:
```

### InitContainerイメージ {#initcontainer-image}

InitContainerイメージ設定は、通常のイメージ設定とまったく同じです。デフォルトでは、チャートローカル値は空のままになり、グローバル設定`global.gitlabBase.image.repository`と現在の`global.gitlabVersion`に関連付けられているイメージタグ付けが、InitContainerイメージの入力に使用されます。グローバル設定は、チャートローカル値（`minio.init.image.tag`など）でオーバーライドできます。

### InitContainerスクリプト {#initcontainer-script}

InitContainerには、次の項目が渡されます:

- `/config`にマウントされた認証アイテム（通常は`accesskey`と`secretkey`）を含むシークレット。
- `config.json`テンプレートを含むConfigMap、および`/config`にマウントされた`sh`で実行されるスクリプトを含む`configure`。
- デーモンのコンテナに渡される`/minio`にマウントされた`emptyDir`。

InitContainerは、`/config/configure`スクリプトを使用して、完了した設定で`/minio/config.json`を入力することが想定されています。`minio-config`コンテナがそのタスクを完了すると、`/minio`ディレクトリが`minio`コンテナに渡され、[MinIO](https://min.io)サーバーに`config.json`を提供するために使用されます。

## Ingressの設定 {#configuring-the-ingress}

これらの設定は、MinIO Ingressを制御します。

| 名前                   |  型   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | 文字列  |         | `apiVersion`フィールドで使用する値。 |
| `annotations`          | 文字列  |         | このフィールドは、[Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)の標準`annotations`と完全に一致します。 |
| `enabled`              | ブール値 | `false` | サービスがサポートするIngressオブジェクトを作成するかどうかを制御する設定。`false`の場合、`global.ingress.enabled`設定が使用されます。 |
| `configureCertmanager` | ブール値 |         | Ingress注釈`cert-manager.io/issuer`と`acme.cert-manager.io/http01-edit-in-place`を切り替えます。詳細については、[GitLab PagesのTLS要件](../../installation/tls.md)を参照してください。 |
| `tls.enabled`          | ブール値 | `true`  | `false`に設定すると、MinIOのTLSが無効になります。これは、IngressレベルでTLS終端を使用できない場合に特に役立ちます。たとえば、Ingressコントローラーの前にTLS終端プロキシがある場合などです。 |
| `tls.secretName`       | 文字列  |         | MinIO URLの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定されていない場合、代わりに`global.ingress.tls.secretName`が使用されます。 |

## イメージの設定 {#configuring-the-image}

`image`、`imageTag`、および`imagePullPolicy`のデフォルトは、[アップストリーム](https://github.com/helm/charts/tree/master/stable/minio#configuration)にドキュメント化されています。

## 永続 {#persistence}

このチャートは、`PersistentVolumeClaim`をプロビジョニングし、対応する永続ボリュームをデフォルトの場所`/export`にマウントします。これが機能するには、Kubernetesクラスタリングで利用可能な物理ストレージが必要です。`emptyDir`を使用する場合は、`persistence.enabled: false`で`PersistentVolumeClaim`を無効にします。

[アップストリーム](https://github.com/helm/charts/tree/master/stable/minio#configuration)で[`persistence`](https://github.com/helm/charts/tree/master/stable/minio#persistence)の動作がドキュメント化されています。

GitLabはいくつかの項目を追加しました:

```yaml
persistence:
  volumeName:
  matchLabels:
  matchExpressions:
```

| 名前               |  型  | デフォルト | 説明 |
|:-------------------|:------:|:--------|:------------|
| `volumeName`       | 文字列 | `false` | `volumeName`が指定されている場合、`PersistentVolumeClaim`は、動的に`PersistentVolume`を作成する代わりに、指定された名前で`PersistentVolume`を使用します。これにより、アップストリームの動作がオーバーライドされます。 |
| `matchLabels`      |  マップ   | `true`  | ボリュームのバインドを選択するときに、照合するラベル名とラベル値のマップを受け入れます。これは、`PersistentVolumeClaim` `selector`セクションで使用されます。[ボリュームドキュメント](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)を参照してください。 |
| `matchExpressions` | 配列  |         | ボリュームのバインドを選択するときに、照合するラベル条件オブジェクトの配列を受け入れます。これは、`PersistentVolumeClaim` `selector`セクションで使用されます。[ボリュームドキュメント](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)を参照してください。 |

## `defaultBuckets` {#defaultbuckets}

`defaultBuckets`は、*インストール*時にMinIOポッドにバケットを自動的に作成するメカニズムを提供します。このプロパティには、`name`、`policy`、および`purge`の3つまでのプロパティを持つ項目の配列が含まれています。

```yaml
defaultBuckets:
  - name: public
    policy: public
    purge: true
  - name: private
  - name: public-read
    policy: download
```

| 名前     |  型   | デフォルト | 説明 |
|:---------|:-------:|:--------|:------------|
| `name`   | 文字列  |         | 作成されるバケットの名前。指定された値は、[AWSバケットの命名規則](https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html)に準拠している必要があります。つまり、DNSに準拠し、長さが3〜63文字の文字列でaz、0〜9、-（ハイフン）の文字のみを含める必要があります。すべてのエントリに`name`プロパティは_必須_です。 |
| `policy` |         | `none`  | `policy`の値は、MinIOのバケットのアクセスポリシーを制御します。`policy`プロパティは必須ではなく、デフォルト値は`none`です。**anonymous**（匿名）アクセスに関して、可能な値は、`none`（匿名アクセスなし）、`download`（匿名読み取り専用アクセス）、`upload`（匿名の書き込み専用アクセス）または`public`（匿名の読み取り/書き込みアクセス）です。 |
| `purge`  | ブール値 |         | `purge`プロパティは、インストール時に、既存のバケットを強制的に削除する手段として提供されます。これは、[永続](#persistence)のvolumeNameプロパティに既存の`PersistentVolume`を使用する場合にのみ有効になります。動的に作成された`PersistentVolume`を使用する場合、これはチャートのインストール時にのみ発生し、作成されたばかりの`PersistentVolume`にデータがないため、貴重な効果はありません。このプロパティは必須ではありませんが、`mc rm -r --force`でバケットを強制的にパージするために、`true`の値を指定できます。 |

## セキュリティコンテキスト {#security-context}

これらのオプションを使用すると、ポッドの起動に使用される`user`や`group`を制御できます。

セキュリティコンテキストの詳細については、公式[Kubernetesドキュメント](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)を参照してください。

## サービスの種類とポート {#service-type-and-port}

これらは[アップストリーム](https://github.com/helm/charts/tree/master/stable/minio#configuration)でドキュメント化されており、主要な概要は次のとおりです:

```yaml
## Expose the MinIO service to be accessed from outside the cluster (LoadBalancer service).
## or access it from within the cluster (ClusterIP service). Set the service type and the port to serve it.
## ref: http://kubernetes.io/docs/user-guide/services/
##
serviceType: LoadBalancer
servicePort: 9000
```

チャートは`type: NodePort`であるとは想定されていないため、そのように設定**しないでください**。

## アップストリーム項目 {#upstream-items}

次の[アップストリームドキュメント](https://github.com/helm/charts/tree/master/stable/minio)も、このチャートに完全に適用されます:

- `resources`
- `nodeSelector`
- `minioConfig`

`minioConfig`設定の詳細な説明については、[MinIO notifyドキュメント](https://min.io/docs/minio/kubernetes/upstream/index.html)を参照してください。これには、バケットオブジェクトにアクセスまたは変更されたときに通知を公開する方法の詳細が含まれます。
