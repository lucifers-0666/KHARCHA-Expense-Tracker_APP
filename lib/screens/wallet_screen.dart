import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_textfield.dart';
import '../widgets/primary_button.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class WalletEntry {
  final String id, name, type;
  final double balance;
  const WalletEntry({required this.id,required this.name,required this.type,required this.balance});

  factory WalletEntry.fromMap(Map<String,dynamic> m, String id) => WalletEntry(
    id:id, name:m['name']??'', type:m['type']??'Cash', balance:(m['balance']??0).toDouble(),
  );
  Map<String,dynamic> toMap() => {'name':name,'type':type,'balance':balance};
}

const _walletTypes = [
  {'type':'Cash','icon':Icons.payments_rounded,'color':Color(0xFF43A047)},
  {'type':'UPI','icon':Icons.phone_android_rounded,'color':Color(0xFF1E88E5)},
  {'type':'Bank','icon':Icons.account_balance_rounded,'color':Color(0xFF6D4C41)},
  {'type':'Credit Card','icon':Icons.credit_card_rounded,'color':Color(0xFF8E24AA)},
  {'type':'Savings','icon':Icons.savings_rounded,'color':Color(0xFFFB8C00)},
];

Color _typeColor(String type) {
  return (_walletTypes.firstWhere((w)=>w['type']==type,orElse:()=>_walletTypes[0])['color'] as Color);
}

