//
//  JimViewController.m
//  testDEMO
//
//  Created by SunXP on 17/4/28.
//  Copyright © 2017年 L. All rights reserved.
//

#import "JimViewController.h"
#import "./WebViewJavascriptBridge/WebViewJavascriptBridge.h"
#import <AVFoundation/AVFoundation.h>

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface JimViewController (){
    AVAudioRecorder *_audioRecorder;
}
@property WebViewJavascriptBridge * bridge;
@end



@implementation JimViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.title = @"综合支付";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    //工具条
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 40.0f, self.view.frame.size.width, 40.0f)];
    toolbar.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *closeditem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(finish)];
    //将按钮单元都添加到数组中
    NSArray *items = @[closeditem];
    //设置导航栏上的按钮单元
    [toolbar setItems:items animated:YES];
    [self.view addSubview:toolbar];
    
    //添加webview
    UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0f, 80.0f, self.view.frame.size.width, self.view.frame.size.height - 40.0f)];
    webView.delegate = self;
    
    webView.scalesPageToFit = YES; //自动对页面进行缩放以适应屏幕
    webView.detectsPhoneNumbers = YES;//自动检测网页上的电话号码，单击可以拨打
    [webView setMediaPlaybackRequiresUserAction:NO];
    
    [self.view addSubview:webView];
    
    [WebViewJavascriptBridge enableLogging];
    
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:webView];
    [self.bridge setWebViewDelegate:self];
    
    [self.bridge registerHandler:@"Log_In" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        
        NSURL * url =[NSURL URLWithString:@"https://app-dev.mtutor.engkoo.com/proxy/oauth/login"];
        NSMutableURLRequest *req= [NSMutableURLRequest requestWithURL:url];
        req.HTTPMethod=@"POST"; //请求方设置为POST ⚠️注意要区分大小写
        //请求的参数
        req.HTTPBody = [@"grant_type=XueLe&id=useridxxxx&secret=2FDA0803-2202-40EB-824D-28CDDC3A2FE4" dataUsingEncoding:NSUTF8StringEncoding];
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
            //请求返回值
            NSString *accessToken = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",accessToken);
            
            responseCallback(accessToken);
        }];
    }];
    
    [self.bridge registerHandler:@"startRecord" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"startRecord called: %@", data);
        
        [self startRecordNotice];
                
        responseCallback(@"");
    }];
    
    [self.bridge registerHandler:@"stopRecord" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"stopRecord called: %@", data);
        
        [self stopRecordNotice];
        
        NSData *wavData = [NSData dataWithContentsOfFile:self.getFilePath];
        NSString *returnData = [self Base64StrWithWAVData:wavData];
                
        responseCallback(returnData);
    }];
    
    NSURL* url = [NSURL URLWithString:@"https://app-dev.mtutor.engkoo.com/dist/app-scenario-lesson/?origin=ios-xinfangxiang"];//创建URL
    NSURLRequest* request = [NSURLRequest requestWithURL:url];//创建NSURLRequest
    [webView loadRequest:request];//加载
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad");
}

- (void)disableSafetyTimeout {
    [self.bridge disableJavscriptAlertBoxSafetyTimeout];
}

- (void)callHandler:(id)sender {
    id data = @{ @"greetingFromObjC": @"Hi there, JS!" };
    [_bridge callHandler:@"testJavascriptHandler" data:data responseCallback:^(id response) {
        NSLog(@"testJavascriptHandler responded: %@", response);
    }];
}

- (NSString *)getFilePath {
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *urlPath = [path stringByAppendingPathComponent:@"temp.wav"];
    
    return urlPath;
}

-(NSDictionary *)getAudioSetting{
    NSMutableDictionary* recordSetting = [NSMutableDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithFloat:16000], AVSampleRateKey,
    [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
    [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
    [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
    [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
    [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey, nil];
    
    return recordSetting;
}

-(AVAudioRecorder *)audioRecorder{
    if (!_audioRecorder) {
        //创建录音文件保存路径
        NSURL *url=[NSURL URLWithString:self.getFilePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        
        _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}

-(void)deleteOldRecordFile{
    NSFileManager* fileManager=[NSFileManager defaultManager];
    
    NSLog(@"存在");
    BOOL blDele= [fileManager removeItemAtPath:self.getFilePath error:nil];
    if (blDele) {
        NSLog(@"删除成功");
    }else {
        NSLog(@"删除失败");
    }
}

- (void)startRecordNotice{
 
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder stop];
    }
   
    [self deleteOldRecordFile];  //如果不删掉，会在原文件基础上录制；虽然不会播放原来的声音，但是音频长度会是录制的最大长度。
    
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    
    if (![self.audioRecorder isRecording]) {//0--停止、暂停，1-录制中
        [self.audioRecorder record];//首次使用应用时如果调用record方法会询问用户是否允许使用麦克风
    }
}

- (void)stopRecordNotice{
 
    NSLog(@"----------结束录音----------");
    
    [self.audioRecorder stop];
}

- (NSString *)Base64StrWithWAVData:(NSData *)data{
    if (!data) {
        NSLog(@"Mp3Data 不能为空");
        return nil;
    }
    //    NSString *str = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *str = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    return str;
}

- (void)finish{
    NSLog(@"----------关闭页面----------");
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
