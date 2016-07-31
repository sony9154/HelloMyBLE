//
//  PeripheralItem.h
//  HelloMyBLE
//
//  Created by Peter Yo on 4月/21/16.
//  Copyright © 2016年 Peter Hsu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface PeripheralItem : NSObject

@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,strong) NSDate *lastSeenDate;//用來記錄設備上次被發現的時間
@property (nonatomic,assign) NSInteger lastRSSI; //設備上次的訊號強度

@end
