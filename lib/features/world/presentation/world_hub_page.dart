import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/sound_service.dart';

/// Interactive, locally saved side-world systems. Online multiplayer/AI is not
/// simulated here: this page clearly labels local-only activities.
class WorldHubPage extends StatefulWidget {
  const WorldHubPage({super.key});
  @override State<WorldHubPage> createState() => _WorldHubPageState();
}
class _WorldHubPageState extends State<WorldHubPage> {
  final _sound = SoundService();
  final _note = TextEditingController();
  final _companionName = TextEditingController(text: 'رفيق');
  int _xp = 0, _roomLevel = 1, _labLevel = 1, _puzzlesSolved = 0;
  int _focusMinutes = 10, _secondsLeft = 0;
  String _avatar = '🦊', _biome = 'الفضاء', _noteSaved = '';
  bool _running = false, _busy = true;
  Timer? _timer;
  static const _avatars = ['🦊','🐼','🐱','🤖','🦉','🐉'];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _xp=p.getInt('world_xp')??0; _roomLevel=p.getInt('world_room')??1;
      _labLevel=p.getInt('world_lab')??1; _puzzlesSolved=p.getInt('world_puzzles')??0;
      _avatar=p.getString('world_avatar')??'🦊'; _biome=p.getString('world_biome')??'الفضاء';
      _noteSaved=p.getString('world_note')??''; _companionName.text=p.getString('world_companion')??'رفيق';
      _note.text=_noteSaved; _busy=false;
    });
  }
  Future<void> _save(String key, Object value) async { final p=await SharedPreferences.getInstance();
    if(value is int) await p.setInt(key,value); else if(value is String) await p.setString(key,value);
  }
  Future<void> _reward(int points, String label) async {
    setState(()=>_xp+=points); await _save('world_xp',_xp); await _sound.playXp();
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$label — حصلت على $points XP')));
  }
  @override void dispose(){_timer?.cancel();_note.dispose();_companionName.dispose();super.dispose();}
  @override Widget build(BuildContext context) => Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:const Text('عالمي الخاص'),actions:[IconButton(tooltip:'الإعدادات الصوتية',icon:const Icon(Icons.volume_up),onPressed:()=>context.go('/settings'))]),
    body:_busy?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff102a56), Color(0xff176b87)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Text(_avatar, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'عالمك يتطور معك',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$_xp نقطة خبرة • المستوى ${1 + _xp ~/ 100}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_xp % 100) / 100,
                    backgroundColor: Colors.white24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height:18), _section('غرفتي ومختبري',Icons.science,[
        ListTile(leading:const Icon(Icons.king_bed),title:Text('تطوير الغرفة — المستوى $_roomLevel'),subtitle:const Text('كل ترقية تفتح ديكورًا جديدًا (تقدم محلي محفوظ)'),trailing:const Icon(Icons.add_circle_outline),onTap:()=>_upgrade('room')),
        ListTile(leading:const Icon(Icons.biotech),title:Text('المختبر الافتراضي — المستوى $_labLevel'),subtitle:const Text('اختر تجربة آمنة وتعرّف إلى فكرتها'),trailing:const Icon(Icons.arrow_forward_ios,size:16),onTap:()=>_showLab()),
      ]),
      _section('مدينة الألغاز',Icons.travel_explore,[
        ListTile(leading:const Icon(Icons.lock_open),title:const Text('لغز المحطة المهجورة'),subtitle:Text('ألغاز محلولة: $_puzzlesSolved'),trailing:const Icon(Icons.play_arrow),onTap:()=>_puzzle()),
      ]),
      _section('رفيقي الذكي',Icons.smart_toy,[
        Padding(padding:const EdgeInsets.all(12),child:Column(children:[Wrap(spacing:8,children:_avatars.map((a)=>ChoiceChip(label:Text(a,style:const TextStyle(fontSize:22)),selected:_avatar==a,onSelected:(_){setState(()=>_avatar=a);_save('world_avatar',a);})).toList()),TextField(controller:_companionName,decoration:const InputDecoration(labelText:'اسم الرفيق',hintText:'اكتب اسمًا قصيرًا'),onChanged:(v)=>_save('world_companion',v)),const SizedBox(height:8),const Text('الرفيق هنا للتشجيع والتخصيص؛ المحادثة الذكية تحتاج ربط خدمة الذكاء الاصطناعي.')]))
      ]),
      _section('استكشف الكون والعالم',Icons.public,[
        Wrap(spacing:8,runSpacing:8,children:['الفضاء','المحيطات','جسم الإنسان','الغابات'].map((x)=>ChoiceChip(label:Text(x),selected:_biome==x,onSelected:(_)async{setState(()=>_biome=x);await _save('world_biome',x);})).toList()),
        Padding(padding:const EdgeInsets.all(12),child:Text(_exploreText(_biome),style:const TextStyle(fontSize:15))),
      ]),
      _section('استوديو الإبداع',Icons.draw,[
        Padding(padding:const EdgeInsets.all(12),child:Column(children:[TextField(controller:_note,maxLines:5,decoration:const InputDecoration(border:OutlineInputBorder(),labelText:'دفتر الأفكار والمشاريع',hintText:'اكتب فكرة أو خطة أو خريطة ذهنية نصية...')),const SizedBox(height:8),Align(alignment:Alignment.centerLeft,child:FilledButton.icon(onPressed:()async{setState(()=>_noteSaved=_note.text);await _save('world_note',_note.text);await _reward(5,'حُفظ إبداعك');},icon:const Icon(Icons.save),label:const Text('حفظ الفكرة'))),if(_noteSaved.isNotEmpty)Text('آخر نص محفوظ: ${_noteSaved.length} حرف')]))
      ]),
      _section('تحديات الأصدقاء والمجتمع',Icons.groups,[
        const ListTile(leading:Icon(Icons.shield_outlined),title:Text('تحدي محلي على الجهاز'),subtitle:Text('لا يوجد اتصال أو ترتيب عالمي مفعّل في هذه النسخة؛ لا نعرض منافسة وهمية.')),
        FilledButton(onPressed:()=>_reward(10,'أنهيت تحدي اليوم'),child:const Text('إنجاز تحدي فردي +10 XP')),
      ]),
      _section('مساحة الراحة',Icons.spa,[
        Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('مؤقت تركيز هادئ — دون موسيقى محمية'),Wrap(spacing:8,children:[10,15,25].map((m)=>ChoiceChip(label:Text('$m دقيقة'),selected:_focusMinutes==m,onSelected:(_)=>setState(()=>_focusMinutes=m))).toList()),Text(_running?'الوقت المتبقي: ${_secondsLeft~/60}:${(_secondsLeft%60).toString().padLeft(2,'0')}':'المدة المختارة: $_focusMinutes دقيقة'),Row(children:[Expanded(child:FilledButton.icon(onPressed:_running?null:_startFocus,icon:const Icon(Icons.play_arrow),label:const Text('ابدأ'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:_stopFocus,icon:const Icon(Icons.stop),label:const Text('إيقاف')))]),const SizedBox(height:8),Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()=>_sound.playNatureAmbience(),icon:const Icon(Icons.spa),label:const Text('صوت طبيعة هادئ'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:()=>_sound.stopNatureAmbience(),icon:const Icon(Icons.volume_off),label:const Text('إيقاف الصوت')))]),const SizedBox(height:8),const Text('صوت محيطي مولّد خصيصًا للتطبيق؛ التحكم العام ومستوى الصوت من الإعدادات.')]))
      ]),
      const SizedBox(height:20),const Text('حالة الميزات: التقدم والتخصيص والملاحظات والألغاز والمؤقت تعمل محليًا. اللعب الجماعي الحقيقي، محتوى تجارب موسّع، ومحادثة الرفيق تحتاج خدمات/محتوى إضافيًا.',style:TextStyle(color:Colors.grey)),
    ])));
  Widget _section(String title,IconData icon,List<Widget> children)=>Card(margin:const EdgeInsets.only(bottom:14),clipBehavior:Clip.antiAlias,child:ExpansionTile(leading:Icon(icon,color:Theme.of(context).colorScheme.primary),title:Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),initiallyExpanded:true,children:children));
  Future<void> _upgrade(String kind) async { if(kind=='room'){setState(()=>_roomLevel++);await _save('world_room',_roomLevel);}else{setState(()=>_labLevel++);await _save('world_lab',_labLevel);} await _reward(20,'تمت الترقية'); }
  void _showLab(){ showModalBottomSheet(context:context,builder:(c)=>Directionality(textDirection:TextDirection.rtl,child:SafeArea(child:Wrap(children:[const ListTile(title:Text('مختبر العلوم الافتراضي'),subtitle:Text('محاكاة تعليمية مبسطة — لا تستخدم مواد حقيقية')),...[
    ('الكثافة','الكثافة = الكتلة ÷ الحجم. غيّر الكتلة أو الحجم ذهنيًا ولاحظ أثرهما.'),('الدوائر الكهربائية','في دائرة بسيطة مغلقة يمر التيار؛ زيادة المقاومة تقلل التيار عند ثبات الجهد.'),('الرقم الهيدروجيني','القيم الأقل من 7 حمضية، و7 متعادلة، والأكبر من 7 قاعدية.')].map((e)=>ListTile(title:Text(e.$1),subtitle:Text(e.$2),onTap:(){Navigator.pop(c);_reward(3,'استكشاف علمي');}))])))); }
  void _puzzle(){
    showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('لغز المحطة المهجورة'),content:const Text('في دائرة كهربائية بسيطة، انطفأ المصباح بعد انقطاع السلك. ما السبب الأقرب؟'),actions:[
      TextButton(onPressed:(){Navigator.pop(c);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('جرّب مجددًا: التيار يحتاج إلى مسار مغلق.')));},child:const Text('البطارية أصبحت أكبر')),
      TextButton(onPressed:(){Navigator.pop(c);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('ليس تمامًا؛ انقطاع السلك يفتح الدائرة.')));},child:const Text('زاد التيار')),
      FilledButton(onPressed:()async{Navigator.pop(c);setState(()=>_puzzlesSolved++);await _save('world_puzzles',_puzzlesSolved);await _reward(8,'إجابة صحيحة: الدائرة مفتوحة');},child:const Text('انفتح مسار الدائرة'))
    ]));
  }
  void _startFocus(){_timer?.cancel();setState(()=>{_running=true,_secondsLeft=_focusMinutes*60});_timer=Timer.periodic(const Duration(seconds:1),(t){if(!mounted)return;if(_secondsLeft<=1){t.cancel();setState(()=>{_secondsLeft=0,_running=false});_reward(15,'انتهت جلسة التركيز');}else{setState(()=>_secondsLeft--);}});}
  void _stopFocus(){_timer?.cancel();setState(()=>{_running=false,_secondsLeft=0});}
  String _exploreText(String place)=>switch(place){'الفضاء'=>'المسافة بين الأرض والشمس نحو 150 مليون كيلومتر في المتوسط. السنة الضوئية وحدة مسافة لا وحدة زمن.','المحيطات'=>'تغطي المحيطات معظم سطح الأرض، وتؤثر في المناخ عبر تخزين الحرارة ونقلها.','جسم الإنسان'=>'القلب يضخ الدم، والرئتان تبادلان الأكسجين وثاني أكسيد الكربون مع الهواء.','الغابات'=>'تدعم الغابات التنوع الحيوي وتخزن الكربون وتساعد على حماية التربة ودورة الماء.',_=>'اختر مجالًا لاكتشاف معلومة علمية.'};
}
