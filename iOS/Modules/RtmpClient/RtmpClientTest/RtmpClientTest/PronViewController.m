//
//  PronViewController.m
//  RtmpClientTest
//
//  Created by Max on 2020/10/23.
//  Copyright © 2020 net.qdating. All rights reserved.
//

#import "PronViewController.h"
#import "AppDelegate.h"
#import "FileDownloadManager.h"

@interface PronViewController ()
@property (weak) IBOutlet StreamWebView *webView;
@property (weak) IBOutlet UIButton *downloadBtn;
@property (weak) IBOutlet UITextView *downloadTextView;

@property (strong) NSMutableDictionary *urlDict;
@property (strong) NSMutableDictionary *urlCheckDict;

@property (weak) IBOutlet UITextField *textFieldAddress;
@property (strong) NSURLSession *session;

@property (strong) NSMutableDictionary* taskURLDict;

@end

@implementation PronViewController
- (void)dealloc {
    [[FileDownloadManager manager] removeDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // 界面处理
    self.title = @"Browser";
    self.urlDict = [NSMutableDictionary dictionary];
    self.urlCheckDict = [NSMutableDictionary dictionary];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"<Back" style:UIBarButtonItemStylePlain target:self action:@selector(backAction:)];

    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    self.webView.hidden = YES;
    self.downloadBtn.enabled = NO;
    
    self.taskURLDict = [NSMutableDictionary dictionary];
    
    NSString *urlString = @"http://www.baidu.com";
    self.textFieldAddress.text = urlString;
    
    [[FileDownloadManager manager] addDelegate:self];
    
    //    [self goAction:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (IBAction)backAction:(id)sender {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)goAction:(UIButton *)sender {
    self.urlDict = [NSMutableDictionary dictionary];
    self.urlCheckDict = [NSMutableDictionary dictionary];
    self.downloadBtn.enabled = NO;

    NSString *urlString = self.textFieldAddress.text;
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
    [self.webView loadRequest:request];
}

- (IBAction)viewAction:(UIButton *)sender {
    self.webView.hidden = !self.webView.hidden;
    self.downloadTextView.hidden = !self.downloadTextView.hidden;
}

- (IBAction)checkDownloadURL {
    [self.webView evaluateJavaScript:@"quality_480p"
                   completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                       self.urlCheckDict[@"480P"] = @(1);
                       if (!error) {
                           NSLog(@"PronViewController::checkDownloadURL( [480P] ), %@", response);
                           self.urlDict[@"480P"] = response;
                       }
                       [self check];
                   }];
    [self.webView evaluateJavaScript:@"quality_720p"
                   completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                       self.urlCheckDict[@"720P"] = @(1);
                       if (!error) {
                           NSLog(@"PronViewController::checkDownloadURL( [720P] ), %@", response);
                           self.urlDict[@"720P"] = response;
                       }
                       [self check];
                   }];
    [self.webView evaluateJavaScript:@"quality_1080p"
                   completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                       self.urlCheckDict[@"1080P"] = @(1);
                       if (!error) {
                           NSLog(@"PronViewController::checkDownloadURL( [1080P] ), %@", response);
                           self.urlDict[@"1080P"] = response;
                       }
                       [self check];
                   }];
}

- (void)check {
    if (self.urlCheckDict.count == 3) {
        self.downloadBtn.enabled = YES;
    }
}

- (IBAction)cleanAction:(UIButton *)sender {
    [[FileDownloadManager manager] cancel];
}

- (IBAction)downloadAction:(UIButton *)sender {
    NSString *urlString = self.urlDict[@"1080P"];
    if (urlString.length == 0) {
        urlString = self.urlDict[@"720P"];
    }
    if (urlString.length == 0) {
        urlString = self.urlDict[@"480P"];
    }

    NSLog(@"PronViewController::downloadAction(), %@", urlString);
    if ( urlString.length > 0) {
        NSString *tips = [NSString stringWithFormat:@"[Download] %@", urlString];
        NSMutableAttributedString *line = [[NSMutableAttributedString alloc] initWithString:tips];
        [line addAttributes:@{
            NSForegroundColorAttributeName:[UIColor blueColor]
        } range:NSMakeRange(0, 10)];
        @synchronized(self) {
            self.taskURLDict[urlString] = line;
        }
        [self changeDownloadStatus];
        [[FileDownloadManager manager] downloadURL:urlString];
    }
}

