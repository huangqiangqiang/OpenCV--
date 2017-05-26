#include <iostream>
#include <opencv2/opencv.hpp>

using namespace std;

#define cvCvtPixToPlane cvSplit
#define cvQueryHistValue_2D(hist,idx0,idx1)   cvGetReal2D((hist)->bins,(idx0),(idx1))

int main()
{
    IplImage* src = cvLoadImage("/Users/huangqiangqiang/Github/OpenCV--/res/BlueCup.jpg");

    IplImage* hsv = cvCreateImage(cvGetSize(src),IPL_DEPTH_8U,3);
    cvCvtColor(src, hsv, CV_BGR2HSV);

    IplImage *h_src = cvCreateImage(cvGetSize(hsv), 8, 1);
    IplImage *s_src = cvCreateImage(cvGetSize(hsv), 8, 1);
    IplImage* images[] = {h_src, s_src};
    cvCvtPixToPlane( hsv, h_src, s_src, 0, 0);

    int h_bins = 30, s_bins = 32;
    CvHistogram* hist;
    {
        int hist_size[] = {h_bins, s_bins};
        float h_ranges[] = {0, 180};
        float s_ranges[] = {0, 255};
        float* ranges[] = {h_ranges, s_ranges};
        hist = cvCreateHist(2, hist_size, CV_HIST_ARRAY, ranges);
    }

    // 从图像中计算直方图
    cvCalcHist(images, hist, 0, 0);
    // 单位化直方图中的数据
    cvNormalizeHist(hist, 1.0);

    IplImage* dst = cvLoadImage("/Users/huangqiangqiang/Github/OpenCV--/res/adrian.jpg");
    IplImage* dst_hsv = cvCreateImage(cvGetSize(dst),IPL_DEPTH_8U,3);
    cvCvtColor(dst, dst_hsv, CV_BGR2HSV);
    IplImage *h_dst = cvCreateImage(cvGetSize(dst_hsv), 8, 1);
    IplImage *s_dst = cvCreateImage(cvGetSize(dst_hsv), 8, 1);
    cvCvtPixToPlane(dst_hsv, h_dst, s_dst, 0, 0);
    images[0] = h_dst;
    images[1] = s_dst;

    CvSize patch_size = cvSize(src->width, src->height);

    IplImage *result = cvCreateImage(cvSize(dst->width - patch_size.width + 1, dst->height - patch_size.height + 1), IPL_DEPTH_32F, 1);
    cvCalcBackProjectPatch(images, result, patch_size, hist, CV_COMP_CORREL, 1);

    cvNamedWindow("result", 1);
    cvShowImage("result",result);

    // 找出最大位置，可得到此位置即为杯子所在位置
    CvPoint max_location;
    cvMinMaxLoc(result,NULL,NULL,NULL,&max_location,NULL);
    //加上边缘，得到在原始图像中的实际位置
    max_location.x += cvRound(patch_size.width/2);
    max_location.y += cvRound(patch_size.height/2);
    //在dst图像中用红色小圆点标出位置
    cvCircle(dst,max_location,3,CV_RGB(255,0,0),-1);

    cvNamedWindow("dst", 1);
    cvShowImage("dst",dst);

    while (1) {
        if (cvWaitKey(100) == 27) {
            break;
        }
    }

    return 0;
}

