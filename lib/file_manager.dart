import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// アプリで扱うファイルとディレクトリを管理する
///
/// ---
/// アプリの起動時に[FileManager.init]を実行する必要がある
///
/// 例：
/// ```
/// Future<void> main() async {
///   // DirectoryManager.init()の前にやっておかないと例外が発生する
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // DirectoryManager.init()のすぐ後にDirectoryManagerを
///   // 利用するモジュールが来る可能性があるため、
///   // awaitで同期処理にしておいたほうが良い
///   await DirectoryManager.init();
///
///   runApp(MainApp());
/// }
/// ```
class FileManager {
  /// アプリのディレクトリパス
  static String _appDirPath = '';

  /// ディレクトリ名とそのパスのマップ
  static Map<String, String> _directoriesPath = {};

  /// このアプリで利用するディレクトリの用意
  /// mainの最初に呼んでおく
  /// getApplicationDocumentsDirectory()をappDirPathにやらせると、appDirPathやpicDirPathを呼び出すメソッドが芋づる式に全部Futureになってしまうので、ここで一括で設定
  /// 外部で初期化を呼ばないと使えないのは正直避けたいが、現状これ以上に使い勝手がいい実装方法が思いつかない
  static Future<void> init() async {
    // アプリのディレクトリパスを取得＆保存
    final Directory directory = await getApplicationDocumentsDirectory();
    _appDirPath = directory.path;
  }

  /// [directoryName]の名前を持つディレクトリを作成し、管理対象として追加する
  ///
  /// ---
  /// ```
  /// addDirectory('foo');
  /// ```
  /// ディレクトリ`foo`が作成され、管理対象として追加される
  ///
  /// ---
  /// ```
  /// addDirectory('foo/bar');
  /// ```
  /// ディレクトリ`foo/bar`が作成され、管理対象として追加されるが、ディレクトリ`foo`は管理対象にならない。
  static void addDirectory(String directoryName) {
    // Mapにディレクトリ名と、そのディレクトリへのパスを保管する
    _directoriesPath.addEntries([
      MapEntry<String, String>(directoryName, '$_appDirPath/$directoryName')
    ]);

    // ディレクトリを(そこまでのディレクトリも含めて)作成する
    Directory(_directoriesPath[directoryName]).createSync(recursive: true);
  }

  /// [directoryNames]の要素の名前を持つディレクトリ群を作成し、管理対象として追加する
  ///
  /// ---
  /// ```
  /// addDirectories(['foo', 'bar/baz']);
  /// ```
  /// ディレクトリ`foo`が作成され、管理対象として追加される
  ///
  /// また、ディレクトリ`bar/baz`が作成され、管理対象として追加されるが、ディレクトリ`bar`は管理対象にならない。
  static void addDirectories(List<String> directoryNames) {
    for (String directoryName in directoryNames) {
      addDirectory(directoryName);
    }
  }

  /// 指定のディレクトリへのパスを返す
  ///
  /// [FileManager.addDirectory]や[FileManager.addDirectories]で追加されていないディレクトリにアクセスしようとした場合は例外が発生する
  ///
  /// ---
  /// ```
  /// addDirectory('foo');
  /// String fooDirPath = getDirectoryPath('foo');
  /// ```
  /// 変数`fooDirPath`にディレクトリ`foo`のパスが格納される
  ///
  /// ---
  ///  ```
  /// addDirectory('bar/baz');
  /// String bazDirPath = getDirectoryPath('bar/baz');
  /// String barDirPath = getDirectoryPath('bar');
  /// ```
  /// 変数`bazDirPath`にディレクトリ`bar/baz`のパスが格納される
  ///
  /// ディレクトリ`bar`は管理対象でないため例外発生
  static String getDirectoryPath(String directoryName) {
    // Mapでは、存在しないキーにアクセスしようとした場合にnullが返ってくるため、
    // 左辺がnullである場合の処理が記述できる ?? 演算子によって例外を投げる
    return _directoriesPath[directoryName] ??
        (throw ArgumentError(
            'Accessing to a directory that is not added in\n"${(FileManager.addDirectory).toString()}"\nor\n"${(FileManager.addDirectories).toString()}."'));
  }

