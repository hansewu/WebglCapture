//
//  AppDelegate.m
//  WKWebViewTest
//
//  Created by Felix Deimel on 10.06.15.
//  Copyright © 2015 Lemon Mojo - Felix Deimel e.U. All rights reserved.
//

#import "AppDelegate.h"
#import <WebKit/WebKit.h>
#import <WebKit/WKSnapshotConfiguration.h>
//#import <wtf/BlockPtr.h>
//#import <wtf/RetainPtr.h>
//#import "WKWebView+Screenshot.h"
#import "WebViewJavascriptBridge.h"


static NSImage *createNSImageFromBuffer(unsigned char *pBuffer, int width, int height)
{
    unsigned char* pBufferNew           = (unsigned char*)malloc(width*height*4);
    memset(pBufferNew,0,width*height*4);
    //memcpy(pBufferNew,pBuffer,width*height*4);
    for(int i = 0;i < height;i++)
    {
        for(int j = 0;j < width; j++)
        {
            pBufferNew[i*width*4+j*4]   = pBuffer[(height-i-1)*width*4+j*4] * pBuffer[(height-i-1)*width*4+4*j+3]/255.0;
            pBufferNew[i*width*4+j*4+1] = pBuffer[(height-i-1)*width*4+j*4+1] * pBuffer[(height-i-1)*width*4+4*j+3]/255.0;
            pBufferNew[i*width*4+j*4+2] = pBuffer[(height-i-1)*width*4+j*4+2] * pBuffer[(height-i-1)*width*4+4*j+3]/255.0;
            pBufferNew[i*width*4+j*4+3] = pBuffer[(height-i-1)*width*4+4*j+3];
        }
    }
    CGColorSpaceRef colorSpace      = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext      = CGBitmapContextCreate(pBufferNew,width,height,8,width*4,colorSpace,kCGImageAlphaPremultipliedLast);
    CGImageRef imageRef             = CGBitmapContextCreateImage(bitmapContext);
    NSImage* image                  = [[NSImage alloc]initWithCGImage:imageRef size:NSMakeSize(width,height)];
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    free(pBufferNew);
    pBufferNew = nil;
    
    return image;
}

@interface AppDelegate ()

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTabView *tabView;
@property (assign) IBOutlet NSImageView *imageView;

@end

@implementation AppDelegate {
    NSMutableArray *m_webViews;
    WebViewJavascriptBridge* _WKBridge;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    m_webViews = [[NSMutableArray alloc] init];
    [self.imageView registeredDraggedTypes];
    WKWebViewConfiguration* config = [[WKWebViewConfiguration alloc] init] ;//autorelease];
    WKPreferences* prefs = config.preferences;
    
    prefs.javaScriptEnabled = YES;
    prefs.javaEnabled = YES;
    prefs.javaScriptCanOpenWindowsAutomatically = YES;
    prefs.plugInsEnabled = YES;
    
    [m_webViews addObject:[self addWebViewWithConfig:config url:@"https://zengxiangliang.github.io/three_text/"//@"https://sanonz.github.io/2018/offscreen-render-target-with-three-js/"
toView:[self.tabView.tabViewItems[0] view]]];
//    [m_webViews addObject:[self addWebViewWithConfig:config url:@"http://www.javatester.org/" toView:[self.tabView.tabViewItems[1] view]]];
//    [m_webViews addObject:[self addWebViewWithConfig:config url:@"http://www.audiotool.com/app" toView:[self.tabView.tabViewItems[2] view]]];
//    [m_webViews addObject:[self addWebViewWithConfig:config url:@"http://www.medicalrounds.com/quicktimecheck/troubleshooting.html" toView:[self.tabView.tabViewItems[3] view]]];
}

- (WKWebView*)addWebViewWithConfig:(WKWebViewConfiguration*)config url:(NSString*)url toView:(NSView*)view
{
    WKWebView* v = [[WKWebView alloc] initWithFrame:view.bounds configuration:config]; //autorelease];
    v.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    

    //v.navigationDelegate = self;
    
    [view addSubview:v];
   
  [self configureWKWebview:v];
//    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//    [v loadRequest:req];
    
    return v;
}

- (IBAction)buttonCaptureScreenshot_action:(id)sender
{
    WKWebView* wkWebView = [m_webViews objectAtIndex:[self.tabView indexOfTabViewItem:self.tabView.selectedTabViewItem]];
    
    //[wkWebView _test_waitForDidFinishNavigation];
    //[wkWebView _killWebContentProcessAndResetState];



    [self captureScreenshotAsyncInWKWebView:wkWebView];
}

