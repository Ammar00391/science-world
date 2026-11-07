import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/weekly_challenge_service.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});
  @override State<GamificationPage> createState() => _GamificationPageState();
}
class _GamificationPageState extends State<GamificationPage> {
  final _game = GamificationService();
  final _sound = SoundService();
  final _weekly = WeeklyChallengeService();
  int _weeklyPoints = 0;
  GamificationSnapshot? _stats;
  bool _challengeRunning = false;
  int _seconds = 30;
  int _challengeScore = 0;
  Timer? _timer;
  int _a = 7, _b = 5;
  String _message = 'ابدأ بخطوة صغيرة؛ الاستمرار يصنع الفرق.';
  final _messages = const [
    'كل سؤال تحله يقربك من هدفك 🎯',
    'لا تحتاج أن تكون مثاليًا، فقط استمر 💙',
    'خمس دقائق تركيز أفضل من ساعة تشتت.',
    'أنت تبني مستقبلك سؤالًا بعد سؤال.',
    'الخطأ فرصة لفهم أعمق، وليس نهاية المحاولة.',
  ];
  @override void initState() { super.initState(); _refresh(); _message = _messages[DateTime.now().day % _messages.length]; }
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  Future<void> _refresh() async { final s = await _game.load(); final weekly = await _weekly.points(); if (mounted) setState(() { _stats = s; _weeklyPoints = weekly; }); }
  Future<void> _answer(bool correct) async {
    if (!_challengeRunning) return;
    if (correct) { _challengeScore++; await _sound.playCorrect(); } else { await _sound.playWrong(); }
    _newQuestion();
    if (mounted) setState(() {});
  }
  void _newQuestion() { final r = Random(); _a = r.nextInt(12) + 2; _b = r.nextInt(9) + 2; }
  Future<void> _startChallenge() async {
    _timer?.cancel();
    setState(() { _challengeRunning = true; _seconds = 30; _challengeScore = 0; _newQuestion(); });
    await _sound.playChallengeStart();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) { t.cancel(); return; }
      if (_seconds <= 1) {
        t.cancel(); setState(() { _seconds = 0; _challengeRunning = false; });
        if (_challengeScore > 0) { for (var i=0;i<_challengeScore;i++) { await _game.recordCorrectAnswer(xp: 5); } }
        await _game.recordStudySession(); await _weekly.addPoints(_challengeScore * 5); await _sound.playGoalComplete(); await _refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('انتهى التحدي! أجبت $_challengeScore إجابة صحيحة، وحصلت على ${_challengeScore * 5} XP.')));
      } else { setState(() => _seconds--); if (_seconds <= 5) await _sound.playChallengeTick(); }
    });
  }
  @override Widget build(BuildContext context) {
    final s = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('رحلة الإنجاز')),
      body: Directionality(textDirection: TextDirection.rtl, child: s == null ? const Center(child:CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xff102b55),Color(0xff1769aa)]),borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            const Text('مستكشف العلوم', style: TextStyle(color:Colors.white70)), const SizedBox(height:6),
            Text('المستوى ${s.level}',style: const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.bold)),
            const SizedBox(height:12), LinearProgressIndicator(value:s.levelProgress,minHeight:9,backgroundColor:Colors.white24,color:Colors.lightBlueAccent),
            const SizedBox(height:8), Text('${s.xpInLevel}/100 XP نحو المستوى التالي',style: const TextStyle(color:Colors.white)),
            const SizedBox(height:14), Row(children:[_stat('⭐','${s.xp}','نقاط الخبرة'),_stat('🔥','${s.streak}','أيام متتالية'),_stat('✓','${s.correctAnswers}','إجابة صحيحة')]),
          ])),
          const SizedBox(height:16), Card(child: Padding(padding: const EdgeInsets.all(16),child: Row(crossAxisAlignment: CrossAxisAlignment.start,children:[const Icon(Icons.lightbulb,color:Colors.amber,size:30),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('دفعة اليوم',style:TextStyle(fontWeight:FontWeight.bold,fontSize:17)),const SizedBox(height:6),Text(_message)])),IconButton(tooltip:'رسالة أخرى',onPressed:()=>setState(()=>_message=_messages[Random().nextInt(_messages.length)]),icon:const Icon(Icons.refresh))]))),
          const SizedBox(height:12),
          Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('⚡ تحدّي البرق',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:5),const Text('حل أكبر عدد من مسائل الضرب خلال 30 ثانية. كل إجابة صحيحة تمنحك 5 XP.'),
            if (_challengeRunning) ...[const SizedBox(height:14),Text('$_a × $_b = ؟     الوقت: $_seconds ثانية',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),const SizedBox(height:8),Wrap(spacing:8,runSpacing:8,children:List.generate(4,(i){final values=[_a*_b,_a*_b+_a,_a*_b-_b,_a*_b+_b]..shuffle();final answer=values[i];return ElevatedButton(onPressed:()=>_answer(answer==_a*_b),child:Text('$answer'));})),Text('الإجابات الصحيحة: $_challengeScore')]
            else ElevatedButton.icon(onPressed:_startChallenge,icon:const Icon(Icons.bolt),label:const Text('ابدأ تحدّي 30 ثانية')),
          ]))),
          const SizedBox(height:12),
          Card(child: ListTile(leading: const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 30), title: const Text('نقاط التحديات هذا الأسبوع', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('تتجدد دورة النقاط كل يوم اثنين، مع بقاء XP الإجمالي محفوظًا.'), trailing: Text('$_weeklyPoints', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)))),
          const SizedBox(height:12),
          const Text('إنجازاتك',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),
          ..._achievementRows(s),
        ],
      )),
    );
  }
  Widget _stat(String icon,String value,String label)=>Expanded(child:Column(children:[Text(icon,style:const TextStyle(fontSize:21)),Text(value,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:18)),Text(label,style:const TextStyle(color:Colors.white70,fontSize:11))]));
  List<Widget> _achievementRows(GamificationSnapshot s) {
    final rows=[('first_answer','البداية القوية','أجب عن أول سؤال','emoji_events'),('ten_answers','صياد الأسئلة','أجب عن 10 أسئلة','quiz'),('level_two','ارتقاء المستوى','اجمع 100 XP','trending_up'),('three_day_streak','ثلاثة أيام من العزم','ادرس 3 أيام متتالية','local_fire_department'),('seven_day_streak','أسبوع من الإنجاز','ادرس 7 أيام متتالية','workspace_premium')];
    return rows.map((r){final unlocked=s.achievements.contains(r.$1);return Card(child:ListTile(leading:CircleAvatar(backgroundColor:unlocked?Colors.amber.withOpacity(.18):Colors.grey.withOpacity(.12),child:Icon(_icon(r.$4),color:unlocked?Colors.amber:Colors.grey)),title:Text(r.$2),subtitle:Text(r.$3),trailing:Icon(unlocked?Icons.check_circle:Icons.lock,color:unlocked?Colors.green:Colors.grey)));}).toList();
  }
  IconData _icon(String s)=>switch(s){'quiz'=>Icons.quiz,'trending_up'=>Icons.trending_up,'local_fire_department'=>Icons.local_fire_department,'workspace_premium'=>Icons.workspace_premium,_=>Icons.emoji_events};
}
