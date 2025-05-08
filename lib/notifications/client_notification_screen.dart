import 'package:flutter/material.dart';

class ClientNotification extends StatefulWidget {
  const ClientNotification({super.key});

  State<ClientNotification> createState() => _ClientNotification();
}

class _ClientNotification extends State<ClientNotification> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notification",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: ()=>Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          "No notifications available",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
