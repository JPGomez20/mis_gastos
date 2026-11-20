import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('gastos');
  await Hive.openBox('config');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mis Gastos',
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});
  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [const PantallaHoy(), const PantallaSemana()][index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: Colors.orange,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Semana'),
        ],
      ),
    );
  }
}

class PantallaHoy extends StatefulWidget {
  const PantallaHoy({super.key});
  @override
  State<PantallaHoy> createState() => _PantallaHoyState();
}

class _PantallaHoyState extends State<PantallaHoy> {
  double get limiteDiario {
    var box = Hive.box('config');
    return (box.get('limite_diario', defaultValue: 50.0) as num).toDouble();
  }

  List categorias = [
    {'nombre': 'Comida', 'icono': Icons.restaurant, 'color': Colors.orange},
    {'nombre': 'Transporte', 'icono': Icons.directions_bus, 'color': Colors.blue},
    {'nombre': 'Antojos', 'icono': Icons.icecream, 'color': Colors.pink},
    {'nombre': 'Casa', 'icono': Icons.home, 'color': Colors.green},
    {'nombre': 'Salud', 'icono': Icons.local_hospital, 'color': Colors.red},
    {'nombre': 'Otro', 'icono': Icons.more_horiz, 'color': Colors.grey},
  ];

  List metodos = ['Yape', 'BCP', 'EFECTIVO', 'TARJETA'];

