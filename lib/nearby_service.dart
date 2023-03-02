import 'package:get/get.dart';
import 'package:example_nearby/functions.dart';
import 'package:example_nearby/constants.dart';

class NearbyService {
  /// 20 length random string with large, small alphabet & number
  static final String uid = getRandomString(20);

  /// Initialize function
  ///
  /// Set [currentDevice] and [nearbyDevices] to messages of disabledAdvertising and disabledDiscovering.
  /// Check and request permissions for nearby service.
  static Future<void> init(RxString currentDevice, RxMap nearbyDevices) async {
    currentDevice.value = Constants.disabledAdvertising;
    nearbyDevices['disabledDiscovering'] = Constants.disabledDiscovering;
    await _checkPermissions();
  }

  /// Check required permissions function
  ///
  /// If any of the permissions are not granted, request the permission.
  /// Return a boolean wheather all permissions are granted or denied.
  static Future<bool> _checkPermissions() async {
    return false;
  }

  /// Activate advertising function
  ///
  /// Set [currentDevice] to [Constants.running] and run nearby function for advertising.
  /// After starting advertising, set [currentDevice] to [uid].
  /// If the nearby function throws [exception], set [currentDevice] to [exception].
  static Future<void> startAdvertise(RxString currentDevice) async {
    currentDevice.value = Constants.running;
    try {
      /// TODO: Nearby function advertise uid

      currentDevice.value = uid;
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
      /// TODO: Nearby function stop advertising

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
      /// TODO: Nearby function discover uids of nearby devices

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
      /// TODO: Nearby function stop discovering

      nearbyDevices.clear();
      nearbyDevices['disabledDiscovering'] = Constants.disabledDiscovering;
    } catch (exception) {
      nearbyDevices.clear();
      nearbyDevices['exception'] = exception.toString();
    }
  }
}
