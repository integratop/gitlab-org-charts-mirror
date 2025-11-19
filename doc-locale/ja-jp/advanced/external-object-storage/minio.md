---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートでMinIOを設定
---

[MinIO](https://min.io/)は、S3互換APIを公開するオブジェクトストレージサーバーです。

MinIOは、いくつかの異なるプラットフォームにデプロイできます。新しいMinIOインスタンスを起動するには、[Quickstart Guide](https://min.io/docs/minio/linux/index.html)に従ってください。[TLSでMinIOサーバーへのアクセスを保護](https://min.io/docs/minio/linux/operations/network-encryption.html)してください。

GitLabを外部の[MinIO](https://min.io/)インスタンスに接続するには、まず、この[設定ファイル](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/values-external-objectstorage.yaml)のバケット名を使用して、GitLabアプリケーション用のMinIOバケットを作成します。

[MinIO client](https://min.io/docs/minio/kubernetes/upstream/)を使用して、使用前に必要なバケットを作成します:

```shell
mc mb gitlab-registry-storage
mc mb gitlab-lfs-storage
mc mb gitlab-artifacts-storage
mc mb gitlab-uploads-storage
mc mb gitlab-packages-storage
mc mb gitlab-backup-storage
```

バケットが作成されると、GitLabはMinIOインスタンスを使用するように設定できます。[examples](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)フォルダーの[`rails.minio.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.minio.yaml)および[`registry.minio.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.minio.yaml)の設定例を参照してください。
