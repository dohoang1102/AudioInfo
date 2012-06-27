//
//  DrawView.m
//  SpiralPlayer
//
//  Created by Rinat Abdrashitov on 12-05-04.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SpiralControl.h"
#import "math.h"

#define DEGREES_PER_UNIT_VALUE 3 // how many degress are per second of audio for example



@interface SpiralControl(PrivateMethods)
-(void)setCurrentAngleDegrees:(double)angleDeg;
-(void)setCurrentAngleRadians:(double)angleRad;
-(void)updateNeedlePosition;
-(void)drawSpiral;
-(void)numOfTurns;
@end

@implementation SpiralControl

@synthesize value = value_, maximumValue = maximumValue_;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
               
        self.backgroundColor = [UIColor lightGrayColor];        
        
        centerX_ = 380; // x-coordinate of the center of the spiral
        centerY_ = 512; // y-coordinate of the center of the spiral 
        dSpace_ = 90.0; // space between succesive turns of the spiral
       
        //Player thumb needle
        thumb_ = [UIButton buttonWithType:UIButtonTypeCustom];
        thumb_.frame=CGRectMake(0, 0, 50, 52);
        thumb_.center = CGPointMake(centerX_, centerY_);
        [thumb_ addTarget:self action:@selector(dragThumbBegan:withEvent:) forControlEvents:UIControlEventTouchDown];
        [thumb_ addTarget:self action:@selector(dragThumbContinue:withEvent:) forControlEvents:UIControlEventTouchDragInside|UIControlEventTouchDragOutside];
        [thumb_ addTarget:self action:@selector(dragThumbEnded:withEvent:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
        [thumb_ setImage:[UIImage imageNamed:@"handle"] forState:UIControlStateNormal];
        [self addSubview:thumb_];
     
    }
    return self;
}

#pragma mark - THUMB NEEDLE TOUCH EVENT HANDLERS

/*Handle event of first touch of the thumb needle*/
- (void) dragThumbBegan:(UIControl *)control withEvent:(UIEvent *)event {
    currentLevel_ = (int)ceil(currentAngleDeg_/360.0) - 1;
    degreeAtCurrentLevel_ = currentAngleDeg_ - currentLevel_*360;
    radianAtCurrentLevel_ = currentAngleRad_ - currentLevel_*2*M_PI;
    if (degreeAtCurrentLevel_ <= 90) {
        currentQuarter_ = 1;
    } else if(degreeAtCurrentLevel_>90 && degreeAtCurrentLevel_<=180){
        currentQuarter_ = 2;
    } else if(degreeAtCurrentLevel_>180 && degreeAtCurrentLevel_ <=270) {
        currentQuarter_ = 3;
    } else if(degreeAtCurrentLevel_>270 && degreeAtCurrentLevel_<=360){
        currentQuarter_ = 4;
    }
    NSLog(@"Began Drag Thumb -- Degree:%f Rad:%f Level:%i", degreeAtCurrentLevel_, radianAtCurrentLevel_, currentLevel_);
}

/*
 * Handle events of dragging the thumb needle
 */
- (void) dragThumbContinue:(UIControl *)control withEvent:(UIEvent *)event {
    
    //UIButton *bt = (UIButton *)control;
    CGPoint p =[[[event allTouches] anyObject] locationInView:self];
    
    //Move the (x,y) coordinates back to the origin
    double x = p.x - centerX_;
    double y = p.y - centerY_;
  
    //Determine which quarter of the circle we touched. Adjust angle accrodingly.
    double angle = atan((double)abs(y)/abs(x));
        
    if  (x>=0 && y>=0) {
        angle = angle; //I quarter - do nothing.
        if (currentQuarter_ == 4) currentLevel_ += 1;
        currentQuarter_ = 1;
    } else if (x<=0 && y>0) {
        angle = M_PI - angle; //II
        currentQuarter_ = 2;
    } else if (x<0 && y<=0) { 
        angle = M_PI + angle; //III
        currentQuarter_ = 3;
    } else if (x>0 && y<0) { 
        angle = 2*M_PI - angle; //IV
        if (currentQuarter_ == 1) currentLevel_ -= 1;
        currentQuarter_ = 4;
    }  
    
    NSLog(@"ANGLE: %f",angle*(180.0/M_PI) );
            
    //add number of 360 degree turns depending on the turn number
    angle = angle + 2*currentLevel_*M_PI;  
    if (angle > maxAngleRad_ || angle<0) return; // exceed turn number limit
       
    //Calculate the final coordinates
    [self setCurrentAngleRadians:angle]; //update metrics
    [self updateNeedlePosition]; 
    [self sendActionsForControlEvents:UIControlEventValueChanged];

}

