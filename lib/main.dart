import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;

import 'file_manager.dart';
import 'picture_manager.dart';
import 'native_opencv.dart';

List<CameraDescription> cameras;

/// 最初に起動する部分
/// このあたりはホットリロードじゃなくてメニューから再起動(回転矢印マークの)かけないと反映されないことがある
Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    // プラグインサービスが初期化されていることを確認する。以下の処理の前にやっておかないと例外発生
    WidgetsFlutterBinding.ensureInitialized();

    // このアプリで利用するディレクトリマネージャと写真のマネージャの準備
    await FileManager.init();
    PictureManager.init();

    // 画面の向きを縦に固定する
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    // デバイスに搭載されている、利用可能なカメラのリストを取得
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(MainApp());
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

/// Main
class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => new CameraApp(),
        '/SavedPictures': (BuildContext context) => new SavedPictures(),
        '/PicturePreview': (BuildContext context) => new PicturePreview(),
      },
    );
  }
}

/// カメラウィジェット
class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

/// カメラウィジェット本体 起動したら最初に出てくる画面
class _CameraAppState extends State<CameraApp> {
  CameraController controller;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // カメラのプレビュー画面を特定するためのキー
  final GlobalKey _cameraPreviewKey = GlobalKey();
  // 切り抜き範囲提示用の輪のサイズ(後で変更をかける)
  double _cutoutCircleSize = 40.0;
  bool _cutoutCircleSizeDecided = false;

  // final double _bottomBoxHeight = 75.0;

