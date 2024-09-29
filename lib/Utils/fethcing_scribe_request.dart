import 'package:eye_connect/Utils/device_storage.dart';
import 'package:eye_connect/Utils/update_scribe_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// class ScribeRequestsTab extends StatefulWidget {
//   @override
//   _ScribeRequestsTabState createState() => _ScribeRequestsTabState();
// }

// class _ScribeRequestsTabState extends State<ScribeRequestsTab> {
//   Future<List<Map<String, dynamic>>> fetchScribeRequests() async {
//     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//         .collection('Scribe Need Request')
//         .get();

//     return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: fetchScribeRequests(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(child: Text('No scribe requests found.'));
//         } else {
//           return ScribeRequestsList(scribeRequests: snapshot.data!);
//         }
//       },
//     );
//   }
// }

// class ScribeRequestsList extends StatefulWidget {
//   final List<Map<String, dynamic>> scribeRequests;

//   ScribeRequestsList({required this.scribeRequests});

//   @override
//   _ScribeRequestsListState createState() => _ScribeRequestsListState();
// }

// class _ScribeRequestsListState extends State<ScribeRequestsList> {
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: widget.scribeRequests.length,
//       itemBuilder: (context, index) {
//         final request = widget.scribeRequests[index];
//         return Dismissible(
//           key: Key('container_$index'), // Unique key for each container
//           background: Container(color: Colors.greenAccent), // Background on swipe
//           onDismissed: (_) {
//             setState(() {
//               widget.scribeRequests.removeAt(index);
//             });
//           },
//           child: Container(
//             margin: EdgeInsets.all(10.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Container ${index + 1}'), // Customize content
//                 Column(
//                   children: [
//                     Text(request['Work']),
//                     const SizedBox(width: 5.0), // Add some space between buttons
//                     ElevatedButton(
//                       onPressed: () {
//                         // Handle button 2 press
//                       },
//                       child: Text('Button 2'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             color: Colors.grey[300],
//           ),
//         );
//       },
//     );
//   }
// }

// Future<List<Map<String, dynamic>>> fetchScribeRequests() async {
//     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//         .collection('Scribe Need Request')
//         .get();

//     return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
//   }


class ScribeRequestsTab extends StatefulWidget {
  @override
  _ScribeRequestsTabState createState() => _ScribeRequestsTabState();
}

class _ScribeRequestsTabState extends State<ScribeRequestsTab> {
  String? getCurrentUID() {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  Future<List<Map<String, dynamic>>> fetchScribeRequests() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Scribe Need Request')
        .where('AssignedTo', isNull: true)
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
          return Center(child: Text('No scribe requests found.'));
        } else {
          final scribeRequests = snapshot.data!;
          return ListView.builder(
            itemCount: scribeRequests.length,
            itemBuilder: (context, index) {
              final request = scribeRequests[index];
              return Dismissible(
                key: Key(request['id'] ?? 'key_$index'),
                background: Container(color: Color.fromARGB(255, 153, 245, 201)),
                onDismissed: (_) {
                  final uid = getCurrentUID();
                  if (uid != null) {
                    updateAssignedTokey(request['id'], uid);
                    setState(() {
                      scribeRequests.removeAt(index);
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You need to be logged in to perform this action')),
                    );
                  }
                },
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Request ${index + 1}'),
                      Container(
                        width: double.infinity,
                        height: 170,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              buildInfoRow(Icons.task, "Task", request["Work"]),
                              buildInfoRow(Icons.calendar_month, "Date", request["Date"]),
                              buildInfoRow(Icons.language, "Language", request["Required Language"]),
                              buildInfoRow(Icons.location_on_outlined, "Location", request["Place"]),
                            ],
                          ),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
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
}

// Assume this function is defined in update_scribe_request.dart
void updateAssignedTokey(String documentId, String uid) async {
  await FirebaseFirestore.instance
      .collection('Scribe Need Request')
      .doc(documentId)
      .update({'AssignedTo': uid});
}