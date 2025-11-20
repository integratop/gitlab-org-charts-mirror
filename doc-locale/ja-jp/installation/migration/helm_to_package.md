---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Helm ChartからLinuxパッケージへの移行
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

HelmインストールからLinuxパッケージ（Omnibus）インストールに移行するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. 左側のサイドバーの下部にある**概要 > コンポーネント**を選択して、現在のGitLabのバージョンを確認します。
1. クリーンなマシンを準備し、お使いのGitLab Helmチャートのバージョンに一致する[Linuxパッケージをインストール](https://docs.gitlab.com/update/package/)します。
1. 移行の前に、GitLab Helmチャートインスタンス上の[Gitリポジトリの整合性を確認](https://docs.gitlab.com/administration/raketasks/check/)します。
1. [GitLab Helmチャートインスタンスのバックアップを作成](../../backup-restore/backup.md)し、必ず[シークレットもバックアップしてください](../../backup-restore/backup.md#back-up-the-secrets)。
1. Linuxパッケージインスタンスで`/etc/gitlab/gitlab-secrets.json`をバックアップします。
1. `kubectl`コマンドを実行するワークステーションに、[yq](https://github.com/mikefarah/yq)ツール（バージョン4.21.1以降）をインストールします。
1. ワークステーションで`/etc/gitlab/gitlab-secrets.json`ファイルのコピーを作成します。
1. 次のコマンドを実行して、GitLab Helmチャートインスタンスからシークレットを取得します。`GITLAB_NAMESPACE`と`RELEASE`を適切な値に置き換えてください:

   ```shell
   kubectl get secret -n GITLAB_NAMESPACE RELEASE-rails-secret -ojsonpath='{.data.secrets\.yml}' | yq '@base64d | from_yaml | .production' -o json > rails-secrets.json
   yq eval-all 'select(filename == "gitlab-secrets.json").gitlab_rails = select(filename == "rails-secrets.json") | select(filename == "gitlab-secrets.json")' -ojson  gitlab-secrets.json rails-secrets.json > gitlab-secrets-updated.json
   ```

1. 結果は`gitlab-secrets-updated.json`です。これを使用して、Linuxパッケージインスタンス上の`/etc/gitlab/gitlab-secrets.json`の古いバージョンを置き換えることができます。
1. `/etc/gitlab/gitlab-secrets.json`を置き換えた後、Linuxパッケージインスタンスを再構成します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Linuxパッケージインスタンスで、[オブジェクトストレージ](https://docs.gitlab.com/administration/object_storage/)を構成し、LFS、アーティファクト、アップロードなどをテストして、動作することを確認します。
1. コンテナレジストリを使用する場合は、[オブジェクトストレージを個別に構成](https://docs.gitlab.com/administration/packages/container_registry/#use-object-storage)します。統合されたオブジェクトストレージはサポートされていません。
1. Helmチャートインスタンスに接続されているオブジェクトストレージから、Linuxパッケージインスタンスに接続されている新しいストレージにデータを同期します。いくつかの注意点があります:

   - S3互換ストレージの場合は、`s3cmd`ユーティリティを使用してデータをコピーします。
   - LinuxパッケージインスタンスでMinIOのようなS3互換のオブジェクトストレージを使用する場合は、MinIOを指す`endpoint`オプションを構成し、`/etc/gitlab/gitlab.rb`で`path_style`を`true`に設定する必要があります。
   - 新しいLinuxパッケージインスタンスで古いオブジェクトストレージを再利用できます。この場合、2つのオブジェクトストレージ間でデータを同期する必要はありません。ただし、組み込みのMinIOインスタンスを使用している場合、GitLab Helmチャートをアンインストールすると、ストレージのプロビジョニングが解除される可能性があります。

1. GitLab HelmバックアップをLinuxパッケージGitLabインスタンスの`/var/opt/gitlab/backups`にコピーし、[復元を実行](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)します。
1. （オプション）Git SSHクライアントでホストの不一致エラーが発生しないように、SSHホストキーを復元します:

   1. 次のスクリプトを使用して、[`<name>-gitlab-shell-host-keys`シークレット](../secrets.md#ssh-host-keys)をファイルに戻します（必要なツール: `jq`、`base64`、`kubectl`）:

      ```shell
      mkdir ssh
      HOSTKEYS_JSON="hostkeys.json"
      GITLAB_NAMESPACE="my_namespace"
      kubectl get secret -n ${GITLAB_NAMESPACE} gitlab-gitlab-shell-host-keys -o json > ${HOSTKEYS_JSON}

      for k in $(jq -r '.data | keys | .[]' ${HOSTKEYS_JSON}); \
      do \
        jq -r --arg host_key ${k} '.data[$host_key]' ${HOSTKEYS_JSON}  | base64 --decode > ssh/$k ; \
      done
      ```

   1. 変換されたファイルをGitLab Railsノードにアップロードします。
   1. ターゲットRailsノード上:
      1. `/etc/ssh/`ディレクトリをバックアップします。例:

         ```shell
         sudo tar -czvf /root/ssh_dir.tar.gz -C /etc ssh
         ```

      1. 既存のホストキーを削除します:

         ```shell
         sudo find /etc/ssh -type f -name "/etc/ssh/ssh_*_key*" -delete
         ```

      1. 変換されたホストキーファイルを所定の場所（`/etc/ssh`）に移動します:

         ```shell
         for f in ssh/*; do sudo install -b -D  -o root -g root -m 0600 $f /etc/${f} ; done
         ```

      1. SSHデーモンを再起動します:

         ```shell
         sudo systemctl restart ssh.service
         ```

1. 復元が完了したら、[doctor Rakeタスク](https://docs.gitlab.com/administration/raketasks/check/)を実行して、シークレットが有効であることを確認します。
1. すべてが検証されたら、GitLab Helmチャートインスタンスを[uninstall](../uninstall.md)できます。
