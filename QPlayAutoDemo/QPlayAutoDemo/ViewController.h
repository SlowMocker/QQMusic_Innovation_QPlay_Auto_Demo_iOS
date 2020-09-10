//
//  ViewController.h
//  QPlayAutoDemo
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NormalPageSize  (30)
#define ID_GO_BACK @"GO_BACK"
#define ID_SEARCH @"SEARCH"

static NSString * const App_ID = @"118";//QQ音乐申请的
static NSString * const App_PrivateKey = @"MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAN4whoWuL1M7gYZRUs/pMCkPlyrm9coqgTwMoOYmjpFWfiwU6rJiKVpMMKcTq97jw1XVeTdamnIg/Ds4tFW+hm1P8HN+f+LJ3ZLFoxwc0jhKKrKMDXP8E2vgZnMmdQJzuK2SVKEjgasS6k7sqrVMqZfBW4qV2X/MrFDAuiL7V5K/AgMBAAECgYAIBXx1ywoOWTGd5cW1l9eTQ+rTM69f8xTjVBli9bVj7dl0QfUPJ5gSmHmRLpaf310n9iMAKpc005gHk05/Yfd8XZCF9cmj02fHHldCQezNu7D7OYCfFhu+Qs3/ETXdKBZjq+IXLLPgFzxVk18tq1JU4K00eGn0eYSSteN0AKOlsQJBAPglc2fqZpGzdapK2b7jb2VTpKnyLlVgri+Wa37ALj8GAsoBQ+bvAWHibElQDGGOL8L2ZqSk74sk/03z/wjMkoMCQQDlOMQcr7YZ6VqNITqqNO9b/6Nc0kgrQtKfQac6G5QoMib3T1rFOTRIds9pD6xToK+6pzwA9NiXG/WlLV/hRNoVAkEAwW0H6U+Ihjg6FvTjiG1mbrhlWWeDAGAtRsDcp9+L7Op1kBquYDubez5wpDD2hbC8wB8rYVmDs5WyQIRaHvS/mwJBAIMrk9YSmvOC/OVsEYUbG6oaxOI2F0RiTeMCj+6Jn6PM5014pKndzVR2YMRvSp7kggse7hBiDJuUTWLDb22al+0CQEasXTReC4vUCK1tSNOWLy35gifvrUjhA1JcqR2A/ES6hCXvYLdaU4AglB7l4t9Wxjx0//yXZamLGr/oIVtzv/c=";//RSA私钥

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *albumImgView;
@property (weak, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *singerLabel;
@property (weak, nonatomic) IBOutlet UIButton *btnPlayPause;
@property (weak, nonatomic) IBOutlet UILabel *logLabel;
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIButton *btnPlayMode;
@property (weak, nonatomic) IBOutlet UIButton *btnLove;
@property (weak, nonatomic) IBOutlet UIButton *btnMore;



- (IBAction)onClickStart:(id)sender;
- (IBAction)onClickPlayPause:(id)sender;
- (IBAction)onClickPlayPrev:(id)sender;
- (IBAction)onClickPlayNext:(id)sender;
- (IBAction)onClickPlayMode:(id)sender;
- (IBAction)onClickLove:(id)sender;
- (IBAction)onSliderSeek:(id)sender;
- (IBAction)onClickMore:(id)sender;

@end

