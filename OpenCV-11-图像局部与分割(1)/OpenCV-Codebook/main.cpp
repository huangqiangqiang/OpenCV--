#include <iostream>
#include <opencv2/opencv.hpp>

using namespace std;

#define channels 3

// 码元的数据结构
typedef struct ce {
    // 此码元各通道的阈值上限（学习界限）
    unsigned char learnHigh[channels];
    // 此码元各通道的阈值下限（学习界限）
    unsigned char learnLow[channels];
    // 学习过程中如果一个新像素各通道值x[i],均有 learnLow[i]<=x[i]<=learnHigh[i],则该像素可合并于此码元，否则新开一个码元

    // 保存此码元像素各通道的最大值
    unsigned char max[channels];
    // 保存此码元像素各通道的最小值
    unsigned char min[channels];

    // 此码元最后一次更新时间，每一帧为一个单位时间，用于计算stale
    int t_last_update;

    // 此码元最长不更新时间，用于删除规定时间不更新的码元，精简码本
    int stale;

} code_element;

// 码本的数据结构
typedef struct code_book {

    // 码元的二维指针，理解为指向码元指针数组的指针，添加码元时不需要来回复制码元，只需要简单的指针赋值即可
    code_element** cb;

    // 此码本中码元的数目
    int numEntries;

    // 此码本现在的时间，一帧为一个时间单位
    int t;

} CodeBook;



void cvupdateCodeBook(uchar *p, CodeBook &c, unsigned *cbBounds, int numChannels);
void cvclearStaleEntries(CodeBook &c);
uchar cvbackgroundDiff(uchar *p, CodeBook &c, int numChannels, int *minMod, int *maxMod);
void find_connected_components(IplImage *mask, int poly1_hull0, float perimScale, int *num, CvRect *bbs, CvPoint *centers);

int main()
{
    ///////////////////////////////////////////////////////////
    // 初始化数据
    ///////////////////////////////////////////////////////////

    // codebook 数组
    CodeBook *cb;
    unsigned cbBounds[channels];
    unsigned char* pColor;
    int nChannels = channels;

    // 开发中需要不断调整mod，对已知前景达到最好的分割
    int maxMod[channels];
    int minMod[channels];

    // 初始化各变量
    cvNamedWindow("CodeBook");


    CvCapture *capture = cvCreateCameraCapture(0);
    if (!capture)
    {
        printf("Couldn't open the capture!");
        return -1;
    }

    IplImage *rawImage = cvQueryFrame(capture);
    // 给yuvImage 分配一个和rawImage 尺寸相同,8位3通道图像
    IplImage *yuvImage = cvCreateImage(cvGetSize(rawImage), 8, 3);
    // 保存识别的结果，为resultImage 分配一个和rawImage 尺寸相同,8位单通道图像
    IplImage *resultImage = cvCreateImage(cvGetSize(rawImage), 8, 1);
    // 设置单通道数组所有元素为255,即初始化为白色图像
    cvSet(resultImage,cvScalar(255));

    // 得到与图像像素数目长度一样的一组码本,以便对每个像素进行处理
    int imageLen = rawImage->width * rawImage->height;
    cb = new CodeBook[imageLen];

    // 初始化每个码元数目为0
    for (int i = 0; i < imageLen; i++) {
        cb[i].numEntries = 0;
    }

    for (int i = 0; i < nChannels; i++) {
        cbBounds[i] = 10;
        maxMod[i] = 20;
        minMod[i] = 20;
    }

    ///////////////////////////////////////////////////////////
    // 开始处理视频每一帧图像
    ///////////////////////////////////////////////////////////

    for (int i = 0; i <= 50 ;i++) {

        // 色彩空间转换，bgr转yuv格式
        cvCvtColor(rawImage, yuvImage, CV_BGR2YCrCb);
        pColor = (unsigned char *)(yuvImage->imageData);


        // 前300帧进行背景学习
        for (int j = 0; j < imageLen; j++) {
            // 对每个像素，调用此函数，捕捉背景中相关变化图像
            cvupdateCodeBook(pColor, cb[j], cbBounds, nChannels);
            // 3 通道图像, 指向下一个像素通道数据
            pColor += 3;
        }

        if (i == 50) {
            // 第300帧时遍历每个码本(像素)，删除码本中陈旧的码元
            for (int j = 0; j < imageLen; j++) {
                cvclearStaleEntries(cb[j]);
            }
        }

        cvShowImage("CodeBook", rawImage);

        // 延时100毫秒获取下一帧图片
        if (cvWaitKey(100) == 27) {
            break;
        }

        rawImage = cvQueryFrame(capture);
    }

    printf("学习完毕，开始测试");
    cvWaitKey(NULL);

    while (1) {
        rawImage = cvQueryFrame(capture);

        // 色彩空间转换，bgr转yuv格式
        cvCvtColor(rawImage, yuvImage, CV_BGR2YCrCb);
        pColor = (unsigned char *)(yuvImage->imageData);

        unsigned char maskPixelCodeBook;
        uchar *pMask = (uchar *)((resultImage)->imageData); //1 channel image
        for (int j = 0; j < imageLen; j++) {
            // 计算的结果，该返回值不是0，就是255
            maskPixelCodeBook = cvbackgroundDiff(pColor, cb[j], nChannels, minMod, maxMod);
            // resultImage是单通道图像
            *pMask++ = maskPixelCodeBook;
            // pColor 指向的是3通道图像
            pColor += 3;
        }

        // 连通域去噪
        find_connected_components(resultImage, 1, 4, NULL, NULL, NULL);

        cvShowImage("CodeBook", resultImage);
        if (cvWaitKey(100) == 27) {
            break;
        }
    }

    ///////////////////////////////////////////////////////////
    // 释放内存
    ///////////////////////////////////////////////////////////

    cvReleaseCapture(&capture);
    if (yuvImage) {
        cvReleaseImage(&yuvImage);
    }
    if(resultImage){
        cvReleaseImage(&resultImage);
    }
    cvDestroyAllWindows();
    delete [] cb;

    return 0;
}


