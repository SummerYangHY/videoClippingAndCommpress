//
//  ViewController.m
//  videoClippingAndCommpress
//
//  Created by Summer on 2019/10/16.
//  Copyright © 2019 Summer. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "SDAVAssetExportSession.h"
#define CompressionVideoPaht [NSHomeDirectory() stringByAppendingFormat:@"/tmp"]
@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
//视频的路径
@property(nonatomic, strong) NSString * SelectvideoPath;
//视屏的url
@property(nonatomic, strong) NSURL * SelectvideoUrl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton * startButton = [[UIButton alloc]initWithFrame:CGRectMake(150, 200, 100, 80)];
    [startButton setTitle:@"开始录制" forState:UIControlStateNormal];
    [startButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    startButton.backgroundColor = [UIColor redColor];
    [startButton addTarget:self action:@selector(StartRecordingButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
}

-(void)StartRecordingButtonClick:(UIButton *)btn{
    UIImagePickerController *  _takeShotPickView = [[UIImagePickerController alloc] init];
    _takeShotPickView.delegate = self;
    _takeShotPickView.sourceType = UIImagePickerControllerSourceTypeCamera;//将这个类型设置为照相机中获取信息
    _takeShotPickView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    _takeShotPickView.allowsEditing = YES;
    _takeShotPickView.videoQuality  = UIImagePickerControllerQualityTypeHigh;
    _takeShotPickView.mediaTypes = @[(NSString *)kUTTypeMovie,(NSString *)kUTTypeImage];
    _takeShotPickView.videoMaximumDuration = 30;
    //            _takeShotPickView.cameraOverlayView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
//    self.tZImagePickerVc.modalPresentationStyle = 0;
    [self presentViewController:_takeShotPickView animated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString * type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.movie"]) {
        NSString *moviePath = [[info objectForKey:
                                UIImagePickerControllerMediaURL] path];
        float  end = [[info objectForKey:@"_UIImagePickerControllerVideoEditingEnd"] floatValue];
        float start = [[info objectForKey:@"_UIImagePickerControllerVideoEditingStart"] floatValue];
        if (start == 0 && end == 0) {
            self.SelectvideoUrl = [NSURL fileURLWithPath:moviePath];
            self.SelectvideoPath = moviePath;
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
                UISaveVideoAtPathToSavedPhotosAlbum ( moviePath, nil, nil, nil);
            }
            [self CompressedvideoWithPath:moviePath];
        }else{
            [self tailoringVideowith:moviePath WithStartTime:start withEnd:end];
        }
    }
   
}


//压缩视频
-(void)CompressedvideoWithPath:(NSString *)moviePath{
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];// 用时间, 给文件重新命名, 防止视频存储覆盖,
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    NSString *bakPath = [CompressionVideoPaht stringByAppendingPathComponent:[NSString stringWithFormat:@"outputJFVideo-%@.mov", [formater stringFromDate:[NSDate date]]]];
    AVAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:moviePath] options:nil];
    
    
    NSArray *tracks = [avAsset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack;
    float width = 0.0;
    float heigth = 0.0;
    if([tracks count] > 0) {
       videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;//这里的矩阵有旋转角度，转换一下即可
        if (t.b == 1 && t.c == -1 ) {
          width = videoTrack.naturalSize.height;
            heigth = videoTrack.naturalSize.width;
        }else{
            width = videoTrack.naturalSize.width;
            heigth = videoTrack.naturalSize.height;
        }
        NSLog(@"=====hello  width:%f===height:%f",width,heigth);//宽高
    }
    
    SDAVAssetExportSession *encoder = [SDAVAssetExportSession.alloc initWithAsset:avAsset];
    encoder.outputFileType = AVFileTypeMPEG4;
    encoder.outputURL = [NSURL fileURLWithPath:bakPath];
    if (width>heigth) {
        encoder.videoSettings = @{
            AVVideoCodecKey: AVVideoCodecTypeH264,
                                  AVVideoWidthKey: @1280,
                                  AVVideoHeightKey: @720,
                                  AVVideoCompressionPropertiesKey: @{
                                          AVVideoAverageBitRateKey: @2000000,
                                          AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                                          },
                                  };
    }else{
        encoder.videoSettings = @{
            AVVideoCodecKey: AVVideoCodecTypeH264,
                                  AVVideoWidthKey: @720,
                                  AVVideoHeightKey: @1280,
                                  AVVideoCompressionPropertiesKey: @{
                                          AVVideoAverageBitRateKey: @2000000,
                                          AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                                          },
                                  };
    }
    
    encoder.audioSettings = @{
                              AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                              AVNumberOfChannelsKey: @2,
                              AVSampleRateKey: @44100,
                              AVEncoderBitRateKey: @128000,
                              };
    
    [encoder exportAsynchronouslyWithCompletionHandler:^
     {
         if (encoder.status == AVAssetExportSessionStatusCompleted)
         {
             
             NSLog(@"Video export cancelled");
            
         }
         else if (encoder.status == AVAssetExportSessionStatusCancelled)
         {
             NSLog(@"Video export cancelled");
         }
         else
         {
             NSLog(@"Video export failed with error: %@ (%ld)", encoder.error.localizedDescription, (long)encoder.error.code);
         }
     }];
    
}

//剪辑视频
-(void)tailoringVideowith:(NSString *)moviePath WithStartTime:(float)starttime withEnd:(float)end{
    
    AVAsset *anAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:moviePath]];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                               initWithAsset:anAsset presetName:AVAssetExportPresetHighestQuality];
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];// 用时间, 给文件重新命名, 防止视频存储覆盖,
        [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
        NSString *backPath = [CompressionVideoPaht stringByAppendingPathComponent:[NSString stringWithFormat:@"tailoringoutputJFVideo-%@.mov", [formater stringFromDate:[NSDate date]]]];
        exportSession.outputURL = [NSURL fileURLWithPath:backPath];
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    exportSession.canPerformMultiplePassesOverSourceMediaData = YES;
        CMTime start = CMTimeMakeWithSeconds(starttime, anAsset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(end-starttime, anAsset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        exportSession.timeRange = range;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{

            switch ([exportSession status]) {
                case AVAssetExportSessionStatusCompleted:
                    self.SelectvideoUrl = [NSURL fileURLWithPath:backPath];
                    self.SelectvideoPath = backPath;
                    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (backPath)) {
                        UISaveVideoAtPathToSavedPhotosAlbum ( backPath, nil, nil, nil);
                    }
                    [self CompressedvideoWithPath:backPath];
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Export canceled");
                    break;
                default:
                    break;
            }
        }];


}


@end
