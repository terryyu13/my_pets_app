import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(PetAdoptionApp());
}

class PetAdoptionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的寵物',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PetListPage(),
    );
  }
}

class Pet {
  String? id;
  final String name;
  final String breed;
  final String? image;
  final String description;
  final int age;

  Pet({
    this.id,
    required this.name,
    required this.breed,
    this.image,
    required this.description,
    required this.age,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'image': image,
      'description': description,
      'age': age,
    };
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'],
      breed: json['breed'],
      image: json['image'],
      description: json['description'],
      age: json['age'],
    );
  }
}

class PetListPage extends StatefulWidget {
  @override
  _PetListPageState createState() => _PetListPageState();
}

class _PetListPageState extends State<PetListPage> {
  final CollectionReference petsCollection = FirebaseFirestore.instance.collection('pets');

  Future<void> addPet(Pet newPet) async {
    try {
      await petsCollection.add(newPet.toJson());
    } catch (e) {
      print('Error adding pet: $e');
    }
  }

  Future<void> deletePet(String id) async {
    try {
      await petsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting pet: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的寵物'),
      ),
      body: StreamBuilder(
        stream: petsCollection.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final pets = snapshot.data!.docs.map((doc) {
            return Pet.fromJson(doc.data() as Map<String, dynamic>)..id = doc.id;
          }).toList();
          return ListView.builder(
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return ListTile(
                leading: pet.image != null && pet.image!.isNotEmpty
                    ? Image.file(File(pet.image!))
                    : Icon(Icons.pets),
                title: Text(pet.name),
                subtitle: Text('${pet.breed} - ${pet.age} 歲'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetDetailsPage(pet: pet),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('確定刪除？'),
                        content: Text('確定要刪除 ${pet.name}？'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              deletePet(pet.id!);
                              Navigator.pop(context);
                            },
                            child: Text('確定'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPetPage(addPet: addPet),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class PetDetailsPage extends StatelessWidget {
  final Pet pet;

  PetDetailsPage({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pet.image != null && pet.image!.isNotEmpty
                ? Image.file(File(pet.image!))
                : Icon(Icons.pets, size: 100),
            SizedBox(height: 16),
            Text(
              pet.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${pet.breed} - ${pet.age} 歲',
              style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 8),
            Text(
              '描述：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(pet.description),
          ],
        ),
      ),
    );
  }
}

class AddPetPage extends StatefulWidget {
  final Function(Pet) addPet;

  AddPetPage({required this.addPet});

  @override
  _AddPetPageState createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  File? _image;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('新增寵物'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(labelText: '名稱'),
            ),
            TextFormField(
              controller: breedController,
              decoration: InputDecoration(labelText: '品種'),
            ),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : Icon(Icons.add_a_photo, size: 50),
              ),
            ),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: '描述'),
            ),
            TextFormField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '年齡'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final newPet = Pet(
                  name: nameController.text,
                  breed: breedController.text,
                  image: _image != null ? _image!.path : null,
                  description: descriptionController.text,
                  age: int.tryParse(ageController.text) ?? 0,
                );
                widget.addPet(newPet);
                Navigator.pop(context);
              },
              child: Text('新增寵物'),
            ),
          ],
        ),
      ),
    );
  }
}
