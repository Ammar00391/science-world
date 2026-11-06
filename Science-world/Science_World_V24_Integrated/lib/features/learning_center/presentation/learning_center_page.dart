import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Connects the requested study workflows to existing screens and adds local
/// plan/error-note/draft persistence without inventing official curriculum sources.
class LearningCenterPage extends StatefulWidget {
  const LearningCenterPage({super.key});
  @override State<LearningCenterPage> createState()=>_LearningCenterPageState();
}
class _LearningCenterPageState extends State<LearningCenterPage>{
  final _plan=TextEditingController(); final _mistakes=TextEditingController(); final _draft=TextEditingController();
  bool _loading=true;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{final p=await SharedPreferences.getInstance();if(!mounted)return;setState((){_plan.text=p.getString('study_personal_plan')??'30 دقيقة رياضيات، 30 دقيقة فيزياء، 20 دقيقة مراجعة';_mistakes.text=p.getString('study_mistakes')??'';_draft.text=p.getString('teacher_question_draft')??'';_loading=false;});}
  Future<void> _save(String key,String value)async{final p=await SharedPreferences.getInstance();await p.setString(key,value);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم الحفظ على هذا الجهاز')));}
  @override void dispose(){_plan.dispose();_mistakes.dispose();_draft.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(appBar:AppBar(title:const Text('مركز التعلّم السوري')),body:_loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(16),children:[
    const Text('مسارات الدراسة',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    const Text('اربط المواد والاختبارات والمراجعة والتحميل من واجهات المشروع الحالية.'),const SizedBox(height:12),
    _link(Icons.menu_book,'المكتبة السورية الذكية','الكتب والمواد المتاحة داخل المشروع','/library'),
    _link(Icons.menu_book_outlined,'مواد ودروس المنهاج','اختر المادة والوحدة والدرس','/subjects'),
    _link(Icons.quiz,'بنك الأسئلة','تصفّح الأسئلة المسجلة في بنك التطبيق','/quiz-bank'),
    _link(Icons.timer,'محاكي الامتحان','الانتقال إلى واجهة الاختبار الموجودة','/test'),
    _link(Icons.smart_toy,'أستاذ الذكاء الاصطناعي','المساعد الحالي؛ يحتاج إعداد خدمة سحابية فعليًا','/assistant'),
    _link(Icons.science,'مختبر العلوم','تجارب مفاهيمية آمنة','/world'),
    _link(Icons.download_for_offline,'التنزيل دون إنترنت','إدارة الملفات التي يدعمها المشروع','/downloads'),
    _link(Icons.insights,'إحصائيات التقدم','عرض صفحة تقدم الطالب الحالية','/progress'),
    _link(Icons.refresh,'دفتر المراجعة','فتح المراجعة الموجودة','/review'),
    const SizedBox(height:16),_panel('خطة دراسة شخصية',Icons.event_note,[
      const Text('اكتب خطة واقعية؛ تحفظ محليًا ويمكن تعديلها في أي وقت.'),TextField(controller:_plan,maxLines:4,decoration:const InputDecoration(labelText:'خطة هذا الأسبوع',border:OutlineInputBorder())),Align(alignment:Alignment.centerLeft,child:FilledButton(onPressed:()=>_save('study_personal_plan',_plan.text),child:const Text('حفظ الخطة')))]),
    _panel('دفتر الأخطاء والمراجعة الذكية',Icons.fact_check,[const Text('سجّل السؤال وسبب الخطأ والإجابة الصحيحة لمراجعته لاحقًا.'),TextField(controller:_mistakes,maxLines:5,decoration:const InputDecoration(labelText:'السؤال • خطئي • التصحيح • موعد المراجعة',border:OutlineInputBorder())),Align(alignment:Alignment.centerLeft,child:FilledButton(onPressed:()=>_save('study_mistakes',_mistakes.text),child:const Text('حفظ الأخطاء')))]),
    _panel('مسودة سؤال للمدرس',Icons.school,[const Text('هذه مسودة محلية فقط؛ لا تُنشر ولا تصبح سؤالًا معتمدًا قبل المراجعة وإضافة مصدر موثوق.'),TextField(controller:_draft,maxLines:5,decoration:const InputDecoration(labelText:'السؤال والإجابة والتعليل والمصدر/الصف/الوحدة/الدرس/الصفحة',border:OutlineInputBorder())),Align(alignment:Alignment.centerLeft,child:FilledButton(onPressed:()=>_save('teacher_question_draft',_draft.text),child:const Text('حفظ المسودة')))]),
    const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('نزاهة المصادر: لا تُوسم الأسئلة بأنها رسمية أو معتمدة لعام 2026–2027 إلا بعد مراجعة الكتب الرسمية وتثبيت الصف والفرع والوحدة والدرس ورقم الصفحة. هذه الواجهة لا تنشئ اتصالًا مباشرًا بلوحة مدرس سحابية أو مزامنة متعددة الأجهزة.'))),
  ])));
  Widget _link(IconData icon,String title,String sub,String route)=>Card(child:ListTile(leading:Icon(icon),title:Text(title),subtitle:Text(sub),trailing:const Icon(Icons.chevron_left),onTap:()=>context.go(route)));
  Widget _panel(String title,IconData icon,List<Widget> children)=>Card(margin:const EdgeInsets.only(top:12),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Icon(icon),const SizedBox(width:8),Expanded(child:Text(title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold)))]),const SizedBox(height:12),...children])));
}
