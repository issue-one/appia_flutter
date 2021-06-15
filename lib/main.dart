import 'dart:io';

import 'package:appia/blocs/screens/search.dart';
import 'package:appia/blocs/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/p2p/p2p.dart';
import 'p2p/namester_client.dart';
import 'p2p/p2p.dart';
import 'p2p/transports/transports.dart';
import 'screens/router.dart' as AppiaRouter;

void main() {
  // use this async iife to set up a dumb echo server on the local machine
  // for testing
  () async {
    try {
      var transport = new WsTransport();
      var listener = await transport.listen(
        WsListeningAddress(
          InternetAddress.tryParse("127.0.0.1")!,
          8088, // note the different port
        ),
      );
      listener.incomingConnections
          .map((conn) => new EventedConnection(
                conn,
                onMessage: (_, msg) {
                  print("server got message ${msg.toJson()}");
                },
              ))
          .forEach((conn) {
        print("server got connection from ${conn.connection.peerAddress}");
        conn.setListener(
          "echo",
          (connection, data) =>
              connection.emitEvent(EventMessage("echo", data)),
        );
      });
    } catch (err) {
      print("err seting up dumb server: $err");
    }
  }();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      // provide repositorys first
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (context) => P2PNode(
              HttpNamesterProxy(Uri.parse("PLACEHODLER")),
              tports: [WsTransport()],
            ),
          ),
        ],
        // then come the blocs
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => P2PBloc(context.read<P2PNode>())),
            BlocProvider(create: (context) => SessionBloc()),
            BlocProvider(
                create: (context) => SearchScreenBloc(context.read<P2PBloc>()))
          ],
          child: MaterialApp(
            title: 'Appia',
            theme: ThemeData(
              primarySwatch: Colors.pink,
            ),
            onGenerateRoute: AppiaRouter.generateRoute,
          ),
        ),
      );
}
