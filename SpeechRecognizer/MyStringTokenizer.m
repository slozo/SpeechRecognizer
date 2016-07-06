//
//  MyStringTokenizer.m
//  SpeechRecognizer
//
//  Created by Mateusz Szlosek on 28.06.2016.
//  Copyright © 2016 slozo. All rights reserved.
//

#import "MyStringTokenizer.h"
#import <Parsimmon.h>

#define kRecognitionTypeEvent @"kRecognitionTypeEvent"
#define kRecognitionTypeEmail @"kRecognitionTypeEmail"

@interface MyStringTokenizer()
@property (strong, nonatomic) ParsimmonNaiveBayesClassifier *classifier;
@end

@implementation MyStringTokenizer

+(instancetype)sharedInstance
{
    static MyStringTokenizer *retVal = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        retVal = [[MyStringTokenizer alloc] init];
    });
    return retVal;
}

-(instancetype)init
{
    if (self = [super init]) {
        self.classifier = [[ParsimmonNaiveBayesClassifier alloc] init];
        [self learn];
    }
    return self;
}

-(void)learn
{
    [self.classifier trainWithText:@"Create an event" category:kRecognitionTypeEvent];
    [self.classifier trainWithText:@"New event" category:kRecognitionTypeEvent];
    [self.classifier trainWithText:@"Create a meeting" category:kRecognitionTypeEvent];
    [self.classifier trainWithText:@"New meeting" category:kRecognitionTypeEvent];
    
    [self.classifier trainWithText:@"Send a message" category:kRecognitionTypeEmail];
    [self.classifier trainWithText:@"Send the message" category:kRecognitionTypeEmail];
    [self.classifier trainWithText:@"New email" category:kRecognitionTypeEmail];
    [self.classifier trainWithText:@"Create an email" category:kRecognitionTypeEmail];
    [self.classifier trainWithText:@"New message" category:kRecognitionTypeEmail];
    [self.classifier trainWithText:@"New mail" category:kRecognitionTypeEmail];
}

-(void)processString:(NSString *)string outTextView:(UITextView *)textView
{
    self.destinationTextView = textView;
    [self processString:string];
}

-(void)processString:(NSString *)string
{
    if ([string length]) {
        [self determineIntention:string];
    }
}

-(void)appendOutputString:(NSString *)string
{
    NSLog(@"%@", string);
    NSString *nowString = self.destinationTextView.text;
    nowString = [nowString stringByAppendingString:@"\n"];
    nowString = [nowString stringByAppendingString:string];
    self.destinationTextView.text = nowString;
}

-(void)determineIntention:(NSString *)query
{
#pragma mark - Bayes Classification
    
    NSString *intention = [self.classifier classify:query];
    if ([intention isEqualToString:kRecognitionTypeEvent]) {
        [self appendOutputString:@"Event Found!"];
    } else if ([intention isEqualToString:kRecognitionTypeEmail] && ([query containsString:@"message"] || [query containsString:@"email"])) {
        [self appendOutputString:@"Mail found!"];
    } else {
        [self appendOutputString:@"Nothing found!"];
    }
    
    [self tokenizeString:query];
}

-(void)tokenizeString:(NSString *)query
{
#pragma mark - Linguistic Tagger
    NSLinguisticTaggerOptions options = NSLinguisticTaggerOmitWhitespace | NSLinguisticTaggerOmitPunctuation | NSLinguisticTaggerJoinNames;
    
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes: [NSLinguisticTagger availableTagSchemesForLanguage:@"en"]
                                                                        options:options];
    tagger.string = query;
    
    [tagger enumerateTagsInRange:NSMakeRange(0, [query length])
                          scheme:NSLinguisticTagSchemeNameTypeOrLexicalClass
                         options:options
                      usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
        NSString *token = [query substringWithRange:tokenRange];
                          [self appendOutputString:[NSString stringWithFormat:@"%@: \t %@",token, tag]];
    }];
    
    NSArray *tokens = [tagger tagsInRange:NSMakeRange(0, [query length])
                                   scheme:NSLinguisticTagSchemeNameTypeOrLexicalClass
                                  options:options
                              tokenRanges:nil];
    
    [self appendOutputString:[NSString stringWithFormat:@"Tokens: %@",tokens]];
    
#pragma mark - Data Detector
    
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeAddress
                                | NSTextCheckingTypePhoneNumber | NSTextCheckingTypeDate
                                                               error:&error];
    
    [detector enumerateMatchesInString:query
                               options:kNilOptions
                                 range:NSMakeRange(0, [query length])
                            usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         [self appendOutputString:[NSString stringWithFormat:@"Match: %@", result]];
     }];
    
    NSLog(@"---------------------------------------------------------------");
}

@end