void cvupdateCodeBook(uchar *p, CodeBook &c, unsigned *cbBounds, int numChannels)
{
    if (c.numEntries == 0) {
        // 码本中码元为0时初始化时间为0
        c.t = 0;
    }

    // 每调用一次加一,即每一帧图像加一
    c.t += 1;

    int n;
    unsigned int high[3], low[3];

    for (n = 0; n < numChannels; n++) {
        // 用p 所指的像素数据,加减cbBonds中数值,作为此像素阀值的上下限
        // *(p+n) 的速度比 p[n]快
        high[n] = *(p + n) + *(cbBounds + n);
        low[n] = *(p + n) - *(cbBounds + n);

        if (high[n] > 255) {
            high[n] = 255;
        }

        if (low[n] < 0) {
            low[n] = 0;
        }
    }

    int matchChannel;
    int i;

    // 遍历此码本每个码元,测试p像素是否满足其中之一
    for (i = 0; i < c.numEntries; i++) {
        matchChannel = 0;
        for (n = 0; n < numChannels; n++) {
            // 遍历每个通道，如果p 像素通道数据在该码元阀值上下限之间
            if ( (*(p+n) >= c.cb[i]->learnLow[n]) &&
                 (*(p+n) <= c.cb[i]->learnHigh[n]) ) {
                matchChannel++;
            }
        }

        // 如果p 像素各通道都满足上面条件
        if (matchChannel == numChannels) {
            // 更新该码元时间为当前时间
            c.cb[i]->t_last_update = c.t;

            // 调整该码元各通道最大最小值
            for (n = 0; n < numChannels; n++) {
                if ( (*(p + n) > c.cb[i]->max[n]) ) {
                    c.cb[i]->max[n] = *(p + n);
                }
                else if ( (*(p + n) < c.cb[i]->min[n]) ) {
                    c.cb[i]->min[n] = *(p + n);
                }
            }
            break;
        }
    }

    // 不匹配其中任何的码元，则创建一个新码元
    if(i == c.numEntries) {
        // 申请c.numEntries+1个指向码元的指针
        code_element **foo = new code_element* [c.numEntries + 1];

        // 将前c.numEntries 个指针指向已存在的每个码元
        for(int ii=0; ii<c.numEntries; ii++) {
            foo[ii] = c.cb[ii];
        }

        // 申请一个新的码元
        foo[c.numEntries] = new code_element;

        // 删除c.cb 指针数组
        if(c.numEntries) {
            delete [] c.cb;
        }
        c.cb = foo;

        // 设置新码元的数据
        for(n=0; n<numChannels; n++) {
            c.cb[c.numEntries]->learnHigh[n] = high[n];
            c.cb[c.numEntries]->learnLow[n] = low[n];
            c.cb[c.numEntries]->max[n] = *(p+n);
            c.cb[c.numEntries]->min[n] = *(p+n);
        }
        c.cb[c.numEntries]->t_last_update = c.t;
        c.cb[c.numEntries]->stale = 0;
        c.numEntries += 1;
    }

    // 计算该码元的不更新时间
    for(int s=0; s<c.numEntries; s++) {
        int negRun = c.t - c.cb[s]->t_last_update;
        if(c.cb[s]->stale < negRun) {
            c.cb[s]->stale = negRun;
        }
    }

    // 如果像素通道数据在高低阈值范围内，但在码元阈值范围外，则缓慢调整此码元学习界限
    for (n = 0; n < numChannels; n++) {
        if (c.cb[i]->learnHigh[n] < high[n]) {
            c.cb[i]->learnHigh[n] += 1;
        }

        if (c.cb[i]->learnLow[n] < low[n]) {
            c.cb[i]->learnLow[n] -= 1;
        }
    }

}

