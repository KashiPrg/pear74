import 'dart:io';

import 'file_manager.dart';

/// アプリで扱う写真を管理する
///
/// ---
/// アプリの起動時に[FileManager.init]と[PictureManager.init]を実行する必要がある
///
/// 例：
/// ```
/// Future<void> main() async {
///   // DirectoryManager.init()の前にやっておかないと例外が発生する
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // PictureManagerはDirectoryManagerの要素に依存するため、
///   // DirectoryManager.init()の終了を待つ
///   await DirectoryManager.init();
///   PictureManager.init();
///
///   runApp(MainApp());
/// }
/// ```
class PictureManager {
  /// 撮った写真を保存するディレクトリの名前
  static final _takenDirName = 'Pictures/Taken';

  /// 画像処理された写真を保存するディレクトリの名前
  static final _procDirName = 'Pictures/Processed';

  static void init() {
    FileManager.addDirectories([_takenDirName, _procDirName]);
  }

  /// 撮った写真を保存するディレクトリのパス
  static String get takenDirPath {
    return FileManager.getDirectoryPath(_takenDirName);
  }

  /// 画像処理された写真を保存するディレクトリのパス
  static String get procDirPath {
    return FileManager.getDirectoryPath(_procDirName);
  }

  /// 撮った写真と、その写真を加工した後の画像の保存パスをタイムスタンプによるファイル名付きで生成する
  ///
  /// 0番目の要素は撮った写真のパス
  ///
  /// 1番目の要素は加工した後の画像の保存パス
  ///
  /// [ext]で拡張子を設定する(例：`'.jpg'`)
  static List<String> picturesPathTimeStamped({String ext = '.jpg'}) {
    // マイクロ秒単位でのタイムスタンプを取得する
    String ts = DateTime.now().toIso8601String();

    return ['$takenDirPath/$ts$ext', '$procDirPath/$ts$ext'];
  }

  /// 撮った写真のファイルパスのリストを取得する
  ///
  /// 新しい順に並んでいるとは限らないため、新しい順に並べたいときは
  /// ```
  /// List<File> takenPics = PictureManager.takenPicturesPathList();
  /// takenPicList.sort((a, b) => b.path.compareTo(a.path));
  /// ```
  /// などでソートする必要がある
  ///
  /// ファイル名がタイムスタンプであるため、名前で並び替えれば良い
  static List<File> takenPicturesPathList() {
    // 一言で言えば、写真用フォルダの中からjpg画像ファイルのみを取得する処理
    return FileManager.filesPathListWithExtension(takenDirPath, '.jpg');
  }

  /// 加工された画像のファイルパスのリストを取得する
  ///
  /// 新しい順に並んでいるとは限らないため、新しい順に並べたいときは
  /// ```
  /// List<File> procPics = PictureManager.processedPicturesPathList();
  /// procPicList.sort((a, b) => b.path.compareTo(a.path));
  /// ```
  /// などでソートする必要がある
  ///
  /// ファイル名がタイムスタンプであるため、名前で並び替えれば良い
  static List<File> processedPicturesPathList() {
    return FileManager.filesPathListWithExtension(procDirPath, '.jpg');
  }

  /// 撮った写真をすべて削除する
  static void deleteTakenPicturesAll() {
    FileManager.removeFiles(takenPicturesPathList());
  }

  /// 加工された画像をすべて削除する
  static void deleteProcessedPicturesAll() {
    FileManager.removeFiles(processedPicturesPathList());
  }
}
