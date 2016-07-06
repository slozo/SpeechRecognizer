//
//  MyStringTokenizer.h
//  SpeechRecognizer
//
//  Created by Mateusz Szlosek on 28.06.2016.
//  Copyright © 2016 slozo. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface MyStringTokenizer : NSObject
@property (weak, nonatomic) UITextView *destinationTextView;
+(instancetype)sharedInstance;
-(void)processString:(NSString *)string outTextView:(UITextView *)textView;
-(void)processString:(NSString *)string;

@end