  @override
  void initState() {
    super.initState();
    // カメラ初期設定
    controller = CameraController(
        cameras[0], //背面カメラのみ
        ResolutionPreset.medium, // iPhoneだと解像度はmediumくらいが縦横比的にちょうどいい
        enableAudio: false, //音声は不要
        imageFormatGroup: ImageFormatGroup.jpeg // jpeg形式で保存
        );
    controller.initialize().then((_) {
      if (!mounted) {
        // フラッシュを焚かないようにする
        controller.setFlashMode(FlashMode.off);
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    // 切り抜き範囲提示用の輪のサイズが決定されていないとき、build終了時に決定する
    if (!_cutoutCircleSizeDecided) {
      // これでbuild終了時に実行する処理が書ける
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() {
          // カメラプレビューのRenderBoxは描画が終わっていないと取得できない
          // したがってbuild終了時に取得する必要がある
          RenderBox box = _cameraPreviewKey.currentContext.findRenderObject();

          // 取得したカメラプレビューの横幅をもとに輪のサイズを決定
          // iPhoneとAndroidでは同じ設定でも解像度が異なることがあるため、横幅をもとに決定
          // ResolutionPreset.mediumのサマリーを見れば、解像度の違いがわかる
          // 乗数は2で良かったはずだが、cameraを0.8.0に更新したらずれた
          _cutoutCircleSize = box.size.width / 15 * 2.15; // 480 / 15 * 2 = 64
          _cutoutCircleSizeDecided = true;
        });
      });
    }
    return MaterialApp(
      title: 'Pear Harvest Time Checker',
      theme: ThemeData(
        primaryColor: Colors.lightGreenAccent, // 上の帯の色
        scaffoldBackgroundColor: Colors.lightGreen, // 背景色
      ),
      home: Scaffold(
        key: _scaffoldKey,
        // 上の帯
        appBar: AppBar(
          title: const Text('Pear Harvest Time Checker'),
        ),
        // 帯の下全域
        body: Center(
          // Columnで縦に要素を並べる
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    // Stackでカメラ画面を奥に、切り抜き範囲提示用の輪を手前に表示する
                    child: Stack(
                      children: <Widget>[
                        // カメラ画面
                        Center(
                            child: Container(
                          key: _cameraPreviewKey,
                          child: CameraPreview(controller),
                        )),
                        // 切り抜き範囲提示用の輪
                        Center(
                            child: CustomPaint(
                          size: Size(_cutoutCircleSize, _cutoutCircleSize),
                          painter: CutoutCirclePaint(),
                        )),
                      ],
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      color: Colors.lightGreenAccent,
                      width: 3.0,
                    ),
                  ),
                ),
              ),
              // 撮影ボタンとアルバムボタン
              Padding(
                padding: const EdgeInsets.all(8.0),
                // Stackで画面奥・手前方向にWidgetを積み重ねる
                child: Stack(
                  children: <Widget>[
                    // アルバムボタン 撮った写真のリストを表示する画面に遷移する
                    // ListTileでアイコンを右端にお手軽配置
                    // こういうのはPaddingでやったほうがいいのか？
                    ListTile(
                      title: Text(''),
                      trailing: IconButton(
                          icon: Icon(
                            Icons.photo,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.of(context).pushNamed('/SavedPictures');
                          }),
                    ),

                    // 撮影ボタン
                    Center(
                        child: ButtonTheme(
                      minWidth: 60.0,
                      height: 60.0,
                      // 浮き上がった感じの影があるボタン
                      child: ElevatedButton(
                          // ボタンの中のカメラアイコン
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.lightGreen,
                            size: 30.0,
                          ),
                          // 押したら撮影
                          onPressed: () => onTakePictureButtonPressed(),
                          // スタイル
                          style: ElevatedButton.styleFrom(
                              primary: Colors.white, // 白
                              shape: CircleBorder(), // 円形
                              minimumSize: Size(60, 60))),
                    ))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// カメラボタンを押したとき
  void onTakePictureButtonPressed() {
    // 写真を撮る処理と、その後の処理
    takePicture().then((List<String> filesPath) {
      if (filesPath != null) {
        // 画像分析
        processImage(filesPath[0], filesPath[1], filesPath[2], filesPath[3]);
        // showInSnackBar('Picture saved to ${filesPath[0]}');
      }
    });
  }

  /// スナックバー表示、画像保存時にファイルパスが表示される
  void showInSnackBar(String message) {
    // deprecatedな部分を修正する方法が現状不明
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  /// カメラ撮影処理
  Future<List<String>> takePicture() async {
    // 撮影した画像を保存するパスを決定
    final List<String> filesPath = PictureManager.picturesPathTimeStamped();
    XFile picture;

    if (controller.value.isTakingPicture) {
      // 写真を撮っている最中なので何もしない
      return null;
    }

    try {
      picture = await controller.takePicture(); // 撮影と保存
    } on CameraException catch (e) {
      // すでに同名のファイルが存在していた場合など、何らかの例外が発生した場合の処理
      _showCameraException(e);
    }

    await picture.saveTo(filesPath[0]);

    return filesPath;
  }

  /// カメラエラー
  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
  }

  /// エラーログ
  void logError(String code, String message) =>
      print('Error: $code/nError Message: $message');
}

/// 輪を描画するためのクラス
class CutoutCirclePaint extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightGreen
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 2;
    canvas.drawRect(
        Rect.fromCenter(center: center, width: radius, height: radius), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// 撮った写真の一覧を表示する画面
class SavedPictures extends StatefulWidget {
  @override
  _SavedPicturesState createState() => _SavedPicturesState();
}

class _SavedPicturesState extends State<SavedPictures> {
  List<File> _takenPicturesList;
  List<File> _trimmedPicturesList;
  List<File> _processedPicturesList;
  List<File> _analyzedTextsList;

  @override
  Widget build(BuildContext context) {
    // 撮った写真などのファイルパスのリストを取得
    _takenPicturesList = PictureManager.takenPicturesPathList();
    _trimmedPicturesList = PictureManager.trimmedPicturesPathList();
    _processedPicturesList = PictureManager.processedPicturesPathList();
    _analyzedTextsList = PictureManager.analyzedTextsPathList();

    // 新しい順に並べる
    _takenPicturesList.sort((a, b) => b.path.compareTo(a.path));
    _trimmedPicturesList.sort((a, b) => b.path.compareTo(a.path));
    _processedPicturesList.sort((a, b) => b.path.compareTo(a.path));
    _analyzedTextsList.sort((a, b) => b.path.compareTo(a.path));

    return Scaffold(
        appBar: AppBar(
          title: Text("Saved Pictures"),
        ),
        body: ListView.builder(
            itemCount: _takenPicturesList.length,
            itemBuilder: (BuildContext context, int index) {
              final takenItem = _takenPicturesList[index];

              // スワイプして削除できるようにする
              return Dismissible(
                // 一意に特定できるキーを設定する ファイル名なら重複しない
                key: Key(takenItem.path),

                // スワイプされたときの動作を記述する
                // [direction]にスワイプの方向が格納されている
                onDismissed: (direction) {
                  // 画面右から左にスワイプされたとき、要素を削除する
                  // ただ、startToEndというのが文章を読む方向に依存しているっぽいので、
                  // 言語設定によっては逆になる可能性あり
                  if (direction == DismissDirection.endToStart) {
                    setState(() {
                      // 実体を削除する
                      FileManager.removeFile(takenItem);
                      FileManager.removeFile(_trimmedPicturesList[index]);
                      FileManager.removeFile(_processedPicturesList[index]);
                      FileManager.removeFile(_analyzedTextsList[index]);

                      // スワイプされた要素をリストから削除する
                      _takenPicturesList.removeAt(index);
                    });
                  }
                },

                // スワイプされたとき、本当に削除するかを決定する
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    // 画面右から左にスワイプされたときだけ削除を許可する
                    return true;
                  }
                  // それ以外の場合はスワイプしても戻ってくる
                  return false;
                },

                // startToEndの方向にスワイプした場合の背景の設定
                background: Container(color: Colors.white),

                // endToStartの方向にスワイプした場合の背景の設定
                secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    color: Colors.red,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(10.0, 0.0, 20.0, 0.0),
                      child: Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    )),

                // ListViewの要素
                child: Card(
                    child: ListTile(
                  onTap: () {
                    // タッチしたらその写真のプレビューに飛ぶ
                    Navigator.of(context).pushNamed('/PicturePreview',
                        arguments: new PicturePreviewContainer(
                            takenItem,
                            _trimmedPicturesList[index],
                            _processedPicturesList[index],
                            _analyzedTextsList[index]));
                  },
                  // 画像のサムネイル
                  leading: Image.file(takenItem),
                  // 拡張子なしのファイル名
                  title: Text(p.basenameWithoutExtension(takenItem.path)),
                  // カラーチャートの数値
                  trailing: Text('2.5'),
                )),
              );
            }));
  }
}

