import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:lora_monitor/domain/measure.dart';
import 'package:lora_monitor/infraestructure/chart_repo.dart';
import 'package:lora_monitor/presentation/core/size_config.dart';
import 'package:lora_monitor/presentation/core/text.dart';

class ConnectedDashboard extends StatefulWidget {
  const ConnectedDashboard({super.key});

  @override
  State<ConnectedDashboard> createState() => _ConnectedDashboardState();
}

class _ConnectedDashboardState extends State<ConnectedDashboard> {
  _ConnectedDashboardState() : loading = true;
  List<Measure> measures = [];
  ChartRepo chartRepo = ChartRepo();
  bool loading;

  Future<void> getNewMeasures() async {
    List<String> messages = [];
    var httpClient = HttpClient();
    var request =
        await httpClient.getUrl(Uri.parse('http://192.168.1.22:80/getAllData'));
    var response = await request.close();
    await for (var line
        in response.transform(utf8.decoder).transform(const LineSplitter())) {
      messages.add(line);
    }
    httpClient.close();
    print(messages);
    
    if (messages.isNotEmpty && messages.first != "error") {
      try {
        // Parse the JSON array from the response
        String jsonString = messages.join();
        List<dynamic> jsonArray = jsonDecode(jsonString);
        
        for (var item in jsonArray) {
          Map<String, dynamic> sensorData = item as Map<String, dynamic>;
          // Add default values for fields not provided by the endpoint
          sensorData['pressure'] = sensorData['pressure'] ?? 0.0;
          sensorData['altitude'] = sensorData['altitude'] ?? 0.0;
          sensorData['date'] = sensorData['date'] ?? DateTime.now().toIso8601String();
          
          Measure measure = Measure.fromServer(sensorData);
          measures.add(measure);
          print('Added measure: ${measure.sensorName}');
        }

        if (measures.isNotEmpty) {
          for (var measure in measures) {
            chartRepo.addLastMeasure(measure);
          }
        }
      } catch (e) {
        print('Error parsing sensor data: $e');
      }
    }
  }

  void sendDeleteData() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.22:80/deleteAllData'),
      );
      if (response.statusCode == 200) {}
      // ignore: empty_catches
    } catch (e) {}
  }

  void uploadNewMeasures(context) async {
    await getNewMeasures();
    if (measures.isNotEmpty) {
      for (var element in measures) {
        chartRepo.addMeasure(element);
      }
      sendDeleteData();
    }
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      loading = true;
    });
    uploadNewMeasures(context);
  }

  @override
  Widget build(BuildContext context) {
    return loading == true
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: SizeConfig.blockSizeHorizontal * 20,
                height: SizeConfig.blockSizeHorizontal * 20,
                child: const CircularProgressIndicator(
                  color: Colors.green,
                ),
              ),
            ],
          )
        : measures.isEmpty
            ? SizedBox(
                width: SizeConfig.blockSizeHorizontal * 90,
                height: SizeConfig.blockSizeHorizontal * 40,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 10,
                  child: Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      getBodyText("No hay nuevas mediciones", false),
                      SizedBox(
                          width: SizeConfig.blockSizeHorizontal * 20,
                          height: SizeConfig.blockSizeHorizontal * 20,
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 60,
                            color: Colors.green,
                          ))
                    ],
                  )),
                ),
              )
            : SizedBox(
                width: SizeConfig.blockSizeHorizontal * 90,
                height: SizeConfig.blockSizeHorizontal * 40,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 10,
                  child: Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      getBodyText("Mediciones recolectadas", false),
                      SizedBox(
                          width: SizeConfig.blockSizeHorizontal * 20,
                          height: SizeConfig.blockSizeHorizontal * 20,
                          child: const Icon(
                            Icons.check_circle_outline_outlined,
                            size: 60,
                            color: Colors.green,
                          ))
                    ],
                  )),
                ),
              );
  }
}