/* Handle event of final touch of the thumb needle */
- (void) dragThumbEnded:(UIControl *)control withEvent:(UIEvent *)event {}

#pragma mark - DRAWING THE SPIRAL
/*
 * Draw a spiral using Bezier Curve (faster drawing method)
 */
- (UIBezierPath *)spiralPath {
	
	int iDegrees = DEGREES_PER_UNIT_VALUE;			// Angle between points. 15, 20, 24, 30.
	int totalPoints = 360 / iDegrees;		// Total number of points.

	double iDegreesRadian= M_PI * iDegrees / 180.0;;			// iDegrees as radians.
	double dAngle;				// Cumulative radians while stepping.
	double dSpaceStep = 0;		// dSpace/iN.
	double insideCircleRadius = 0;				// Radius of inside circle. 
	double X = 0.0;				// x co-ordinate of a point.
	double Y = 0.0;				// y co-ordinate of a point.
    
    // Control- and end-points. First 2 points are control-points. Third point is end-point.

	dSpaceStep = 0; 
	double iCount = -1;
	
	CGPoint c1 = CGPointMake(0, 0);
	CGPoint c2 = CGPointMake(0, 0);
	
	UIBezierPath *path = [UIBezierPath bezierPath];
	[path moveToPoint:CGPointMake(centerX_, centerY_)];
	
  	//for (int k = 0; k < iTurns_; k++) {
		for (int i = iDegrees; i <= maximumValue_; i += iDegrees)	{
            
            dSpaceStep += dSpace_/(double)totalPoints;
			dAngle = M_PI * i / 180.0;
               
			// Get points.
			iCount += 1;
			if ((iCount == 0) || (iCount == 1)) {
				// Control-point.
				X = ((insideCircleRadius + dSpaceStep) / cos(iDegreesRadian)) * cos(dAngle) + centerX_;
 				Y = ((insideCircleRadius + dSpaceStep) / cos(iDegreesRadian)) * sin(dAngle) + centerY_;
                
				if (iCount == 0){
					c1 = CGPointMake(X, Y);
                   // NSLog(@"Control Point 1: X:%f Y:%f", X-centerX, Y-centerY);
                } else {
					c2 = CGPointMake(X, Y);
                    //NSLog(@"Control Point 2: X:%f Y:%f", X-centerX, Y-centerY);
                }
			} else {
				// End-point.
				X = (insideCircleRadius + dSpaceStep) * cos(dAngle) + centerX_;
                Y = (insideCircleRadius + dSpaceStep) * sin(dAngle) + centerY_;
                //NSLog(@"End point: X:%f Y:%f", X-centerX, Y-centerY);
				iCount = -1;
			    [path addCurveToPoint:CGPointMake(X, Y) controlPoint1:c1 controlPoint2:c2];
            }
            
            // Draw circle after each turn
//            if (i%360 == 0) {            
//                CGContextSetLineWidth(context, 1.0);
//                CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
//                float circleRad = (k+1)*dSpace_;
//                CGRect rectangle = CGRectMake(centerX_-circleRad, centerY_-circleRad, 2*circleRad, 2*circleRad);
//                CGContextAddEllipseInRect(context, rectangle);
//                CGContextStrokeEllipseInRect(context, rectangle);
//                CGContextStrokePath(context);
//            }
        }
       
    //}
    return path;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    UIBezierPath *path = [self spiralPath]; // get your bezier path, perhaps from an ivar?
    [path stroke];
    //[self drawSpiral];
}

