#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
    #import <CoreBluetooth/CoreBluetooth.h>
#else
    #import <IOBluetooth/IOBluetooth.h>
#endif

// BlueGiga Service
#define BLUEGIGA_SERVICE_UUID                    "1D5688DE-866D-3AA4-EC46-A1BDDB37ECF6"
#define BLUEGIGA_CHAR_TX_UUID                    "AF20fBAC-2518-4998-9AF7-AF42540731B3"
#define BLUEGIGA_CHAR_RX_UUID                    "AF20fBAC-2518-4998-9AF7-AF42540731B3"

// RBL Service
#define RBL_SERVICE_UUID                         "713D0000-503E-4C75-BA94-3148F18D941E"
#define RBL_CHAR_TX_UUID                         "713D0002-503E-4C75-BA94-3148F18D941E"
#define RBL_CHAR_RX_UUID                         "713D0003-503E-4C75-BA94-3148F18D941E"

// Adafruit BLE
// http://learn.adafruit.com/getting-started-with-the-nrf8001-bluefruit-le-breakout/adding-app-support
// Adafruit | Nordic's TX and RX are the opposite of RBL. This code uses RBL perspective for naming.
#define ADAFRUIT_SERVICE_UUID                    "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define ADAFRUIT_CHAR_TX_UUID                    "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
#define ADAFRUIT_CHAR_RX_UUID                    "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

// Laird Virtual Serial Port (vSP) service for BL600 http://www.lairdtech.com/DownloadAsset.aspx?id=2147489885
#define LAIRD_SERVICE_UUID                       "569a1101-b87f-490c-92cb-11ba5ea5167c"
#define LAIRD_CHAR_TX_UUID                       "569a2000-b87f-490c-92cb-11ba5ea5167c"
#define LAIRD_CHAR_RX_UUID                       "569a2001-b87f-490c-92cb-11ba5ea5167c"

// HM-10 (unfortunately this is also the UUID for the TI simple key service)
// http://processors.wiki.ti.com/index.php/SensorTag_User_Guide#Simple_Key_Service
#define HM10_SERVICE_UUID                       "ffe0"
#define HM10_CHAR_TX_UUID                       "ffe1"
#define HM10_CHAR_RX_UUID                       "ffe1"

// HC-02
// http://www.hc01.com/productdetail?productid=20180314021
#define HC02_SERVICE_UUID "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
#define HC02_CHAR_TX_UUID "49535343-1E4D-4BD9-BA61-23C647249616"
#define HC02_CHAR_RX_UUID "49535343-8841-43F4-A8D4-ECBE34729BB3"
#define HC02_ADV_UUID "18F0"

#define RBL_BLE_FRAMEWORK_VER                    0x0200

typedef void (^foundCallback)(NSString* device);

@interface CBPeripheral(com_megster_bluetoothserial_extension)

@property (nonatomic, retain) NSString *btsAdvertising;
@property (nonatomic, retain) NSNumber *btsAdvertisementRSSI;

-(void)bts_setAdvertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber*)rssi;

@end

@interface BluetoothImpl : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate> {
    NSString* _connectCallbackId;
    NSString* _subscribeCallbackId;
    NSString* _subscribeBytesCallbackId;
    NSString* _rssiCallbackId;

    NSMutableString *_buffer;
    NSString *_delimiter;
}

@property (strong, nonatomic) NSMutableArray *peripherals;
@property (strong, nonatomic) CBCentralManager *CM;
@property (strong, nonatomic) CBPeripheral *activePeripheral;

-(void) bleDidConnect;
-(void) bleDidDisconnect;
-(void) bleDidUpdateRSSI:(NSNumber *) rssi;
-(void) bleDidReceiveData:(unsigned char *) data length:(int) length;

-(void) enableReadNotification:(CBPeripheral *)p;
-(void) read;
-(void) writeValue:(CBUUID *)serviceUUID characteristicUUID:(CBUUID *)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data;

-(BOOL) isConnected;
-(void) write:(NSData *)d;
-(void) readRSSI;

-(void) controlSetup;
-(int) findBLEPeripherals:(int) timeout;
-(void) scan:(int)timeout;
-(void) connectPeripheral:(CBPeripheral *)peripheral;

-(UInt16) swap:(UInt16) s;
-(const char *) centralManagerStateToString:(int)state;
-(void) scanTimer:(NSTimer *)timer;
-(void) printKnownPeripherals;
-(void) printPeripheralInfo:(CBPeripheral*)peripheral;

-(void) getAllServicesFromPeripheral:(CBPeripheral *)p;
-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p;
-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p;
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service;

-(NSString *) CBUUIDToString:(CBUUID *) UUID;

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
-(int) compareCBUUIDToInt:(CBUUID *) UUID1 UUID2:(UInt16)UUID2;
-(UInt16) CBUUIDToInt:(CBUUID *) UUID;
-(BOOL) UUIDSAreEqual:(NSUUID *)UUID1 UUID2:(NSUUID *)UUID2;


-(instancetype)Init: (foundCallback) callback;
-(void)Destroy;

@end
