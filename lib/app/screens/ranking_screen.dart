import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ranking_service.dart';
import 'package:qadam_app/app/components/loading_widget.dart';
import 'package:qadam_app/app/components/error_widget.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<RankingService>(context, listen: false).fetchRankings());
  }

  @override
  Widget build(BuildContext context) {
    final rankingService = Provider.of<RankingService>(context);
    final rankings = rankingService.rankings;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Reyting'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: rankings.isEmpty
          ? const Center(child: Text('Reytingda foydalanuvchilar yo‘q.'))
          : Column(
              children: [
                if (rankings.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Eng yuqori foydalanuvchi:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(rankings.first.name,
                            style:
                                TextStyle(fontSize: 18, color: Colors.green)),
                        Text('Qadam: ${rankings.first.steps}'),
                        const SizedBox(height: 10),
                        Text('Eng past foydalanuvchi:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(rankings.last.name,
                            style: TextStyle(fontSize: 18, color: Colors.red)),
                        Text('Qadam: ${rankings.last.steps}'),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: ListView.separated(
                    itemCount: rankings.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final user = rankings[i];
                      return ListTile(
                        leading: Text('#${user.rank}'),
                        title: Text(
                            user.name.isNotEmpty ? user.name : user.userId),
                        trailing: Text('${user.steps} qadam'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
