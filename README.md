# 暗棋

4×8 中国暗棋，32 子随机盖面，首翻分配双方颜色。普通棋子相邻走一格，炮隔恰好一子吃明敌子；将帅不能吃兵卒，兵卒可吃将帅。无合法动作或己子全灭判负，40 半回合未翻/吃和三次重复判和。电脑只看到公开状态，三档分别使用随机、收益/风险评估及更高下一手威胁权重；不宣称深层搜索或必胜。

## 操作与本地数据

触控、鼠标和键盘可操作真实按钮。棋格支持 Tab 进入、方向键移焦点、Enter 或空格确认；密室移动另用 WASD/E。Esc 暂停，离开标签页暂停后需手动继续。声音默认关闭，由右上角开关启用。对局进度与最近 50 条结果只保存在当前站点、当前设备；存储不可用时页面会提示，本页关闭后无法保证恢复。

游戏中心仅负责目录；独立游戏可以通过左上角返回中心。没有联机后端，也没有云同步或在线排行榜。

## 工程与构建

`lib/dark_chess.dart` 的 `DarkChess`：合法动作、等级与跳炮、终局、公开信息 AI、序列化校验。旧未接入象棋模型保留，但不是正式规则引擎。

正式主题为 Frequency Terminal，中文清晰操作区域使用黑色、酸黄和琥珀语义色。Web 平台适配器通过条件导入使用 Dart JSInterop，`web/game_bridge.js` 负责 localStorage、短提示音和白名单站内导航；不要删除 index.html 中该桥接脚本。

构建前在兼容 Flutter SDK 上取得现有依赖并运行分析、测试。Web 输出放仓库外，正式项目部署 base 保持：

```sh
flutter pub get
flutter analyze
flutter test
flutter build web --release --base-href /XJY.GAME.MINI.flipChess_flutter/ --output /absolute/external/build/XJY.GAME.MINI.flipChess_flutter
```

超级仓库并行开发时，Flutter SDK、pubspec/lock 与测试命令由统一升级会话串行执行。构建成功仍需真实浏览器验收；不得在失败或验收前覆盖旧 docs。历史重复 CNAME 不代表该子项目应部署为共享域名根路径。

## 验收状态

本轮源码已写入，分析、规则测试、release 构建及完整浏览器玩法验收由统一流程记录；此 README 不以源码就绪声明已上线。运行时元数据为中文产品真名，旧 docs 仍在成功验收前保留。设计、生成过程、截图与 QA 报告不提交到 Git。
