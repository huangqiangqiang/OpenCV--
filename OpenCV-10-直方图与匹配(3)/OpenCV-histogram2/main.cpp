#include <iostream>
#include <opencv2/opencv.hpp>

using namespace std;

int main()
{
    IplImage *src, *templ, *ftmp[6];

    src = cvLoadImage("/Users/huangqiangqiang/Github/OpenCV--/res/faceScene.jpg");
    templ = cvLoadImage("/Users/huangqiangqiang/Github/OpenCV--/res/faceTemplate.jpg");

    // 因为边缘不检测，所以结果图像的宽高要比原图像小
    int iwidth = src->width - templ->width + 1;
    int iheight = src->height - templ->height + 1;

    for (int i = 0; i < 6; i++) {
        ftmp[i] = cvCreateImage(cvSize(iwidth, iheight), 32, 1);
    }

    // 进行不同算法的模板匹配
    for (int i = 0; i < 6; i++) {
        cvMatchTemplate(src, templ, ftmp[i], i); // CV_TM_*
        cvNormalize(ftmp[i],ftmp[i],1,0,CV_MINMAX);

        CvPoint value;
        cvMinMaxLoc(ftmp[i],NULL,NULL,&value,NULL,NULL);

//        value.x += cvRound(templ->width/2);
//        value.y += cvRound(templ->height/2);

        cout << "--------------------- start" << endl;
        cout << value.x << endl;
        cout << value.y << endl;
        cout << "--------------------- end" << endl;
        //在dst图像中用红色小圆点标出位置
        cvCircle(ftmp[i],value,3,CV_RGB(255,255,255),-1);
    }

    cvNamedWindow("Template",0);
    cvNamedWindow("Image",0);
    cvNamedWindow("SQDIFF",0);
    cvNamedWindow("SQDIFF_NORMED",0);
    cvNamedWindow("CCORR",0);
    cvNamedWindow("CCORR_NORMED",0);
    cvNamedWindow("CCOEFF",0);
    cvNamedWindow("CCOEFF_NORMED",0);

    cvShowImage("Template",templ);
    cvShowImage("Image",src);
    cvShowImage("SQDIFF",ftmp[0]);
    cvShowImage("SQDIFF_NORMED",ftmp[1]);
    cvShowImage("CCORR",ftmp[2]);
    cvShowImage("CCORR_NORMED",ftmp[3]);
    cvShowImage("CCOEFF",ftmp[4]);
    cvShowImage("CCOEFF_NORMED",ftmp[5]);

    cvWaitKey();
    return 0;
}

