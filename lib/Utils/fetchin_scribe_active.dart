import 'package:eye_connect/Utils/device_storage.dart';
import 'package:eye_connect/Utils/redirect_to_call.dart';
import 'package:eye_connect/Utils/update_scribe_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ScribeActiveRequest extends StatefulWidget {
  @override
  _ScribeActiveRequestState createState() => _ScribeActiveRequestState();
}

class _ScribeActiveRequestState extends State<ScribeActiveRequest> {
  String? getCurrentUID() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _showThankYouDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Icon(Icons.star_border, color: Colors.amberAccent, size: 50),
          content: Text('Thanks For Your Kind Help.'),
          actions: <Widget>[
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  File? file;

  Future<void> image_pick(ImageSource source, String number, String? uid) async {
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You need to be logged in to perform this action')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        file = File(pickedFile.path);
      });
      await _showThankYouDialog();
      // Uncomment the following line when you implement updateStatus
      // await updateStatus(number, uid);
    }
  }

  Future<List<Map<String, dynamic>>> fetchScribeRequests() async {
    final uid = getCurrentUID();
    if (uid == null) return [];

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Scribe Need Request')
        .where('AssignedTo', isEqualTo: uid)
        .get();

    return querySnapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add document ID to the map
          return data;
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchScribeRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No active scribe requests found.',style: TextStyle(color: Colors.white)));
        } else {
          final scribeRequests = snapshot.data!;
          return ListView.builder(
            itemCount: scribeRequests.length,
            itemBuilder: (context, index) {
              final request = scribeRequests[index];
              return buildRequestCard(request, index);
            },
          );
        }
      },
    );
  }

  Widget buildRequestCard(Map<String, dynamic> request, int index) {
    return Container(
      margin: EdgeInsets.all(10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Pending ${index + 1}'),
          Container(
            width: double.infinity,
            height: 310,
            padding: EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green, width: 3.0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                buildInfoRow(Icons.person, "Name", request["Name"]),
                buildInfoRow(Icons.task, "Task", request["Work"]),
                buildInfoRow(Icons.calendar_month, "Date", request["Date"]),
                buildInfoRow(Icons.language, "Language", request["Required Language"]),
                buildInfoRow(Icons.location_on_outlined, "Location", request["Place"]),
                buildInfoRow(Icons.timer, "Total Duration", request["Total Duration"]),
                Divider(thickness: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildActionButton(
                      Icons.call,
                      () => makePhoneCall(request["phoneNumber"]),
                    ),
                    buildActionButton(
                      Icons.upload,
                      () => image_pick(ImageSource.camera, request['phoneNumber'], getCurrentUID()),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon),
        Text(" $label: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(value ?? "Not specified", style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(width: 0.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(icon),
      ),
    );
  }
}