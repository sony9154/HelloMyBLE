//
//  SecondViewController.m
//  HelloMyBLE
//
//  Created by Peter Yo on 4月/21/16.
//  Copyright © 2016年 Peter Hsu. All rights reserved.
//

#import "SecondViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define CHATROOM_NAME @"PeterChatRoom"
#define SERVICE_UUID @"8888"
#define CHARACTERISTIC_UUID @"8888"

@interface SecondViewController ()<UITextFieldDelegate, CBCentralManagerDelegate, CBPeripheralManagerDelegate>
{
    CBPeripheralManager *peripheralManager;
    CBMutableCharacteristic *chatRoomCharacteristic;
}

@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    peripheralManager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
    
    self.inputTextField.delegate = self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startBocastBtn:(id)sender {
    
    // Will start advertising
    if([sender isOn]) {
        
        // Prepare Service and Characteristic
        
        CBUUID *uuidService = [CBUUID UUIDWithString:SERVICE_UUID];
        
        if(chatRoomCharacteristic == nil) {
            
            CBUUID *uuidCharacteristic = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];//建立CHARACTERISTIC 要給uuid
            
            
            CBCharacteristicProperties properties = //定義(溝通的屬性)讀寫方式還有notify
            CBCharacteristicPropertyRead |
            CBCharacteristicPropertyWrite |
            CBCharacteristicPropertyNotify;
            
            CBAttributePermissions permissions = //定義讀寫都可以的能力
            CBAttributePermissionsReadable |
            CBAttributePermissionsWriteable;
            
            chatRoomCharacteristic = [[CBMutableCharacteristic alloc]initWithType:uuidCharacteristic properties:properties value:nil permissions:permissions];//創造Characteristic,value是預設值
            
            CBMutableService *service = [[CBMutableService alloc]initWithType:uuidService primary:true];
            // Service 裡沒有屬性 他只是架構
            
            service.characteristics = @[chatRoomCharacteristic];
            [peripheralManager addService:service];
            
        }
        
        // Start advertising
        NSArray *uuids = @[uuidService];
        NSDictionary *info = @{CBAdvertisementDataServiceDataKey:uuids,CBAdvertisementDataLocalNameKey:CHATROOM_NAME};
        [peripheralManager startAdvertising:info];
        
        
    } else {
        // Will stop advertising
        [peripheralManager stopAdvertising];
        
    }
    
}

- (void) sendText:(NSString*) content
          central:(CBCentral*) central { //central可以指定
    
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    
    if(central == nil) { //nil把訊息發給所有的central
        [peripheralManager updateValue:data forCharacteristic:chatRoomCharacteristic onSubscribedCentrals:nil];
    } else {
        [peripheralManager updateValue:data forCharacteristic:chatRoomCharacteristic onSubscribedCentrals:@[central]];
    }
    
}


#pragma mark - CGPeripheralManagerDelegate Methods

- (void) peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    CBPeripheralManagerState state = peripheralManager.state;
    
    if(state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"BLE is not avilible. %ld", (long)state);//沒跟到
    }
    
    
}

// 有人來監聽這個Characteristic用didSubscribe
- (void) peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    
    NSString *info = [NSString stringWithFormat:@"* Central subscribed(%@),max length: %ld", central.identifier.UUIDString,
                      central.maximumUpdateValueLength];
    NSLog(@"%@",info);
    
    self.logTextView.text = [NSString stringWithFormat:@"%@%@",info,self.logTextView.text];
    
    // Say hello to central
    NSString *hello = [NSString stringWithFormat:@"[%@] 進來吧 %@.(Total: %ld)",CHATROOM_NAME,CHATROOM_NAME,
                       chatRoomCharacteristic.subscribedCentrals.count];
    
    [self sendText:hello central:central];
    
}


- (void) peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    [self sendText:@"* someone leave the room." central:nil];
    
    self.logTextView.text = [NSString stringWithFormat:@"%@%@",@"* Central unsubscribed.",self.logTextView.text];
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    
    for (CBATTRequest *tmp in requests) {
        NSString *content = [[NSString alloc] initWithData:tmp.value encoding:NSUTF8StringEncoding];
        
        if(content != nil) {
            self.logTextView.text = [NSString stringWithFormat:@"%@%@",content,self.logTextView.text];
            [self sendText:content central:nil];
        }
        //0422 2:50pm
        [peripheralManager respondToRequest:tmp withResult:CBATTErrorSuccess];
    }
    
}

- (void) peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    
    //if previous update is finished.
    
}

#pragma mark - UITextFieldDelegate Method
// 0422 pm2:57
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    NSString *content = textField.text;
    if (content.length > 0) {
        NSString *contentWillSend = [NSString stringWithFormat:@"[%@] %@\n",CHATROOM_NAME,content];
        
        [self sendText:contentWillSend central:nil];
        
        self.logTextView.text = [NSString stringWithFormat:@"%@%@", contentWillSend,self.logTextView.text];
    }
    
    return  false;
}


@end















