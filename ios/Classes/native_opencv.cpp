#include <opencv2/opencv.hpp>

using namespace cv;
using namespace std;

// Avoiding name mangling
extern "C" {
    // Attributes to prevent 'unused' function from being removed and to make it visible
    __attribute__((visibility("default"))) __attribute__((used))
    const char* version() {
        return "CV_VERSION";
    }

    __attribute__((visibility("default"))) __attribute__((used))
    char* process_image(char* inputImagePath, char* outputImagePath) {
        /*
        Mat input = imread(inputImagePath, IMREAD_GRAYSCALE);
        Mat threshed, withContours;

        vector<vector<Point>> contours;
        vector<Vec4i> hierarchy;

        adaptiveThreshold(input, threshed, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, 77, 6);
        findContours(threshed, contours, hierarchy, RETR_TREE, CHAIN_APPROX_TC89_L1);

        cvtColor(threshed, withContours, COLOR_GRAY2BGR);
        drawContours(withContours, contours, -1, Scalar(0, 255, 0), 4);

        imwrite(outputImagePath, withContours);
        */

       // トリミングする円形の半径
        int trim_radius = 640 / 5 / 2;

        // 画像の読み込み(末尾の1はRGBでの読み込みを示す)
        Mat img = imread(inputImagePath, 1);

        // 読み込んだ画像の切り抜き 画像の中心の一部を切り抜く
        int trim_start_x = img.cols / 2 - trim_radius;  // 切り抜きの始点のx座標
        int trim_start_y = img.rows / 2 - trim_radius;  // 切り抜きの始点のy座標
        Mat trimmed = Mat(img, Rect(trim_start_x, trim_start_y, trim_radius * 2, trim_radius * 2));

        // ぼかしでコルクを目立たなくする作戦
        // ただしコルクの色も少なからず混じるので、地の色よりだいぶ黄色くなる印象
        // そもそも人間が見たときの見た目をぼかすことにどの程度の意味があるのか？
        // Mat blurred;
        // medianBlur(trimmed, blurred, 7);

        // 切り抜いた画像を更に円形にマスキングする(円の内側だけ残す)
        // 切り抜いた画像と同じ寸法の真っ黒な画像
        Mat mask = Mat::zeros(trimmed.cols, trimmed.rows, CV_8UC3);

        // マスクとなる白く塗りつぶされた円を、マスク画像に描画
        // circle(対象画像, 中心座標, 半径, RGB色指定, 円の太さ(負の値で塗りつぶし。FILLED=-1))
        circle(mask, Point(mask.cols / 2, mask.rows / 2), mask.rows / 2, Scalar(255, 255, 255), FILLED);

        // マスキング
        // マスク対象画像.copyTo(出力先, マスク)
        Mat masked;
        trimmed.copyTo(masked, mask);

        // エッジ検出によってコルクを検出し、画像からコルクを取り除く
        // しかし結果を見るに、解像度が荒い故にうまく行っている部分がある気がする
        // エッジ検出のためグレースケール化
        Mat cir_gray;
        cvtColor(trimmed, cir_gray, COLOR_BGR2GRAY);
        // ラプラシアンエッジ検出
        Mat laplacian;
        Laplacian(cir_gray, laplacian, CV_32F, 1, 5);
        // CV_32F(0.0 ~ 1.0) -> CV_8U(0 ~ 255)への変換を行う
        laplacian.convertTo(laplacian, CV_8U, 256, 0.0);

        // ラプラシアンエッジをマスクとして適用
        Mat cork_removed;
        masked.copyTo(cork_removed, laplacian);

        // 自動的な二値化でコルクを取り除こうとしたが、やはり下のほうが暗いらしくそちらが引っかかる。
        // どうにか輝度を平坦化できればうまい具合にできそうだが……？
        // Mat cir_bin;
        // threshold(cir_gray, cir_bin, 0, 255, THRESH_BINARY | THRESH_OTSU);

        imwrite(outputImagePath, cork_removed);

        // メモリリリース
        img.release();
        trimmed.release();
        masked.release();
        mask.release();
        cir_gray.release();
        laplacian.release();
        cork_removed.release();

        return "2.5";
    }
}