//
//  CentralModeTableViewController.m
//  HelloMyBLE
//
//  Created by Peter Yo on 4月/21/16.
//  Copyright © 2016年 Peter Hsu. All rights reserved.
//

#import "CentralModeTableViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "PeripheralItem.h"

@interface CentralModeTableViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate> {
    
    CBCentralManager *centralManager;
    
    // For Peripheral List display
    NSMutableDictionary *allDiscovered;
    NSDate *lastReloadTableViewDate;
    
    // For Discovery Service
    NSMutableArray *restServices;
    NSMutableString *detailInfo;
    
    // For Talking Support
    BOOL tryToTalk;
    CBPeripheral *talkingPeripheral;
    CBCharacteristic *talkingCBCharacteristic;
    
    
}

@end

@implementation CentralModeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    allDiscovered = [NSMutableDictionary new];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(talkingPeripheral != nil) {
        [centralManager cancelPeripheralConnection:talkingPeripheral];
        talkingPeripheral = nil;
        talkingCBCharacteristic = nil;
        
        [self startToScan];
    }
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;//只有一個section
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return allDiscovered.count;//Dict裡面項目的總數
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"myCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSArray *allKeys = allDiscovered.allKeys;//Dict的key可以是array(UUID String),就可以把dict轉array
    NSString *targetKey = allKeys[indexPath.row];//allkey就有順序性
    PeripheralItem *item = allDiscovered[targetKey];
    
    NSString *line1 = [NSString stringWithFormat:@"%@ RSSI: %ld", item.peripheral.name,(long)item.lastRSSI];
    NSString *line2 = [NSString stringWithFormat:@"Last Seen: %.1f seconds ago.",[[NSDate date] timeIntervalSinceDate:item.lastSeenDate]];
    
    cell.textLabel.text = line1;
    cell.detailTextLabel.text = line2;
    
    return cell;
}

//Detail Disclouse(那個i按鈕)
- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    tryToTalk = false;
    [self connectToItemWithIndexPath:indexPath];
    
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    tryToTalk = true;
    [self connectToItemWithIndexPath:indexPath];
    
}


-(void) connectToItemWithIndexPath:(NSIndexPath*) indexPath {
    
    NSArray *allKeys = allDiscovered.allKeys;//Dict的key可以是array(UUID String),就可以把dict轉array
    NSString *targetKey = allKeys[indexPath.row];//allkey就有順序性
    PeripheralItem *item = allDiscovered[targetKey];
    
    [self stopScanning]; //連上就可以停止scan
    
    [centralManager connectPeripheral:item.peripheral options:nil];//找出conn的對象然後連過去
    
    
}




/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"goTalk"]) {
        
        UIViewController *vc = segue.destinationViewController;
        
        [vc setValue:talkingPeripheral forKey:@"targetPeripheral"];//0422 9:40am
        
        [vc setValue:talkingCBCharacteristic forKey:@"targetCharacteristic"];
        
    }
    
}

- (IBAction)startScanValueChanged:(id)sender {
    
    if([sender isOn]){
        [self startToScan];
    } else {
        [self stopScanning];
    }
    
}

- (void) startToScan {
    
    CBUUID *targetServices = [CBUUID UUIDWithString:@"7777"];
    
    NSArray *services = @[targetServices];
    NSDictionary *options =@{CBCentralManagerScanOptionAllowDuplicatesKey:@(true)};
    
    // @(true) == [NSNumber numberWithBool:true];
    [centralManager scanForPeripheralsWithServices:nil options:options];
}

- (void) stopScanning {
    [centralManager stopScan];
}


- (void) showSimpleAlertWithMessage:(NSString*) message {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:true completion:nil];
    
}

#pragma mark = CBCentralManagerDelegate Methods

-(void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    CBCentralManagerState state = centralManager.state;
    
    if(state != CBCentralManagerStatePoweredOn) {
        NSString *message = [NSString stringWithFormat:@"BLE is not available.(%ld)",(long)state];
        
        [self showSimpleAlertWithMessage:message];
    }
    
    
}

- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                   RSSI:(NSNumber *)RSSI {
    
    PeripheralItem *exisItem = allDiscovered[peripheral.identifier.UUIDString];
    //用UUIDString做key檢查有無已經存在的項目
    
    if(exisItem == nil) {
        NSLog(@"found %@,RSSI: %ld,UUID: %@",peripheral.name,(long)[RSSI integerValue],peripheral.identifier.UUIDString);
    }
    
    PeripheralItem *newItem = [PeripheralItem new];
    newItem.peripheral = peripheral;
    newItem.lastRSSI = [RSSI integerValue];
    newItem.lastSeenDate = [NSDate date];
    
    [allDiscovered setObject:newItem forKey:peripheral.identifier.UUIDString];
    //把資料塞進allDiscovered,新的資料會取代舊的
    
    //Reload TableView if necessary
    NSDate *now = [NSDate date];
    
    if (exisItem == nil || [now timeIntervalSinceDate:
        lastReloadTableViewDate]>3.0) { //超過3秒才進來
        lastReloadTableViewDate = now;
        
        [self.tableView reloadData];
    }
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"didConnectPeripheral: %@", peripheral.name);
    
    // Try to discovery the service of peripheral
    peripheral.delegate = self; //回報也是通過potocal
    [peripheral discoverServices:nil]; //要求所有支援的service
    
}


-(void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    NSLog(@"didFailToConnectPeripheral: %@", error.description);
    [self showSimpleAlertWithMessage:@"Fail to connect"];
    [self startToScan];
    
}


- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
    [self startToScan];//訊號不良斷線時 要求重新連線
    
}

#pragma mark -CBPeripheralDelegate Methods

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    
    if(error) {
        NSLog(@"didDiscoverServices: %@", error.description);
        
        [self showSimpleAlertWithMessage:@"Fail to Discover services"];
        
        [centralManager cancelPeripheralConnection:peripheral]; //要求centralManager斷線
        [self startToScan];
        return;
    }
    
    //Discover characteristic from services
    detailInfo = nil; //
    restServices = [NSMutableArray arrayWithArray:peripheral.services];
    CBService *targetService = restServices.firstObject;
    
    [peripheral discoverCharacteristics:nil forService:targetService]; // nil就會全部回傳
    [restServices removeObjectAtIndex:0];
    
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    if(error) {
        NSLog(@"didDiscoverCharacteristicsForService: %@", error.description);
        
        [self showSimpleAlertWithMessage:@"Fail to Discover Characteristics"];
        
        [centralManager cancelPeripheralConnection:peripheral]; //要求centralManager斷線
        [self startToScan];
        return;
    }
    
    //Fail Peripheral info into detailInfo.
    if(detailInfo == nil) {
        detailInfo = [NSMutableString stringWithFormat:@"*** Peripheral: %@ (%ld services)\n",
                      peripheral.name, peripheral.services.count];
    }
    
    // Fill Service info into detailInfo.
    [detailInfo appendFormat:@"** Service: %@ (%ld Characteristics)\n", service.UUID.UUIDString, service.characteristics.count];
    
    
    //Fill Characteristics info into detailInfo.
    for (CBCharacteristic *tmp in service.characteristics) {
        [detailInfo appendFormat:@"* Characteristics: %@\n", tmp.UUID.UUIDString];
        
        if (tryToTalk) {
            if ([tmp.UUID.UUIDString hasPrefix:@"888"] && [service.UUID.UUIDString hasPrefix:@"888"]) {
                
                talkingPeripheral = peripheral;
                talkingCBCharacteristic = tmp;
                
                [self performSegueWithIdentifier:@"goTalk" sender:nil];
                
                return;
            }
        }
        
    }
    
    // Move to next service
    if(restServices.count > 0) {
        CBService *targetService = restServices.firstObject;
        
        [peripheral discoverCharacteristics:nil forService:targetService];
        [restServices removeObjectAtIndex:0];
    } else {
        // All Done !
        [self showSimpleAlertWithMessage:detailInfo];
        [centralManager cancelPeripheralConnection:peripheral];
        [self startToScan];
        
    }
    
    
}


@end































