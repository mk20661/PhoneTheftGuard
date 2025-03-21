import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:_HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget{
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage>{
  int _selectedIndex = 2;
  final List<Widget> _pages = [
    Center(child: Text("Search Page", style: TextStyle(fontSize: 24))),
    Center(child: Text("History Data", style: TextStyle(fontSize: 24))),
    Center(child: Text("Home", style: TextStyle(fontSize: 24))),
    Center(child: Text("Community", style: TextStyle(fontSize: 24))),
    Center(child: Text("Setting", style: TextStyle(fontSize: 24))),
  ];
    void oneTapOnBottom(int index){
      setState(() {
        _selectedIndex = index;
      });
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: oneTapOnBottom,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          iconSize: 28, 
          showUnselectedLabels: true, 
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "History Data"),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: "Community"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Setting"),
          ],
        ),
      );
    }
}