  /// アプリのディレクトリパス
  static String get appDirPath {
    return _appDirPath;
  }

  /// [directoryPath]で指定されたディレクトリの、すべてのファイルのリストを取得する
  ///
  /// 希望の順番で並んでいるとは限らないため、取得後のソートが必要
  static List<File> filesPathList(String directoryPath) {
    return List<File>.from(Directory(directoryPath)
        .listSync() // 同期処理で指定ディレクトリ配下の要素を取得
        .where((element) =>
            FileSystemEntity.isFileSync(element.path))); // ファイルのみ取得(ディレクトリを排除)
  }

  /// [directoryPath]で指定されたディレクトリから、[ext]で指定された拡張子を持つファイルのリストを取得する
  ///
  /// [ext]の例：`'.jpg'`, `'.txt'`
  ///
  /// 希望の順番で並んでいるとは限らないため、取得後のソートが必要
  static List<File> filesPathListWithExtension(
      String directoryPath, String ext) {
    // 指定のディレクトリの、すべてのファイルのリストを取得する
    List<File> fpList = filesPathList(directoryPath);

    // 指定の拡張子を持つファイルのみを取得して返す
    return _extractFilesWithExtension(fpList, ext);
  }

  /// [directoryPath]で指定されたディレクトリから、[exts]で指定された拡張子群のいずれかを持つファイルのリストを取得する
  ///
  /// [exts]の例：`{'.jpg', '.txt'}`
  ///
  /// 希望の順番で並んでいるとは限らないため、取得後のソートが必要
  static List<File> filesPathListWithExtensions(
      String directoryPath, List<String> exts) {
    // 指定のディレクトリの、すべてのファイルのリストを取得する
    List<File> fpList = filesPathList(directoryPath);
    // 返り値用のリスト
    List<File> returnList = [];

    // 指定の拡張子を一つずつ取り出し、その拡張子に合致するファイルのリストを抽出して結合
    for (String ext in exts) {
      returnList = [...returnList, ..._extractFilesWithExtension(fpList, ext)];
    }

    // 抽出されたファイルが重複していた場合に備え、
    // 重複要素を許さないSetに変換後、再びListに変換して返す
    return returnList.toSet().toList();
  }

  /// 引数として渡されたファイルパスのリストから、指定の拡張子を持つファイルを抽出する
  ///
  /// 簡単のため、リスト中のファイルが存在しなかったり、リストにディレクトリが含まれている場合の動作は保証しない。
  static List<File> _extractFilesWithExtension(
      List<File> filesPathList, String ext) {
    return filesPathList
        .where((element) => p.extension(element.path) == ext)
        .toList();
  }

  /// [file]のファイルを削除する
  ///
  /// [file]で指定されたファイルが存在する場合はそれを削除して`true`を返し、存在しない場合は何も行わず`false`を返す。
  static bool removeFile(File file) {
    if (file.existsSync()) {
      // そのファイルが存在するなら削除する
      file.deleteSync();
      return true;
    }
    return false;
  }

  /// [files]のファイル群を削除する
  ///
  /// 実際にそれぞれのファイルの削除が行われた(`true`)か否(`false`)かは返り値のリストに格納されている
  ///
  /// 順番は[files]と対応しており、`true`の場合は指定のファイルが存在しており、削除されたことを示す
  ///
  /// `false`の場合は指定のファイルが存在しておらず、何も行われなかったことを示す
  static List<bool> removeFiles(List<File> files) {
    /// ファイル削除の成否群を格納する
    List<bool> results = [];

    // 実際の作業はremoveFile()にお任せ
    for (File file in files) {
      results.add(removeFile(file));
    }

    return results;
  }
}
