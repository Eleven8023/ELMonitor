//
//  ViewController.m
//  RunLoopMonitor
//
//  Created by Eleven on 2018/11/17.
//  Copyright © 2018 Eleven. All rights reserved.
//

#import "ViewController.h"

#import "ELMonitor.h"
#import "ELMonitorControl.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[ELMonitor sharedInstance] startMonitor];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)longAct:(id)sender {
    for ( int i = 0 ; i < 10000 ; i ++ ){
        NSLog(@"%d",i);
    }
}

- (IBAction)printAct:(id)sender {
    [[ELMonitor sharedInstance] printLogTrace];
}
@end
