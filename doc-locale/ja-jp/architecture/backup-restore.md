---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バックアップと復元
---

このドキュメントでは、CNGとの間でのバックアップとリストアの技術的な実装について説明します。

## Toolboxポッド {#toolbox-pod}

[toolbox chart](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/gitlab/charts/toolbox)は、ポッドをクラスタリングにデプロイします。このポッドは、クラスタリング内の他のコンテナとのインタラクションのエントリポイントとして機能します。

このポッドを使用すると、ユーザーは`kubectl exec -it <pod name> -- <arbitrary command>`を使用してコマンドを実行できます

Toolboxは、[Toolbox image](https://gitlab.com/gitlab-org/build/CNG/tree/master/gitlab-toolbox)からコンテナを実行します。

このイメージには、ユーザーがコマンドとして呼び出す[custom scripts](https://gitlab.com/gitlab-org/build/CNG/-/tree/master/gitlab-toolbox/scripts/bin)がいくつか含まれています。これらのスクリプトは、Rakeタスク、バックアップ、リストアの実行、およびオブジェクトストレージとのインタラクションのためのいくつかのヘルパースクリプト用です。

## Backupユーティリティ {#backup-utility}

[Backup utility](https://gitlab.com/gitlab-org/build/CNG/-/blob/master/gitlab-toolbox/scripts/bin/backup-utility)は、toolboxコンテナ内のスクリプトの1つであり、名前が示すように、バックアップを実行するために使用されるスクリプトですが、既存のバックアップのリストアも処理します。

### バックアップ {#backups}

引数なしで実行されたBackupユーティリティスクリプトは、バックアップtarを作成し、オブジェクトストレージにアップロードします。

#### 実行順序 {#sequence-of-execution}

バックアップは、次の手順で順番に作成されます:

1. [GitLab backup Rake task](https://gitlab.com/gitlab-org/build/CNG/-/blob/f65867afa54f6d0033e19f9e9038ec680abd5eb2/gitlab-toolbox/scripts/bin/backup-utility#L217)を使用して、（スキップされていない場合）データベースをバックアップします
1. [GitLab backup Rake task](https://gitlab.com/gitlab-org/build/CNG/-/blob/f65867afa54f6d0033e19f9e9038ec680abd5eb2/gitlab-toolbox/scripts/bin/backup-utility#L220)を使用して、（スキップされていない場合）リポジトリをバックアップします
1. オブジェクトストレージバックエンドごとに、
   1. オブジェクトストレージバックエンドがスキップするようにマークされている場合は、このストレージバックエンドをスキップします。
   1. 対応するオブジェクトストレージバケット内の既存のデータをtarでアーカイブし、`<bucket-name>.tar`という名前を付けます
   1. tarをディスク上のバックアップ場所に移動します
1. `backup_information.yml`ファイルを作成します。これには、GitLabのバージョン、バックアップの時刻、スキップされた項目を識別するメタデータが含まれます。
1. 個々のtarファイルを`backup_information.yml`とともに含むtarファイルを作成します
1. 結果のtarファイルをオブジェクトストレージ`gitlab-backups`バケットにアップロードします。

#### コマンドライン引数 {#command-line-arguments}

- `--skip <component>`

  バックアッププロセスでスキップするすべてのコンポーネントに対して`--skip <component>`を使用することにより、バックアッププロセスの一部をスキップできます。スキップ可能なコンポーネントは、[Excluding specific data from the backup](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-data-from-the-backup)にあります。

- `-t <timestamp-override-value>`

  これにより、バックアップの名前を部分的に制御できます。このフラグを指定すると、作成されたバックアップの名前は`<timestamp-override-value>_gitlab_backup.tar`になります。デフォルト値は現在のUNIXタイムスタンプであり、現在の`YYYY_mm_dd`にフォーマットされた日付が後置されます。

- `--backend <backend>`

  バックアップに使用するオブジェクトストレージバックエンドを構成します。`s3`または`gcs`のいずれかになります。デフォルトは`s3`です。

- `--storage-class <storage-class-name>`

  `--storage-class <storage-class-name>`を使用してバックアップが保存されるストレージクラスを指定することもでき、バックアップストレージのコストを節約できます。指定しない場合、ストレージバックエンドのデフォルトが使用されます。

  {{< alert type="note" >}}

このストレージクラス名は、指定したバックエンドのストレージクラス引数にそのまま渡されます。

  {{< /alert >}}

#### GitLabバックアップバケット {#gitlab-backup-bucket}

バックアップの保存に使用されるバケットのデフォルト名は`gitlab-backups`です。これは、`BACKUP_BUCKET_NAME`環境変数を使用して構成可能です。

#### Google Cloud Storageへのバックアップ {#backing-up-to-google-cloud-storage}

デフォルトでは、Backupユーティリティは`s3cmd`を使用して、オブジェクトストレージからアーティファクトをアップロードおよびフェッチします。これはGoogle Cloud Storage（GCS）で動作しますが、相互運用性APIを使用する必要があり、認証と認可に望ましくない妥協が生じます。バックアップにGoogle Cloud Storageを使用する場合、環境変数`BACKUP_BACKEND`を`gcs`に設定することにより、Cloud StorageネイティブCLIである`gsutil`を使用して、アーティファクトのアップロードとフェッチを行うように、Backupユーティリティスクリプトを構成できます。

### 復元する {#restore}

Backupユーティリティは、引数`--restore`が指定されると、実行中のインスタンスへの既存のバックアップからリストアを試みます。このバックアップは、バックアップされたインスタンスと実行中のインスタンスの両方が同じバージョンのGitLabを実行していることを考えると、LinuxパッケージのインストールまたはCNG Helm Chartのインストールのいずれかからのものにすることができます。リストアは、`-t <backup-name>`を使用したバックアップバケット内のファイル、または`-f <url>`を使用したリモートURLを想定しています。

`-t`パラメータが指定されている場合、その名前のバックアップtarについて、オブジェクトストレージ内のバックアップバケットを調べます。`-f`パラメータが指定されている場合、指定されたURIが、コンテナからアクセス可能な場所にあるバックアップtarの有効なURIであると想定します。

バックアップtarをフェッチした後、実行順序は次のとおりです:

1. リポジトリとデータベースの場合は、[GitLab backup Rake task](https://gitlab.com/gitlab-org/gitlab-foss/-/blob/master/lib/tasks/gitlab/backup.rake)を実行します
1. オブジェクトストレージバックエンドごとに、:
   - 対応するオブジェクトストレージバケット内の既存のデータをtarでアーカイブし、`<backup-name>.tar`という名前を付けます
   - オブジェクトストレージ内の`tmp`バケットにアップロードします
   - 対応するバケットをクリーンアップします
   - バックアップコンテンツを対応するバケットにリストアします

{{< alert type="note" >}}

リストアが失敗した場合、ユーザーは手動プロセスであるバックアップバケットの`tmp`ディレクトリにあるデータを使用して、以前のバックアップに戻す必要があります。

{{< /alert >}}
