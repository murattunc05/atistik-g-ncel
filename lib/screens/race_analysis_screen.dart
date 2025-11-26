import 'package:flutter/material.dart';
import '../services/tjk_api_service.dart';

class RaceAnalysisScreen extends StatefulWidget {
  final List<Map<String, String>> horses;

  const RaceAnalysisScreen({super.key, required this.horses});

  @override
  State<RaceAnalysisScreen> createState() => _RaceAnalysisScreenState();
}

class _RaceAnalysisScreenState extends State<RaceAnalysisScreen> {
  bool _isLoading = true;
  List<dynamic> _analysisResults = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeRace();
  }

  Future<void> _analyzeRace() async {
    try {
      final result = await TjkApiService.analyzeRace(widget.horses);
      
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _analysisResults = result['results'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['error'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Koyu arka plan
      appBar: AppBar(
        title: const Text('Yarış Analizi'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? Center(child: Text('Hata: $_error', style: const TextStyle(color: Colors.red)))
              : _buildAnalysisTable(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.greenAccent),
          const SizedBox(height: 20),
          Text(
            'Veriler TJK\'dan çekiliyor ve işleniyor...',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            'Bu işlem birkaç saniye sürebilir.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTable() {
    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: _analysisResults.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final item = _analysisResults[index];
              return _buildAnalysisRow(index + 1, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: const [
          SizedBox(width: 30, child: Text('#', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('AT İSMİ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(flex: 4, child: Text('GÜÇ PUANI', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('HIZ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 2, child: Text('FORM', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11))),
          Expanded(flex: 3, child: Text('TAHMİN', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(int rank, dynamic item) {
    final double score = (item['overallScore'] as num).toDouble();
    final double speed = (item['speedScore'] as num).toDouble();
    final String trend = item['formTrend'];
    final String prediction = item['prediction'];

    Color scoreColor = Colors.red;
    if (score > 80) scoreColor = Colors.green;
    else if (score > 60) scoreColor = Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 30, 
            child: Text(
              '$rank', 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              item['name'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: TextStyle(color: scoreColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey[800],
                  color: scoreColor,
                  minHeight: 4,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              speed.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  trend == 'UP' ? Icons.arrow_upward : Icons.arrow_downward,
                  color: trend == 'UP' ? Colors.green : Colors.red,
                  size: 16,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPredictionColor(prediction).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _getPredictionColor(prediction).withOpacity(0.5)),
              ),
              child: Text(
                prediction,
                style: TextStyle(
                  color: _getPredictionColor(prediction),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPredictionColor(String prediction) {
    switch (prediction) {
      case 'Favori': return Colors.greenAccent;
      case 'Plase': return Colors.blueAccent;
      case 'Süratli': return Colors.orangeAccent;
      case 'Formda': return Colors.purpleAccent;
      default: return Colors.grey;
    }
  }
}
