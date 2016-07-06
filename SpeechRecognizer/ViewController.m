//
//  ViewController.m
//  SpeechRecognizer
//
//  Created by Mateusz Szlosek on 28.06.2016.
//  Copyright © 2016 slozo. All rights reserved.
//

#import "ViewController.h"
#import "ContextualStringsDataSource.h"
#import "MyStringTokenizer.h"
#import <Parsimmon.h>
@import Accelerate;



@interface ViewController () <SFSpeechRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *recordButtton;
- (void)recordStop:(id)sender;
- (void)recordStart:(id)sender;

@property (strong, nonatomic) SFSpeechRecognizer *speechRecognizer;
@property (strong, nonatomic) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (strong, nonatomic) SFSpeechRecognitionTask *recognitionTask;
@property (strong, nonatomic) AVAudioEngine *audioEngine;

@property (strong, nonatomic) ContextualStringsDataSource *contextStrings;
@property (strong, nonatomic) UIViewPropertyAnimator *animator;
@property (weak, nonatomic) IBOutlet UIView *rectangle;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:@"en-US"]];
    self.speechRecognizer.delegate = self;
    
    self.contextStrings = [[ContextualStringsDataSource alloc] init];
    
    self.audioEngine = [[AVAudioEngine alloc] init];
    self.recordButtton.enabled = NO;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.animator = [[UIViewPropertyAnimator alloc] initWithDuration:0.2f curve:UIViewAnimationCurveEaseOut animations:^{
        self.rectangle.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
    }];
    self.destinationTextView.text = @"";
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    self.recordButtton.enabled = YES;
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied:
                    self.recordButtton.enabled = NO;
                    [self.recordButtton setTitle:@"Access Denied" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                    self.recordButtton.enabled = NO;
                    [self.recordButtton setTitle:@"Access Restricted" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    self.recordButtton.enabled = NO;
                    [self.recordButtton setTitle:@"Not Yet Authorized" forState:UIControlStateDisabled];
                    break;
                default:
                    break;
            }
            [self recordStart:nil];
        }];
    }];
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    [self.animator startAnimation];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self recordStop:nil];
    AudioServicesPlaySystemSound (kSystemSoundID_Vibrate);
    
    [super viewWillDisappear:animated];
}

-(CGSize)preferredContentSize
{
    return CGSizeMake(300, 300);
}

-(void)startRecording
{
    if (self.recognitionTask) {
        [self.recognitionTask cancel];
        self.recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setMode:AVAudioSessionModeMeasurement error:nil];
    [audioSession setActive:YES error:nil];
    
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    SFSpeechAudioBufferRecognitionRequest *recognitionReq = self.recognitionRequest;
    
    recognitionReq.shouldReportPartialResults = YES;
    
    recognitionReq.contextualStrings = self.contextStrings.contextualStrings;
    
    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:recognitionReq resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = NO;
        NSString *myResult = result.bestTranscription.formattedString;
        
        
        if (result) {
            self.textView.text = myResult;
            isFinal = result.final;
        }
        
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            
            self.recognitionRequest = nil;
            self.recognitionTask = nil;
            
            self.recordButtton.enabled = YES;
            [self.recordButtton setTitle:@"Start Recording" forState:UIControlStateNormal];
            [[MyStringTokenizer sharedInstance] processString:myResult outTextView:self.destinationTextView];
        }
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
        [self processBuffer:buffer];
            }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:nil];
    
    self.textView.text = @"(I'm listening)";
}

-(void)processBuffer:(AVAudioPCMBuffer *)buffer
{
    const vDSP_Stride stride = buffer.stride;
    float output;
    vDSP_measqv(buffer.floatChannelData[0], stride, &output, buffer.frameLength);
//    NSLog(@"Mean = %f", output *10000.f);
    __weak typeof (self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [weakSelf.animator addAnimations:^{
            weakSelf.rectangle.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1000*output, 1000*output);
        }];
        if (![self.animator isRunning]) {
            [self.animator startAnimation];
        }
    });

}

-(void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available
{
    if (available) {
        self.recordButtton.enabled = NO;
        [self.recordButtton setTitle:@"Recognition not available" forState:UIControlStateDisabled];
    } else {
        self.recordButtton.enabled = YES;
        [self.recordButtton setTitle:@"Start Recording" forState:UIControlStateNormal];
    }
}


- (IBAction)recordStop:(id)sender {
    if ([self.audioEngine isRunning]) {
        [self.audioEngine stop];
        [self.recognitionRequest endAudio];
        self.recordButtton.enabled = NO;
        [self.recordButtton setTitle:@"Stopping" forState:UIControlStateDisabled];
    }
}


- (IBAction)recordStart:(id)sender {
    if (![self.audioEngine isRunning]) {
        [self startRecording];
        [self.recordButtton setTitle:@"Stop Recording" forState:UIControlStateNormal];
    }
}
@end
