---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインスタンスの復元
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

LinuxパッケージやGitLab Helmチャートなどの他のインストール方法を使用した既存のGitLabインスタンスのバックアップtarballを取得するには、[ドキュメントに記載されている](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)手順に従ってください。

別のインスタンスから取得したバックアップを復元する場合は、バックアップを作成する前に、既存のインスタンスをオブジェクトストレージを使用するように移行する必要があります。[issue 646](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/646)を参照してください。

復元は、作成元のGitLabのバージョンと同じバージョンに復元することをお勧めします。

GitLabのバックアップ復元は、チャートで提供されるToolboxポッドで`backup-utility`コマンドを実行することで行われます。

初めて復元を実行する前に、[Toolboxが適切に設定されていること](_index.md)を、[オブジェクトストレージ](_index.md#object-storage)にアクセスするために確認する必要があります。

GitLab Helmチャートによって提供されるバックアップユーティリティは、次のいずれかの場所からtarballを復元することをサポートしています。

1. インスタンスに関連付けられたオブジェクトストレージサービスの`gitlab-backups`バケット。これはデフォルトのシナリオです。
1. ポッドからアクセスできるパブリックURL。
1. `kubectl cp`を使用してToolboxポッドにコピーできるローカルファイル

## シークレットの復元 {#restoring-the-secrets}

### Railsシークレットの復元 {#restore-the-rails-secrets}

{{<alert type="note">}}

[GitLab Environment Toolkit（GET）](https://docs.gitlab.com/install/install_methods/#gitlab-environment-toolkit-get)を使用してデプロイされたハイブリッド環境は、OmnibusノードとKubernetes間のシークレットの自動同期を実行します。復元を実行する際には、これを考慮する必要があります。詳細については、GETドキュメントの[こちらのセクション](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_post_considerations.md#restores)を参照してください。

{{</alert>}}

GitLabチャートは、RailsシークレットがYAMLのコンテンツを含むKubernetesシークレットとして提供されることを想定しています。LinuxパッケージインスタンスからRailsシークレットを復元している場合、シークレットは`/etc/gitlab/gitlab-secrets.json`ファイルにJSON形式で保存されます。ファイルを変換し、シークレットをYAML形式で作成するには、次の手順に従います:

1. `/etc/gitlab/gitlab-secrets.json`ファイルを、`kubectl`コマンドを実行するワークステーションにコピーします。

1. ワークステーションに[yq](https://github.com/mikefarah/yq)ツール（バージョン4.21.1以降）をインストールします。

1. 次のコマンドを実行して、`gitlab-secrets.json`をYAML形式に変換します:

   ```shell
   yq -P '{"production": .gitlab_rails}' gitlab-secrets.json -o yaml >> gitlab-secrets.yaml
   ```

1. 新しい`gitlab-secrets.yaml`ファイルに次のコンテンツが含まれていることを確認します:

   ```YAML
   production:
     db_key_base: <your key base value>
     secret_key_base: <your secret key base value>
     otp_key_base: <your otp key base value>
     openid_connect_signing_key: <your openid signing key>
     active_record_encryption_primary_key:
     - 'your active record encryption primary key'
     active_record_encryption_deterministic_key:
     - 'your active record encryption deterministic key'
     active_record_encryption_key_derivation_salt: 'your active record key derivation salt'
   ```

1. `openid_connect_signing_key`のような複数行のシークレットに改行文字（`\n`）が含まれていないことを確認してください。アプリケーションで使用される際に[デコードの問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3352#note_994430571)を回避するために、複数行のシークレットを複数の行に分割します。

YAMLファイルからRailsシークレットを復元するには、次の手順に従います:

1. Railsシークレットのオブジェクト名を見つけます:

   ```shell
   kubectl get secrets | grep rails-secret
   ```

1. 既存のシークレットを削除します:

   ```shell
   kubectl delete secret <rails-secret-name>
   ```

1. 古いシークレットと同じ名前を使用して新しいシークレットを作成し、ローカルYAMLファイルを渡します。

   ```shell
   kubectl create secret generic <rails-secret-name> --from-file=secrets.yml=gitlab-secrets.yaml
   ```

### ポッドをリセットする {#restart-the-pods}

新しいシークレットを使用するには、Webservice、Sidekiq、およびToolboxポッドをリセットする必要があります。これらのポッドをリセットする最も安全な方法は、次を実行することです:

```shell
kubectl delete pods -lapp=sidekiq,release=<helm release name>
kubectl delete pods -lapp=webservice,release=<helm release name>
kubectl delete pods -lapp=toolbox,release=<helm release name>
```

## バックアップファイルの復元 {#restoring-the-backup-file}

GitLabインスタンスを復元する手順は次のとおりです

1. チャートをデプロイして、実行中のGitLabインスタンスがあることを確認します。次のコマンドを実行して、Toolboxポッドが有効になっていることを確認します。

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. 上記のいずれかの場所でtarballを準備します。`<backup_ID>_gitlab_backup.tar`形式で名前が付けられていることを確認してください。[バックアップID](https://docs.gitlab.com/administration/backup_restore/backup_archive_process/#backup-id)の詳細をお読みください。

1. 後続のリセットのために、データベースクライアントの現在のレプリカ数に注意してください:

   ```shell
   kubectl get deploy -n <namespace> -lapp=sidekiq,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   kubectl get deploy -n <namespace> -lapp=webservice,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   kubectl get deploy -n <namespace> -lapp=prometheus,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   ```

1. 復元プロセスを妨げるロックを防ぐために、データベースのクライアントを停止します:

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=0
   kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=0
   kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=0
   ```

1. バックアップユーティリティを実行してtarballを復元します

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t <backup_ID>
   ```

   ここで、`<backup_ID>`は、`gitlab-backups`バケットに格納されているtarballの名前から取得されます。パブリックURLを提供する場合は、次のコマンドを使用します:

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -f <URL>
   ```

    形式が`file:///<path>`である限り、ローカルパスをURLとして指定できます。

1. このプロセスは、tarballのサイズに応じて時間がかかります。
1. 復元プロセスは、データベースの既存のコンテンツを消去し、既存のリポジトリを一時的な場所に移動し、tarballのコンテンツを抽出します。リポジトリは、ディスク上の対応する場所に移動され、アーティファクト、アップロード、LFSなどのその他のデータは、オブジェクトストレージ内の対応するバケットにアップロードされます。

1. アプリケーションをリセットします:

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<value>
   kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<value>
   kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<value>
   ```

{{< alert type="note" >}}

復元中、バックアップtarballをディスクに抽出する必要があります。これは、Toolboxポッドに必要なサイズのディスクが利用可能であることを意味します。詳細と設定については、[Toolboxドキュメント](../charts/gitlab/toolbox/_index.md#persistence-configuration)をご覧ください。

{{< /alert >}}

### Runnerの登録トークンを復元する {#restore-the-runner-registration-token}

復元後、含まれているRunnerは、正しい登録トークンを持たなくなったため、インスタンスに登録できなくなります。リセットされた[トラブルシューティングの手順](../troubleshooting/_index.md#included-gitlab-runner-failing-to-register)に従って、更新してください。

## Kubernetes関連の設定を有効にする {#enable-kubernetes-related-settings}

復元されたバックアップがチャートの既存のインストールからのものではない場合は、復元後にいくつかのKubernetes固有の機能を有効にする必要もあります。[増分CIジョブログ](https://docs.gitlab.com/administration/cicd/job_logs/#incremental-logging-architecture)など。

1. 次のコマンドを実行して、Toolboxポッドを見つけます

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. インスタンスのセットアップスクリプトを実行して、必要な機能を有効にします

   ```shell
   kubectl exec <Toolbox pod name> -it -- gitlab-rails runner -e production /scripts/custom-instance-setup
   ```

## ポッドをリセットする {#restart-the-pods-1}

新しい変更を使用するには、WebserviceとSidekiqポッドをリセットする必要があります。これらのポッドをリセットする最も安全な方法は、次を実行することです:

```shell
kubectl delete pods -lapp=sidekiq,release=<helm release name>
kubectl delete pods -lapp=webservice,release=<helm release name>
```

## （オプション）ルートユーザーのパスワードをリセットする {#optional-reset-the-root-users-password}

復元プロセスでは、バックアップの値で`gitlab-initial-root-password`シークレットが更新されません。`root`としてログインするには、バックアップに含まれている元のパスワードを使用します。パスワードにアクセスできなくなった場合は、次の手順に従ってリセットしてください。

1. コマンドを実行して、Webserviceポッドにアタッチします

   ```shell
   kubectl exec <Webservice pod name> -it -- bash
   ```

1. 次のコマンドを実行して、`root`ユーザーのパスワードをリセットします。`#{password}`をご希望のパスワードに置き換えてください

   ```shell
   /srv/gitlab/bin/rails runner "user = User.first; user.password='#{password}'; user.password_confirmation='#{password}'; user.save!"
   ```

## 追加情報 {#additional-information}

- [GitLabチャートバックアップ/復元の概要](_index.md)
- [GitLabインスタンスのバックアップ](backup.md)
