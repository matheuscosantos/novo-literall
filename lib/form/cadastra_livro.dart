import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';

//Essa tela precisa ser Stateful para utilizar o geolocator de forma assíncrona
class FormularioLivro extends StatefulWidget {
  @override
  _FormularioLivroState createState() => _FormularioLivroState();
}

class _FormularioLivroState extends State<FormularioLivro> {

  final _auth = FirebaseAuth.instance;
  dynamic usuario;
  String telefoneUsuario;
  String _emailUsuario;
  String _nomeUsuario;
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
      _nomeUsuario = usuario.displayName;
    });
  }

  @override
  Widget build(BuildContext context) {
    var snapshots = Firestore.instance
        .collection('livros')
        .where('excluido', isEqualTo: false)
        .where('email', isEqualTo: _emailUsuario)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus livros'),
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
            return Center(child: Text('Nenhum livro cadastrado'));
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
                  child: ListTile(
                    isThreeLine: true,
                    leading: IconButton(
                        icon: Icon(
                          livro['disponivel']
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        onPressed: () => document.reference.updateData({'disponivel' : !livro['disponivel']})
                    ),
                    title: Text(livro['titulo']),
                    subtitle: Text(livro['autor']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => document.reference.updateData({'excluido' : !livro['excluido']}),
                    ),
                  ),
                );
              });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          modalCreate(context);
        },
        tooltip: 'Adiciona',
        child: Icon(Icons.add),
      ),
    );
  }

  Future modalCreate(BuildContext context) {
    var form = GlobalKey<FormState>();

    var titulo = TextEditingController();
    var autor = TextEditingController();
    var telefone = TextEditingController();


    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Título'),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Título do livro',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      )
                    ),
                    controller: titulo,
                    validator: (value){
                      if(value.isEmpty){
                        return 'Este campo não pode ser vazio';
                      }
                      return null;
                    },
                  ),


                  Text('Autor'),
                  TextFormField(
                    decoration: InputDecoration(
                        hintText: 'Autor do livro',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        )
                    ),
                    controller: autor,
                    validator: (value){
                      if(value.isEmpty){
                        return 'Este campo não pode ser vazio';
                      }
                      return null;
                    },
                  ),


                  Text('Telefone'),
                  TextFormField(
                    decoration: InputDecoration(
                        hintText: 'Telefone para contato',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        )
                    ),
                    controller: telefone,
                    validator: (value){
                      if(value.isEmpty){
                        return 'Este campo não pode ser vazio';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar')),
              FlatButton(
                  onPressed: () async{

                    if(form.currentState.validate()){
                      await Firestore.instance.collection('livros').add({
                        'titulo':titulo.text,
                        'autor': autor.text,
                        'telefone': telefone.text,
                        'email': _emailUsuario,
                        'contato': _nomeUsuario,
                        'cidade': _cidade,
                        'estado': _estado,
                        'disponivel': true,
                        'data': Timestamp.now(),
                        'excluido': false,
                      });

                      Navigator.of(context).pop();
                    }
                  },
                  color: Colors.green,
                  child: Text('Salvar')),
            ],
          );
        });
  }
}