IconData _typeIcon(String type) {
  return (_walletTypes.firstWhere((w)=>w['type']==type,orElse:()=>_walletTypes[0])['icon'] as IconData);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  final _svc = FirestoreServices();
  final _fmt = NumberFormat('#,##,###');
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync:this,duration:const Duration(milliseconds:600))..forward();
    _fade = CurvedAnimation(parent:_ctrl,curve:Curves.easeOut);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Map<String,dynamic>>>(
        stream: _svc.getWallets(),
        builder: (ctx, snap) {
          final wallets = (snap.data??[]).map((m)=>WalletEntry.fromMap(m,m['id']??'')).toList();
          final totalBalance = wallets.fold(0.0,(s,w)=>s+w.balance);

          // Group by type
          final Map<String,double> byType = {};
          for(final w in wallets) byType[w.type] = (byType[w.type]??0)+w.balance;

          return FadeTransition(
            opacity:_fade,
            child:CustomScrollView(
              slivers:[
                // ── AppBar ──
                SliverAppBar(
                  backgroundColor:Colors.white, elevation:0, pinned:true,
                  leading:IconButton(
                    icon:const Icon(Icons.arrow_back_ios_new_rounded,size:20),
                    color:const Color(0xFF1A1A2E),
                    onPressed:()=>Navigator.pop(context),
                  ),
                  title:const Text('My Wallets',style:TextStyle(color:Color(0xFF1A1A2E),fontSize:18,fontWeight:FontWeight.w700)),
                  actions:[
                    GestureDetector(
                      onTap:()=>_showAddSheet(context),
                      child:Container(
                        margin:const EdgeInsets.only(right:16),
                        padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),
                        decoration:BoxDecoration(color:AppColors.primary,borderRadius:BorderRadius.circular(20)),
                        child:const Text('+ Wallet',style:TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w700)),
                      ),
                    ),
                  ],
                  bottom:PreferredSize(preferredSize:const Size.fromHeight(1),child:Container(height:1,color:const Color(0xFFE8F5E9))),
                ),

                // ── Total balance hero ──
                SliverToBoxAdapter(child:_TotalBalanceCard(total:totalBalance,byType:byType,fmt:_fmt)),

                // ── Type breakdown ──
                if(byType.isNotEmpty) ...[
                  SliverToBoxAdapter(child:_SectionHeader2(title:'By Account Type',sub:'Your wallet breakdown')),
                  SliverToBoxAdapter(child:_TypeBreakdownRow(byType:byType,fmt:_fmt)),
                ],

                // ── Wallets list or empty ──
                SliverToBoxAdapter(child:_SectionHeader2(title:wallets.isEmpty?'Your Wallets':'All Wallets (${wallets.length})',sub:wallets.isEmpty?'Add cash, UPI or bank accounts':'Swipe left to delete')),

                if(wallets.isEmpty)
                  SliverToBoxAdapter(child:_EmptyWalletState(onAdd:()=>_showAddSheet(context)))
                else
                  SliverList(delegate:SliverChildBuilderDelegate(
                    (_,i)=>_WalletTile(wallet:wallets[i],fmt:_fmt,onDelete:()=>_svc.deleteWallet(wallets[i].id)),
                    childCount:wallets.length,
                  )),

                // ── Info section ──
                SliverToBoxAdapter(child:_SectionHeader2(title:'What to track',sub:'Keep all balances in one place')),
                SliverToBoxAdapter(child:_InfoGrid()),

                const SliverPadding(padding:EdgeInsets.only(bottom:40)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext ctx) {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController();
    String selectedType = 'Cash';
    showModalBottomSheet(
      context:ctx, isScrollControlled:true, backgroundColor:Colors.white,
      shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),
      builder:(_)=>StatefulBuilder(builder:(ctx2,setSt)=>Padding(
        padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(ctx2).viewInsets.bottom+24),
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Center(child:Container(width:36,height:4,decoration:BoxDecoration(color:const Color(0xFFE0E0E0),borderRadius:BorderRadius.circular(2)))),
          const SizedBox(height:16),
          Row(children:[
            Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:AppColors.primary.withValues(alpha:0.1),borderRadius:BorderRadius.circular(10)),
              child:Icon(Icons.account_balance_wallet_rounded,color:AppColors.primary,size:20)),
            const SizedBox(width:10),
            const Text('Add Wallet',style:TextStyle(fontSize:17,fontWeight:FontWeight.w700,color:Color(0xFF1A1A2E))),
          ]),
          const SizedBox(height:20),
          // Type selector
          SizedBox(height:44,child:ListView.separated(
            scrollDirection:Axis.horizontal,
            itemCount:_walletTypes.length,
            separatorBuilder:(_,__)=>const SizedBox(width:8),
            itemBuilder:(_,i){
              final wt = _walletTypes[i];
              final sel = selectedType==wt['type'];
              return GestureDetector(
                onTap:()=>setSt(()=>selectedType=wt['type'] as String),
                child:AnimatedContainer(
                  duration:const Duration(milliseconds:200),
                  padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
                  decoration:BoxDecoration(
                    color:sel?(wt['color'] as Color).withValues(alpha:0.1):const Color(0xFFF5F5F5),
                    borderRadius:BorderRadius.circular(10),
                    border:Border.all(color:sel?(wt['color'] as Color):Colors.transparent,width:1.5),
                  ),
                  child:Row(children:[
                    Icon(wt['icon'] as IconData,size:15,color:sel?(wt['color'] as Color):Colors.grey),
                    const SizedBox(width:5),
                    Text(wt['type'] as String,style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:sel?(wt['color'] as Color):Colors.grey)),
                  ]),
                ),
              );
            },
          )),
          const SizedBox(height:14),
          PremiumTextField(controller:nameCtrl,label:'Wallet Name',hint:'e.g. HDFC Savings'),
          const SizedBox(height:12),
          PremiumTextField(controller:balCtrl,label:'Current Balance (₹)',hint:'0',keyboardType:TextInputType.number),
          const SizedBox(height:20),
          PrimaryButton(label:'Add Wallet',onPressed:()async{
            final name=nameCtrl.text.trim();
            final bal=double.tryParse(balCtrl.text)??0;
            if(name.isEmpty)return;
            await _svc.addWallet({'name':name,'type':selectedType,'balance':bal});
            if(ctx.mounted)Navigator.pop(ctx);
          }),
        ]),
      )),
    );
  }
}

