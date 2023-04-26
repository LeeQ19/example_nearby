import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:example_nearby/constants.dart';
import 'package:example_nearby/functions.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyService {
  static final _ble = FlutterReactiveBle();
  static final _blePeripheral = FlutterBlePeripheral();
  static const _serviceId = '9840d77d-4ecf-443f-8175-7b736cc2b263';
  static const _beaconId = '514a35d3-7e3c-47b4-b657-1b8c4fc5883f';
  static late AdvertiseData _advertiseData;
  static final List<Region> _regions = [];
  static StreamSubscription<DiscoveredDevice>? _bleStream;
  static StreamSubscription<RangingResult>? _beaconStream;

  /// 28 length random string with large, small alphabet & number
  static final String _uid = getRandomString(28);

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

    await flutterBeacon.initializeAndCheckScanning;

    // _advertiseData = AdvertiseData(
    //   serviceUuid: _serviceId,
    //   manufacturerId: 0xa1b1, //Android only.
    //   manufacturerData: Uint8List.fromList([0xab, 0xcd, 0xef]), //Android only.
    //   serviceDataUuid: _serviceId, //Android only.
    //   serviceData: [12, 34, 45], //Android only.
    //   includeDeviceName: true, //Android only.
    //   localName: _uid, //iOS only.
    // );
    // _regions.add(Region(identifier: 'com.beacon', proximityUUID: _beaconId));

    if (Platform.isAndroid) {
      _advertiseData = AdvertiseData(
        serviceUuid: _serviceId,
        manufacturerId: 0xa1b1, //Android only.
        manufacturerData: Uint8List.fromList([0xab, 0xcd, 0xef]), //Android only.
        serviceDataUuid: _serviceId, //Android only.
        serviceData: [12, 34, 45], //Android only.
        includeDeviceName: true, //Android only.
      );
      _regions.add(Region(identifier: 'com.beacon'));
    } else {
      _advertiseData = AdvertiseData(
        serviceUuid: _serviceId,
        localName: _uid, //iOS only.
      );
      _regions.add(Region(identifier: 'com.beacon', proximityUUID: _beaconId));
    }
  }

  /// Check required permissions function
  ///
  /// If any of the permissions are not granted, request the permission.
  /// Return a boolean wheather all permissions are granted or denied.
  static Future<List<bool>> _checkPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    final granted = statuses.values.map((status) => status == PermissionStatus.granted).toList();
    return granted;
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
        advertiseData: _advertiseData,
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
      ).listen((DiscoveredDevice device) {
        print("Device Found!| id: ${device.id}| rssi: ${device.rssi}");
        print("Device Found!| manufacturerData: ${device.manufacturerData}| name: ${device.name}");
        print("Device Found!| serviceUuids: ${device.serviceUuids}| serviceData: ${device.serviceData}");

        nearbyDevices.remove('noDevice');
        nearbyDevices[device.id] = device.id;
      });

      _beaconStream = flutterBeacon.ranging(_regions).listen((RangingResult result) {
        final beacons = result.beacons;
        if (beacons.isEmpty) {
          print("Beacon Empty...| result: $result");
          return;
        }

        final Beacon beacon = beacons.last;
        final key = '${beacon.major}-${beacon.minor}';
        if (nearbyDevices.keys.contains(key)) return;

        print("Beacon Found!| major: ${beacon.major}| minor: ${beacon.minor}");

        nearbyDevices.remove('noDevice');
        nearbyDevices[key] = key;
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
      await _bleStream!.cancel();
      _bleStream = null;

      await _beaconStream!.cancel();
      _beaconStream = null;

      nearbyDevices.clear();
      nearbyDevices['disabledDiscovering'] = Constants.disabledDiscovering;
    } catch (exception) {
      nearbyDevices.clear();
      nearbyDevices['exception'] = exception.toString();
    }
  }
}
