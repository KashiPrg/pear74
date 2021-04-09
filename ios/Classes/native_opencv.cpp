#include <opencv2/opencv.hpp>

using namespace cv;
using namespace std;

void calcHistAvrStd(Mat hist, int hist_size, float *avr, float *peak, float *std_dev, float *med)
{
    float a, max, dev, std_d, sum, mid, next;
    int i;

    for(i = 0, mid = 0.0; i < hist_size; i++)
        mid += hist.at<float>(i);
    mid *= 0.5;

    for(i = 0, sum = 0.0; i < hist_size; i++){
        next = sum + hist.at<float>(i);
        if(next >= mid){
            *med = (float)i;
            break;
        }
        else
            sum = next;
    }

    for(i = 0, a = 0.0, max = 0.0, sum = 0.0; i < hist_size; i++){
        a += (float)i * hist.at<float>(i);
        sum += hist.at<float>(i);
        if(max < hist.at<float>(i))
            max = (float)i;
    }

    a = a / sum;

    for(i = 0, std_d = 0.0; i < hist_size; i++){
        dev = (float)i - a;
        dev *= dev;
        std_d += dev * hist.at<float>(i);
    }

    // avr:平均値　peak:最大値　std_dev:標準偏差
    *avr = a;
    *peak = max;
    *std_dev = sqrt(std_d / sum);
}

// Avoiding name mangling
extern "C" {
    // Attributes to prevent 'unused' function from being removed and to make it visible
    __attribute__((visibility("default"))) __attribute__((used))
    const char* version() {
        return "CV_VERSION";
    }

    __attribute__((visibility("default"))) __attribute__((used))
    char* process_image(char* inputImagePath, char* trimmedImagePath, char* processedImagePath) {
        // トリミングする円形の半径
        int trim_radius = 640 / 5 / 2;

        // 画像の読み込み(末尾の1はRGBでの読み込みを示す)
        Mat img = imread(inputImagePath, 1);

        // 読み込んだ画像の切り抜き 画像の中心の一部を切り抜く
        int trim_start_x = img.cols / 2 - trim_radius;  // 切り抜きの始点のx座標
        int trim_start_y = img.rows / 2 - trim_radius;  // 切り抜きの始点のy座標
        Mat trimmed = Mat(img, Rect(trim_start_x, trim_start_y, trim_radius * 2, trim_radius * 2));
        // imwrite(img_path + "_trimmed.jpeg", trimmed);

        // RGB -> Lab

        Mat dst_img;

        cvtColor(trimmed, dst_img, COLOR_BGR2Lab);


        // Lab : a, b histgram

        int lbins = 256, abins = 256, bbins=256;

        int lhistSize[] = {lbins};
        int ahistSize[] = {abins};
        int bhistSize[] = {bbins};

        float lrange[] = {0, 255};
        float arange[] = {0, 255};
        float brange[] = {0, 255};

        const float* lranges[] = {lrange};
        const float* aranges[] = {arange};
        const float* branges[] = {brange};

        int lchannels[] = {0};
        int achannels[] = {1};
        int bchannels[] = {2};

        Mat lhist, ahist, bhist;

        calcHist(&dst_img, 1, lchannels, Mat(), lhist, 1, lhistSize, lranges, true, false);
        calcHist(&dst_img, 1, achannels, Mat(), ahist, 1, ahistSize, aranges, true, false);
        calcHist(&dst_img, 1, bchannels, Mat(), bhist, 1, bhistSize, branges, true, false);

        float l_avr, l_peak, l_std, l_med;
        float a_avr, a_peak, a_std, a_med;
        float b_avr, b_peak, b_std, b_med;

        calcHistAvrStd(lhist, lbins, &l_avr, &l_peak, &l_std, &l_med);
        // printf("-------------------\n");
        // printf("Lab-L:AVR = %f, PEAK = %f, STD = %f\n", l_avr, l_peak, l_std);

        calcHistAvrStd(ahist, abins, &a_avr, &a_peak, &a_std, &a_med);
        // printf("-------------------\n");
        // printf("Lab-A:AVR = %f, PEAK = %f, STD = %f\n", a_avr, a_peak, a_std);

        calcHistAvrStd(bhist, bbins, &b_avr, &b_peak, &b_std, &b_med);
        // printf("-------------------\n");
        // printf("Lab-B:AVR = %f, PEAK = %f, STD = %f\n", b_avr, b_peak, b_std);
        // printf("%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f\n", l_avr, l_peak, l_std, l_med, a_avr, a_peak, a_std, a_med, b_avr, b_peak, b_std, b_med);
        // printf("%f, %f, %f\n", l_med, a_med, b_med);

        imwrite(trimmedImagePath, trimmed);
        imwrite(processedImagePath, dst_img);

        // メモリリリース
        img.release();
        trimmed.release();
        dst_img.release();

        stringstream ss;

        ss << "Lab-L:AVR = " << l_avr << ", MED = " << l_med << ", PEAK = " << l_peak << ", STD = " << l_std;
        ss << "\nLab-A:AVR = " << a_avr << ", MED = " << a_med << ", PEAK = " << a_peak << ", STD = " << a_std;
        ss << "\nLab-B:AVR = " << b_avr << ", MED = " << b_med << ", PEAK = " << b_peak << ", STD = " << b_std;

        char *result_buffer;
        sprintf(result_buffer, "Lab-L:AVR = %.1f, MED = %.1f, PEAK = %.1f, STD = %.1f\nLab-A:AVR = %.1f, MED = %.1f, PEAK = %.1f, STD = %.1f\nLab-B:AVR = %.1f, MED = %.1f, PEAK = %.1f, STD = %.1f", l_avr, l_med, l_peak, l_std, a_avr, a_med, a_peak, a_std, b_avr, b_med, b_peak, b_std);

        return result_buffer;
    }
}