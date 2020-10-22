import 'dart:async';
import 'dart:io';
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
  String imagePath;

  /// ネイティブ側でOpenCVを扱うためのメソッドチャンネル
  /// 2020-08-29現在、FlutterにはiOSでもOpenCVを扱えるようにするライブラリがない(Android用のはある)
  /// なので、ネイティブ側でやってもらうしかない
  /// また、保守性の観点からサードパーティ製のライブラリはあまり使いたくない
  static const MethodChannel _opencv =
      const MethodChannel('com.miyatalab.pear74/opencv');

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // final double _bottomBoxHeight = 75.0;

  @override
  void initState() {
    super.initState();
    // カメラ初期設定
    controller = CameraController(
      cameras[0], //背面カメラのみ
      ResolutionPreset.medium, // iPhoneだと解像度はmediumくらいが縦横比的にちょうどいい
      enableAudio: false, //音声は不要
    );
    controller.initialize().then((_) {
      if (!mounted) {
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
              // カメラ画面
              Flexible(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
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
                      child: RaisedButton(
                        // ボタンの中のカメラアイコン
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.lightGreen,
                          size: 30.0,
                        ),
                        // 押したら撮影
                        onPressed: () => onTakePictureButtonPressed(),
                        color: Colors.white,
                        // 形は円形
                        shape: CircleBorder(),
                      ),
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
        setState(() {
          imagePath = filesPath[0];
        });
        // showInSnackBar('Picture saved to ${filesPath[0]}');
      }
    });
  }

  /// スナックバー表示、画像保存時にファイルパスが表示される
  void showInSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(message)));
  }

  /// タイムスタンプ取得
  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  /// カメラ撮影処理
  Future<List<String>> takePicture() async {
    // 撮影した画像を保存するパスを決定
    final List<String> filesPath = PictureManager.picturesPathTimeStamped();

    try {
      await controller.takePicture(filesPath[0]); // 撮影と保存
    } on CameraException catch (e) {
      // すでに同名のファイルが存在していた場合など、何らかの例外が発生した場合の処理
      _showCameraException(e);
    }

    // カラーチャート判定のためにネイティブ(Swift/Kotlin)の処理を呼ぶ
    // なぜネイティブ側で処理しなければならないかは"_opencv"の説明を参照のこと
    final Map invokeMethodParams = <String, dynamic>{
      'picPath': filesPath[0],
      'procPath': filesPath[1],
    };
    // final String result =
    // await _opencv.invokeMethod('JudgeColorChart', invokeMethodParams);

    showInSnackBar(processImage(filesPath[0], filesPath[1]));

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

/// 撮った写真確認用の画面
class SavedPictures extends StatefulWidget {
  @override
  _SavedPicturesState createState() => _SavedPicturesState();
}

class _SavedPicturesState extends State<SavedPictures> {
  List<File> _picturesList;

  @override
  Widget build(BuildContext context) {
    // 撮った写真のファイルパスのリストを取得
    _picturesList = PictureManager.takenPicturesPathList();

    // 新しい順に並べる
    _picturesList.sort((a, b) => b.path.compareTo(a.path));

    return Scaffold(
        appBar: AppBar(
          title: Text("Saved Pictures"),
        ),
        body: ListView.builder(
            itemCount: _picturesList.length,
            itemBuilder: (BuildContext context, int index) {
              final item = _picturesList[index];

              // スワイプして削除できるようにする
              return Dismissible(
                // 一意に特定できるキーを設定する ファイル名なら重複しない
                key: Key(item.path),

                // スワイプされたときの動作を記述する
                // [direction]にスワイプの方向が格納されている
                onDismissed: (direction) {
                  // 画面右から左にスワイプされたとき、要素を削除する
                  // ただ、startToEndというのが文章を読む方向に依存しているっぽいので、
                  // 言語設定によっては逆になる可能性あり
                  if (direction == DismissDirection.endToStart) {
                    setState(() {
                      // 実体を削除する
                      FileManager.removeFile(item);

                      // スワイプされた要素をリストから削除する
                      _picturesList.removeAt(index);
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
                  leading: Image.file(item),
                  title: Text(p.basenameWithoutExtension(item.path)),
                  trailing: Text('2.5'),
                )),
              );
            }));
  }
}
