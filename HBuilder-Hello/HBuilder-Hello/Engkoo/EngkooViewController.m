//
//  EngkooViewController.m
//  EngkooViewController
//
//  Created by SunXP on 17/4/28.
//  Copyright © 2017年 L. All rights reserved.
//

#import "EngkooViewController.h"
#import "./WebViewJavascriptBridge/WebViewJavascriptBridge.h"
#import <AVFoundation/AVFoundation.h>

@interface EngkooViewController (){
    AVAudioRecorder *_audioRecorder;
}
@property (nonatomic,strong) WKWebView* webView;
@property WebViewJavascriptBridge * bridge;
@end

@implementation EngkooViewController

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
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    // 创建设置对象
    WKPreferences *preference = [[WKPreferences alloc]init];
    //最小字体大小 当将javaScriptEnabled属性设置为NO时，可以看到明显的效果
    preference.minimumFontSize = 0;
    //设置是否支持javaScript 默认是支持的
    preference.javaScriptEnabled = YES;
    // 在iOS上默认为NO，表示是否允许不经过用户交互由javaScript自动打开窗口
    preference.javaScriptCanOpenWindowsAutomatically = YES;
    config.preferences = preference;
    
    // 是使用h5的视频播放器在线播放, 还是使用原生播放器全屏播放
    config.allowsInlineMediaPlayback = YES;
    //设置视频是否需要用户手动播放  设置为NO则会允许自动播放
    config.requiresUserActionForMediaPlayback = YES;
    //设置是否允许画中画技术 在特定设备上有效
    config.allowsPictureInPictureMediaPlayback = YES;
    //设置请求的User-Agent信息中应用程序名称 iOS9后可用
    //config.applicationNameForUserAgent = @"ChinaDailyForiPad";
    
    WKWebView* webView = [[WKWebView alloc] initWithFrame:CGRectMake(0.0f, 80.0f, self.view.frame.size.width, self.view.frame.size.height - 40.0f) configuration:config];
    self.webView.UIDelegate = self;
    [self.view addSubview:webView];
    
    [WebViewJavascriptBridge enableLogging];
    
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:webView];
    [self.bridge setWebViewDelegate:self];
    
    [self.bridge registerHandler:@"Log_In" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"Login called: %@", data);
        responseCallback([self.engkooParameter objectForKey:@"accessToken"]);
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
    
    NSURL* url = [NSURL URLWithString:[self.engkooParameter objectForKey:@"englishAssistantScenarioLessonUrl"]];//创建URL
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