#pragma mark - UIControl TOUCH EVENTS

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    NSLog(@"Touch Began");
    return YES;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    NSLog(@"Touch Continued");
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    //NSLog(@"Touch Ended");
    CGPoint p = [touch locationInView:self];
    
    //Move the (x,y) coordinates back to the origin
    double x = p.x - centerX_;
    double y = p.y - centerY_;
    //Calculate turn number based on the distance from the of origin
    currentLevel_ = floor(sqrt(pow(x,2) + pow(y,2)) / dSpace_); 
        
    //Determine which quarter of the circle we touched. Adjust angle accrodingly.
    double angle = atan((double)abs(y)/abs(x));
    
    if  (x>=0 && y>=0) {
        angle = angle; //I quarter - do nothing.
        currentQuarter_ = 1;
    } else if (x<=0 && y>0) {
        angle = M_PI - angle; //II
        currentQuarter_ = 2;
    } else if (x<0 && y<=0) { 
        angle = M_PI + angle; //III
        currentQuarter_ = 3;
    } else if (x>0 && y<0) { 
        angle = 2*M_PI - angle; //IV
        currentQuarter_ = 4;
    }  
    
    
    //add number of 360 degree turns depending on the turn number
    angle = angle + 2*currentLevel_*M_PI;  
    if (angle > maxAngleRad_ || angle < 0) return; // exceed turn number limit
        
    //Calculate the final coordinates
    [self setCurrentAngleRadians:angle]; // update metrics 
    [self updateNeedlePosition];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {[super touchesBegan:touches withEvent:event];}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {[super touchesMoved:touches withEvent:event];}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {[super touchesEnded:touches withEvent:event];}

#pragma mark - CUSTOM PUBLIC GETTERS AND SETTERS 
-(double)value {
    return value_/DEGREES_PER_UNIT_VALUE;
}

-(void)setValue:(double)value {
    value_ = value * DEGREES_PER_UNIT_VALUE;
    currentAngleDeg_ = value_;
    currentAngleRad_ = value_ * (M_PI/180.0);
    [self updateNeedlePosition];
}

-(double)maximumValue{
    return maximumValue_/DEGREES_PER_UNIT_VALUE;
}

-(void)setMaximumValue:(double)maximumValue {
    maximumValue_ = maximumValue * DEGREES_PER_UNIT_VALUE; //convert value to degrees
    maxAngleDeg_ = maximumValue_; // same
    maxAngleRad_ = maximumValue_ * (M_PI/180.0); //convert to radians
}

#pragma mark - CUSTOM PRIVATE METHODS

-(void)setCurrentAngleDegrees:(double)angleDeg {
    value_ = angleDeg;
    currentAngleDeg_ = angleDeg;
    currentAngleRad_ = angleDeg * (180.0/M_PI);
}

-(void) setCurrentAngleRadians:(double)angleRad {
    value_ = (angleRad *(180.0/M_PI));
    currentAngleDeg_ = value_;
    currentAngleRad_ = angleRad;    
}

/*
 * Update needle position depending on the current angle
 */
-(void)updateNeedlePosition {
    double newX = (dSpace_*currentAngleRad_*cos(currentAngleRad_))/(2*M_PI) + centerX_;
    double newY = (dSpace_*currentAngleRad_*sin(currentAngleRad_))/(2*M_PI) + centerY_;
    thumb_.center = CGPointMake(newX, newY);
    //NSLog(@"Continue --    turn:%i newX:%0.0f newY:%0.0f x:%0.0f y:%0.0f", turnNum, newX, newY, p.x, p.y);
}


@end