void cvclearStaleEntries(CodeBook &c)
{
    // 设定刷新时间，右移一位相当于除以2
    int staleThresh = c.t >> 1;
    // 申请一个标记数组
    int *keep = new int [c.numEntries];
    // 记录不删除码元数目
    int keepCnt = 0;

    // 遍历码本中每个码元
    for (int i = 0; i < c.numEntries; i++) {
        // 如码元中的不更新时间大于设定的刷新时间,则标记为删除
        if (c.cb[i]->stale > staleThresh) {
            keep[i] = 0;
        }
        else {
            keep[i] = 1;
            keepCnt += 1;
        }
    }

    // 码本时间清零
    c.t = 0;

    // 申请大小为keepCnt 的码元指针数组
    code_element **foo = new code_element* [keepCnt];

    int k=0;
    for(int ii=0; ii<c.numEntries; ii++) {
        if(keep[ii]) {
            foo[k] = c.cb[ii];
            foo[k]->stale = 0;
            foo[k]->t_last_update = 0;
            k++;
        }
    }

    delete [] keep;
    delete [] c.cb;
    // 把foo 头指针地址赋给c.cb
    c.cb = foo;
    // 被清理的码元个数
    int numCleared = c.numEntries - keepCnt;
    // 剩余的码元个数
    c.numEntries = keepCnt;
}

uchar cvbackgroundDiff(uchar *p, CodeBook &c, int numChannels, int *minMod, int *maxMod)
{
    int matchChannel;
    int i;
    for (i = 0; i < c.numEntries; i++) {
        matchChannel = 0;
        for (int n = 0; n < numChannels; n++) {
            if ( (c.cb[i]->max[n] + maxMod[n] >= *(p + n) ) &&
                 (c.cb[i]->min[n] - minMod[n] <= *(p + n) ) ) {
                matchChannel++;
            }
            else{
                break;
            }
        }

        // 第i个码元的所有通道都匹配了，说明应该为背景，则跳出for循环
        if (matchChannel == numChannels) {
            break;
        }
    }

    // 没有匹配的码元，识别为前景，返回白色
    if(i == c.numEntries) {
        return(255);
    }

    // 识别为背景，返回黑色
    return 0;
}



// for connected components:
// approx.threshold - the bigger it is, the simpler is the boundary
// 用于连接组件:
// 大约阈值越大越好，边界越简单
#define CVCONTOUR_APPROX_LEVEL 2
// how many iterations of erosion and/or dilation there should be
// 应该有多少次侵蚀和/或扩张迭代
#define CVCLOSE_ITR 1


