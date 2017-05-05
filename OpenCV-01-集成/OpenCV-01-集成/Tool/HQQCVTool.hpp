//
//  HQQCVTool.h
//  OpenCV-01-集成
//
//  Created by 黄强强 on 17/5/5.
//  Copyright © 2017年 黄强强. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface HQQCVTool : NSObject


/**
 Mat转UIImage

 @param image <#image description#>
 @return <#return value description#>
 */
UIImage* MatToUIImage(const cv::Mat& image);


/**
 UIImage转Mat

 @param image <#image description#>
 @param m <#m description#>
 @param alphaExist <#alphaExist description#>
 */
void UIImageToMat(const UIImage* image, cv::Mat& m, bool alphaExist = false);

@end
