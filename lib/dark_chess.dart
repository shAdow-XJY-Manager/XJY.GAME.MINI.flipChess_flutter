import 'dart:math';

class DarkPiece {
  final int id,color,kind;bool revealed;
  DarkPiece(this.id,this.color,this.kind,{this.revealed=false});
  DarkPiece clone()=>DarkPiece(id,color,kind,revealed:revealed);
  static const red=['帅','仕','相','车','马','炮','兵'],black=['将','士','象','车','马','砲','卒'];
  String get name=>(color==0?red:black)[kind];
  List<int> toJson()=>[id,color,kind,revealed?1:0];
}
class DarkMove {final int from,to;const DarkMove(this.from,this.to);bool get flip=>from==to;@override bool operator==(Object other)=>other is DarkMove&&other.from==from&&other.to==to;@override int get hashCode=>Object.hash(from,to);}
class DarkChess {
  List<DarkPiece?> board;int player=0;int? firstColor;int quiet=0;String? result;
  final List<DarkPiece> captured=[];final List<String> history=[];final Map<String,int> repetitions={};
  DarkChess({Random? random}):board=[] {var id=0;for(int color=0;color<2;color++){for(int kind=0;kind<7;kind++){for(int count=0;count<(kind==0?1:kind==6?5:2);count++){board.add(DarkPiece(id++,color,kind));}}}board.shuffle(random??Random());repetitions[key]=1;}
  DarkChess._(this.board);
  int? get color=>firstColor==null?null:player==0?firstColor:1-firstColor!;
  String get key=>'${board.map((p)=>p==null?'.':!p.revealed?'?':'${p.color}${p.kind}').join(',')}:$player:$firstColor';
  static bool adjacent(int a,int b)=>(a~/4-b~/4).abs()+(a%4-b%4).abs()==1;
  static bool canCapture(DarkPiece a,DarkPiece b){if(a.color==b.color||!b.revealed||a.kind==5)return false;if(a.kind==0&&b.kind==6)return false;if(a.kind==6&&b.kind==0)return true;return a.kind<=b.kind;}
  static List<DarkMove> moves(List<DarkPiece?> cells,int? side){
    final out=<DarkMove>[];
    for(int from=0;from<32;from++){
      final p=cells[from];if(p==null)continue;
      if(!p.revealed){out.add(DarkMove(from,from));continue;}
      if(side==null||p.color!=side)continue;
      for(final delta in [-4,4,-1,1]){final to=from+delta;if(to<0||to>=32||!adjacent(from,to))continue;final t=cells[to];if(t==null||canCapture(p,t))out.add(DarkMove(from,to));}
      if(p.kind==5){for(final direction in [[0,-1],[0,1],[-1,0],[1,0]]){var x=from%4+direction[0],y=from~/4+direction[1];bool screen=false;while(x>=0&&x<4&&y>=0&&y<8){final to=y*4+x,target=cells[to];if(target!=null){if(!screen){screen=true;}else{if(target.revealed&&target.color!=side)out.add(DarkMove(from,to));break;}}x+=direction[0];y+=direction[1];}}}
    }return out;
  }
  List<DarkMove> get legal=>result==null?moves(board,color):[];
  String square(int i)=>'${String.fromCharCode(65+i%4)}${8-i~/4}';
  bool apply(DarkMove move){if(!legal.contains(move))return false;final piece=board[move.from]!;final target=board[move.to];
    if(move.flip){piece.revealed=true;firstColor??=piece.color;quiet=0;history.add('${square(move.from)} 翻开${piece.color==0?'红':'黑'}${piece.name}');}
    else{if(target!=null){captured.add(target);quiet=0;}else{quiet++;}board[move.to]=piece;board[move.from]=null;history.add('${square(move.from)} → ${square(move.to)}${target==null?'':' 吃${target.name}'}');}
    player=1-player;final k=key;repetitions[k]=(repetitions[k]??0)+1;
    if(board.every((p)=>p==null||p.color!=color)||moves(board,color).isEmpty){result='玩家${2-player}获胜';}else if(quiet>=40){result='和棋：40 步未翻子或吃子';}else if(repetitions[k]!>=3){result='和棋：局面重复三次';}
    return true;
  }
  String explainIllegal(int from,int to){
    if(from<0||from>=32||to<0||to>=32)return '超出棋盘。';
    final p=board[from],target=board[to];
    if(p==null||!p.revealed||p.color!=color)return '先选择己方明子。';
    if(target!=null&&!target.revealed)return '盖子可以翻开，不能直接吃。';
    if(target!=null&&target.color==p.color)return '不能吃己方棋子。';
    if(p.kind==5&&target!=null){
      if(from~/4!=to~/4&&from%4!=to%4)return '炮只能沿同行或同列吃子。';
      final delta=from~/4==to~/4?(to>from?1:-1):(to>from?4:-4);var screens=0;
      for(int i=from+delta;i!=to;i+=delta){if(board[i]!=null)screens++;}
      return '炮需要恰好一个炮架，当前 $screens 个。';
    }
    if(!adjacent(from,to))return '只能上下左右移动一格。';
    if(p.kind==0&&target?.kind==6)return '将帅不能吃兵卒。';
    return target==null?'请选择标记的空格。':'${p.name}不能吃${target.name}，检查棋子等级。';
  }
  DarkMove choose(int difficulty,Random random){
    final actions=legal;if(actions.isEmpty)throw StateError('No legal move');if(difficulty==0||firstColor==null)return actions[random.nextInt(actions.length)];
    // ponytail: one-step public risk heuristic; add bounded search only after a playing-strength benchmark.
    // AI receives a public observation: unknown pieces carry no identity/rank/color.
    final visible=board.map((p)=>p==null?null:p.revealed?p.clone():DarkPiece(-1,-1,-1)).toList();
    final pool=<DarkPiece>[];
    for(int side=0;side<2;side++){for(int kind=0;kind<7;kind++){var remaining=kind==0?1:kind==6?5:2;remaining-=visible.where((p)=>p!=null&&p.revealed&&p.color==side&&p.kind==kind).length;remaining-=captured.where((p)=>p.color==side&&p.kind==kind).length;for(int n=0;n<remaining;n++){pool.add(DarkPiece(-1,side,kind,revealed:true));}}}
    const values=[90.0,70.0,50.0,45.0,30.0,35.0,10.0];final side=color!;
    double score(List<DarkPiece?> cells,DarkMove action,DarkPiece? reveal){
      final b=cells.map((p)=>p?.clone()).toList();double gain=0;
      if(action.flip){b[action.to]=reveal?.clone();}else{final t=b[action.to];if(t!=null)gain+=values[t.kind];b[action.to]=b[action.from];b[action.from]=null;}
      final replies=moves(b,1-side);double danger=0;
      for(final reply in replies){if(!reply.flip&&b[reply.to]!=null){final penalty=values[b[reply.to]!.kind];danger=max(danger,penalty);}}
      final mobility=moves(b,side).where((m)=>!m.flip).length;
      final moved=b[action.to];if(moved!=null&&moved.revealed&&moved.color==side&&replies.any((m)=>!m.flip&&m.to==action.to))gain-=values[moved.kind]*(difficulty==2? 0.8:0.5);
      return gain-danger*(difficulty==2? 0.65:0.25)+mobility*0.2;
    }
    double best=-double.infinity;final ties=<DarkMove>[];
    for(final action in actions){double value;if(action.flip){value=pool.isEmpty?0:pool.map((p)=>score(visible,action,p)).reduce((a,b)=>a+b)/pool.length;}else{value=score(visible,action,null);}if(value>best+0.0001){best=value;ties.clear();ties.add(action);}else if((value-best).abs()<0.0001){ties.add(action);}}
    return ties[random.nextInt(ties.length)];
  }
  Map<String,dynamic> toJson()=>{'version':1,'board':board.map((p)=>p?.toJson()).toList(),'captured':captured.map((p)=>p.toJson()).toList(),'player':player,'firstColor':firstColor,'quiet':quiet,'result':result,'history':history,'repetitions':repetitions};
  static DarkChess? fromJson(Map<String,dynamic> j){try{
    if(j['version']!=1)return null;
    DarkPiece parse(dynamic row){final a=List<int>.from(row as List);if(a.length!=4||a[0]<0||a[0]>31||a[1]<0||a[1]>1||a[2]<0||a[2]>6||a[3]<0||a[3]>1)throw const FormatException();return DarkPiece(a[0],a[1],a[2],revealed:a[3]==1);}
    final b=(j['board'] as List).map<DarkPiece?>((v)=>v==null?null:parse(v)).toList();if(b.length!=32)return null;final c=(j['captured'] as List).map(parse).toList();final all=[...b.whereType<DarkPiece>(),...c];if(all.length!=32||all.map((p)=>p.id).toSet().length!=32||c.any((p)=>!p.revealed))return null;
    for(int side=0;side<2;side++){for(int kind=0;kind<7;kind++){if(all.where((p)=>p.color==side&&p.kind==kind).length!=(kind==0?1:kind==6?5:2))return null;}}
    final g=DarkChess._(b);g.player=j['player'] as int;g.firstColor=j['firstColor'] as int?;if(g.player<0||g.player>1||(g.firstColor!=null&&g.firstColor!=0&&g.firstColor!=1))return null;g.quiet=j['quiet'] as int;if(g.quiet<0||g.quiet>40)return null;g.result=j['result'] as String?;g.history.addAll(List<String>.from(j['history'] as List));g.captured.addAll(c);g.repetitions.addAll(Map<String,int>.from(j['repetitions'] as Map));if(g.repetitions.isEmpty||g.repetitions.values.any((n)=>n<=0)||!g.repetitions.containsKey(g.key))return null;if(g.firstColor==null&&(g.player!=0||g.quiet!=0||g.history.isNotEmpty||c.isNotEmpty||b.any((p)=>p?.revealed==true)))return null;if(g.firstColor!=null&&c.isEmpty&&!b.any((p)=>p?.revealed==true))return null;return g;
  }catch(_){return null;}}
}
