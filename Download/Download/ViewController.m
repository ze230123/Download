//
//  ViewController.m
//  Download
//
//  Created by 泽i on 2017/5/21.
//  Copyright © 2017年 泽i. All rights reserved.
//

#define URL [NSURL URLWithString:@"http://sw.bos.baidu.com/sw-search-sp/software/d2ad2d0b38c/PlantsVsZombiesSetup.zip"]
#define VIDEO_URL [NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"]

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <NSURLSessionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UILabel *pathLabel;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;


@property (nonatomic, strong) NSDate *date;
@property (nonatomic, assign) int64_t totalBytesWritten;

@property (nonatomic, strong) NSData *resumeData;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark-  NSURLSessionDelegate
//下载完成
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    //获取Downloads文件夹
    NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDownloadsDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    //修改文件名
    NSURL *filename = [documentsDirectoryURL URLByAppendingPathComponent:downloadTask.response.suggestedFilename];
    // 剪切文件
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:filename error:nil];
    NSLog(@"%@",filename.path);
    self.downloadTask = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.titleLabel.text = @"下载完成";
        self.speedLabel.text = @"0KB/s";
        self.pathLabel.text = filename.path;
        self.playBtn.hidden = NO;
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    //计算下载进度
    double progress = (double)totalBytesWritten / totalBytesExpectedToWrite;
    //计算已经下载的大小
    NSString *currentSize = [NSByteCountFormatter stringFromByteCount:totalBytesWritten
                                                           countStyle:NSByteCountFormatterCountStyleMemory];
    //计算总大小
    NSString *totalSize = [NSByteCountFormatter stringFromByteCount:totalBytesExpectedToWrite
                                                         countStyle:NSByteCountFormatterCountStyleMemory];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sizeLabel.text = [NSString stringWithFormat:@"%@/%@",currentSize,totalSize];
        self.progressView.progress = progress;
        self.progressLabel.text = [NSString stringWithFormat:@"%.1f%%",progress*100];
    });

    // 计算下载速度
    NSDate *currentDate = [NSDate date];
    NSTimeInterval interval = [currentDate timeIntervalSinceDate:self.date];

    if (interval >= 1 || totalBytesWritten == totalBytesExpectedToWrite) {

        NSString *speedStr = [NSByteCountFormatter stringFromByteCount:(totalBytesWritten - self.totalBytesWritten)/interval
                                                            countStyle:NSByteCountFormatterCountStyleMemory];
        NSString *speedString = [speedStr stringByAppendingString:@"/s"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.speedLabel.text = speedString;
        });
        self.totalBytesWritten = totalBytesWritten;
        self.date = currentDate;
    }
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    
}

#pragma mark- 下载行为
// 开始下载
- (IBAction)start:(id)sender {
    if (!self.downloadTask) {
        self.downloadTask = [self.session downloadTaskWithURL:VIDEO_URL];
        [self.downloadTask resume];
        self.titleLabel.text = @"开始下载";
    }
}
// 继续下载
- (IBAction)resume:(id)sender {
    if (!self.downloadTask) {
        self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
        [self.downloadTask resume];
        self.titleLabel.text = @"恢复下载";
    }
}
// 暂停下载
- (IBAction)pause:(id)sender {
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        self.resumeData = resumeData;
        self.downloadTask = nil;
    }];
    self.titleLabel.text = @"暂停下载";
    self.speedLabel.text = @"0KB/s";
}

/**
 删除任务及临时文件或已完成文件 此处只实现了删除临时文件
 
 resumeData 读取临时文件名
 http://stackoverflow.com/questions/21895853/how-can-i-check-that-an-nsdata-blob-is-valid-as-resumedata-for-an-nsurlsessiondo?answertab=votes#tab-top
 
 @param sender UIButton
 */
- (IBAction)delete:(id)sender {
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        // 将resumeData 序列化
        NSError *listError = nil;
        NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:resumeData options:NSPropertyListImmutable format:nil error:&listError];
        if (listError) {
            NSLog(@"%@",listError.description);
        }
        // 取得临时文件的名字
        NSString *fileName = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoTempFileName"];
        // 获取 tmp 临时文件夹  拼接临时文件名
        NSString *tmp = [NSTemporaryDirectory() stringByAppendingString:fileName];
        // 删除临时文件
        NSError *fileError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:tmp error:&fileError];
        if (fileError) {
            NSLog(@"%@",fileError.description);
        }
        self.resumeData = nil;
        self.downloadTask = nil;
    }];
    
    self.titleLabel.text = @"删除任务";
    self.progressView.progress = 0;
    self.progressLabel.text = @"";
    self.speedLabel.text = @"0KB/s";
    self.sizeLabel.text = @"--/--";
    self.playBtn.hidden = YES;
}
//播放
- (IBAction)play:(id)sender {
    AVPlayerViewController *videoVC = [[AVPlayerViewController alloc]init];
    videoVC.player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:self.pathLabel.text]];
    [self presentViewController:videoVC animated:YES completion:nil];
    [videoVC.player play];
}

#pragma mark- setter and getter
- (NSURLSession *)session {
    if (_session == nil) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:nil];
    }
    return _session;
}
- (NSDate *)date {
    if (_date == nil) {
        _date = [NSDate date];
    }
    return _date;
}

@end
