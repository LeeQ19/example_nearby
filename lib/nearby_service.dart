import 'dart:async';

import 'package:example_nearby/constants.dart';
import 'package:example_nearby/functions.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyService {
  static final _ble = FlutterReactiveBle();
  static final _blePeripheral = FlutterBlePeripheral();
  static const _serviceId = '9840d77d-4ecf-443f-8175-7b736cc2b263';
  static StreamSubscription<DiscoveredDevice>? _bleStream;

  /// 20 length random string with large, small alphabet & number
  static final String _uid = getRandomString(20);

  static final AdvertiseData advertiseData = AdvertiseData(
    serviceUuid: _serviceId,
    // manufacturerId: null,           //Android only. Specifies a manufacturer id Manufacturer ID assigned by Bluetooth SIG.
    // manufacturerData: null,         //Android only. Specifies a manufacturer id Manufacturer ID assigned by Bluetooth SIG.
    // serviceDataUuid: null,          //Android only. Specifies service data UUID.
    // serviceData: null,              //Android only. Specifies service data.
    // includeDeviceName: false,       //Android only. Set to true if device name needs to be included with advertisement Default: false
    // localName: null,                //iOS only. Set the deviceName to be broadcasted. Can be 10 bytes.
    // includePowerLevel: false,       //Android only. set to true if you want to include the power level in the advertisement Default: false
    // serviceSolicitationUuid: null,  //Android > SDK 31 only. A service solicitation UUID to advertise data.
  );

  /// Initialize function
  ///
  /// Set [currentDevice] and [nearbyDevices] to messages of disabledAdvertising and disabledDiscovering.
  /// Check and request permissions for nearby service.
  static Future<void> init(RxString currentDevice, RxMap nearbyDevices) async {
    currentDevice.value = Constants.disabledAdvertising;
    nearbyDevices['disabledDiscovering'] = Constants.disabledDiscovering;
    final isSupported = await _blePeripheral.isSupported;
    print('Weve| isSupported: $isSupported');
    final permissionsGranted = await _checkPermissions();
    print('Weve| permissions: $permissionsGranted');
  }

  /// Check required permissions function
  ///
  /// If any of the permissions are not granted, request the permission.
  /// Return a boolean wheather all permissions are granted or denied.
  static Future<bool> _checkPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    if (statuses.values.every((status) => status == PermissionStatus.granted)) return true;
    return false;
  }

  /// Activate advertising function
  ///
  /// Set [currentDevice] to [Constants.running] and run nearby function for advertising.
  /// After starting advertising, set [currentDevice] to [_uid].
  /// If the nearby function throws [exception], set [currentDevice] to [exception].
  static Future<void> startAdvertise(RxString currentDevice) async {
    currentDevice.value = Constants.running;
    try {
      await _blePeripheral.start(
        advertiseData: advertiseData,
        advertiseSettings: AdvertiseSettings(timeout: 0),
      );

      currentDevice.value = Constants.unknown;
    } catch (exception) {
      currentDevice.value = exception.toString();
    }
  }

  /// Deactivate advertising function
  ///
  /// Set [currentDevice] to [Constants.stopping] and run nearby function for stop advertising.
  /// After stopping advertising, set [currentDevice] to [Constants.disabledAdvertising].
  /// If the nearby function throws [exception], set [currentDevice] to [exception].
  static Future<void> stopAdvertise(RxString currentDevice) async {
    currentDevice.value = Constants.stopping;
    try {
      await _blePeripheral.stop();

      currentDevice.value = Constants.disabledAdvertising;
    } catch (exception) {
      currentDevice.value = exception.toString();
    }
  }

  /// Activate discovering function
  ///
  /// Set [nearbyDevices] to {'running': [Constants.running]} and run nearby function for discovering.
  /// After starting advertising, set [nearbyDevices] to {'noDevice': [Constants.noDevice]}.
  /// When discover a nearby device, update [nearbyDevices] with deviceId & uid of the device.
  /// If the nearby function throws [exception], set [nearbyDevices] to {'exception': [exception]}.
  static Future<void> startDiscover(RxMap nearbyDevices) async {
    nearbyDevices.clear();
    nearbyDevices['running'] = Constants.running;
    try {
      _bleStream = _ble.scanForDevices(
        withServices: [Uuid.parse(_serviceId)],
        requireLocationServicesEnabled: true,
      ).listen((device) {
        print("Device Found!| id: ${device.id}| rssi: ${device.rssi}");

        nearbyDevices.remove('noDevice');
        nearbyDevices[device.id] = device.id;
      });

      nearbyDevices.remove('running');
      nearbyDevices['noDevice'] = Constants.noDevice;
    } catch (exception) {
      nearbyDevices.clear();
      nearbyDevices['exception'] = exception.toString();
    }
  }

  /// Deactivate discovering function
  ///
  /// Set [nearbyDevices] to {'stopping': [Constants.stopping]} and run nearby function for stop discovering.
  /// After stopping discovering, set [nearbyDevices] to {'disabledDiscovering': [Constants.disabledDiscovering]}.
  /// If the nearby function throws [exception], set [nearbyDevices] to {'exception': [exception]}.
  static Future<void> stopDiscover(RxMap nearbyDevices) async {
    nearbyDevices.clear();
    nearbyDevices['stopping'] = Constants.stopping;
    try {
      _bleStream!.cancel();
      _bleStream = null;

      nearbyDevices.clear();
      nearbyDevices['disabledDiscovering'] = Constants.disabledDiscovering;
    } catch (exception) {
      nearbyDevices.clear();
      nearbyDevices['exception'] = exception.toString();
    }
  }
}
