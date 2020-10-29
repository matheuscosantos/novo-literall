import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';

//Essa tela precisa ser Stateful para utilizar o geolocator de forma assíncrona
class FormularioEvento extends StatefulWidget {
  @override
  _FormularioEventoState createState() => _FormularioEventoState();
}

class _FormularioEventoState extends State<FormularioEvento> {

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
        .collection('evento')
        .where('excluido', isEqualTo: false)
        .where('email', isEqualTo: _emailUsuario)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        title: Text('Eventos Criados por mim'),
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
            return Center(child: Text('Nenhum evento cadastrado'));
          }

          return ListView.builder(
              itemCount: snapshot.data.documents.length,
              itemBuilder: (BuildContext context, int i) {
                var document = snapshot.data.documents[i];
                var evento = document.data;

                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: ListTile(
                    isThreeLine: true,
                    leading: IconButton(
                        icon: Icon(
                          evento['disponivel']
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        onPressed: () => document.reference.updateData({'disponivel' : !evento['disponivel']})
                    ),
                    title: Text(evento['nome']),
                    subtitle: Text(evento['descricao']),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => document.reference.updateData({'excluido' : !evento['excluido']}),
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

    var nome = TextEditingController();
    var descricao = TextEditingController();
    //var data = TextEditingController();
    //var horario = TextEditingController();
    var telefone = TextEditingController();
    var endereco = TextEditingController();

    var data = DateFormat("dd-MM-yyyy");
    var horario = DateFormat("HH:mm");

    
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Form(
              key: form,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Evento'),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Nome do Evento',
                        //border: OutlineInputBorder(
                          //borderRadius: BorderRadius.circular(10),
                        //)
                      ),
                      controller: nome,
                      validator: (value){
                        if(value.isEmpty){
                          return 'Este campo não pode ser vazio';
                        }
                        return null;
                      },
                    ),

                    Text('Descrição'),
                    TextFormField(
                      decoration: InputDecoration(
                          hintText: 'Descrição do evento',
                          //border: OutlineInputBorder(
                            //borderRadius: BorderRadius.circular(10),
                          //)
                      ),
                      controller: descricao,
                      validator: (value){
                        if(value.isEmpty){
                          return 'Este campo não pode ser vazio';
                        }
                        return null;
                      },
                    ),

                    Text('Data (${data.pattern})'),
                    DateTimeField(
                      format: data,
                      onShowPicker: (context, currentValue) {
                      return showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          initialDate: currentValue ?? DateTime.now(),
                          lastDate: DateTime(2100));
                      },
                    ),

                    Text('Horário (${horario.pattern})'),
                    DateTimeField(
                      format: horario,
                      onShowPicker: (context, currentValue) async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
                        );
                        return DateTimeField.convert(time);
                      },
                    ),

                    Text('Telefone'),
                    TextFormField(
                      decoration: InputDecoration(
                          hintText: 'Telefone para contato',
                          //border: OutlineInputBorder(
                            //borderRadius: BorderRadius.circular(10),
                          //)
                      ),
                      controller: telefone,
                      validator: (value){
                        if(value.isEmpty){
                          return 'Este campo não pode ser vazio';
                        }
                        return null;
                      },
                    ),

                    Text('Endereço'),
                    TextFormField(
                      decoration: InputDecoration(
                          hintText: 'Endereço do evento',
                          //border: OutlineInputBorder(
                            //borderRadius: BorderRadius.circular(10),
                         //)
                      ),
                      controller: endereco,
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
            ),
            actions: <Widget>[
              FlatButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar')),
              FlatButton(
                  onPressed: () async{

                    if(form.currentState.validate()){
                      await Firestore.instance.collection('evento').add({
                        'nome':nome.text,
                        'descricao': descricao.text,
                        'telefone': telefone.text,
                        'endereco': endereco.text,
                        'email': _emailUsuario,
                        'contato': _nomeUsuario,
                        'cidade': _cidade,
                        'estado': _estado,
                        'horario': horario,
                        'disponivel': true,
                        'data': data,
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
