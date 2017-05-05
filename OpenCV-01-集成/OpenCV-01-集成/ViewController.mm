//
//  ViewController.m
//  OpenCV-01-集成
//
//  Created by 黄强强 on 17/5/5.
//  Copyright © 2017年 黄强强. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>
#import "HQQCVTool.hpp"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 命名空间
    using namespace cv;
    
    // 创建300 * 300的图形
    Mat colorim(300,300, CV_8UC3);
    
    // 设置颜色
    for (int i = 0; i < colorim.rows; i++) {
        for (int j = 0; j < colorim.cols; j++) {
            Vec3b pixel;
            pixel[0] = i % 255;   // blue
            pixel[1] = j % 255;   // green
            pixel[2] = 0;         // red
            colorim.at<Vec3b>(i,j) = pixel;
        }
    }
    
    // Mat转UIImage
    UIImage *img = MatToUIImage(colorim);
    
    [self.view addSubview:[[UIImageView alloc] initWithImage:img]];
}

@end
