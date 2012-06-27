//
//  DrawView.h
//  SpiralPlayer
//
//  Created by Rinat Abdrashitov on 12-05-04.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpiralControl : UIControl {
    UIButton* thumb_;
    double centerX_;
    double centerY_;
    double dSpace_;
    
    int currentLevel_;
    double degreeAtCurrentLevel_;
    double radianAtCurrentLevel_;
    int currentQuarter_;    
    
    //Current values
    double value_;
    double currentAngleDeg_;
    double currentAngleRad_;
    
    //Maximum values
    double maximumValue_;
    double maxAngleDeg_;
    double maxAngleRad_;
    
}

@property (nonatomic, assign) double value;
@property (nonatomic, assign) double maximumValue;

@end
