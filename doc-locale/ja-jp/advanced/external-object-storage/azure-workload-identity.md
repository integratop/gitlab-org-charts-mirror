---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャート使用時のAzure Workload Identity
---

チャートでの外部オブジェクトストレージのデフォルト設定では、シークレットキーを使用します。[Azure Workload Identity](https://azure.github.io/azure-workload-identity/docs/)を使用すると、有効期間の短いtokenを使用して、Kubernetes clusteringにObject storageへのアクセス権を付与できます。[Azure Kubernetes Service（AKS）クラスターでワークロードIDをデプロイおよび設定する方法に関するMicrosoftのドキュメント](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster)をお読みください。

## 要件 {#requirements}

Object storageでworkload identityを使用するには、以下が必要です:

1. OpenID Connect Issuer（OIDC）Issuerが有効になっているAKS clustering。
1. `Storage Blob Data Contributor`ロールがassignられたAzureマネージドID。
1. 注釈`azure.workload.identity/client-id: <CLIENT ID>`が指定された、マネージドIDに関連付けられたKubernetes service account。

workload identityをアクティブ化するには、各podにラベル`azure.workload.identity/use: "true"`が必要です。これはpodの**ラベル**であり、注釈ではありません。

## チャートの設定 {#chart-configuration}

### レジストリ {#registry}

{{< history >}}

- GitLab 17.9でベータ機能として[導入](https://gitlab.com/gitlab-org/container-registry/-/issues/1431)されました。

{{< /history >}}

レジストリに対するworkload identityサポートはベータ版です。podのラベルを設定することで、workload identityを有効にできます:

```plaintext
--set registry.podLabels."azure\.workload\.identity/use"=true
```

[`registry-storage.yaml`](../../charts/registry/_index.md#storage)シークレットを作成する際は、以下を行う必要があります:

1. `azure_v2` storageの設定を使用します。
1. `credentialstype`を`default_credentials`に設定します。

例: 

```yaml
azure_v2:
  accountname: accountname
  container: containername
  credentialstype: default_credentials
  realm: core.windows.net
```

`azure_v2` storage driverはworkload identityをサポートしていますが、`azure` driverはサポートしていません。現在`azure` driverを使用している場合にworkload identityを使用する場合は、`azure_v2` driverに移行します。詳細については、[`azure_v2`のドキュメント](https://gitlab.com/gitlab-org/container-registry/-/blob/3ebb5bffd3f6cfbf4479b1b8a4079d842a1c8025/docs/storage-drivers/azure_v2.md)を参照してください。

### LFS、artifacts、uploads、パッケージ {#lfs-artifacts-uploads-packages}

LFS、artifacts、uploads、パッケージの場合、IAMロールは、`webservice`、`sidekiq`、および`toolbox`設定のアノテーションキーを介して指定できます:

```shell
--set gitlab.sidekiq.podLabels."azure\.workload\.identity/use"="true"
--set gitlab.webservice.podLabels."azure\.workload\.identity/use"="true"
--set gitlab.toolbox.podLabels."azure\.workload\.identity/use"="true"
```

[`object-storage.yaml`](../../charts/globals.md#connection)シークレットの場合は、`azure_storage_access_key`を省略します:

```yaml
provider: AzureRM
azure_storage_account_name: YOUR_AZURE_STORAGE_ACCOUNT_NAME
azure_storage_domain: blob.core.windows.net
```

### バックアップ {#backups}

Toolbox設定を使用すると、podのラベルを設定できます:

```shell
--set gitlab.toolbox.podLabels."azure\.workload\.identity/use"="true"
```

`gitlab.toolbox.backups.objectStorage.config.secret`シークレットに保存されている[`azure-backup-conf.yaml`](../../backup-restore/_index.md)の場合は、`azure_storage_access_key`を省略します:

```yaml
# azure-backup-conf.yaml
azure_storage_account_name: <storage account>
azure_storage_domain: blob.core.windows.net # optional
```

## トラブルシューティング {#troubleshooting}

Azure workload identityが正しく設定されていること、およびGitLabが`toolbox` podにログインしてAzure Blob Storageにアクセスしていることをテストできます（`<namespace>`をGitLabがあるnamespaceに置き換えます）:

```shell
kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
```

まず、必要なenvironment variableが存在するかどうかを確認します:

- `AZURE_TENANT_ID`
- `AZURE_FEDERATED_TOKEN_FILE`
- `AZURE_CLIENT_ID`

たとえば、次のように表示されます:

```shell
$ env | grep AZURE
AZURE_TENANT_ID=abcdefghi-c2c5-43d6-b426-1d8c9e8e7ad1
AZURE_FEDERATED_TOKEN_FILE=/var/run/secrets/azure/tokens/azure-identity-token
AZURE_AUTHORITY_HOST=https://login.microsoftonline.com/
AZURE_CLIENT_ID=123456789-abcd-12ab-89ca-cb379118f978
```

次に、`azcopy`を使用してblob container内のファイルを一覧表示します:

```shell
export AZCOPY_AUTO_LOGIN_TYPE=workload
azcopy --log-level debug list https://<YOUR STORAGE ACCOUNT NAME>.blob.core.windows.net/<YOUR AZURE BLOB CONTAINER NAME>
```

認証に成功した場合は、blob containerの内容とともに、次のメッセージが表示されます:

```plaintext
INFO: Login with Workload Identity succeeded
INFO: Authenticating to source using Azure AD
```

401または403エラーが表示される場合は、マネージドIDの設定を確認してください。一般的なエラーを以下に示します:

1. Azure storageアカウントとblob containerの名前のスペルを確認します。
1. `kubectl describe pod <pod>`を使用して、podに正しいKubernetes service accountと`azure.workload.identity/use: "true"` podラベルがあることを確認します。
1. マネージドIDの場合は、フェデレーション認証情報の設定に、正しいIssuer URL、namespace、および関連付けられているKubernetes service accountがあることを確認してください。これは、Azureポータルで確認するか、[command-line interface`az`](https://learn.microsoft.com/en-us/cli/azure/identity)を使用して確認できます。
1. マネージドIDにblob storage containerの`Storage Blob Data Contributor`があることを確認します。
