import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:example_nearby/constants.dart';
import 'package:example_nearby/nearby_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: Constants.title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePageView(title: Constants.title),
    );
  }
}

class HomePageView extends StatelessWidget {
  final String title;
  final controller = Get.put(_HomePageController());

  HomePageView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advertise This Device',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Obx(() {
                  return Switch(
                    value: controller.isAdvertising.value,
                    onChanged: controller.onChangeAdvertise,
                  );
                }),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Discover Nearby Devices',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Obx(() {
                  return Switch(
                    value: controller.isDiscovering.value,
                    onChanged: controller.onchangeDiscover,
                  );
                }),
              ],
            ),
            const Divider(
              height: 25,
              thickness: 5,
            ),
            const Text(
              'UID of This Device',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Obx(() {
              return Text(controller.currentDevice.value);
            }),
            const SizedBox(height: 10),
            const Text(
              'Discovered Devices',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Obx(() {
                return ListView.separated(
                  itemCount: controller.nearbyDevices.length,
                  itemBuilder: (BuildContext context, int index) {
                    String key = controller.nearbyDevices.keys.elementAt(index);
                    return Text(controller.nearbyDevices[key]!);
                  },
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 10),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePageController extends GetxController {
  RxBool isAdvertising = false.obs;
  RxBool isDiscovering = false.obs;
  RxString currentDevice = ''.obs;
  RxMap<String, String> nearbyDevices = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    NearbyService.init(currentDevice, nearbyDevices);
  }

  void onChangeAdvertise(bool value) async {
    isAdvertising.value = value;
    if (value) {
      await NearbyService.startAdvertise(currentDevice);
    } else {
      await NearbyService.stopAdvertise(currentDevice);
    }
  }

  void onchangeDiscover(bool value) async {
    isDiscovering.value = value;
    if (value) {
      await NearbyService.startDiscover(nearbyDevices);
    } else {
      await NearbyService.stopDiscover(nearbyDevices);
    }
  }
}
