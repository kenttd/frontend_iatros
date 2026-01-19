import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int index;
    if (location.startsWith("/home")) {
      index = 0;
    } else if (location.startsWith("/search") || location.startsWith("/add")) {
      index = 1;
    } else if (location.startsWith("/messaging")) {
      index = 2;
    } else if (location.startsWith("/map")) {
      index = 3;
    } else if (location.startsWith("/settings")) {
      index = 4;
    } else {
      index = 0;
    }

    return FBottomNavigationBar(
      index: index,
      onChange: (i) {
        switch (i) {
          case 0:
            context.go("/home");
            break;
          case 1:
            context.go("/search");
            break;
          case 2:
            context.go("/messaging");
            break;
          case 3:
            context.go("/map");
            break;
          case 4:
            context.go("/settings");
            break;
        }
      },
      children: const [
        FBottomNavigationBarItem(icon: Icon(FIcons.house), label: Text("Home")),
        FBottomNavigationBarItem(
          icon: Icon(FIcons.search),
          label: Text("Search"),
        ),
        FBottomNavigationBarItem(
          icon: Icon(FIcons.messageCircle),
          label: Text("Messages"),
        ),
        FBottomNavigationBarItem(icon: Icon(Icons.map), label: Text("Map")),
        FBottomNavigationBarItem(
          icon: Icon(FIcons.cog),
          label: Text("Settings"),
        ),
      ],
    );
  }
}
