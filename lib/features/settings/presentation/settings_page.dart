import 'package:flutter/material.dart';
import '../../../core/services/sound_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  final _sound = SoundService(); bool _enabled = true; double _volume = .75; bool _loading = true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async { final e=await _sound.isEnabled(); final v=await _sound.getVolume(); if(mounted)setState((){_enabled=e;_volume=v;_loading=false;}); }
  @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text('الإعدادات')),body:Directionality(textDirection:TextDirection.rtl,child:ListView(children:[
    const ListTile(leading:Icon(Icons.text_fields),title:Text('حجم الخط'),subtitle:Text('افتراضي')),
    const ListTile(leading:Icon(Icons.language),title:Text('اللغة'),subtitle:Text('العربية')),
    const Divider(),
    const ListTile(leading:Icon(Icons.graphic_eq),title:Text('المؤثرات الصوتية'),subtitle:Text('أصوات أصلية للإجابات والتحديات والإنجازات')),
    if(_loading) const LinearProgressIndicator() else SwitchListTile(secondary:const Icon(Icons.volume_up),title:const Text('تشغيل المؤثرات'),subtitle:Text(_enabled?'الأصوات مفعّلة':'الوضع الصامت'),value:_enabled,onChanged:(v)async{setState(()=>_enabled=v);await _sound.setEnabled(v);if(v)await _sound.playXp();}),
    ListTile(leading:const Icon(Icons.tune),title:const Text('مستوى الصوت'),subtitle:Slider(value:_volume,min:0,max:1,divisions:10,label:'${(_volume*100).round()}%',onChanged:_enabled?(v)async{setState(()=>_volume=v);await _sound.setVolume(v);}:null),trailing:Text('${(_volume*100).round()}%')),
    ListTile(leading:const Icon(Icons.play_circle_outline),title:const Text('تجربة الصوت'),subtitle:const Text('تشغيل نغمة أصلية قصيرة'),onTap:()=>_sound.playAchievement()),
    const Divider(),const ListTile(leading:Icon(Icons.info_outline),title:Text('حول التطبيق'),subtitle:Text('عالم العلوم v1.0')),
  ])));
}