- (void)changeDownloadStatus {
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] init];
//    NSMutableString* mutString = [NSMutableString string];
    for(NSString* key in self.taskURLDict) {
//        [mutString appendFormat:@"%@\n", self.taskURLDict[key]];
        NSAttributedString *line = [[NSAttributedString alloc] initWithAttributedString:self.taskURLDict[key]];
        [attrString appendAttributedString:line];
        [attrString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
//    self.downloadTextView.text = mutString;
    self.downloadTextView.attributedText = attrString;
    
}

- (NSString *)readableSize:(NSInteger)size {
    NSString *unit = @"B";
    if (size / 1024 > 1) {
        size /= 1024;
        unit = @"K";

        if (size / 1024 > 1) {
            size /= 1024;
            unit = @"M";
        }

        if (size / 1024 > 1) {
            size /= 1024;
            unit = @"G";
        }
    }
    NSString *result = [NSString stringWithFormat:@"%ld%@", size, unit];
    return result;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {

    NSString* urlString = downloadTask.currentRequest.URL.absoluteString;
    float percent = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    NSString* percentString = [NSString stringWithFormat:@"(%@/%@)%.0f%%", [self readableSize:totalBytesWritten], [self readableSize:totalBytesExpectedToWrite], percent * 100];
    NSString *tips = [NSString stringWithFormat:@"[Download] %@ - %@", downloadTask.response.suggestedFilename, percentString];
    NSMutableAttributedString *line = [[NSMutableAttributedString alloc] initWithString:tips];
    [line addAttributes:@{
        NSForegroundColorAttributeName:[UIColor blueColor]
    } range:NSMakeRange(0, 10)];
    @synchronized(self) {
        if (urlString.length > 0) {
            self.taskURLDict[urlString] = line;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self changeDownloadStatus];
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"PronViewController::didResumeAtOffset(), (%@/%@)", [self readableSize:fileOffset], [self readableSize:expectedTotalBytes]);
    
    NSString* urlString = downloadTask.currentRequest.URL.absoluteString;
    float percent = 1.0 * fileOffset / expectedTotalBytes;
    NSString* percentString = [NSString stringWithFormat:@"(%@/%@)%.0f%%", [self readableSize:fileOffset], [self readableSize:expectedTotalBytes], percent * 100];
    NSString *tips = [NSString stringWithFormat:@"[Download] %@ - %@", downloadTask.response.suggestedFilename, percentString];
    NSMutableAttributedString *line = [[NSMutableAttributedString alloc] initWithString:tips];
    [line addAttributes:@{
        NSForegroundColorAttributeName:[UIColor blueColor]
    } range:NSMakeRange(0, 10)];
    @synchronized(self) {
        if (urlString.length > 0) {
            self.taskURLDict[urlString] = line;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self changeDownloadStatus];
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *ouputDir = [NSString stringWithFormat:@"%@/download", cacheDir];
    NSString *ouputFile = [NSString stringWithFormat:@"%@/%@", ouputDir, downloadTask.response.suggestedFilename];

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    [fm createDirectoryAtPath:ouputDir withIntermediateDirectories:YES attributes:nil error:&error];
    [fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:ouputFile] error:&error];
    NSLog(@"PronViewController::didFinishDownloadingToURL(), %@", downloadTask.response.suggestedFilename);
    self.title = self.webView.title;
    
    NSString* urlString = downloadTask.currentRequest.URL.absoluteString;
    NSString *tips = [NSString stringWithFormat:@"[Finish] %@", downloadTask.response.suggestedFilename];
    NSMutableAttributedString *line = [[NSMutableAttributedString alloc] initWithString:tips];
    [line addAttributes:@{
        NSForegroundColorAttributeName:[UIColor greenColor]
    } range:NSMakeRange(0, 8)];
    @synchronized(self) {
        if (urlString.length > 0) {
            self.taskURLDict[urlString] = line;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self changeDownloadStatus];
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSLog(@"PronViewController::didCompleteWithError(), %@", error);
    if (error) {
        NSString* urlString = task.currentRequest.URL.absoluteString;
        NSString *tips = [NSString stringWithFormat:@"[Error] %@", task.response.suggestedFilename];
        NSMutableAttributedString *line = [[NSMutableAttributedString alloc] initWithString:tips];
        [line addAttributes:@{
            NSForegroundColorAttributeName:[UIColor redColor]
        } range:NSMakeRange(0, 7)];
        @synchronized(self) {
            if (urlString.length > 0) {
                self.taskURLDict[urlString] = line;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self changeDownloadStatus];
        });
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    NSLog(@"PronViewController::didBecomeInvalidWithError(), %@", error);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSLog(@"PronViewController::decidePolicyForNavigationAction()");
    decisionHandler(WKNavigationActionPolicyAllow);
    self.textFieldAddress.text = navigationAction.request.URL.absoluteString;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"PronViewController::didStartProvisionalNavigation()");
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSLog(@"PronViewController::decidePolicyForNavigationResponse()");
    decisionHandler(WKNavigationResponsePolicyAllow);
    [self checkDownloadURL];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"PronViewController::didFailProvisionalNavigation(), error: %@", error);
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@"PronViewController::didCommitNavigation()");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"PronViewController::didFinishNavigation()");
    [self checkDownloadURL];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"PronViewController::didFailNavigation(), error:%@", error);
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    NSLog(@"PronViewController:webViewWebContentProcessDidTerminate()");
}

#pragma mark - 输入回调
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL result = YES;
    [textField resignFirstResponder];
    return result;
}

#pragma mark - 处理键盘回调
- (void)moveInputBarWithKeyboardHeight:(CGFloat)height withDuration:(NSTimeInterval)duration {
    //    BOOL bFlag = NO;

    // Ensures that all pending layout operations have been completed
    [self.view layoutIfNeeded];

    if (height != 0) {
        // 弹出键盘
        
    } else {
        // 收起键盘
    }

    [UIView animateWithDuration:duration
                     animations:^{
                         // Make all constraint changes here, Called on parent view
                         [self.view layoutIfNeeded];

                     }
                     completion:^(BOOL finished){

                     }];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];

    [self moveInputBarWithKeyboardHeight:keyboardRect.size.height withDuration:animationDuration];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];

    // 动画收起键盘
    [self moveInputBarWithKeyboardHeight:0.0 withDuration:animationDuration];
}
@end
