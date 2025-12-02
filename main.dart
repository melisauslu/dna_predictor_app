import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HealthRiskApp());
}

class HealthRiskApp extends StatelessWidget {
  const HealthRiskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hastalık Risk Tahmin Uygulaması',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// home page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sağlık Risk Tahmin Uygulaması'),
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => const AuthDialog(isLogin: true));
            },
            child: const Text('Giriş', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => const AuthDialog(isLogin: false));
            },
            child: const Text('Kayıt', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Hangi testi yapmak istiyorsunuz?",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _buildBallButton(
                    context, "Kalp Hastalığı", HeartFormPage(), Colors.red),
                _buildBallButton(
                    context, "Meme Kanseri", CancerFormPage(), Colors.purple),
                _buildBallButton(
                    context, "Diyabet", DiabetesFormPage(), Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBallButton(
      BuildContext context, String text, Widget page, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => page));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// authdialog
class AuthDialog extends StatefulWidget {
  final bool isLogin;
  const AuthDialog({super.key, required this.isLogin});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  
  final TextEditingController adController = TextEditingController();      // isim
  final TextEditingController soyadController = TextEditingController();   // soyisim
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String message = '';

  Future<void> submit() async {

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        (!widget.isLogin &&
            (adController.text.isEmpty || soyadController.text.isEmpty))) {
      setState(() {
        message = "Lütfen tüm alanları doldurun!";
      });
      return;
    }

    final url = widget.isLogin
        ? "http://10.0.2.2:8000/login"
        : "http://10.0.2.2:8000/register";


    final body = widget.isLogin
        ? {
      "email": emailController.text,
      "sifre": passwordController.text,
    }
        : {
      "ad": adController.text,
      "soyad": soyadController.text,
      "email": emailController.text,
      "sifre": passwordController.text,
    };

    try {
      final response = await http.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: json.encode(body));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          message = data['message'] ?? "Başarılı!";
        });


        if (widget.isLogin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', emailController.text);
        }
      } else {
        setState(() {
          message = "Hata: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        message = "Bağlantı hatası: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            if (!widget.isLogin) ...[
              TextField(
                controller: adController,
                decoration: const InputDecoration(labelText: 'Ad'),
              ),
              TextField(
                controller: soyadController,
                decoration: const InputDecoration(labelText: 'Soyad'),
              ),
            ],
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            const SizedBox(height: 10),
            Text(message,
                style: TextStyle(
                    color: message.startsWith("Hata") ||
                        message.startsWith("Bağlantı")
                        ? Colors.red
                        : Colors.green)),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat')),
        ElevatedButton(
            onPressed: submit,
            child: Text(widget.isLogin ? 'Giriş' : 'Kayıt')),
      ],
    );
  }
}

// formtemplate
class FormPageTemplate extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> fields;
  final String apiUrl;

  const FormPageTemplate(
      {super.key, required this.title, required this.fields, required this.apiUrl});

  @override
  State<FormPageTemplate> createState() => _FormPageTemplateState();
}

class _FormPageTemplateState extends State<FormPageTemplate> {
  final Map<String, TextEditingController> controllers = {};
  String _result = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    for (var f in widget.fields) {
      controllers[f['name']] = TextEditingController();
    }
  }

  Future<void> predictRisk() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    for (var f in widget.fields) {
      if (controllers[f['name']]!.text.isEmpty) {
        setState(() {
          _result = "Lütfen tüm zorunlu alanları doldurun.";
          _loading = false;
        });
        return;
      }
    }

    final Map<String, dynamic> requestBody = {};
    for (var f in widget.fields) {
      if (f['type'] == 'int') {
        requestBody[f['name']] = int.tryParse(controllers[f['name']]!.text) ?? 0;
      } else {
        requestBody[f['name']] = double.tryParse(controllers[f['name']]!.text) ?? 0.0;
      }
    }

    try {
      final response = await http.post(Uri.parse(widget.apiUrl),
          headers: {"Content-Type": "application/json"},
          body: json.encode(requestBody));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _result = "Risk: ${data.values.last}%";
        });
      } else {
        setState(() {
          _result = "Sunucu hatası: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Bağlantı hatası: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget buildTextField(Map<String, dynamic> field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextField(
        controller: controllers[field['name']],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(
          labelText: field['label'],
          hintText: field['range'],
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: widget.fields.map(buildTextField).toList(),
              ),
            ),
            const SizedBox(height: 10),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                onPressed: predictRisk, child: const Text("Tahmin Et")),
            const SizedBox(height: 10),
            Text(_result,
                style: const TextStyle(fontSize: 18, color: Colors.green))
          ],
        ),
      ),
    );
  }
}

// heartform
class HeartFormPage extends StatelessWidget {
  HeartFormPage({super.key});

  final List<Map<String, dynamic>> fields = [
    {"name": "age", "label": "Yaş", "type": "int", "range":"0-120"},
    {"name": "sex", "label": "Cinsiyet (Erkek=1, Kadın=0)", "type": "int", "range":"0-1"},
    {"name": "chest_pain_type", "label": "Göğüs ağrısı tipi", "type": "int", "range":"0-3"},
    {"name": "resting_bp_s", "label": "Dinlenme Tansiyonu", "type": "double", "range":"80-200"},
    {"name": "cholesterol", "label": "Kolesterol", "type": "double", "range":"100-400"},
    {"name": "fasting_blood_sugar", "label": "Açlık kan şekeri >120 mg/dL?", "type": "int", "range":"0-1"},
    {"name": "resting_ecg", "label": "Dinlenme ECG", "type": "int", "range":"0-2"},
    {"name": "max_heart_rate", "label": "Maksimum Kalp Hızı", "type": "double", "range":"60-220"},
    {"name": "exercise_angina", "label": "Egzersiz Anginası", "type": "int", "range":"0-1"},
    {"name": "oldpeak", "label": "Oldpeak", "type": "double", "range":"0-6"},
    {"name": "ST_slope", "label": "ST Eğim", "type": "int", "range":"0-2"},
  ];

