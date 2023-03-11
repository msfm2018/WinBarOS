unit core;

interface

uses
  shellapi, Wininet, classes, winapi.windows, Graphics, SysUtils, UrlMon,
  Tlhelp32, messages, core_db, Registry, aclapi, AccCtrl, forms, vcl.controls,
  shlobj, ComObj, activex, System.Generics.Collections, System.Hash, u_debug,
  cfg_form, bottom_form, Vcl.ExtCtrls, math;

type

//叶节点
  TNode = class(timage)
  public

  ///节点路径
    nodePath: string;
    ///每个节点靠左位置
    nodeLeft: integer;
  end;

  TNodes = record
    nodeCount: integer;
    diagnosticsNode: array of TNode;
    isCfging: Boolean;

    nodeWH: integer;

    const
      marginTop = 10;
      visHeight: Integer = 9; // 露头高度
      topSnapGap: Integer = 40; // 吸附距离

      ///原始数据
      nodeWidth_ = 72;
      nodeHeight_ = 72;
      nodeGap_ = 30;      //间隔
  end;

  TUtils = record
    ///  node 存储辅助
    fileMap: TDictionary<string, string>;

    shortcutKey: string;
  public
    procedure launcher(path: string);
       //根据宽度 得到间隙
    function get_snap(w: integer): integer;
//    比例因子
    function get_zoom_factor(w: double): double;
      ///自动运行
    procedure SetAutoRun(ok: Boolean);

    function get_form_height(wh: Integer): integer;

    procedure update_db();
  end;

  tobj = record
  end;

  TGblVar = class
  public
    db: tgdb;
    pathMap: TDictionary<integer, tobject>;
    utils: TUtils;
    nodes: TNodes;
  private
    formObject: TDictionary<string, TObject>;
  public
    function find(name_: string): TObject;
  end;

var
  g_core: TGblVar;

implementation

procedure TUtils.SetAutoRun(ok: Boolean);
var
  reg: TRegistry;
begin
  reg := TRegistry.create;
  try
    reg.RootKey := HKEY_CURRENT_USER;

    if reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', true) then
      reg.WriteString('xtool', ExpandFileName(paramstr(0)));

    reg.CloseKey;
  finally
    reg.Free;
  end;
end;

procedure TUtils.update_db;
var
  hash: string;
  v: string;
begin
  g_core.db.itemdb.clean();
  g_core.db.itemdb.clean(false);

  for var key in fileMap.Keys do
  begin
    v := '';
    fileMap.TryGetValue(key, v);

    hash := THashMD5.GetHashString(key);
       //k v 存储在不同表中
    g_core.db.itemdb.SetVarValue(hash, key);
    g_core.db.itemdb.SetVarValue(hash, v, false);

  end;

end;

function TUtils.get_form_height(wh: Integer): integer;
begin
  Result := math.Ceil(g_core.nodes.nodeHeight_ * wh / 118) + g_core.db.cfgDb.GetInteger('ih'); //     118:72:198:xx
end;

function TUtils.get_snap(w: integer): integer;
begin
  result := round(w * g_core.nodes.nodeGap_ / g_core.nodes.nodeWidth_); //64:30=128:?

end;

function TUtils.get_zoom_factor(w: double): double;
begin
                //计算比例因子
  result := (101.82 * 5 * w) / g_core.nodes.nodeWidth_;
end;

procedure TUtils.launcher(path: string);
begin
  if path.trim = '' then
    exit;
  if path.Contains('https') or path.Contains('http') or path.Contains('.html') or path.Contains('.htm') then
    Winapi.ShellAPI.ShellExecute(application.Handle, nil, PChar(path), nil, nil, SW_SHOWNORMAL)
  else
    ShellExecute(0, 'open', PChar(path), nil, nil, SW_SHOW);
end;

{ TGblVar }

function TGblVar.find(name_: string): TObject;
var
  vobj: TObject;
begin
  if g_core.formObject.TryGetValue(name_, vobj) then
    result := vobj
  else
    result := nil;
end;

initialization
  g_core := TGblVar.Create;

  if g_core.db.cfgDb = nil then
    g_core.db.cfgDb := TCfgDB.Create;

  if g_core.db.itemdb = nil then
    g_core.db.itemdb := TItemsDb.Create;

  g_core.db.desktopdb := TdesktopDb.Create;

  g_core.utils.fileMap := TDictionary<string, string>.Create;

    //初始化数据


  g_core.nodes.nodeWH := g_core.db.cfgDb.getInteger('ih');

  g_core.formObject := TDictionary<string, TObject>.create;
  g_core.formObject.AddOrSetValue('cfgForm', TCfgForm.Create(nil));
  g_core.formObject.AddOrSetValue('bottomForm', TbottomForm.Create(nil));

  g_core.utils.SetAutoRun(true);


finalization
  for var MyElem in g_core.formObject.Values do
    FreeAndNil(MyElem);
  g_core.formObject.Free;

  g_core.utils.fileMap.Free;

//   g_core.db.desktopdb.Free;
//   g_core.db.itemdb.Free;
//   g_core.db.cfgDb.Free;

  g_core.Free;

end.

