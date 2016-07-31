//
//  TalkingViewController.m
//  HelloMyBLE
//
//  Created by Peter Yo on 4月/22/16.
//  Copyright © 2016年 Peter Hsu. All rights reserved.
//

#import "TalkingViewController.h"

#define GUEST_NAME @"Peter"

@interface TalkingViewController () <CBPeripheralDelegate>
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@end

@implementation TalkingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.targetPeripheral.delegate = self;//打開和Peripheral之間的溝通
    [self.targetPeripheral setNotifyValue:true forCharacteristic:self.targetCharacteristic];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
   
    // Stop,and not receive notify from peripheral any more.
    [self.targetPeripheral setNotifyValue:false forCharacteristic:self.targetCharacteristic];
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)sendBtnPressed:(id)sender {
    
    NSString *inputString = self.inputTextField.text;
    
    if (inputString.length == 0) {
        return;
    }
    
    [self.inputTextField resignFirstResponder];
    
    NSString *contentWillSend = [NSString stringWithFormat:@"[%@]%@\n", GUEST_NAME, inputString];
    
    NSData *dataWillSend = [contentWillSend dataUsingEncoding:NSUTF8StringEncoding];//字串轉NSData
    [self.targetPeripheral writeValue:dataWillSend forCharacteristic:self.targetCharacteristic type:CBCharacteristicWriteWithResponse];//Response會由peripheral發送
    
    
}

#pragma mark - CBPeripheralDelegate Methods
-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSString *content = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    
    //0422 9:57am
    if(content.length > 0) {
        self.logTextView.text = [NSString stringWithFormat:@"%@%@", content, self.logTextView.text];
    }
    
}

- (void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    if(error) {
        NSLog(@"didWriteValueForCharacteristic: %@",error.description);
    }
    
    
}



@end




















