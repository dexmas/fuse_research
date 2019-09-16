#import "BluetoothImpl.hh"
#import <Uno/Memory.h>

static char BTS_ADVERTISING_IDENTIFER;
static char BTS_ADVERTISEMENT_RSSI_IDENTIFER;

@implementation CBPeripheral(com_megster_bluetoothserial_extension)

// AdvertisementData and RSSI are from didDiscoverPeripheral.
// Save the manufacturerData so we can pass to Fuse in the peripheral
-(void)bts_setAdvertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)rssi{

    if (advertisementData) {
        id manufacturerData = [advertisementData objectForKey:CBAdvertisementDataManufacturerDataKey];
        if (manufacturerData) {
            const void *bytes = [manufacturerData bytes];
            long len = [manufacturerData length];
            // skip manufacturer uuid
            NSData *data = [NSData dataWithBytes:(const char*)bytes+2 length:len-2];
            [self setBtsAdvertising: [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        }
    }

    [self setBtsAdvertisementRSSI: rssi];
}

-(void)setBtsAdvertising:(NSString *)newAdvertisingValue{
    objc_setAssociatedObject(self, &BTS_ADVERTISING_IDENTIFER, newAdvertisingValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString*)btsAdvertising{
    return objc_getAssociatedObject(self, &BTS_ADVERTISING_IDENTIFER);
}


-(void)setBtsAdvertisementRSSI:(NSNumber *)newAdvertisementRSSIValue {
    objc_setAssociatedObject(self, &BTS_ADVERTISEMENT_RSSI_IDENTIFER, newAdvertisementRSSIValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSString*)btsAdvertisementRSSI{
    return objc_getAssociatedObject(self, &BTS_ADVERTISEMENT_RSSI_IDENTIFER);
}

@end

@interface BluetoothImpl()
- (NSString *)readUntilDelimiter:(NSString *)delimiter;
- (NSMutableArray *)getPeripheralList;
- (void)sendDataToSubscriber;
- (CBPeripheral *)findPeripheralByUUID:(NSString *)uuid;
- (void)connectToUUID:(NSString *)uuid;
- (void)listPeripheralsTimer:(NSTimer *)timer;
- (void)connectFirstDeviceTimer:(NSTimer *)timer;
- (void)connectUuidTimer:(NSTimer *)timer;
@end

@implementation BluetoothImpl

@synthesize CM;
@synthesize peripherals;
@synthesize activePeripheral;

static bool isConnected = false;
static int rssi = 0;

// TODO should have a configurable list of services
CBUUID *redBearLabsServiceUUID;
CBUUID *adafruitServiceUUID;
CBUUID *lairdServiceUUID;
CBUUID *blueGigaServiceUUID;
CBUUID *hm10ServiceUUID;
CBUUID *hc02ServiceUUID;
CBUUID *hc02AdvUUID;
CBUUID *serialServiceUUID;
CBUUID *readCharacteristicUUID;
CBUUID *writeCharacteristicUUID;

- (void)Init {

    NSLog(@"Fuse Bluetooth Serial Plugin");
    NSLog(@"(c)2019 iDeXmas");

    [self controlSetup];

    _buffer = [[NSMutableString alloc] init];
}

- (void)Destroy {

}

- (void)bleDidReceiveData:(unsigned char *)data length:(int)length {
    NSLog(@"bleDidReceiveData");

    // Append to the buffer
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSLog(@"Received %@", s);

    if (s) {
        [_buffer appendString:s];

        if (_subscribeCallbackId) {
            [self sendDataToSubscriber]; // only sends if a delimiter is hit
        }

    } else {
        NSLog(@"Error converting received data into a String.");
    }

    // Always send raw data if someone is listening
    if (_subscribeBytesCallbackId) {
        NSData* nsData = [NSData dataWithBytes:(const void *)data length:length];
        
    }

}

- (void)bleDidConnect {
    NSLog(@"bleDidConnect");
    [self clearBuffer];
}

- (void)bleDidDisconnect {
    // TODO is there anyway to figure out why we disconnected?
    NSLog(@"bleDidDisconnect");
    _connectCallbackId = nil;
}

- (void)bleDidUpdateRSSI:(NSNumber *)rssi {
    if (_rssiCallbackId) {
    }
}

-(void)listPeripheralsTimer:(NSTimer *)timer {
    NSString *callbackId = [timer userInfo];
    NSMutableArray *peripherals = [self getPeripheralList];
}

-(void)connectFirstDeviceTimer:(NSTimer *)timer {

    if(peripherals.count > 0) {
        NSLog(@"Connecting");
        [self connectPeripheral:[peripherals objectAtIndex:0]];
    } else {
        NSString *error = @"Did not find any BLE peripherals";
        NSLog(@"%@", error);
    }
}

-(void)connectUuidTimer:(NSTimer *)timer {

    NSString *uuid = [timer userInfo];

    CBPeripheral *peripheral = [self findPeripheralByUUID:uuid];

    if (peripheral) {
        [self connectPeripheral:peripheral];
    } else {
        NSString *error = [NSString stringWithFormat:@"Could not find peripheral %@.", uuid];
        NSLog(@"%@", error);
    }
}

- (void)bluetoothStateTimer:(NSTimer *)timer {

    NSString *callbackId = [timer userInfo];

    int bluetoothState = [CM state];

    BOOL enabled = bluetoothState == CBCentralManagerStatePoweredOn;
}

- (NSString*)readUntilDelimiter: (NSString*) delimiter {

    NSRange range = [_buffer rangeOfString: delimiter];
    NSString *message = @"";

    if (range.location != NSNotFound) {

        long end = range.location + range.length;
        message = [_buffer substringToIndex:end];

        NSRange truncate = NSMakeRange(0, end);
        [_buffer deleteCharactersInRange:truncate];
    }
    return message;
}

- (NSMutableArray*) getPeripheralList {

    NSMutableArray *per = [NSMutableArray array];

    for (int i = 0; i < peripherals.count; i++) {
        NSMutableDictionary *peripheral = [NSMutableDictionary dictionary];
        CBPeripheral *p = [per objectAtIndex:i];

        NSString *uuid = p.identifier.UUIDString;
        [peripheral setObject: uuid forKey: @"uuid"];
        [peripheral setObject: uuid forKey: @"id"];

        NSString *name = [p name];
        if (!name) {
            name = [peripheral objectForKey:@"uuid"];
        }
        [peripheral setObject: name forKey: @"name"];

        NSNumber *rssi = [p btsAdvertisementRSSI];
        if (rssi) { // BLEShield doesn't provide advertised RSSI
            [peripheral setObject: rssi forKey:@"rssi"];
        }

        [peripherals addObject:peripheral];
    }

    return peripherals;
}

// calls the JavaScript subscriber with data if we hit the _delimiter
- (void) sendDataToSubscriber {
    NSString *message = [self readUntilDelimiter:_delimiter];

    if ([message length] > 0) {
        [self sendDataToSubscriber];
    }

}

// Ideally we'd get a callback when found, maybe _bleShield can be modified
// to callback on centralManager:didRetrievePeripherals. For now, use a timer.
- (void)scanForBLEPeripherals:(int)timeout {
    NSLog(@"Scanning for BLE Peripherals");

    // disconnect
    if (activePeripheral) {
        if(activePeripheral.state == CBPeripheralStateConnected)
        {
            [CM cancelPeripheralConnection:activePeripheral];
            return;
        }
    }

    // remove existing peripherals
    if (peripherals) {
        peripherals = nil;
    }

    [self findBLEPeripherals:timeout];
}

- (void)connectToFirstDevice {
    [self scanForBLEPeripherals:3];
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0
                                     target:self
                                   selector:@selector(connectFirstDeviceTimer:)
                                   userInfo:nil
                                    repeats:NO];
}

- (void)connectToUUID:(NSString *)uuid {

    int interval = 0;

    if (peripherals.count < 1) {
        interval = 3;
        [self scanForBLEPeripherals:interval];
    }

    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(connectUuidTimer:)
                                   userInfo:uuid
                                    repeats:NO];
}

- (CBPeripheral*)findPeripheralByUUID:(NSString*)uuid {

    NSMutableArray *peripherals = peripherals;
    CBPeripheral *peripheral = nil;

    for (CBPeripheral *p in peripherals) {

        NSString *other = p.identifier.UUIDString;

        if ([uuid isEqualToString:other]) {
            peripheral = p;
            break;
        }
    }
    return peripheral;
}

- (void)clearBuffer {
    long end = [_buffer length];
    NSRange truncate = NSMakeRange(0, end);
    [_buffer deleteCharactersInRange:truncate];
}


-(void) readRSSI
{
    [activePeripheral readRSSI];
}

-(BOOL) isConnected
{
    return isConnected;
}

-(void) read
{
//    CBUUID *uuid_service = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
//    CBUUID *uuid_char = [CBUUID UUIDWithString:@RBL_CHAR_TX_UUID];

//    [self readValue:uuid_service characteristicUUID:uuid_char p:activePeripheral];
     [self readValue:serialServiceUUID characteristicUUID:readCharacteristicUUID p:activePeripheral];

}

-(void) write:(NSData *)d
{
//    CBUUID *uuid_service = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
//    CBUUID *uuid_char = [CBUUID UUIDWithString:@RBL_CHAR_RX_UUID];
//
//    [self writeValue:uuid_service characteristicUUID:uuid_char p:activePeripheral data:d];
    [self writeValue:serialServiceUUID characteristicUUID:writeCharacteristicUUID p:activePeripheral data:d];
}

-(void) enableReadNotification:(CBPeripheral *)p
{
//    CBUUID *uuid_service = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
//    CBUUID *uuid_char = [CBUUID UUIDWithString:@RBL_CHAR_TX_UUID];
//
//    [self notification:uuid_service characteristicUUID:uuid_char p:p on:YES];
    [self notification:serialServiceUUID characteristicUUID:readCharacteristicUUID p:p on:YES];

}

-(void) notification:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];

    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
               [self CBUUIDToString:serviceUUID],
               p.identifier.UUIDString);

        return;
    }

    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];

    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    [p setNotifyValue:on forCharacteristic:characteristic];
}