- (void)captureScreenshotAsyncInWKWebView:(WKWebView*)wkWebView
{
    WKSnapshotConfiguration* snapshotConfiguration = [[WKSnapshotConfiguration alloc] init];

    [snapshotConfiguration setRect:wkWebView.frame]; //
    [snapshotConfiguration setSnapshotWidth:@(wkWebView.bounds.size.width)];
    
    [wkWebView takeSnapshotWithConfiguration:snapshotConfiguration completionHandler:^(NSImage *snapshotImage, NSError *error) {
        self.imageView.image = snapshotImage;
            //EXPECT_NULL(snapshotImage);
            //EXPECT_WK_STREQ(@"WKErrorDomain", error.domain);

            //isDone = true;
        }];
   /* [wkWebView captureScreenshotWithCompletionHandler:^(NSImage *screenshot) {
        self.imageView.image = screenshot;
    }];*/
}


- (void)configureWKWebview:(WKWebView*)_WKWebView
{
    // Create Bridge
    _WKBridge = [WebViewJavascriptBridge bridgeForWebView:_WKWebView];
    
    [_WKBridge registerHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called:");
        
        //NSUInteger count = [data length];
        //NSString *string = [data ];
        NSUInteger count = [data count];
      //  NSArray *allValue = [data allValues];
        //NSMutableString
        unsigned char *pbuffer =  (unsigned char *)malloc(count);
        for(int i=0; i< count; i++)
        {
            id dataValue = [data objectForKey:[[NSNumber numberWithInt:i] stringValue]] ;
            //pbuffer[i] = [data  characterAtIndex:[NSNumber numberWithInt:i]];
            pbuffer[i] = [dataValue unsignedCharValue];//  [data class] objectForKey:(__bridge id)i];
            if(i==0)
            NSLog(@"%d %d", i, pbuffer[i]);
        }

        
        NSImage *image = createNSImageFromBuffer(pbuffer, 500, 500);//(__bridge void *)[[data class] bytes], 300, 300); //(__bridge void *)
        self.imageView.image = image;
        free(pbuffer);
        //NSLog(@"testObjcCallback called: %@", data);
        //unsigned char *datap = (unsigned char *)data;
       // data[0] =100;
        //responseCallback(@"Response from testObjcCallback");
        
    }];
    
 
    
    // Load Page
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"index1" ofType:@"html"];
    //NSString* html = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    //NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    //[_WKWebView loadHTMLString:html baseURL:baseURL];
    
    NSURL *fileURL = [NSURL fileURLWithPath:htmlPath];
    NSString* basePath = [htmlPath stringByDeletingLastPathComponent];
    basePath = [basePath stringByAppendingString:@"/"];
    [_WKWebView loadFileURL:fileURL allowingReadAccessToURL:[NSURL fileURLWithPath:basePath isDirectory:YES]];
    
}

- (IBAction)buttonGetDataWithScript_action:(id)sender
{
    [_WKBridge callHandler:@"testJavascriptHandler" data:@{ @"foo":@"before ready" } responseCallback:^(id data) {
        NSLog(@"testJavascriptHandler responseCallback called:");
        
        NSData *data1 = [[NSData data] initWithBase64EncodedString:data options:0];
        NSUInteger count = [data1 length];
        unsigned char *pbuffer =  (unsigned char *)malloc(count);
        [data1 getBytes:pbuffer length:count];
        //const char *cString = [data UTF8String];
        //NSString *string = [data ];
        //NSUInteger count = [data count];
      //  NSArray *allValue = [data allValues];
        //NSMutableString
        
       /* for(int i=0; i< count; i++)
        {
            //id dataValue = [data objectForKey:[[NSNumber numberWithInt:i] stringValue]] ;
            //pbuffer[i] = [data  characterAtIndex:[NSNumber numberWithInt:i]];
            pbuffer[i] = cString[i];//[dataValue unsignedCharValue];//  [data class] objectForKey:(__bridge id)i];
            if(i==0)
            NSLog(@"%d %d", i, pbuffer[i]);
        }*/

        
        NSImage *image = createNSImageFromBuffer(pbuffer, 512, 512);//(__bridge void *)[[data class] bytes], 300, 300); //(__bridge void *)
        self.imageView.image = image;
        free(pbuffer);
        //NSLog(@"testObjcCallback called: %@", data);
        //unsigned char *datap = (unsigned char *)data;
       // data[0] =100;
        //responseCallback(@"Response from testObjcCallback");
        
    }];
}

/*
- (void)captureScreenshotSyncInWKWebView:(WKWebView*)wkWebView
{
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    self.imageView.image = [wkWebView captureScreenshotWithTimeout:timeout];
}
*/
@end
