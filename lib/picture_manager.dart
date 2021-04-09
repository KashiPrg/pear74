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

  /// トリミングされた写真を保存するディレクトリの名前
  static final _trimmedDirName = 'Pictures/Trimmed';

  /// 画像処理された写真を保存するディレクトリの名前
  static final _procDirName = 'Pictures/Processed';

  /// 画像の分析結果のテキストファイルを保存するディレクトリの名前
  static final _analyzedDirName = 'Texts/Analyzed';

  static void init() {
    FileManager.addDirectories(
        [_takenDirName, _trimmedDirName, _procDirName, _analyzedDirName]);
  }

  /// 撮った写真を保存するディレクトリのパス
  static String get takenDirPath {
    return FileManager.getDirectoryPath(_takenDirName);
  }

  /// トリミングされた写真を保存するディレクトリのパス
  static String get trimmedDirPath {
    return FileManager.getDirectoryPath(_trimmedDirName);
  }

  /// 画像処理された写真を保存するディレクトリのパス
  static String get procDirPath {
    return FileManager.getDirectoryPath(_procDirName);
  }

  /// 画像の分析結果のテキストファイルを保存するディレクトリのパス
  static String get analyzedDirPath {
    return FileManager.getDirectoryPath(_analyzedDirName);
  }

  /// 撮った写真と、その写真を加工した後の画像の保存パスをタイムスタンプによるファイル名付きで生成する
  ///
  /// 0番目の要素は撮った写真のパス
  ///
  /// 1番目の要素はトリミングされた写真のパス
  ///
  /// 2番目の要素は加工した後の画像の保存パス
  ///
  /// 3番目の要素は画像の分析結果のテキストファイルのパス(拡張子は`.txt`で固定)
  ///
  /// [ext]で拡張子を設定する(例：`'.jpg'`)
  static List<String> picturesPathTimeStamped({String ext = '.jpg'}) {
    // マイクロ秒単位でのタイムスタンプを取得する
    String ts = DateTime.now().toIso8601String();

    return [
      '$takenDirPath/$ts$ext',
      '$trimmedDirPath/$ts$ext',
      '$procDirPath/$ts$ext',
      '$analyzedDirPath/$ts.txt'
    ];
  }

  /// 撮った写真のファイルパスのリストを取得する
  ///
  /// 新しい順に並んでいるとは限らないため、新しい順に並べたいときは
  /// ```
  /// List<File> takenPics = PictureManager.takenPicturesPathList();
  /// takenPics.sort((a, b) => b.path.compareTo(a.path));
  /// ```
  /// などでソートする必要がある
  ///
  /// ファイル名がタイムスタンプであるため、名前で並び替えれば良い
  static List<File> takenPicturesPathList() {
    // 一言で言えば、写真用フォルダの中からjpg画像ファイルのみを取得する処理
    return FileManager.filesPathListWithExtension(takenDirPath, '.jpg');
  }

  /// トリミングされた写真のファイルパスのリストを取得する
  ///
  /// 新しい順に並んでいるとは限らないため、新しい順に並べたいときは
  /// ```
  /// List<File> trimmedPics = PictureManager.trimmedPicturesPathList();
  /// trimmedPics.sort((a, b) => b.path.compareTo(a.path));
  /// ```
  /// などでソートする必要がある
  ///
  /// ファイル名がタイムスタンプであるため、名前で並び替えれば良い
  static List<File> trimmedPicturesPathList() {
    // 一言で言えば、写真用フォルダの中からjpg画像ファイルのみを取得する処理
    return FileManager.filesPathListWithExtension(trimmedDirPath, '.jpg');
  }

  /// 加工された画像のファイルパスのリストを取得する
  ///
  /// 新しい順に並んでいるとは限らないため、新しい順に並べたいときは
  /// ```
  /// List<File> procPics = PictureManager.processedPicturesPathList();
  /// procPics.sort((a, b) => b.path.compareTo(a.path));
  /// ```
  /// などでソートする必要がある
  ///
  /// ファイル名がタイムスタンプであるため、名前で並び替えれば良い
  static List<File> processedPicturesPathList() {
    return FileManager.filesPathListWithExtension(procDirPath, '.jpg');
  }

  /// 分析結果のテキストファイルのパスのリストを取得する
  ///
  /// 新しい順に並んでいるとは限らないため、新しい順に並べたいときは
  /// ```
  /// List<File> analyzedTexts = PictureManager.analyzedTextsPathList();
  /// analyzedTexts.sort((a, b) => b.path.compareTo(a.path));
  /// ```
  /// などでソートする必要がある
  ///
  /// ファイル名がタイムスタンプであるため、名前で並び替えれば良い
  static List<File> analyzedTextsPathList() {
    return FileManager.filesPathListWithExtension(analyzedDirPath, '.txt');
  }

  /// 撮った写真をすべて削除する
  static void deleteTakenPicturesAll() {
    FileManager.removeFiles(takenPicturesPathList());
  }

  /// 撮った写真をすべて削除する
  static void deleteTrimmedPicturesAll() {
    FileManager.removeFiles(trimmedPicturesPathList());
  }

  /// 加工された画像をすべて削除する
  static void deleteProcessedPicturesAll() {
    FileManager.removeFiles(processedPicturesPathList());
  }

  /// 分析結果のテキストファイルをすべて削除する
  static void deleteAnalyzedTextsAll() {
    FileManager.removeFiles(analyzedTextsPathList());
  }
}
