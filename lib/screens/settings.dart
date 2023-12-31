import 'package:enawra/pages/privacy.dart';
import 'package:enawra/pages/terms.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enawra/utils/constants.dart';

class Setting extends StatefulWidget {
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.keyboard_backspace),
        ),
        backgroundColor: Theme.of(context).backgroundColor,
        elevation: 0.0,
        title: Text(
          "Settings",
          style: TextStyle(),
        ),
      ),
      backgroundColor: Theme.of(context).backgroundColor,
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: ListView(
          children: <Widget>[
            ListTile(
                title: Text(
                  "About",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle:
                    Text("A Social Media Application Dedicated to connecting "
                        "Ethiopians Around the World"),
                trailing: Icon(Icons.error)),
            Divider(),
            ListTile(
              title: Text(
                "Dark Mode",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: Text("Use the dark mode"),
              trailing: Consumer<ThemeNotifier>(
                builder: (context, notifier, child) => CupertinoSwitch(
                  onChanged: (val) {
                    notifier.toggleTheme();
                  },
                  value: notifier.dark,
                  activeColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            Divider(),
            ListTile(
              title: Text(
                "Terms of Use",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => Terms(),
                ),
              ),
            ),
            Divider(),
            ListTile(
              title: Text(
                "Privacy Policy",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (_) => Privacy(),
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
