//
//  ViewController.m
//  LJwebView
//
//  Created by liujie on 16/12/23.
//  Copyright © 2016年 liujie. All rights reserved.
//

#import "ViewController.h"
#import "LJWebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    button.backgroundColor = [UIColor redColor];
    [button addTarget:self action:@selector(buttonttttt:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button];
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)buttonttttt:(UIButton *)sender{
    sender.backgroundColor = [UIColor grayColor];
    LJWebViewController * ljv = [[LJWebViewController alloc] init];
    ljv.url = @"https://www.baidu.com";
    [self.navigationController pushViewController:ljv animated:YES];

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