/*
 * 连通域去噪声
 * Find_Connected_Component参数说明：
 * mask ——— 一副灰度图
 * polygon1_hull0 ——— 用多边形拟合选1，用凸包拟合选0
 * scale ——— 设置不被删除的连通轮廓大小
 * num ———— 连通轮廓的最大数目（收集轮廓的统计信息）
 * bbs —— 指向连通轮廓的外接矩形（收集轮廓的统计信息）
 * center —— 指向连通轮廓的中心（收集轮廓的统计信息）
*/
void find_connected_components(IplImage *mask, int poly1_hull0, float perimScale, int *num, CvRect *bbs, CvPoint *centers)
{
    static CvMemStorage* mem_storage = NULL;
    static CvSeq* contours = NULL;

    // 开运算
    cvMorphologyEx(mask, mask, 0, 0, CV_MOP_OPEN, CVCLOSE_ITR);
    // 闭运算
    cvMorphologyEx(mask, mask, 0, 0, CV_MOP_CLOSE, CVCLOSE_ITR);

    // 现在，噪声已经被从掩模图像上清除了
    if(mem_storage == NULL) {
        mem_storage = cvCreateMemStorage(0);
    }
    else {
        cvClearMemStorage(mem_storage);
    }

    // 在掩模图像上寻找轮廓，cvStartFindContours每次返回一个轮廓，而不是像cvFindContours一次返回所有轮廓
    // 调用scanner的cvFindNextContour查找剩余的轮廓
    CvContourScanner scanner = cvStartFindContours(mask, mem_storage, sizeof(CvContour),CV_RETR_EXTERNAL,CV_CHAIN_APPROX_SIMPLE);

    // 下一步，我们丢弃较小的轮廓，用多边形或凸包拟合剩下的轮廓
    CvSeq* c;
    // 处理后剩余轮廓的个数
    int numCont = 0;

    while ( (c = cvFindNextContour(scanner)) != NULL ) {
        // cvContourPerimeter函数作用于一个轮廓并返回其长度
        double len = cvContourPerimeter(c);
        double q = (mask->height + mask->width) / perimScale;

        if (len < q) {
            // 删除该轮廓
            cvSubstituteContour( scanner, NULL);
        }
        else {
            // 如果其足够大，平滑其边缘
            CvSeq* c_new;

            if (poly1_hull0) {
                // 多边形逼近该轮廓（多边形拟合）
                c_new = cvApproxPoly(c,sizeof(CvContour),mem_storage,CV_POLY_APPROX_DP,CVCONTOUR_APPROX_LEVEL,0);
            }
            else {
                // 凸包拟合
                c_new = cvConvexHull2(c, mem_storage, CV_CLOCKWISE, 1);
            }

            // 把c轮廓替换成换成c_new
            cvSubstituteContour(scanner, c_new);
            numCont++;
        }
    }

    // 释放scanner并返回所有的轮廓
    contours = cvEndFindContours(&scanner);

    const CvScalar CVX_WHITE = CV_RGB(0xff, 0xff, 0xff);
    const CvScalar CVX_BLACK = CV_RGB(0x00, 0x00, 0x00);

    // 转为全黑图像，以便在上面绘制轮廓
    cvZero(mask);

    IplImage *maskTemp;

    if (num != NULL) {
        int N = *num, numFilled = 0, i = 0;
        CvMoments moments;
        double M00,M01,M10;
        maskTemp = cvCloneImage(mask);

        for (i = 0, c = contours; c != NULL; c = c->h_next, i++) {
            if (i < N) {
                cvDrawContours(maskTemp, c, CVX_WHITE, CVX_WHITE, -1, CV_FILLED, 8);

                // find the centerof each contour
                if (centers != NULL) {
                    cvMoments(maskTemp, &moments, 1);
                    M00 = cvGetSpatialMoment(&moments, 0, 0);
                    M01 = cvGetSpatialMoment(&moments, 0, 1);
                    M10 = cvGetSpatialMoment(&moments, 1, 0);
                    centers[i].x = (int)(M10/M00);
                    centers[i].y = (int)(M01/M00);
                }

                if (bbs != NULL) {
                    bbs[i] = cvBoundingRect(c);
                }
                cvZero(maskTemp);
                numFilled++;
            }
            cvDrawContours(mask, c, CVX_WHITE, CVX_WHITE, -1, CV_FILLED, 8);
        }
        *num = numFilled;
        cvReleaseImage(&maskTemp);
    }
    else {

        // 如果用户不需要图像中生成区域的外接矩形和中心，我们只需要把轮廓画出来即可

        for (c = contours; c != NULL; c = c->h_next) {
            /*
             *  绘制轮廓
             * mask         要绘制的图像
             * c            要绘制的轮廓
             * CVX_WHITE    轮廓的颜色
             * CVX_BLACK    轮廓内部洞的颜色
             * -1           -1表示只有输入轮廓会被画出（-2，-1，0，1）
             */
            cvDrawContours(mask, c, CVX_WHITE, CVX_BLACK, -1, CV_FILLED, 8);
        }
    }
}
