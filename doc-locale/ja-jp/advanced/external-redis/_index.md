---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部RedisでGitLabチャートを設定します
---

このドキュメントでは、外部RedisサービスでこのHelmチャートを設定する方法について説明します。

Redisが設定されていない場合は、オンプレミスまたは仮想マシンへのデプロイのために、弊社の[Linuxパッケージ](external-omnibus-redis.md)の使用をご検討ください。

現在サポートされているRedisのバージョンの詳細については、[インストールシステムの要件](https://docs.gitlab.com/install/requirements/#redis)を参照してください。

## チャートを設定します {#configure-the-chart}

`redis`チャートとそれが提供するRedisサービスを無効にし、他のサービスを外部サービスに接続します。

次のパラメータを設定する必要があります:

- `redis.install`: `false`に設定して、Redisチャートを含めないようにします。
- `global.redis.host`: 外部Redisのホスト名に設定します。これはドメインまたはIPアドレスにすることができます。
- `global.redis.auth.enabled`: 外部Redisがパスワードを必要としない場合は、`false`に設定します。
- `global.redis.auth.secret`: [認証用のトークンを含むシークレット](../../installation/secrets.md#redis-password)の名前。
- `global.redis.auth.key`: シークレット内のキー。これには、トークンコンテンツが含まれています。

デフォルトを使用していない場合は、以下の項目をさらにカスタマイズできます:

- `global.redis.port`: データベースが利用可能なポート。 デフォルトは`6379`です。
- `global.redis.database`: Redisサーバー上で接続するデータベース。 `0`がデフォルトです。

たとえば、デプロイ中にHelmの`--set`フラグを使用してこれらの値を渡します:

```shell
helm install gitlab gitlab/gitlab  \
  --set redis.install=false \
  --set global.redis.host=redis.example \
  --set global.redis.auth.secret=gitlab-redis \
  --set global.redis.auth.key=redis-password \
```

Sentinelサーバーが実行されているRedis高可用性クラスタリングに接続している場合は、`global.redis.host`属性を、`sentinel.conf`で指定されているように、Redis Redisインスタンスグループの名前（`mymaster`や`resque`など）に設定する必要があります。Redis mainのホスト名には設定しないでください。Sentinelサーバーは、`--set`フラグの`global.redis.sentinels[0].host`および`global.redis.sentinels[0].port`値を使用して参照できます。インデックスはゼロから始まります。

## 複数のRedis Redisインスタンスを使用する {#use-multiple-redis-instances}

GitLabは、リソースを大量に消費する複数のRedis操作を複数のRedis Redisインスタンスに分割することをサポートしています。このチャートは、これらの永続属性を他のRedis Redisインスタンスに分散することをサポートしています。

複数のRedis Redisインスタンスを使用するためのチャートの設定に関する詳細については、[グローバル](../../charts/globals.md#multiple-redis-support)ドキュメントを参照してください。

## セキュアなRedisスキーム（SSL）を指定する {#specify-secure-redis-scheme-ssl}

SSLを使用してRedisに接続するには、`rediss`（二重の`s`に注意してください）スキームパラメータを使用します:

```shell
--set global.redis.scheme=rediss
```

## `redis.yml`オーバーライド {#redisyml-override}

[GitLab 15.8で導入された`redis.yml`設定ファイル](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106854)の内容をオーバーライドする場合は、`global.redis.redisYmlOverride`で値を定義することで呼び出すことができます。そのキーの下のすべての値とサブ値は、そのまま`redis.yml`にレンダリングされます。

`global.redis.redisYmlOverride`設定は、外部Redisサービスで使用することを目的としています。`redis.install`を`false`に設定する必要があります。詳細については、[Redis設定の設定](../../charts/globals.md#configure-redis-settings)を参照してください。

例: 

```yaml
redis:
  install: false
global:
  redis:
    redisYmlOverride:
      raredis:
        host: rare-redis.example.com:6379
        password:
          enabled: true
          secret: secretname
          key: password
      exotic_redis:
        host: redis.example.com:6379
        password: <%= File.read('/path/to/secret').strip.to_json %>
      mystery_setting:
        deeply:
          nested: value
```

`/path/to/secret`に`THE SECRET`が含まれ、`/path/to/secret/raredis-override-password`に`RARE SECRET`が含まれていると仮定すると、これにより`redis.yml`に以下がレンダリングされます:

```yaml
production:
  raredis:
    host: rare-redis.example.com:6379
    password: "RARE SECRET"
  exotic_redis:
    host: redis.example.com:6379
    password: "THE SECRET"
  mystery_setting:
    deeply:
      nested: value
```

### 注意すべき点 {#things-to-look-out-for}

`redisYmlOverride`の柔軟性の裏返しは、ユーザーフレンドリーではないことです。例: 

1. パスワードを`redis.yml`に挿入するには、次のいずれかを行います:
   - 既存の[パスワード定義](../../charts/globals.md#multiple-redis-support)を使用し、HelmにERBステートメントに置き換えさせます。
   - 正しいERB `<%= File.read('/path/to/secret').strip.to_json %>`ステートメントを自分で記述します。コンテナにシークレットがマウントされているパスを使用します。
1. `redisYmlOverride`では、GitLab Railsの命名規則に従う必要があります。たとえば、「SharedState」インスタンスは`sharedState`とは呼び出されず、`shared_state`とは呼び出されます。
1. 設定値の継承はありません。たとえば、単一のSentinelセットを共有する3つのRedis Redisインスタンスがある場合は、Sentinel設定を3回繰り返す必要があります。
1. CNGイメージは[有効な`resque.yml`と`cable.yml`を想定しています](https://gitlab.com/gitlab-org/build/CNG/-/blob/4d314e505edb25ccefd4297d212bfbbb5bc562f9/gitlab-rails/scripts/lib/checks/redis.rb#L54)。 `resque.yml`ファイルを取得するには、少なくとも`global.redis.host`を設定する必要があります。

## トラブルシューティング {#troubleshooting}

<!-- markdownlint-disable line-length -->

### `ERR Error running script (call to f_5962bd591b624c0e0afce6631ff54e7e4402ebd8): @user_script:7: ERR syntax error` {#err-error-running-script-call-to-f_5962bd591b624c0e0afce6631ff54e7e4402ebd8-user_script7-err-syntax-error}

Helmチャート7.2以降で外部Redis 5を使用している場合は、`webservice`および`sidekiq`ポッドのログにこのエラーが表示されることがあります。Redis 5は[サポートされていません](https://docs.gitlab.com/install/requirements/#redis)。

これを修正するには、外部Redisインスタンスを6.x以降にアップグレードします。

<!-- markdownlint-enable line-length -->
