//
//  TalkingViewController.h
//  HelloMyBLE
//
//  Created by Peter Yo on 4月/22/16.
//  Copyright © 2016年 Peter Hsu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface TalkingViewController : UIViewController

@property (nonatomic,strong) CBPeripheral *targetPeripheral;
@property (nonatomic,strong) CBCharacteristic *targetCharacteristic;


@end
