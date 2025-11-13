---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Helmチャートインスタンスのアップグレード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Helmチャートインスタンスを、以降のバージョンのGitLabにアップグレードします。

{{< alert type="note" >}}

**ロダウンタイムアップグレード**は、[GitLab Operator](https://docs.gitlab.com/operator/gitlab_upgrades/)を使用することで、クラウドネイティブのGitLabインスタンスでのみ利用可能です。

{{< /alert >}}

## 前提要件 {#prerequisites}

GitLab Helmチャートインスタンスをアップグレードする前に:

1. [アップグレード前に必要な情報](https://docs.gitlab.com/update/plan_your_upgrade/)を確認してください。
1. GitLab Helmチャートのバージョンは、GitLabのバージョンと同じ番号付けに従っていないため、必要なGitLab Helmチャートのバージョンを見つけるには、[マッピング](version_mappings.md)を参照してください。
1. アップグレード先の特定リリースに対応する[変更履歴](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/CHANGELOG.md)を参照してください。
1. 8.x以前のバージョンのGitLab Helmチャートからアップグレードする場合は、[GitLabドキュメントアーカイブ](https://docs.gitlab.com/archives/)を参照して、ドキュメントの古いバージョンにアクセスしてください。
1. [バックアップ](../backup-restore/_index.md)を実行します。

## GitLab Helmチャートインスタンスのアップグレード {#upgrade-a-gitlab-helm-chart-instance}

GitLab Helmチャートインスタンスをアップグレードするには:

1. ワークフローを中断しないように、アップグレード中に[メンテナンスモードをオンにすること](https://docs.gitlab.com/administration/maintenance_mode/)を検討し、ユーザーによる書き込み操作を制限します。
1. ターゲットのGitLabバージョンと同じバージョンに[GitLab Runner](https://docs.gitlab.com/runner/install/)をアップグレードしてください。
1. [デプロイドキュメント](deployment.md)にステップごとに従ってください。
1. 以前に提供された値を抽出します:

   ```shell
   helm get values gitlab > gitlab.yaml
   ```

1. アップグレード時に引き継ぐ必要のあるすべての値を決定します。明示的に設定する最小限の値のセットのみを保持し、アップグレードプロセス中にそれらを渡す必要があります。そうでない場合は、GitLabのデフォルト値に依存する必要があります。
1. 以前のステップで抽出およびレビューした値を使用して、アップグレードを実行します:

   ```shell
   helm upgrade gitlab gitlab/gitlab \
     --version <new version> \
     -f gitlab.yaml \
     --set gitlab.migrations.enabled=true \
     --set ...
   ```

   主要なデータベースのアップグレード中は、`gitlab.migrations.enabled`を`false`に設定する必要があります。将来のアップデートのために、明示的に`true`に戻してください。

アップグレード後:

1. 有効になっている場合は、[メンテナンスモードをオフに](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode)します。
1. [アップグレードヘルスチェック](https://docs.gitlab.com/update/plan_your_upgrade/#run-upgrade-health-checks)を実行します。

## バンドルされているPostgreSQLのアップグレード {#upgrade-the-bundled-postgresql}

`postgresql.install`が`true`の場合、これらの手順はバンドルされているPostgreSQLチャートを使用している場合にのみ実行してください。

バンドルされているPostgreSQLをアップグレードするには:

1. アップグレード先の[PostgreSQLのバージョン](https://docs.gitlab.com/install/requirements/#postgresql)を決定します。
1. [既存のデータベースを準備](database_upgrade.md#prepare-the-existing-database)します。
1. [既存のPostgreSQLデータを削除](database_upgrade.md#delete-existing-postgresql-data)します。
1. `postgresql.image.tag`の値を必要なバージョンのPostgreSQLに更新し、[チャートを再インストール](database_upgrade.md#upgrade-gitlab)して、新しいPostgreSQLデータベースを作成します。
1. [データベースを復元する](database_upgrade.md#restore-the-database)。