// ─── Total Balance Card ───────────────────────────────────────────────────────
class _TotalBalanceCard extends StatelessWidget {
  final double total;
  final Map<String,double> byType;
  final NumberFormat fmt;
  const _TotalBalanceCard({required this.total,required this.byType,required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:const EdgeInsets.fromLTRB(20,20,20,8),
      padding:const EdgeInsets.all(22),
      decoration:BoxDecoration(
        gradient:LinearGradient(colors:[AppColors.primary,AppColors.primary.withValues(alpha:0.78)],begin:Alignment.topLeft,end:Alignment.bottomRight),
        borderRadius:BorderRadius.circular(20),
        boxShadow:[BoxShadow(color:AppColors.primary.withValues(alpha:0.25),blurRadius:20,offset:const Offset(0,8))],
      ),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          const Icon(Icons.account_balance_wallet_rounded,color:Colors.white70,size:16),
          const SizedBox(width:6),
          const Text('TOTAL BALANCE',style:TextStyle(color:Colors.white70,fontSize:11,fontWeight:FontWeight.w700,letterSpacing:1.0)),
          const Spacer(),
          Container(
            padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
            decoration:BoxDecoration(color:Colors.white.withValues(alpha:0.2),borderRadius:BorderRadius.circular(20)),
            child:const Text('All Accounts',style:TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w600)),
          ),
        ]),
        const SizedBox(height:12),
        Text('₹${fmt.format(total.toInt())}',style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.w800,letterSpacing:-0.5)),
        const SizedBox(height:16),
        if(byType.isNotEmpty)
          Wrap(
            spacing:10,runSpacing:8,
            children:byType.entries.map((e)=>_BalancePill(type:e.key,amount:e.value,fmt:fmt)).toList(),
          )
        else
          Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white.withValues(alpha:0.15),borderRadius:BorderRadius.circular(12)),
            child:const Row(children:[
              Icon(Icons.info_outline_rounded,color:Colors.white70,size:15),
              SizedBox(width:8),
              Expanded(child:Text('Add wallets to track cash, UPI, and bank balances in one place',style:TextStyle(color:Colors.white,fontSize:12))),
            ]),
          ),
      ]),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String type;
  final double amount;
  final NumberFormat fmt;
  const _BalancePill({required this.type,required this.amount,required this.fmt});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
      decoration:BoxDecoration(color:Colors.white.withValues(alpha:0.2),borderRadius:BorderRadius.circular(20)),
      child:Row(mainAxisSize:MainAxisSize.min,children:[
        Icon(_typeIcon(type),size:12,color:Colors.white),
        const SizedBox(width:4),
        Text('$type  ₹${fmt.format(amount.toInt())}',style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w600)),
      ]),
    );
  }
}

// ─── Type Breakdown Row ───────────────────────────────────────────────────────
class _TypeBreakdownRow extends StatelessWidget {
  final Map<String,double> byType;
  final NumberFormat fmt;
  const _TypeBreakdownRow({required this.byType,required this.fmt});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:110,
      child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:20),
        children:byType.entries.map((e)=>Container(
          width:120,margin:const EdgeInsets.only(right:12),
          padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(
            color:Colors.white,borderRadius:BorderRadius.circular(16),
            border:Border.all(color:_typeColor(e.key).withValues(alpha:0.2)),
            boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:0.04),blurRadius:8,offset:const Offset(0,2))],
          ),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:_typeColor(e.key).withValues(alpha:0.1),borderRadius:BorderRadius.circular(8)),
              child:Icon(_typeIcon(e.key),size:16,color:_typeColor(e.key))),
            const SizedBox(height:8),
            Text(e.key,style:const TextStyle(fontSize:11,color:Color(0xFF757575),fontWeight:FontWeight.w500)),
            Text('₹${fmt.format(e.value.toInt())}',style:TextStyle(fontSize:14,fontWeight:FontWeight.w800,color:_typeColor(e.key))),
          ]),
        )).toList(),
      ),
    );
  }
}

