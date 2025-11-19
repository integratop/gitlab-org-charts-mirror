---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: IAMロールとGitLabチャートを使用したAWSの設定
---

このチャートの外部オブジェクトストレージのデフォルト構成では、アクセストークンとシークレットキーを使用します。IAMロールを[`kube2iam`](https://github.com/jtblin/kube2iam) 、[`kiam`](https://github.com/uswitch/kiam) 、または[IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)と組み合わせて使用​​することもできます。

## IAMロール {#iam-role}

IAMロールには、S3バケットに対する読み取り、書き込み、およびリスト権限が必要です。バケットごとにロールを設定するか、それらを組み合わせることができます。

## チャートの設定 {#chart-configuration}

IAMロールは、以下に示すように、注釈を追加し、シークレットを変更することで指定できます:

### レジストリ {#registry}

IAMロールは、注釈キーを介して指定できます:

```plaintext
--set registry.annotations."iam\.amazonaws\.com/role"=<role name>
```

[`registry-storage.yaml`](../../charts/registry/_index.md#storage)シークレットを作成するときは、アクセストークンとシークレットキーを省略してください:

```yaml
s3:
  bucket: gitlab-registry
  v4auth: true
  region: us-east-1
```

*注*: キーペアを指定すると、IAMロールは無視されます。詳細については、[AWSのドキュメント](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html#credentials-default)を参照してください。

### LFS、アーティファクト、アップロード、パッケージ {#lfs-artifacts-uploads-packages}

LFS、アーティファクト、アップロード、およびパッケージの場合、IAMロールは、`webservice`および`sidekiq`構成の注釈キーを介して指定できます:

```shell
--set gitlab.sidekiq.annotations."iam\.amazonaws\.com/role"=<role name>
--set gitlab.webservice.annotations."iam\.amazonaws\.com/role"=<role name>
```

[`object-storage.yaml`](../../charts/globals.md#connection)シークレットの場合は、アクセストークンとシークレットキーを省略します。GitLab RailsのコードベースはS3ストレージにFogを使用するため、[`use_iam_profile`](https://docs.gitlab.com/administration/cicd/secure_files/#s3-compatible-connection-settings)キーを追加して、Fogがロールを使用できるようにする必要があります:

```yaml
provider: AWS
use_iam_profile: true
region: us-east-1
```

{{< alert type="note" >}}

この設定に`endpoint`を含めないでください。IRSAは、特殊なエンドポイントを使用する[STSトークン](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)を利用します。`endpoint`を指定すると、AWSクライアントは[このエンドポイントに`AssumeRoleWithWebIdentity`メッセージを送信しようとして失敗します](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3148#note_889357676)。

{{< /alert >}}

### バックアップ {#backups}

Toolbox構成では、バックアップをS3にアップロードするように注釈を設定できます:

```shell
--set gitlab.toolbox.annotations."iam\.amazonaws\.com/role"=<role name>
```

[`s3cmd.config`](_index.md#backups-storage-example)シークレットは、アクセストークンとシークレットキーなしで作成されます:

```ini
[default]
bucket_location = us-east-1
```

### サービスアカウントへのIAMロールの使用 {#using-iam-roles-for-service-accounts}

GitLabがAWS EKSクラスタリング（バージョン1.14以降）で実行されている場合、アクセストークンを生成または保存しなくても、AWS IAMロールを使用してS3オブジェクトストレージに認証できます。EKSクラスタリングでのIAMロールの使用に関する詳細は、AWSの[サービスアカウントへのきめ細かいIAMロールの導入](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)ドキュメントに記載されています。

ロールに対する適切なIRSA注釈は、次の2つの方法のいずれかで、このHelm Chart全体のサービスアカウントに適用できます:

1. 上記のAWSドキュメントで説明されているように、事前に作成されたサービスアカウント。これにより、サービスアカウントとリンクされたOIDCプロバイダーに対する適切な注釈が保証されます。
1. 注釈が定義されたチャート生成サービスアカウント。サービスアカウントの注釈の設定は、グローバルベースとチャートごとのベースの両方で許可されています。

EKSクラスタリングのサービスアカウントにIAMロールを使用するには、特定の注釈が`eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME>`である必要があります。

AWS EKSクラスタリングで実行されているGitLabのサービスアカウントに対してIAMロールを有効にするには、[サービスアカウントのIAMロール](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)の手順に従ってください。

#### 事前に作成されたサービスアカウントの使用 {#using-pre-created-service-accounts}

GitLabチャートのデプロイ時に、次のオプションを設定します。サービスアカウントは有効になっていますが、作成されていないことに注意してください。

```yaml
global:
  serviceAccount:
    enabled: true
    create: false
    name: <SERVICE ACCT NAME>
```

きめ細かいサービスアカウント制御も利用できます:

```yaml
registry:
  serviceAccount:
    create: false
    name: gitlab-registry
gitlab:
  migrations:
    serviceAccount:
      create: false
      name: gitlab-migrations
  webservice:
    serviceAccount:
      create: false
      name: gitlab-webservice
  sidekiq:
    serviceAccount:
      create: false
      name: gitlab-sidekiq
  toolbox:
    serviceAccount:
      create: false
      name: gitlab-toolbox
```

IAMロールの信頼ポリシーが[これらのKubernetesサービスアカウントを信頼する](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)ように構成されていることを確認してください。

#### チャートが所有するサービスアカウントの使用 {#using-chart-owned-service-accounts}

GitLabが所有するチャートによって作成された_すべて_のサービスアカウントに`eks.amazonaws.com/role-arn`注釈を適用するには、`global.serviceAccount.annotations`を構成します。

```yaml
global:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/name
```

注釈はサービスアカウントごとに追加することもできますが、チャートごとに一致する定義を追加します。これらは同じロールまたは個々のロールにすることができます。

```yaml
registry:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab-registry
gitlab:
  migrations:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  webservice:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  sidekiq:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  toolbox:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab-toolbox
```

## トラブルシューティング {#troubleshooting}

IAMロールが正しく設定され、GitLabがIAMロールを使用してS3にアクセスしているかどうかをテストするには、`toolbox`ポッドにログインして`awscli`を使用します（`<namespace>`をGitLabがインストールされているネームスペースに置き換えます）:

```shell
kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
```

`awscli`パッケージがインストールされた状態で、AWS APIと通信できることを確認します:

```shell
aws sts get-caller-identity
```

AWS APIへの接続が成功した場合、一時ユーザーID、アカウント番号、およびIAM Amazonリソースネーム（これは、S3へのアクセスに使用されるロールのIAM Amazonリソースネームではありません）を示す通常の応答が返されます。接続が失敗した場合、`toolbox`ポッドがAWS APIと通信できない理由を特定するために、さらにトラブルシューティングが必要になります。

AWS APIへの接続が成功した場合、次のコマンドは、作成されたIAMロールを想定し、S3へのアクセスのためにSTSトークンが取得できることを確認します。IAMロールの注釈がポッドに追加されると、`AWS_ROLE_ARN`および`AWS_WEB_IDENTITY_TOKEN_FILE`変数が環境で定義され、定義する必要はありません:

```shell
aws sts assume-role-with-web-identity --role-arn $AWS_ROLE_ARN  --role-session-name gitlab --web-identity-token file://$AWS_WEB_IDENTITY_TOKEN_FILE
```

IAMロールを想定できない場合は、次のようなエラーメッセージが表示されます:

```plaintext
An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

それ以外の場合は、STS認証情報とIAMロール情報が表示されます。

## `WebIdentityErr: failed to retrieve credentials` {#webidentityerr-failed-to-retrieve-credentials}

ログにこのエラーが表示された場合、`endpoint`が[`object-storage.yaml`](../../charts/globals.md#connection)シークレットで設定されていることを示唆しています。この設定を削除し、`webservice`と`sidekiq`ポッドを再起動します。
