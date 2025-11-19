---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートを使用する際のAzure MinIOゲートウェイ
---

[MinIO](https://min.io/)は、S3互換APIを公開するオブジェクトストレージサーバーであり、Azure Blob Storageへのリクエストをプロキシできるゲートウェイ機能を備えています。ゲートウェイをセットアップするには、AzureのLinux上のWeb Appを使用します。

まず、Azure CLIがインストールされ、ログインしていることを確認してください（`az login`）。[リソースグループ](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview#resource-groups)を作成してください（まだ作成していない場合）:

```shell
az group create --name "gitlab-azure-minio" --location "WestUS"
```

## ストレージアカウント {#storage-account}

リソースグループにストレージアカウントを作成します。ストレージアカウントの名前はグローバルに一意である必要があります:

```shell
az storage account create \
    --name "gitlab-azure-minio-storage" \
    --kind BlobStorage \
    --sku Standard_LRS \
    --access-tier Cool \
    --resource-group "gitlab-azure-minio" \
    --location "WestUS"
```

ストレージアカウントのアカウントキーを取得する:

```shell
az storage account show-connection-string \
    --name "gitlab-azure-minio-storage" \
    --resource-group "gitlab-azure-minio"
```

出力は次の形式である必要があります:

```json
{
    "connectionString": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=gitlab-azure-minio-storage;AccountKey=h0tSyeTebs+..."
}
```

## Linux上のWeb AppにMinIOをデプロイする {#deploy-minio-to-web-app-on-linux}

まず、同じリソースグループにApp Service Planを作成する必要があります。

```shell
az appservice plan create \
    --name "gitlab-azure-minio-app-plan" \
    --is-linux \
    --sku B1 \
    --resource-group "gitlab-azure-minio" \
    --location "WestUS"
```

[`minio/minio`](https://hub.docker.com/r/minio/minio) Dockerコンテナで構成されたWebアプリを作成します。指定した名前は、WebアプリのURLで使用されます:

```shell
az webapp create \
    --name "gitlab-minio-app" \
    --deployment-container-image-name "minio/minio" \
    --plan "gitlab-azure-minio-app-plan" \
    --resource-group "gitlab-azure-minio"
```

Webアプリは、`https://gitlab-minio-app.azurewebsites.net`でアクセスできるはずです。

最後に、起動コマンドを設定し、Webアプリで使用するストレージアカウント名とキーを格納する環境変数、`MINIO_ACCESS_KEY`と`MINIO_SECRET_KEY`を作成する必要があります。

```shell
az webapp config appsettings set \
    --settings "MINIO_ACCESS_KEY=gitlab-azure-minio-storage" "MINIO_SECRET_KEY=h0tSyeTebs+..." "PORT=9000" \
    --name "gitlab-minio-app" \
    --resource-group "gitlab-azure-minio"

# Startup command
az webapp config set \
    --startup-file "gateway azure" \
    --name "gitlab-minio-app" \
    --resource-group "gitlab-azure-minio"
```

## まとめ {#conclusion}

このゲートウェイは、S3互換性のあるすべてのクライアントで使用できます。WebアプリケーションのURLは`s3 endpoint`になり、ストレージアカウント名は`accesskey`になり、ストレージアカウントキーは`secretkey`になります。

## 参照 {#reference}

<!-- vale gitlab.Spelling = NO -->

このガイドは、[Alessandro Segalaの同じトピックに関するブログ投稿](https://withblue.ink/2017/10/29/how-to-use-s3cmd-and-any-other-amazon-s3-compatible-app-with-azure-blob-storage.html)から後世のために翻案されました。

<!-- vale gitlab.Spelling = YES -->