// ─── Wallet Tile ──────────────────────────────────────────────────────────────
class _WalletTile extends StatelessWidget {
  final WalletEntry wallet;
  final NumberFormat fmt;
  final VoidCallback onDelete;
  const _WalletTile({required this.wallet,required this.fmt,required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final col = _typeColor(wallet.type);
    return Dismissible(
      key:Key(wallet.id),
      direction:DismissDirection.endToStart,
      background:Container(
        margin:const EdgeInsets.fromLTRB(20,0,20,12),
        alignment:Alignment.centerRight,
        padding:const EdgeInsets.only(right:20),
        decoration:BoxDecoration(color:Colors.red.shade50,borderRadius:BorderRadius.circular(14)),
        child:const Icon(Icons.delete_outline_rounded,color:Colors.redAccent),
      ),
      onDismissed:(_)=>onDelete(),
      child:Container(
        margin:const EdgeInsets.fromLTRB(20,0,20,10),
        padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(
          color:Colors.white,borderRadius:BorderRadius.circular(14),
          border:Border.all(color:col.withValues(alpha:0.15)),
          boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:0.03),blurRadius:8,offset:const Offset(0,2))],
        ),
        child:Row(children:[
          Container(width:44,height:44,decoration:BoxDecoration(color:col.withValues(alpha:0.1),borderRadius:BorderRadius.circular(12)),
            child:Icon(_typeIcon(wallet.type),color:col,size:20)),
          const SizedBox(width:14),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(wallet.name,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:Color(0xFF1A1A2E))),
            Text(wallet.type,style:const TextStyle(fontSize:12,color:Color(0xFF9E9E9E))),
          ])),
          Text('₹${fmt.format(wallet.balance.toInt())}',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:col)),
        ]),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyWalletState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyWalletState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:const EdgeInsets.symmetric(horizontal:20,vertical:8),
      child:Container(
        width:double.infinity,
        padding:const EdgeInsets.all(24),
        decoration:BoxDecoration(
          color:const Color(0xFFF9FFF9),
          borderRadius:BorderRadius.circular(20),
          border:Border.all(color:AppColors.primary.withValues(alpha:0.15)),
        ),
        child:Column(children:[
          const Text('👛',style:TextStyle(fontSize:48)),
          const SizedBox(height:12),
          const Text('No wallets added',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E))),
          const SizedBox(height:6),
          Text('Track your cash, UPI, and bank balances in one unified dashboard.',textAlign:TextAlign.center,style:TextStyle(fontSize:13,color:Colors.grey.shade500)),
          const SizedBox(height:20),
          _WalletTypeRow(),
          const SizedBox(height:20),
          SizedBox(width:double.infinity,height:48,
            child:ElevatedButton(
              onPressed:onAdd,
              style:ElevatedButton.styleFrom(backgroundColor:AppColors.primary,foregroundColor:Colors.white,elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
              child:const Text('Add First Wallet',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _WalletTypeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(spacing:8,runSpacing:8,alignment:WrapAlignment.center,
      children:_walletTypes.map((wt)=>Container(
        padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
        decoration:BoxDecoration(color:(wt['color'] as Color).withValues(alpha:0.08),borderRadius:BorderRadius.circular(20),border:Border.all(color:(wt['color'] as Color).withValues(alpha:0.2))),
        child:Row(mainAxisSize:MainAxisSize.min,children:[
          Icon(wt['icon'] as IconData,size:13,color:wt['color'] as Color),
          const SizedBox(width:4),
          Text(wt['type'] as String,style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:wt['color'] as Color)),
        ]),
      )).toList(),
    );
  }
}

// ─── Info Grid ────────────────────────────────────────────────────────────────
class _InfoGrid extends StatelessWidget {
  final _items = const [
    {'icon':Icons.payments_rounded,'label':'Cash','desc':'Track physical money on hand','color':Color(0xFF43A047)},
    {'icon':Icons.phone_android_rounded,'label':'UPI Wallets','desc':'GPay, PhonePe, Paytm','color':Color(0xFF1E88E5)},
    {'icon':Icons.account_balance_rounded,'label':'Bank Accounts','desc':'Savings & current accounts','color':Color(0xFF6D4C41)},
    {'icon':Icons.credit_card_rounded,'label':'Credit Cards','desc':'Track credit utilization','color':Color(0xFF8E24AA)},
  ];
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:const EdgeInsets.symmetric(horizontal:20),
      child:GridView.count(
        crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.5,
        children:_items.map((item)=>Container(
          padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(
            color:Colors.white,borderRadius:BorderRadius.circular(14),
            border:Border.all(color:(item['color'] as Color).withValues(alpha:0.15)),
            boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:0.03),blurRadius:6,offset:const Offset(0,2))],
          ),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
            Icon(item['icon'] as IconData,color:item['color'] as Color,size:20),
            const SizedBox(height:6),
            Text(item['label'] as String,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700,color:Color(0xFF1A1A2E))),
            Text(item['desc'] as String,style:const TextStyle(fontSize:10,color:Color(0xFF9E9E9E))),
          ]),
        )).toList(),
      ),
    );
  }
}

class _SectionHeader2 extends StatelessWidget {
  final String title, sub;
  const _SectionHeader2({required this.title,required this.sub});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:const EdgeInsets.fromLTRB(20,20,20,8),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w800,color:Color(0xFF1A1A2E))),
        const SizedBox(height:2),
        Text(sub,style:const TextStyle(fontSize:12,color:Color(0xFF9E9E9E))),
      ]),
    );
  }
}
