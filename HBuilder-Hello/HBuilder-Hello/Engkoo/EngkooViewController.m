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

// status bar height.
#define kStatusBarHeight (IS_iPhoneX ? 44.f : 20.f)
// Navigation bar height.
#define kNavigationBarHeight 44.f
// Tabbar height.
#define kTabbarHeight (IS_iPhoneX ? (49.f+34.f) : 49.f)
// Tabbar safe bottom margin.
#define kTabbarSafeBottomMargin (IS_iPhoneX ? 34.f : 0.f)
// Status bar & navigation bar height.
#define kStatusBarAndNavigationBarHeight (IS_iPhoneX ? 88.f : 64.f)
//判断是否iPhone X
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IOS_11  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.f)
#define IS_iPhoneX (IS_IOS_11 && IS_IPHONE && (MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) >= 375 && MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) >= 812))

@interface EngkooViewController (){
    AVAudioRecorder *_audioRecorder;
}
@property (nonatomic,strong) WKWebView* webView;
@property WebViewJavascriptBridge* bridge;
@property WVJBResponseCallback currentResponseCallback;
@end

@implementation EngkooViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self addToolBar];
    WKWebView* webView = [self addWebView];
    [self addWebViewJavascriptBridge:webView];
    
    NSURL* url = [NSURL URLWithString:[self.engkooParameter objectForKey:@"englishAssistantScenarioLessonUrl"]];//创建URL
    NSURLRequest* request = [NSURLRequest requestWithURL:url];//创建NSURLRequest
    [webView loadRequest:request];//加载
}

-(void)addToolBar{
    //工具条
    NSLog(@"kStatusBarHeight is: %f", kStatusBarHeight);
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, kStatusBarHeight, self.view.frame.size.width, kNavigationBarHeight)];
    toolbar.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *closeditem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(finish)];
    //将按钮单元都添加到数组中
    NSArray *items = @[closeditem];
    //设置导航栏上的按钮单元
    [toolbar setItems:items animated:YES];
    [self.view addSubview:toolbar];
}

- (WKWebView *)addWebView{
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
    
    WKWebView* webView = [[WKWebView alloc] initWithFrame:CGRectMake(0.0f, kStatusBarHeight + kNavigationBarHeight, self.view.frame.size.width, self.view.frame.size.height - kNavigationBarHeight - kStatusBarHeight - kTabbarSafeBottomMargin) configuration:config];
    self.webView.navigationDelegate  = self;
    [self.view addSubview:webView];
    
    return webView;
}

-(void) addWebViewJavascriptBridge:(WKWebView *)webView{
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
        
        NSData *wavData = [NSData dataWithContentsOfFile:self.getAudioFilePath];
        NSString *returnData = [self Base64StrWithWAVData:wavData];
        
        responseCallback(returnData);
    }];
    
    [self.bridge registerHandler:@"chooseImage" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"chooseImage called: %@", data);
        [self takeImage:responseCallback];
    }];
    
    [self.bridge registerHandler:@"shootImage" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"shootImage called: %@", data);
        [self shootImage:responseCallback];
    }];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidStartLoad");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidFinishLoad");
}

- (NSString *)getAudioFilePath {
    
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
        NSURL *url=[NSURL URLWithString:self.getAudioFilePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        
        _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        //_audioRecorder.delegate=self;
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
    BOOL blDele= [fileManager removeItemAtPath:self.getAudioFilePath error:nil];
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
    
    NSString *str = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    return str;
}

- (void)finish{
    NSLog(@"----------关闭页面----------");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)takeImage:(WVJBResponseCallback)responseCallback{
    
    self.currentResponseCallback = responseCallback;
    
    //初始化UIImagePickerController类
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    //全屏幕
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    //判断数据来源为相册
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    //设置代理
    picker.delegate = self;
    //打开相册
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)shootImage:(WVJBResponseCallback)responseCallback{
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO)
        return  ;
    
    self.currentResponseCallback = responseCallback;
    
    //初始化UIImagePickerController类
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    //全屏幕
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    //数据来源
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    // 设置拍摄照片
    picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    // 设置使用手机的前置摄像头。
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    //设置代理
    picker.delegate = self;
    
    //打开
    [self presentViewController:picker animated:YES completion:nil];
}

//选择完成回调函数
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    //获取图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    if(image != nil && self.currentResponseCallback!=nil){
        
        image = [self imageCompressForWidthScale:image targetWidth:400];
        NSData *imageData = [self compressImageQuality:image toByte:50*1024];
        
        NSString * returnData = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        returnData = [returnData stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        returnData = [returnData stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        self.currentResponseCallback(returnData);
        
        self.currentResponseCallback = nil;
    }
}

//用户取消选择
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.currentResponseCallback = nil;
}


//指定宽度按比例缩放
-(UIImage *) imageCompressForWidthScale:(UIImage *)sourceImage targetWidth:(CGFloat)defineWidth{
    
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = defineWidth;
    CGFloat targetHeight = height / (width / targetWidth);
    CGSize size = CGSizeMake(targetWidth, targetHeight);
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    if(CGSizeEqualToSize(imageSize, size) == NO){
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if(widthFactor > heightFactor){
            scaleFactor = widthFactor;
        }
        else{
            scaleFactor = heightFactor;
        }
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        if(widthFactor > heightFactor){
            
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            
        }else if(widthFactor < heightFactor){
            
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(size);
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil){
        
        NSLog(@"scale image fail");
    }
    UIGraphicsEndImageContext();
    return newImage;
}

//压缩图片质量
- (NSData *)compressImageQuality:(UIImage *)image toByte:(NSInteger)maxLength {
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    while (data.length > maxLength && compression > 0) {
        compression -= 0.02;
        data = UIImageJPEGRepresentation(image, compression); // When compression less than a value, this code dose not work
    }
    
    return data;
}
@end
