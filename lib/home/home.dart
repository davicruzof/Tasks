import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _todoConttoller = TextEditingController();

  List _todoList = [];

  Map<String, dynamic> _lastRemove;
  int _LastRemovePosition;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _readData().then((data){
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a,b){
        if(a["ok"] && !b["ok"]){
          return 1;
        }else if(!a["ok"] && b["ok"]){
          return -1;
        }else{
          return 0;
        }
      });
      _saveData();
    });
    return null;
  }

  void _addTodo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _todoConttoller.text;
      _todoConttoller.text = "";
      newTodo["ok"] = false;
      _todoList.add(newTodo);

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Lista de Tarefas",
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _todoConttoller,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(
                        color: Colors.blueAccent,
                      )
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _todoList.length,
                itemBuilder: buildItem,
              ),
            )
          )
        ],
      ),
    );
  }

  Widget buildItem (context, index){
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),
      direction: DismissDirection.startToEnd,
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      onDismissed: (direction){
        setState(() {
          _lastRemove = Map.from(_todoList[index]);
          _LastRemovePosition = index;
          _todoList.removeAt(index);
          _saveData();
          
          final snack = SnackBar(
              content: Text("Tarefa ${_lastRemove["title"]} removida!"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: (){
                  setState(() {
                    _todoList.insert(_LastRemovePosition, _lastRemove);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();    // ADICIONE ESTE COMANDO
          Scaffold.of(context).showSnackBar(snack);
        });
      },
      child: CheckboxListTile(
        onChanged: (c){
          setState(() {
            _todoList[index]["ok"] = c;
            _saveData();
          });
        },
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(
              _todoList[index]["ok"] ? Icons.check : Icons.error
          ),
        ),
      ),
    );
  }


  Future<File> _getFile() async{
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async{
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async{
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch(e){
      return null;
    }
  }
}