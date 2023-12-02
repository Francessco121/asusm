import 'mice/tuf_gaming_m4_air.dart';
import 'mouse.dart';

const miceList = <AsusMouseDeviceDescriptor>[
  AsusMouseDeviceDescriptor(
    name: 'TUF Gaming M4 Air',
    vendorId: 0xb05, 
    productId: 0x1a03, 
    usage: 0x1, 
    usagePage: 0xff01,
    ctor: TufGamingM4Air.new
  )
];