  void cambiarLimite() {
    TextEditingController ctrl = TextEditingController(text: limiteDiario.toStringAsFixed(0));
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Tu límite diario'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Ej: 50', prefixText: 'S/ ')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () {
          Hive.box('config').put('limite_diario', double.tryParse(ctrl.text) ?? 50);
          setState(() {});
          Navigator.pop(context);
        }, child: const Text('Guardar')),
      ],
    ));
  }

  void agregarGasto() {
    TextEditingController montoCtrl = TextEditingController();
    TextEditingController notaCtrl = TextEditingController();
    String catSel = 'Comida';
    String metodoSel = 'Yape';
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
      title: const Text('¿En qué gastaste?'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: montoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), decoration: const InputDecoration(prefixText: 'S/ ', hintText: '0.00', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 6, children: categorias.map((c) {
          bool sel = c['nombre'] == catSel;
          return ChoiceChip(label: Text(c['nombre']), selected: sel, selectedColor: c['color'], labelStyle: TextStyle(color: sel ? Colors.white : Colors.black), onSelected: (_) => setDialog(() => catSel = c['nombre']));
        }).toList()),
        const SizedBox(height: 12),
        const Text('¿Cómo pagaste?', style: TextStyle(fontWeight: FontWeight.bold)),
        Wrap(spacing: 6, children: metodos.map((m) {
          bool sel = m == metodoSel;
          return ChoiceChip(label: Text(m), selected: sel, selectedColor: Colors.black, labelStyle: TextStyle(color: sel ? Colors.white : Colors.black), onSelected: (_) => setDialog(() => metodoSel = m));
        }).toList()),
        const SizedBox(height: 12),
        TextField(controller: notaCtrl, decoration: const InputDecoration(labelText: 'Nota ej: Almuerzo', border: OutlineInputBorder())),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () {
          double monto = double.tryParse(montoCtrl.text) ?? 0;
          if (monto <= 0) return;
          Hive.box('gastos').add({'monto': monto, 'categoria': catSel, 'metodo': metodoSel, 'nota': notaCtrl.text, 'fecha': DateTime.now().toString()});
          Navigator.pop(context);
          setState(() {});
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('GUARDAR GASTO', style: TextStyle(color: Colors.white))),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Gastos - Hoy'), backgroundColor: Colors.orange, foregroundColor: Colors.white, actions: [IconButton(icon: const Icon(Icons.settings), onPressed: cambiarLimite)]),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('gastos').listenable(),
        builder: (context, Box box, _) {
          String hoy = DateTime.now().toString().substring(0, 10);
          List gastosHoy = box.values.where((g) => (g['fecha'] as String).substring(0, 10) == hoy).toList();
          gastosHoy.sort((a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String));
          double totalHoy = gastosHoy.fold(0, (sum, g) => sum + (g['monto'] as num).toDouble());
          double queda = limiteDiario - totalHoy;
          double porcentaje = (totalHoy / limiteDiario).clamp(0, 1);
          Color colorBarra = totalHoy > limiteDiario ? Colors.red : totalHoy > limiteDiario * 0.8 ? Colors.orange : Colors.green;
          double totalYape = gastosHoy.where((g) => g['metodo'] == 'YAPE').fold(0, (s, g) => s + (g['monto'] as num).toDouble());
          double totalBcp = gastosHoy.where((g) => g['metodo'] == 'BCP QR').fold(0, (s, g) => s + (g['monto'] as num).toDouble());
          double totalEfectivo = gastosHoy.where((g) => g['metodo'] == 'EFECTIVO').fold(0, (s, g) => s + (g['monto'] as num).toDouble());
          return Column(children: [
            Container(padding: const EdgeInsets.all(20), color: Colors.orange[50], child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Hoy gastaste', style: TextStyle(fontSize: 16, color: Colors.grey)), GestureDetector(onTap: cambiarLimite, child: Text('Límite: S/ ${limiteDiario.toStringAsFixed(0)} ✏️', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)))]),
              const SizedBox(height: 6),
              Text('S/ ${totalHoy.toStringAsFixed(2)}', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: colorBarra)),
              const SizedBox(height: 4),
              Text(queda >= 0 ? 'Te quedan S/ ${queda.toStringAsFixed(2)} hoy' : '¡Te pasaste por S/ ${(-queda).toStringAsFixed(2)}!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorBarra)),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: porcentaje, minHeight: 14, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation<Color>(colorBarra))),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_miniResumen('YAPE', totalYape, Colors.purple), _miniResumen('BCP QR', totalBcp, Colors.blue), _miniResumen('EFECTIVO', totalEfectivo, Colors.green)]),
            ])),
            Padding(padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.receipt, color: Colors.orange), const SizedBox(width: 8), Text('Tus gastos de hoy (${gastosHoy.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])),
            Expanded(child: gastosHoy.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.savings, size: 60, color: Colors.grey), SizedBox(height: 12), Text('Aún no gastaste nada hoy. ¡Bien!')])) : ListView.builder(itemCount: gastosHoy.length, itemBuilder: (context, i) {
              var g = gastosHoy[i];
              String hora = g['fecha'].toString().substring(11, 16);
              var cat = categorias.firstWhere((c) => c['nombre'] == g['categoria'], orElse: () => categorias.last);
              return Dismissible(key: Key(g['fecha'].toString() + i.toString()), direction: DismissDirection.endToStart, background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)), onDismissed: (_) async {
                for (var key in box.keys) { var val = box.get(key); if (val['fecha'] == g['fecha'] && val['monto'] == g['monto']) { await box.delete(key); break; } }
              }, child: Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: ListTile(leading: CircleAvatar(backgroundColor: cat['color'], child: Icon(cat['icono'], color: Colors.white, size: 20)), title: Text(g['nota'].toString().isEmpty ? g['categoria'] : g['nota'], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${g['categoria']} • ${g['metodo']} • $hora'), trailing: Text('- S/ ${(g['monto'] as num).toDouble().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)))));
            })),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: agregarGasto, backgroundColor: Colors.orange, icon: const Icon(Icons.add, color: Colors.white), label: const Text('AGREGAR GASTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
    );
  }

  Widget _miniResumen(String titulo, double monto, Color color) {
    return Column(children: [Text(titulo, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)), Text('S/ ${monto.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))]);
  }
}

class PantallaSemana extends StatelessWidget {
  const PantallaSemana({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Esta Semana'), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('gastos').listenable(),
        builder: (context, Box box, _) {
          DateTime ahora = DateTime.now();
          DateTime inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
          List gastosSemana = box.values.where((g) { DateTime fecha = DateTime.parse(g['fecha']); return fecha.isAfter(inicioSemana.subtract(const Duration(days: 1))); }).toList();
          double totalSemana = gastosSemana.fold(0, (s, g) => s + (g['monto'] as num).toDouble());
          Map<String, double> porCategoria = {};
          Map<String, double> porMetodo = {};
          for (var g in gastosSemana) {
            porCategoria[g['categoria']] = (porCategoria[g['categoria']] ?? 0) + (g['monto'] as num).toDouble();
            porMetodo[g['metodo']] = (porMetodo[g['metodo']] ?? 0) + (g['monto'] as num).toDouble();
          }
          var catOrdenado = porCategoria.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          var metodoOrdenado = porMetodo.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(16)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Gastaste esta semana', style: TextStyle(color: Colors.grey)), const SizedBox(height: 4), Text('S/ ${totalSemana.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))]), Column(children: [Text('${gastosSemana.length} gastos', style: const TextStyle(fontWeight: FontWeight.bold)), Text('Promedio: S/ ${(gastosSemana.isEmpty ? 0 : totalSemana / 7).toStringAsFixed(2)} / día', style: const TextStyle(color: Colors.grey))])])),
            const SizedBox(height: 20),
            const Text('¿En qué se te va más?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (catOrdenado.isEmpty) const Card(child: ListTile(title: Text('Aún no hay gastos esta semana.'))),
            ...catOrdenado.map((e) => Card(child: ListTile(title: Text(e.key), trailing: Text('S/ ${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: LinearProgressIndicator(value: totalSemana == 0 ? 0 : (e.value / totalSemana).clamp(0, 1), backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange))))),
            const SizedBox(height: 20),
            const Text('¿Cómo pagas más?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...metodoOrdenado.map((e) => Card(child: ListTile(leading: Icon(e.key == 'YAPE' ? Icons.smartphone : e.key == 'BCP QR' ? Icons.qr_code : Icons.money, color: Colors.orange), title: Text(e.key), trailing: Text('S/ ${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))))),
          ]));
        },
      ),
    );
  }
}