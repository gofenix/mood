import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mood/eventbus.dart';
import 'package:mood/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'i';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> pages = [DailyPage(), LearnPage()];

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.house), label: "日记"),
          BottomNavigationBarItem(icon: Icon(Icons.house), label: "学习"),
        ],
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (context) {
                return Container(
                  height: MediaQuery.of(context).size.height - 60,
                  child: EditPage(),
                );
              });
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerDocked, // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class DailyPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _DailyPageState();
  }
}

class _DailyPageState extends State<DailyPage> {
  Future<Map<String, List<String>?>> _getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();

    Map<String, List<String>?> result = {};

    for (var key in keys) {
      try {
        DateTime.parse(key);
        result[key] = prefs.getStringList(key);
      } catch (e) {
        print(e);
        continue;
      }
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    bus.on("moods", (arg) {
      if (mounted) {
        setState(() {
          print("moods----------------------");
        });
      }
    });
  }

  Widget buildDayCard(Map<String, List<String>?>? data) {
    if (data == null) {
      return Center(
        child: Text("create one"),
      );
    }

    List<String> _keys = data.keys.toList();
    if (_keys == null) {
      return Center(
        child: Text("create one"),
      );
    }
    _keys.sort();

    var w = <Widget>[];
    for (var key in _keys.reversed) {
      if (data[key] != null) {
        var card = Card(
          child: ListTile(
            title: Row(
              children: [
                Icon(Icons.calendar_today),
                SizedBox(width: 10),
                Text(key),
              ],
            ),
            subtitle: buildItemCard(data[key]),
          ),
        );

        w.add(card);
        w.add(Divider(height: 10));
      }
    }

    return Column(children: w);
  }

  List<Widget> _previewImages(List<dynamic>? paths) {
    if (paths == null) {
      return <Widget>[];
    }

    return <Widget>[
      for (var f in paths)
        kIsWeb
            ? Image.network(
                f,
                fit: BoxFit.cover,
              )
            : Image.file(
                File(f),
                fit: BoxFit.cover,
              )
    ];
  }

  Widget buildItemCard(List<String>? data) {
    if (data == null) {
      return Center(
        child: Text("item card"),
      );
    }

    var w = <Widget>[];
    for (var item in data.reversed) {
      Map<String, dynamic> map = {};
      try {
        map = jsonDecode(item);
      } catch (e) {
        print(e);
        continue;
      }

      var card = Card(
        child: ListTile(
          leading: Icon(Icons.emoji_emotions),
          title: Row(
            children: [
              Text(map["emo"], textScaleFactor: 2),
              SizedBox(width: 10),
              Text(
                formatHourMinute(DateTime.parse(map["datetime"])),
                textScaleFactor: 0.8,
              ),
            ],
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(map["note"]),
              ..._previewImages(map["images"]),
            ],
          ),
        ),
      );

      w.add(card);
    }

    return Column(children: w);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      builder: ((context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text("error: ${snapshot.error}");
          } else {
            Map<String, List<String>?>? moods = snapshot.data;
            if (moods == null) {
              return Center(
                child: Text("create one"),
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: buildDayCard(moods),
              ),
            );
          }
        } else {
          return CircularProgressIndicator();
        }
      }),
      future: _getNotes(),
    );
  }
}

class LearnPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _LearnPageState();
  }
}

class _LearnPageState extends State<LearnPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Center(
      child: Text("WIP"),
    );
  }
}

class EditPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _EditPageState();
  }
}

class _EditPageState extends State<EditPage> {
  DateTime _dateTime = DateTime.now();
  String? _emo;
  String? _note;

  late ImagePicker _picker;
  List<XFile>? _imageFiles;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _picker = ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            height: 150,
                            child: CupertinoDatePicker(
                              onDateTimeChanged: (value) {
                                setState(() {
                                  _dateTime = value;
                                });
                              },
                              initialDateTime: _dateTime,
                            ),
                          );
                        });
                  },
                  child: Text("${formatDateTime(_dateTime)}",
                      textScaleFactor: 1.5),
                ),
              ],
            ),
            SizedBox(height: 30),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("你感觉怎么样？", textScaleFactor: 2),
                Card(
                  child: ListTile(
                    title: Text("小情绪"),
                    subtitle: Row(
                      children: [
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _emo = "开心";
                                });
                              },
                              icon: Icon(Icons.emoji_emotions),
                              color: (_emo == "开心" ? Colors.red : Colors.grey),
                            ),
                            Text("开心"),
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _emo = "还行";
                                });
                              },
                              icon: Icon(Icons.emoji_emotions),
                              color: (_emo == "还行" ? Colors.red : Colors.grey),
                            ),
                            Text("还行"),
                          ],
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _emo = "难过";
                                });
                              },
                              icon: Icon(Icons.emoji_emotions),
                              color: (_emo == "难过" ? Colors.red : Colors.grey),
                            ),
                            Text("难过"),
                          ],
                        ),
                      ],
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Divider(height: 2),
                SizedBox(height: 15),
                Text("你这一阵子都在忙些什么？", textScaleFactor: 1.8),
                SizedBox(height: 10),
                Card(
                  child: ListTile(
                    title: Row(
                      children: [Icon(Icons.book), Text("笔记")],
                    ),
                    subtitle: TextFormField(
                      restorationId: "biji",
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (String? value) {
                        _note = value;
                      },
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                      title: Row(
                        children: [
                          Icon(Icons.photo),
                          Text("照片"),
                        ],
                      ),
                      subtitle: Column(
                        children: [
                          ElevatedButton(
                            child: Text("轻点选择照片"),
                            onPressed: () async {
                              final files = await _picker.pickMultiImage();
                              setState(() {
                                _imageFiles = files;
                              });
                            },
                          ),
                          ...() {
                            var images = <Widget>[];
                            if (_imageFiles != null) {
                              for (var f in _imageFiles!) {
                                images.add(
                                  kIsWeb
                                      ? Image.network(
                                          f.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(f.path),
                                          fit: BoxFit.cover,
                                        ),
                                );
                              }
                            }
                            return images;
                          }()
                        ],
                      )),
                ),
                SizedBox(
                  height: 30,
                ),
                Center(
                  child: IconButton(
                    onPressed: () async {
                      if (_emo == null || _note == null) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return SimpleDialog(
                              children: [Center(child: Text("请记录情绪或日记"))],
                            );
                          },
                        );
                        return;
                      }

                      final prefs = await SharedPreferences.getInstance();

                      final key = getKey(_dateTime);
                      var olds = await prefs.getStringList(key) ?? [];

                      final model = {
                        "emo": _emo,
                        "datetime": formatDateTime(_dateTime),
                        "note": _note,
                        "images": getImagePaths(_imageFiles)
                      };
                      olds.add(json.encode(model));
                      await prefs.setStringList(key, olds);
                      bus.emit("moods", olds);
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_forward_ios),
                    iconSize: 50,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