  @override
  Widget build(BuildContext context) {
    return FormPageTemplate(
        title: "Kalp Hastalığı Risk Formu",
        fields: fields,
        apiUrl: "http://10.0.2.2:8000/predict/heart");
  }
}

// cancerform
class CancerFormPage extends StatelessWidget {
  CancerFormPage({super.key});

  final List<Map<String, dynamic>> fields = [
    {"name": "radius_mean", "label": "Ortalama Yarıçap", "type": "double", "range":"12-25"},
    {"name": "texture_mean", "label": "Ortalama Doku", "type": "double", "range":"10-40"},
    {"name": "perimeter_mean", "label": "Ortalama Çevre", "type": "double", "range":"70-200"},
    {"name": "area_mean", "label": "Ortalama Alan", "type": "double", "range":"200-2000"},
    {"name": "smoothness_mean", "label": "Ortalama Düzgünlük", "type": "double", "range":"0-1"},
    {"name": "compactness_mean", "label": "Ortalama Kompaktlık", "type": "double", "range":"0-1"},
    {"name": "concavity_mean", "label": "Ortalama Çukurlaşma", "type": "double", "range":"0-1"},
    {"name": "concave_points_mean", "label": "Ortalama Çukur Noktaları", "type": "double", "range":"0-1"},
    {"name": "symmetry_mean", "label": "Ortalama Simetri", "type": "double", "range":"0-1"},
    {"name": "fractal_dimension_mean", "label": "Ortalama Fraktal Boyut", "type": "double", "range":"0-1"},
    {"name": "radius_se", "label": "SE Yarıçap", "type": "double", "range":"0-2"},
    {"name": "texture_se", "label": "SE Doku", "type": "double", "range":"0-2"},
    {"name": "perimeter_se", "label": "SE Çevre", "type": "double", "range":"0-5"},
    {"name": "area_se", "label": "SE Alan", "type": "double", "range":"0-50"},
    {"name": "smoothness_se", "label": "SE Düzgünlük", "type": "double", "range":"0-0.1"},
    {"name": "compactness_se", "label": "SE Kompaktlık", "type": "double", "range":"0-0.5"},
    {"name": "concavity_se", "label": "SE Çukurlaşma", "type": "double", "range":"0-0.5"},
    {"name": "concave_points_se", "label": "SE Çukur Noktaları", "type": "double", "range":"0-0.2"},
    {"name": "symmetry_se", "label": "SE Simetri", "type": "double", "range":"0-0.2"},
    {"name": "fractal_dimension_se", "label": "SE Fraktal Boyut", "type": "double", "range":"0-0.1"},
    {"name": "radius_worst", "label": "En Kötü Yarıçap", "type": "double", "range":"10-40"},
    {"name": "texture_worst", "label": "En Kötü Doku", "type": "double", "range":"10-50"},
    {"name": "perimeter_worst", "label": "En Kötü Çevre", "type": "double", "range":"50-250"},
    {"name": "area_worst", "label": "En Kötü Alan", "type": "double", "range":"100-2500"},
    {"name": "smoothness_worst", "label": "En Kötü Düzgünlük", "type": "double", "range":"0-1"},
    {"name": "compactness_worst", "label": "En Kötü Kompaktlık", "type": "double", "range":"0-2"},
    {"name": "concavity_worst", "label": "En Kötü Çukurlaşma", "type": "double", "range":"0-2"},
    {"name": "concave_points_worst", "label": "En Kötü Çukur Noktaları", "type": "double", "range":"0-1"},
    {"name": "symmetry_worst", "label": "En Kötü Simetri", "type": "double", "range":"0-1"},
    {"name": "fractal_dimension_worst", "label": "En Kötü Fraktal Boyut", "type": "double", "range":"0-1"},
  ];


  @override
  Widget build(BuildContext context) {
    return FormPageTemplate(
        title: "Meme Kanseri Risk Formu",
        fields: fields,
        apiUrl: "http://10.0.2.2:8000/predict/cancer");
  }
}

// diabetesform
class DiabetesFormPage extends StatelessWidget {
  DiabetesFormPage({super.key});

  final List<Map<String, dynamic>> fields = [
    {"name": "Pregnancies", "label": "Gebelik Sayısı", "type": "int", "range":"0+"},
    {"name": "Glucose", "label": "Glukoz", "type": "double", "range":"70-200"},
    {"name": "BloodPressure", "label": "Kan Basıncı", "type": "double", "range":"60-120"},
    {"name": "SkinThickness", "label": "Cilt Kalınlığı", "type": "double", "range":"10-50"},
    {"name": "Insulin", "label": "İnsülin", "type": "double", "range":"0-200"},
    {"name": "BMI", "label": "Vücut Kitle İndeksi", "type": "double", "range":"15-50"},
    {"name": "DiabetesPedigreeFunction", "label": "Diyabet Soy Geçmişi", "type": "double", "range":"0-2"},
    {"name": "Age", "label": "Yaş", "type": "int", "range":"0-120"},
  ];

  @override
  Widget build(BuildContext context) {
    return FormPageTemplate(
        title: "Diyabet Risk Formu",
        fields: fields,
        apiUrl: "http://10.0.2.2:8000/predict/diabetes");
  }
}
