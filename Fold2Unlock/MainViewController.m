//
//  MainViewController.m
//  Fold2Unlock
//
//  Created by Kyle Howells on 10/03/2021.
//

#import "MainViewController.h"
#import "KHFoldView.h"

@interface MainViewController ()
@end

@implementation MainViewController {
	KHFoldView *foldView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	UIImage *screenshot = [UIImage imageNamed:@"screenshot.png"];
	
	foldView = [[[KHFoldView alloc] initWithFrame:CGRectMake(0, 0, screenshot.size.width, screenshot.size.height)] autorelease];
	foldView.slices = 7;
	foldView.viewImage = screenshot;
	[self.view addSubview:foldView];
}

-(void)viewDidLayoutSubviews{
	[super viewDidLayoutSubviews];
	
	CGSize size = self.view.bounds.size;
	foldView.center = CGPointMake(size.width * 0.5, size.height * 0.5);
}

@end
