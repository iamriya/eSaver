import 'package:esaver/classes/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Permissions extends StatefulWidget {
  final int id;
  final String location;
  Permissions(this.id, this.location);

  @override
  _PermissionsState createState() => _PermissionsState(this.id, this.location);
}

Future<String> getToken() async {
  final _prefs = await SharedPreferences.getInstance();
  return _prefs.getString('token');
}

class _PermissionsState extends State<Permissions> {
  int id;
  String location;
  String grantUserId;
  List accessingUsers = [];

  _PermissionsState(this.id, this.location);

  Map grantedUsers;

  

  Future<List<User>> _getUsers() async {
    String _token = await getToken();

    var response = await http.get(
        Uri.encodeFull('https://smartboi.herokuapp.com/api/location/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_token',
        });

    var jsonData = json.decode(response.body)['users'];
    List<User> users = [];

    for (var u in jsonData) {
      User user = User(u['id'], u['name'], u['username'], u['is_admin'], u['locations']);
      users.add(user);
    }
    
    return users;
  }

  findUserId() async {
    String _token = await getToken();

    var response = await http.get(
        Uri.encodeFull('https://smartboi.herokuapp.com/api/userlist'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_token',
        });

    var jsonData = json.decode(response.body)['users'];
    for (var u in jsonData) {
      if (u['username'] == grantUserId) {
        accessingUsers.add(u['id']);
        // setState(() {
        //   grantedUsers.add(u);
        // });
      }
    }
  }

  _grantUser() async {
    await findUserId();
    String jsonData = '{"users": $accessingUsers}';
    String _token = await getToken();
    var response = await http.put(
        'https://smartboi.herokuapp.com/api/location/$id/addusers',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_token',
        },
        body: jsonData);
    print(response.body);
  }

  _deleteUser() async {
    String jsonData = '{"users": $accessingUsers}';
    String _token = await getToken();
    var response = await http.put(
        'https://smartboi.herokuapp.com/api/location/$id/addusers',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_token',
        },
        body: jsonData);
    print(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage Permissions'),
        ),
        body: Container(
            margin: EdgeInsets.all(15.0),
            child: ListView(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$location',
                    style: TextStyle(
                      fontSize: 22,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  // margin: EdgeInsets.all(10.0),
                  padding: EdgeInsets.only(top: 10, bottom: 15),
                  color: Colors.white24,
                  child: TextFormField(
                    onChanged: (value) {
                      grantUserId = value;
                    },
                    style: TextStyle(color: Colors.black, fontSize: 20),
                    maxLines: 1,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_add,
                        color: Colors.grey,
                        size: 22,
                      ),
                      border:
                          OutlineInputBorder(borderSide: BorderSide(width: 1)),
                      hintText: "Student ID",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                      //labelStyle: TextStyle(color: Colors.black)
                    ),
                  ),
                ),
                SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0)),
                    padding: EdgeInsets.all(7.0),
                    color: Colors.blue,
                    child: Text(
                      "Grant Permission",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    onPressed: () {
                      _grantUser();
                    },
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Accessing',
                    style: TextStyle(
                      fontSize: 20,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Divider(
                  color: Colors.blue,
                  thickness: 5,
                ),
                FutureBuilder(
                    future: _getUsers(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.data == null) {
                        return Container(
                          child: Center(
                            child: Text('Loading...'),
                          ),
                        );
                      } else {
                        return ListView.builder(
                            physics: ScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context, int index) {
                              print(snapshot.data[index].username);
                              accessingUsers.add(snapshot.data[index].id);
                              return Column(
                                children: <Widget>[
                                  ListTile(
                                    leading: Icon(
                                      Icons.person,
                                      size: 25,
                                      color: Colors.grey.shade500,
                                    ),
                                    title: Text(
                                      snapshot.data[index].username,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        size: 25,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: () {
                                        print(accessingUsers.remove(snapshot.data[index].id));
                                          setState(() async {
                                          await _deleteUser();
                                        });
                                      },
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    color: Colors.grey.shade700,
                                  )
                                ],
                              );
                            });
                      }
                    }),
              ],
            )),
      ),
    );
  }
}