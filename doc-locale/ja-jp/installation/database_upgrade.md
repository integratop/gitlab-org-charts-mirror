---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バンドルされているPostgreSQLバージョンをアップグレードします
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

これらの手順は、バンドルされているPostgreSQLチャート（`postgresql.install`がfalseでない）を使用している場合に該当し、外部PostgreSQLセットアップには該当しません。

{{< /alert >}}

{{< alert type="warning" >}}

バンドルされているbitnami PostgreSQLチャートは、本番環境に対応していません。本番環境に対応したGitLabチャートデプロイでは、外部データベースを使用してください。

{{< /alert >}}

バンドルされているPostgreSQLチャートを使用してPostgreSQLの新しいメジャーバージョンに変更するには、既存のデータベースのバックアップを作成し、新しいデータベースに復元することで行います。

{{< alert type="note" >}}

このチャートの`9.0.0`リリースの一部として、デフォルトのPostgreSQLバージョンを`14.8.0`から`16.6.0`にアップグレードしました。これは、[PostgreSQLチャート](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)のバージョンを`12.5.2`から`13.4.4`にアップグレードすることで行われます。

{{< /alert >}}

これは、ドロップイン代替ではありません。データベースをアップグレードするには、手動による手順を実行する必要があります。手順は、[アップグレードの手順](#steps-for-upgrading-the-bundled-postgresql)に記載されています。

## バンドルされているPostgreSQLをアップグレードする手順 {#steps-for-upgrading-the-bundled-postgresql}

これは、[アップストリーム](https://github.com/bitnami/charts/issues/16707)PostgreSQLチャートのイシューが原因です。PostgreSQLパスワードに環境変数を使用せず、ファイルの使用を希望する場合は、以下の手順を実行する前に、手動による[既存のPostgreSQLパスワードシークレットの編集](#edit-the-existing-postgresql-passwords-secret)、およびPostgreSQLチャートのパスワードファイルを有効化する手順に従う必要があります。

### 既存のデータベースを準備 {#prepare-the-existing-database}

次の点に注意してください:

- バンドルされているPostgreSQLチャート（`postgresql.install`がfalseの場合）を使用していない場合は、これらの手順に従う必要はありません。
- 同じネームスペースに複数のチャートがインストールされている場合。データベースアップグレードスクリプトにHelmリリース名を渡す必要がある場合があります。後で提供されるコマンド例で、`bash -s STAGE`を`bash -s -- -r RELEASE STAGE`に置き換えます。
- `kubectl`コンテキストのデフォルト以外のネームスペースにチャートをインストールした場合は、データベースアップグレードスクリプトにネームスペースを渡す必要があります。後で提供されるコマンド例で、`bash -s STAGE`を`bash -s -- -n NAMESPACE STAGE`に置き換えます。このオプションは、`-r RELEASE`とともに使用できます。`kubectl config set-context --current --namespace=NAMESPACE`を実行するか、kubectxの[`kubens`を使用して、コンテキストのデフォルトネームスペースを設定できます。](https://github.com/ahmetb/kubectx)

`pre`ステージでは、Toolboxのバックアップユーティリティスクリプトを使用してデータベースのバックアップを作成し、構成済みのS3バケット（デフォルトではMinIO）に保存します:

```shell
# GITLAB_RELEASE should be the version of the chart you are installing, starting with 'v': v6.0.0
curl -s "https://gitlab.com/gitlab-org/charts/gitlab/-/raw/${GITLAB_RELEASE}/scripts/database-upgrade" | bash -s pre
```

### 既存のPostgreSQLデータを削除 {#delete-existing-postgresql-data}

{{< alert type="note" >}}

PostgreSQLデータ形式が変更されたため、アップグレードするには、リリースをアップグレードする前に、既存のPostgreSQL StatefulSetを削除する必要があります。StatefulSetは、次の手順で再作成されます。

{{< /alert >}}

{{< alert type="warning" >}}

前の手順でデータベースのバックアップを作成したことを確認してください。バックアップがないと、GitLabデータが失われます。

{{< /alert >}}

```shell
kubectl delete statefulset RELEASE-NAME-postgresql
kubectl delete pvc data-RELEASE_NAME-postgresql-0
```

### GitLabをアップグレードする {#upgrade-gitlab}

次の追加を含めて、[標準的な手順](upgrade.md)に従ってGitLabをアップグレードします:

アップグレードコマンドで次のフラグを使用して、移行を無効にします:

1. `--set gitlab.migrations.enabled=false`

バンドルされているPostgreSQLのデータベースの移行は、後の手順で実行します。

### データベースを復元する {#restore-the-database}

次の点に注意してください:

- bash連想配列の使用が必要なため、スクリプトを正常に実行するには、Bash 4.0以上を使用する必要があります。

1. Toolboxポッドのアップグレードが完了するまで待ちます。RELEASE_NAMEは、`helm list`からのGitLabリリースの名前である必要があります

   ```shell
   kubectl rollout status -w deployment/RELEASE_NAME-toolbox
   ```

1. Toolboxポッドが正常にデプロイされたら、`post`手順を実行します:

   ```shell
   # GITLAB_RELEASE should be the version of the chart you are installing, starting with 'v': v6.0.0
   curl -s "https://gitlab.com/gitlab-org/charts/gitlab/-/raw/${GITLAB_RELEASE}/scripts/database-upgrade" | bash -s post
   ```

   この手順では、次のことを行います:

   1. `webservice`、`sidekiq`、および`gitlab-exporter`デプロイのレプリカを0に設定します。これにより、バックアップの復元中に他のアプリケーションがデータベースを変更できなくなります。
   1. preステージで作成されたバックアップからデータベースを復元する。
   1. 新しいバージョンのデータベース移行を実行します。
   1. 最初の手順からデプロイを再開します。

### データベースのアップグレードプロセスのトラブルシューティング {#troubleshooting-database-upgrade-process}

- アップグレード中にエラーが発生した場合は、`gitlab-upgrade-check`ポッドの説明を確認すると詳細がわかる場合があります:

  ```shell
  kubectl get pods -lrelease=RELEASE,app=gitlab
  kubectl describe pod <gitlab-upgrade-check-pod-full-name>
  ```

## 既存のPostgreSQLパスワードシークレットを編集 {#edit-the-existing-postgresql-passwords-secret}

{{< alert type="note" >}}

これは`7.0.0`のアップグレードのみを対象としており、PostgreSQLサービスコンテナ内でパスワードファイルの使用を強制する場合にのみ該当します。

{{< /alert >}}

新しいバージョンの[PostgreSQLチャート](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)は、異なるキーを使用してシークレット内のパスワードを参照します。`postgresql-password`および`postgresql-postgres-password`の代わりに、`password`および`postgres-password`を使用します。これらのキーは、値を変更せずに、`RELEASE-postgresql-password`シークレットで変更する_必要があります_。

このシークレットは、GitLabチャートによって初めて生成され、アップグレード中またはアップグレード後には変更されません。したがって、シークレットを編集し、キーを変更する必要があります。

シークレットを編集したら、_必ず_**Helmアップグレード値で`postgresql.auth.usePasswordFiles`を`true`に設定する**必要があります。デフォルトは`false`です。

次のスクリプトは、シークレットのパッチに役立ちます:

1. まず、既存のシークレットのバックアップを作成します。次のコマンドは、`-backup`という名前のサフィックスを持つ新しいシークレットにコピーします:

   ```shell
   kubectl get secrets ${RELEASE}-postgresql-password -o yaml | sed 's/name: \(.*\)$/name: \1-backup/' | kubectl apply -f -
   ```

1. パッチが正しく表示されることを確認します:

   ```shell
   kubectl get secret ${RELEASE}-postgresql-password \
     -o go-template='{"data":{"password":"{{index .data "postgresql-password"}}","postgres-password":"{{index .data "postgresql-postgres-password"}}","postgresql-password":null,"postgresql-postgres-password":null}}'
   ```

1. 次に、それを適用します:

   ```shell
   kubectl patch secret ${RELEASE}-postgresql-password --patch "$(
     kubectl get secret ${RELEASE}-postgresql-password \
       -o go-template='{"data":{"password":"{{index .data "postgresql-password"}}","postgres-password":"{{index .data "postgresql-postgres-password"}}","postgresql-password":null,"postgresql-postgres-password":null}}')"
   ```
