import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

// import '../Beranda/beranda.dart';
  import '../TanyaBerita/tanya_berita.dart';
  import '../LaporkanBerita/laporkan_berita.dart';

class Menu extends StatefulWidget {
  @override
  MenuState createState() => MenuState();
}


class MenuState extends State<Menu> {
  final navigationKey = GlobalKey<CurvedNavigationBarState>();
  int _currentIndex = 0;

  static MenuState? of(BuildContext context) {
    return context.findAncestorStateOfType<MenuState>();
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    final navigationState = navigationKey.currentState;
    navigationState?.setPage(index);
  }

  final List<Widget> _screens = [
    TanyaBerita(),
    LaporkanBeritaPage(),
  ];

  final List<IconData> _icons = [
    Icons.newspaper_outlined,
    Icons.new_releases_outlined,
  ];

  final List<String> _labels = [
    "Tanya Berita",
    "Laporkan Berita",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        key: navigationKey,
        index: _currentIndex,
        items: List.generate(_icons.length, (i) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[i],
              size: 30,
              color: _currentIndex == i ? Colors.white : Color(0xFF76BC6B),
            ),
            if (_currentIndex != i)
              Text(
                _labels[i],
                style: TextStyle(fontSize: 12, color: Color(0xFF76BC6B)),
              ),
          ],
        )),
        height: 65,
        onTap: changeTab,
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: Color(0xFF76BC6B),
      ),
    );
  }
}