class PicturePreviewContainer {
  PicturePreviewContainer(this.takenPicture, this.trimmedPicture,
      this.processedPicture, this.analyzedText);

  final File takenPicture;
  final File trimmedPicture;
  final File processedPicture;
  final File analyzedText;
}

/// 撮った写真の確認用の画面
class PicturePreview extends StatefulWidget {
  /// ページ呼び出し用のメソッド
  static Route<dynamic> route(
      {@required PicturePreviewContainer picPreContainer}) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => new PicturePreview(),
      settings: RouteSettings(arguments: picPreContainer),
    );
  }

  @override
  _PicturePreviewState createState() => _PicturePreviewState();
}

class _PicturePreviewState extends State<PicturePreview> {
  @override
  Widget build(BuildContext context) {
    PicturePreviewContainer arguments =
        ModalRoute.of(context).settings.arguments;

    return Scaffold(
        appBar: AppBar(
            // タイトルは拡張子なしのファイル名
            title:
                Text(p.basenameWithoutExtension(arguments.takenPicture.path))),
        // 要素を並べていく
        body: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Image.file(arguments.takenPicture),
              ),
              Center(
                child: Row(
                  children: [
                    Image.file(arguments.trimmedPicture),
                    Image.file(arguments.processedPicture)
                  ],
                ),
              ),
              Text(
                arguments.analyzedText.readAsStringSync(),
                textAlign: TextAlign.left,
              )
            ],
          ),
        ));
  }
}
