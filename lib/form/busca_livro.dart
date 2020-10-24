import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';

//Essa tela precisa ser Stateful para utilizar o geolocator de forma assíncrona
class BuscaLivro extends StatefulWidget {
  @override
  _BuscaLivroState createState() => _BuscaLivroState();
}

class _BuscaLivroState extends State<BuscaLivro> {

  final _auth = FirebaseAuth.instance;
  dynamic usuario;
  String _emailUsuario;
  String _cidade = "";
  String _estado = "";

  @override
  void initState(){
    super.initState();
    getCurrentLocation();
    getCurrentUser();
  }

  getCurrentLocation() async {
    final geoposition = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final coordinates = new Coordinates(geoposition.latitude, geoposition.longitude);
    var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    setState(() {
      _cidade = first.subAdminArea;
      _estado = first.adminArea;
    });
  }

  getCurrentUser() async {
    final usuario = await _auth.currentUser();
    setState(() {
      _emailUsuario = usuario.email;
    });
  }

  @override
  Widget build(BuildContext context) {

    var snapshots = Firestore.instance
        .collection('livros')
        .where('excluido', isEqualTo: false)
        .where('disponivel', isEqualTo: true)
        .where('cidade', isEqualTo: _cidade)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Livros para doação na cidade'),
        backgroundColor: Colors.green[300],
      ),
      backgroundColor: Colors.cyan[50],
      body: StreamBuilder(
        stream: snapshots,
        builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data.documents.length == 0) {
            return Center(child: Text('Nenhum livro encontrado.'));
          }

          return ListView.builder(
              itemCount: snapshot.data.documents.length,
              itemBuilder: (BuildContext context, int i) {
                var document = snapshot.data.documents[i];
                var livro = document.data;

                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),

                  child: Container(
                    child: Card(
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                              'Título: ${livro['titulo']}',
                              style: TextStyle(fontSize: 18)
                          ),
                          Text('Autor: ${livro['autor']}'),
                          Text('Contato: ${livro['contato']}' ),
                          Text('Telefone: ' + livro['telefone']),
                          Text(livro['cidade']+' - '+livro['estado'])
                        ]
                      )
                    ),
                  )
                );
              });
        },
      ),
    );
  }
}