-(UInt16) frameworkVersion
{
    return RBL_BLE_FRAMEWORK_VER;
}

-(NSString *) CBUUIDToString:(CBUUID *) cbuuid;
{
    NSData *data = cbuuid.data;

    if ([data length] == 2)
    {
        const char *tokenBytes = (const char*)[data bytes];
        return [NSString stringWithFormat:@"%02x%02x", tokenBytes[0], tokenBytes[1]];
    }
    else if ([data length] == 16)
    {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSUUID* nsuuid = [[NSUUID alloc] initWithUUIDString: string];
        return [nsuuid UUIDString];
    }

    return [cbuuid description];
}

-(void) readValue: (CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];

    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];

    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    [p readValueForCharacteristic:characteristic];
}

-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data
{
    CBService *service = [self findServiceFromUUID:serviceUUID p:p];

    if (!service)
    {
        NSLog(@"Could not find service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:characteristicUUID service:service];

    if (!characteristic)
    {
        NSLog(@"Could not find characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
              [self CBUUIDToString:characteristicUUID],
              [self CBUUIDToString:serviceUUID],
              p.identifier.UUIDString);

        return;
    }

    if ((characteristic.properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite) {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
    else if ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse) {
        [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

-(UInt16) swap:(UInt16)s
{
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

- (void) controlSetup
{
    self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (int) findBLEPeripherals:(int) timeout
{
    if (self.CM.state != CBManagerStatePoweredOn)
    {
        NSLog(@"CoreBluetooth not correctly initialized !");
        NSLog(@"State = %ld (%s)\r\n", (long)self.CM.state, [self centralManagerStateToString:self.CM.state]);
        return -1;
    }

    [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];

#if TARGET_OS_IPHONE
    redBearLabsServiceUUID = [CBUUID UUIDWithString:@RBL_SERVICE_UUID];
    adafruitServiceUUID = [CBUUID UUIDWithString:@ADAFRUIT_SERVICE_UUID];
    lairdServiceUUID = [CBUUID UUIDWithString:@LAIRD_SERVICE_UUID];
    blueGigaServiceUUID = [CBUUID UUIDWithString:@BLUEGIGA_SERVICE_UUID];
    hm10ServiceUUID = [CBUUID UUIDWithString:@HM10_SERVICE_UUID];
    hc02ServiceUUID = [CBUUID UUIDWithString:@HC02_SERVICE_UUID];
    hc02AdvUUID = [CBUUID UUIDWithString:@HC02_ADV_UUID];
    NSArray *services = @[redBearLabsServiceUUID, adafruitServiceUUID, lairdServiceUUID, blueGigaServiceUUID, hm10ServiceUUID, 
                        hc02AdvUUID];
    [self.CM scanForPeripheralsWithServices:services options: nil];
#else
    [self.CM scanForPeripheralsWithServices:nil options:nil]; // Start scanning
#endif

    NSLog(@"scanForPeripheralsWithServices");

    return 0; // Started scanning OK !
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    done = false;

    [self bleDidDisconnect];

    isConnected = false;
}

- (void) connectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connecting to peripheral with UUID : %@", peripheral.identifier.UUIDString);

    self.activePeripheral = peripheral;
    self.activePeripheral.delegate = self;
    [self.CM connectPeripheral:self.activePeripheral
                       options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

- (const char *) centralManagerStateToString: (int)state
{
    switch(state)
    {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }

    return "Unknown state";
}

- (void) scanTimer:(NSTimer *)timer
{
    [self.CM stopScan];
    NSLog(@"Stopped Scanning");
    NSLog(@"Known peripherals : %lu", (unsigned long)[self.peripherals count]);
    [self printKnownPeripherals];
}

- (void) printKnownPeripherals
{
    NSLog(@"List of currently known peripherals :");

    for (int i = 0; i < self.peripherals.count; i++)
    {
        CBPeripheral *p = [self.peripherals objectAtIndex:i];

        if (p.identifier != NULL)
            NSLog(@"%d  |  %@", i, p.identifier.UUIDString);
        else
            NSLog(@"%d  |  NULL", i);

        [self printPeripheralInfo:p];
    }
}

- (void) printPeripheralInfo:(CBPeripheral*)peripheral
{
    NSLog(@"------------------------------------");
    NSLog(@"Peripheral Info :");

    if (peripheral.identifier != NULL)
        NSLog(@"UUID : %@", peripheral.identifier.UUIDString);
    else
        NSLog(@"UUID : NULL");

    NSLog(@"Name : %@", peripheral.name);
    NSLog(@"-------------------------------------");
}

- (BOOL) UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2
{
    if ([UUID1.UUIDString isEqualToString:UUID2.UUIDString])
        return TRUE;
    else
        return FALSE;
}

-(void) getAllServicesFromPeripheral:(CBPeripheral *)p
{
    [p discoverServices:nil]; // Discover all services without filter
}

-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p
{
    for (int i=0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        //        printf("Fetching characteristics for service with UUID : %s\r\n",[self CBUUIDToString:s.UUID]);
        [p discoverCharacteristics:nil forService:s];
    }
}

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2
{
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1 length:16];
    [UUID2.data getBytes:b2 length:16];

    if (memcmp(b1, b2, UUID1.data.length) == 0)
        return 1;
    else
        return 0;
}

-(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2
{
    char b1[16];

    [UUID1.data getBytes:b1 length:16];
    UInt16 b2 = [self swap:UUID2];

    if (memcmp(b1, (char *)&b2, 2) == 0)
        return 1;
    else
        return 0;
}

-(UInt16) CBUUIDToInt:(CBUUID *) UUID
{
    char b1[16];
    [UUID.data getBytes:b1 length:16];
    return ((b1[0] << 8) | b1[1]);
}

-(CBUUID *) IntToCBUUID:(UInt16)UUID
{
    char t[16];
    t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
    NSData *data = [[NSData alloc] initWithBytes:t length:16];
    return [CBUUID UUIDWithData:data];
}

-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p
{
    for(int i = 0; i < p.services.count; i++)
    {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID])
            return s;
    }

    return nil; //Service not found on this peripheral
}

-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service
{
    for(int i=0; i < service.characteristics.count; i++)
    {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }

    return nil; //Characteristic not found on this service
}

#if TARGET_OS_IPHONE
    //-- no need for iOS
#else
- (BOOL) isLECapableHardware
{
    NSString * state = nil;

    switch ([CM state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;

        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;

        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;

        case CBCentralManagerStatePoweredOn:
            return TRUE;

        case CBCentralManagerStateUnknown:
        default:
            return FALSE;

    }

    NSLog(@"Central manager state: %@", state);

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
    [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:nil contextInfo:nil];

    return FALSE;
}
#endif

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
#if TARGET_OS_IPHONE
    NSLog(@"Status of CoreBluetooth central manager changed %ld (%s)", (long)central.state, [self centralManagerStateToString:central.state]);
#else
    [self isLECapableHardware];
#endif
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (!self.peripherals)
        self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral,nil];
    else
    {
        for(int i = 0; i < self.peripherals.count; i++)
        {
            CBPeripheral *p = [self.peripherals objectAtIndex:i];
            p.delegate = self;
            
            [p bts_setAdvertisementData:advertisementData RSSI:RSSI];

            if ((p.identifier == NULL) || (peripheral.identifier == NULL))
                continue;

            if ([self UUIDSAreEqual:p.identifier UUID2:peripheral.identifier])
            {
                [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
                NSLog(@"Duplicate UUID found updating...");
                return;
            }
        }

        [self.peripherals addObject:peripheral];

        NSLog(@"New UUID, adding");
    }

    NSLog(@"didDiscoverPeripheral");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if (peripheral.identifier != NULL)
        NSLog(@"Connected to %@ successful", peripheral.identifier.UUIDString);
    else
        NSLog(@"Connected to NULL successful");

    self.activePeripheral = peripheral;
    [self.activePeripheral discoverServices:nil];
    [self getAllServicesFromPeripheral:peripheral];
}

static bool done = false;

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (!error)
    {
        //        printf("Characteristics of service with UUID : %s found\n",[self CBUUIDToString:service.UUID]);

        for (int i=0; i < service.characteristics.count; i++)
        {
            //            CBCharacteristic *c = [service.characteristics objectAtIndex:i];
            //            printf("Found characteristic %s\n",[ self CBUUIDToString:c.UUID]);
            CBService *s = [peripheral.services objectAtIndex:(peripheral.services.count - 1)];

            if ([service.UUID isEqual:s.UUID])
            {
                if (!done)
                {
                    [self enableReadNotification:activePeripheral];
                    [self bleDidConnect];
                    isConnected = true;
                    done = true;
                }

                break;
            }
        }
    }
    else
    {
        NSLog(@"Characteristic discorvery unsuccessful!");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (!error)
    {
        // Determine if we're connected to Red Bear Labs, Adafruit or Laird hardware
        for (CBService *service in peripheral.services) {

            if ([service.UUID isEqual:redBearLabsServiceUUID]) {
                NSLog(@"RedBearLabs Bluetooth");
                serialServiceUUID = redBearLabsServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@RBL_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@RBL_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:adafruitServiceUUID]) {
                NSLog(@"Adafruit Bluefruit LE");
                serialServiceUUID = adafruitServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@ADAFRUIT_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@ADAFRUIT_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:lairdServiceUUID]) {
                NSLog(@"Laird BL600");
                serialServiceUUID = lairdServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@LAIRD_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@LAIRD_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:blueGigaServiceUUID]) {
                NSLog(@"BlueGiga Bluetooth");
                serialServiceUUID = blueGigaServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@BLUEGIGA_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@BLUEGIGA_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:hm10ServiceUUID]) {
                NSLog(@"HM-10 Bluetooth");
                serialServiceUUID = hm10ServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@HM10_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@HM10_CHAR_RX_UUID];
                break;
            } else if ([service.UUID isEqual:hc02ServiceUUID]) {
                NSLog(@"HC-02 Bluetooth");
                NSLog(@"Set HC-02 read write UUID");
                serialServiceUUID = hc02ServiceUUID;
                readCharacteristicUUID = [CBUUID UUIDWithString:@HC02_CHAR_TX_UUID];
                writeCharacteristicUUID = [CBUUID UUIDWithString:@HC02_CHAR_RX_UUID];
                break;
            } else {
                // ignore unknown services
            }
        }

        // TODO - future versions should just get characteristics we care about
        // [peripheral discoverCharacteristics:characteristics forService:service];
        [self getAllCharacteristicsFromPeripheral:peripheral];
    }
    else
    {
        NSLog(@"Service discovery was unsuccessful!");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error)
    {
        //        printf("Updated notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[self UUIDToString:peripheral.UUID]);
    }
    else
    {
        NSLog(@"Error in setting notification state for characteristic with UUID %@ on service with UUID %@ on peripheral with UUID %@",
               [self CBUUIDToString:characteristic.UUID],
               [self CBUUIDToString:characteristic.service.UUID],
               peripheral.identifier.UUIDString);

        NSLog(@"Error code was %s", [[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    unsigned char data[20];

    static unsigned char buf[512];
    static int len = 0;
    NSInteger data_len;

    if (!error)
    {
        if ([characteristic.UUID isEqual:readCharacteristicUUID])
        {
            data_len = characteristic.value.length;
            [characteristic.value getBytes:data length:data_len];

            if (data_len == 20)
            {
                memcpy(&buf[len], data, 20);
                len += data_len;

                if (len >= 64)
                {
                    [self bleDidReceiveData:buf length:len];
                    len = 0;
                }
            }
            else if (data_len < 20)
            {
                memcpy(&buf[len], data, data_len);
                len += data_len;

                [self bleDidReceiveData:buf length:len];
                len = 0;
            }
        }
    }
    else
    {
        NSLog(@"updateValueForCharacteristic failed!");
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    
    if (!isConnected)
        return;
    
    if (rssi != RSSI.intValue)
    {
        rssi = RSSI.intValue;
        [self bleDidUpdateRSSI:RSSI];
    }
}


@end
