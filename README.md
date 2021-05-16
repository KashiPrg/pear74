# pear74

このアプリはgoogleが提供する[Flutter](https://flutter.dev/)フレームワークを用いて開発されています。
このアプリの開発・ビルドを行うためには、[Flutter SDK](https://flutter.dev/docs/get-started/install)と、Flutter SDKが要求する環境の整備が必要です。
環境の整備に関して必要な情報はFlutter公式がダウンロードページで丁寧に解説していますし、細かなトラブルに関する情報もユーザ集団によって活発に交換されていますので、ここには載せません。

## アプリのビルドを行う前に

アプリのビルドに必要なdartパッケージが不足している場合があります。
このリポジトリのルートディレクトリ(つまり`pear74`ディレクトリ)で
```
flutter pub get
```
を実行し、必要なパッケージを導入してください。

## iOSにおけるビルド

サイズが100MBを超えており、GitHubにアップロードできないため、iOS向けのビルドに必要なファイルの一部がリポジトリに含まれていません。
以下に必要なファイルを導入する手順を記述します。
なお、この手順は2020-10-22時点でのものです。

- [OpenCVの配布ページ](https://opencv.org/releases/)にアクセスし、**最新版のiOS pack**をダウンロードします。
- ダウンロードしたファイル(**opencv-x.x.x-ios-framework.zip**のような名前になっていると思われます。x.x.xはバージョンを示します)を解凍します。**opencv2.framework**というフォルダが出てきます。
- ターミナルでこのリポジトリの`ios`ディレクトリに飛びます。
- `open Runner.xcworkspace`を実行し、Xcodeを開きます。
- Xcodeが管理しているファイル群の画面を開き、先の手順で解凍した**opencv2.framework**を、ドラッグ&ドロップでプロジェクトにインポートします。このとき、"Choose options for adding these files"というメニューが出てくるので、"Copy items if needed"にチェックをつけ、"Create folder references"を選択して**Finish**を押してください。

これで必要なコンポーネントが揃ったはずです。
