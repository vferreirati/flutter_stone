import 'package:flutter/material.dart';
import 'package:bluetooth_query/bluetooth_query.dart';
import 'package:bluetooth_query/bluetooth_device.dart';
import 'package:flutter_stone/flutter_stone.dart';
import 'dart:io';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool _pluginStarted = false;
  bool _connected = false;
  List<BluetoothDevice> _devices = [];

  @override
  void initState() {
    super.initState();

    if(Platform.isAndroid) {
      BluetoothQuery.initialize();
    }
  }

  void _startPlugin(BuildContext ctx) async {
    final started = await FlutterStone.startPlugin(InitArguments("ADD YOUR STONE CODE HERE", ModeEnum.SANDBOX));
    
    if(!started) {
      final snack = SnackBar(content: Text('Plugin failed to start'),);
      Scaffold.of(ctx).showSnackBar(snack);
    } else {
      setState(() {
        _pluginStarted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Stone Demo',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Stone Demo'),
          centerTitle: true,
        ), 
        body: Builder(
          builder: (ctx) => Container(
            alignment: AlignmentDirectional.center,
            child: Column(
              children: <Widget>[
                _buildPluginStatusIcon(),
                SizedBox(height: 20,),
                RaisedButton(
                  child: Text('Start Plugin'),
                  onPressed: () => _startPlugin(ctx),
                ),
                SizedBox(height: 20,),
                _buildOptionsBar()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPluginStatusIcon() {
    return Container(
      padding: EdgeInsets.only(top: 20),
      child: Icon(
        Icons.power_settings_new,
        color: _pluginStarted ? Colors.green : Colors.red,
        size: 150,
      ),
    );
  }

  Widget _buildOptionsBar() {
    return Offstage(
      offstage: !_pluginStarted,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              RaisedButton(
                child: Text('BT On'),
                onPressed: _turnBluetoothOn,
              ),
              RaisedButton(
                child: Text('GPS Permission'),
                onPressed: _gpsPermission,
              ),
              RaisedButton(
                child: Text('Scan'),
                onPressed: _scan,
              )
            ],
          ),
          Builder(
            builder: (ctx) => RaisedButton(
              child: Text('Connect (iOS)'),
              onPressed: () => _connectIOS(ctx),
            ),
          ),
          Offstage(
            offstage: _connected,
            child: ListView.builder(
              itemCount: _devices.length,
              shrinkWrap: true,
              itemBuilder: (context, index) => _buildDeviceItem(index),
            ),
          ),
          Builder(
            builder: (ctx) => Offstage(
              offstage: !_connected,
              child: RaisedButton(
                child: Text('Make transaction'),
                onPressed: () => _makeTransaction(ctx), 
              ),
            ),
          ),
          Offstage(
            offstage: !_connected,
            child: RaisedButton(
              child: Text('Write to display'),
              onPressed: _writeToDisplay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(int index) {
    final device = _devices[index];
    return ListTile(
      title: Text(device.name),
      subtitle: Text(device.address),
      onTap: () => _onDeviceSelected(device),
    );
  }

  void _turnBluetoothOn() async {
    if(!await BluetoothQuery.isBluetoothEnabled()) {
      BluetoothQuery.askToTurnBluetoothOn();
    }
  }

  void _gpsPermission() async {
    if(!await BluetoothQuery.checkLocationPermission()) {
      BluetoothQuery.askLocationPermission();
    }
  }

  void _scan() {
    setState(() {
      _devices.clear();
    });
    BluetoothQuery.startScan().listen((device) {
      print('Found device: ${device.name}');
      setState(() {
        _devices.add(device);
      });
    });
  }

  void _onDeviceSelected(BluetoothDevice device) async {
    print('Device selected \"${device.name}\"');
    final event = await FlutterStone.connectToDeviceAndroid(device);

    setState(() {
      _connected = event.connectionSuccessful;
    });
  }

  void _makeTransaction(BuildContext ctx) async {
    final transaction = Transaction(
      "1500",
      12,
      1,
      "Serveloja",
      "5993",
      "Aracaju",
      "49095806",
      "0800",
      "12345678990"
    );

    final result = await FlutterStone.makeTransaction(transaction);
    final message = result.errorCode == null ? 'Transação aprovada!' : 'Erro na transação. Código ${result.errorCode}';
    final snack = SnackBar(content: Text(message),);
    Scaffold.of(ctx).showSnackBar(snack);
  }

  void _connectIOS(BuildContext ctx) async {
    final connectionEvent = await FlutterStone.connectToDeviceIOS();
    final message = connectionEvent.connectionSuccessful ? 'Conectado!' : 'Erro na conexão: ${connectionEvent.errorCode}';
    final snack = SnackBar(content: Text(message),);
    Scaffold.of(ctx).showSnackBar(snack);

    setState(() {
      _connected = connectionEvent.connectionSuccessful;
    });
  }

  void _writeToDisplay() => FlutterStone.writeToDisplay('Serveloja'); 
}